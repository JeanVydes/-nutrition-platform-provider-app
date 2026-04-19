// ─────────────────────────────────────────
// MODELO: Proveedor (Empresa)
// Tabla: proveedores
// ─────────────────────────────────────────
class Proveedor {
  final String idProveedor;
  final String idAccount;
  final String nombreProveedor;
  final String? registroEmpresaProveedor; // NIT
  final String? emailContactoProveedor;
  final String? telefonoContactoProveedor;

  // Campos extra del formulario (no en la tabla principal)
  final String? pais;
  final String? ciudad;
  final String? direccionFacturacion;
  final String? oficina;

  const Proveedor({
    required this.idProveedor,
    required this.idAccount,
    required this.nombreProveedor,
    this.registroEmpresaProveedor,
    this.emailContactoProveedor,
    this.telefonoContactoProveedor,
    this.pais,
    this.ciudad,
    this.direccionFacturacion,
    this.oficina,
  });

    factory Proveedor.fromJson(Map<String, dynamic> json) => Proveedor(
      idProveedor: (json['id_proveedor'] ?? json['id'])?.toString() ?? '',
      idAccount: (json['id_account'] ?? json['accountId'])?.toString() ?? '',
      nombreProveedor: (json['nombre_proveedor'] ?? json['name'])?.toString() ?? '',
      registroEmpresaProveedor:
        (json['registro_empresa_proveedor'] ?? json['companyRegistration'])?.toString(),
      emailContactoProveedor:
        (json['email_contacto_proveedor'] ?? json['contactEmail'])?.toString(),
      telefonoContactoProveedor:
        (json['telefono_contacto_proveedor'] ?? json['contactPhone'])?.toString(),
      pais: json['pais']?.toString(),
      ciudad: json['ciudad']?.toString(),
      direccionFacturacion: (json['direccion_facturacion'] ?? json['billingAddress'])?.toString(),
      oficina: json['oficina']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id_proveedor': idProveedor,
        'id_account': idAccount,
        'nombre_proveedor': nombreProveedor,
        'registro_empresa_proveedor': registroEmpresaProveedor,
        'email_contacto_proveedor': emailContactoProveedor,
        'telefono_contacto_proveedor': telefonoContactoProveedor,
        'pais': pais,
        'ciudad': ciudad,
        'direccion_facturacion': direccionFacturacion,
        'oficina': oficina,
      };
}

// ─────────────────────────────────────────
// MODELO: Trabajador
// Tabla: trabajadores
// ─────────────────────────────────────────
class Trabajador {
  final String idTrabajador;
  final String idAccount;
  final String idProveedor;
  final EstadoEmpleoTrabajador estadoEmpleo;
  final String? cargoTrabajador;
  final String? tipoContratoTrabajador;
  final DateTime? fechaContratacion;
  final double? salarioTrabajador;
  final DateTime creadoEn;

  // Datos enriquecidos del join
  final String? nombreProveedor;
  final List<Cafeteria>? cafeterias;

  const Trabajador({
    required this.idTrabajador,
    required this.idAccount,
    required this.idProveedor,
    this.estadoEmpleo = EstadoEmpleoTrabajador.activo,
    this.cargoTrabajador,
    this.tipoContratoTrabajador,
    this.fechaContratacion,
    this.salarioTrabajador,
    required this.creadoEn,
    this.nombreProveedor,
    this.cafeterias,
  });

    factory Trabajador.fromJson(Map<String, dynamic> json) => Trabajador(
      idTrabajador: (json['id_trabajador'] ?? json['id'])?.toString() ?? '',
      idAccount: (json['id_account'] ?? json['accountId'])?.toString() ?? '',
      idProveedor: (json['id_proveedor'] ?? json['providerId'])?.toString() ?? '',
      estadoEmpleo: EstadoEmpleoExt.fromString(
        (json['estado_empleo_trabajador'] ?? json['employmentStatus'] ?? 'activo').toString(),
      ),
      cargoTrabajador: (json['cargo_trabajador'] ?? json['position'])?.toString(),
      tipoContratoTrabajador: (json['tipo_contrato_trabajador'] ?? json['contractType'])?.toString(),
      fechaContratacion: (json['fecha_contratacion_trabajador'] ?? json['hireDate']) != null
        ? DateTime.parse((json['fecha_contratacion_trabajador'] ?? json['hireDate']).toString())
            : null,
      salarioTrabajador: (json['salario_trabajador'] ?? json['salary']) != null
        ? double.tryParse((json['salario_trabajador'] ?? json['salary']).toString())
        : null,
      creadoEn: json['creado_en'] != null
        ? DateTime.parse(json['creado_en'].toString())
        : DateTime.now(),
      nombreProveedor: (json['nombre_proveedor'] ?? json['providerName'])?.toString(),
        cafeterias: (json['cafeterias'] as List<dynamic>?)
            ?.map((c) => Cafeteria.fromJson(c))
            .toList(),
      );
}

// ─────────────────────────────────────────
// ENUM: Estado Empleo Trabajador
// Refleja el ENUM de PostgreSQL
// ─────────────────────────────────────────
enum EstadoEmpleoTrabajador { activo, suspendido, retirado }

extension EstadoEmpleoExt on EstadoEmpleoTrabajador {
  static EstadoEmpleoTrabajador fromString(String s) {
    switch (s) {
      case 'suspendido':
        return EstadoEmpleoTrabajador.suspendido;
      case 'retirado':
        return EstadoEmpleoTrabajador.retirado;
      default:
        return EstadoEmpleoTrabajador.activo;
    }
  }

  String get label {
    switch (this) {
      case EstadoEmpleoTrabajador.activo:
        return 'Activo';
      case EstadoEmpleoTrabajador.suspendido:
        return 'Suspendido';
      case EstadoEmpleoTrabajador.retirado:
        return 'Retirado';
    }
  }

  // Para el chip de color en UI
  int get colorValue {
    switch (this) {
      case EstadoEmpleoTrabajador.activo:
        return 0xFF00C896;
      case EstadoEmpleoTrabajador.suspendido:
        return 0xFFF59E0B;
      case EstadoEmpleoTrabajador.retirado:
        return 0xFFEF4444;
    }
  }
}

// ─────────────────────────────────────────
// MODELO: Cafeteria
// Tabla: cafeterias
// ─────────────────────────────────────────
class Cafeteria {
  final String idCafeteria;
  final String idColegio;
  final String? idProveedor;
  final String? nombreCafeteria;

  const Cafeteria({
    required this.idCafeteria,
    required this.idColegio,
    this.idProveedor,
    this.nombreCafeteria,
  });

  factory Cafeteria.fromJson(Map<String, dynamic> json) => Cafeteria(
        idCafeteria: (json['id_cafeteria'] ?? json['id'])?.toString() ?? '',
        idColegio: (json['id_colegio'] ?? json['schoolId'])?.toString() ?? '',
      idProveedor: (json['id_proveedor'] ?? json['providerId'])?.toString(),
        nombreCafeteria: (json['nombre_cafeteria'] ?? json['name'])?.toString(),
      );

    Map<String, dynamic> toJson() => {
      'id': idCafeteria,
      'schoolId': idColegio,
      if (idProveedor != null && idProveedor!.isNotEmpty) 'providerId': idProveedor,
      'name': nombreCafeteria,
    };
}

class AsignacionTrabajador {
  final String id;
  final String workerId;
  final String cafeteriaId;
  final String? role;
  final DateTime? startDate;
  final DateTime? endDate;

  const AsignacionTrabajador({
    required this.id,
    required this.workerId,
    required this.cafeteriaId,
    this.role,
    this.startDate,
    this.endDate,
  });

  factory AsignacionTrabajador.fromJson(Map<String, dynamic> json) =>
      AsignacionTrabajador(
        id: (json['id'] ?? json['id_asignacion'])?.toString() ?? '',
        workerId: (json['workerId'] ?? json['id_trabajador'])?.toString() ?? '',
        cafeteriaId: (json['cafeteriaId'] ?? json['id_cafeteria'])?.toString() ?? '',
        role: (json['role'] ?? json['rol'])?.toString(),
        startDate: (json['startDate'] ?? json['start_date']) != null
            ? DateTime.tryParse((json['startDate'] ?? json['start_date']).toString())
            : null,
        endDate: (json['endDate'] ?? json['end_date']) != null
            ? DateTime.tryParse((json['endDate'] ?? json['end_date']).toString())
            : null,
      );
}
