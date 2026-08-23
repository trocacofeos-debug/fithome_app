import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Fala com as Vercel Serverless Functions que integram com o Asaas
/// (checkout de assinatura recorrente e cancelamento). Toda a comunicação
/// direta com a API do Asaas fica no servidor (pasta /api do projeto) — o
/// app nunca vê a chave de API do Asaas.
///
/// Diferente da primeira versão (que usava Cloud Functions do Firebase),
/// isso roda na Vercel — não exige o plano pago (Blaze) do Firebase, só
/// usa o Firestore no plano gratuito normal.
class PaymentService {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  Future<String?> _tokenDeLogin() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return null;
    return usuario.getIdToken();
  }

  /// Cria a assinatura no Asaas e retorna a URL de pagamento (onde o aluno
  /// escolhe PIX, boleto ou cartão). [cpf] só precisa ser passado se o
  /// perfil do usuário ainda não tiver um salvo.
  Future<String> criarCheckout({required String planId, String? cpf}) async {
    if (_baseUrl.isEmpty) {
      throw Exception('API_BASE_URL não configurado no .env.');
    }
    final token = await _tokenDeLogin();
    if (token == null) throw Exception('Faça login para assinar.');

    final resposta = await http.post(
      Uri.parse('$_baseUrl/api/asaas-checkout'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'planId': planId, if (cpf != null) 'cpf': cpf}),
    );

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;
    if (resposta.statusCode != 200) {
      throw Exception(dados['error'] ?? 'Erro ao criar checkout de assinatura.');
    }
    return dados['url'] as String;
  }

  /// Cancela de verdade no Asaas (não só no Firestore) uma assinatura com
  /// cobrança automática.
  Future<void> cancelarAssinatura(String subscriptionId) async {
    if (_baseUrl.isEmpty) {
      throw Exception('API_BASE_URL não configurado no .env.');
    }
    final token = await _tokenDeLogin();
    if (token == null) throw Exception('Faça login.');

    final resposta = await http.post(
      Uri.parse('$_baseUrl/api/asaas-cancel'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'subscriptionId': subscriptionId}),
    );

    if (resposta.statusCode != 200) {
      final dados = jsonDecode(resposta.body) as Map<String, dynamic>;
      throw Exception(dados['error'] ?? 'Erro ao cancelar assinatura.');
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