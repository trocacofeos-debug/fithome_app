// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/workout_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/shared_widgets.dart';

enum _FiltroTreino { todos, publicados, rascunhos, individuais }

class InstructorWorkoutsTab extends StatefulWidget {
  const InstructorWorkoutsTab({super.key});

  @override
  State<InstructorWorkoutsTab> createState() => _InstructorWorkoutsTabState();
}

class _InstructorWorkoutsTabState extends State<InstructorWorkoutsTab> {
  final _fsService = FirestoreService();
  String _busca = '';
  _FiltroTreino _filtro = _FiltroTreino.todos;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return ListView(
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
              hintText: 'Buscar treino...',
              hintStyle: TextStyle(color: AppColors.mutedForeground),
              prefixIcon: Icon(Icons.search, size: 18, color: AppColors.mutedForeground),
            ),
            onChanged: (v) => setState(() => _busca = v.toLowerCase()),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chipFiltro(_FiltroTreino.todos, 'Todos'),
              _chipFiltro(_FiltroTreino.publicados, 'Publicados'),
              _chipFiltro(_FiltroTreino.rascunhos, 'Rascunhos'),
              _chipFiltro(_FiltroTreino.individuais, 'Individuais'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder(
          stream: _fsService.streamTreinos(instrutorId: auth.usuario!.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) return StreamErrorMessage(erro: snapshot.error);
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.instrutorColor)),
              );
            }
            final treinos = _aplicarFiltros(snapshot.data!);
            if (treinos.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Text(
                  snapshot.data!.isEmpty ? 'Você ainda não criou nenhum treino.' : 'Nenhum treino encontrado.',
                  style: const TextStyle(color: AppColors.mutedForeground),
                ),
              );
            }
            return Column(
              children: treinos.map((treino) => _TreinoCard(
                    treino: treino,
                    onEditar: () => context.push('/instrutor/editar-treino/${treino.id}'),
                    onTogglePublicar: () => _fsService.atualizarTreino(treino.id, {'publicado': !treino.publicado}),
                    onDuplicar: () => _duplicar(context, treino),
                    onExcluir: () => _confirmarExclusao(context, treino),
                  )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _chipFiltro(_FiltroTreino valor, String label) {
    final selecionado = _filtro == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selecionado,
        onSelected: (_) => setState(() => _filtro = valor),
        selectedColor: AppColors.instrutorColor.withOpacity(0.2),
      ),
    );
  }

  List<WorkoutModel> _aplicarFiltros(List<WorkoutModel> treinos) {
    return treinos.where((t) {
      if (_busca.isNotEmpty && !t.titulo.toLowerCase().contains(_busca)) return false;
      switch (_filtro) {
        case _FiltroTreino.publicados:
          return t.publicado;
        case _FiltroTreino.rascunhos:
          return !t.publicado;
        case _FiltroTreino.individuais:
          return t.isIndividual;
        case _FiltroTreino.todos:
          return true;
      }
    }).toList();
  }

  Future<void> _duplicar(BuildContext context, WorkoutModel treino) async {
    await _fsService.duplicarTreino(treino);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${treino.titulo}" duplicado como rascunho.')),
      );
    }
  }

  Future<void> _confirmarExclusao(BuildContext context, WorkoutModel treino) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir treino?'),
        content: Text('"${treino.titulo}" será excluído permanentemente. Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await _fsService.excluirTreino(treino.id);
    }
  }
}

class _TreinoCard extends StatelessWidget {
  final WorkoutModel treino;
  final VoidCallback onEditar;
  final VoidCallback onTogglePublicar;
  final VoidCallback onDuplicar;
  final VoidCallback onExcluir;

  const _TreinoCard({
    required this.treino,
    required this.onEditar,
    required this.onTogglePublicar,
    required this.onDuplicar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: treino.capaUrl != null
                    ? Image.network(treino.capaUrl!, width: 48, height: 48, fit: BoxFit.cover)
                    : Container(
                        width: 48,
                        height: 48,
                        color: AppColors.secondary,
                        child: const Icon(Icons.fitness_center, size: 20, color: AppColors.mutedForeground),
                      ),
              ),
              const SizedBox(width: 12),
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
                onSelected: (v) {
                  if (v == 'editar') onEditar();
                  if (v == 'publicar') onTogglePublicar();
                  if (v == 'duplicar') onDuplicar();
                  if (v == 'excluir') onExcluir();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'publicar', child: Text(treino.publicado ? 'Despublicar' : 'Publicar')),
                  const PopupMenuItem(value: 'duplicar', child: Text('Duplicar')),
                  const PopupMenuItem(value: 'excluir', child: Text('Excluir', style: TextStyle(color: AppColors.destructive))),
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
  }
}