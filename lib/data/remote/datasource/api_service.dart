import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:untitled2/core/constants/env.dart';
import 'package:untitled2/domain/model/user_profile.dart';
import 'package:untitled2/domain/model/models.dart';

class ApiService {
  static final Map<String, String> _schoolNames = {};
  static String? _accessToken;

  /// Set by AuthProvider to handle 401 responses globally.
  static VoidCallback? on401;

  /// Call after every authenticated request. If 401, clears token and fires callback.
  static void _checkAuth(http.Response response) {
    if (response.statusCode == 401) {
      clearAccessToken();
      on401?.call();
    }
  }

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  static Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${Env.baseUrl}$path').replace(queryParameters: query);
  }

  static Uri _securityUri(String path) {
    return Uri.parse('${Env.securityBaseUrl}$path');
  }

  static Map<String, String> _headers({bool withAuth = true, bool hasBody = true}) {
    final headers = <String, String>{};
    if (hasBody) {
      headers['Content-Type'] = 'application/json';
    }
    if (withAuth && _accessToken != null && _accessToken!.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  static void setAccessToken(String token) {
    final t = token.trim();
    if (t.toLowerCase().startsWith('bearer ')) {
      _accessToken = t.substring(7).trim();
    } else {
      _accessToken = t;
    }
  }

  static void clearAccessToken() {
    _accessToken = null;
  }

  static String _extractMessage(http.Response response) {
    _checkAuth(response);
    try {
      final body = json.decode(response.body);
      if (body is Map && body['mensaje'] != null) {
        return body['mensaje'].toString();
      }
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

  static Future<List<Map<String, dynamic>>> getSchoolConfigs() async {
    final response = await http.get(
      _uri('/school-configs'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response));
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      return [];
    }

    final configs = decoded.map((e) => e as Map<String, dynamic>).toList();
    for (final c in configs) {
      cacheSchoolName(c['id']?.toString() ?? '', c['schoolName']?.toString());
    }
    return configs;
  }

  static Future<void> ping() async {
    final response = await http.get(_uri('/health'));
    if (response.statusCode != 200) {
      throw Exception('API no disponible: ${_extractMessage(response)}');
    }
  }

  static Future<void> requestSecurityPin(String identifier) async {
    final response = await http.post(
      _securityUri('/login/request-pin'),
      headers: _headers(withAuth: false),
      body: json.encode({'identificadorAcceso': identifier}),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response));
    }
  }

  static Future<String> loginWithSecurityPin({
    required String identifier,
    required String pin,
  }) async {
    final response = await http.post(
      _securityUri('/login'),
      headers: _headers(withAuth: false),
      body: json.encode({
        'identificadorAcceso': identifier,
        'pinAcceso': pin,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response));
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final datos = body['datos'] as Map<String, dynamic>? ?? {};
    final token = datos['tokenApp']?.toString() ?? '';
    if (token.isEmpty) {
      throw Exception('Token JWT no recibido desde seguridad');
    }

    setAccessToken(token);
    return token;
  }

  static Future<UserProfile> getSecurityMe() async {
    final response = await http.get(
      _securityUri('/me'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response));
    }

    debugPrint('[ApiService] /me raw response: ${response.body}');
    final body = json.decode(response.body) as Map<String, dynamic>;
    return UserProfile.fromSecurityMe(body);
  }

  static Future<Map<String, dynamic>> getSecurityUserById(String id) async {
    final response = await http.get(
      _securityUri('/users/$id'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response));
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final datos = body['datos'] as Map<String, dynamic>? ?? {};
    return datos;
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
    // Guard: accountId is required by the backend Zod schema
    if (accountId.trim().isEmpty) {
      throw Exception('No se puede crear el proveedor: accountId está vacío. Verifica tu sesión.');
    }

    final optionalFields = <String, String?>{
      'contactEmail': email,
      'contactPhone': telefono,
      'pais': pais,
      'ciudad': ciudad,
      'billingAddress': direccion,
      'oficina': oficina,
    }..removeWhere((_, value) => value == null || value.trim().isEmpty);

    final payload = <String, dynamic>{
      'accountId': accountId,
      'name': nombre,
      'companyRegistration': registro,
      ...optionalFields,
    };

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
      headers: _headers(hasBody: false),
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

        throw Exception('Cafeterias not found for provider: $providerId');
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

        throw Exception('Cafeterias not found');
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

    throw Exception('Failed to create Cafeteria');
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

    throw Exception('Failed to update Cafeteria');
  }

  static Future<void> eliminarCafeteria(String idCafeteria) async {
    try {
      final response = await http.delete(
        _uri('/cafeterias/$idCafeteria'),
        headers: _headers(hasBody: false),
      );

      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 404) {
        return;
      }

      throw Exception(_extractMessage(response));
    } catch (_) {
          throw Exception('Failed to delete Cafeteria');
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

    throw Exception('Assignments not found for worker: $workerId');
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

      throw Exception(_extractMessage(response));
    } catch (e) {
      if (e is Exception && !e.toString().contains('Assignments not found')) {
        rethrow;
      }
    }

    throw Exception('Assignments not found for cafeteria: $cafeteriaId');
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
      if (endDate != null)
        'endDate':
            '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
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

      throw Exception(_extractMessage(response));
    } catch (e) {
      if (e is Exception && !e.toString().contains('Failed to assign worker')) {
        rethrow;
      }
    }

    throw Exception('Failed to assign worker to cafeteria');
  }

  static Future<void> eliminarAsignacion(String assignmentId) async {
    try {
      final response = await http.delete(
        _uri('/workers/assignments/$assignmentId'),
        headers: _headers(hasBody: false),
      );

      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 404) {
        return;
      }

      throw Exception(_extractMessage(response));
    } catch (_) {
          throw Exception('Failed to delete assignment');
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
    // Guard: both accountId and providerId are required by the backend
    if (accountId.trim().isEmpty) {
      throw Exception('No se puede crear el trabajador: accountId está vacío. Verifica tu sesión.');
    }
    if (providerId.trim().isEmpty) {
      throw Exception('No se puede crear el trabajador: providerId está vacío.');
    }

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
      headers: _headers(hasBody: false),
    );

    if (response.statusCode != 200 && response.statusCode != 204 && response.statusCode != 404) {
      throw Exception(_extractMessage(response));
    }
  }
}
