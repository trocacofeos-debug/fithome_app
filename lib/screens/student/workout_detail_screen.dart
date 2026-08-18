// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/workout_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../shared/gif_viewer_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  final _fsService = FirestoreService();
  bool _concluindo = false;
  bool _concluidoAgora = false;
  late final Future<WorkoutModel> _treinoFuture;

  @override
  void initState() {
    super.initState();
    _treinoFuture = _fsService.getTreino(widget.workoutId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<WorkoutModel>(
        future: _treinoFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final treino = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(treino.titulo),
                  background: treino.capaUrl != null
                      ? Image.network(treino.capaUrl!, fit: BoxFit.cover)
                      : Container(color: AppColors.primary),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(label: Text(treino.categoria)),
                          Chip(label: Text(treino.nivel)),
                          Chip(label: Text('${treino.duracaoMinutos} min')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(treino.descricao, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 20),
                      Text('EXERCÍCIOS', style: condensed(fontSize: 19)),
                      const SizedBox(height: 8),
                      ...treino.exercicios.asMap().entries.map((entry) {
                        final i = entry.key;
                        final ex = entry.value;
                        return Card(
                          child: ListTile(
                            leading: ex.gifUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(ex.gifUrl!, width: 44, height: 44, fit: BoxFit.cover),
                                  )
                                : CircleAvatar(
                                    backgroundColor: AppColors.primary.withOpacity(0.15),
                                    child: Text('${i + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  ),
                            title: Text(ex.nome),
                            subtitle: Text('${ex.series} séries x ${ex.repeticoes} reps · descanso ${ex.descansoSegundos}s'),
                            trailing: ex.gifUrl != null
                                ? const Icon(Icons.open_in_full, size: 18, color: AppColors.primary)
                                : null,
                            onTap: ex.gifUrl != null
                                ? () => _abrirGif(context, ex.gifUrl!, ex.nome)
                                : null,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<WorkoutModel>(
            future: _treinoFuture,
            builder: (context, snapshot) {
              final treino = snapshot.data;
              final concluido = _concluidoAgora;
              return ElevatedButton.icon(
                onPressed: (treino == null || _concluindo || concluido)
                    ? null
                    : () => _concluirTreino(context, treino),
                icon: _concluindo
                    ? const SizedBox(
                        height: 16, width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryForeground))
                    : Icon(concluido ? Icons.check_circle : Icons.check_circle_outline),
                label: Text(concluido ? 'TREINO CONCLUÍDO' : 'CONCLUIR TREINO'),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _concluirTreino(BuildContext context, WorkoutModel treino) async {
    final auth = context.read<AuthProvider>();
    final usuario = auth.usuario;
    if (usuario == null) return;

    setState(() => _concluindo = true);
    try {
      await _fsService.registrarConclusaoTreino(
        alunoId: usuario.id,
        alunoNome: usuario.nome,
        treino: treino,
      );
      if (mounted) {
        setState(() {
          _concluindo = false;
          _concluidoAgora = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Treino registrado no seu progresso 💪'), backgroundColor: AppColors.emerald),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _concluindo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar: $e'), backgroundColor: AppColors.destructive),
        );
      }
    }
  }

  void _abrirGif(BuildContext context, String url, String titulo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GifViewerScreen(gifUrl: url, titulo: titulo),
        fullscreenDialog: true,
      ),
    );
  }
}