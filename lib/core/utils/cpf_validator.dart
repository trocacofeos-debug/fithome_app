/// Validação de CPF com o algoritmo real de dígito verificador — não basta
/// contar 11 dígitos, precisa calcular. Isso evita que números claramente
/// inválidos (ex: "00000000000", "11111111111") passem e quebrem a criação
/// do cliente no Asaas depois, na hora do checkout.
class CpfValidator {
  /// Retorna null se o CPF for válido, ou uma mensagem de erro se não for.
  static String? validar(String? valor) {
    if (valor == null || valor.isEmpty) return null; // opcional em vários formulários

    final digitos = valor.replaceAll(RegExp(r'\D'), '');

    if (digitos.length != 11) return 'CPF precisa ter 11 dígitos';

    // CPFs com todos os dígitos iguais (000..., 111..., etc.) passam na
    // conta do dígito verificador matematicamente, mas nunca são válidos.
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digitos)) return 'CPF inválido';

    final numeros = digitos.split('').map(int.parse).toList();

    int calcularDigito(int totalCasas) {
      var soma = 0;
      var peso = totalCasas + 1;
      for (var i = 0; i < totalCasas; i++) {
        soma += numeros[i] * peso;
        peso--;
      }
      final resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    final digito1 = calcularDigito(9);
    if (digito1 != numeros[9]) return 'CPF inválido';

    final digito2 = calcularDigito(10);
    if (digito2 != numeros[10]) return 'CPF inválido';

    return null;
  }

  static bool isValido(String? valor) => validar(valor) == null;
}