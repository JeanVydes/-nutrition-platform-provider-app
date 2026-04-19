import 'package:flutter/material.dart';
import 'package:untitled2/domain/model/models.dart';
import 'package:untitled2/data/remote/datasource/api_service.dart';
import 'package:untitled2/main.dart';
import 'package:untitled2/presentation/trabajador/editar_trabajador_screen.dart';
import 'package:untitled2/presentation/cafeteria/cafeterias_screen.dart';

class EmpresaDetalleScreen extends StatefulWidget {
  final Proveedor empresa;

  const EmpresaDetalleScreen({super.key, required this.empresa});

  @override
  State<EmpresaDetalleScreen> createState() => _EmpresaDetalleScreenState();
}

class _EmpresaDetalleScreenState extends State<EmpresaDetalleScreen> {
  late Future<List<Trabajador>> _trabajadoresFuture;

  @override
  void initState() {
    super.initState();
    _cargarTrabajadores();
  }

  void _cargarTrabajadores() {
    setState(() {
      _trabajadoresFuture = ApiService.getTrabajadoresDeEmpresa(widget.empresa.idProveedor);
    });
  }

  Future<void> _eliminarTrabajador(Trabajador trabajador) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar trabajador'),
        content: const Text('¿Seguro que deseas eliminar este trabajador de la empresa?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.eliminarTrabajador(trabajador.idTrabajador);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trabajador eliminado correctamente'),
          backgroundColor: AppTheme.accent,
        ),
      );
      _cargarTrabajadores();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.empresa.nombreProveedor),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información de la Empresa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(icon: Icons.badge_outlined, label: 'NIT / Registro', value: widget.empresa.registroEmpresaProveedor ?? 'No especificado'),
                      const SizedBox(height: 8),
                      _InfoRow(icon: Icons.email_outlined, label: 'Correo', value: widget.empresa.emailContactoProveedor ?? 'No especificado'),
                      const SizedBox(height: 8),
                      _InfoRow(icon: Icons.phone_outlined, label: 'Teléfono', value: widget.empresa.telefonoContactoProveedor ?? 'No especificado'),
                      const SizedBox(height: 8),
                      _InfoRow(icon: Icons.location_on_outlined, label: 'Ubicación', value: '${widget.empresa.ciudad ?? ''}, ${widget.empresa.pais ?? ''}'.trim()),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CafeteriasScreen(empresa: widget.empresa),
                              ),
                            );
                          },
                          icon: const Icon(Icons.coffee_rounded),
                          label: const Text('Gestionar cafeterías (en colegios)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Listado de Empleados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          FutureBuilder<List<Trabajador>>(
            future: _trabajadoresFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text('Error cargando trabajadores', style: TextStyle(color: AppTheme.danger)),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No hay empleados registrados', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                );
              }

              final trabajadores = snapshot.data!;
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final trabajador = trabajadores[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          onTap: () async {
                            final bool? update = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditarTrabajadorScreen(trabajador: trabajador),
                              ),
                            );
                            if (update == true) {
                              _cargarTrabajadores(); // Refrescar lista
                            }
                          },
                          leading: CircleAvatar(
                            backgroundColor: Color(trabajador.estadoEmpleo.colorValue).withValues(alpha: 0.2),
                            child: Icon(
                              Icons.person,
                              color: Color(trabajador.estadoEmpleo.colorValue),
                            ),
                          ),
                          title: Text(
                            trabajador.cargoTrabajador ?? 'Trabajador sin cargo',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Contrato: ${trabajador.tipoContratoTrabajador ?? "No especificado"}\nID: ${trabajador.idTrabajador.substring(0, 8)}...',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'editar') {
                                final bool? update = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditarTrabajadorScreen(trabajador: trabajador),
                                  ),
                                );
                                if (update == true) _cargarTrabajadores();
                              }
                              if (v == 'eliminar') {
                                _eliminarTrabajador(trabajador);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem<String>(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'eliminar',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_rounded, size: 18, color: AppTheme.danger),
                                    SizedBox(width: 8),
                                    Text('Eliminar', style: TextStyle(color: AppTheme.danger)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: trabajadores.length,
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty || value == ', ') return const SizedBox();
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
