// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/exercise_model.dart';
import '../../models/workout_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

enum _Fase { executando, descansando, concluido }

/// Execução guiada do treino: mostra um exercício por vez.
///
/// - Exercícios "por repetições": o aluno toca um botão quando terminar.
/// - Exercícios "por tempo" (prancha, wall-sit etc.): a tela conta
///   regressivamente sozinha, igual o temporizador de descanso, e avança
///   automaticamente quando o tempo acaba.
///
/// Entre um exercício e outro (quando não é o último), entra um
/// temporizador de descanso baseado no `descansoSegundos` cadastrado.
class WorkoutPlayerScreen extends StatefulWidget {
  final WorkoutModel treino;

  const WorkoutPlayerScreen({super.key, required this.treino});

  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen> {
  final _fsService = FirestoreService();

  int _indiceAtual = 0;
  _Fase _fase = _Fase.executando;

  // Reaproveitado tanto para o descanso quanto para a contagem "por tempo"
  // do próprio exercício — só um dos dois roda por vez.
  int _segundosRestantes = 0;
  int _segundosTotal = 1;
  Timer? _timer;

  bool _salvandoConclusao = false;
  String? _erroConclusao;

  List<ExerciseModel> get _exercicios => widget.treino.exercicios;
  ExerciseModel get _exercicioAtual => _exercicios[_indiceAtual];
  bool get _ultimoExercicio => _indiceAtual == _exercicios.length - 1;

  @override
  void initState() {
    super.initState();
    _iniciarExecucaoSeForPorTempo();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Se o exercício atual for "por tempo", começa a contagem regressiva
  /// automaticamente assim que a tela de execução dele é exibida.
  void _iniciarExecucaoSeForPorTempo() {
    final ex = _exercicioAtual;
    if (!ex.porTempo) return;
    final duracao = ex.duracaoSegundos ?? 30;

    setState(() {
      _segundosTotal = duracao;
      _segundosRestantes = duracao;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_segundosRestantes <= 1) {
        t.cancel();
        HapticFeedback.mediumImpact();
        _concluirSerie();
      } else {
        setState(() => _segundosRestantes--);
      }
    });
  }

  void _concluirSerie() {
    _timer?.cancel();
    final descanso = _exercicioAtual.descansoSegundos;
    if (_ultimoExercicio || descanso <= 0) {
      _avancar();
      return;
    }
    setState(() {
      _fase = _Fase.descansando;
      _segundosTotal = descanso;
      _segundosRestantes = descanso;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_segundosRestantes <= 1) {
        t.cancel();
        HapticFeedback.mediumImpact();
        _avancar();
      } else {
        setState(() => _segundosRestantes--);
      }
    });
  }

  void _pular() {
    _timer?.cancel();
    _avancar();
  }

  void _avancar() {
    _timer?.cancel();
    if (_ultimoExercicio) {
      _finalizarTreino();
      return;
    }
    setState(() {
      _indiceAtual++;
      _fase = _Fase.executando;
    });
    _iniciarExecucaoSeForPorTempo();
  }

  Future<void> _finalizarTreino() async {
    setState(() {
      _fase = _Fase.concluido;
      _salvandoConclusao = true;
      _erroConclusao = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      await _fsService.registrarConclusaoTreino(
        alunoId: auth.usuario!.id,
        alunoNome: auth.usuario!.nome,
        treino: widget.treino,
      );
    } catch (e) {
      _erroConclusao = '$e';
    } finally {
      if (mounted) setState(() => _salvandoConclusao = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _fase == _Fase.concluido || (_fase == _Fase.executando && !_exercicioAtual.porTempo),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _fase == _Fase.concluido
            ? null
            : AppBar(
                title: Text('Exercício ${_indiceAtual + 1} de ${_exercicios.length}',
                    style: condensed(fontSize: 16)),
              ),
        body: SafeArea(
          child: switch (_fase) {
            _Fase.executando => _exercicioAtual.porTempo ? _telaExecucaoPorTempo() : _telaExecucaoPorRepeticoes(),
            _Fase.descansando => _telaDescanso(),
            _Fase.concluido => _telaConclusao(),
          },
        ),
      ),
    );
  }

  Widget _telaExecucaoPorRepeticoes() {
    final ex = _exercicioAtual;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _barraProgresso(),
          const SizedBox(height: 24),
          Expanded(child: _gifOuIcone(ex)),
          const SizedBox(height: 24),
          Text(ex.nome.toUpperCase(), textAlign: TextAlign.center, style: condensed(fontSize: 28)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pill('${ex.series} séries'),
              const SizedBox(width: 8),
              _pill('${ex.repeticoes} reps'),
              if (!_ultimoExercicio) ...[
                const SizedBox(width: 8),
                _pill('${ex.descansoSegundos}s descanso'),
              ],
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _concluirSerie,
              child: Text(_ultimoExercicio ? 'FINALIZAR TREINO' : 'CONCLUÍDO, PRÓXIMO'),
            ),
          ),
        ],
      ),
    );
  }

  /// Exercício "por tempo" (prancha etc.) — conta regressivamente sozinho,
  /// igual a tela de descanso, mas antes dela.
  Widget _telaExecucaoPorTempo() {
    final ex = _exercicioAtual;
    final progresso = _segundosTotal == 0 ? 0.0 : _segundosRestantes / _segundosTotal;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _barraProgresso(),
              const SizedBox(height: 20),
              Text(ex.nome.toUpperCase(), textAlign: TextAlign.center, style: condensed(fontSize: 24)),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: progresso,
                        strokeWidth: 10,
                        backgroundColor: AppColors.secondary,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    Text('$_segundosRestantes', style: condensed(fontSize: 64)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('${ex.series > 1 ? "${ex.series} séries · " : ""}segure a posição',
                  textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
              const SizedBox(height: 28),
              OutlinedButton(
                onPressed: _concluirSerie,
                child: Text(_ultimoExercicio ? 'FINALIZAR AGORA' : 'PULAR PARA O DESCANSO'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _telaDescanso() {
    final progresso = _segundosTotal == 0 ? 0.0 : _segundosRestantes / _segundosTotal;
    final proximoExercicio = _ultimoExercicio ? null : _exercicios[_indiceAtual + 1];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('DESCANSO',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedForeground, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: progresso,
                        strokeWidth: 10,
                        backgroundColor: AppColors.secondary,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    Text('$_segundosRestantes', style: condensed(fontSize: 64)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (proximoExercicio != null) ...[
                const Text('A SEGUIR',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(proximoExercicio.nome, style: condensed(fontSize: 22), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: _pular,
                child: const Text('PULAR DESCANSO'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _telaConclusao() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: 24),
              Text('TREINO CONCLUÍDO! 💪', style: condensed(fontSize: 28), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(widget.treino.titulo, style: const TextStyle(color: AppColors.mutedForeground), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              if (_salvandoConclusao)
                const CircularProgressIndicator(color: AppColors.primary)
              else if (_erroConclusao != null)
                Column(
                  children: [
                    Text('Não conseguimos registrar seu progresso: $_erroConclusao',
                        textAlign: TextAlign.center, style: const TextStyle(color: AppColors.destructive, fontSize: 12)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _finalizarTreino, child: const Text('TENTAR DE NOVO')),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('VOLTAR'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barraProgresso() {
    return LinearProgressIndicator(
      value: _indiceAtual / _exercicios.length,
      backgroundColor: AppColors.secondary,
      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
      minHeight: 4,
    );
  }

  Widget _gifOuIcone(ExerciseModel ex) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ex.gifUrl != null
          ? Image.network(ex.gifUrl!, fit: BoxFit.cover, width: double.infinity)
          : Container(
              color: AppColors.card,
              width: double.infinity,
              child: const Icon(Icons.fitness_center, size: 64, color: AppColors.mutedForeground),
            ),
    );
  }

  Widget _pill(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Text(texto, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
    );
  }
}