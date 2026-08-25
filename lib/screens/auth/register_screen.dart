import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  /// Código de indicação vindo do link do instrutor (`/cadastro?ref=...`),
  /// se houver. Pré-preenche o campo de código, mas continua editável.
  final String? codigoIndicacaoInicial;

  const RegisterScreen({super.key, this.codigoIndicacaoInicial});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  late final _codigoIndicacaoCtrl = TextEditingController(text: widget.codigoIndicacaoInicial ?? '');
  bool _carregando = false;

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.registrar(
      _nomeCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _senhaCtrl.text.trim(),
      codigoIndicacao: _codigoIndicacaoCtrl.text.trim().isEmpty ? null : _codigoIndicacaoCtrl.text.trim(),
    );
    setState(() => _carregando = false);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.erro ?? 'Erro ao cadastrar'), backgroundColor: AppColors.destructive),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Criar conta', style: condensed(fontSize: 18))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nomeCtrl,
                  style: const TextStyle(color: AppColors.foreground),
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    labelStyle: TextStyle(color: AppColors.mutedForeground),
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.mutedForeground),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Informe seu nome' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.foreground),
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    labelStyle: TextStyle(color: AppColors.mutedForeground),
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.mutedForeground),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _senhaCtrl,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.foreground),
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    labelStyle: TextStyle(color: AppColors.mutedForeground),
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.mutedForeground),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codigoIndicacaoCtrl,
                  style: const TextStyle(color: AppColors.foreground),
                  decoration: const InputDecoration(
                    labelText: 'Código de indicação (opcional)',
                    labelStyle: TextStyle(color: AppColors.mutedForeground),
                    prefixIcon: Icon(Icons.card_giftcard_outlined, color: AppColors.mutedForeground),
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _carregando ? null : _cadastrar,
                  child: _carregando
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryForeground))
                      : const Text('CADASTRAR'),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Todo cadastro entra como Aluno. Para se tornar Instrutor, '
                  'peça a um Administrador para alterar seu perfil.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
