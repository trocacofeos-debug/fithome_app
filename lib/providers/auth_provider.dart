import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { carregando, autenticado, naoAutenticado }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus status = AuthStatus.carregando;
  UserModel? usuario;
  String? erro;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(fb.User? firebaseUser) async {
    if (firebaseUser == null) {
      usuario = null;
      status = AuthStatus.naoAutenticado;
      notifyListeners();
      return;
    }
    try {
      usuario = await _authService.getUserData(firebaseUser.uid);
      status = AuthStatus.autenticado;
    } catch (e) {
      erro = e.toString();
      status = AuthStatus.naoAutenticado;
    }
    notifyListeners();
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

  Future<bool> registrar(String nome, String email, String senha) async {
    try {
      erro = null;
      usuario = await _authService.registrar(nome: nome, email: email, senha: senha);
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
    await _authService.logout();
    usuario = null;
    status = AuthStatus.naoAutenticado;
    notifyListeners();
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
          // Mostrando o código explicitamente (ex: "auth/invalid-api-key",
          // "auth/configuration-not-found") porque e.message às vezes vem
          // vazio ou genérico ("Error") no Firebase Web, e o código é o
          // que realmente aponta a causa.
          return 'Erro de autenticação (${e.code}): ${e.message ?? "sem detalhes"}';
      }
    }
    if (e.toString().contains('cancelado')) {
      return 'Login cancelado.';
    }
    return 'Erro inesperado: $e';
  }
}