
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/subscription_service.dart';
import '../../../widgets/shared_widgets.dart';

class StudentSubscriptionTab extends StatelessWidget {
  const StudentSubscriptionTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final subService = SubscriptionService();
    final dateFmt = DateFormat('dd/MM/yyyy');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const SectionTitle('Minha Assinatura'),
        const SizedBox(height: 14),
        StreamBuilder(
          stream: subService.streamDoAluno(auth.usuario!.id),
          builder: (context, snapshot) {
            final assinatura = snapshot.data;
            if (assinatura == null) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Você ainda não possui uma assinatura. Fale com a administração para ativar seu plano.',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
              );
            }

            final ativa = assinatura.status == SubscriptionStatus.ativa;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card do plano atual
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ativa ? AppColors.primary : AppColors.destructive.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: ativa ? null : Border.all(color: AppColors.destructive.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PLANO ATUAL',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2,
                                  color: ativa ? AppColors.primaryForeground.withValues(alpha: 0.7) : AppColors.foreground)),
                          Icon(ativa ? Icons.check_circle : Icons.warning_amber_rounded,
                              size: 18, color: ativa ? AppColors.primaryForeground : AppColors.destructive),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(assinatura.planoNome.toUpperCase(),
                          style: condensed(fontSize: 32, color: ativa ? AppColors.primaryForeground : AppColors.foreground)),
                      Text('R\$ ${assinatura.valor.toStringAsFixed(2)} / mês',
                          style: condensed(
                              fontSize: 18,
                              color: ativa ? AppColors.primaryForeground.withValues(alpha: 0.7) : AppColors.mutedForeground)),
                      const SizedBox(height: 14),
                      Container(height: 1, color: (ativa ? AppColors.primaryForeground : AppColors.foreground).withValues(alpha: 0.15)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Vencimento: ${dateFmt.format(assinatura.proximoVencimento)}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: ativa ? AppColors.primaryForeground.withValues(alpha: 0.7) : AppColors.mutedForeground)),
                          StatusBadge.status(assinatura.status.label),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const SectionTitle('Benefícios'),
        const SizedBox(height: 12),
        ...['Treinos ilimitados', 'Acompanhamento do instrutor', 'Relatórios de progresso', 'Suporte prioritário']
            .map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(p, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
      ],
    );
  }
}
