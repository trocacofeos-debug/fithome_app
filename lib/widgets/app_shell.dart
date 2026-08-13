// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../screens/shared/profile_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../services/firestore_service.dart';

class AppTab {
  final String key;
  final String label;
  final IconData icon;
  const AppTab({required this.key, required this.label, required this.icon});
}

/// Casca visual comum aos 3 painéis: barra superior com logo/papel/sino/sair,
/// conteúdo central e navegação por abas fixa embaixo — espelha o componente
/// <Shell> do design original em React.
class AppShell extends StatelessWidget {
  final UserRole role;
  final Widget body;
  final List<AppTab> tabs;
  final String activeTab;
  final ValueChanged<String> onTab;

  const AppShell({
    super.key,
    required this.role,
    required this.body,
    required this.tabs,
    required this.activeTab,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = AppColors.porRole(role);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(role: role, roleColor: roleColor),
            const Divider(height: 1),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: tabs.map((tab) {
              final ativo = tab.key == activeTab;
              final cor = ativo ? roleColor : AppColors.mutedForeground;
              return Expanded(
                child: InkWell(
                  onTap: () => onTab(tab.key),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tab.icon, size: 20, color: cor),
                        const SizedBox(height: 4),
                        Text(
                          tab.label.toUpperCase(),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: cor, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final UserRole role;
  final Color roleColor;

  const _TopBar({required this.role, required this.roleColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.primary, size: 20),
          const SizedBox(width: 6),
          Text(AppConstants.appName, style: condensed(fontSize: 15)),
          const SizedBox(width: 6),
          Text('· ${role.label}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: roleColor)),
          const Spacer(),
          _AvatarButton(role: role, roleColor: roleColor),
          const SizedBox(width: 10),
          _NotificationBell(),
          const SizedBox(width: 10),
          _CircleIconButton(
            icon: Icons.logout,
            hoverColor: AppColors.destructive,
            onTap: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  final UserRole role;
  final Color roleColor;

  const _AvatarButton({required this.role, required this.roleColor});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final iniciais = (usuario == null || usuario.nome.isEmpty) ? '?' : usuario.nome.substring(0, 1).toUpperCase();

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: roleColor.withOpacity(0.15),
          border: Border.all(color: roleColor.withOpacity(0.4)),
          image: usuario?.fotoUrl != null
              ? DecorationImage(image: NetworkImage(usuario!.fotoUrl!), fit: BoxFit.cover)
              : null,
        ),
        child: usuario?.fotoUrl == null
            ? Center(child: Text(iniciais, style: condensed(fontSize: 13, color: roleColor)))
            : null,
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  _NotificationBell();

  final _fsService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().usuario?.id;
    if (uid == null) {
      return _CircleIconButton(icon: Icons.notifications_outlined, onTap: () {});
    }

    return StreamBuilder(
      stream: _fsService.streamNotificacoes(uid),
      builder: (context, snapshot) {
        final naoLidas = (snapshot.data ?? []).where((n) => !n.lida).length;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _CircleIconButton(
              icon: Icons.notifications_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            ),
            if (naoLidas > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: const BoxDecoration(color: AppColors.destructive, shape: BoxShape.circle),
                  child: Text(
                    naoLidas > 9 ? '9+' : '$naoLidas',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color hoverColor;

  const _CircleIconButton({required this.icon, required this.onTap, this.hoverColor = AppColors.foreground});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 15, color: AppColors.mutedForeground),
      ),
    );
  }
}