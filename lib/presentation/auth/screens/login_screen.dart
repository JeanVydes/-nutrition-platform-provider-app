import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled2/main.dart';
import 'package:untitled2/presentation/auth/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _pinRequested = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _identifierController.dispose();
    _pinController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _resendCooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _requestPin() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.requestPin(identifier);
      if (!mounted) return;
      setState(() => _pinRequested = true);
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PIN enviado. Revisa tu SMS o correo.'),
          backgroundColor: AppTheme.accent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo enviar el PIN: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _doLogin() async {
    final identifier = _identifierController.text.trim();
    final pin = _pinController.text.trim();
    if (identifier.isEmpty || pin.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.loginWithPin(identifier: identifier, pin: pin);
      // Auth gate will auto-redirect to HomeScreen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PIN inválido o expirado: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Dev token dialog ────────────────────────
  void _showDevTokenDialog() {
    final tokenCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dev: insertar token', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: tokenCtrl,
          maxLines: 4,
          style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Pega tu JWT aquí...',
            hintStyle: TextStyle(fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final token = tokenCtrl.text.trim();
              if (token.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final auth = context.read<AuthProvider>();
                await auth.loginWithDevToken(token);
                // Auth gate auto-redirects
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Token inválido: $e'),
                    backgroundColor: AppTheme.danger,
                  ),
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Ingresar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main login form ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo / branding ─────────────
                  Container(
                    width: 64,
                    height: 64,
                    margin: const EdgeInsets.only(bottom: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      size: 32,
                      color: AppTheme.accent,
                    ),
                  ),
                  const Text(
                    'Pay School Snacks',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Inicia sesión para continuar',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // ── Phone field ─────────────────
                  TextField(
                    controller: _identifierController,
                    enabled: !_pinRequested,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Número de celular',
                      hintText: '3001234567',
                      prefixIcon: const Icon(Icons.phone_iphone_rounded,
                          color: AppTheme.textSecondary),
                      suffixIcon: _pinRequested
                          ? IconButton(
                              icon: const Icon(Icons.edit_rounded,
                                  size: 18, color: AppTheme.textSecondary),
                              tooltip: 'Cambiar número',
                              onPressed: () {
                                setState(() {
                                  _pinRequested = false;
                                  _pinController.clear();
                                  _cooldownTimer?.cancel();
                                  _resendCooldown = 0;
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (_pinRequested) ...[
                    // ── PIN field ───────────────────
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofocus: true,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        letterSpacing: 8,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'PIN (6 dígitos)',
                        prefixIcon: Icon(Icons.lock_outline_rounded,
                            color: AppTheme.textSecondary),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _resendCooldown > 0 || _isLoading
                            ? null
                            : _requestPin,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                          disabledForegroundColor: AppTheme.textSecondary,
                        ),
                        child: Text(
                          _resendCooldown > 0
                              ? 'Reenviar PIN en ${_resendCooldown}s'
                              : 'Reenviar PIN',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 8),

                  // ── Action button ─────────────────
                  SizedBox(
                    height: 50,
                    child: _pinRequested
                        ? ElevatedButton(
                            onPressed: _isLoading ? null : _doLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Text('Ingresar'),
                          )
                        : OutlinedButton(
                            onPressed: _isLoading ? null : _requestPin,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5),
                                  )
                                : const Text('Enviar PIN'),
                          ),
                  ),
                ],
              ),
            ),

            // ── Dev token button (bottom-right corner) ──
            Positioned(
              right: 8,
              bottom: 8,
              child: GestureDetector(
                onTap: _showDevTokenDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.code_rounded, size: 14, color: AppTheme.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        'DEV',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
