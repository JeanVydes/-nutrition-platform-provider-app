import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled2/main.dart';
import 'package:untitled2/data/remote/datasource/api_service.dart';
import 'package:untitled2/presentation/auth/providers/auth_provider.dart';

class AgregarTrabajadorScreen extends StatefulWidget {
  final String? idProveedor;
  final String? nombreEmpresa;

  const AgregarTrabajadorScreen({
    super.key,
    this.idProveedor,
    this.nombreEmpresa,
  });

  @override
  State<AgregarTrabajadorScreen> createState() =>
      _AgregarTrabajadorScreenState();
}

class _AgregarTrabajadorScreenState extends State<AgregarTrabajadorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _busquedaCtrl = TextEditingController();
  bool _buscando = false;
  String? _usuarioEncontrado;
  String? _idAccountEncontrado;

  // Form datos del trabajador
  final _formKey = GlobalKey<FormState>();
  final _cargoCtrl = TextEditingController();
  final _salarioCtrl = TextEditingController();
  String? _tipoContrato;
  DateTime? _fechaContratacion;
  bool _isLoading = false;

  static const List<String> _tiposContrato = [
    'Indefinido',
    'Término fijo',
    'Obra o labor',
    'Prestación de servicios',
    'Aprendizaje',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _busquedaCtrl.dispose();
    _cargoCtrl.dispose();
    _salarioCtrl.dispose();
    super.dispose();
  }

  // ── Buscar usuario real en el servicio de seguridad ──
  Future<void> _buscarUsuario() async {
    final query = _busquedaCtrl.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el UUID del usuario a buscar')),
      );
      return;
    }

    setState(() {
      _buscando = true;
      _usuarioEncontrado = null;
      _idAccountEncontrado = null;
    });

    try {
      final datos = await ApiService.getSecurityUserById(query);

      if (!mounted) return;

      final idUsuario = datos['idUsuario']?.toString() ?? query;
      final nombre = datos['primerNombre']?.toString() ?? '';
      final apellido = datos['primerApellido']?.toString() ?? '';
      final correo = datos['correo']?.toString() ?? '';
      final celular = datos['celular']?.toString() ?? '';
      final roles = (datos['roles'] as List?)?.join(', ') ?? '';

      final displayName = [nombre, apellido]
          .where((s) => s.isNotEmpty)
          .join(' ');

      final details = <String>[
        if (displayName.isNotEmpty) displayName,
        if (correo.isNotEmpty) correo,
        if (celular.isNotEmpty) 'Tel: $celular',
        if (roles.isNotEmpty) 'Roles: $roles',
      ];

      setState(() {
        _buscando = false;
        _idAccountEncontrado = idUsuario;
        _usuarioEncontrado = details.isNotEmpty
            ? details.join('\n')
            : 'Usuario encontrado: $idUsuario';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _buscando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se encontró el usuario: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  // ── Usar mi propio accountId ────────────────────────
  void _usarMiCuenta() {
    final auth = context.read<AuthProvider>();
    final profile = auth.currentProfile;
    final accountId = auth.activeAccountId;

    if (accountId.isEmpty || profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay sesión activa')),
      );
      return;
    }

    setState(() {
      _idAccountEncontrado = accountId;
      _usuarioEncontrado =
          '${profile.nombreCompleto}\n${profile.email ?? profile.phone ?? ''}\nRoles: ${profile.rolLabel}';
      _busquedaCtrl.text = accountId;
    });
  }

  // ── Vincular el trabajador ───────────────────────────
  Future<void> _vincularTrabajador() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usuarioEncontrado == null || _idAccountEncontrado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero busca y selecciona un usuario')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.idProveedor == null || widget.idProveedor!.isEmpty) {
        throw Exception('No se recibió el proveedor para vincular el trabajador');
      }

      await ApiService.crearTrabajador(
        accountId: _idAccountEncontrado!,
        providerId: widget.idProveedor!,
        cargo: _cargoCtrl.text.trim(),
        tipoContrato: _tipoContrato,
        fechaContratacion: _fechaContratacion,
        salario: double.tryParse(_salarioCtrl.text.trim().replaceAll(',', '.')),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Trabajador vinculado correctamente'),
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
          content: Text('No se pudo vincular el trabajador: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaContratacion ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.accent, surface: AppTheme.cardBg),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaContratacion = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.nombreEmpresa != null
              ? 'Trabajador · ${widget.nombreEmpresa}'
              : 'Agregar trabajador',
          overflow: TextOverflow.ellipsis,
        ),
        leading: const BackButton(),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Buscar usuario'),
            Tab(text: 'Datos del cargo'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            // ── TAB 1: Buscar usuario ────────────────────
            _Tab1BuscarUsuario(
              controller: _busquedaCtrl,
              buscando: _buscando,
              usuarioEncontrado: _usuarioEncontrado,
              onBuscar: _buscarUsuario,
              onUsarMiCuenta: _usarMiCuenta,
              onSiguiente: _usuarioEncontrado != null
                  ? () => _tabController.animateTo(1)
                  : null,
            ),

            // ── TAB 2: Datos del cargo ───────────────────
            _Tab2DatosCargo(
              cargoCtrl: _cargoCtrl,
              salarioCtrl: _salarioCtrl,
              tipoContrato: _tipoContrato,
              tiposContrato: _tiposContrato,
              fechaContratacion: _fechaContratacion,
              isLoading: _isLoading,
              onChangeTipoContrato: (v) => setState(() => _tipoContrato = v),
              onSeleccionarFecha: _seleccionarFecha,
              onVincular: _vincularTrabajador,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// TAB 1: Buscar usuario
// ─────────────────────────────────────────
class _Tab1BuscarUsuario extends StatelessWidget {
  final TextEditingController controller;
  final bool buscando;
  final String? usuarioEncontrado;
  final VoidCallback onBuscar;
  final VoidCallback onUsarMiCuenta;
  final VoidCallback? onSiguiente;

  const _Tab1BuscarUsuario({
    required this.controller,
    required this.buscando,
    required this.usuarioEncontrado,
    required this.onBuscar,
    required this.onUsarMiCuenta,
    required this.onSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        const Text(
          'Busca al usuario por su UUID (proporcionado por el servicio de seguridad) para vincularlo como trabajador.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 16),

        // ── Botón usar mi cuenta ───────────────────────
        OutlinedButton.icon(
          onPressed: onUsarMiCuenta,
          icon: const Icon(Icons.person_rounded, size: 18),
          label: const Text('Usar mi propia cuenta'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.accent,
            side: const BorderSide(color: AppTheme.accent),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Campo de búsqueda ──────────────────────────
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'UUID del usuario',
                  hintText: '550e8400-e29b-41d4-a716-446655440000',
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppTheme.textSecondary),
                ),
                onFieldSubmitted: (_) => onBuscar(),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: buscando ? null : onBuscar,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              child: buscando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search_rounded),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Resultado de búsqueda ──────────────────────
        if (usuarioEncontrado != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuarioEncontrado!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'Usuario verificado ✓',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onSiguiente,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Continuar'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ] else if (!buscando) ...[
          // Hint visual cuando no hay resultado
          Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.manage_search_rounded,
                    size: 56, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  'Ingresa el UUID del usuario\nque quieres vincular como trabajador',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────
// TAB 2: Datos del cargo
// ─────────────────────────────────────────
class _Tab2DatosCargo extends StatelessWidget {
  final TextEditingController cargoCtrl;
  final TextEditingController salarioCtrl;
  final String? tipoContrato;
  final List<String> tiposContrato;
  final DateTime? fechaContratacion;
  final bool isLoading;
  final ValueChanged<String?> onChangeTipoContrato;
  final VoidCallback onSeleccionarFecha;
  final VoidCallback onVincular;

  const _Tab2DatosCargo({
    required this.cargoCtrl,
    required this.salarioCtrl,
    required this.tipoContrato,
    required this.tiposContrato,
    required this.fechaContratacion,
    required this.isLoading,
    required this.onChangeTipoContrato,
    required this.onSeleccionarFecha,
    required this.onVincular,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        const Text(
          'Completa los datos del cargo del trabajador dentro de tu empresa.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 24),

        // ── Cargo ──────────────────────────────────────
        TextFormField(
          controller: cargoCtrl,
          decoration: const InputDecoration(
            labelText: 'Cargo *',
            hintText: 'Ej: Cajero, Cocinero, Supervisor',
            prefixIcon: Icon(Icons.work_rounded, color: AppTheme.textSecondary),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'El cargo es requerido' : null,
        ),
        const SizedBox(height: 14),

        // ── Tipo de contrato ───────────────────────────
        DropdownButtonFormField<String>(
          value: tipoContrato,
          decoration: InputDecoration(
            labelText: 'Tipo de contrato',
            prefixIcon: const Icon(Icons.description_rounded,
                color: AppTheme.textSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppTheme.inputFill,
          ),
          hint: const Text('Selecciona el tipo'),
          items: tiposContrato
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: onChangeTipoContrato,
        ),
        const SizedBox(height: 14),

        // ── Fecha de contratación ──────────────────────
        GestureDetector(
          onTap: onSeleccionarFecha,
          child: AbsorbPointer(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Fecha de contratación',
                hintText: fechaContratacion != null
                    ? '${fechaContratacion!.day}/${fechaContratacion!.month}/${fechaContratacion!.year}'
                    : 'Seleccionar fecha',
                prefixIcon: const Icon(Icons.calendar_today_rounded,
                    color: AppTheme.textSecondary),
              ),
              controller: TextEditingController(
                text: fechaContratacion != null
                    ? '${fechaContratacion!.day}/${fechaContratacion!.month}/${fechaContratacion!.year}'
                    : '',
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Salario ────────────────────────────────────
        TextFormField(
          controller: salarioCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Salario mensual',
            hintText: 'Ej: 1500000',
            prefixIcon: Icon(Icons.attach_money_rounded,
                color: AppTheme.textSecondary),
            prefixText: '\$ ',
          ),
        ),
        const SizedBox(height: 32),

        // ── Botón vincular ─────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : onVincular,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Vincular trabajador'),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
