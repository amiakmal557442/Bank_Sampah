import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final url = Uri.parse(
    'http://localhost/bank_sampah_api/transactions/index.php',
  );
  final response = await http.get(url);
  final data = jsonDecode(response.body);
  print(jsonEncode(data['data']));
}
