// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/referral_commission_model.dart';
import '../../models/subscription_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/referral_service.dart';
import '../../services/subscription_service.dart';
import '../../widgets/shared_widgets.dart';

/// Tela do instrutor para acompanhar quem ele indicou e quanto já ganhou
/// de comissão (R$10/mês por aluno indicado ativo no plano de R$29,99).
class InstructorReferralsScreen extends StatelessWidget {
  final String instrutorId;
  final String instrutorNome;

  const InstructorReferralsScreen({super.key, required this.instrutorId, required this.instrutorNome});

  // Usa a origem atual do navegador (funciona com qualquer domínio em que
  // o app estiver publicado — produção, preview da Vercel, etc) em vez de
  // fixar uma URL, que ficaria errada assim que o domínio mudasse.
  String get _link => '${Uri.base.origin}/cadastro?ref=$instrutorId';

  void _copiar(BuildContext context, String texto, String mensagem) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final fsService = FirestoreService();
    final referralService = ReferralService();
    final subscriptionService = SubscriptionService();

    return Scaffold(
      appBar: AppBar(title: Text('INDICAÇÕES', style: condensed(fontSize: 18))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _cardCodigo(context),
          const SizedBox(height: 20),
          StreamBuilder<List<ReferralCommissionModel>>(
            stream: referralService.streamComissoes(instrutorId),
            builder: (context, comissaoSnapshot) {
              if (comissaoSnapshot.hasError) return StreamErrorMessage(erro: comissaoSnapshot.error);
              final comissoes = comissaoSnapshot.data ?? [];
              final agora = DateTime.now();
              final periodoAtual = '${agora.year}-${agora.month.toString().padLeft(2, '0')}';
              final comissaoMes = comissoes.where((c) => c.periodo == periodoAtual).fold(0.0, (s, c) => s + c.valor);
              final comissaoTotal = comissoes.fold(0.0, (s, c) => s + c.valor);

              return StreamBuilder<List<UserModel>>(
                stream: fsService.streamIndicadosPeloInstrutor(instrutorId),
                builder: (context, alunosSnapshot) {
                  if (alunosSnapshot.hasError) return StreamErrorMessage(erro: alunosSnapshot.error);
                  final indicados = alunosSnapshot.data ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.5,
                        children: [
                          StatCard(
                            label: 'Alunos indicados',
                            value: '${indicados.length}',
                            icon: Icons.people_outline,
                            accent: true,
                            accentColor: AppColors.instrutorColor,
                          ),
                          StatCard(
                            label: 'Comissão este mês',
                            value: 'R\$${comissaoMes.toStringAsFixed(2)}',
                            icon: Icons.calendar_today_outlined,
                          ),
                          StatCard(
                            label: 'Comissão acumulada',
                            value: 'R\$${comissaoTotal.toStringAsFixed(2)}',
                            icon: Icons.savings_outlined,
                          ),
                          const StatCard(
                            label: 'Por aluno ativo',
                            value: 'R\$10,00/mês',
                            icon: Icons.attach_money,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const SectionTitle('Seus indicados'),
                      const SizedBox(height: 12),
                      if (indicados.isEmpty)
                        const Text(
                          'Você ainda não indicou nenhum aluno. Compartilhe seu código ou link '
                          'acima — quando alguém se cadastrar com ele e assinar o plano de R\$29,99, '
                          'você passa a ganhar R\$10 por mês enquanto o aluno continuar ativo.',
                          style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                        )
                      else
                        Column(
                          children: indicados.map((aluno) {
                            return StreamBuilder<SubscriptionModel?>(
                              stream: subscriptionService.streamDoAluno(aluno.id),
                              builder: (context, subSnapshot) {
                                final assinatura = subSnapshot.data;
                                return _AlunoIndicadoCard(aluno: aluno, assinatura: assinatura);
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _cardCodigo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SEU CÓDIGO DE INDICAÇÃO',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.mutedForeground)),
          const SizedBox(height: 4),
          const Text(
            'Compartilhe com quem quiser treinar — ao se cadastrar com esse código e assinar '
            'o plano de R\$29,99, você ganha R\$10 por mês enquanto o aluno estiver ativo.',
            style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    instrutorId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _copiar(context, instrutorId, 'Código copiado!'),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copiar código'),
              ),
            ],
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _link,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _copiar(context, _link, 'Link copiado!'),
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('Copiar link'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AlunoIndicadoCard extends StatelessWidget {
  final UserModel aluno;
  final SubscriptionModel? assinatura;

  const _AlunoIndicadoCard({required this.aluno, required this.assinatura});

  @override
  Widget build(BuildContext context) {
    final ativo = assinatura?.emDia ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          InitialsAvatar(
            initials: aluno.nome.isNotEmpty ? aluno.nome.substring(0, 1).toUpperCase() : '?',
            color: AppColors.instrutorColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(aluno.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  assinatura == null ? 'Sem plano ativo' : assinatura!.planoNome,
                  style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge.status(assinatura?.status.label ?? 'Sem plano'),
              if (ativo) ...[
                const SizedBox(height: 4),
                const Text('+R\$10/mês', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.emerald)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
