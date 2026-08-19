// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/workout_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/shared_widgets.dart';

const _categorias = ['funcional', 'musculacao', 'hiit', 'alongamento'];

String _rotuloCategoria(String c) {
  switch (c) {
    case 'funcional':
      return 'Funcional';
    case 'musculacao':
      return 'Musculação';
    case 'hiit':
      return 'HIIT';
    case 'alongamento':
      return 'Alongamento';
    default:
      return c;
  }
}

class StudentWorkoutsTab extends StatefulWidget {
  const StudentWorkoutsTab({super.key});

  @override
  State<StudentWorkoutsTab> createState() => _StudentWorkoutsTabState();
}

class _StudentWorkoutsTabState extends State<StudentWorkoutsTab> {
  String _busca = '';
  String? _categoriaFiltro; // null = todas

  // Dia selecionado na agenda semanal — começa em "hoje". "todos" mostra
  // tudo, sem filtrar por dia.
  late String _diaSelecionado = diaDeHoje();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fsService = FirestoreService();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const SectionTitle('Meus Treinos'),
        const SizedBox(height: 14),
        _seletorDiaSemanal(),
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
              _chipCategoria(null, 'Todas'),
              ..._categorias.map((c) => _chipCategoria(c, _rotuloCategoria(c))),
            ],
          ),
        ),
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
            final treinos = _aplicarFiltros(snapshot.data!);
            if (treinos.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  snapshot.data!.isEmpty
                      ? 'Nenhum treino disponível no momento.'
                      : _diaSelecionado != 'todos'
                          ? 'Nenhum treino para ${rotuloDiaDaSemana(_diaSelecionado)}.'
                          : 'Nenhum treino encontrado.',
                  style: const TextStyle(color: AppColors.mutedForeground),
                ),
              );
            }
            return Column(
              children: treinos.map((t) => _WorkoutRow(treino: t)).toList(),
            );
          },
        ),
      ],
    );
  }

  /// Faixa de dias (Hoje + resto da semana) — como uma mini-agenda. Toca
  /// num dia pra ver só os treinos daquele dia; "Todos" tira o filtro.
  Widget _seletorDiaSemanal() {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chipDia('todos', 'Todos', null),
          ...diasDaSemana.map((d) => _chipDia(d, rotuloDiaDaSemana(d).substring(0, 3), d)),
        ],
      ),
    );
  }

  Widget _chipDia(String valor, String label, String? diaReal) {
    final selecionado = _diaSelecionado == valor;
    final ehHoje = diaReal != null && diaReal == diaDeHoje();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _diaSelecionado = valor),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          decoration: BoxDecoration(
            color: selecionado ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selecionado ? AppColors.primary : AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: selecionado ? AppColors.primaryForeground : AppColors.mutedForeground)),
              if (ehHoje) ...[
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selecionado ? AppColors.primaryForeground : AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipCategoria(String? valor, String label) {
    final selecionado = _categoriaFiltro == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selecionado,
        onSelected: (_) => setState(() => _categoriaFiltro = valor),
        selectedColor: AppColors.primary.withOpacity(0.2),
      ),
    );
  }

  List<WorkoutModel> _aplicarFiltros(List<WorkoutModel> treinos) {
    return treinos.where((t) {
      if (_busca.isNotEmpty && !t.titulo.toLowerCase().contains(_busca)) return false;
      if (_categoriaFiltro != null && t.categoria != _categoriaFiltro) return false;
      // Filtro de dia: treinos sem dia fixo (diaDaSemana == null) sempre
      // aparecem, não importa o dia selecionado — só ficam de fora quando
      // um dia específico está marcado E o treino é de outro dia.
      if (_diaSelecionado != 'todos' && t.diaDaSemana != null && t.diaDaSemana != _diaSelecionado) {
        return false;
      }
      return true;
    }).toList();
  }
}

class _WorkoutRow extends StatelessWidget {
  final WorkoutModel treino;

  const _WorkoutRow({required this.treino});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: treino.isIndividual ? AppColors.primary.withOpacity(0.4) : AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: treino.capaUrl != null
                ? Image.network(treino.capaUrl!, width: 40, height: 40, fit: BoxFit.cover)
                : Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.play_arrow, color: AppColors.primary),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(treino.titulo,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.foreground)),
                    ),
                    if (treino.isIndividual) ...[
                      const SizedBox(width: 6),
                      const StatusBadge(label: 'Personalizado', color: AppColors.primary),
                    ],
                    if (treino.diaDaSemana != null) ...[
                      const SizedBox(width: 6),
                      StatusBadge(label: rotuloDiaDaSemana(treino.diaDaSemana!), color: AppColors.mutedForeground),
                    ],
                  ],
                ),
                Text('${_rotuloCategoria(treino.categoria)} · ${treino.duracaoMinutos} min · ${treino.exercicios.length} exercícios',
                    style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
            onPressed: () => context.push('/aluno/treino/${treino.id}'),
            child: const Text('INICIAR'),
          ),
        ],
      ),
    );
  }
}