class TeaRoom {
  final String id;
  String name;
  String? description;
  final String ownerId;

  TeaRoom ({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
  });

  TeaRoom copyWith ({
    String? id,
    String? name,
    String? description,
    String? ownerId,
  }) {
    return TeaRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  factory TeaRoom.fromJson(Map<String, dynamic> json) {
    return TeaRoom(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      ownerId: json['owner_id'],
    );
  }
}