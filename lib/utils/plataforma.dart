// Puerta de entrada única a todo lo que depende de la plataforma.
export 'archivo_elegido.dart';
export 'plataforma_movil.dart'
    if (dart.library.js_interop) 'plataforma_web.dart';
