# EduCampus

Aplicacion Flutter para la gestion academica de EduCampus - COLMAS. El proyecto
incluye interfaces para administradores, docentes y acudientes, conectadas a un
backend HTTP.

## Requisitos

- Flutter y Dart compatibles con la restriccion del proyecto (`sdk: ^3.13.2` en
  `pubspec.yaml`).
- Android Studio/Android SDK para ejecutar o compilar Android.
- Google Chrome para ejecutar o compilar Web.
- Un backend accesible desde el dispositivo o navegador.

## Preparar el proyecto

```bash
flutter pub get
```

## Configurar el backend

La URL del backend se configura mediante `API_BASE_URL`. Si no se especifica, la
app usa `http://127.0.0.1:8000`.

Ejemplo para desarrollo:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

En un telefono Android, `127.0.0.1` apunta al propio telefono, no al computador
que ejecuta el backend. Para probar en un dispositivo fisico, usa la IP local
del computador o una URL HTTPS accesible desde el telefono:

```bash
flutter run -d <id-del-dispositivo> \
  --dart-define=API_BASE_URL=http://<ip-del-computador>:8000
```

## Ejecutar y compilar

```bash
# Ejecutar en un dispositivo conectado
flutter devices
flutter run -d <id-del-dispositivo> \
  --dart-define=API_BASE_URL=<url-del-backend>

# Ejecutar en Chrome
flutter run -d chrome \
  --dart-define=API_BASE_URL=<url-del-backend>

# Generar APK de depuracion
flutter build apk --debug \
  --dart-define=API_BASE_URL=<url-del-backend>

# Generar compilacion Web
flutter build web \
  --dart-define=API_BASE_URL=<url-del-backend>
```

## Compatibilidad Android y Web

Las APIs dependientes de plataforma estan aisladas en `lib/utils/`. El selector
de archivos, la apertura de documentos y enlaces usan una implementacion nativa
fuera de Web y una implementacion del navegador en Web. La instalacion como PWA
y la cache local de contrasenas generadas por administradores solo estan
disponibles en Web.

Para evitar que codigo exclusivo del navegador rompa la compilacion Android,
los imports de `dart:html` y `dart:js_interop` deben permanecer en
`lib/utils/plataforma_web.dart`; la prueba `test/sin_imports_web_test.dart`
comprueba esta regla.

## Verificaciones

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build web
```

El analizador puede mostrar avisos informativos existentes; revisa que la
compilacion y las pruebas terminen correctamente.
