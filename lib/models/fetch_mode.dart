enum FetchMode {
  lazy('Lazy'),
  eager('Eager');

  const FetchMode(this.description);

  final String description;

  @override
  String toString() => description;
}
