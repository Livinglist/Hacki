enum CommentsOrder {
  natural('Natural'),
  newestFirst('Newest first'),
  oldestFirst('Oldest first');

  const CommentsOrder(this.description);

  final String description;
}
