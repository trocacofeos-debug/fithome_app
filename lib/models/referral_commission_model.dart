import 'package:cloud_firestore/cloud_firestore.dart';

/// Um registro de comissão de indicação: gerado pelo backend (webhook do
/// Asaas) sempre que a mensalidade de um aluno indicado é confirmada.
/// Um documento por (instrutor, aluno, mês) — nunca duplicado, mesmo que
/// o Asaas reenvie o mesmo evento de pagamento.
class ReferralCommissionModel {
  final String id;
  final String instrutorId;
  final String alunoId;
  final String alunoNome;
  final String subscriptionId;
  final double valor;
  final String periodo; // 'YYYY-MM'
  final DateTime criadoEm;

  ReferralCommissionModel({
    required this.id,
    required this.instrutorId,
    required this.alunoId,
    required this.alunoNome,
    required this.subscriptionId,
    required this.valor,
    required this.periodo,
    required this.criadoEm,
  });

  factory ReferralCommissionModel.fromMap(String id, Map<String, dynamic> map) {
    return ReferralCommissionModel(
      id: id,
      instrutorId: map['instrutorId'] ?? '',
      alunoId: map['alunoId'] ?? '',
      alunoNome: map['alunoNome'] ?? '',
      subscriptionId: map['subscriptionId'] ?? '',
      valor: (map['valor'] ?? 0).toDouble(),
      periodo: map['periodo'] ?? '',
      criadoEm: (map['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
