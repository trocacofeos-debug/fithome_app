import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Serviço de upload de arquivos (capa de treino, GIF de exercício, avatar).
///
/// HISTÓRICO: a primeira versão usava o pacote `minio` pra falar direto com
/// o Cloudflare R2 do navegador. Isso não funciona de forma confiável no
/// Flutter Web — o protocolo de assinatura da AWS que o R2 usa (streaming
/// signed payload) não é algo que o navegador consegue enviar corretamente
/// via fetch/XHR, e a falha de assinatura aparecia disfarçada de erro de
/// CORS (o R2 não devolve cabeçalho de CORS em respostas de erro de auth).
///
/// SOLUÇÃO ATUAL: o navegador manda os bytes (em base64) pra uma Vercel
/// Serverless Function (`/api/upload.js`), que roda no servidor — lá sim
/// um cliente S3 de verdade (Node) consegue assinar e enviar pro R2 sem
/// nenhuma limitação de navegador. O app nunca fala direto com o R2, e
/// nunca tem a chave secreta.
class R2StorageService {
  /// URL da função serverless de upload — normalmente
  /// "https://SEU-APP.vercel.app/api/upload", configurada no `.env` como
  /// UPLOAD_API_URL.
  final String _uploadEndpoint = dotenv.env['UPLOAD_API_URL'] ?? '';

  /// Faz upload de um arquivo a partir dos bytes já lidos em memória, e
  /// retorna a URL pública para salvar no Firestore.
  Future<String> upload({
    required Uint8List bytes,
    required String nomeOriginal,
    required String pasta, // 'workouts', 'exercises' ou 'avatars'
  }) async {
    if (_uploadEndpoint.isEmpty) {
      throw Exception(
        'UPLOAD_API_URL não configurado no .env — aponte para a URL da sua '
        'função /api/upload publicada na Vercel.',
      );
    }

    final extensao = nomeOriginal.contains('.') ? nomeOriginal.split('.').last : '';
    final contentType = _contentTypePorExtensao(extensao);

    final resposta = await http.post(
      Uri.parse(_uploadEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'pasta': pasta,
        'nomeOriginal': nomeOriginal,
        'contentType': contentType,
        'base64': base64Encode(bytes),
      }),
    );

    if (resposta.statusCode != 200) {
      throw Exception('Erro ao enviar arquivo: ${resposta.body}');
    }

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;
    return dados['publicUrl'] as String;
  }

  String _contentTypePorExtensao(String extensao) {
    switch (extensao.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }
}