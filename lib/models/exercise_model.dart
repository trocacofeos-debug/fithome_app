class ExerciseModel {
  final String id;
  final String nome;
  final String? descricao;

  /// 'repeticoes' (padrão) ou 'tempo' — exercícios como prancha, wall-sit
  /// etc. são feitos por tempo, não por repetição.
  final String tipo;

  final int series;
  final int repeticoes;

  /// Usado só quando [tipo] == 'tempo' — quantos segundos o aluno precisa
  /// sustentar o exercício. A tela de execução conta regressivamente
  /// sozinha, igual o temporizador de descanso.
  final int? duracaoSegundos;

  final int descansoSegundos;
  final String? gifUrl; // URL do GIF demonstrativo no Cloudflare R2

  ExerciseModel({
    required this.id,
    required this.nome,
    this.descricao,
    this.tipo = 'repeticoes',
    required this.series,
    required this.repeticoes,
    this.duracaoSegundos,
    required this.descansoSegundos,
    this.gifUrl,
  });

  bool get porTempo => tipo == 'tempo';

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      descricao: map['descricao'],
      tipo: map['tipo'] ?? 'repeticoes',
      series: map['series'] ?? 3,
      repeticoes: map['repeticoes'] ?? 12,
      duracaoSegundos: map['duracaoSegundos'],
      descansoSegundos: map['descansoSegundos'] ?? 60,
      // Lê "videoUrl" como fallback — treinos criados antes da migração
      // pra GIF continuam mostrando o que já foi enviado.
      gifUrl: map['gifUrl'] ?? map['videoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'tipo': tipo,
      'series': series,
      'repeticoes': repeticoes,
      'duracaoSegundos': duracaoSegundos,
      'descansoSegundos': descansoSegundos,
      'gifUrl': gifUrl,
    };
  }
}