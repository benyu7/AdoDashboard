import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';

const _patKey = 'ado_pat';

class AuthState extends ChangeNotifier {
  String _pat = '';

  String get pat => _pat;

  Future<void> load() async {
    final stored = await SecureStorageService.read(_patKey);
    if (stored != null) {
      _pat = stored;
      notifyListeners();
    }
  }

  Future<void> setPat(String value) async {
    _pat = value;
    notifyListeners();
    await SecureStorageService.write(_patKey, value);
  }

  Future<void> clearPat() async {
    _pat = '';
    notifyListeners();
    await SecureStorageService.delete(_patKey);
  }
}
