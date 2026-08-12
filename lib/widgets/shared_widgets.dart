// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Mensagem de erro para quando um StreamBuilder falha (ex: índice do
/// Firestore faltando, permissão negada). Sem isso, a tela ficaria girando
/// no CircularProgressIndicator para sempre, porque `snapshot.hasData`
/// nunca vira true quando o stream emite um erro em vez de dados.
class StreamErrorMessage extends StatelessWidget {
  final Object? erro;
  final String? titulo;

  const StreamErrorMessage({super.key, required this.erro, this.titulo});

  @override
  Widget build(BuildContext context) {
    final texto = erro.toString();
    final indiceFaltando = texto.contains('failed-precondition') || texto.contains('requires an index');
    final semPermissao = texto.contains('permission-denied') || texto.contains('insufficient permissions');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.destructive, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo ?? 'Não foi possível carregar os dados',
                  style: const TextStyle(color: AppColors.destructive, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (indiceFaltando)
            const Text(
              'O Firestore precisa de um índice para essa consulta. O link para criar automaticamente '
              'está no texto de erro logo abaixo (ou no Console do navegador, F12). Depois de criar, '
              'aguarde 1-2 minutos e recarregue a tela.',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
            )
          else if (semPermissao)
            const Text(
              'Sem permissão para ler esses dados — confira se as regras do Firestore (firestore.rules) '
              'foram publicadas no Console.',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
            ),
          const SizedBox(height: 8),
          SelectableText(
            texto,
            style: const TextStyle(color: AppColors.mutedForeground, fontSize: 10, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

/// Card de estatística com número grande em Barlow Condensed.
/// Espelha o componente <StatCard> do design original.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final IconData icon;
  final bool accent;
  final Color accentColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    required this.icon,
    this.accent = false,
    this.accentColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final bg = accent ? accentColor : AppColors.card;
    final fg = accent ? AppColors.primaryForeground : AppColors.foreground;
    final fgMuted = accent ? AppColors.primaryForeground.withOpacity(0.7) : AppColors.mutedForeground;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: accent ? null : Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: fgMuted,
                ),
              ),
              Icon(icon, size: 16, color: fgMuted),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: condensed(fontSize: 26, color: fg)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!, style: TextStyle(fontSize: 11, color: fgMuted)),
          ],
        ],
      ),
    );
  }
}

/// Título de seção — Barlow Condensed, uppercase, bold.
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: condensed(fontSize: 19));
  }
}

/// Círculo com iniciais, usado para representar alunos/instrutores sem foto.
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color color;

  const InitialsAvatar({
    super.key,
    required this.initials,
    this.size = 36,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: condensed(fontSize: size * 0.36, color: color),
      ),
    );
  }
}

/// Badge de status colorido (Ativo/Pendente/Cancelado/etc).
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  factory StatusBadge.status(String status) {
    switch (status.toLowerCase()) {
      case 'ativo':
      case 'ativa':
        return StatusBadge(label: status, color: AppColors.emerald);
      case 'pendente':
        return StatusBadge(label: status, color: AppColors.amber);
      case 'cancelado':
      case 'cancelada':
      case 'atrasada':
        return StatusBadge(label: status, color: AppColors.destructive);
      default:
        return StatusBadge(label: status, color: AppColors.mutedForeground);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }
}