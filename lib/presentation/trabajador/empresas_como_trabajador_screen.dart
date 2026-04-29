import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled2/main.dart';
import 'package:untitled2/domain/model/models.dart';
import 'package:untitled2/data/remote/datasource/api_service.dart';
import 'package:untitled2/presentation/auth/providers/auth_provider.dart';

class EmpresasComoTrabajadorScreen extends StatefulWidget {
  final bool isEmbedded;

  const EmpresasComoTrabajadorScreen({super.key, this.isEmbedded = false});

  @override
  State<EmpresasComoTrabajadorScreen> createState() =>
      _EmpresasComoTrabajadorScreenState();
}

class _EmpresasComoTrabajadorScreenState
    extends State<EmpresasComoTrabajadorScreen> {
  bool _isLoading = true;
  List<Trabajador> _empleos = [];

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
    _cargarEmpleos();
  }

  Future<void> _cargarEmpleos() async {
    setState(() => _isLoading = true);
    try {
      final accountId = context.read<AuthProvider>().activeAccountId;

      final empleos = await ApiService.getEmpleosPorCuenta(accountId);
      if (!mounted) return;
      setState(() => _empleos = empleos);
    } catch (e) {
      if (!mounted) return;
      _showError('No se pudieron cargar tus empleos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soy trabajador'),
        leading: widget.isEmbedded ? null : const BackButton(),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            )
          : _empleos.isEmpty
              ? _EmptyStateTrabajador()
              : RefreshIndicator(
                  color: AppTheme.accent,
                  onRefresh: _cargarEmpleos,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: _empleos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) =>
                        _EmpleoCard(trabajador: _empleos[i]),
                  ),
                ),
    );
  }
}

// ─────────────────────────────────────────
// CARD DE EMPLEO
// ─────────────────────────────────────────
class _EmpleoCard extends StatefulWidget {
  final Trabajador trabajador;

  const _EmpleoCard({required this.trabajador});

  @override
  State<_EmpleoCard> createState() => _EmpleoCardState();
}

class _EmpleoCardState extends State<_EmpleoCard> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.trabajador;

    return Card(
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header de la empresa ─────────────────────
          Container(
            color: AppTheme.cardBg,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono empresa
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      (t.nombreProveedor ?? 'E')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
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
                        t.nombreProveedor ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.cargoTrabajador ?? 'Sin cargo',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de estado
                _EstadoBadge(estado: t.estadoEmpleo),
              ],
            ),
          ),

          // ── Datos del empleo ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DatoItem(
                        label: 'Tipo contrato',
                        value: t.tipoContratoTrabajador ?? 'No especificado',
                        icon: Icons.description_rounded,
                      ),
                    ),
                    Expanded(
                      child: _DatoItem(
                        label: 'Fecha inicio',
                        value: t.fechaContratacion != null
                            ? '${t.fechaContratacion!.day}/${t.fechaContratacion!.month}/${t.fechaContratacion!.year}'
                            : 'No registrada',
                        icon: Icons.calendar_today_rounded,
                      ),
                    ),
                  ],
                ),
                if (t.salarioTrabajador != null)
                  Row(
                    children: [
                      Expanded(
                        child: _DatoItem(
                          label: 'Salario mensual',
                          value:
                              '\$${t.salarioTrabajador!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                          icon: Icons.attach_money_rounded,
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
              ],
            ),
          ),

          // ── Separador expandible de cafeterías ───────
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.coffee_rounded,
                      size: 16, color: AppTheme.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Cafeterías asignadas (${t.cafeterias?.length ?? 0})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.accent,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expandido ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded,
                        size: 20, color: AppTheme.accent),
                  ),
                ],
              ),
            ),
          ),

          // ── Lista de cafeterías (expandible) ─────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expandido && (t.cafeterias?.isNotEmpty ?? false)
                ? Container(
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.05),
                      border: const Border(
                        top: BorderSide(color: AppTheme.border),
                      ),
                    ),
                    child: Column(
                      children: t.cafeterias!
                          .map((c) => _CafeteriaRow(cafeteria: c))
                          .toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// BADGE DE ESTADO
// ─────────────────────────────────────────
class _EstadoBadge extends StatelessWidget {
  final EstadoEmpleoTrabajador estado;

  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = Color(estado.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            estado.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// ÍTEM DE DATO
// ─────────────────────────────────────────
class _DatoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DatoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// FILA DE CAFETERÍA
// ─────────────────────────────────────────
class _CafeteriaRow extends StatelessWidget {
  final Cafeteria cafeteria;

  const _CafeteriaRow({required this.cafeteria});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.coffee_rounded,
                size: 18, color: AppTheme.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cafeteria.nombreCafeteria ?? 'Cafetería sin nombre',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
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
class _EmptyStateTrabajador extends StatelessWidget {
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
                color: AppTheme.cardBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.badge_rounded,
                size: 48,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No estás vinculado a ninguna empresa',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando un administrador te vincule a una empresa como trabajador, aparecerá aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
