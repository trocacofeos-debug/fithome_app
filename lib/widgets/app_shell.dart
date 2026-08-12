import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';

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
          _CircleIconButton(icon: Icons.notifications_outlined, onTap: () {}),
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
