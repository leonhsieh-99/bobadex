import 'package:bobadex/models/city.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class CityDataProvider extends ChangeNotifier {
  List<City> _cities = [];

  List<City> parseCities(String jsonString) {
    final List<dynamic> data = json.decode(jsonString);
    return data.map((item) => City.fromJson(item)).toList();
  }

  Future<List<City>> getCities() async {
    if (_cities.isNotEmpty) return _cities;
    String jsonString = await rootBundle.loadString('lib/assets/cities.json');
    _cities = parseCities(jsonString);
    return _cities;
  }
}