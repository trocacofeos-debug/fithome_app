import 'dart:io';
import 'dart:typed_data';
import 'package:minio/minio.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Serviço de armazenamento de vídeos/imagens no Cloudflare R2.
///
/// R2 é compatível com a API do S3, então usamos o pacote `minio` (cliente
/// S3) apontando para o endpoint do R2. Credenciais ficam no arquivo `.env`
/// (nunca commitar esse arquivo - veja `.env.example`).
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
  /// perfil etc) e retorna a URL pública para salvar no Firestore.
  ///
  /// Observação: o pacote `minio` para Dart não expõe `fPutObject` (esse
  /// método existe em outros SDKs, como Python/Go/Java) — aqui usamos
  /// `putObject`, que recebe o arquivo como `Stream<Uint8List>` mais o
  /// tamanho em bytes.
  Future<String> upload({
    required File arquivo,
    required String pasta, // ex: 'workouts', 'exercises', 'avatars'
  }) async {
    final extensao = arquivo.path.split('.').last;
    final nomeArquivo = '$pasta/${const Uuid().v4()}.$extensao';

    final tamanho = await arquivo.length();
    final stream = arquivo.openRead().map((chunk) => Uint8List.fromList(chunk));

    await _client.putObject(
      bucket,
      nomeArquivo,
      stream,
      size: tamanho,
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
      default:
        return 'application/octet-stream';
    }
  }
}