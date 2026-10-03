# Pádel Comunidad - Agent Instructions

## Objetivo

Desarrollar y mantener una aplicación web PWA para la gestión de reservas de una pista de pádel de una comunidad de propietarios.

La aplicación debe funcionar como:

- Web responsive
- Aplicación instalable en Android
- Aplicación instalable en iPhone/iPad
- Aplicación instalable en escritorio

No se publicará en App Store ni Google Play.

Debe funcionar mediante un enlace HTTPS.

---

# Stack Obligatorio

## Frontend

- Nuxt 4
- Vue 3
- TypeScript estricto
- Composition API
- Tailwind CSS
- Nuxt UI

## Backend

- Supabase

## Base de Datos

- PostgreSQL

## Autenticación

- Supabase Auth

## Calidad

- ESLint
- Vitest
- Zod

## Despliegue

- GitHub
- Vercel

## PWA

- @vite-pwa/nuxt

No introducir frameworks alternativos salvo petición explícita.

---

# Filosofía

La solución debe ser:

- Gratuita
- Simple
- Segura
- Escalable
- Fácil de mantener
- Mobile First

Siempre priorizar simplicidad frente a complejidad.

---

# Reglas de Reserva

Existe una única pista de pádel.

Aplicar obligatoriamente:

1. Máximo 120 minutos por vivienda al día.
2. Solo reservar dentro de las próximas 24 horas.
3. No permitir reservas en el pasado.
4. Duración mínima 30 minutos.
5. Intervalos de 30 minutos.
6. Duración máxima por reserva 120 minutos.
7. No permitir solapamientos.
8. El límite diario se aplica a toda la vivienda.
9. Usuarios revocados no pueden reservar.
10. Mantener histórico de reservas.

Todas las restricciones críticas deben ser verificadas en PostgreSQL.

Nunca depender únicamente del frontend.

---

# Usuarios

Campos mínimos:

- Nombre
- Usuario
- Password
- Email
- Bloque
- Piso
- Puerta

Estados posibles:

- approved
- revoked

Por defecto:

approved

Un administrador puede:

- Revocar
- Reactivar
- Corregir vivienda

No permitir cambios de rol desde cliente.

---

# Seguridad

Obligatorio:

- Row Level Security
- Validaciones servidor
- Validaciones PostgreSQL
- Políticas RLS
- Protección XSS
- Protección SQL Injection
- Protección contra manipulación de fechas
- Protección contra reservas simultáneas

Nunca confiar en:

- Datos enviados por el navegador
- Roles recibidos desde cliente
- user_id enviados desde cliente

Obtener siempre el usuario desde auth.uid().

---

# Arquitectura

Usar la siguiente estructura:

src/

app/
components/
pages/
layouts/
middleware/
composables/
types/
utils/

server/
api/
utils/

supabase/
migrations/

tests/

public/

---

# Diseño

Tema:

- Verde oscuro
- Verde claro
- Blanco

Mobile first.

Requisitos:

- WCAG
- Labels accesibles
- Navegación teclado
- Foco visible
- Contraste adecuado

---

# Base de Datos

Tablas mínimas:

profiles

reservations

court_blocks

app_settings

audit_log

Crear:

- PK
- FK
- Índices
- Constraints
- Triggers
- Migraciones versionadas

---

# PWA

Obligatorio:

- Manifest
- Service Worker
- Offline page
- Iconos 192
- Iconos 512
- Maskable icon
- Standalone mode

Configurar Add To Home Screen.

Para iOS mostrar instrucciones manuales.

Nunca afirmar que iOS permite instalar automáticamente una web app.

---

# Código

## TypeScript

strict: true

Evitar:

- any
- ts-ignore
- código muerto
- duplicación

## Vue

Usar:

- script setup
- composables
- componentes reutilizables

Mantener componentes pequeños.

---

# Calidad

Antes de dar una tarea por finalizada ejecutar:

npm run lint

npm run typecheck

npm run test

npm run build

Corregir errores encontrados.

Nunca afirmar que algo funciona si no se ha validado.

---

# Git

Commits pequeños y descriptivos.

Formato:

feat:

fix:

refactor:

test:

docs:

---

# Documentación

Actualizar README siempre que:

- Se añada funcionalidad
- Cambien variables de entorno
- Se modifique el despliegue
- Se modifiquen migraciones

Todos los comandos deben poder copiarse y pegarse directamente.

---

# Prioridades

1. Seguridad
2. Correctitud de negocio
3. Experiencia móvil
4. Rendimiento
5. Mantenimiento
6. Funcionalidades adicionales

Ante varias opciones elegir la más simple que cumpla los requisitos.