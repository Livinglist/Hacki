import 'package:equatable/equatable.dart';
import 'package:hacki/models/github/github_repository.dart';

enum GithubStatus { initial, loading, success, failure }

class GithubState extends Equatable {
  const GithubState({
    this.repositories = const <String, GithubRepository>{},
    this.status = GithubStatus.initial,
    this.error,
  });

  final Map<String, GithubRepository> repositories;
  final GithubStatus status;
  final String? error;

  GithubState copyWith({
    Map<String, GithubRepository>? repositories,
    GithubStatus? status,
    String? error,
  }) {
    return GithubState(
      repositories: repositories ?? this.repositories,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [repositories, status, error];
}
