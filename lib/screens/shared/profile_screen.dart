// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/r2_storage_service.dart';
import '../../widgets/shared_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fsService = FirestoreService();
  final _storageService = R2StorageService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _cpfCtrl;

  File? _fotoLocal;
  String? _fotoUrlExistente;
  bool _salvando = false;
  bool _enviandoFoto = false;

  @override
  void initState() {
    super.initState();
    final usuario = context.read<AuthProvider>().usuario!;
    _nomeCtrl = TextEditingController(text: usuario.nome);
    _telefoneCtrl = TextEditingController(text: usuario.telefone ?? '');
    _cpfCtrl = TextEditingController(text: usuario.cpf ?? '');
    _fotoUrlExistente = usuario.fotoUrl;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    _cpfCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario!;
    final corPapel = AppColors.porRole(usuario.role);

    return Scaffold(
      appBar: AppBar(title: Text('MEU PERFIL', style: condensed(fontSize: 18))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: _seletorFoto(usuario, corPapel)),
            const SizedBox(height: 8),
            Center(
              child: StatusBadge(label: usuario.role.label, color: corPapel),
            ),
            const SizedBox(height: 28),

            TextFormField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Informe seu nome' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              initialValue: usuario.email,
              readOnly: true,
              style: const TextStyle(color: AppColors.mutedForeground),
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
                helperText: 'O e-mail não pode ser alterado por aqui.',
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _telefoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefone (opcional)', prefixIcon: Icon(Icons.phone_outlined)),
            ),

            if (usuario.role == UserRole.aluno) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _cpfCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                decoration: const InputDecoration(
                  labelText: 'CPF (só números)',
                  prefixIcon: Icon(Icons.badge_outlined),
                  helperText: 'Usado para gerar a cobrança da assinatura.',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null; // opcional até assinar
                  return v.length == 11 ? null : 'CPF precisa ter 11 dígitos';
                },
              ),
            ],

            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryForeground))
                  : const Text('SALVAR ALTERAÇÕES'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seletorFoto(UserModel usuario, Color corPapel) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _enviandoFoto ? null : _escolherFoto,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: corPapel.withOpacity(0.15),
              border: Border.all(color: corPapel.withOpacity(0.4), width: 2),
              image: _fotoLocal != null
                  ? DecorationImage(image: FileImage(_fotoLocal!), fit: BoxFit.cover)
                  : (_fotoUrlExistente != null
                      ? DecorationImage(image: NetworkImage(_fotoUrlExistente!), fit: BoxFit.cover)
                      : null),
            ),
            child: (_fotoLocal == null && _fotoUrlExistente == null)
                ? Center(
                    child: Text(
                      usuario.nome.isNotEmpty ? usuario.nome.substring(0, 1).toUpperCase() : '?',
                      style: condensed(fontSize: 36, color: corPapel),
                    ),
                  )
                : (_enviandoFoto
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : null),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt, size: 14, color: AppColors.primaryForeground),
          ),
        ),
      ],
    );
  }

  Future<void> _escolherFoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 600);
    if (img == null) return;

    setState(() {
      _fotoLocal = File(img.path);
      _enviandoFoto = true;
    });

    try {
      final url = await _storageService.upload(arquivo: _fotoLocal!, pasta: 'avatars');
      final uid = context.read<AuthProvider>().usuario!.id;
      await _fsService.atualizarPerfilProprio(uid, fotoUrl: url);
      setState(() => _fotoUrlExistente = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar foto: $e'), backgroundColor: AppColors.destructive),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      final uid = context.read<AuthProvider>().usuario!.id;
      await _fsService.atualizarPerfilProprio(
        uid,
        nome: _nomeCtrl.text.trim(),
        telefone: _telefoneCtrl.text.trim().isEmpty ? null : _telefoneCtrl.text.trim(),
        cpf: _cpfCtrl.text.trim().isEmpty ? null : _cpfCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso.'), backgroundColor: AppColors.emerald),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: AppColors.destructive),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
}