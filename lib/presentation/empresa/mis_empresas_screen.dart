import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled2/main.dart';
import 'package:untitled2/domain/model/models.dart';
import 'package:untitled2/data/remote/datasource/api_service.dart';
import 'package:untitled2/presentation/auth/providers/auth_provider.dart';
import 'empresa_detalle_screen.dart';

class MisEmpresasScreen extends StatefulWidget {
  /// Si está embebido en el HomeScreen (IndexedStack) no muestra su propio AppBar
  final bool isEmbedded;

  const MisEmpresasScreen({super.key, this.isEmbedded = false});

  @override
  State<MisEmpresasScreen> createState() => _MisEmpresasScreenState();
}

class _MisEmpresasScreenState extends State<MisEmpresasScreen> {
  bool _isLoading = true;
  List<Proveedor> _empresas = [];

  void _showError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.danger,
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _cargarEmpresas();
  }

  Future<void> _cargarEmpresas() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final accountId = auth.activeAccountId;

      final empresas = await ApiService.getMisProveedores(accountId);
      if (!mounted) return;
      setState(() => _empresas = empresas);
    } catch (e) {
      if (!mounted) return;
      _showError('No se pudieron cargar las empresas: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _irACrearEmpresa() async {
    final result = await Navigator.pushNamed(context, '/crear-empresa');
    if (result == true) _cargarEmpresas();
  }

  void _irAEditarEmpresa(Proveedor empresa) async {
    final result = await Navigator.pushNamed(
      context,
      '/crear-empresa',
      arguments: empresa.toJson(),
    );
    if (result == true) _cargarEmpresas();
  }

  void _irAAgregarTrabajador(Proveedor empresa) {
    Navigator.pushNamed(
      context,
      '/agregar-trabajador',
      arguments: {
        'idProveedor': empresa.idProveedor,
        'nombreEmpresa': empresa.nombreProveedor,
      },
    );
  }

  Future<void> _confirmarEliminar(Proveedor empresa) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar empresa'),
        content: Text(
          '¿Seguro que quieres eliminar "${empresa.nombreProveedor}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.eliminarProveedor(empresa.idProveedor);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Empresa eliminada correctamente'),
            backgroundColor: AppTheme.accent,
          ),
        );
        _cargarEmpresas();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo eliminar: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isEmbedded
          ? AppBar(
              title: const Text('Mis empresas'),
              actions: [
                IconButton(
                  onPressed: _irACrearEmpresa,
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Nueva empresa',
                ),
              ],
            )
          : AppBar(
              title: const Text('Mis empresas'),
              leading: const BackButton(),
            ),
      floatingActionButton: widget.isEmbedded
          ? null
          : FloatingActionButton.extended(
              onPressed: _irACrearEmpresa,
              backgroundColor: AppTheme.accent,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Nueva empresa',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            )
          : _empresas.isEmpty
              ? _EmptyState(onCrear: _irACrearEmpresa)
              : RefreshIndicator(
                  color: AppTheme.accent,
                  onRefresh: _cargarEmpresas,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _empresas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _EmpresaCard(
                      empresa: _empresas[i],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmpresaDetalleScreen(empresa: _empresas[i]),
                          ),
                        );
                      },
                      onEditar: () => _irAEditarEmpresa(_empresas[i]),
                      onAgregarTrabajador: () =>
                          _irAAgregarTrabajador(_empresas[i]),
                      onEliminar: () => _confirmarEliminar(_empresas[i]),
                    ),
                  ),
                ),
    );
  }
}

// ─────────────────────────────────────────
// CARD DE EMPRESA
// ─────────────────────────────────────────
class _EmpresaCard extends StatelessWidget {
  final Proveedor empresa;
  final VoidCallback onEditar;
  final VoidCallback onAgregarTrabajador;
  final VoidCallback onEliminar;
  final VoidCallback onTap;

  const _EmpresaCard({
    required this.empresa,
    required this.onEditar,
    required this.onAgregarTrabajador,
    required this.onEliminar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fila superior ──────────────────────────
            Row(
              children: [
                // Avatar con inicial
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      empresa.nombreProveedor[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empresa.nombreProveedor,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (empresa.registroEmpresaProveedor != null)
                        Text(
                          'NIT: ${empresa.registroEmpresaProveedor}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                // Menú de opciones
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppTheme.textSecondary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    if (v == 'editar') onEditar();
                    if (v == 'eliminar') onEliminar();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Editar'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'eliminar',
                      child: Row(children: [
                        Icon(Icons.delete_rounded,
                            size: 18, color: AppTheme.danger),
                        const SizedBox(width: 10),
                        Text('Eliminar',
                            style: TextStyle(color: AppTheme.danger)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Info ───────────────────────────────────
            if (empresa.ciudad != null || empresa.pais != null)
              _InfoRow(
                icon: Icons.location_on_rounded,
                text:
                    [empresa.ciudad, empresa.pais].whereType<String>().join(', '),
              ),
            if (empresa.emailContactoProveedor != null)
              _InfoRow(
                icon: Icons.email_rounded,
                text: empresa.emailContactoProveedor!,
              ),

            const SizedBox(height: 14),

            // ── Botón agregar trabajador ───────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAgregarTrabajador,
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Agregar trabajador'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accent,
                  side: const BorderSide(color: AppTheme.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// ESTADO VACÍO
// ─────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onCrear;

  const _EmptyState({required this.onCrear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.business_rounded,
                size: 48,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin empresas aún',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea tu primera empresa proveedora\npara empezar a gestionar cafeterías.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCrear,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear empresa'),
            ),
          ],
        ),
      ),
    );
  }
}
