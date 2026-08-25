// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_constants.dart';
import '../models/workout_model.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/admin/admin_panel.dart';
import '../screens/instructor/instructor_panel.dart';
import '../screens/instructor/create_workout_screen.dart';
import '../screens/student/student_panel.dart';
import '../screens/student/workout_detail_screen.dart';
import '../screens/student/workout_player_screen.dart';
import '../screens/account_blocked_screen.dart';
import '../screens/chat_route_screen.dart';

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final status = authProvider.status;
      final indoParaAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/cadastro' ||
          state.matchedLocation == '/esqueci-senha';

      if (status == AuthStatus.carregando) return null; // fica na splash

      if (status == AuthStatus.naoAutenticado) {
        return indoParaAuth ? null : '/login';
      }

      // Conta desativada pelo admin: prende a pessoa na tela de bloqueio,
      // não importa pra onde ela tente navegar. Se o admin reativar, o
      // próximo check já libera sozinho (a stream do usuário atualiza em
      // tempo real, sem precisar deslogar/logar de novo).
      if (authProvider.contaBloqueada) {
        return state.matchedLocation == '/bloqueado' ? null : '/bloqueado';
      }
      if (state.matchedLocation == '/bloqueado') {
        // Foi desbloqueado nesse meio tempo -> manda pra home certa.
        return _rotaInicialPorRole(authProvider.usuario!.role);
      }

      // Autenticado
      if (state.matchedLocation == '/' || indoParaAuth) {
        return _rotaInicialPorRole(authProvider.usuario!.role);
      }

      // Bloqueia acesso a rotas de outro papel
      final role = authProvider.usuario!.role;
      if (state.matchedLocation.startsWith('/admin') && role != UserRole.admin) {
        return _rotaInicialPorRole(role);
      }
      if (state.matchedLocation.startsWith('/instrutor') && role != UserRole.instrutor) {
        return _rotaInicialPorRole(role);
      }
      if (state.matchedLocation.startsWith('/aluno') && role != UserRole.aluno) {
        return _rotaInicialPorRole(role);
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(
        path: '/cadastro',
        builder: (c, s) => RegisterScreen(codigoIndicacaoInicial: s.uri.queryParameters['ref']),
      ),
      GoRoute(path: '/esqueci-senha', builder: (c, s) => const ForgotPasswordScreen()),
      GoRoute(path: '/bloqueado', builder: (c, s) => const AccountBlockedScreen()),
      GoRoute(
        path: '/chat/:chatId',
        builder: (c, s) => ChatRouteScreen(chatId: s.pathParameters['chatId']!),
      ),

      // ---- ALUNO ----
      // O painel do aluno gerencia suas próprias abas internamente
      // (Início / Treinos / Progresso / Plano) — ver StudentPanel.
      GoRoute(path: '/aluno', builder: (c, s) => const StudentPanel()),
      GoRoute(
        path: '/aluno/treino/:id',
        builder: (c, s) => WorkoutDetailScreen(workoutId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/aluno/treino/:id/executar',
        builder: (c, s) => WorkoutPlayerScreen(treino: s.extra as WorkoutModel),
      ),

      // ---- INSTRUTOR ----
      GoRoute(path: '/instrutor', builder: (c, s) => const InstructorPanel()),
      GoRoute(
        path: '/instrutor/novo-treino',
        builder: (c, s) => CreateWorkoutScreen(
          presetAlunoId: s.uri.queryParameters['alunoId'],
          presetAlunoNome: s.uri.queryParameters['alunoNome'],
        ),
      ),
      GoRoute(
        path: '/instrutor/editar-treino/:id',
        builder: (c, s) => CreateWorkoutScreen(workoutId: s.pathParameters['id']),
      ),

      // ---- ADMIN ----
      GoRoute(path: '/admin', builder: (c, s) => const AdminPanel()),
    ],
  );
}

String _rotaInicialPorRole(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return '/admin';
    case UserRole.instrutor:
      return '/instrutor';
    case UserRole.aluno:
      return '/aluno';
  }
}