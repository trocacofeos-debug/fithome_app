import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // A partir da v7 do pacote, GoogleSignIn é um singleton (sem construtor
  // público) e precisa ser inicializado uma única vez antes do primeiro uso.
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInicializado = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Cria a conta no Auth e o documento do usuário no Firestore.
  /// Por padrão todo cadastro público entra como 'aluno'.
  /// Instrutor e Admin são promovidos manualmente pelo painel Admin.
  ///
  /// [codigoIndicacao], se informado, é o uid de um instrutor (sistema de
  /// indicação/comissão). Só é gravado como `indicadoPor` se o código
  /// corresponder de fato a um usuário com papel 'instrutor' — um código
  /// inválido/vazio nunca bloqueia o cadastro, só é ignorado.
  Future<UserModel> registrar({
    required String nome,
    required String email,
    required String senha,
    String? codigoIndicacao,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );

    final uid = cred.user!.uid;
    final indicadoPor = await _resolverIndicadoPor(codigoIndicacao);
    final userModel = UserModel(
      id: uid,
      nome: nome,
      email: email,
      role: UserRole.aluno,
      createdAt: DateTime.now(),
      indicadoPor: indicadoPor,
    );

    await _db.collection(FirestoreCollections.users).doc(uid).set(userModel.toMap());
    await cred.user!.updateDisplayName(nome);

    return userModel;
  }

  Future<String?> _resolverIndicadoPor(String? codigoIndicacao) async {
    final codigo = codigoIndicacao?.trim();
    if (codigo == null || codigo.isEmpty) return null;
    final doc = await _db.collection(FirestoreCollections.users).doc(codigo).get();
    if (!doc.exists) return null;
    final role = UserRoleX.fromString(doc.data()?['role'] ?? 'aluno');
    return role == UserRole.instrutor ? codigo : null;
  }

  Future<UserModel> login({required String email, required String senha}) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: senha);
    return getUserData(cred.user!.uid);
  }

  Future<void> _garantirGoogleSignInInicializado() async {
    if (_googleSignInInicializado) return;
    // Em Android o clientId é lido automaticamente do google-services.json.
    // No iOS vem do GoogleService-Info.plist (via `flutterfire configure`).
    // Se for usar o fluxo nativo também na Web (em vez do popup do Firebase
    // usado abaixo), informe clientId/serverClientId aqui.
    await _googleSignIn.initialize();
    _googleSignInInicializado = true;
  }

  /// Login com conta Google. Se for o primeiro acesso dessa pessoa, cria o
  /// documento dela no Firestore automaticamente com papel 'aluno' (igual
  /// ao cadastro por e-mail/senha). Em acessos seguintes, só busca os
  /// dados já existentes.
  Future<UserModel> loginComGoogle() async {
    late final UserCredential cred;

    if (kIsWeb) {
      // Na Web, o fluxo mais simples e estável continua sendo o popup do
      // próprio Firebase — a v7 do google_sign_in mudou bastante o
      // funcionamento no navegador (exige renderizar o botão oficial do
      // Google), então evitamos essa complexidade aqui.
      final provider = GoogleAuthProvider();
      cred = await _auth.signInWithPopup(provider);
    } else {
      await _garantirGoogleSignInInicializado();

      late final GoogleSignInAccount googleUser;
      try {
        googleUser = await _googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        // Cobre tanto cancelamento pelo usuário quanto outras falhas do
        // fluxo nativo (ex: conta não configurada, Play Services ausente).
        throw Exception(e.description ?? 'Login com Google cancelado.');
      }

      // Na v7, autenticação (identidade) e autorização (tokens de acesso a
      // escopos) são etapas separadas.
      const escopos = ['email'];
      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(escopos);

      final credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken,
        idToken: googleUser.authentication.idToken,
      );
      cred = await _auth.signInWithCredential(credential);
    }

    final user = cred.user!;
    final doc = await _db.collection(FirestoreCollections.users).doc(user.uid).get();

    if (!doc.exists) {
      final userModel = UserModel(
        id: user.uid,
        nome: user.displayName ?? 'Usuário',
        email: user.email ?? '',
        role: UserRole.aluno,
        fotoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
      await _db.collection(FirestoreCollections.users).doc(user.uid).set(userModel.toMap());
      return userModel;
    }

    return UserModel.fromMap(doc.id, doc.data()!);
  }

  Future<void> logout() async {
    if (_googleSignInInicializado) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  Future<void> resetarSenha(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserModel> getUserData(String uid) async {
    final doc = await _db.collection(FirestoreCollections.users).doc(uid).get();
    if (!doc.exists) {
      throw Exception('Usuário não encontrado no banco de dados.');
    }
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  Stream<UserModel?> userDataStream(String uid) {
    return _db.collection(FirestoreCollections.users).doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromMap(doc.id, doc.data()!) : null,
        );
  }
}