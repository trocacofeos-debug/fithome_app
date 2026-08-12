class ExerciseModel {
  final String id;
  final String nome;
  final String? descricao;
  final int series;
  final int repeticoes;
  final int descansoSegundos;
  final String? videoUrl; // URL no Cloudflare R2
  final String? thumbnailUrl;

  ExerciseModel({
    required this.id,
    required this.nome,
    this.descricao,
    required this.series,
    required this.repeticoes,
    required this.descansoSegundos,
    this.videoUrl,
    this.thumbnailUrl,
  });

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      descricao: map['descricao'],
      series: map['series'] ?? 3,
      repeticoes: map['repeticoes'] ?? 12,
      descansoSegundos: map['descansoSegundos'] ?? 60,
      videoUrl: map['videoUrl'],
      thumbnailUrl: map['thumbnailUrl'],
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
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}
