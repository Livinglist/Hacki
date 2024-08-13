part of 'remote_config_cubit.dart';

final class RemoteConfigState extends Equatable {
  const RemoteConfigState({
    required this.data,
  });

  RemoteConfigState.init() : data = <String, dynamic>{};

  @protected
  final Map<String, dynamic> data;

  String get storySelector => getString(
        key: 'storySelector',
        fallback: '''#hnmain > tbody > tr > td > table > tbody > .athing''',
      );

  String get subtextSelector => getString(
        key: 'subtextSelector',
        fallback:
            '''#hnmain > tbody > tr > td > table > tbody > tr > .subtext''',
      );

  String get titlelineSelector => getString(
        key: 'titlelineSelector',
        fallback: '''.title > .titleline > a''',
      );

  String get pointSelector => getString(
        key: 'pointSelector',
        fallback: '''.subline > .score''',
      );

  String get userSelector => getString(
        key: 'userSelector',
        fallback: '''.subline > .hnuser''',
      );

  String get ageSelector => getString(
        key: 'ageSelector',
        fallback: '''.subline > .age''',
      );

  String get cmtCountSelector => getString(
        key: 'cmtCountSelector',
        fallback: '''.subline > a''',
      );

  String get moreLinkSelector => getString(
        key: 'moreLinkSelector',
        fallback:
            ''''#hnmain > tbody > tr:nth-child(3) > td > table > tbody > tr > td.title > a''',
      );

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
