class Habit {
  int id;
  String name;
  String category;
  bool done;

  Habit({
    required this.id,
    required this.name,
    required this.category,
    this.done = false,
  });
}
