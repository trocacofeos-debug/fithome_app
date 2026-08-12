import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/shared_widgets.dart';

class InstructorWorkoutsTab extends StatelessWidget {
  const InstructorWorkoutsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fsService = FirestoreService();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionTitle('Treinos Criados'),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.instrutorColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => context.push('/instrutor/novo-treino'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Novo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            StreamBuilder(
              stream: fsService.streamTreinos(instrutorId: auth.usuario!.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) return StreamErrorMessage(erro: snapshot.error);
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.instrutorColor)),
                  );
                }
                final treinos = snapshot.data!;
                if (treinos.isEmpty) {
                  return const Text('Você ainda não criou nenhum treino.', style: TextStyle(color: AppColors.mutedForeground));
                }
                return Column(
                  children: treinos.map((treino) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(treino.titulo, style: condensed(fontSize: 17)),
                                    Text('${treino.duracaoMinutos} min · ${treino.nivel}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                                    if (treino.isIndividual) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 12, color: AppColors.instrutorColor),
                                          const SizedBox(width: 4),
                                          Text('Individual · ${treino.alunoNome}',
                                              style: const TextStyle(fontSize: 11, color: AppColors.instrutorColor, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                color: AppColors.card,
                                icon: const Icon(Icons.more_vert, color: AppColors.mutedForeground, size: 18),
                                onSelected: (v) async {
                                  if (v == 'editar') {
                                    context.push('/instrutor/editar-treino/${treino.id}');
                                  } else if (v == 'publicar') {
                                    await fsService.atualizarTreino(treino.id, {'publicado': !treino.publicado});
                                  } else if (v == 'excluir') {
                                    await fsService.excluirTreino(treino.id);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'editar', child: Text('Editar')),
                                  PopupMenuItem(value: 'publicar', child: Text(treino.publicado ? 'Despublicar' : 'Publicar')),
                                  const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(height: 1, color: AppColors.border),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.fitness_center, size: 13, color: AppColors.mutedForeground),
                              const SizedBox(width: 6),
                              Text('${treino.exercicios.length} exercícios',
                                  style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                              const Spacer(),
                              StatusBadge(
                                label: treino.publicado ? 'Publicado' : 'Rascunho',
                                color: treino.publicado ? AppColors.emerald : AppColors.mutedForeground,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}