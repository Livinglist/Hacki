mixin PostDataMixin {
  Map<String, dynamic> toJson();
}

class LoginPostData with PostDataMixin {
  LoginPostData({
    required this.acct,
    required this.pw,
    required this.goto,
  });

  final String acct;
  final String pw;
  final String goto;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'acct': acct,
      'pw': pw,
      'goto': goto,
    };
  }
}

class CommentPostData with PostDataMixin {
  CommentPostData({
    required this.acct,
    required this.pw,
    required this.text,
    required this.parent,
  });

  final String acct;
  final String pw;
  final String text;
  final int parent;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'acct': acct,
      'pw': pw,
      'text': text,
      'parent': parent,
    };
  }
}

class FlagPostData with PostDataMixin {
  FlagPostData({
    required this.acct,
    required this.pw,
    required this.id,
    this.un,
  });

  final String acct;
  final String pw;
  final int id;
  final String? un;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'acct': acct,
      'pw': pw,
      'id': id,
      'un': un,
    };
  }
}
