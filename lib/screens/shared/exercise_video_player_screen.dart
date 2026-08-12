// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_theme.dart';

/// Player de vídeo em tela cheia para os vídeos demonstrativos de exercício
/// (armazenados no Cloudflare R2). Toca em loop por padrão — é um vídeo
/// curto de demonstração, não um conteúdo longo.
class ExerciseVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String titulo;

  const ExerciseVideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.titulo,
  });

  @override
  State<ExerciseVideoPlayerScreen> createState() => _ExerciseVideoPlayerScreenState();
}

class _ExerciseVideoPlayerScreenState extends State<ExerciseVideoPlayerScreen> {
  late final VideoPlayerController _controller;
  bool _erro = false;
  bool _controlesVisiveis = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.addListener(_onControllerChanged);
    _controller.initialize().then((_) {
      if (!mounted) return;
      _controller.setLooping(true);
      _controller.play();
      setState(() {});
    }).catchError((_) {
      if (mounted) setState(() => _erro = true);
    });
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _alternarPlayPause() {
    _controller.value.isPlaying ? _controller.pause() : _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final pronto = _controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _erro
                  ? _mensagemErro()
                  : pronto
                      ? GestureDetector(
                          onTap: () => setState(() => _controlesVisiveis = !_controlesVisiveis),
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        )
                      : const CircularProgressIndicator(color: AppColors.primary),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (pronto && !_erro && _controlesVisiveis) _barraDeControles(),
          ],
        ),
      ),
    );
  }

  Widget _barraDeControles() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 30, 12, 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black87],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              padding: EdgeInsets.zero,
              colors: const VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white10,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: _alternarPlayPause,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatarDuracao(_controller.value.position)} / ${_formatarDuracao(_controller.value.duration)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    widget.titulo,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mensagemErro() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.error_outline, color: AppColors.destructive, size: 40),
          SizedBox(height: 12),
          Text(
            'Não foi possível carregar este vídeo. Verifique sua conexão ou tente novamente mais tarde.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatarDuracao(Duration d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    final minutos = dois(d.inMinutes.remainder(60));
    final segundos = dois(d.inSeconds.remainder(60));
    return '$minutos:$segundos';
  }
}