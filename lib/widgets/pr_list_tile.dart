import 'package:flutter/material.dart';
import '../models/pull_request.dart';

class PrListTile extends StatelessWidget {
  final PullRequest pr;

  const PrListTile({super.key, required this.pr});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'abandoned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      title: Text(
        pr.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(pr.createdBy),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward, size: 14),
          ),
          Text(pr.targetBranch),
          if (pr.approvals > 0) ...[
            const SizedBox(width: 8),
            ...List.generate(
              pr.approvals,
              (_) =>
                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
            ),
          ],
        ],
      ),
      trailing: Chip(
        label: Text(
          pr.status,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: _statusColor(pr.status),
        padding: EdgeInsets.zero,
      ),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          '#${pr.id}',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
