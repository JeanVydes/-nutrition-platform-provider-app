import 'package:flutter/material.dart';
import 'package:untitled2/domain/model/models.dart';
import 'package:untitled2/data/remote/datasource/api_service.dart';
import 'package:untitled2/main.dart';

class EditarTrabajadorScreen extends StatefulWidget {
  final Trabajador trabajador;

  const EditarTrabajadorScreen({super.key, required this.trabajador});

  @override
  State<EditarTrabajadorScreen> createState() => _EditarTrabajadorScreenState();
}

class _EditarTrabajadorScreenState extends State<EditarTrabajadorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late EstadoEmpleoTrabajador _estadoEmpleo;
  late TextEditingController _cargoController;
  late TextEditingController _contratoController;
  late TextEditingController _salarioController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _estadoEmpleo = widget.trabajador.estadoEmpleo;
    _cargoController = TextEditingController(text: widget.trabajador.cargoTrabajador);
    _contratoController = TextEditingController(text: widget.trabajador.tipoContratoTrabajador);
    _salarioController = TextEditingController(text: widget.trabajador.salarioTrabajador?.toString() ?? '');
  }

  @override
  void dispose() {
    _cargoController.dispose();
    _contratoController.dispose();
    _salarioController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final trabajadorEditado = Trabajador(
        idTrabajador: widget.trabajador.idTrabajador,
        idAccount: widget.trabajador.idAccount,
        idProveedor: widget.trabajador.idProveedor,
        estadoEmpleo: _estadoEmpleo,
        cargoTrabajador: _cargoController.text.trim(),
        tipoContratoTrabajador: _contratoController.text.trim(),
        fechaContratacion: widget.trabajador.fechaContratacion,
        salarioTrabajador: double.tryParse(_salarioController.text.replaceAll(',', '.').trim()),
        creadoEn: widget.trabajador.creadoEn,
        nombreProveedor: widget.trabajador.nombreProveedor,
        cafeterias: widget.trabajador.cafeterias,
      );

      await ApiService.updateTrabajador(trabajadorEditado);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trabajador actualizado correctamente', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.accent,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el trabajador: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Trabajador'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Datos de Usuario (Lectura)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Text('ID: ${widget.trabajador.idTrabajador}'),
                            Text('Aceptado en: ${widget.trabajador.fechaContratacion?.toLocal().toString().split(" ")[0] ?? "N/A"}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Estado Laboral',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<EstadoEmpleoTrabajador>(
                      value: _estadoEmpleo,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      items: EstadoEmpleoTrabajador.values.map((estado) {
                        return DropdownMenuItem<EstadoEmpleoTrabajador>(
                          value: estado,
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: Color(estado.colorValue), size: 12),
                              const SizedBox(width: 8),
                              Text(estado.label),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _estadoEmpleo = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cargoController,
                      decoration: const InputDecoration(
                        labelText: 'Cargo asignado',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contratoController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de contrato',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _salarioController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Salario base',
                        prefixIcon: Icon(Icons.attach_money_outlined),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _guardarCambios,
                        child: const Text('Guardar Cambios'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
