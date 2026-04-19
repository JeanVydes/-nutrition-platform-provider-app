import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled2/main.dart';
import 'package:untitled2/data/remote/datasource/api_service.dart';
import 'package:untitled2/presentation/auth/providers/auth_provider.dart';

class CrearEmpresaScreen extends StatefulWidget {
  /// Si viene con datos, entra en modo edición
  final Map<String, dynamic>? empresaExistente;

  const CrearEmpresaScreen({super.key, this.empresaExistente});

  bool get modoEdicion => empresaExistente != null;

  @override
  State<CrearEmpresaScreen> createState() => _CrearEmpresaScreenState();
}

class _CrearEmpresaScreenState extends State<CrearEmpresaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores para cada campo del formulario
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _nitCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _direccionFactCtrl;
  late final TextEditingController _oficinaCtrl;
  late final TextEditingController _ciudadCtrl;

  String? _paisSeleccionado;

  // Países de ejemplo (en producción carga desde API)
  static const List<String> _paises = [
    'Colombia',
    'México',
    'Argentina',
    'Chile',
    'Perú',
    'Ecuador',
    'Venezuela',
    'España',
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            // ── Encabezado ─────────────────────────────
            _SectionHeader(
              icon: Icons.business_rounded,
              title: 'Información de la empresa',
            ),
            const SizedBox(height: 16),

            // ── Nombre ─────────────────────────────────
            _AppTextField(
              controller: _nombreCtrl,
              label: 'Nombre de la empresa *',
              hint: 'Ej: Cafetería Los Andes S.A.S.',
              icon: Icons.storefront_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'El nombre es requerido' : null,
            ),
            const SizedBox(height: 14),

            // ── NIT ────────────────────────────────────
            _AppTextField(
              controller: _nitCtrl,
              label: 'NIT / Registro empresa *',
              hint: 'Ej: 900123456-7',
              icon: Icons.numbers_rounded,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'El NIT es requerido' : null,
            ),
            const SizedBox(height: 14),

            // ── Email ──────────────────────────────────
            _AppTextField(
              controller: _emailCtrl,
              label: 'Email de contacto',
              hint: 'contacto@miempresa.com',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v != null && v.isNotEmpty && !v.contains('@')) {
                  return 'Ingresa un email válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Teléfono ───────────────────────────────
            _AppTextField(
              controller: _telefonoCtrl,
              label: 'Teléfono de contacto',
              hint: '+57 300 000 0000',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // ── Sección Ubicación ──────────────────────
            _SectionHeader(
              icon: Icons.location_on_rounded,
              title: 'Ubicación y facturación',
            ),
            const SizedBox(height: 16),

            // ── País ───────────────────────────────────
            DropdownButtonFormField<String>(
              value: _paisSeleccionado,
              decoration: InputDecoration(
                labelText: 'País *',
                prefixIcon: const Icon(
                  Icons.flag_rounded,
                  color: AppTheme.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              hint: const Text('Selecciona un país'),
              items: _paises
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _paisSeleccionado = v),
              validator: (v) => v == null ? 'Selecciona un país' : null,
            ),
            const SizedBox(height: 14),

            // ── Ciudad ─────────────────────────────────
            _AppTextField(
              controller: _ciudadCtrl,
              label: 'Ciudad *',
              hint: 'Ej: Bogotá',
              icon: Icons.location_city_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'La ciudad es requerida' : null,
            ),
            const SizedBox(height: 14),

            // ── Dirección facturación ──────────────────
            _AppTextField(
              controller: _direccionFactCtrl,
              label: 'Dirección de facturación *',
              hint: 'Calle 123 # 45-67, Barrio',
              icon: Icons.receipt_long_rounded,
              maxLines: 2,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'La dirección es requerida' : null,
            ),
            const SizedBox(height: 14),

            // ── Oficina ────────────────────────────────
            _AppTextField(
              controller: _oficinaCtrl,
              label: 'Oficina / Local',
              hint: 'Ej: Piso 3, Oficina 301',
              icon: Icons.door_front_door_rounded,
            ),
            const SizedBox(height: 32),

            // ── Botón guardar ──────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _guardar,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        widget.modoEdicion ? 'Guardar cambios' : 'Crear empresa',
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// WIDGETS REUTILIZABLES DEL FORMULARIO
// ─────────────────────────────────────────

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
            color: AppTheme.accent.withOpacity(0.12),
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

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _AppTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: AppTheme.textSecondary, size: 20)
            : null,
      ),
    );
  }
}
