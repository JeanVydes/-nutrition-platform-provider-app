import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled2/data/remote/datasource/api_service.dart';
import 'package:untitled2/domain/model/models.dart';
import 'package:untitled2/main.dart';
import 'package:untitled2/presentation/auth/providers/auth_provider.dart';

class CrearCafeteriaScreen extends StatefulWidget {
  final Proveedor? empresa;
  final Cafeteria? cafeteriaExistente;

  const CrearCafeteriaScreen({
    super.key,
    this.empresa,
    this.cafeteriaExistente,
  });

  bool get modoEdicion => cafeteriaExistente != null;

  @override
  State<CrearCafeteriaScreen> createState() => _CrearCafeteriaScreenState();
}

class _CrearCafeteriaScreenState extends State<CrearCafeteriaScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSchoolId;
  List<String> _schoolIds = [];
  late final TextEditingController _schoolNameCtrl;
  late final TextEditingController _nombreCtrl;
  String _selectedProviderId = '';
  List<Proveedor> _proveedores = [];
  bool _loading = false;
  bool _loadingProviders = false;
  bool _loadingSchools = false;

  @override
  void initState() {
    super.initState();
    _selectedSchoolId = widget.cafeteriaExistente?.idColegio;
    _schoolNameCtrl = TextEditingController(
      text: ApiService.schoolNameOf(widget.cafeteriaExistente?.idColegio ?? '') ?? '',
    );
    _nombreCtrl = TextEditingController(text: widget.cafeteriaExistente?.nombreCafeteria ?? '');
    _selectedProviderId = widget.empresa?.idProveedor ?? widget.cafeteriaExistente?.idProveedor ?? '';
    _loadProveedores();
    _loadSchoolIds();
  }

  Future<void> _loadSchoolIds() async {
    setState(() => _loadingSchools = true);
    try {
      final ids = await ApiService.getSchoolIds();
      if (!mounted) return;
      setState(() {
        _schoolIds = List<String>.from(ids);
        if ((_selectedSchoolId ?? '').isNotEmpty && !_schoolIds.contains(_selectedSchoolId)) {
          _schoolIds.insert(0, _selectedSchoolId!);
        }
        if ((_selectedSchoolId ?? '').isEmpty && _schoolIds.isNotEmpty) {
          _selectedSchoolId = _schoolIds.first;
        }
      });
    } finally {
      if (mounted) setState(() => _loadingSchools = false);
    }
  }

  Future<void> _loadProveedores() async {
    if (widget.empresa != null) return;
    setState(() => _loadingProviders = true);
    try {
      final accountId = context.read<AuthProvider>().activeAccountId;
      final providers = await ApiService.getMisProveedores(accountId);
      if (!mounted) return;
      setState(() {
        _proveedores = providers;
        if (_selectedProviderId.isNotEmpty && !_proveedores.any((p) => p.idProveedor == _selectedProviderId)) {
          _selectedProviderId = '';
        }
      });
    } finally {
      if (mounted) setState(() => _loadingProviders = false);
    }
  }

  @override
  void dispose() {
    _schoolNameCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      if (widget.modoEdicion) {
        await ApiService.actualizarCafeteria(
          idCafeteria: widget.cafeteriaExistente!.idCafeteria,
          schoolId: _selectedSchoolId!.trim(),
          name: _nombreCtrl.text.trim(),
          providerId: _selectedProviderId,
          schoolName: _schoolNameCtrl.text.trim(),
        );
      } else {
        await ApiService.crearCafeteria(
          schoolId: _selectedSchoolId!.trim(),
          name: _nombreCtrl.text.trim(),
          providerId: _selectedProviderId,
          schoolName: _schoolNameCtrl.text.trim(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.modoEdicion
              ? 'Cafetería actualizada correctamente'
              : 'Cafetería creada correctamente'),
          backgroundColor: AppTheme.accent,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo crear la cafetería: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modoEdicion ? 'Editar cafetería' : 'Nueva cafetería'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.empresa != null)
              Text(
                'Empresa: ${widget.empresa!.nombreProveedor}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (widget.empresa != null) const SizedBox(height: 16),
            if (widget.empresa == null)
              DropdownButtonFormField<String>(
                value: _selectedProviderId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Empresa/proveedor *',
                  prefixIcon: Icon(Icons.business_rounded),
                ),
                items: [
                  ..._proveedores.map(
                    (p) => DropdownMenuItem<String>(
                      value: p.idProveedor,
                      child: Text(p.nombreProveedor),
                    ),
                  ),
                ],
                onChanged: _loadingProviders ? null : (v) => setState(() => _selectedProviderId = v ?? ''),
                validator: (v) => v == null || v.trim().isEmpty ? 'Selecciona una empresa' : null,
              ),
            if (widget.empresa == null) const SizedBox(height: 16),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSchoolId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: _loadingSchools ? 'Cargando colegios...' : 'ID colegio *',
                prefixIcon: const Icon(Icons.school_rounded),
              ),
              items: _schoolIds
                  .map((id) => DropdownMenuItem<String>(value: id, child: Text(id)))
                  .toList(),
              onChanged: _loadingSchools ? null : (v) => setState(() => _selectedSchoolId = v),
              validator: (v) => v == null || v.trim().isEmpty ? 'Selecciona un colegio' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _schoolNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del colegio *',
                prefixIcon: Icon(Icons.apartment_rounded),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de cafetería *',
                prefixIcon: Icon(Icons.coffee_rounded),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _guardar,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(widget.modoEdicion ? 'Guardar cambios' : 'Crear cafetería'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
