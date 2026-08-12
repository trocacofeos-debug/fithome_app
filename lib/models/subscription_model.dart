import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class SubscriptionModel {
  final String id;
  final String alunoId;
  final String alunoNome;
  final String planoId;
  final String planoNome;
  final double valor;
  final SubscriptionStatus status;
  final DateTime inicio;
  final DateTime proximoVencimento;
  final DateTime? canceladaEm;
  final String? observacoes;

  SubscriptionModel({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.planoId,
    required this.planoNome,
    required this.valor,
    required this.status,
    required this.inicio,
    required this.proximoVencimento,
    this.canceladaEm,
    this.observacoes,
  });

  bool get emDia => status == SubscriptionStatus.ativa;

  factory SubscriptionModel.fromMap(String id, Map<String, dynamic> map) {
    return SubscriptionModel(
      id: id,
      alunoId: map['alunoId'] ?? '',
      alunoNome: map['alunoNome'] ?? '',
      planoId: map['planoId'] ?? '',
      planoNome: map['planoNome'] ?? '',
      valor: (map['valor'] ?? 0).toDouble(),
      status: SubscriptionStatusX.fromString(map['status'] ?? 'pendente'),
      inicio: (map['inicio'] as Timestamp?)?.toDate() ?? DateTime.now(),
      proximoVencimento:
          (map['proximoVencimento'] as Timestamp?)?.toDate() ?? DateTime.now(),
      canceladaEm: (map['canceladaEm'] as Timestamp?)?.toDate(),
      observacoes: map['observacoes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alunoId': alunoId,
      'alunoNome': alunoNome,
      'planoId': planoId,
      'planoNome': planoNome,
      'valor': valor,
      'status': status.value,
      'inicio': Timestamp.fromDate(inicio),
      'proximoVencimento': Timestamp.fromDate(proximoVencimento),
      'canceladaEm': canceladaEm != null ? Timestamp.fromDate(canceladaEm!) : null,
      'observacoes': observacoes,
    };
  }
}

class PlanModel {
  final String id;
  final String nome;
  final double valor;
  final int duracaoDias;
  final String? descricao;

  PlanModel({
    required this.id,
    required this.nome,
    required this.valor,
    required this.duracaoDias,
    this.descricao,
  });

  factory PlanModel.fromMap(String id, Map<String, dynamic> map) {
    return PlanModel(
      id: id,
      nome: map['nome'] ?? '',
      valor: (map['valor'] ?? 0).toDouble(),
      duracaoDias: map['duracaoDias'] ?? 30,
      descricao: map['descricao'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'valor': valor,
      'duracaoDias': duracaoDias,
      'descricao': descricao,
    };
  }
}
