import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Visualização em tela cheia do GIF demonstrativo do exercício. Bem mais
/// simples que um player de vídeo — GIF já anima e faz loop sozinho, não
/// precisa de play/pause nem barra de progresso.
class GifViewerScreen extends StatelessWidget {
  final String gifUrl;
  final String titulo;

  const GifViewerScreen({super.key, required this.gifUrl, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  gifUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const CircularProgressIndicator(color: AppColors.primary);
                  },
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: AppColors.destructive, size: 40),
                        SizedBox(height: 12),
                        Text('Não foi possível carregar o GIF.', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}