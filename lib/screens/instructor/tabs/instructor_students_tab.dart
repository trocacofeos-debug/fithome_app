import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user_model.dart';
import '../../../models/workout_model.dart';
import '../../../models/workout_progress_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/shared_widgets.dart';

/// Um "aluno do instrutor" é alguém que já concluiu pelo menos um treino
/// criado por ele, ou que recebeu um treino individual dele — não existe
/// (ainda) um cadastro explícito de "matrícula", então essa é a definição
/// prática de vínculo instrutor-aluno usada aqui.
class InstructorStudentsTab extends StatefulWidget {
  const InstructorStudentsTab({super.key});

  @override
  State<InstructorStudentsTab> createState() => _InstructorStudentsTabState();
}

class _InstructorStudentsTabState extends State<InstructorStudentsTab> {
  final _fsService = FirestoreService();
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final instrutorId = auth.usuario!.id;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const SectionTitle('Meus Alunos'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            style: const TextStyle(color: AppColors.foreground, fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Buscar aluno...',
              hintStyle: TextStyle(color: AppColors.mutedForeground),
              prefixIcon: Icon(Icons.search, size: 18, color: AppColors.mutedForeground),
            ),
            onChanged: (v) => setState(() => _busca = v.toLowerCase()),
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder<List<WorkoutModel>>(
          stream: _fsService.streamTreinos(instrutorId: instrutorId),
          builder: (context, treinoSnapshot) {
            if (treinoSnapshot.hasError) {
              return _erroCarregar(treinoSnapshot.error);
            }
            final treinos = treinoSnapshot.data ?? [];
            final idsPorTreinoIndividual = treinos.where((t) => t.isIndividual).map((t) => t.alunoId!).toSet();

            return StreamBuilder<List<WorkoutProgressModel>>(
              stream: _fsService.streamProgressoDoInstrutor(instrutorId),
              builder: (context, progSnapshot) {
                if (progSnapshot.hasError) {
                  return _erroCarregar(progSnapshot.error);
                }
                if (!treinoSnapshot.hasData || !progSnapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.instrutorColor)),
                  );
                }

                final progresso = progSnapshot.data!;
                final contagemPorAluno = <String, int>{};
                final ultimaAtividadePorAluno = <String, DateTime>{};
                for (final p in progresso) {
                  contagemPorAluno[p.alunoId] = (contagemPorAluno[p.alunoId] ?? 0) + 1;
                  final atual = ultimaAtividadePorAluno[p.alunoId];
                  if (atual == null || p.concluidoEm.isAfter(atual)) {
                    ultimaAtividadePorAluno[p.alunoId] = p.concluidoEm;
                  }
                }

                final meusAlunosIds = {...idsPorTreinoIndividual, ...contagemPorAluno.keys};

                if (meusAlunosIds.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Text(
                      'Você ainda não tem alunos vinculados. Isso acontece quando alguém conclui um treino seu ou quando você cria um treino individual para alguém.',
                      style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                    ),
                  );
                }

                return StreamBuilder<List<UserModel>>(
                  stream: _fsService.streamUsuarios(role: UserRole.aluno),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.hasError) {
                      return _erroCarregar(userSnapshot.error);
                    }
                    if (!userSnapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator(color: AppColors.instrutorColor)),
                      );
                    }
                    final meusAlunos = userSnapshot.data!
                        .where((u) => meusAlunosIds.contains(u.id) && u.nome.toLowerCase().contains(_busca))
                        .toList()
                      ..sort((a, b) {
                        final da = ultimaAtividadePorAluno[a.id];
                        final db = ultimaAtividadePorAluno[b.id];
                        if (da == null && db == null) return a.nome.compareTo(b.nome);
                        if (da == null) return 1;
                        if (db == null) return -1;
                        return db.compareTo(da);
                      });

                    if (meusAlunos.isEmpty) {
                      return const Text('Nenhum aluno encontrado.', style: TextStyle(color: AppColors.mutedForeground));
                    }

                    return Column(
                      children: meusAlunos.map((a) {
                        return _AlunoCard(
                          aluno: a,
                          treinosConcluidos: contagemPorAluno[a.id] ?? 0,
                          temTreinoIndividual: idsPorTreinoIndividual.contains(a.id),
                          ultimaAtividade: ultimaAtividadePorAluno[a.id],
                          onTap: () => _abrirDetalheAluno(context, a, contagemPorAluno[a.id] ?? 0, ultimaAtividadePorAluno[a.id]),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _erroCarregar(Object? erro) => StreamErrorMessage(erro: erro, titulo: 'Não foi possível carregar os alunos');

  void _abrirDetalheAluno(BuildContext context, UserModel aluno, int treinosConcluidos, DateTime? ultimaAtividade) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                InitialsAvatar(
                  initials: aluno.nome.isNotEmpty ? aluno.nome.substring(0, 1).toUpperCase() : '?',
                  color: AppColors.instrutorColor,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(aluno.nome, style: condensed(fontSize: 20)),
                      Text(aluno.email, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: StatCard(label: 'Treinos concluídos', value: '$treinosConcluidos', icon: Icons.check_circle_outline)),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Última atividade',
                    value: ultimaAtividade != null ? DateFormat('dd/MM').format(ultimaAtividade) : '—',
                    icon: Icons.event_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/instrutor/novo-treino?alunoId=${aluno.id}&alunoNome=${Uri.encodeComponent(aluno.nome)}');
              },
              icon: const Icon(Icons.fitness_center),
              label: const Text('Criar treino individual'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlunoCard extends StatelessWidget {
  final UserModel aluno;
  final int treinosConcluidos;
  final bool temTreinoIndividual;
  final DateTime? ultimaAtividade;
  final VoidCallback onTap;

  const _AlunoCard({
    required this.aluno,
    required this.treinosConcluidos,
    required this.temTreinoIndividual,
    required this.ultimaAtividade,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(aluno.nome,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      if (temTreinoIndividual) ...[
                        const SizedBox(width: 6),
                        const StatusBadge(label: 'Individual', color: AppColors.instrutorColor),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ultimaAtividade != null
                        ? '$treinosConcluidos treinos · última vez ${DateFormat('dd/MM').format(ultimaAtividade!)}'
                        : (treinosConcluidos > 0 ? '$treinosConcluidos treinos concluídos' : 'Ainda não concluiu treinos'),
                    style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}