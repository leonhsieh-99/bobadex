class City {
  final String name;
  final String state;

  const City({
    required this.name,
    required this.state,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
    name: json['city'] as String,
    state: json['state'] as String
  );
}