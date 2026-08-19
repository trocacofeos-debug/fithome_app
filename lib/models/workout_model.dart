import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import 'exercise_model.dart';

/// Dias da semana válidos para o campo diaDaSemana, na ordem
/// segunda→domingo (bate com DateTime.weekday: 1=segunda...7=domingo).
const diasDaSemana = ['segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado', 'domingo'];

String rotuloDiaDaSemana(String dia) {
  switch (dia) {
    case 'segunda':
      return 'Segunda';
    case 'terca':
      return 'Terça';
    case 'quarta':
      return 'Quarta';
    case 'quinta':
      return 'Quinta';
    case 'sexta':
      return 'Sexta';
    case 'sabado':
      return 'Sábado';
    case 'domingo':
      return 'Domingo';
    default:
      return dia;
  }
}

/// Chave (mesmo formato de [diasDaSemana]) do dia de hoje.
String diaDeHoje() => diasDaSemana[DateTime.now().weekday - 1];

class WorkoutModel {
  final String id;
  final String titulo;
  final String descricao;
  final String instrutorId;
  final String instrutorNome;
  final String nivel; // iniciante, intermediario, avancado
  final String categoria; // funcional, musculacao, hiit, alongamento...
  final String? capaUrl;
  final List<ExerciseModel> exercicios;
  final int duracaoMinutos;
  final DateTime createdAt;
  final bool publicado;

  /// Se preenchido, este treino é individual — só aparece para este aluno
  /// específico (além do próprio instrutor e do admin). Se for null, é um
  /// treino geral, visível para todos os alunos assinantes.
  final String? alunoId;
  final String? alunoNome;

  /// Dia da semana em que esse treino deve ser feito (ex: 'segunda').
  /// Null significa "sem dia fixo" — continua aparecendo todo dia na
  /// lista geral, só não some quando o aluno filtra por um dia específico.
  final String? diaDaSemana;

  WorkoutModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.instrutorId,
    required this.instrutorNome,
    required this.nivel,
    required this.categoria,
    this.capaUrl,
    required this.exercicios,
    required this.duracaoMinutos,
    required this.createdAt,
    this.publicado = true,
    this.alunoId,
    this.alunoNome,
    this.diaDaSemana,
  });

  bool get isIndividual => alunoId != null;

  factory WorkoutModel.fromMap(String id, Map<String, dynamic> map) {
    return WorkoutModel(
      id: id,
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'] ?? '',
      instrutorId: map['instrutorId'] ?? '',
      instrutorNome: map['instrutorNome'] ?? '',
      nivel: map['nivel'] ?? 'iniciante',
      categoria: map['categoria'] ?? 'funcional',
      capaUrl: map['capaUrl'],
      exercicios: ((map['exercicios'] ?? []) as List)
          .map((e) => ExerciseModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      duracaoMinutos: map['duracaoMinutos'] ?? 30,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      publicado: lerBoolFirestore(map['publicado'], padrao: true),
      alunoId: map['alunoId'],
      alunoNome: map['alunoNome'],
      diaDaSemana: map['diaDaSemana'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descricao': descricao,
      'instrutorId': instrutorId,
      'instrutorNome': instrutorNome,
      'nivel': nivel,
      'categoria': categoria,
      'capaUrl': capaUrl,
      'exercicios': exercicios.map((e) => e.toMap()).toList(),
      'duracaoMinutos': duracaoMinutos,
      'createdAt': Timestamp.fromDate(createdAt),
      'publicado': publicado,
      'alunoId': alunoId,
      'alunoNome': alunoNome,
      'diaDaSemana': diaDaSemana,
    };
  }
}