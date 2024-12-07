import 'dart:convert';
import 'package:http/http.dart' as http;

class PythonFuzzyAPI {
  final String baseUrl;

  PythonFuzzyAPI(this.baseUrl);

  Future<double> computeSleepQuality(
      double rhythm, double stress, double duration, double environment) async {
    var url = Uri.parse('$baseUrl/compute_sleep_quality/');
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'rhythm': rhythm,
        'stress': stress,
        'duration': duration,
        'environment': environment,
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['sleep_quality'];
    } else {
      print('Error: ${response.body}');
      return 0.0;
    }
  }
}

void main() async {
  var api = PythonFuzzyAPI('http://127.0.0.1:8000'); // FastAPI server address
  double result = await api.computeSleepQuality(5, 7, 6, 8);
  print('Computed Sleep Quality: $result');
}
