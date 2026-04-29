import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled2/data/remote/datasource/api_service.dart';
import 'package:untitled2/domain/model/models.dart';
import 'package:untitled2/main.dart';
import 'package:untitled2/presentation/auth/providers/auth_provider.dart';

class AsignarTrabajadorCafeteriaScreen extends StatefulWidget {
  final Proveedor? empresa;
  final Cafeteria? cafeteriaInicial;

  const AsignarTrabajadorCafeteriaScreen({
    super.key,
    this.empresa,
    this.cafeteriaInicial,
  });

  @override
  State<AsignarTrabajadorCafeteriaScreen> createState() => _AsignarTrabajadorCafeteriaScreenState();
}

class _AsignarTrabajadorCafeteriaScreenState extends State<AsignarTrabajadorCafeteriaScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _deleting = false;

  List<Proveedor> _empresas = [];
  List<Cafeteria> _cafeterias = [];
  List<Trabajador> _trabajadores = [];
  List<AsignacionTrabajador> _asignaciones = [];
  Map<String, String> _nombresReales = {};

  String? _selectedProviderId;
  String? _selectedCafeteriaId;
  String? _selectedWorkerId;

  final _rolCtrl = TextEditingController(text: 'Auxiliar');
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _rolCtrl.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _loading = true);
    try {
      if (widget.empresa != null) {
        _selectedProviderId = widget.empresa!.idProveedor;
      } else {
        final accountId = context.read<AuthProvider>().activeAccountId;
        _empresas = await ApiService.getMisProveedores(accountId);
        _selectedProviderId = _empresas.isNotEmpty ? _empresas.first.idProveedor : null;
      }

      _cafeterias = await ApiService.getCafeterias();
      _selectedCafeteriaId = widget.cafeteriaInicial?.idCafeteria ??
          (_cafeterias.isNotEmpty ? _cafeterias.first.idCafeteria : null);

      await _loadWorkersForSelectedProvider();
      await _loadAsignaciones();

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron cargar datos: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadWorkersForSelectedProvider() async {
    if (_selectedProviderId == null || _selectedProviderId!.isEmpty) {
      _trabajadores = [];
      _selectedWorkerId = null;
      return;
    }

    _trabajadores = await ApiService.getTrabajadoresDeEmpresa(_selectedProviderId!);
    _selectedWorkerId = _trabajadores.isNotEmpty ? _trabajadores.first.idTrabajador : null;

    final futures = _trabajadores.map((w) async {
      try {
        final datos = await ApiService.getSecurityUserById(w.idAccount);
        final nombre = datos['primerNombre'] ?? '';
        final apellido = datos['primerApellido'] ?? '';
        String fullName = '$nombre $apellido'.trim();
        if (fullName.isEmpty) {
          fullName = datos['correo'] ?? datos['celular'] ?? '';
        }
        if (fullName.isNotEmpty) {
          _nombresReales[w.idTrabajador] = fullName;
        }
      } catch (_) {}
    });
    await Future.wait(futures);
  }

  Future<void> _loadAsignaciones() async {
    if (_selectedCafeteriaId == null || _selectedCafeteriaId!.isEmpty) {
      _asignaciones = [];
      return;
    }

    _asignaciones = await ApiService.getAssignmentsByCafeteria(_selectedCafeteriaId!);
  }

  String _nombreProveedor(String? providerId) {
    if (providerId == null || providerId.isEmpty) return 'Sin proveedor';
    for (final empresa in _empresas) {
      if (empresa.idProveedor == providerId) return empresa.nombreProveedor;
    }
    return 'Proveedor asignado';
  }

  String _nombreColegio(String schoolId) {
    return ApiService.schoolNameOf(schoolId) ?? 'Colegio sin nombre';
  }

  String _nombreTrabajador(String workerId) {
    Trabajador? worker;
    for (final row in _trabajadores) {
      if (row.idTrabajador == workerId) {
        worker = row;
        break;
      }
    }
    if (worker == null) return 'Trabajador';

    final realName = _nombresReales[workerId];
    if (realName != null && realName.isNotEmpty) {
      return '$realName - ${worker.cargoTrabajador ?? "Sin cargo"}';
    }

    if ((worker.cargoTrabajador ?? '').trim().isNotEmpty) return worker.cargoTrabajador!;
    return 'Trabajador';
  }

  Cafeteria? get _cafeteriaSeleccionada {
    final id = _selectedCafeteriaId;
    if (id == null) return null;
    final filtered = _cafeterias.where((c) => c.idCafeteria == id);
    if (filtered.isEmpty) return null;
    return filtered.first;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _asignar() async {
    if (_selectedWorkerId == null || _selectedCafeteriaId == null) return;
    if (_rolCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un rol para la asignación'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ApiService.asignarTrabajadorACafeteria(
        workerId: _selectedWorkerId!,
        cafeteriaId: _selectedCafeteriaId!,
        role: _rolCtrl.text.trim(),
        startDate: _startDate,
      );

      await _loadAsignaciones();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trabajador asignado correctamente'),
          backgroundColor: AppTheme.accent,
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo asignar trabajador: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _eliminarAsignacion(String id) async {
    setState(() => _deleting = true);
    try {
      await ApiService.eliminarAsignacion(id);
      await _loadAsignaciones();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asignación eliminada correctamente'),
          backgroundColor: AppTheme.accent,
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar la asignación: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cafeteriaActual = _cafeteriaSeleccionada;
    final providerValue = _selectedProviderId != null && _empresas.any((e) => e.idProveedor == _selectedProviderId)
      ? _selectedProviderId
      : null;
    final cafeteriaValue = _selectedCafeteriaId != null && _cafeterias.any((c) => c.idCafeteria == _selectedCafeteriaId)
      ? _selectedCafeteriaId
      : null;
    final workerValue = _selectedWorkerId != null && _trabajadores.any((w) => w.idTrabajador == _selectedWorkerId)
      ? _selectedWorkerId
      : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Asignar trabajador')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.empresa == null) ...[
                  DropdownButtonFormField<String>(
                    value: providerValue,
                    decoration: const InputDecoration(
                      labelText: 'Empresa / proveedor *',
                      prefixIcon: Icon(Icons.business_rounded),
                    ),
                    items: _empresas
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.idProveedor,
                            child: Text(e.nombreProveedor),
                          ),
                        )
                        .toList(),
                    onChanged: (v) async {
                      setState(() {
                        _selectedProviderId = v;
                        _trabajadores = [];
                        _selectedWorkerId = null;
                      });
                      await _loadWorkersForSelectedProvider();
                      if (!mounted) return;
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                DropdownButtonFormField<String>(
                  value: cafeteriaValue,
                  decoration: const InputDecoration(
                    labelText: 'Cafetería *',
                    prefixIcon: Icon(Icons.coffee_rounded),
                  ),
                  items: _cafeterias
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c.idCafeteria,
                          child: Text(c.nombreCafeteria ?? 'Cafetería sin nombre'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) async {
                    setState(() => _selectedCafeteriaId = v);
                    await _loadAsignaciones();
                    if (!mounted) return;
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                if (cafeteriaActual != null)
                  Text(
                    'Colegio: ${_nombreColegio(cafeteriaActual.idColegio)} · Proveedor: ${_nombreProveedor(cafeteriaActual.idProveedor)}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: workerValue,
                  decoration: const InputDecoration(
                    labelText: 'Trabajador *',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  items: _trabajadores
                      .map(
                        (w) => DropdownMenuItem<String>(
                          value: w.idTrabajador,
                          child: Text(_nombreTrabajador(w.idTrabajador)),
                        ),
                      )
                      .toList(),
                  onChanged: _trabajadores.isEmpty ? null : (v) => setState(() => _selectedWorkerId = v),
                ),
                if (_trabajadores.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'No hay trabajadores disponibles para esta empresa.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _rolCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Rol en cafetería *',
                    prefixIcon: Icon(Icons.badge_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha inicio',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    child: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_saving || _selectedWorkerId == null || _selectedCafeteriaId == null)
                        ? null
                        : _asignar,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Asignar trabajador'),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Asignaciones actuales',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                if (_asignaciones.isEmpty)
                  const Text(
                    'No hay asignaciones registradas para esta cafetería.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  )
                else
                  ..._asignaciones.map(
                    (a) => Card(
                      child: ListTile(
                        title: Text(a.role ?? 'Sin rol'),
                        subtitle: Text('Trabajador: ${_nombreTrabajador(a.workerId)}'),
                        trailing: IconButton(
                          onPressed: _deleting ? null : () => _eliminarAsignacion(a.id),
                          icon: const Icon(Icons.delete_rounded, color: AppTheme.danger),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
