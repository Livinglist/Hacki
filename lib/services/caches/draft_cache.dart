class DraftCache {
  static final Map<int, String> _drafts = <int, String>{};

  void removeDraft({required int replyingTo}) => _drafts.remove(replyingTo);

  void cacheDraft({required String text, required int replyingTo}) =>
      _drafts[replyingTo] = text;

  String? getDraft({required int replyingTo}) => _drafts[replyingTo];
}
