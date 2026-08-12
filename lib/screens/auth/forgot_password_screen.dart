import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authService = AuthService();
  final _emailCtrl = TextEditingController();
  bool _enviando = false;
  bool _enviado = false;

  Future<void> _enviar() async {
    if (_emailCtrl.text.isEmpty || !_emailCtrl.text.contains('@')) return;
    setState(() => _enviando = true);
    try {
      await _authService.resetarSenha(_emailCtrl.text.trim());
      setState(() => _enviado = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.destructive),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Recuperar senha', style: condensed(fontSize: 18))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _enviado
            ? const Center(
                child: Text(
                  'Enviamos um link de recuperação para o seu e-mail.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.foreground),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Informe seu e-mail cadastrado para receber o link de redefinição de senha.',
                    style: TextStyle(color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.foreground),
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      labelStyle: TextStyle(color: AppColors.mutedForeground),
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.mutedForeground),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _enviando ? null : _enviar,
                    child: _enviando
                        ? const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryForeground))
                        : const Text('ENVIAR LINK'),
                  ),
                ],
              ),
      ),
    );
  }
}
