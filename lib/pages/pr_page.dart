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
    if (pat.isEmpty) {
      SnackBarService.show(
        'Please enter a PAT in Settings before listing PRs.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _pullRequests = [];
    });

    try {
      final credentials = base64Encode(utf8.encode(':$pat'));
      final uri = Uri.parse(
        'https://dev.azure.com/$organisation/FFA/_apis/git/repositories/FFA-Agreements/pullrequests?api-version=7.1&searchCriteria.creatorId=$userId',
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Basic $credentials'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (data['value'] as List<dynamic>)
            .map((e) => PullRequest.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() => _pullRequests = items);
      } else {
        SnackBarService.show(
          'Error ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
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
