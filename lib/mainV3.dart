import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Entry point of the application.
void main() {
  runApp(MyApp());
}

// Custom theme data with black and white colors.
final ThemeData appThemeData = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.black,
  scaffoldBackgroundColor: Colors.black,
  hintColor: Colors.white,
  canvasColor: Colors.black,
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    titleLarge: TextStyle(color: Colors.white),
  ),
);

// Mapping of currency codes to full names.
Map<String, String> currencyNames = {
  'usd': 'US Dollar',
  'eur': 'Euro',
  'gbp': 'British Pound',
  'chf': 'Swiss Franc',
  'cad': 'Canadian Dollar',
  'aud': 'Australian Dollar',
  'sek': 'Swedish Krona',
  'nok': 'Norwegian Krone',
  'rub': 'Russian Ruble',
  'thb': 'Thai Baht',
  'sgd': 'Singapore Dollar',
  'hkd': 'Hong Kong Dollar',
  'azn': 'Azerbaijani Manat',
  'amd': 'Armenian Dram',
  'dkk': 'Danish Krone',
  'aed': 'UAE Dirham',
  'jpy': 'Japanese Yen',
  'try': 'Turkish Lira',
  'cny': 'Chinese Yuan',
  'sar': 'Saudi Riyal',
  'inr': 'Indian Rupee',
  'myr': 'Malaysian Ringgit',
  'afn': 'Afghan Afghani',
  'kwd': 'Kuwaiti Dinar',
  'iqd': 'Iraqi Dinar',
  'bhd': 'Bahraini Dinar',
  'omr': 'Omani Rial',
  'qar': 'Qatari Riyal',
  'emami1': 'Imami Gold Coin',
  'azadi1g': 'Azadi Gold Coin',
  'azadi1': 'Full Azadi Coin',
  'azadi1_2': 'Half Azadi Coin',
  'azadi1_4': 'Quarter Azadi Coin',
  'mithqal': 'Mesqal',
  'gol18': 'Gold 18K',
  'ounce': 'Gold Ounce',
  'bitcoin': 'Bitcoin',
};

// Mapping of currency codes to emojis for symbols.
Map<String, String> currencySymbols = {
  'usd': '🇺🇸',
  'eur': '🇪🇺',
  'gbp': '🇬🇧',
  'chf': '🇨🇭',
  'cad': '🇨🇦',
  'aud': '🇦🇺',
  'sek': '🇸🇪',
  'nok': '🇳🇴',
  'rub': '🇷🇺',
  'thb': '🇹🇭',
  'sgd': '🇸🇬',
  'hkd': '🇭🇰',
  'azn': '🇦🇿',
  'amd': '🇦🇲',
  'dkk': '🇩🇰',
  'aed': '🇦🇪',
  'jpy': '🇯🇵',
  'try': '🇹🇷',
  'cny': '🇨🇳',
  'sar': '🇸🇦',
  'inr': '🇮🇳',
  'myr': '🇲🇾',
  'afn': '🇦🇫',
  'kwd': '🇰🇼',
  'iqd': '🇮🇶',
  'bhd': '🇧🇭',
  'omr': '🇴🇲',
  'qar': '🇶🇦',
  'emami1': '💰',
  'azadi1g': '🥇',
  'azadi1': '🥇',
  'azadi1_2': '🥈',
  'azadi1_4': '🥉',
  'mithqal': '⚖️',
  'gol18': '👑',
  'ounce': '🏅',
  'bitcoin': '₿',
};

// Root widget of the application.
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

// State of the root widget.
class _MyAppState extends State<MyApp> {
  // Map to hold the currency data.
  Map<String, dynamic> currencyData = {};

  // Map to hold the previous currency data for price difference.
  Map<String, dynamic> previousCurrencyData = {};

  // List of currency codes to display.
  List<String> currencyCodes = [];

  // Last updated time.
  String lastUpdatedTime = '';

  // Fetch data from the API.
  Future<void> fetchData() async {
    final response =
        await http.get(Uri.parse('https://bonbast.amirhn.com/latest'));
    if (response.statusCode == 200) {
      setState(() {
        previousCurrencyData = Map.from(currencyData);
        currencyData = json.decode(response.body);

        // Remove 'irr' from currencyCodes for Price page
        currencyCodes = currencyData.keys.toList();
        currencyCodes.remove('irr');

        // Update last updated time without seconds
        DateTime now = DateTime.now().toLocal();
        lastUpdatedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      });
    } else {
      throw Exception('Failed to load currency data');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // Build the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gheymat',
      theme: appThemeData,
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            bottom: TabBar(
              tabs: [
                Tab(text: 'Price'),
                Tab(text: 'Convert'),
              ],
            ),
            title: GestureDetector(
                onTap: () {
                  fetchData();
                },
                child: Text('Gheymat')),
          ),
          body: TabBarView(
            children: [
              PriceTab(
                currencyData: currencyData,
                previousCurrencyData: previousCurrencyData,
                currencyCodes: currencyCodes,
                lastUpdatedTime: lastUpdatedTime,
              ),
              ConvertTab(currencyData: currencyData),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget for the 'Price' tab.
class PriceTab extends StatelessWidget {
  final Map<String, dynamic> currencyData;
  final Map<String, dynamic> previousCurrencyData;
  final List<String> currencyCodes;
  final String lastUpdatedTime;

  PriceTab({
    required this.currencyData,
    required this.previousCurrencyData,
    required this.currencyCodes,
    required this.lastUpdatedTime,
  });

  @override
  Widget build(BuildContext context) {
    if (currencyData.isEmpty) {
      return Center(child: CircularProgressIndicator());
    } else {
      List<DataRow> rows = [];
      for (String code in currencyCodes) {
        Map<String, dynamic> data = currencyData[code];
        if (data['buy'] != null) {
          String name = currencyNames[code.toLowerCase()] ?? code.toUpperCase();
          String symbol = currencySymbols[code.toLowerCase()] ?? '';
          String price = data['buy'].toString();
          double currentPrice = data['buy'].toDouble();

          // Calculate price difference
          String priceDifference = '';
          Color diffColor = Colors.white;
          if (previousCurrencyData.isNotEmpty &&
              previousCurrencyData.containsKey(code)) {
            double previousPrice =
                previousCurrencyData[code]['buy'].toDouble();
            double diff = currentPrice - previousPrice;
            if (diff != 0) {
              String diffStr = diff > 0
                  ? '+${diff.toStringAsFixed(2)}'
                  : diff.toStringAsFixed(2);
              diffColor = diff > 0 ? Colors.green : Colors.red;
              priceDifference = ' (${diffStr})';
            }
          }

          rows.add(
            DataRow(
              cells: [
                DataCell(Row(
                  children: [
                    Text(
                      symbol,
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(width: 8),
                    Text(
                      name,
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        code.toUpperCase(),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                )),
                DataCell(
                  Row(
                    children: [
                      Text(
                        double.parse(price).toStringAsFixed(2),
                        style: TextStyle(color: Colors.white),
                      ),
                      if (priceDifference != '')
                        Text(
                          priceDifference,
                          style: TextStyle(color: diffColor),
                        ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    lastUpdatedTime,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
      }

      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columnSpacing: 16.0,
          columns: [
            DataColumn(
                label: Text('Currency', style: TextStyle(color: Colors.white))),
            DataColumn(
                label: Text('Price', style: TextStyle(color: Colors.white))),
            DataColumn(
                label:
                    Text('Updated', style: TextStyle(color: Colors.white))),
          ],
          rows: rows,
        ),
      );
    }
  }
}

// Widget for the 'Convert' tab.
class ConvertTab extends StatefulWidget {
  final Map<String, dynamic> currencyData;

  ConvertTab({required this.currencyData});

  @override
  _ConvertTabState createState() => _ConvertTabState();
}

class _ConvertTabState extends State<ConvertTab> {
  String fromCurrency = 'usd';
  String toCurrency = 'irr';
  double amount = 1.0;
  String result = '';

  TextEditingController amountController = TextEditingController(text: '1.0');

  @override
  void initState() {
    super.initState();
    if (!widget.currencyData.containsKey('irr')) {
      widget.currencyData['irr'] = {'buy': 1.0};
    }
  }

  void convertCurrency() {
    double fromRate;
    double toRate;

    if (fromCurrency == 'irr') {
      fromRate = 1.0;
    } else {
      fromRate = widget.currencyData[fromCurrency]['buy'].toDouble();
    }
    if (toCurrency == 'irr') {
      toRate = 1.0;
    } else {
      toRate = widget.currencyData[toCurrency]['buy'].toDouble();
    }
    double convertedAmount = (amount * fromRate) / toRate;
    result = convertedAmount.toStringAsFixed(2);

    String fromName =
        currencyNames[fromCurrency.toLowerCase()] ?? fromCurrency.toUpperCase();
    String toName =
        currencyNames[toCurrency.toLowerCase()] ?? toCurrency.toUpperCase();

    // Show the result in a Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$amount $fromName equals $result $toName',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[800],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currencyData.isEmpty) {
      return Center(child: CircularProgressIndicator());
    } else {
      List<String> currencyCodes =
          List<String>.from(widget.currencyData.keys);
      return Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              keyboardType:
                  TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                try {
                  amount = double.parse(value);
                } catch (e) {
                  amount = 1.0;
                }
              },
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: fromCurrency,
              dropdownColor: Colors.black,
              decoration: InputDecoration(
                labelText: 'From',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              items: currencyCodes.map((String code) {
                String name =
                    currencyNames[code.toLowerCase()] ?? code.toUpperCase();
                String symbol =
                    currencySymbols[code.toLowerCase()] ?? '';
                return DropdownMenuItem<String>(
                  value: code,
                  child: Row(
                    children: [
                      Text(
                        symbol,
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(width: 8),
                      Text(
                        name,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  fromCurrency = value!;
                });
              },
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: toCurrency,
              dropdownColor: Colors.black,
              decoration: InputDecoration(
                labelText: 'To',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              items: currencyCodes.map((String code) {
                String name =
                    currencyNames[code.toLowerCase()] ?? code.toUpperCase();
                String symbol =
                    currencySymbols[code.toLowerCase()] ?? '';
                return DropdownMenuItem<String>(
                  value: code,
                  child: Row(
                    children: [
                      Text(
                        symbol,
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(width: 8),
                      Text(
                        name,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
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
              onPressed: convertCurrency,
              child: Text('Convert'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white, // foreground
              ),
            ),
          ],
        ),
      );
    }
  }
}
