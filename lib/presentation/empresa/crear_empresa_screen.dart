import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled2/main.dart';
import 'package:untitled2/data/remote/datasource/api_service.dart';
import 'package:untitled2/presentation/auth/providers/auth_provider.dart';

class CrearEmpresaScreen extends StatefulWidget {
  final Map<String, dynamic>? empresaExistente;

  const CrearEmpresaScreen({super.key, this.empresaExistente});

  bool get modoEdicion => empresaExistente != null;

  @override
  State<CrearEmpresaScreen> createState() => _CrearEmpresaScreenState();
}

class _CrearEmpresaScreenState extends State<CrearEmpresaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _nitCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _direccionFactCtrl;
  late final TextEditingController _oficinaCtrl;
  late final TextEditingController _ciudadCtrl;

  String? _paisSeleccionado;

  static const List<String> _paises = [
    'Colombia', 'México', 'Argentina', 'Chile',
    'Perú', 'Ecuador', 'Venezuela', 'España',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.empresaExistente;
    _nombreCtrl = TextEditingController(text: e?['nombre_proveedor'] ?? '');
    _nitCtrl = TextEditingController(text: e?['registro_empresa_proveedor'] ?? '');
    _emailCtrl = TextEditingController(text: e?['email_contacto_proveedor'] ?? '');
    _telefonoCtrl = TextEditingController(text: e?['telefono_contacto_proveedor'] ?? '');
    _direccionFactCtrl = TextEditingController(text: e?['direccion_facturacion'] ?? '');
    _oficinaCtrl = TextEditingController(text: e?['oficina'] ?? '');
    _ciudadCtrl = TextEditingController(text: e?['ciudad'] ?? '');
    _paisSeleccionado = e?['pais'];
    if (_paisSeleccionado != null && !_paises.contains(_paisSeleccionado)) {
      _paisSeleccionado = null;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _nitCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionFactCtrl.dispose();
    _oficinaCtrl.dispose();
    _ciudadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (widget.modoEdicion) {
        final idProveedor = widget.empresaExistente?['id_proveedor']?.toString() ??
            widget.empresaExistente?['id']?.toString();

        if (idProveedor == null || idProveedor.isEmpty) {
          throw Exception('No se encontró el ID de la empresa a editar');
        }

        await ApiService.actualizarProveedor(
          idProveedor: idProveedor,
          nombre: _nombreCtrl.text.trim(),
          registro: _nitCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim(),
          pais: _paisSeleccionado,
          ciudad: _ciudadCtrl.text.trim(),
          direccion: _direccionFactCtrl.text.trim(),
          oficina: _oficinaCtrl.text.trim(),
        );
      } else {
        final accountId = context.read<AuthProvider>().activeAccountId;

        if (accountId.trim().isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: no se encontró tu ID de cuenta. Cierra sesión e inicia de nuevo.'),
                backgroundColor: AppTheme.danger,
              ),
            );
          }
          return;
        }

        await ApiService.crearProveedor(
          accountId: accountId,
          nombre: _nombreCtrl.text.trim(),
          registro: _nitCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim(),
          pais: _paisSeleccionado,
          ciudad: _ciudadCtrl.text.trim(),
          direccion: _direccionFactCtrl.text.trim(),
          oficina: _oficinaCtrl.text.trim(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.modoEdicion
                ? 'Empresa actualizada correctamente'
                : 'Empresa creada correctamente',
          ),
          backgroundColor: AppTheme.accent,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar la empresa: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modoEdicion ? 'Editar empresa' : 'Nueva empresa'),
        leading: const BackButton(),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionHeader(
              icon: Icons.business_rounded,
              title: 'Información de la empresa',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Nombre de la empresa *',
                hintText: 'Ej: Cafetería Los Andes S.A.S.',
                prefixIcon: Icon(Icons.storefront_rounded, color: AppTheme.textSecondary, size: 20),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'El nombre es requerido' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nitCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'NIT / Registro empresa *',
                hintText: 'Ej: 900123456-7',
                prefixIcon: Icon(Icons.numbers_rounded, color: AppTheme.textSecondary, size: 20),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.trim().isEmpty ? 'El NIT es requerido' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Email de contacto',
                hintText: 'contacto@miempresa.com',
                prefixIcon: Icon(Icons.email_rounded, color: AppTheme.textSecondary, size: 20),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v != null && v.isNotEmpty && !v.contains('@')) {
                  return 'Ingresa un email válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _telefonoCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Teléfono de contacto',
                hintText: '+57 300 000 0000',
                prefixIcon: Icon(Icons.phone_rounded, color: AppTheme.textSecondary, size: 20),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.location_on_rounded,
              title: 'Ubicación y facturación',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paisSeleccionado,
              dropdownColor: AppTheme.cardBg,
              style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Poppins'),
              decoration: const InputDecoration(
                labelText: 'País *',
                prefixIcon: Icon(Icons.flag_rounded, color: AppTheme.textSecondary),
              ),
              hint: const Text('Selecciona un país'),
              items: _paises
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _paisSeleccionado = v),
              validator: (v) => v == null ? 'Selecciona un país' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _ciudadCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Ciudad *',
                hintText: 'Ej: Bogotá',
                prefixIcon: Icon(Icons.location_city_rounded, color: AppTheme.textSecondary, size: 20),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'La ciudad es requerida' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _direccionFactCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Dirección de facturación *',
                hintText: 'Calle 123 # 45-67, Barrio',
                prefixIcon: Icon(Icons.receipt_long_rounded, color: AppTheme.textSecondary, size: 20),
              ),
              maxLines: 2,
              validator: (v) => v == null || v.trim().isEmpty ? 'La dirección es requerida' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _oficinaCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Oficina / Local',
                hintText: 'Ej: Piso 3, Oficina 301',
                prefixIcon: Icon(Icons.door_front_door_rounded, color: AppTheme.textSecondary, size: 20),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _guardar,
                child: _isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(widget.modoEdicion ? 'Guardar cambios' : 'Crear empresa'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppTheme.accent),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
