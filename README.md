# 🚛 LogiFlow — Container & Fleet Management App

Aplicación móvil para registrar y administrar flujos de contenedores en operaciones logísticas. Desarrollada con **Flutter** y **Supabase** como backend.

> Estado del proyecto: 🚧 En desarrollo — Demo en construcción

---

## 📋 Descripción

LogiFlow permite a equipos de operaciones logísticas gestionar en tiempo real el movimiento de contenedores, la asignación de camiones y conductores, y la generación de facturas, todo desde una app móvil.

---

## ✨ Funcionalidades principales

- **Registro de activos** — camiones, conductores y contenedores
- **Gestión de viajes** — asignación de camión + conductor + contenedor por ruta
- **Trazabilidad** — historial de movimientos y estado de cada contenedor
- **Facturación** — generación y exportación de facturas en PDF
- **Dashboard en tiempo real** — KPIs y alertas vía Supabase Realtime
- **Fotos y documentos** — carga de imágenes de placas, licencias y firmas
- **Roles de acceso** — admin, operador y chofer con permisos diferenciados
- **Modo offline** — visualización sin conexión con sincronización al reconectar

---

## 🛠️ Stack tecnológico

| Capa | Tecnología |
|---|---|
| Mobile | Flutter 3.x (Android/iOS) |
| Backend / DB | Supabase (PostgreSQL) |
| Auth | Supabase Auth + Row Level Security |
| Storage | Supabase Storage |
| Realtime | Supabase Realtime |
| Hosting / VPS | Hostinger VPS (Nginx + SSL) |

---

## 🗄️ Modelo de datos

profiles      — usuarios del sistema con rol asignado
trucks        — registro de camiones (placa, marca, estado)
drivers       — conductores con licencia y datos de contacto
containers    — contenedores (número BL, tipo, ubicación actual)
trips         — viajes que relacionan camión + conductor + contenedor
invoices      — facturas asociadas a cada viaje

---

## 🚀 Cómo empezar

### Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.0
- Cuenta en [Supabase](https://supabase.com) (plan gratuito funciona)
- Android Studio o VS Code con extensión Flutter

### Instalación

```bash
# 1. Clonar el repositorio
git clone https://github.com/GP-Shacht/logistic_App.git
cd logiflow

# 2. Instalar dependencias
flutter pub get

# 3. Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales de Supabase
```

### Configuración de Supabase

1. Crear un proyecto nuevo en [supabase.com](https://supabase.com)
2. Ejecutar los scripts SQL en `supabase/migrations/` en orden
3. Copiar `Project URL` y `anon key` al archivo `.env`
4. Activar Row Level Security en todas las tablas

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu_anon_key_aqui
```

### Ejecutar en desarrollo

```bash
flutter run
```

---

## 📁 Estructura del proyecto

```
lib/
├── core/
│   ├── config/          # Inicialización de Supabase, temas
│   └── router/          # Rutas de navegación
├── features/
│   ├── auth/            # Login, registro, gestión de sesión
│   ├── trucks/          # CRUD de camiones
│   ├── drivers/         # CRUD de conductores
│   ├── containers/      # CRUD de contenedores
│   ├── trips/           # Gestión de viajes y movimientos
│   ├── invoices/        # Facturación
│   └── dashboard/       # KPIs y métricas en tiempo real
└── shared/
    ├── widgets/         # Componentes reutilizables
    └── utils/           # Helpers y constantes

supabase/
└── migrations/          # Scripts SQL ordenados por fecha
```

---

## 👥 Roles de usuario

| Rol | Permisos |
|---|---|
| `admin` | Acceso total, gestión de usuarios |
| `operador` | Crear y editar viajes, activos y facturas |
| `chofer` | Ver sus propios viajes asignados (solo lectura) |

---

## 🗺️ Roadmap

- [x] Diseño de base de datos y modelo de datos
- [x] Configuración de Supabase (Auth, RLS, Storage)
- [x] Módulo Auth y manejo de roles
- [x] CRUD camiones, conductores y contenedores
- [x] Registro y seguimiento de viajes
- [x] Dashboard con métricas en tiempo real
- [x] Navegación bottom bar con botón central (Dashboard)
- [x] Navegación a pantallas de detalle y edición (drivers, trips)
- [ ] Facturación con exportación PDF
- [ ] Modo offline con sincronización
- [ ] Build APK demo

---

## 📄 Licencia

MIT — ver [LICENSE](LICENSE) para más detalles.

---

> Desarrollado con Flutter 🐦 + Supabase ⚡
