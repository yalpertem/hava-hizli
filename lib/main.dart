import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const HavaHizliApp());

class HavaHizliApp extends StatelessWidget {
  const HavaHizliApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'hava-hızlı',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212),
          cardColor: const Color(0xFF1E1E1E),
          primarySwatch: Colors.blue,
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _cities = {
    'Berlin': [52.520008, 13.404954],
    'İzmir': [38.423733, 27.142826],
    'Kuşadası': [37.8556, 27.2566],
    'Mersin': [36.812103, 34.641479],
    'Ankara': [39.925533, 32.866287],
  };

  String _selected = 'Berlin';
  Map<String, double>?
      _temps; // {'tDay':..,'tNight':..,'tmDay':..,'tmNight':..}
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final c = _cities[_selected]!;
    final url = Uri.parse('https://api.open-meteo.com/v1/forecast'
        '?latitude=${c[0]}&longitude=${c[1]}'
        '&daily=temperature_2m_max,temperature_2m_min'
        '&forecast_days=2&timezone=auto');
    try {
      final r = await http.get(url);
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        final maxT = (d['daily']['temperature_2m_max'] as List)
            .cast<num>()
            .map((e) => e.toDouble())
            .toList();
        final minT = (d['daily']['temperature_2m_min'] as List)
            .cast<num>()
            .map((e) => e.toDouble())
            .toList();
        setState(() => _temps = {
              'tDay': maxT[0],
              'tNight': minT[0],
              'tmDay': maxT[1],
              'tmNight': minT[1],
            });
      } else {
        setState(() => _error = 'HTTP ${r.statusCode}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _card(String title, double day, double night) => Expanded(
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('☀️', style: TextStyle(fontSize: 28)),
                          Text('${day.toStringAsFixed(1)}°C',
                              style: const TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('🌙', style: TextStyle(fontSize: 28)),
                          Text('${night.toStringAsFixed(1)}°C',
                              style: const TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('hava-hızlı')),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E1E1E),
                    value: _selected,
                    items: _cities.keys
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c,
                                style: TextStyle(
                                  color: c == _selected
                                      ? Colors.blueAccent
                                      : Colors.white,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selected = val);
                        _fetch();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_loading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator())),
              if (_error != null)
                Expanded(child: Center(child: Text('Hata: $_error'))),
              if (_temps != null && _error == null) ...[
                _card('Bugün', _temps!['tDay']!, _temps!['tNight']!),
                const SizedBox(height: 12),
                _card('Yarın', _temps!['tmDay']!, _temps!['tmNight']!),
              ],
            ],
          ),
        ),
      );
}
