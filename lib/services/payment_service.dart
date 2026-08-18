import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fala com as Cloud Functions que integram com o Asaas (checkout de
/// assinatura recorrente e cancelamento). Toda a comunicação direta com a
/// API do Asaas fica no backend (functions/index.js) — o app nunca vê a
/// chave de API do Asaas.
class PaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Cria a assinatura no Asaas e retorna a URL de pagamento (onde o aluno
  /// escolhe PIX, boleto ou cartão). [cpf] só precisa ser passado se o
  /// perfil do usuário ainda não tiver um salvo.
  Future<String> criarCheckout({required String planId, String? cpf}) async {
    try {
      final resultado = await _functions.httpsCallable('createAsaasCheckout').call({
        'planId': planId,
        if (cpf != null) 'cpf': cpf,
      });
      return resultado.data['url'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Erro ao criar checkout de assinatura.');
    }
  }

  /// Cancela de verdade no Asaas (não só no Firestore) uma assinatura com
  /// cobrança automática.
  Future<void> cancelarAssinatura(String subscriptionId) async {
    try {
      await _functions.httpsCallable('cancelAsaasSubscription').call({
        'subscriptionId': subscriptionId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Erro ao cancelar assinatura.');
    }
  }

  /// Abre a URL de pagamento do Asaas no navegador (ou app externo).
  Future<void> abrirCheckout(String url) async {
    final uri = Uri.parse(url);
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu) {
      throw Exception('Não foi possível abrir a página de pagamento.');
    }
  }
}