// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import '../../widgets/shared_widgets.dart';

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
  Uint8List? _capaBytes;
  String? _capaNomeArquivo;
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
                    initialValue: _nivel,
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
                    initialValue: _categoria,
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
            if (_exercicios.length > 1)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Arraste pelo ícone ⠿ para reordenar',
                    style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
              ),
            const SizedBox(height: 8),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _exercicios.removeAt(oldIndex);
                  _exercicios.insert(newIndex, item);
                });
              },
              children: [
                for (int i = 0; i < _exercicios.length; i++)
                  _cardExercicio(i, _exercicios[i], key: ValueKey(_exercicios[i].id)),
              ],
            ),
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
          if (snapshot.hasError) {
            return SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: StreamErrorMessage(erro: snapshot.error)));
          }
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
          image: _capaBytes != null
              ? DecorationImage(image: MemoryImage(_capaBytes!), fit: BoxFit.cover)
              : (_capaUrlExistente != null
                  ? DecorationImage(image: NetworkImage(_capaUrlExistente!), fit: BoxFit.cover)
                  : null),
        ),
        child: (_capaBytes == null && _capaUrlExistente == null)
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
    if (img == null) return;
    final bytes = await img.readAsBytes();
    setState(() {
      _capaBytes = bytes;
      _capaNomeArquivo = img.name;
    });
  }

  Future<void> _escolherGif(_ExercicioForm ex) async {
    final picker = ImagePicker();
    final arquivo = await picker.pickImage(source: ImageSource.gallery);
    if (arquivo == null) return;

    final extensao = arquivo.name.contains('.') ? arquivo.name.split('.').last.toLowerCase() : '';
    if (extensao != 'gif') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escolha um arquivo .gif — outros formatos de imagem não animam.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    final bytes = await arquivo.readAsBytes();
    setState(() {
      ex.gifBytes = bytes;
      ex.gifNomeArquivo = arquivo.name;
    });
  }

  Widget _cardExercicio(int index, _ExercicioForm ex, {required Key key}) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.drag_indicator, color: AppColors.mutedForeground),
                  ),
                ),
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
            const SizedBox(height: 10),
            // Alterna entre "por repetições" e "por tempo" (ex: prancha)
            Row(
              children: [
                Expanded(
                  child: _chipTipo(
                    selecionado: ex.tipo == 'repeticoes',
                    label: 'Repetições',
                    icone: Icons.repeat,
                    onTap: () => setState(() => ex.tipo = 'repeticoes'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _chipTipo(
                    selecionado: ex.tipo == 'tempo',
                    label: 'Por tempo',
                    icone: Icons.timer_outlined,
                    onTap: () => setState(() => ex.tipo = 'tempo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (ex.tipo == 'repeticoes')
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
              )
            else
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
                      controller: ex.duracaoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Duração (s)', hintText: 'ex: 30'),
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
            if (ex.gifBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(ex.gifBytes!, height: 100, fit: BoxFit.cover, width: double.infinity),
              )
            else if (ex.gifUrlExistente != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(ex.gifUrlExistente!, height: 100, fit: BoxFit.cover, width: double.infinity),
              ),
            if (ex.gifBytes != null || ex.gifUrlExistente != null) const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _escolherGif(ex),
              icon: const Icon(Icons.gif_box_outlined),
              label: Text(ex.gifBytes != null || ex.gifUrlExistente != null
                  ? 'Trocar GIF demonstrativo'
                  : 'Adicionar GIF demonstrativo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipTipo({required bool selecionado, required String label, required IconData icone, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selecionado ? AppColors.primary.withOpacity(0.15) : AppColors.secondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selecionado ? AppColors.primary : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 15, color: selecionado ? AppColors.primary : AppColors.mutedForeground),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selecionado ? AppColors.primary : AppColors.mutedForeground)),
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
      if (_capaBytes != null) {
        capaUrl = await _storageService.upload(
          bytes: _capaBytes!,
          nomeOriginal: _capaNomeArquivo ?? 'capa.jpg',
          pasta: 'workouts',
        );
      }

      final exerciciosModel = <ExerciseModel>[];
      for (final ex in _exercicios) {
        String? gifUrl = ex.gifUrlExistente;
        if (ex.gifBytes != null) {
          gifUrl = await _storageService.upload(
            bytes: ex.gifBytes!,
            nomeOriginal: ex.gifNomeArquivo ?? 'exercicio.gif',
            pasta: 'exercises',
          );
        }
        exerciciosModel.add(ExerciseModel(
          id: ex.id,
          nome: ex.nomeCtrl.text,
          tipo: ex.tipo,
          series: int.tryParse(ex.seriesCtrl.text) ?? 3,
          repeticoes: int.tryParse(ex.repeticoesCtrl.text) ?? 12,
          duracaoSegundos: ex.tipo == 'tempo' ? (int.tryParse(ex.duracaoCtrl.text) ?? 30) : null,
          descansoSegundos: int.tryParse(ex.descansoCtrl.text) ?? 60,
          gifUrl: gifUrl,
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
        final novoId = await _fsService.criarTreino(treino);
        if (treino.isIndividual) {
          await _fsService.criarNotificacao(
            userId: treino.alunoId!,
            titulo: 'Novo treino personalizado',
            mensagem: '${treino.instrutorNome} criou o treino "${treino.titulo}" especialmente para você.',
            tipo: 'treino_individual',
            rota: '/aluno/treino/$novoId',
          );
        }
      }

      if (mounted) Navigator.of(context).pop();
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
  final duracaoCtrl = TextEditingController(text: '30');
  final descansoCtrl = TextEditingController(text: '60');
  String tipo = 'repeticoes';
  Uint8List? gifBytes;
  String? gifNomeArquivo;
  String? gifUrlExistente;

  _ExercicioForm() : id = const Uuid().v4();

  _ExercicioForm.fromModel(ExerciseModel e) : id = e.id {
    nomeCtrl.text = e.nome;
    tipo = e.tipo;
    seriesCtrl.text = e.series.toString();
    repeticoesCtrl.text = e.repeticoes.toString();
    duracaoCtrl.text = (e.duracaoSegundos ?? 30).toString();
    descansoCtrl.text = e.descansoSegundos.toString();
    gifUrlExistente = e.gifUrl;
  }
}