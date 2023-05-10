import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class BackendService {
  static Future<String> httpConnetPost({
    String? message,
    String? battery,
    String? hour,
    String? date,
  }) async {
    Uri url = Uri.parse('https://back-taller.onrender.com');

    try {
      final response = await http.post(
        url,
        body: {
          'message': message ?? '',
          'battery': battery ?? '',
          'hour': hour ?? '',
          'date': date ?? '',
        },
      );

      Map<String, dynamic> resNode = json.decode(response.body);

      return resNode["peticion_body"]["message"]["text"];
    } catch (e) {
      print(e);
      return 'No se pudo conectar con el servidor';
    }
  }
}
