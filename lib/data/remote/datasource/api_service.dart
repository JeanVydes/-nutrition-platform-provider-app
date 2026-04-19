import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:untitled2/core/constants/env.dart';
import 'package:untitled2/domain/model/user_profile.dart';
import 'package:untitled2/domain/model/models.dart';

class ApiService {
  static final List<Cafeteria> _mockCafeterias = [];
  static final List<AsignacionTrabajador> _mockAssignments = [];
  static final Map<String, String> _schoolNames = {};
  static List<String> _schoolIdsCache = const [];

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  static Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${Env.baseUrl}$path').replace(queryParameters: query);
  }

  static Map<String, String> _headers({bool withAuth = true}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withAuth) {
      headers['Authorization'] = 'Bearer ${Env.accessToken}';
    }
    return headers;
  }

  static String _extractMessage(http.Response response) {
    try {
      final body = json.decode(response.body);
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
      if (body is Map && body['error'] != null) {
        return body['error'].toString();
      }
    } catch (_) {}
    return 'Error HTTP ${response.statusCode}';
  }

  static List<Map<String, dynamic>> _normalizeListBody(dynamic body) {
    if (body is List) {
      return body.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    if (body is Map<String, dynamic>) {
      return [body];
    }
    return [];
  }

  static bool _isValidUuid(String value) => _uuidRegex.hasMatch(value);

  static String _generateMockUuid() {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(16).padLeft(32, '0');
    final seed = now.substring(now.length - 32);
    return '${seed.substring(0, 8)}-${seed.substring(8, 12)}-4${seed.substring(13, 16)}-8${seed.substring(17, 20)}-${seed.substring(20, 32)}';
  }

  static void cacheSchoolName(String schoolId, String? schoolName) {
    final id = schoolId.trim();
    final name = schoolName?.trim() ?? '';
    if (id.isEmpty || name.isEmpty) return;
    _schoolNames[id] = name;
  }

  static String? schoolNameOf(String schoolId) {
    final name = _schoolNames[schoolId];
    if (name == null || name.trim().isEmpty) return null;
    return name;
  }

  static Future<List<String>> getSchoolIds() async {
    final response = await http.get(
      _uri('/school-configs/school-ids'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      if (_schoolIdsCache.isNotEmpty) return List<String>.from(_schoolIdsCache);
      throw Exception(_extractMessage(response));
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      if (_schoolIdsCache.isNotEmpty) return List<String>.from(_schoolIdsCache);
      return [];
    }

    final ids = decoded.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    _schoolIdsCache = ids;
    return ids;
  }

  static Future<void> ping() async {
    final response = await http.get(_uri('/health'));
    if (response.statusCode != 200) {
      throw Exception('API no disponible: ${_extractMessage(response)}');
    }
  }

  static Future<String> _resolveLoginAccountId() async {
    if (_isValidUuid(Env.defaultAccountId)) {
      try {
        final byAccountResponse = await http.get(
          _uri('/providers/account/${Env.defaultAccountId}'),
          headers: _headers(),
        );

        if (byAccountResponse.statusCode == 200) {
          return Env.defaultAccountId;
        }
      } catch (_) {}
    }

    try {
      final response = await http.get(_uri('/providers'), headers: _headers());
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final rows = _normalizeListBody(body);
        if (rows.isNotEmpty) {
          final dynamic accountId = rows.first['accountId'] ?? rows.first['id_account'];
          if (accountId != null && _isValidUuid(accountId.toString())) {
            return accountId.toString();
          }
        }
      }
    } catch (_) {}

    return '11111111-1111-4111-8111-111111111111';
  }

  static Future<UserProfile?> login(String email, String password) async {
    final raw = email.trim();
    if (_isValidUuid(raw)) {
      return UserProfile(
        idAccount: raw,
        email: email,
        nombre: raw.substring(0, 8),
        rol: 'DuenoProvider',
      );
    }

    final resolvedAccountId = await _resolveLoginAccountId();
    return UserProfile(
      idAccount: resolvedAccountId,
      email: email,
      nombre: email.split('@').first,
      rol: 'DuenoProvider',
    );
  }

  static Future<List<Proveedor>> getMisProveedores(String idAccount) async {
    if (_isValidUuid(idAccount)) {
      final byAccountResponse = await http.get(
        _uri('/providers/account/$idAccount'),
        headers: _headers(),
      );

      if (byAccountResponse.statusCode == 404) {
        return [];
      }

      if (byAccountResponse.statusCode == 200) {
        final body = json.decode(byAccountResponse.body);
        return _normalizeListBody(body).map(Proveedor.fromJson).toList();
      }

      if (byAccountResponse.statusCode != 400) {
        throw Exception(_extractMessage(byAccountResponse));
      }
    }

    final listResponse = await http.get(_uri('/providers'), headers: _headers());
    if (listResponse.statusCode != 200) {
      throw Exception(_extractMessage(listResponse));
    }

    final body = json.decode(listResponse.body);
    final providers = _normalizeListBody(body).map(Proveedor.fromJson).toList();
    if (_isValidUuid(idAccount)) {
      return providers.where((p) => p.idAccount == idAccount).toList();
    }
    return providers;
  }

  static Future<Proveedor> crearProveedor({
    required String accountId,
    required String nombre,
    required String registro,
    String? email,
    String? telefono,
    String? pais,
    String? ciudad,
    String? direccion,
    String? oficina,
  }) async {
    final payload = {
      'accountId': accountId,
      'name': nombre,
      'companyRegistration': registro,
      'contactEmail': email,
      'contactPhone': telefono,
      'pais': pais,
      'ciudad': ciudad,
      'billingAddress': direccion,
      'oficina': oficina,
    }..removeWhere((key, value) => value == null || value.trim().isEmpty);

    final response = await http.post(
      _uri('/providers'),
      headers: _headers(),
      body: json.encode(payload),
    );

    if (response.statusCode != 201) {
      throw Exception(_extractMessage(response));
    }

    return Proveedor.fromJson(json.decode(response.body));
  }

  static Future<void> actualizarProveedor({
    required String idProveedor,
    required String nombre,
    required String registro,
    String? email,
    String? telefono,
    String? pais,
    String? ciudad,
    String? direccion,
    String? oficina,
  }) async {
    final payload = {
      'name': nombre,
      'companyRegistration': registro,
      'contactEmail': email,
      'contactPhone': telefono,
      'pais': pais,
      'ciudad': ciudad,
      'billingAddress': direccion,
      'oficina': oficina,
    }..removeWhere((key, value) => value == null || value.trim().isEmpty);

    final response = await http.patch(
      _uri('/providers/$idProveedor'),
      headers: _headers(),
      body: json.encode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response));
    }
  }

  static Future<void> eliminarProveedor(String idProveedor) async {
    final response = await http.delete(
      _uri('/providers/$idProveedor'),
      headers: _headers(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_extractMessage(response));
    }
  }

  static Future<List<Trabajador>> getTrabajadoresDeEmpresa(String idProveedor) async {
    final response = await http.get(
      _uri('/workers/provider/$idProveedor'),
      headers: _headers(),
    );

    if (response.statusCode == 404) {
      return [];
    }

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response));
    }

    final body = json.decode(response.body);
    final workers = _normalizeListBody(body).map(Trabajador.fromJson).toList();
    return _attachCafeteriasToWorkers(idProveedor, workers);
  }

  static Future<List<Trabajador>> getEmpleosPorCuenta(String accountId) async {
    final response = await http.get(
      _uri('/workers/account/$accountId'),
      headers: _headers(),
    );

    if (response.statusCode == 404) {
      return [];
    }

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response));
    }

    final body = json.decode(response.body);
    final workers = _normalizeListBody(body).map(Trabajador.fromJson).toList();
    if (workers.isEmpty) return [];

    final byProvider = <String, List<Trabajador>>{};
    for (final worker in workers) {
      byProvider.putIfAbsent(worker.idProveedor, () => []).add(worker);
    }

    final enriched = <Trabajador>[];
    for (final entry in byProvider.entries) {
      final part = await _attachCafeteriasToWorkers(entry.key, entry.value);
      enriched.addAll(part);
    }
    return enriched;
  }

  static Future<List<Cafeteria>> getCafeteriasByProvider(String providerId) async {
    try {
      final response = await http.get(
        _uri('/cafeterias/provider/$providerId'),
        headers: _headers(),
      );

      if (response.statusCode == 404) {
        return [];
      }

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final rows = _normalizeListBody(body);
        for (final row in rows) {
          cacheSchoolName(
            (row['schoolId'] ?? row['id_colegio'] ?? '').toString(),
            (row['schoolName'] ?? row['nombreColegio'])?.toString(),
          );
        }
        return rows.map(Cafeteria.fromJson).toList();
      }

      if (response.statusCode == 400) {
        throw Exception(_extractMessage(response));
      }
    } catch (_) {}

    return _mockCafeterias.where((c) => c.idProveedor == providerId).toList();
  }

  static Future<List<Cafeteria>> getCafeterias() async {
    try {
      final response = await http.get(
        _uri('/cafeterias'),
        headers: _headers(),
      );

      if (response.statusCode == 404) {
        return [];
      }

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final rows = _normalizeListBody(body);
        for (final row in rows) {
          cacheSchoolName(
            (row['schoolId'] ?? row['id_colegio'] ?? '').toString(),
            (row['schoolName'] ?? row['nombreColegio'])?.toString(),
          );
        }
        return rows.map(Cafeteria.fromJson).toList();
      }

      if (response.statusCode == 400) {
        throw Exception(_extractMessage(response));
      }
    } catch (_) {}

    return List<Cafeteria>.from(_mockCafeterias);
  }

  static Future<Cafeteria> crearCafeteria({
    required String schoolId,
    required String name,
    String? providerId,
    String? schoolName,
  }) async {
    cacheSchoolName(schoolId, schoolName);

    final payload = {
      'schoolId': schoolId,
      'name': name,
      if (providerId != null && providerId.trim().isNotEmpty) 'providerId': providerId,
    };

    try {
      final response = await http.post(
        _uri('/cafeterias'),
        headers: _headers(),
        body: json.encode(payload),
      );

      if (response.statusCode == 201) {
        return Cafeteria.fromJson(json.decode(response.body));
      }

      if (response.statusCode == 400 || response.statusCode == 404) {
        throw Exception(_extractMessage(response));
      }
    } catch (_) {}

    final mock = Cafeteria(
      idCafeteria: _generateMockUuid(),
      idColegio: schoolId,
      idProveedor: providerId,
      nombreCafeteria: name,
    );
    _mockCafeterias.add(mock);
    return mock;
  }

  static Future<void> actualizarCafeteria({
    required String idCafeteria,
    required String schoolId,
    required String name,
    String? providerId,
    String? schoolName,
  }) async {
    cacheSchoolName(schoolId, schoolName);

    final payload = {
      'schoolId': schoolId,
      'name': name,
      if (providerId != null && providerId.trim().isNotEmpty) 'providerId': providerId,
    };

    try {
      final response = await http.patch(
        _uri('/cafeterias/$idCafeteria'),
        headers: _headers(),
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        return;
      }

      if (response.statusCode == 400 || response.statusCode == 404) {
        throw Exception(_extractMessage(response));
      }
    } catch (_) {}

    final idx = _mockCafeterias.indexWhere((c) => c.idCafeteria == idCafeteria);
    if (idx != -1) {
      _mockCafeterias[idx] = Cafeteria(
        idCafeteria: idCafeteria,
        idColegio: schoolId,
        idProveedor: providerId,
        nombreCafeteria: name,
      );
    }
  }

  static Future<void> eliminarCafeteria(String idCafeteria) async {
    try {
      final response = await http.delete(
        _uri('/cafeterias/$idCafeteria'),
        headers: _headers(),
      );

      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 404) {
        return;
      }

      throw Exception(_extractMessage(response));
    } catch (_) {
      _mockCafeterias.removeWhere((c) => c.idCafeteria == idCafeteria);
      _mockAssignments.removeWhere((a) => a.cafeteriaId == idCafeteria);
    }
  }

  static Future<List<Map<String, dynamic>>> getAssignmentsByWorkerRaw(String workerId) async {
    final response = await http.get(
      _uri('/workers/assignments/worker/$workerId'),
      headers: _headers(),
    );

    if (response.statusCode == 404) {
      return [];
    }

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return _normalizeListBody(body);
    }

    return _mockAssignments
        .where((a) => a.workerId == workerId)
        .map((a) => {
              'id': a.id,
              'workerId': a.workerId,
              'cafeteriaId': a.cafeteriaId,
              'role': a.role,
              'startDate': a.startDate?.toIso8601String(),
              'endDate': a.endDate?.toIso8601String(),
            })
        .toList();
  }

  static Future<List<AsignacionTrabajador>> getAssignmentsByWorker(String workerId) async {
    final rows = await getAssignmentsByWorkerRaw(workerId);
    return rows.map(AsignacionTrabajador.fromJson).toList();
  }

  static Future<List<AsignacionTrabajador>> getAssignmentsByCafeteria(String cafeteriaId) async {
    try {
      final response = await http.get(
        _uri('/workers/assignments/cafeteria/$cafeteriaId'),
        headers: _headers(),
      );

      if (response.statusCode == 404) {
        return [];
      }

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return _normalizeListBody(body).map(AsignacionTrabajador.fromJson).toList();
      }

      if (response.statusCode == 400) {
        throw Exception(_extractMessage(response));
      }
    } catch (_) {}

    return _mockAssignments.where((a) => a.cafeteriaId == cafeteriaId).toList();
  }

  static Future<AsignacionTrabajador> asignarTrabajadorACafeteria({
    required String workerId,
    required String cafeteriaId,
    required String role,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final payload = {
      'workerId': workerId,
      'cafeteriaId': cafeteriaId,
      'role': role,
      'startDate':
          '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'endDate': endDate != null
          ? '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}'
          : null,
    };

    try {
      final response = await http.post(
        _uri('/workers/assignments'),
        headers: _headers(),
        body: json.encode(payload),
      );

      if (response.statusCode == 201) {
        return AsignacionTrabajador.fromJson(json.decode(response.body));
      }

      if (response.statusCode == 400 || response.statusCode == 404) {
        throw Exception(_extractMessage(response));
      }
    } catch (_) {}

    final mock = AsignacionTrabajador(
      id: _generateMockUuid(),
      workerId: workerId,
      cafeteriaId: cafeteriaId,
      role: role,
      startDate: startDate,
      endDate: endDate,
    );
    _mockAssignments.add(mock);
    return mock;
  }

  static Future<void> eliminarAsignacion(String assignmentId) async {
    try {
      final response = await http.delete(
        _uri('/workers/assignments/$assignmentId'),
        headers: _headers(),
      );

      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 404) {
        return;
      }

      throw Exception(_extractMessage(response));
    } catch (_) {
      _mockAssignments.removeWhere((a) => a.id == assignmentId);
    }
  }

  static Future<List<Trabajador>> _attachCafeteriasToWorkers(
    String providerId,
    List<Trabajador> workers,
  ) async {
    if (workers.isEmpty) return workers;

    final cafeterias = await getCafeteriasByProvider(providerId);
    if (cafeterias.isEmpty) return workers;

    final cafeteriasById = {
      for (final cafeteria in cafeterias) cafeteria.idCafeteria: cafeteria,
    };

    final assignmentResults = await Future.wait(
      workers.map((w) async {
        final assignments = await getAssignmentsByWorkerRaw(w.idTrabajador);
        return MapEntry(w.idTrabajador, assignments);
      }),
    );

    final assignmentsByWorker = {
      for (final row in assignmentResults) row.key: row.value,
    };

    return workers.map((worker) {
      final assignments = assignmentsByWorker[worker.idTrabajador] ?? const [];
      final cafeteriaIds = assignments
          .map((a) => (a['cafeteriaId'] ?? a['id_cafeteria'])?.toString())
          .whereType<String>()
          .toSet();

      final assigned = cafeteriaIds
          .map((id) => cafeteriasById[id])
          .whereType<Cafeteria>()
          .toList();

      return Trabajador(
        idTrabajador: worker.idTrabajador,
        idAccount: worker.idAccount,
        idProveedor: worker.idProveedor,
        estadoEmpleo: worker.estadoEmpleo,
        cargoTrabajador: worker.cargoTrabajador,
        tipoContratoTrabajador: worker.tipoContratoTrabajador,
        fechaContratacion: worker.fechaContratacion,
        salarioTrabajador: worker.salarioTrabajador,
        creadoEn: worker.creadoEn,
        nombreProveedor: worker.nombreProveedor,
        cafeterias: assigned,
      );
    }).toList();
  }

  static Future<void> crearTrabajador({
    required String accountId,
    required String providerId,
    required String cargo,
    String? tipoContrato,
    DateTime? fechaContratacion,
    double? salario,
  }) async {
    final payload = {
      'accountId': accountId,
      'providerId': providerId,
      'position': cargo,
      if (tipoContrato != null && tipoContrato.trim().isNotEmpty) 'contractType': tipoContrato,
      if (fechaContratacion != null)
        'hireDate':
            '${fechaContratacion.year.toString().padLeft(4, '0')}-${fechaContratacion.month.toString().padLeft(2, '0')}-${fechaContratacion.day.toString().padLeft(2, '0')}',
      if (salario != null) 'salary': salario.toStringAsFixed(2),
    };

    final response = await http.post(
      _uri('/workers'),
      headers: _headers(),
      body: json.encode(payload),
    );

    if (response.statusCode != 201) {
      throw Exception(_extractMessage(response));
    }
  }

  static Future<bool> updateTrabajador(Trabajador trabajador) async {
    final salario = trabajador.salarioTrabajador;
    final response = await http.patch(
      _uri('/workers/${trabajador.idTrabajador}'),
      headers: _headers(),
      body: json.encode({
        'employmentStatus': trabajador.estadoEmpleo.name,
        'position': trabajador.cargoTrabajador,
        'contractType': trabajador.tipoContratoTrabajador,
        if (trabajador.fechaContratacion != null)
          'hireDate':
              '${trabajador.fechaContratacion!.year.toString().padLeft(4, '0')}-${trabajador.fechaContratacion!.month.toString().padLeft(2, '0')}-${trabajador.fechaContratacion!.day.toString().padLeft(2, '0')}',
        if (salario != null) 'salary': salario.toStringAsFixed(2),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }

    throw Exception(_extractMessage(response));
  }

  static Future<void> eliminarTrabajador(String idTrabajador) async {
    final response = await http.delete(
      _uri('/workers/$idTrabajador'),
      headers: _headers(),
    );

    if (response.statusCode != 200 && response.statusCode != 204 && response.statusCode != 404) {
      throw Exception(_extractMessage(response));
    }
  }
}
