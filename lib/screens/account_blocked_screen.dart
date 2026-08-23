// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

/// Tela travada, mostrada quando a conta do usuário está desativada pelo
/// admin. Não tem botão de voltar nem forma de fechar — só dá pra sair da
/// conta. Se o admin reativar o acesso, o roteador tira a pessoa dessa
/// tela sozinho (sem precisar deslogar/logar de novo), porque o app está
/// ouvindo o status da conta em tempo real.
class AccountBlockedScreen extends StatelessWidget {
  const AccountBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(color: AppColors.destructive.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.lock_outline, color: AppColors.destructive, size: 44),
                    ),
                    const SizedBox(height: 24),
                    Text('ACESSO BLOQUEADO', textAlign: TextAlign.center, style: condensed(fontSize: 26)),
                    const SizedBox(height: 12),
                    const Text(
                      'Seu acesso foi bloqueado por um administrador. '
                      'Fale com a equipe do FitHome Pro para regularizar sua situação.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.mutedForeground, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.read<AuthProvider>().logout(),
                        icon: const Icon(Icons.logout),
                        label: const Text('SAIR DA CONTA'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}