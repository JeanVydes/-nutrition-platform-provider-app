import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled2/main.dart';
import 'package:untitled2/presentation/auth/providers/auth_provider.dart';
import 'package:untitled2/presentation/empresa/mis_empresas_screen.dart';
import 'package:untitled2/presentation/trabajador/empresas_como_trabajador_screen.dart';
import 'package:untitled2/presentation/cafeteria/cafeterias_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = const [
      MisEmpresasScreen(isEmbedded: true),
      EmpresasComoTrabajadorScreen(isEmbedded: true),
      CafeteriasScreen(isEmbedded: true),
      _ProfileTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.business_rounded),
              label: 'Empresas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.badge_rounded),
              label: 'Empleos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.coffee_rounded),
              label: 'Cafeterías',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// TAB: Perfil
// ─────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.currentProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            onPressed: () => _confirmLogout(context, auth),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          // ── Avatar ──────────────────────────────
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initials(profile),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accent,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              profile?.nombreCompleto ?? 'Usuario',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          if (profile?.email != null && profile!.email!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                profile.email!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
          if (profile?.phone != null && profile!.phone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                profile.phone!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // ── Info card ───────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileRow(
                    icon: Icons.fingerprint_rounded,
                    label: 'ID',
                    value: auth.activeAccountId.isNotEmpty
                        ? '${auth.activeAccountId.substring(0, 8)}...'
                        : 'N/A',
                  ),
                  const Divider(height: 20),
                  _ProfileRow(
                    icon: Icons.shield_rounded,
                    label: 'Roles',
                    value: profile?.rolLabel ?? 'Sin rol',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Logout ──────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, auth),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(dynamic profile) {
    if (profile == null) return '?';
    final n = profile.nombres?.toString() ?? '';
    final a = profile.apellidos?.toString() ?? '';
    final buffer = StringBuffer();
    if (n.isNotEmpty) buffer.write(n[0].toUpperCase());
    if (a.isNotEmpty) buffer.write(a[0].toUpperCase());
    return buffer.isEmpty ? '?' : buffer.toString();
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      auth.logout();
      // Auth gate will automatically redirect to login
    }
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
