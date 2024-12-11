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
  'irr': 'Iranian Riyal',
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
  'irr': '🇮🇷',
  'myr': '🇲🇾',
  'afn': '🇦🇫',
  'kwd': '🇰🇼',
  'iqd': '🇮🇶',
  'bhd': '🇧🇭',
  'omr': '🇴🇲',
  'qar': '🇶🇦',
  'emami1': '🪙 ',
  'azadi1g': '🟡',
  'azadi1': '🟡',
  'azadi1_2': '🟡',
  'azadi1_4': '🟡',
  'mithqal': '⚖️',
  'gol18': '🟡',
  'ounce': '🪙 ',
  'bitcoin': '₿',
};

// Function to format numbers with commas and K/M notation
String formatPrice(double price) {
  if (price >= 1000000) {
    return '${(price / 1000000).toStringAsFixed(1)}M';
  } else if (price >= 100000) {
    return '${(price / 1000).toStringAsFixed(0)}K';
  } else {
    if (price % 1 == 0) {
      return price.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    } else {
      return price.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    }
  }
}

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

  PriceTab({
    required this.currencyData,
    required this.previousCurrencyData,
    required this.currencyCodes,
  });

  @override
  Widget build(BuildContext context) {
    if (currencyData.isEmpty) {
      return Center(child: CircularProgressIndicator());
    } else {
      return GridView.builder(
        padding: EdgeInsets.all(8.0),
        itemCount: currencyCodes.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Number of columns
          childAspectRatio: 1, // To make cards square
        ),
        itemBuilder: (BuildContext context, int index) {
          String code = currencyCodes[index];
          Map<String, dynamic> data = currencyData[code];
          if (data['buy'] != null) {
            String name = currencyNames[code.toLowerCase()] ?? code.toUpperCase();
            String symbol = currencySymbols[code.toLowerCase()] ?? '';
            double priceValue = data['buy'].toDouble();

            // Format the price
            String price = formatPrice(priceValue);

            // Calculate price difference
            String priceDifference = '';
            Color diffColor = Colors.white;
            if (previousCurrencyData.isNotEmpty &&
                previousCurrencyData.containsKey(code)) {
              double previousPriceValue =
                  previousCurrencyData[code]['buy'].toDouble();
              double diff = priceValue - previousPriceValue;
              if (diff != 0) {
                String diffStr = diff > 0
                    ? '+${formatPrice(diff)}'
                    : '${formatPrice(diff)}';
                diffColor = diff > 0 ? Colors.green : Colors.red;
                priceDifference = diffStr;
              }
            }

            return Card(
              color: Colors.grey[850],
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    // Top left currency name
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Text(
                        name,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    // Top right currency code badge
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          symbol,
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                    ),
                    // Bottom left price
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (priceDifference != '')
                            Text(
                              priceDifference,
                              style:
                                  TextStyle(color: diffColor, fontSize: 14),
                            ),
                          Text(
                            price,
                            style:
                                TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Container();
          }
        },
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
    String result = convertedAmount % 1 == 0
        ? convertedAmount.toInt().toString()
        : convertedAmount.toStringAsFixed(2);

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
        backgroundColor: Colors.grey[900],
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
                String symbol = currencySymbols[code.toLowerCase()] ?? '';
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
                String symbol = currencySymbols[code.toLowerCase()] ?? '';
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
                backgroundColor: Colors.grey[700], // darker background
              ),
            ),
          ],
        ),
      );
    }
  }
}
