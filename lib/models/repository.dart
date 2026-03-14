class Repository {
  final String id;
  final String name;
  final String project;

  Repository({required this.id, required this.name, required this.project});

  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
      id: json['id'] as String,
      name: json['name'] as String,
      project: (json['project'] as Map<String, dynamic>)['name'] as String,
    );
  }
}
