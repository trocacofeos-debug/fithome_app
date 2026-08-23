import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/workout_progress_model.dart';
import '../../../models/workout_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/shared_widgets.dart';
import '../instructor_chats_list_screen.dart';

class InstructorHomeTab extends StatelessWidget {
  const InstructorHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fsService = FirestoreService();
    final instrutorId = auth.usuario!.id;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const Text('PAINEL DO INSTRUTOR',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.mutedForeground)),
        const SizedBox(height: 2),
        Text(auth.usuario!.nome.toUpperCase(), style: condensed(fontSize: 30)),
        const SizedBox(height: 18),

        _cardMensagens(context, instrutorId, auth.usuario!.nome),
        const SizedBox(height: 20),

        StreamBuilder(
          stream: fsService.streamTreinos(instrutorId: instrutorId),
          builder: (context, treinoSnapshot) {
            if (treinoSnapshot.hasError) return StreamErrorMessage(erro: treinoSnapshot.error);
            final treinos = treinoSnapshot.data ?? [];

            return StreamBuilder(
              stream: fsService.streamProgressoDoInstrutor(instrutorId),
              builder: (context, progressoSnapshot) {
                if (progressoSnapshot.hasError) return StreamErrorMessage(erro: progressoSnapshot.error);
                final progresso = progressoSnapshot.data ?? [];
                final agora = DateTime.now();
                final sessoesNoMes = progresso
                    .where((p) => p.concluidoEm.year == agora.year && p.concluidoEm.month == agora.month)
                    .length;

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
                        StatCard(label: 'Treinos criados', value: '${treinos.length}', icon: Icons.fitness_center, accent: true, accentColor: AppColors.instrutorColor),
                        StatCard(label: 'Publicados', value: '${treinos.where((t) => t.publicado).length}', icon: Icons.visibility_outlined),
                        StatCard(label: 'Sessões no mês', value: '$sessoesNoMes', icon: Icons.play_circle_outline),
                        StatCard(label: 'Total concluído', value: '${progresso.length}', icon: Icons.emoji_events_outlined),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _cardProgressoAlunos(context, fsService, treinos, progresso),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _cardMensagens(BuildContext context, String meuId, String meuNome) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => InstructorChatsListScreen(meuId: meuId, meuNome: meuNome)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.chat_bubble_outline, color: AppColors.instrutorColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MENSAGENS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.mutedForeground)),
                  Text('Falar com seus alunos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }

  /// Card "Progresso dos Alunos": para cada um dos seus alunos mais ativos
  /// recentemente, mostra uma barra com a % de dias, dos últimos 7, em que
  /// ele concluiu pelo menos um treino — calculado a partir do histórico
  /// verdadeiro de `workout_progress`.
  Widget _cardProgressoAlunos(
    BuildContext context,
    FirestoreService fsService,
    List<WorkoutModel> treinos,
    List<WorkoutProgressModel> progresso,
  ) {
    final idsPorTreinoIndividual = treinos.where((t) => t.isIndividual).map((t) => t.alunoId!).toSet();
    final meusAlunosIds = {...idsPorTreinoIndividual, ...progresso.map((p) => p.alunoId)};

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
          const Text('PROGRESSO DOS ALUNOS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.mutedForeground)),
          const SizedBox(height: 4),
          const Text('% de dias ativos nos últimos 7 dias',
              style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
          const SizedBox(height: 12),
          if (meusAlunosIds.isEmpty)
            const Text('Nenhum aluno vinculado ainda.', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12))
          else
            StreamBuilder(
              stream: fsService.streamUsuarios(role: UserRole.aluno),
              builder: (context, snapshot) {
                if (snapshot.hasError) return StreamErrorMessage(erro: snapshot.error);
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator(color: AppColors.instrutorColor)),
                  );
                }

                final agora = DateTime.now();
                final seteDiasAtras = agora.subtract(const Duration(days: 7));

                final diasAtivosPorAluno = <String, Set<String>>{};
                for (final p in progresso) {
                  if (p.concluidoEm.isBefore(seteDiasAtras)) continue;
                  final chaveDia = '${p.concluidoEm.year}-${p.concluidoEm.month}-${p.concluidoEm.day}';
                  diasAtivosPorAluno.putIfAbsent(p.alunoId, () => {}).add(chaveDia);
                }

                final alunos = snapshot.data!.where((u) => meusAlunosIds.contains(u.id)).toList()
                  ..sort((a, b) {
                    final da = diasAtivosPorAluno[a.id]?.length ?? 0;
                    final db = diasAtivosPorAluno[b.id]?.length ?? 0;
                    return db.compareTo(da);
                  });
                final top4 = alunos.take(4).toList();

                if (top4.isEmpty) {
                  return const Text('Nenhum aluno vinculado ainda.', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12));
                }

                return Column(
                  children: top4.map((a) {
                    final diasAtivos = diasAtivosPorAluno[a.id]?.length ?? 0;
                    final percentual = ((diasAtivos / 7) * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          InitialsAvatar(
                            initials: a.nome.isNotEmpty ? a.nome.substring(0, 1).toUpperCase() : '?',
                            size: 30,
                            color: AppColors.instrutorColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(a.nome, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text('$percentual%',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.instrutorColor)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: percentual / 100,
                                    minHeight: 5,
                                    backgroundColor: AppColors.secondary,
                                    valueColor: const AlwaysStoppedAnimation(AppColors.instrutorColor),
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
            ),
        ],
      ),
    );
  }
}