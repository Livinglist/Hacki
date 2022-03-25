import 'dart:convert';

class User {
  User({
    required this.about,
    required this.created,
    required this.delay,
    required this.id,
    required this.karma,
  });

  User.empty()
      : about = '',
        created = 0,
        delay = 0,
        id = '',
        karma = 0;

  User.fromJson(Map<String, dynamic> json)
      : about = json['about'] as String? ?? '',
        created = json['created'] as int? ?? 0,
        delay = json['delay'] as int? ?? 0,
        id = json['id'] as String? ?? '',
        karma = json['karma'] as int? ?? 0;

  final String about;
  final int created;
  final int delay;
  final String id;
  final int karma;

  @override
  String toString() {
    final prettyString = const JsonEncoder.withIndent('  ').convert(this);
    return 'User $prettyString';
  }
}
