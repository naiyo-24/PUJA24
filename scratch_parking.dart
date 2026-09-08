import 'dart:convert';
import 'package:dio/dio.dart';
void main() async {
  final dio = Dio();
  try {
    final response = await dio.get('https://maps.googleapis.com/maps/api/place/nearbysearch/json',
      queryParameters: {
        'location': '22.4578,88.4087', // Approx Rajpur Sonarpur coords
        'radius': '15000',
        'keyword': 'parking',
        'key': 'AIzaSyBmc97dQWHVQCx6obwgI3Quw2_BCJTeAIg'
      }
    );
    print(response.data['status']);
    if (response.data['status'] == 'OK') {
      print((response.data['results'] as List).length);
      print(response.data['results'][0]['name']);
    } else {
      print(response.data['error_message']);
    }
  } catch (e) {
    print(e);
  }
}
