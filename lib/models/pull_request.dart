class PullRequest {
  final int id;
  final String title;
  final String status;
  final String createdBy;
  final String targetBranch;

  PullRequest({
    required this.id,
    required this.title,
    required this.status,
    required this.createdBy,
    required this.targetBranch,
  });

  factory PullRequest.fromJson(Map<String, dynamic> json) {
    return PullRequest(
      id: json['pullRequestId'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      createdBy: (json['createdBy'] as Map<String, dynamic>)['displayName'] as String,
      targetBranch: (json['targetRefName'] as String).replaceFirst('refs/heads/', ''),
    );
  }
}
