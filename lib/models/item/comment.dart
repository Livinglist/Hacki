import 'package:hacki/models/item/item.dart';

class Comment extends Item {
  Comment({
    required super.id,
    required super.time,
    required super.parent,
    required super.score,
    required super.by,
    required super.text,
    required super.kids,
    required super.dead,
    required super.deleted,
    required super.hidden,
    required this.level,
    required this.isFromCache,
    this.isHiddenByUser = false,
    this.isCollapsedByUser = false,
    this.isNew = false,
  }) : super(
          descendants: 0,
          parts: <int>[],
          title: '',
          url: '',
          type: '',
        );

  Comment.fromJson(super.json, {this.level = 0})
      : isFromCache = json['fromCache'] == true,
        isHiddenByUser = false,
        isCollapsedByUser = false,
        isNew = false,
        super.fromJson();

  Comment.fromJsonWithCollapsedStateOnly(super.json, {this.level = 0})
      : isFromCache = json['fromCache'] == true,
        isHiddenByUser = json['isHiddenByUser'] == true,
        isCollapsedByUser = json['isCollapsedByUser'] == true,
        isNew = false,
        super.fromJson();

  final int level;
  final bool isHiddenByUser;
  final bool isCollapsedByUser;
  final bool isFromCache;
  final bool isNew;

  String get metadata => '''by $by $timeAgo''';

  bool get isRoot => level == 0;

  Comment copyWith({
    int? level,
    int? kid,
    bool? hidden,
    bool? isHiddenByUser,
    bool? isCollapsedByUser,
    bool? isNew,
  }) {
    return Comment(
      id: id,
      time: time,
      parent: parent,
      score: score,
      by: by,
      text: text,
      kids: kid == null ? kids : <int>[...kids, kid],
      dead: dead,
      deleted: deleted,
      hidden: hidden ?? this.hidden,
      level: level ?? this.level,
      isFromCache: isFromCache,
      isHiddenByUser: isHiddenByUser ?? this.isHiddenByUser,
      isCollapsedByUser: isCollapsedByUser ?? this.isCollapsedByUser,
      isNew: isNew ?? this.isNew,
    );
  }

  Comment copyWithOnlyCollapseState() {
    return Comment(
      id: id,
      time: time,
      parent: parent,
      score: score,
      by: by,
      text: '',
      kids: kids,
      dead: dead,
      deleted: deleted,
      hidden: hidden,
      level: level,
      isFromCache: isFromCache,
      isHiddenByUser: isHiddenByUser,
      isCollapsedByUser: isCollapsedByUser,
    );
  }

  Map<String, dynamic> toJsonWithOnlyCollapseState() {
    return <String, dynamic>{
      ...super.toJson(full: false),
      'isHiddenByUser': isHiddenByUser,
      'isCollapsedByUser': isCollapsedByUser,
    };
  }

  @override
  bool? get stringify => false;

  @override
  List<Object?> get props => <Object?>[
        ...super.props,
        isHiddenByUser,
        isCollapsedByUser,
        isNew,
      ];
}
