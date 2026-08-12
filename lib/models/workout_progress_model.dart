import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro de um treino concluído por um aluno — gerado quando ele toca em
/// "Concluir treino" na tela de detalhe do treino.
class WorkoutProgressModel {
  final String id;
  final String alunoId;
  final String alunoNome;
  final String workoutId;
  final String workoutTitulo;
  final String instrutorId;
  final int duracaoMinutos;
  final DateTime concluidoEm;

  WorkoutProgressModel({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.workoutId,
    required this.workoutTitulo,
    required this.instrutorId,
    required this.duracaoMinutos,
    required this.concluidoEm,
  });

  factory WorkoutProgressModel.fromMap(String id, Map<String, dynamic> map) {
    return WorkoutProgressModel(
      id: id,
      alunoId: map['alunoId'] ?? '',
      alunoNome: map['alunoNome'] ?? '',
      workoutId: map['workoutId'] ?? '',
      workoutTitulo: map['workoutTitulo'] ?? '',
      instrutorId: map['instrutorId'] ?? '',
      duracaoMinutos: map['duracaoMinutos'] ?? 0,
      concluidoEm: (map['concluidoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alunoId': alunoId,
      'alunoNome': alunoNome,
      'workoutId': workoutId,
      'workoutTitulo': workoutTitulo,
      'instrutorId': instrutorId,
      'duracaoMinutos': duracaoMinutos,
      'concluidoEm': Timestamp.fromDate(concluidoEm),
    };
  }
}