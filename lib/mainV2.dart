import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Converter',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.black,
        hintColor: Colors.white,
      ),
      home: CurrencyConverter(),
    );
  }
}

class CurrencyConverter extends StatefulWidget {
  @override
  _CurrencyConverterState createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  late Map<String, dynamic> rates;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRates();
  }

  Future<void> fetchRates() async {
    final response = await http.get(Uri.parse('https://bonbast.amirhn.com/latest'));
    if (response.statusCode == 200) {
      setState(() {
        rates = json.decode(response.body);
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load rates');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Currency Converter'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Price'),
              Tab(text: 'Convert'),
            ],
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  PriceTab(rates: rates),
                  ConvertTab(rates: rates),
                ],
              ),
      ),
    );
  }
}

class PriceTab extends StatelessWidget {
  final Map<String, dynamic> rates;

  PriceTab({required this.rates});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: rates.keys.length,
      itemBuilder: (context, index) {
        String key = rates.keys.elementAt(index);
        return ListTile(
          title: Text(
            key.toUpperCase(),
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            'Sell: ${rates[key]['sell']} IRR, Buy: ${rates[key]['buy']} IRR',
            style: TextStyle(color: Colors.white70),
          ),
        );
      },
    );
  }
}

class ConvertTab extends StatefulWidget {
  final Map<String, dynamic> rates;

  ConvertTab({required this.rates});

  @override
  _ConvertTabState createState() => _ConvertTabState();
}

class _ConvertTabState extends State<ConvertTab> {
  String fromCurrency = 'usd';
  String toCurrency = 'irr';
  double amount = 1.0;
  double result = 0.0;

  void convert() {
    double fromRate = widget.rates[fromCurrency]['sell'].toDouble();
    double toRate = toCurrency == 'irr' ? 1.0 : widget.rates[toCurrency]['sell'].toDouble();
    setState(() {
      result = (amount * fromRate) / toRate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Amount',
              labelStyle: TextStyle(color: Colors.white),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.white),
            onChanged: (value) {
              amount = double.tryParse(value) ?? 1.0;
            },
          ),
          SizedBox(height: 16.0),
          DropdownButton<String>(
            value: fromCurrency,
            dropdownColor: Colors.black,
            items: widget.rates.keys.map((String key) {
              return DropdownMenuItem<String>(
                value: key,
                child: Text(key.toUpperCase(), style: TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                fromCurrency = value!;
              });
            },
          ),
          SizedBox(height: 16.0),
          DropdownButton<String>(
            value: toCurrency,
            dropdownColor: Colors.black,
            items: ['irr', ...widget.rates.keys].map((String key) {
              return DropdownMenuItem<String>(
                value: key,
                child: Text(key.toUpperCase(), style: TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                toCurrency = value!;
              });
            },
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: convert,
            child: Text('Convert'),
          ),
          SizedBox(height: 16.0),
          Text(
            'Result: $result ${toCurrency.toUpperCase()}',
            style: TextStyle(color: Colors.white, fontSize: 24.0),
          ),
        ],
      ),
    );
  }
}
