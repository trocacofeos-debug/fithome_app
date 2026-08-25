import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { carregando, autenticado, naoAutenticado }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<UserModel?>? _userSub;

  AuthStatus status = AuthStatus.carregando;
  UserModel? usuario;
  String? erro;

  /// true quando o usuário está autenticado só que com a conta desativada
  /// pelo admin — o roteador usa isso pra prender a pessoa numa tela de
  /// bloqueio, sem deslogar (assim, se o admin reativar, ela volta a
  /// navegar normalmente sem precisar logar de novo).
  bool get contaBloqueada => usuario != null && !usuario!.ativo;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(fb.User? firebaseUser) async {
    await _userSub?.cancel();
    _userSub = null;

    if (firebaseUser == null) {
      usuario = null;
      status = AuthStatus.naoAutenticado;
      notifyListeners();
      return;
    }

    // Assina o documento do usuário em tempo real: qualquer alteração no
    // perfil (edição própria, mudança de papel, ativar/desativar conta
    // pelo admin) já reflete no app inteiro na hora, sem precisar deslogar
    // e logar de novo.
    _userSub = _authService.userDataStream(firebaseUser.uid).listen(
      (dados) {
        if (dados != null) {
          usuario = dados;
          status = AuthStatus.autenticado;
        }
        notifyListeners();
      },
      onError: (e) {
        erro = e.toString();
        status = AuthStatus.naoAutenticado;
        notifyListeners();
      },
    );
  }

  Future<bool> login(String email, String senha) async {
    try {
      erro = null;
      usuario = await _authService.login(email: email, senha: senha);
      status = AuthStatus.autenticado;
      notifyListeners();
      return true;
    } catch (e) {
      erro = _mensagemAmigavel(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginComGoogle() async {
    try {
      erro = null;
      usuario = await _authService.loginComGoogle();
      status = AuthStatus.autenticado;
      notifyListeners();
      return true;
    } catch (e) {
      erro = _mensagemAmigavel(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrar(String nome, String email, String senha, {String? codigoIndicacao}) async {
    try {
      erro = null;
      usuario = await _authService.registrar(
        nome: nome,
        email: email,
        senha: senha,
        codigoIndicacao: codigoIndicacao,
      );
      status = AuthStatus.autenticado;
      notifyListeners();
      return true;
    } catch (e) {
      erro = _mensagemAmigavel(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _userSub?.cancel();
    _userSub = null;
    await _authService.logout();
    usuario = null;
    status = AuthStatus.naoAutenticado;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  String _mensagemAmigavel(Object e) {
    if (e is fb.FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'Usuário não encontrado.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-mail ou senha inválidos.';
        case 'email-already-in-use':
          return 'Este e-mail já está cadastrado.';
        case 'weak-password':
          return 'Senha muito fraca (mínimo 6 caracteres).';
        case 'account-exists-with-different-credential':
          return 'Já existe uma conta com este e-mail usando outro método de login.';
        default:
          return 'Erro de autenticação (${e.code}): ${e.message ?? "sem detalhes"}';
      }
    }
    if (e.toString().contains('cancelado')) {
      return 'Login cancelado.';
    }
    return 'Erro inesperado: $e';
  }
}