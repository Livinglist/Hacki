import 'package:equatable/equatable.dart';

class GithubRepository extends Equatable {
  const GithubRepository({
    required this.fullName,
    required this.description,
    required this.stars,
    required this.language,
    required this.license,
    required this.watching,
    required this.forks,
  });

  final String fullName;
  final String description;
  final int stars;
  final String language;
  final String license;
  final int watching;
  final int forks;

  @override
  List<Object?> get props => <Object?>[
        fullName,
        description,
        stars,
        language,
        license,
        watching,
        forks,
      ];

  factory GithubRepository.fromJson(Map<String, dynamic> json) {
    return GithubRepository(
      fullName: json['full_name'] as String? ?? '',
      description: json['description']?.toString() ?? '',
      stars: json['stargazers_count'] as int? ?? 0,
      language: json['language']?.toString() ?? '',
      license:
          (json['license'] as Map<String, dynamic>?)?['name']?.toString() ??
              'No License',
      watching: json['subscribers_count'] as int? ?? 0,
      forks: json['forks_count'] as int? ?? 0,
    );
  }
}
