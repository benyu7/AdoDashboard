import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/pull_request.dart';
import '../services/auth_state.dart';
import '../services/snack_bar_service.dart';
import '../widgets/pr_list_tile.dart';

class PrPage extends StatefulWidget {
  const PrPage({super.key});

  @override
  State<PrPage> createState() => _PrPageState();
}

class _PrPageState extends State<PrPage> {
  bool _loading = false;
  List<PullRequest> _pullRequests = [];

  Future<void> _listPullRequests() async {
    final auth = context.read<AuthState>();
    final pat = auth.pat;
    final organisation = auth.organisation;
    final userId = auth.userId;
    final projects = auth.selectedProjects;
    final repositories = auth.selectedRepositories;

    if (pat.isEmpty) {
      SnackBarService.show(
        'Please enter a PAT in Settings before listing PRs.',
      );
      return;
    }
    if (userId.isEmpty) {
      SnackBarService.show(
        'Generate a User ID in Settings before listing PRs.',
      );
      return;
    }
    if (projects.isEmpty || repositories.isEmpty) {
      SnackBarService.show(
        'Select at least one project and repository in Settings.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _pullRequests = [];
    });

    try {
      print('Fetching PRs for projects: $projects, repos: $repositories');
      final credentials = base64Encode(utf8.encode(':$pat'));
      final requests = <Future<http.Response>>[];
      for (final project in projects) {
        for (final repo in repositories) {
          print('Fetching PRs for project: $project, repo: $repo');
          print(
            'https://dev.azure.com/$organisation/$project/_apis/git/repositories/$repo/pullrequests?api-version=7.1&searchCriteria.creatorId=$userId',
          );
          requests.add(
            http.get(
              Uri.parse(
                'https://dev.azure.com/$organisation/$project/_apis/git/repositories/$repo/pullrequests?api-version=7.1&searchCriteria.creatorId=$userId',
              ),
              headers: {'Authorization': 'Basic $credentials'},
            ),
          );
        }
      }

      final responses = await Future.wait(requests);
      final allPrs = <PullRequest>[];

      for (final response in responses) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          allPrs.addAll(
            (data['value'] as List<dynamic>).map(
              (e) => PullRequest.fromJson(e as Map<String, dynamic>),
            ),
          );
        } else {
          SnackBarService.show(
            'Error ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      }

      allPrs.sort((a, b) => b.id.compareTo(a.id));
      setState(() => _pullRequests = allPrs);
      if (allPrs.isEmpty) SnackBarService.show('No pull requests found.');
    } catch (e) {
      SnackBarService.show('Request failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Pull Requests'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _listPullRequests,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.list),
                label: const Text('List PRs'),
              ),
            ),
            if (_pullRequests.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                '${_pullRequests.length} pull request${_pullRequests.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: _pullRequests.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      PrListTile(pr: _pullRequests[index]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
