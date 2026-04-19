import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled2/data/remote/datasource/api_service.dart';
import 'package:untitled2/domain/model/models.dart';
import 'package:untitled2/main.dart';
import 'package:untitled2/presentation/auth/providers/auth_provider.dart';
import 'package:untitled2/presentation/cafeteria/asignar_trabajador_cafeteria_screen.dart';
import 'package:untitled2/presentation/cafeteria/crear_cafeteria_screen.dart';

class CafeteriasScreen extends StatefulWidget {
  final Proveedor? empresa;
  final bool isEmbedded;

  const CafeteriasScreen({
    super.key,
    this.empresa,
    this.isEmbedded = false,
  });

  @override
  State<CafeteriasScreen> createState() => _CafeteriasScreenState();
}

class _CafeteriasScreenState extends State<CafeteriasScreen> {
  bool _loading = true;
  List<Cafeteria> _cafeterias = [];
  Map<String, String> _providerNames = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final accountId = context.read<AuthProvider>().activeAccountId;
      final providers = await ApiService.getMisProveedores(accountId);
      final data = widget.empresa != null
          ? await ApiService.getCafeteriasByProvider(widget.empresa!.idProveedor)
          : await ApiService.getCafeterias();
      if (!mounted) return;
      setState(() {
        _cafeterias = data;
        _providerNames = {
          for (final p in providers) p.idProveedor: p.nombreProveedor,
        };
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron cargar cafeterías: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _crear() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CrearCafeteriaScreen(empresa: widget.empresa),
      ),
    );
    if (ok == true) _cargar();
  }

  Future<void> _editar(Cafeteria cafeteria) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CrearCafeteriaScreen(
          empresa: widget.empresa,
          cafeteriaExistente: cafeteria,
        ),
      ),
    );
    if (ok == true) _cargar();
  }

  Future<void> _eliminar(Cafeteria cafeteria) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cafetería'),
        content: Text(
          '¿Seguro que deseas eliminar "${cafeteria.nombreCafeteria ?? cafeteria.idCafeteria}"?',
        ),
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
      await ApiService.eliminarCafeteria(cafeteria.idCafeteria);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cafetería eliminada correctamente'),
          backgroundColor: AppTheme.accent,
        ),
      );
      _cargar();
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

  Future<void> _asignar(Cafeteria cafeteria) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AsignarTrabajadorCafeteriaScreen(
          empresa: widget.empresa,
          cafeteriaInicial: cafeteria,
        ),
      ),
    );
    if (ok == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.empresa != null ? 'Cafeterías · ${widget.empresa!.nombreProveedor}' : 'Cafeterías'),
        actions: [
          IconButton(
            onPressed: _crear,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Nueva cafetería',
          )
        ],
      ),
      floatingActionButton: widget.isEmbedded
          ? null
          : FloatingActionButton.extended(
              onPressed: _crear,
              backgroundColor: AppTheme.accent,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nueva cafetería',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _cafeterias.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No hay cafeterías registradas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  color: AppTheme.accent,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _cafeterias.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final c = _cafeterias[i];
                      final schoolName = ApiService.schoolNameOf(c.idColegio) ?? 'Colegio sin nombre';
                      final providerName = (c.idProveedor ?? '').isEmpty
                          ? 'Sin proveedor'
                          : (_providerNames[c.idProveedor] ?? 'Proveedor asignado');
                      return Card(
                        child: ListTile(
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.coffee_rounded, color: AppTheme.accent),
                          ),
                          title: Text(c.nombreCafeteria ?? 'Cafetería sin nombre'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Colegio: $schoolName'),
                              Text('Proveedor: $providerName'),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'asignar') _asignar(c);
                              if (v == 'editar') _editar(c);
                              if (v == 'eliminar') _eliminar(c);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem<String>(
                                value: 'asignar',
                                child: Row(
                                  children: [
                                    Icon(Icons.person_add_alt_1_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Asignar trabajador'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
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
                      );
                    },
                  ),
                ),
    );
  }
}
