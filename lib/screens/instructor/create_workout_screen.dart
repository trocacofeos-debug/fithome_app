// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/exercise_model.dart';
import '../../models/workout_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/r2_storage_service.dart';
import '../../core/constants/app_constants.dart';

class CreateWorkoutScreen extends StatefulWidget {
  final String? workoutId; // se preenchido, é edição
  final String? presetAlunoId; // pré-seleciona destinatário individual
  final String? presetAlunoNome;

  const CreateWorkoutScreen({
    super.key,
    this.workoutId,
    this.presetAlunoId,
    this.presetAlunoNome,
  });

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final _fsService = FirestoreService();
  final _storageService = R2StorageService();
  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _duracaoCtrl = TextEditingController(text: '30');

  String _nivel = 'iniciante';
  String _categoria = 'funcional';
  File? _capaLocal;
  String? _capaUrlExistente;
  bool _salvando = false;

  // Destinatário do treino: null = geral (todos os alunos), preenchido =
  // individual (só aquele aluno vê).
  String? _alunoId;
  String? _alunoNome;

  final List<_ExercicioForm> _exercicios = [];

  @override
  void initState() {
    super.initState();
    if (widget.workoutId != null) {
      _carregarTreinoExistente();
    } else if (widget.presetAlunoId != null) {
      _alunoId = widget.presetAlunoId;
      _alunoNome = widget.presetAlunoNome;
    }
  }

  Future<void> _carregarTreinoExistente() async {
    final treino = await _fsService.getTreino(widget.workoutId!);
    setState(() {
      _tituloCtrl.text = treino.titulo;
      _descricaoCtrl.text = treino.descricao;
      _duracaoCtrl.text = treino.duracaoMinutos.toString();
      _nivel = treino.nivel;
      _categoria = treino.categoria;
      _capaUrlExistente = treino.capaUrl;
      _alunoId = treino.alunoId;
      _alunoNome = treino.alunoNome;
      _exercicios.addAll(treino.exercicios.map((e) => _ExercicioForm.fromModel(e)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.workoutId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar treino' : 'Novo treino', style: condensed(fontSize: 18)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _seletorCapa(),
            const SizedBox(height: 16),
            _seletorDestinatario(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(labelText: 'Título do treino'),
              validator: (v) => (v == null || v.isEmpty) ? 'Informe um título' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricaoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _nivel,
                    decoration: const InputDecoration(labelText: 'Nível'),
                    items: const [
                      DropdownMenuItem(value: 'iniciante', child: Text('Iniciante')),
                      DropdownMenuItem(value: 'intermediario', child: Text('Intermediário')),
                      DropdownMenuItem(value: 'avancado', child: Text('Avançado')),
                    ],
                    onChanged: (v) => setState(() => _nivel = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _categoria,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: const [
                      DropdownMenuItem(value: 'funcional', child: Text('Funcional')),
                      DropdownMenuItem(value: 'musculacao', child: Text('Musculação')),
                      DropdownMenuItem(value: 'hiit', child: Text('HIIT')),
                      DropdownMenuItem(value: 'alongamento', child: Text('Alongamento')),
                    ],
                    onChanged: (v) => setState(() => _categoria = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _duracaoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Duração estimada (minutos)'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('EXERCÍCIOS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.mutedForeground)),
                TextButton.icon(
                  onPressed: () => setState(() => _exercicios.add(_ExercicioForm())),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._exercicios.asMap().entries.map((entry) => _cardExercicio(entry.key, entry.value)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryForeground))
                  : Text(editando ? 'Salvar alterações' : 'Criar treino'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seletorDestinatario() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PARA QUEM É ESSE TREINO?',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.mutedForeground)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _opcaoDestinatario(
                  selecionado: _alunoId == null,
                  icone: Icons.groups_outlined,
                  titulo: 'Geral',
                  subtitulo: 'Todos os alunos',
                  onTap: () => setState(() {
                    _alunoId = null;
                    _alunoNome = null;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _opcaoDestinatario(
                  selecionado: _alunoId != null,
                  icone: Icons.person_outline,
                  titulo: 'Individual',
                  subtitulo: _alunoNome ?? 'Escolher aluno',
                  onTap: _escolherAlunoIndividual,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _opcaoDestinatario({
    required bool selecionado,
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selecionado ? AppColors.instrutorColor.withOpacity(0.12) : AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selecionado ? AppColors.instrutorColor : Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 18, color: selecionado ? AppColors.instrutorColor : AppColors.mutedForeground),
            const SizedBox(height: 6),
            Text(titulo, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: selecionado ? AppColors.instrutorColor : AppColors.foreground)),
            const SizedBox(height: 2),
            Text(subtitulo,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
          ],
        ),
      ),
    );
  }

  void _escolherAlunoIndividual() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StreamBuilder<List<UserModel>>(
        stream: _fsService.streamUsuarios(role: UserRole.aluno),
        builder: (context, snapshot) {
          final alunos = snapshot.data ?? [];
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('ESCOLHER ALUNO', style: condensed(fontSize: 18)),
                  const SizedBox(height: 12),
                  if (!snapshot.hasData)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator(color: AppColors.instrutorColor)),
                    )
                  else if (alunos.isEmpty)
                    const Text('Nenhum aluno cadastrado ainda.', style: TextStyle(color: AppColors.mutedForeground))
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: alunos.length,
                        itemBuilder: (context, i) {
                          final a = alunos[i];
                          return ListTile(
                            title: Text(a.nome),
                            subtitle: Text(a.email, style: const TextStyle(fontSize: 11)),
                            onTap: () {
                              setState(() {
                                _alunoId = a.id;
                                _alunoNome = a.nome;
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _seletorCapa() {
    return GestureDetector(
      onTap: _escolherCapa,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          image: _capaLocal != null
              ? DecorationImage(image: FileImage(_capaLocal!), fit: BoxFit.cover)
              : (_capaUrlExistente != null
                  ? DecorationImage(image: NetworkImage(_capaUrlExistente!), fit: BoxFit.cover)
                  : null),
        ),
        child: (_capaLocal == null && _capaUrlExistente == null)
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.textSecondary),
                    SizedBox(height: 8),
                    Text('Adicionar capa do treino'),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Future<void> _escolherCapa() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _capaLocal = File(img.path));
  }

  Widget _cardExercicio(int index, _ExercicioForm ex) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: ex.nomeCtrl,
                    decoration: const InputDecoration(labelText: 'Nome do exercício'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  onPressed: () => setState(() => _exercicios.removeAt(index)),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: ex.seriesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Séries'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: ex.repeticoesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Repetições'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: ex.descansoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Descanso (s)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final picker = ImagePicker();
                final video = await picker.pickVideo(source: ImageSource.gallery);
                if (video != null) setState(() => ex.videoLocal = File(video.path));
              },
              icon: const Icon(Icons.videocam_outlined),
              label: Text(ex.videoLocal != null || ex.videoUrlExistente != null
                  ? 'Vídeo selecionado ✓'
                  : 'Adicionar vídeo demonstrativo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exercicios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione ao menos um exercício.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _salvando = true);
    final auth = context.read<AuthProvider>();

    try {
      String? capaUrl = _capaUrlExistente;
      if (_capaLocal != null) {
        capaUrl = await _storageService.upload(arquivo: _capaLocal!, pasta: 'workouts');
      }

      final exerciciosModel = <ExerciseModel>[];
      for (final ex in _exercicios) {
        String? videoUrl = ex.videoUrlExistente;
        if (ex.videoLocal != null) {
          videoUrl = await _storageService.upload(arquivo: ex.videoLocal!, pasta: 'exercises');
        }
        exerciciosModel.add(ExerciseModel(
          id: ex.id,
          nome: ex.nomeCtrl.text,
          series: int.tryParse(ex.seriesCtrl.text) ?? 3,
          repeticoes: int.tryParse(ex.repeticoesCtrl.text) ?? 12,
          descansoSegundos: int.tryParse(ex.descansoCtrl.text) ?? 60,
          videoUrl: videoUrl,
        ));
      }

      final treino = WorkoutModel(
        id: widget.workoutId ?? '',
        titulo: _tituloCtrl.text,
        descricao: _descricaoCtrl.text,
        instrutorId: auth.usuario!.id,
        instrutorNome: auth.usuario!.nome,
        nivel: _nivel,
        categoria: _categoria,
        capaUrl: capaUrl,
        exercicios: exerciciosModel,
        duracaoMinutos: int.tryParse(_duracaoCtrl.text) ?? 30,
        createdAt: DateTime.now(),
        alunoId: _alunoId,
        alunoNome: _alunoNome,
      );

      if (widget.workoutId != null) {
        await _fsService.atualizarTreino(widget.workoutId!, treino.toMap());
      } else {
        await _fsService.criarTreino(treino);
      }

      if (mounted) context.go('/instrutor');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
}

class _ExercicioForm {
  final String id;
  final nomeCtrl = TextEditingController();
  final seriesCtrl = TextEditingController(text: '3');
  final repeticoesCtrl = TextEditingController(text: '12');
  final descansoCtrl = TextEditingController(text: '60');
  File? videoLocal;
  String? videoUrlExistente;

  _ExercicioForm() : id = const Uuid().v4();

  _ExercicioForm.fromModel(ExerciseModel e) : id = e.id {
    nomeCtrl.text = e.nome;
    seriesCtrl.text = e.series.toString();
    repeticoesCtrl.text = e.repeticoes.toString();
    descansoCtrl.text = e.descansoSegundos.toString();
    videoUrlExistente = e.videoUrl;
  }
}