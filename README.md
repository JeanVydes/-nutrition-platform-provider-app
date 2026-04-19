# Nutrition Platform Provider App

Aplicación Flutter para gestión de:

- proveedores (empresas),
- cafeterías por colegio,
- trabajadores,
- asignaciones trabajador ↔ cafetería.

Está integrada con `provider-service` usando token mock (`offline-token`) y soporta sesión mock para desarrollo local.

## Stack

- Flutter / Dart
- `provider` para estado de sesión
- `http` para integración backend
- Arquitectura por capas en `lib/` (`core`, `data`, `domain`, `presentation`)

## Estructura principal

- `lib/main.dart`: tema global y rutas
- `lib/core/constants/env.dart`: configuración de entorno (base URL, token, account por defecto)
- `lib/data/remote/datasource/api_service.dart`: cliente API y mapeo de contratos
- `lib/domain/model/`: modelos de dominio
- `lib/presentation/`: pantallas y flujos UI

## Variables de entorno

El proyecto usa `String.fromEnvironment` (no `.env` runtime). Puedes sobreescribir en ejecución:

- `BASE_URL` (default: `http://localhost:8080`)
- `ACCESS_TOKEN` (default: `offline-token`)
- `DEFAULT_ACCOUNT_ID` (uuid mock)

Ejemplo:

`flutter run -d linux --dart-define=BASE_URL=http://localhost:8080 --dart-define=ACCESS_TOKEN=offline-token`

## Backend esperado (provider-service)

Endpoints clave usados por la app:

- Health: `GET /health`
- Providers: `POST/GET /providers`, `GET /providers/account/{accountId}`, `PATCH/DELETE /providers/{id}`
- Cafeterias: `POST/GET /cafeterias`, `GET /cafeterias/{id}`, `GET /cafeterias/provider/{providerId}`, `PATCH/DELETE /cafeterias/{id}`
- Workers: `POST/GET /workers`, `GET /workers/{id}`, `GET /workers/provider/{providerId}`, `GET /workers/account/{accountId}`, `PATCH/DELETE /workers/{id}`
- Assignments: `POST /workers/assignments`, `GET /workers/assignments`, `GET /workers/assignments/worker/{workerId}`, `GET /workers/assignments/cafeteria/{cafeteriaId}`, `DELETE /workers/assignments/{id}`
- School IDs (multi-tenant): `GET /school-configs/school-ids`

## Notas funcionales importantes

- `schoolId` en cafeterías se selecciona desde `GET /school-configs/school-ids`.
- El backend actual exige `providerId` al crear cafetería (según contrato y validación real).
- El flujo de agregar trabajador usa mock de seguridad con usuario logeado por defecto.

## Ejecutar en local

1. Instalar dependencias:

`flutter pub get`

2. Ejecutar app:

`flutter run -d linux`

3. Análisis estático:

`flutter analyze`

## Flujo de navegación

- Login
- Home con tabs:
	- Mis empresas
	- Soy trabajador
	- Cafeterías
	- Perfil

## Estado del repositorio

El proyecto está preparado para versionado Git con `.gitignore` para Flutter/Android/iOS/macOS/Linux/Windows y archivos locales sensibles (`android/local.properties`, `android/key.properties`).
