import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/app_shell.dart';
import 'tabs/admin_dashboard_tab.dart';
import 'tabs/admin_plans_tab.dart';
import 'tabs/admin_users_tab.dart';
import 'tabs/admin_settings_tab.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  String _tab = 'dashboard';

  static const _tabs = [
    AppTab(key: 'dashboard', label: 'Dashboard', icon: Icons.bar_chart_outlined),
    AppTab(key: 'assinaturas', label: 'Planos', icon: Icons.credit_card_outlined),
    AppTab(key: 'usuarios', label: 'Usuários', icon: Icons.people_outline),
    AppTab(key: 'config', label: 'Config', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      role: UserRole.admin,
      tabs: _tabs,
      activeTab: _tab,
      onTab: (t) => setState(() => _tab = t),
      body: switch (_tab) {
        'assinaturas' => const AdminPlansTab(),
        'usuarios' => const AdminUsersTab(),
        'config' => const AdminSettingsTab(),
        _ => const AdminDashboardTab(),
      },
    );
  }
}
