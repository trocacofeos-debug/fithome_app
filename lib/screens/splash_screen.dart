import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';

/// Tela exibida enquanto o AuthProvider verifica a sessão.
/// No design original existe um "RoleSelector" manual, mas aqui o papel
/// (aluno/instrutor/admin) já vem do Firestore junto com o login — então
/// esta tela funciona só como splash de carregamento.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_fire_department, color: AppColors.primary, size: 56),
            const SizedBox(height: 12),
            Text(AppConstants.appName, style: condensed(fontSize: 26)),
            const SizedBox(height: 28),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
