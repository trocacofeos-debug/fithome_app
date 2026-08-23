// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/workout_model.dart';
import '../../../models/workout_progress_model.dart';
import '../../../models/appointment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/shared_widgets.dart';
import '../student_schedule_screen.dart';
import '../../chat_screen.dart';

class StudentHomeTab extends StatelessWidget {
  const StudentHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nome = auth.usuario!.nome;
    final alunoId = auth.usuario!.id;
    final fsService = FirestoreService();

    return StreamBuilder<List<WorkoutModel>>(
      stream: fsService.streamTreinos(apenasPublicados: true, paraAlunoId: alunoId),
      builder: (context, treinoSnapshot) {
        if (treinoSnapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [StreamErrorMessage(erro: treinoSnapshot.error)],
          );
        }
        final treinos = treinoSnapshot.data ?? [];

        return StreamBuilder<List<WorkoutProgressModel>>(
          stream: fsService.streamProgressoDoAluno(alunoId),
          builder: (context, progSnapshot) {
            if (progSnapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [StreamErrorMessage(erro: progSnapshot.error)],
              );
            }
            final historico = progSnapshot.data ?? [];
            final sequencia = _calcularSequencia(historico);
            final totalMinutos = historico.fold<int>(0, (soma, p) => soma + p.duracaoMinutos);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_saudacaoPorHorario(),
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.mutedForeground)),
                          const SizedBox(height: 2),
                          Text(nome.split(' ').first.toUpperCase(), style: condensed(fontSize: 34)),
                        ],
                      ),
                    ),
                    if (sequencia > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text('$sequencia ${sequencia == 1 ? 'dia' : 'dias'}', style: condensed(fontSize: 14, color: AppColors.primary)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                if (treinos.isNotEmpty) _cardDestaque(treinos),
                if (treinos.isNotEmpty) const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: StatCard(label: 'Treinos', value: '${historico.length}', icon: Icons.fitness_center)),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(label: 'Sequência', value: '${sequencia}d', icon: Icons.local_fire_department)),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(label: 'Horas', value: _formatarHoras(totalMinutos), icon: Icons.access_time)),
                  ],
                ),
                const SizedBox(height: 20),

                _cardInstrutor(context, fsService, treinos, historico),
                const SizedBox(height: 20),
                _cardProximoCompromisso(context, fsService, alunoId),
              ],
            );
          },
        );
      },
    );
  }

  String _saudacaoPorHorario() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'BOM DIA 👋';
    if (hora < 18) return 'BOA TARDE 👋';
    return 'BOA NOITE 👋';
  }

  int _calcularSequencia(List<WorkoutProgressModel> historico) {
    if (historico.isEmpty) return 0;
    final diasComTreino = historico.map((p) => DateTime(p.concluidoEm.year, p.concluidoEm.month, p.concluidoEm.day)).toSet();

    var cursor = DateTime.now();
    var diaChave = DateTime(cursor.year, cursor.month, cursor.day);
    if (!diasComTreino.contains(diaChave)) {
      diaChave = diaChave.subtract(const Duration(days: 1));
    }

    var sequencia = 0;
    while (diasComTreino.contains(diaChave)) {
      sequencia++;
      diaChave = diaChave.subtract(const Duration(days: 1));
    }
    return sequencia;
  }

  String _formatarHoras(int totalMinutos) {
    final horas = totalMinutos / 60;
    if (totalMinutos == 0) return '0h';
    return totalMinutos % 60 == 0 ? '${horas.toInt()}h' : '${horas.toStringAsFixed(1)}h';
  }

  Widget _cardDestaque(List<WorkoutModel> treinos) {
    final individuais = treinos.where((t) => t.isIndividual).toList();
    final destaque = individuais.isNotEmpty ? individuais.first : treinos.first;
    return Builder(builder: (context) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.card,
                image: destaque.capaUrl != null
                    ? DecorationImage(image: NetworkImage(destaque.capaUrl!), fit: BoxFit.cover)
                    : null,
                gradient: destaque.capaUrl == null
                    ? const LinearGradient(colors: [Color(0xFF242424), Color(0xFF141414)])
                    : null,
              ),
            ),
            Container(
              height: 160,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(destaque.isIndividual ? 'TREINO PERSONALIZADO' : 'TREINO DE HOJE',
                            style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                        Text(destaque.titulo.toUpperCase(),
                            style: condensed(fontSize: 22, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${destaque.duracaoMinutos} min · ${destaque.exercicios.length} exercícios',
                            style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/aluno/treino/${destaque.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow, color: AppColors.primaryForeground, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _cardInstrutor(
    BuildContext context,
    FirestoreService fsService,
    List<WorkoutModel> treinos,
    List<WorkoutProgressModel> historico,
  ) {
    final individuais = treinos.where((t) => t.isIndividual).toList();
    if (individuais.isNotEmpty) {
      return _instrutorCard(context, individuais.first.instrutorId, individuais.first.instrutorNome);
    }

    if (historico.isNotEmpty) {
      final contagem = <String, int>{};
      for (final p in historico) {
        contagem[p.instrutorId] = (contagem[p.instrutorId] ?? 0) + 1;
      }
      final instrutorIdMaisAtivo = contagem.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      return StreamBuilder(
        stream: fsService.streamUsuarios(role: UserRole.instrutor),
        builder: (context, snapshot) {
          final instrutores = snapshot.data ?? [];
          final match = instrutores.where((i) => i.id == instrutorIdMaisAtivo);
          if (match.isEmpty) return const SizedBox.shrink();
          return _instrutorCard(context, match.first.id, match.first.nome);
        },
      );
    }

    return StreamBuilder(
      stream: fsService.streamUsuarios(role: UserRole.instrutor),
      builder: (context, snapshot) {
        final instrutores = snapshot.data ?? [];
        if (instrutores.isEmpty) return const SizedBox.shrink();
        return _instrutorCard(context, instrutores.first.id, instrutores.first.nome);
      },
    );
  }

  Widget _instrutorCard(BuildContext context, String instrutorId, String nomeInstrutor) {
    final iniciais = nomeInstrutor.isNotEmpty ? nomeInstrutor.substring(0, 1).toUpperCase() : '?';
    final auth = context.read<AuthProvider>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          InitialsAvatar(initials: iniciais, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SEU INSTRUTOR',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.mutedForeground)),
                Text(nomeInstrutor, style: condensed(fontSize: 16)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  instrutorId: instrutorId,
                  instrutorNome: nomeInstrutor,
                  alunoId: auth.usuario!.id,
                  alunoNome: auth.usuario!.nome,
                  meuId: auth.usuario!.id,
                  meuNome: auth.usuario!.nome,
                  souInstrutor: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardProximoCompromisso(BuildContext context, FirestoreService fsService, String alunoId) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: fsService.streamAgendaDoAluno(alunoId),
      builder: (context, snapshot) {
        final agora = DateTime.now();
        final proximos = (snapshot.data ?? [])
            .where((a) => a.dataHora.isAfter(agora) && a.status == AppointmentStatus.agendado)
            .toList()
          ..sort((a, b) => a.dataHora.compareTo(b.dataHora));

        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentScheduleScreen())),
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
                  child: const Icon(Icons.event_outlined, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MINHA AGENDA',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.mutedForeground)),
                      Text(
                        proximos.isEmpty
                            ? 'Nenhum compromisso agendado'
                            : '${proximos.first.tipo} · ${proximos.first.dataHora.day}/${proximos.first.dataHora.month}',
                        style: condensed(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
              ],
            ),
          ),
        );
      },
    );
  }
}