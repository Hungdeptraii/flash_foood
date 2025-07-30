import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_model.dart';

class FoodService {
  static const String baseUrl = 'http://192.168.10.1:3000/api/foods'; // Sửa lại nếu backend chạy port khác

  static Future<List<FoodModel>> getFoods() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => FoodModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load foods');
    }
  }

  static Future<FoodModel> addFood(FoodModel food) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(food.toJson()),
    );
    if (response.statusCode == 201) {
      return FoodModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add food');
    }
  }

  static Future<FoodModel> updateFood(FoodModel food) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${food.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(food.toJson()),
    );
    if (response.statusCode == 200) {
      return FoodModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update food');
    }
  }

  static Future<void> deleteFood(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete food');
    }
  }
} 