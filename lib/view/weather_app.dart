import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  final TextEditingController cidadeController = TextEditingController();

  String resultado = '';
  String temperatura = '';
  String condicao = '';
  String sensacaoTermica = '';
  String vento = '';
  String iconeUrl = '';
  List<String> historicoCidades = [];

  @override
  void initState() {
    super.initState();
    obterLocalizacao();
  }

  Future<void> obterLocalizacao() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      final posicao = await Geolocator.getCurrentPosition();
      buscarClima(lat: posicao.latitude, lon: posicao.longitude);
    } else {
      setState(() {
        resultado = 'Permissão de localização negada.';
      });
    }
  }

  void buscarClima({String? cidade, double? lat, double? lon}) async {
    const apiKey = '9ff8d7ae24e3449e921222637251908';

    Uri url;

    if (cidade != null) {
      url = Uri.parse(
        'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$cidade&aqi=yes',
      );
    } else if (lat != null && lon != null) {
      url = Uri.parse(
        'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$lat,$lon&aqi=yes',
      );
    } else {
      return;
    }

    final resposta = await http.get(url);

    if (resposta.statusCode == 200) {
      final dados = jsonDecode(resposta.body);
      final cidadeNome = dados['location']['name'];
      final temp = dados['current']['temp_c'];
      final feelsLike = dados['current']['feelslike_c'];
      final wind = dados['current']['wind_kph'];
      final cond = dados['current']['condition']['text'];
      final icon = dados['current']['condition']['icon'];

      setState(() {
        temperatura = '$temp°C';
        sensacaoTermica = '$feelsLike°C';
        vento = '$wind km/h';
        condicao = cond;
        iconeUrl = 'https:$icon';
        resultado = 'Cidade: $cidadeNome';

        // Atualiza histórico
        if (cidade != null && cidade.isNotEmpty) {
          historicoCidades.removeWhere(
            (item) => item.toLowerCase() == cidade.toLowerCase(),
          );
          historicoCidades.insert(0, cidade);
          if (historicoCidades.length > 5) {
            historicoCidades = historicoCidades.sublist(0, 5);
          }
        }
      });
    } else {
      setState(() {
        resultado = 'Erro na requisição: ${resposta.statusCode}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clima App')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: cidadeController,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.search),
                  labelText: 'Digite a cidade:',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  final cidade = cidadeController.text.trim();
                  if (cidade.isNotEmpty) {
                    buscarClima(cidade: cidade);
                    cidadeController.clear();
                  }
                },
                child: const Text('Buscar Clima'),
              ),
              if (historicoCidades.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Últimas cidades buscadas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: historicoCidades
                      .map(
                        (cidade) => ActionChip(
                          label: Text(cidade),
                          onPressed: () {
                            buscarClima(cidade: cidade);
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 25),
              resultado.isNotEmpty
                  ? Column(
                      children: [
                        Text(
                          resultado,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (iconeUrl.isNotEmpty)
                          Image.network(
                            iconeUrl,
                            height: 64,
                            width: 64,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported),
                          ),
                        const SizedBox(height: 10),
                        Text('Condição: $condicao'),
                        Text('Temperatura: $temperatura'),
                        Text('Sensação térmica: $sensacaoTermica'),
                        Text('Vento: $vento'),
                      ],
                    )
                  : const Text('Dados não encontrados ou não informados.'),
            ],
          ),
        ),
      ),
    );
  }
}
