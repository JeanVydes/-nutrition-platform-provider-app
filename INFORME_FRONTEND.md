# Pay School Snacks Providers App

| Campo | Valor |
|---|---|
| **Nombre** | Pay School Snacks Providers App |
| **Descripción** | Aplicación móvil para la gestión de proveedores, cafeterías y vinculación de trabajadores. |
| **Versión** | 1.0.0 |
| **Entorno** | Android / iOS (Flutter) |
| **Bounded Context** | Interfaz de Usuario y Orquestación de API para Proveedores |
| **Integrantes** | Jean Vides, Luis Rincon, Santiago Criollo |
| **Repositorio** | (Repositorio interno) |

---

## 1. Propósito y Alcance

La plataforma **Pay School Snacks** es un ecosistema amplio. Esta aplicación, **Pay School Snacks Providers App**, abarca únicamente una pequeña parte de ese ecosistema: somos la interfaz oficial para la gestión de los proveedores. Sirve como el punto de acceso exclusivo para que usuarios (proveedores y trabajadores) interactúen con el sistema de gestión. Permite la administración de empresas proveedoras, la creación de cafeterías dentro de colegios y la vinculación de trabajadores.

**Casos de uso principales:**
- **Proveedores:** Registrar su empresa, crear cafeterías, y vincular trabajadores a dichas cafeterías.
- **Trabajadores:** Ver las empresas a las que están vinculados y aceptar invitaciones o registrarse bajo un proveedor mediante validación de identidad.

---

## 2. Stack Tecnológico (Frontend)

| Componente | Tecnología | Justificación Técnica |
|---|---|---|
| Framework UI | Flutter (Material 3) | Permite compilar nativamente para iOS y Android desde un solo código base, utilizando los nuevos lineamientos de Material Design 3 para una apariencia moderna. |
| Lenguaje | Dart | Fuertemente tipado, compilación AOT (Ahead Of Time) para rendimiento nativo y JIT (Just In Time) para un desarrollo rápido (Hot Reload). |
| Estado Global | Provider | Gestión de dependencias y estado ligero y eficiente para mantener sincronizada la sesión de usuario (`AuthProvider`). |
| Cliente HTTP | `http` (Paquete nativo) | Interfaz sencilla para realizar peticiones REST al `provider-service` y al servicio de seguridad. |
| Autenticación | JWT (JSON Web Tokens) | Los tokens son provistos por el microservicio de seguridad y almacenados en memoria para firmar cada petición saliente. |
| Navegación | Navigator 2.0 (Básica) | Gestión limpia de rutas para el flujo de autenticación, pestañas principales (BottomNavigationBar) y vistas detalladas. |
| Theming | Material 3 (Personalizado) | Esquema de colores vibrantes (`AppTheme`), tarjetas elevadas, text-fields delineados y uso intensivo de bordes redondeados. |

---

## 3. Seguridad y Sesión

La aplicación no maneja contraseñas directamente. Su flujo de seguridad es el siguiente:

1. **Solicitud de PIN:** El usuario ingresa su correo o celular. Se hace un POST al servicio de seguridad.
2. **Validación de PIN:** El usuario ingresa el PIN OTP (One Time Password). El servicio retorna un JWT.
3. **Persistencia en Sesión:** El token se almacena en memoria (`ApiService._accessToken`).
4. **Obtención de Perfil:** Inmediatamente después del login, la app consulta `GET /me` en el servicio de seguridad para mapear el ID de usuario (`idAccount`), roles y nombres. Todo esto se guarda en `AuthProvider`.
5. **Interceptores:** Si cualquier petición al backend retorna un **401 Unauthorized** (token expirado), un callback en `ApiService` notifica a `AuthProvider` para cerrar la sesión y redirigir a la pantalla de login automáticamente.

> **Nota de Desarrollo:** Existe un flujo de Bypass (`loginWithDevToken`) que permite inyectar un JWT directamente para saltarse el flujo OTP en entornos de prueba locales.

---

## 4. Arquitectura y Estructura del Proyecto

La arquitectura sigue un modelo en capas simplificado adaptado para Flutter:

```
lib/
├── main.dart                             ← Entry point, inicialización y ruteo inicial (AuthGate).
├── domain/
│   └── model/
│       ├── models.dart                   ← Entidades de negocio (Proveedor, Cafeteria, Trabajador, Asignacion).
│       └── user_profile.dart             ← Perfil del usuario obtenido del servicio de seguridad.
├── data/
│   └── remote/
│       └── datasource/
│           └── api_service.dart          ← Único punto de contacto con el Backend. Convierte JSON a Modelos.
├── presentation/                         ← Capa de Interfaz de Usuario (UI).
│   ├── auth/
│   │   ├── login_screen.dart             ← Flujo de OTP.
│   │   └── providers/auth_provider.dart  ← Estado global de autenticación.
│   ├── home/
│   │   └── home_screen.dart              ← Contenedor principal con BottomNavigationBar.
│   ├── empresa/
│   │   ├── mis_empresas_screen.dart      ← Lista de empresas del usuario logueado.
│   │   ├── crear_empresa_screen.dart     ← Formulario de registro/edición de proveedor.
│   │   └── empresa_detalle_screen.dart   ← Vista detallada (datos, cafeterías y trabajadores).
│   ├── trabajador/
│   │   ├── empresas_como_trabajador...   ← Lista de empleos vigentes del usuario.
│   │   ├── agregar_trabajador_screen...  ← Formulario para vincular un trabajador.
│   │   └── editar_trabajador_screen.dart ← Gestión de estado de empleo y salario.
│   ├── cafeteria/
│   │   ├── cafeterias_screen.dart        ← Listado general de cafeterías.
│   │   ├── crear_cafeteria_screen.dart   ← Formulario de creación de sede.
│   │   └── asignar_trabajador_cafete...  ← Asignación de rol y fechas en una cafetería.
│   └── theme/                            ← Definición de colores, tipografías y estilos base.
└── core/
    └── env/
        └── env.dart                      ← Variables de entorno (URLs de los microservicios).
```

### 4.1 Flujo de Datos

1. **UI:** El usuario interactúa con un Widget (ej: Botón "Guardar Empresa").
2. **Action:** El Widget llama a un método estático en `ApiService` pasando los parámetros.
3. **API Service:** `ApiService` serializa los datos a JSON, adjunta el Header `Authorization: Bearer <token>`, y envía la petición vía `http`.
4. **Parseo:** Si la respuesta es 2xx, `ApiService` decodifica el JSON y utiliza los constructores `factory model.fromJson` para instanciar las entidades.
5. **Update UI:** El Widget recibe la entidad o simplemente recarga su lista actualizando su estado (`setState()`), redibujando la pantalla.

---

## 5. Decisiones de Diseño UI/UX

*   **Renderizado Dinámico de Pestañas:** El contenedor `HomeScreen` gestiona las pestañas (`Mis Empresas`, `Mis Empleos`, etc.). Para garantizar que la información esté **siempre actualizada** al cambiar de pestaña, las pantallas se re-renderizan dinámicamente (`_tabs[_currentIndex]`) en lugar de usar un `IndexedStack` persistente. Esto asegura que la función `initState` dispare peticiones HTTP frescas en cada visita.
*   **Gestión de Formularios:** Se utilizan `TextEditingController` para enlazar datos existentes en formularios de edición. Todos los campos envían su estado validado al backend. Los valores nulos o vacíos son removidos en el `ApiService` antes de enviarlos (omitiéndolos del JSON).
*   **Identidad Visual:** 
    *   **Color Primario:** Azul Indigo (`#4F46E5`), utilizado para acentos principales, FABs (Floating Action Buttons) e íconos.
    *   **Color de Superficie:** Blanco puro y fondos sutiles (`#F8FAFC`) para dar sensación de pulcritud.
    *   **Estado Empleo:** Chips visuales de colores (Verde = Activo, Naranja = Suspendido, Rojo = Retirado).
*   **Feedback al Usuario:** Todos los procesos asíncronos muestran un `CircularProgressIndicator`. Los errores devueltos por el backend se extraen (`_extractMessage`) y se presentan mediante `SnackBar` de error (fondo rojo).

---

## 6. Sincronización con el Backend

El frontend refleja estrictamente el contrato establecido por el `provider-service`:

1.  **Cascada:** Dado que el backend implementa `ON DELETE CASCADE`, la app de Flutter permite al usuario eliminar una empresa con confianza, actualizando la lista de inmediato sin enfrentar bloqueos de restricciones de clave foránea.
2.  **Ubicaciones:** Los campos `pais`, `ciudad`, `direccion_facturacion` y `oficina` se mapean fielmente desde los formularios hasta la API, completando la estructura de datos del proveedor.
3.  **Identidad Consolidada:** Se resolvieron discrepancias de ID. El frontend extrae el `idAccount` verídico desde la respuesta del servicio de seguridad (`/me`) y lo utiliza para todas las operaciones (ej. `getMisProveedores(idAccount)` y `getEmpleosPorCuenta(idAccount)`).


