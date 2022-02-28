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

class FavoritePostData with PostDataMixin {
  FavoritePostData({
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

class VotePostData with PostDataMixin {
  VotePostData({
    required this.acct,
    required this.pw,
    required this.id,
    required this.how,
  });

  final String acct;
  final String pw;
  final int id;
  final String how;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'acct': acct,
      'pw': pw,
      'id': id,
      'how': how,
    };
  }
}

class SubmitPostData with PostDataMixin {
  SubmitPostData({
    required this.fnid,
    required this.fnop,
    required this.title,
    this.url,
    this.text,
  }) : assert((url != null && text == null) || (url == null && text != null));

  final String fnid;
  final String fnop;
  final String title;
  final String? url;
  final String? text;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fnid': fnid,
      'fnop': fnop,
      'title': title,
      'url': url,
      'text': text,
    };
  }
}

class EditPostData with PostDataMixin {
  EditPostData({
    required this.hmac,
    required this.id,
    this.text,
  });

  final String hmac;
  final int id;
  final String? text;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'hmac': hmac,
      'id': id,
      'text': text,
    };
  }
}

class FormPostData with PostDataMixin {
  FormPostData({
    required this.acct,
    required this.pw,
    this.id,
  });

  final String acct;
  final String pw;
  final int? id;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'acct': acct,
      'pw': pw,
      'id': id,
    };
  }
}
