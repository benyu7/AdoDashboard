import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';

const _patKey = 'ado_pat';
const _emailKey = 'ado_email';

class AuthState extends ChangeNotifier {
  String _pat = '';
  String _email = '';

  String get pat => _pat;
  String get email => _email;

  Future<void> load() async {
    final results = await Future.wait([
      SecureStorageService.read(_patKey),
      SecureStorageService.read(_emailKey),
    ]);
    _pat = results[0] ?? '';
    _email = results[1] ?? '';
    notifyListeners();
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

  Future<void> setEmail(String value) async {
    _email = value;
    notifyListeners();
    await SecureStorageService.write(_emailKey, value);
  }

  Future<void> clearEmail() async {
    _email = '';
    notifyListeners();
    await SecureStorageService.delete(_emailKey);
  }
}
