class PullRequest {
  final int id;
  final String title;
  final String status;
  final String createdBy;
  final String targetBranch;
  final String repository;
  final int approvals;

  PullRequest({
    required this.id,
    required this.title,
    required this.status,
    required this.createdBy,
    required this.targetBranch,
    required this.repository,
    required this.approvals,
  });

  factory PullRequest.fromJson(Map<String, dynamic> json) {
    final reviewers = (json['reviewers'] as List<dynamic>?) ?? [];
    final approvals = reviewers
        .cast<Map<String, dynamic>>()
        .where((r) => r['vote'] == 10)
        .length;

    return PullRequest(
      id: json['pullRequestId'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      createdBy: (json['createdBy'] as Map<String, dynamic>)['displayName'] as String,
      targetBranch: (json['targetRefName'] as String).replaceFirst('refs/heads/', ''),
      repository: (json['repository'] as Map<String, dynamic>)['name'] as String,
      approvals: approvals,
    );
  }
}
