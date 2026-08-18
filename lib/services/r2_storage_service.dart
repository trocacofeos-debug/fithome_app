import 'dart:typed_data';
import 'package:minio/minio.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Serviço de armazenamento de vídeos/imagens no Cloudflare R2.
///
/// R2 é compatível com a API do S3, então usamos o pacote `minio` (cliente
/// S3) apontando para o endpoint do R2. Credenciais ficam no arquivo `.env`
/// (nunca commitar esse arquivo - veja `.env.example`).
///
/// IMPORTANTE: este serviço trabalha só com bytes (`Uint8List`), nunca com
/// `dart:io File` — o `File` do dart:io não funciona no Flutter Web (lança
/// `UnsupportedError` em qualquer operação de leitura). Usando bytes, o
/// upload funciona igual em Web, Android, iOS e Desktop.
class R2StorageService {
  late final Minio _client;
  final String bucket = dotenv.env['R2_BUCKET'] ?? '';
  final String publicBaseUrl = dotenv.env['R2_PUBLIC_URL'] ?? '';

  R2StorageService() {
    _client = Minio(
      // O pacote minio espera só o domínio puro (sem "https://" e sem "/"
      // no final) — removemos aqui por segurança, caso o .env venha com a
      // URL completa por engano.
      endPoint: _sanitizarEndpoint(dotenv.env['R2_ENDPOINT'] ?? ''),
      accessKey: dotenv.env['R2_ACCESS_KEY_ID'] ?? '',
      secretKey: dotenv.env['R2_SECRET_ACCESS_KEY'] ?? '',
      useSSL: true,
    );
  }

  String _sanitizarEndpoint(String endpoint) {
    return endpoint
        .trim()
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'/+$'), '');
  }

  /// Faz upload de um arquivo (vídeo de exercício, capa de treino, foto de
  /// perfil etc) a partir dos bytes já lidos em memória, e retorna a URL
  /// pública para salvar no Firestore.
  ///
  /// [nomeOriginal] é usado só para descobrir a extensão (ex: "foto.jpg")
  /// — o arquivo em si é salvo com um nome gerado (UUID), então não precisa
  /// ser o nome real do arquivo do usuário.
  Future<String> upload({
    required Uint8List bytes,
    required String nomeOriginal,
    required String pasta, // ex: 'workouts', 'exercises', 'avatars'
  }) async {
    final extensao = nomeOriginal.contains('.') ? nomeOriginal.split('.').last : 'bin';
    final nomeArquivo = '$pasta/${const Uuid().v4()}.$extensao';

    await _client.putObject(
      bucket,
      nomeArquivo,
      Stream.value(bytes),
      size: bytes.length,
      metadata: {'Content-Type': _contentTypePorExtensao(extensao)},
    );

    return '$publicBaseUrl/$nomeArquivo';
  }

  Future<void> excluir(String urlOuChave) async {
    final chave = urlOuChave.startsWith('http')
        ? urlOuChave.replaceFirst('$publicBaseUrl/', '')
        : urlOuChave;
    await _client.removeObject(bucket, chave);
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
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }
}