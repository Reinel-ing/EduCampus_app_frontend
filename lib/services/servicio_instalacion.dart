import 'dart:js_interop';

@JS('eduCampusPuedeInstalar')
external bool _puedeInstalar();

@JS('eduCampusInstalarApp')
external JSPromise<JSString> _instalarApp();

class InstalacionService {
  bool get instalacionDisponible {
    try {
      return _puedeInstalar();
    } catch (_) {
      return false;
    }
  }

  Future<String> instalar() async {
    try {
      final resultado = await _instalarApp().toDart;
      return resultado.toDart;
    } catch (_) {
      return 'unavailable';
    }
  }
}
