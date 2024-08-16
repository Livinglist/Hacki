enum HackerNewsDataSource {
  api('API'),
  web('Web');

  const HackerNewsDataSource(this.description);

  final String description;
}
