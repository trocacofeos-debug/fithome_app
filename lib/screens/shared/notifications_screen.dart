// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/shared_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fsService = FirestoreService();
    final uid = context.read<AuthProvider>().usuario!.id;

    return Scaffold(
      appBar: AppBar(
        title: Text('NOTIFICAÇÕES', style: condensed(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => fsService.marcarTodasNotificacoesComoLidas(uid),
            child: const Text('Marcar tudo como lido', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: fsService.streamNotificacoes(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(padding: const EdgeInsets.all(20), child: StreamErrorMessage(erro: snapshot.error));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final notificacoes = snapshot.data!;
          if (notificacoes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none, size: 48, color: AppColors.mutedForeground),
                    SizedBox(height: 12),
                    Text('Nenhuma notificação por aqui ainda.', style: TextStyle(color: AppColors.mutedForeground)),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notificacoes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _NotificationCard(
              notificacao: notificacoes[i],
              onTap: () => _abrir(context, fsService, notificacoes[i]),
            ),
          );
        },
      ),
    );
  }

  void _abrir(BuildContext context, FirestoreService fsService, NotificationModel n) {
    if (!n.lida) fsService.marcarNotificacaoComoLida(n.id);
    if (n.rota != null && n.rota!.isNotEmpty) {
      context.push(n.rota!);
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notificacao;
  final VoidCallback onTap;

  const _NotificationCard({required this.notificacao, required this.onTap});

  IconData get _icone {
    switch (notificacao.tipo) {
      case 'treino_individual':
        return Icons.fitness_center;
      case 'role_alterado':
        return Icons.badge_outlined;
      case 'agendamento':
        return Icons.event_outlined;
      case 'assinatura':
        return Icons.payments_outlined;
      case 'mensagem':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final naoLida = !notificacao.lida;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: naoLida ? AppColors.primary.withOpacity(0.06) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: naoLida ? AppColors.primary.withOpacity(0.25) : AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icone, size: 16, color: naoLida ? AppColors.primary : AppColors.mutedForeground),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notificacao.titulo,
                            style: TextStyle(fontWeight: naoLida ? FontWeight.bold : FontWeight.w600, fontSize: 13)),
                      ),
                      if (naoLida)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(notificacao.mensagem, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                  const SizedBox(height: 6),
                  Text(DateFormat('dd/MM/yyyy HH:mm').format(notificacao.createdAt),
                      style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}