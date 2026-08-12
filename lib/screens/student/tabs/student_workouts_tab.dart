// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/shared_widgets.dart';

class StudentWorkoutsTab extends StatelessWidget {
  const StudentWorkoutsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fsService = FirestoreService();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const SectionTitle('Meus Treinos'),
        const SizedBox(height: 14),
        StreamBuilder(
          stream: fsService.streamTreinos(apenasPublicados: true, paraAlunoId: auth.usuario!.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) return StreamErrorMessage(erro: snapshot.error);
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }
            final treinos = snapshot.data!;
            if (treinos.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text('Nenhum treino disponível no momento.', style: TextStyle(color: AppColors.mutedForeground)),
              );
            }
            return Column(
              children: treinos.map((t) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: t.isIndividual ? AppColors.primary.withOpacity(0.4) : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.play_arrow, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(t.titulo,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.foreground)),
                                ),
                                if (t.isIndividual) ...[
                                  const SizedBox(width: 6),
                                  const StatusBadge(label: 'Personalizado', color: AppColors.primary),
                                ],
                              ],
                            ),
                            Text('${t.categoria} · ${t.duracaoMinutos} min · ${t.exercicios.length} exercícios',
                                style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                        onPressed: () => context.push('/aluno/treino/${t.id}'),
                        child: const Text('INICIAR'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}