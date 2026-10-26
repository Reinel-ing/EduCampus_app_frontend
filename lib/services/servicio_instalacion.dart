import '../utils/plataforma.dart';

class InstalacionService {
  bool get instalacionDisponible => instalacionPwaDisponible();

  Future<String> instalar() => instalarPwa();
}
