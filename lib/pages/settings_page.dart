import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../services/auth_state.dart';
import '../services/snack_bar_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _patController;
  late final TextEditingController _orgController;
  late final TextEditingController _emailController;
  late final TextEditingController _userIdController;
  bool _obscurePat = true;
  bool _generating = false;
  bool _loadingProjects = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthState>();
    _patController = TextEditingController(text: auth.pat);
    _orgController = TextEditingController(text: auth.organisation);
    _emailController = TextEditingController(text: auth.email);
    _userIdController = TextEditingController(text: auth.userId);
  }

  @override
  void dispose() {
    _patController.dispose();
    _orgController.dispose();
    _emailController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _generateUserId() async {
    final auth = context.read<AuthState>();
    final pat = auth.pat;
    final email = auth.email;
    final organisation = auth.organisation;

    if (pat.isEmpty || email.isEmpty) {
      SnackBarService.show('PAT and email are required to generate a User ID.');
      return;
    }

    setState(() => _generating = true);

    try {
      final credentials = base64Encode(utf8.encode(':$pat'));
      final uri = Uri.parse(
        'https://vssps.dev.azure.com/$organisation/_apis/graph/users?api-version=7.1-preview.1',
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Basic $credentials'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final users = data['value'] as List<dynamic>;
        final match = users.cast<Map<String, dynamic>>().firstWhere(
          (u) =>
              (u['principalName'] as String?)?.toLowerCase() ==
              email.toLowerCase(),
          orElse: () => {},
        );

        if (match.isEmpty) {
          SnackBarService.show('No user found with email "$email".');
        } else {
          final originId = match['originId'] as String;
          await auth.setUserId(originId);
          if (mounted) _userIdController.text = originId;
          SnackBarService.show('User ID generated successfully.');
        }
      } else {
        SnackBarService.show(
          'Error ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      SnackBarService.show('Request failed: $e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _selectProjects() async {
    final auth = context.read<AuthState>();
    final pat = auth.pat;
    final organisation = auth.organisation;

    if (pat.isEmpty || organisation.isEmpty) {
      SnackBarService.show(
        'PAT and organisation are required to load projects.',
      );
      return;
    }

    setState(() => _loadingProjects = true);

    List<Project> projects = [];
    try {
      final credentials = base64Encode(utf8.encode(':$pat'));
      final uri = Uri.parse(
        'https://dev.azure.com/$organisation/_apis/projects?api-version=7.1',
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Basic $credentials'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        projects =
            (data['value'] as List<dynamic>)
                .map((e) => Project.fromJson(e as Map<String, dynamic>))
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name));
      } else {
        SnackBarService.show(
          'Error ${response.statusCode}: ${response.reasonPhrase}',
        );
        return;
      }
    } catch (e) {
      SnackBarService.show('Request failed: $e');
      return;
    } finally {
      if (mounted) setState(() => _loadingProjects = false);
    }

    if (!mounted) return;

    final current = Set<String>.from(auth.selectedProjects);
    final selected = Set<String>.from(current);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Projects'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: projects.map((project) {
                    return CheckboxListTile(
                      value: selected.contains(project.name),
                      title: Text(project.name),
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            selected.add(project.name);
                          } else {
                            selected.remove(project.name);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected.toSet().difference(current).isNotEmpty ||
        current.difference(selected).isNotEmpty) {
      await auth.setSelectedProjects(selected.toList());
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedProjects = context.watch<AuthState>().selectedProjects;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Access Token',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Required to authenticate with Azure DevOps.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _patController,
              obscureText: _obscurePat,
              enableInteractiveSelection: true,
              onChanged: (value) => context.read<AuthState>().setPat(value),
              decoration: InputDecoration(
                hintText: 'Enter your Azure DevOps PAT',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePat ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscurePat = !_obscurePat),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Organisation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _orgController,
              onChanged: (value) =>
                  context.read<AuthState>().setOrganisation(value),
              decoration: const InputDecoration(
                hintText: 'Enter your Azure DevOps organisation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Projects',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _loadingProjects ? null : _selectProjects,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffixIcon: _loadingProjects
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.arrow_drop_down),
                ),
                child: selectedProjects.isEmpty
                    ? const Text(
                        'Tap to select projects',
                        style: TextStyle(color: Colors.black38),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: selectedProjects
                            .map(
                              (name) => Chip(
                                label: Text(name),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                              ),
                            )
                            .toList(),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Email',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => context.read<AuthState>().setEmail(value),
              decoration: const InputDecoration(
                hintText: 'Enter your email address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'User ID',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userIdController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Not yet generated',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FloatingActionButton.extended(
                onPressed: _generating ? null : _generateUserId,
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: const Text('Generate'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
