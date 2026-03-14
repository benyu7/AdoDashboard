import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';

const _patKey = 'ado_pat';
const _emailKey = 'ado_email';
const _orgKey = 'ado_org';
const _userIdKey = 'ado_user_id';
const _projectsKey = 'ado_projects';
const _reposKey = 'ado_repositories';

class AuthState extends ChangeNotifier {
  String _pat = '';
  String _email = '';
  String _organisation = '';
  String _userId = '';
  List<String> _selectedProjects = [];
  List<String> _selectedRepositories = [];

  String get pat => _pat;
  String get email => _email;
  String get organisation => _organisation;
  String get userId => _userId;
  List<String> get selectedProjects => List.unmodifiable(_selectedProjects);
  List<String> get selectedRepositories => List.unmodifiable(_selectedRepositories);

  Future<void> load() async {
    final results = await Future.wait([
      SecureStorageService.read(_patKey),
      SecureStorageService.read(_emailKey),
      SecureStorageService.read(_orgKey),
      SecureStorageService.read(_userIdKey),
      SecureStorageService.read(_projectsKey),
      SecureStorageService.read(_reposKey),
    ]);
    _pat = results[0] ?? '';
    _email = results[1] ?? '';
    _organisation = results[2] ?? '';
    _userId = results[3] ?? '';
    final projectsJson = results[4];
    _selectedProjects = projectsJson != null
        ? List<String>.from(jsonDecode(projectsJson) as List)
        : [];
    final reposJson = results[5];
    _selectedRepositories = reposJson != null
        ? List<String>.from(jsonDecode(reposJson) as List)
        : [];
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

  Future<void> setOrganisation(String value) async {
    _organisation = value;
    notifyListeners();
    await SecureStorageService.write(_orgKey, value);
  }

  Future<void> clearOrganisation() async {
    _organisation = '';
    notifyListeners();
    await SecureStorageService.delete(_orgKey);
  }

  Future<void> setUserId(String value) async {
    _userId = value;
    notifyListeners();
    await SecureStorageService.write(_userIdKey, value);
  }

  Future<void> clearUserId() async {
    _userId = '';
    notifyListeners();
    await SecureStorageService.delete(_userIdKey);
  }

  Future<void> setSelectedProjects(List<String> projects) async {
    _selectedProjects = List.of(projects);
    notifyListeners();
    await SecureStorageService.write(_projectsKey, jsonEncode(projects));
  }

  Future<void> setSelectedRepositories(List<String> repositories) async {
    _selectedRepositories = List.of(repositories);
    notifyListeners();
    await SecureStorageService.write(_reposKey, jsonEncode(repositories));
  }
}
