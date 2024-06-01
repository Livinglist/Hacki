part of 'remote_config_cubit.dart';

final class RemoteConfigState extends Equatable {
  const RemoteConfigState({
    required this.data,
  });

  RemoteConfigState.init() : data = <String, dynamic>{};

  @protected
  final Map<String, dynamic> data;

  String get athingComtrSelector => getString(
        key: 'athingComtrSelector',
        fallback:
            '''#hnmain > tbody > tr > td > table > tbody > .athing.comtr''',
      );

  String get commentTextSelector => getString(
        key: 'commentTextSelector',
        fallback:
            '''td > table > tbody > tr > td.default > div.comment > div.commtext''',
      );

  String get commentHeadSelector => getString(
        key: 'commentHeadSelector',
        fallback: '''td > table > tbody > tr > td.default > div > span > a''',
      );

  String get commentAgeSelector => getString(
        key: 'commentAgeSelector',
        fallback:
            '''td > table > tbody > tr > td.default > div > span > span.age''',
      );

  String get commentIndentSelector => getString(
        key: 'commentIndentSelector',
        fallback: '''td > table > tbody > tr > td.ind''',
      );

  String getString({required String key, String fallback = ''}) {
    return data[key] as String? ?? fallback;
  }

  bool getBool({required String key, bool fallback = false}) {
    return data[key] as bool? ?? fallback;
  }

  int getInt({required String key, int fallback = 0}) {
    return data[key] as int? ?? fallback;
  }

  RemoteConfigState copyWith({Map<String, dynamic>? data}) {
    return RemoteConfigState(data: data ?? this.data);
  }

  @override
  List<Object?> get props => <Object?>[data];
}
