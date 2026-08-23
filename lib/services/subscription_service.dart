import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/subscription_model.dart';

/// Centraliza toda a lógica de gestão de assinaturas.
class SubscriptionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.subscriptions);

  Stream<List<SubscriptionModel>> streamTodas() {
    return _col.orderBy('proximoVencimento').snapshots().map(
          (snap) => snap.docs.map((d) => SubscriptionModel.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<SubscriptionModel?> streamDoAluno(String alunoId) {
    return _col
        .where('alunoId', isEqualTo: alunoId)
        .orderBy('inicio', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : SubscriptionModel.fromMap(snap.docs.first.id, snap.docs.first.data()));
  }

  Future<String> criarAssinatura(SubscriptionModel assinatura) async {
    final doc = await _col.add(assinatura.toMap());
    return doc.id;
  }

  Future<void> atualizarStatus(String id, SubscriptionStatus status) {
    return _col.doc(id).update({
      'status': status.value,
      if (status == SubscriptionStatus.cancelada) 'canceladaEm': Timestamp.now(),
    });
  }

  Future<void> renovar(String id, {required int diasAdicionais}) {
    return _db.runTransaction((tx) async {
      final ref = _col.doc(id);
      final snap = await tx.get(ref);
      final atual = SubscriptionModel.fromMap(snap.id, snap.data()!);
      final novoVencimento = atual.proximoVencimento.isAfter(DateTime.now())
          ? atual.proximoVencimento.add(Duration(days: diasAdicionais))
          : DateTime.now().add(Duration(days: diasAdicionais));

      tx.update(ref, {
        'status': SubscriptionStatus.ativa.value,
        'proximoVencimento': Timestamp.fromDate(novoVencimento),
      });
    });
  }

  Future<void> cancelar(String id) => atualizarStatus(id, SubscriptionStatus.cancelada);
}