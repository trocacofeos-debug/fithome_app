class ExerciseModel {
  final String id;
  final String nome;
  final String? descricao;
  final int series;
  final int repeticoes;
  final int descansoSegundos;
  final String? gifUrl; // URL do GIF demonstrativo no Cloudflare R2

  ExerciseModel({
    required this.id,
    required this.nome,
    this.descricao,
    required this.series,
    required this.repeticoes,
    required this.descansoSegundos,
    this.gifUrl,
  });

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      descricao: map['descricao'],
      series: map['series'] ?? 3,
      repeticoes: map['repeticoes'] ?? 12,
      descansoSegundos: map['descansoSegundos'] ?? 60,
      // Lê "videoUrl" como fallback — treinos criados antes dessa mudança
      // (quando ainda era vídeo) continuam mostrando o que já foi enviado.
      gifUrl: map['gifUrl'] ?? map['videoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'series': series,
      'repeticoes': repeticoes,
      'descansoSegundos': descansoSegundos,
      'gifUrl': gifUrl,
    };
  }
}