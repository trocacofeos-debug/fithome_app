import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/subscription_model.dart';
import '../../../services/subscription_service.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/shared_widgets.dart';

class AdminPlansTab extends StatelessWidget {
  const AdminPlansTab({super.key});

  @override
  Widget build(BuildContext context) {
    final subService = SubscriptionService();
    final fsService = FirestoreService();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionTitle('Planos'),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _abrirNovoPlano(context, fsService),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Novo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder(
              stream: fsService.streamPlanos(),
              builder: (context, planSnapshot) {
                final planos = planSnapshot.data ?? [];
                if (planos.isEmpty) {
                  return const Text('Nenhum plano cadastrado ainda.', style: TextStyle(color: AppColors.mutedForeground));
                }
                return StreamBuilder(
                  stream: subService.streamTodas(),
                  builder: (context, subSnapshot) {
                    final assinaturas = subSnapshot.data ?? [];
                    return Column(
                      children: planos.map((plano) {
                        final assinantes = assinaturas
                            .where((a) => a.planoId == plano.id && a.status == SubscriptionStatus.ativa)
                            .length;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(plano.nome.toUpperCase(), style: condensed(fontSize: 24, color: AppColors.adminColor)),
                                          Text('R\$ ${plano.valor.toStringAsFixed(2)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('$assinantes', style: condensed(fontSize: 28, color: AppColors.adminColor)),
                                        const Text('assinantes', style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                                child: Text(
                                  plano.descricao ?? 'Duração: ${plano.duracaoDias} dias',
                                  style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: () => fsService.excluirPlano(plano.id),
                                        style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
                                        icon: const Icon(Icons.delete_outline, size: 15),
                                        label: const Text('Remover', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  void _abrirNovoPlano(BuildContext context, FirestoreService fsService) {
    final nomeCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    final duracaoCtrl = TextEditingController(text: '30');
    final descricaoCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('NOVO PLANO', style: condensed(fontSize: 20)),
              const SizedBox(height: 16),
              TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome do plano')),
              const SizedBox(height: 12),
              TextField(
                controller: valorCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Valor mensal (R\$)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: duracaoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duração (dias)'),
              ),
              const SizedBox(height: 12),
              TextField(controller: descricaoCtrl, decoration: const InputDecoration(labelText: 'Descrição (opcional)')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (nomeCtrl.text.isEmpty || valorCtrl.text.isEmpty) return;
                  await fsService.criarPlano(PlanModel(
                    id: '',
                    nome: nomeCtrl.text,
                    valor: double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0,
                    duracaoDias: int.tryParse(duracaoCtrl.text) ?? 30,
                    descricao: descricaoCtrl.text.isEmpty ? null : descricaoCtrl.text,
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Criar plano'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
