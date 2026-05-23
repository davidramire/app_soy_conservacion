# Nombre del proyecto

BioVisor


## Descripción general

Este proyecto consiste en una aplicación que permite ver los registros de especies de fauna y flora con el fin de contribuir al analisis cíentifico de la biodiversidad del territorio.


## Tecnologías Utilizadas

# Frontend 

- Flutter - Framework para desarrollo multiplataforma
- Dart - Lenguaje de programación
- Provider - Gestión de estado
- Flutter Map - Mapas interactivos
- HTTP - Cliente HTTP para requests
- Flutter Secure Storage - Almacenamiento seguro de  datos
- Shared Preferences - Preferencias locales
- Google Fonts - Fuentes personalizadas
- Lucide Icons - Iconografía
- Intl - Internacionalización y localización
- Flutter Dotenv - Gestión de variables de entorno

# Backend (API)

- Node.js - Runtime de JavaScript
- Express.js - Framework web
- Prisma - ORM (Object-Relational Mapping)
- PostgreSQL/MySQL - Base de datos
- JWT (jsonwebtoken) - Autenticación
- bcryptjs - Hash de contraseñas
- CORS - Control de acceso cross-origin


## Instrucciones de instalación

### Requisitos Previos
- Node.js (v18 o superior)
- Flutter SDK
- Dart SDK
- pnpm (o npm)
- PostgreSQL o MySQL
- Git

### Configuración del Proyecto

#### 1. Clonar el repositorio
```bash
git clone <url-del-repositorio>
cd soy_conservacion
```

#### 2. Configurar el Backend

Navega a la carpeta del backend:
```bash
cd backend
```

**Instalar dependencias:**
```bash
pnpm install
```

**Configurar variables de entorno:**
Crea un archivo `.env` en la carpeta `backend` con las siguientes variables:
```
DATABASE_URL="postgresql://usuario:contraseña@localhost:5432/soy_conservacion"
JWT_SECRET="tu_clave_secreta_aqui"
PORT=3000
NODE_ENV=development
```

**Ejecutar migraciones de base de datos:**
```bash
pnpm prisma:migrate
```

**Iniciar el servidor backend (modo desarrollo):**
```bash
pnpm dev
```

O en modo producción:
```bash
pnpm start
```

El servidor estará disponible en `http://localhost:3000`

#### 3. Configurar el Frontend

Desde la raíz del proyecto:
```bash
# Instalar dependencias de Flutter
flutter pub get
```

**Configurar variables de entorno:**
Crea un archivo `.env.local` en la raíz del proyecto:
```
API_BASE_URL=http://localhost:3000
```

**Ejecutar la aplicación:**

Para Android:
```bash
flutter run -d android
```

Para iOS:
```bash
flutter run -d ios
```

Para Web:
```bash
flutter run -d chrome
```

Para Windows:
```bash
flutter run -d windows
```

## Pasos para Ejecutar el Proyecto

1. Asegúrate de que la base de datos está corriendo
2. Inicia el backend desde la carpeta `/backend` con `pnpm dev`
3. En otra terminal, desde la raíz, inicia el frontend con `flutter run -d <plataforma>`
4. La aplicación se conectará automáticamente a la API del backend

### Comandos Útiles

**Backend:**
- `pnpm dev` - Modo desarrollo con hot-reload
- `pnpm start` - Modo producción
- `pnpm prisma:studio` - Abrir Prisma Studio (UI para la BD)
- `pnpm prisma:migrate` - Ejecutar migraciones pendientes

**Frontend:**
- `flutter pub get` - Instalar/actualizar dependencias
- `flutter clean` - Limpiar archivos de build
- `flutter pub upgrade` - Actualizar dependencias


## Integrantes del equipo

- Diego Alejandro Lesmes
- Juan Pablo Rodríguez 
- Frank Esteban Berrío
- David Esteban Ramírez