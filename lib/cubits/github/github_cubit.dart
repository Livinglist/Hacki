import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/github/github_states.dart';
import 'package:hacki/models/github/github_repository.dart';

class GithubCubit extends Cubit<GithubState> {
  GithubCubit({Dio? dio})
      : _dio = dio ?? Dio(),
        super(const GithubState());

  final Dio _dio;
  static const String _githubApiUrl = 'https://api.github.com/repos/';
  static const String _token = 'YOUR_GITHUB_PAT_ADMIN';

  Future<void> fetchRepository(String url) async {
    if (state.repositories.containsKey(url)) return;
    if (!_isValidGithubUrl(url)) return;

    emit(state.copyWith(status: GithubStatus.loading));

    try {
      final String apiUrl = url.replaceFirst(
        'https://github.com/',
        _githubApiUrl,
      );

      final response = await _dio.get(
        apiUrl,
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
        ),
      );

      final GithubRepository repository =
          GithubRepository.fromJson(response.data as Map<String, dynamic>);

      emit(state.copyWith(
        repositories: {...state.repositories, url: repository},
        status: GithubStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GithubStatus.failure,
        error: e.toString(),
      ));
    }
  }

  bool _isValidGithubUrl(String url) {
    return RegExp(r'^https://github\.com/[\w\-]+/[\w\-]+$').hasMatch(url);
  }
}
