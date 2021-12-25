abstract class Item {
  Item({
    required this.id,
    required this.deleted,
    required this.by,
    required this.time,
    required this.text,
    required this.dead,
    required this.parent,
    required this.kids,
    required this.poll,
    required this.url,
    required this.score,
    required this.title,
    required this.parts,
    required this.descendants,
  });

  final int id;
  final int time;
  final int poll;
  final int score;
  final int parent;

  /// The total comments count for stories and polls.
  final int descendants;

  final bool deleted;
  final bool dead;

  final String by;
  final String text;
  final String url;
  final String title;

  final List<int> kids;
  final List<int> parts;
}
