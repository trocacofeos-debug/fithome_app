import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/referral_commission_model.dart';

/// Centraliza a leitura das comissões de indicação. A gravação é feita
/// só pelo backend (webhook do Asaas em api/asaas-webhook.js), nunca
/// pelo app.
class ReferralService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ReferralCommissionModel>> streamComissoes(String instrutorId) {
    return _db
        .collection(FirestoreCollections.referralCommissions)
        .where('instrutorId', isEqualTo: instrutorId)
        .orderBy('periodo', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ReferralCommissionModel.fromMap(d.id, d.data())).toList());
  }
}
