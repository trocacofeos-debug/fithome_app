import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { agendado, concluido, cancelado }

extension AppointmentStatusX on AppointmentStatus {
  String get value => toString().split('.').last;

  static AppointmentStatus fromString(String value) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AppointmentStatus.agendado,
    );
  }

  String get label {
    switch (this) {
      case AppointmentStatus.agendado:
        return 'Agendado';
      case AppointmentStatus.concluido:
        return 'Concluído';
      case AppointmentStatus.cancelado:
        return 'Cancelado';
    }
  }
}

/// Um compromisso na agenda do instrutor: avaliação física, treino
/// presencial, consultoria, etc.
class AppointmentModel {
  final String id;
  final String instrutorId;
  final String alunoId;
  final String alunoNome;
  final String tipo; // "Avaliação física", "Treino presencial", "Consultoria"...
  final DateTime dataHora;
  final int duracaoMinutos;
  final String? observacoes;
  final AppointmentStatus status;

  AppointmentModel({
    required this.id,
    required this.instrutorId,
    required this.alunoId,
    required this.alunoNome,
    required this.tipo,
    required this.dataHora,
    this.duracaoMinutos = 60,
    this.observacoes,
    this.status = AppointmentStatus.agendado,
  });

  factory AppointmentModel.fromMap(String id, Map<String, dynamic> map) {
    return AppointmentModel(
      id: id,
      instrutorId: map['instrutorId'] ?? '',
      alunoId: map['alunoId'] ?? '',
      alunoNome: map['alunoNome'] ?? '',
      tipo: map['tipo'] ?? 'Treino presencial',
      dataHora: (map['dataHora'] as Timestamp?)?.toDate() ?? DateTime.now(),
      duracaoMinutos: map['duracaoMinutos'] ?? 60,
      observacoes: map['observacoes'],
      status: AppointmentStatusX.fromString(map['status'] ?? 'agendado'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'instrutorId': instrutorId,
      'alunoId': alunoId,
      'alunoNome': alunoNome,
      'tipo': tipo,
      'dataHora': Timestamp.fromDate(dataHora),
      'duracaoMinutos': duracaoMinutos,
      'observacoes': observacoes,
      'status': status.value,
    };
  }
}