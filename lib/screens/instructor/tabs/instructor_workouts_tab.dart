// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/workout_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/shared_widgets.dart';
import '../instructor_workouts_by_group_screen.dart';

/// Em vez de uma lista única de treinos, mostra os alunos que têm treino
/// individual (mais um grupo "Geral" para os treinos sem dono específico)
/// — tocando num aluno, mostra só os treinos dele.
class InstructorWorkoutsTab extends StatefulWidget {
  const InstructorWorkoutsTab({super.key});

  @override
  State<InstructorWorkoutsTab> createState() => _InstructorWorkoutsTabState();
}

class _InstructorWorkoutsTabState extends State<InstructorWorkoutsTab> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fsService = FirestoreService();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionTitle('Treinos'),
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
        const SizedBox(height: 12),
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
            final geral = treinos.where((t) => !t.isIndividual).toList();

            final porAluno = <String, List<WorkoutModel>>{};
            final nomePorAluno = <String, String>{};
            for (final t in treinos.where((t) => t.isIndividual)) {
              porAluno.putIfAbsent(t.alunoId!, () => []).add(t);
              nomePorAluno[t.alunoId!] = t.alunoNome ?? 'Aluno';
            }
            final alunosOrdenados = porAluno.keys.toList()
              ..sort((a, b) => (nomePorAluno[a] ?? '').compareTo(nomePorAluno[b] ?? ''));

            // Aplica a busca por nome (não filtra "Geral", que não tem nome de aluno)
            final alunosFiltrados = _busca.isEmpty
                ? alunosOrdenados
                : alunosOrdenados.where((id) => (nomePorAluno[id] ?? '').toLowerCase().contains(_busca)).toList();

            if (treinos.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Text('Você ainda não criou nenhum treino.', style: TextStyle(color: AppColors.mutedForeground)),
              );
            }

            return Column(
              children: [
                if ('geral'.contains(_busca) || _busca.isEmpty)
                  _GrupoCard(
                    titulo: 'Geral',
                    subtitulo: 'Visível para todos os alunos',
                    icone: Icons.groups_outlined,
                    corIcone: AppColors.primary,
                    quantidade: geral.length,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InstructorWorkoutsByGroupScreen(alunoId: null, tituloGrupo: 'Geral'),
                      ),
                    ),
                  ),
                ...alunosFiltrados.map((alunoId) => _GrupoCard(
                      titulo: nomePorAluno[alunoId]!,
                      subtitulo: 'Treinos individuais',
                      icone: Icons.person_outline,
                      corIcone: AppColors.instrutorColor,
                      quantidade: porAluno[alunoId]!.length,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InstructorWorkoutsByGroupScreen(alunoId: alunoId, tituloGrupo: nomePorAluno[alunoId]!),
                        ),
                      ),
                    )),
                if (alunosFiltrados.isEmpty && _busca.isNotEmpty && !'geral'.contains(_busca))
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text('Nenhum aluno encontrado.', style: TextStyle(color: AppColors.mutedForeground)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GrupoCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final Color corIcone;
  final int quantidade;
  final VoidCallback onTap;

  const _GrupoCard({
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.corIcone,
    required this.quantidade,
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: corIcone.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icone, color: corIcone, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitulo, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20)),
              child: Text('$quantidade', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}