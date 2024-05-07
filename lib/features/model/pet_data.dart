// To parse this JSON data, do
//
//     final petGetData = petGetDataFromJson(jsonString);

import 'dart:convert';

List<PetGetData> petGetDataFromJson(String str) =>
    List<PetGetData>.from(json.decode(str).map((x) => PetGetData.fromJson(x)));

String petGetDataToJson(List<PetGetData> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class PetGetData {
  String petId;
  String userId;
  String name;
  String gender;
  String typePet;
  String breedPet;
  DateTime birthdate;
  String color;
  String petDegree;
  String imageProfile;
  String description;
  int price;
  double weight;

  PetGetData({
    required this.petId,
    required this.userId,
    required this.name,
    required this.gender,
    required this.typePet,
    required this.breedPet,
    required this.birthdate,
    required this.color,
    required this.petDegree,
    required this.imageProfile,
    required this.description,
    required this.price,
    required this.weight,
  });

  PetGetData copyWith({
    String? petId,
    String? userId,
    String? name,
    String? gender,
    String? typePet,
    String? breedPet,
    DateTime? birthdate,
    String? color,
    String? petDegree,
    String? imageProfile,
    String? description,
    int? price,
    double? weight,
  }) =>
      PetGetData(
        petId: petId ?? this.petId,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        gender: gender ?? this.gender,
        typePet: typePet ?? this.typePet,
        breedPet: breedPet ?? this.breedPet,
        birthdate: birthdate ?? this.birthdate,
        color: color ?? this.color,
        petDegree: petDegree ?? this.petDegree,
        imageProfile: imageProfile ?? this.imageProfile,
        description: description ?? this.description,
        price: price ?? this.price,
        weight: weight ?? this.weight,
      );

  factory PetGetData.fromJson(Map<String, dynamic> json) => PetGetData(
        petId: json["pet_id"],
        userId: json["user_id"],
        name: json["name"],
        gender: json["gender"],
        typePet: json["type_pet"],
        breedPet: json["breed_pet"],
        birthdate: DateTime.parse(json["birthdate"]),
        color: json["color"],
        petDegree: json["pet_degree"],
        imageProfile: json["image_profile"],
        description: json["description"],
        price: json["price"],
        weight: json["weight"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "pet_id": petId,
        "user_id": userId,
        "name": name,
        "gender": gender,
        "type_pet": typePet,
        "breed_pet": breedPet,
        "birthdate":
            "${birthdate.year.toString().padLeft(4, '0')}-${birthdate.month.toString().padLeft(2, '0')}-${birthdate.day.toString().padLeft(2, '0')}",
        "color": color,
        "pet_degree": petDegree,
        "image_profile": imageProfile,
        "description": description,
        "price": price,
        "weight": weight,
      };
}
