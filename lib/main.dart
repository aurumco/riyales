import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

// Entry point of the application.
void main() {
  runApp(MyApp());
}

// Custom theme data with black and white colors, using Google Fonts.
final ThemeData appThemeData = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.black,
  scaffoldBackgroundColor: Colors.black,
  hintColor: Colors.white,
  canvasColor: Colors.black,
  fontFamily: GoogleFonts.varelaRound().fontFamily, // Use Google Fonts
  tabBarTheme: TabBarTheme(
    labelColor: Colors.white,       // Active tab text color
    unselectedLabelColor: Colors.white60, // Inactive tab text color
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: Colors.white, width: 2), // Active tab underline
    ),
  ),
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
  'irr': 'IR Toman',
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

// Mapping of currency codes to colors for card background.
Map<String, Color> currencyColors = {
  'usd': const Color.fromARGB(255, 0, 149, 255),
  'eur': const Color.fromARGB(255, 21, 72, 255),
  'gbp': const Color.fromARGB(255, 0, 139, 143),
  'chf': const Color.fromARGB(255, 251, 111, 146),
  'cad': const Color.fromARGB(255, 255, 17, 0),
  'aud': const Color.fromARGB(255, 72, 58, 202),
  'sek': const Color.fromARGB(255, 216, 213, 11),
  'nok': const Color.fromARGB(255, 202, 71, 62),
  'rub': const Color.fromARGB(255, 198, 6, 18),
  'thb': const Color.fromARGB(255, 157, 78, 221),
  'sgd': const Color.fromARGB(255, 255, 179, 198),
  'hkd': const Color.fromARGB(255, 244, 151, 142),
  'azn': const Color.fromARGB(255, 131, 197, 190),
  'amd': const Color.fromARGB(255, 253, 53, 1),
  'dkk': const Color.fromARGB(255, 180, 70, 62),
  'aed': const Color.fromARGB(255, 99, 99, 99),
  'jpy': const Color.fromARGB(255, 213, 26, 54),
  'try': const Color.fromARGB(255, 230, 41, 28),
  'cny': const Color.fromARGB(255, 246, 16, 0),
  'sar': const Color.fromARGB(255, 0, 183, 49),
  'inr': const Color.fromARGB(255, 226, 149, 120),
  'irr': const Color.fromARGB(255, 54, 54, 54),
  'myr': const Color.fromARGB(255, 84, 0, 149),
  'afn': const Color.fromARGB(255, 79, 104, 62),
  'kwd': const Color.fromARGB(255, 31, 138, 76),
  'iqd': const Color.fromARGB(255, 173, 55, 61),
  'bhd': const Color.fromARGB(255, 255, 0, 110),
  'omr': const Color.fromARGB(255, 255, 77, 109),
  'qar': const Color.fromARGB(255, 141, 0, 16),
  'emami1': const Color.fromARGB(255, 54, 54, 54),
  'azadi1g': const Color.fromARGB(255, 255, 205, 54),
  'azadi1': const Color.fromARGB(255, 255, 205, 54),
  'azadi1_2': const Color.fromARGB(255, 255, 205, 54),
  'azadi1_4': const Color.fromARGB(255, 255, 205, 54),
  'mithqal': const Color.fromARGB(255, 172, 146, 79),
  'gol18': const Color.fromARGB(255, 255, 205, 54),
  'ounce': const Color.fromARGB(255, 54, 54, 54),
  'bitcoin': const Color.fromARGB(255, 255, 128, 0),
};


// Function to format numbers with commas and K/M notation
String formatPrice(double price) {
  if (price >= 1000000) {
    return '${(price / 1000000).toStringAsFixed(1)}M';
  } else if (price >= 1000) {
    return '${(price / 1000).toStringAsFixed(1)}K';
  } else {
    return price.toStringAsFixed(2);
  }
}

// Root widget of the application.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sekkeh',
      theme: appThemeData,
      home: SplashScreen(), // Start with SplashScreen
    );
  }
}

// SplashScreen widget
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

// State for SplashScreen
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to HomeScreen after 1.5 seconds
    Timer(Duration(milliseconds: 1500), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // iOS-style loading animation
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

// HomeScreen widget
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// State of the HomeScreen widget.
class _HomeScreenState extends State<HomeScreen> {
  // Map to hold the currency data.
  Map<String, dynamic> currencyData = {};

  // Map to hold the previous currency data for price difference.
  Map<String, dynamic> previousCurrencyData = {};

  // List of currency codes to display.
  List<String> currencyCodes = [];

  // For search functionality
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  // Loading state
  bool isLoading = false;

  // Last refresh time
  DateTime? lastRefreshTime;

  // Fetch data from the APIs.
  Future<void> fetchData() async {
    // Rate-limit refresh to once per minute
    DateTime now = DateTime.now();
    if (lastRefreshTime != null &&
        now.difference(lastRefreshTime!).inSeconds < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please wait a minute before refreshing again.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.grey[800],
        ),
      );
      return;
    }

    lastRefreshTime = now;

    setState(() {
      isLoading = true;
    });

    // Try primary API
    final response =
        await http.get(Uri.parse('https://bonbast.amirhn.com/latest'));

    if (response.statusCode == 200) {
      setState(() {
        previousCurrencyData = Map.from(currencyData);
        currencyData = json.decode(response.body);

        // Remove 'irr' from currencyCodes for Price page
        currencyCodes = currencyData.keys.toList();
        currencyCodes.remove('irr');

        isLoading = false;
      });
    } else {
      // Try backup API
      final backupResponse =
          await http.get(Uri.parse('https://baha24.com/api/v1/price'));

      if (backupResponse.statusCode == 200) {
        setState(() {
          previousCurrencyData = Map.from(currencyData);
          Map<String, dynamic> data = json.decode(backupResponse.body);
          currencyData = {};

          data.forEach((key, value) {
            currencyData[key.toLowerCase()] = {
              'buy': value['buy'],
              'symbol': value['symbol'].toLowerCase(),
            };
          });

          // Remove 'irr' from currencyCodes for Price page
          currencyCodes = currencyData.keys.toList();
          currencyCodes.remove('irr');

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load data from both primary and backup APIs.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.grey[800],
          ),
        );
      }
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // Added AppBar with iOS-style icons
        appBar: AppBar(
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            'سکـه',
            style: TextStyle(
              fontFamily: GoogleFonts.vazirmatn().fontFamily,
              fontWeight: FontWeight.bold,
              
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh), // Use outline-style icon
              onPressed: fetchData,
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white, // Active tab underline color
            tabs: [
              Tab(text: 'Price'),
              Tab(text: 'Convert'),
            ],
          ),
        ),
        body: isLoading && currencyData.isEmpty
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: EdgeInsets.fromLTRB(15, 15, 15, 6),
                    child: TextField(
                      controller: searchController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: ' Chand?!',
                        hintStyle:
                            TextStyle(color: Colors.white60),
                        suffixIcon: Icon(Icons.search_outlined,
                            color: Colors.white60),
                        filled: true,
                        fillColor: Color(0xFF1B1B1B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        PriceTab(
                          currencyData: currencyData,
                          previousCurrencyData: previousCurrencyData,
                          currencyCodes: currencyCodes,
                          searchQuery: searchQuery,
                        ),
                        ConvertTab(currencyData: currencyData),
                      ],
                    ),
                  ),
                ],
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
  final String searchQuery;

  PriceTab({
    required this.currencyData,
    required this.previousCurrencyData,
    required this.currencyCodes,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    List<String> filteredCurrencyCodes = currencyCodes.where((code) {
      String name = currencyNames[code.toLowerCase()]?.toLowerCase() ?? '';
      String symbol = code.toLowerCase();
      return name.contains(searchQuery) || symbol.contains(searchQuery);
    }).toList();

    if (currencyData.isEmpty) {
      return Center(child: CircularProgressIndicator());
    } else {
      return GridView.builder(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16),
        itemCount: filteredCurrencyCodes.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Number of columns
          childAspectRatio: 1.5, // To make cards square
          crossAxisSpacing: 15.0, // Adjust spacing between cards
          mainAxisSpacing: 15.0, // Adjust spacing between cards
        ),
        itemBuilder: (BuildContext context, int index) {
          String code = filteredCurrencyCodes[index];
          Map<String, dynamic> data = currencyData[code];
          if (data['buy'] != null) {
            String name =
                currencyNames[code.toLowerCase()] ?? code.toUpperCase();
            String symbol = currencySymbols[code.toLowerCase()] ?? '';
            double priceValue = data['buy'].toDouble();

            // Format the price
            String price = formatPrice(priceValue);

            // Split price into number and symbol
            RegExp regExp = RegExp(r'([0-9,.]+)([a-zA-Z]*)');
            Match? match = regExp.firstMatch(price);
            String priceNumber = '';
            String priceSymbol = '';
            if (match != null) {
              priceNumber = match.group(1) ?? '';
              priceSymbol = match.group(2) ?? '';
            } else {
              priceNumber = price;
            }

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
                diffColor = diff > 0
                    ? Color.fromARGB(255, 185, 255, 214) // Green
                    : Color.fromARGB(255, 255, 206, 206); // Red
                priceDifference = diffStr;
              }
            }

            // Get background color
            Color bgColor = currencyColors[code.toLowerCase()] ??
                const Color.fromARGB(255, 15, 15, 15);

            // Apply rounded corners
            return Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      bgColor.withOpacity(0.8),
                      Color.fromARGB(255, 0, 0, 0),
                    ],
                    center: Alignment.bottomRight,
                    // focal: Alignment.topLeft,
                    // focalRadius: 1.0,
                    // stops: [0.0, 1.0],
                    // tileMode: TileMode.clamp,
                    radius: 2.1,
                  ),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Stack(
                  children: [
                    // Emoji with reduced size
                    Positioned(
                      top: 14,
                      left: 16,
                      child: Text(
                        symbol,
                        style: TextStyle(
                          fontSize: 21, // Adjust emoji size here
                          fontFamily: 'SpaceMono', // Use Space Mono font
                        ),
                      ),
                    ),
                    // Top right: Currency code and name
                    Positioned(
                      top: 15,
                      right: 15,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: Color.fromARGB(255, 79, 79, 79)
                                  .withOpacity(0.25),
                            ),
                            child: Text(
                              code.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12, // Adjust badge font size here
                                fontFamily: 'SpaceMono', // Use Space Mono font
                              ),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 0,
                              fontFamily: 'varelaRound',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bottom left: Price and price difference
                    Positioned(
                      bottom: 15,
                      left: 15,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price number and symbol
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                priceNumber,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24, // Adjust price font size here
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'varelaRound',
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                priceSymbol,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14, // Adjust symbol font size here
                                  fontFamily: 'varelaRound',
                                ),
                              ),
                            ],
                          ),
                          // Price difference
                          if (priceDifference != '')
                            Text(
                              priceDifference,
                              style: TextStyle(
                                color: diffColor,
                                fontSize: 14,
                              ),
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

    // Format numbers with comma separator
    String formattedAmount = amount % 1 == 0
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
    formattedAmount = formattedAmount.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    String formattedResult = result.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    // Show the result in a Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$formattedAmount $fromName equals $formattedResult $toName',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(180, 30, 30, 30), // Darker Snackbar
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currencyData.isEmpty) {
      return Center(child: CircularProgressIndicator());
    } else {
      List<String> currencyCodes = List<String>.from(widget.currencyData.keys);
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              style: TextStyle(
                color: Colors.white,
                fontFamily: GoogleFonts.varelaRound().fontFamily,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13), // Round corners
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(13), // Round corners
                ),
                prefixIcon:
                    Icon(Icons.numbers_outlined, color: Colors.white), // Outline icon
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                try {
                  amount = double.parse(value);
                } catch (e) {
                  amount = 1.0;
                }
              },
            ),
            SizedBox(height: 18.0),
            DropdownButtonFormField<String>(
              value: fromCurrency,
              dropdownColor: Colors.black,
              decoration: InputDecoration(
                labelText: 'From',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13), // Round corners
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(13), // Round corners
                ),
                prefixIcon:
                    Icon(Icons.arrow_upward_outlined, color: Colors.white), // Outline icon
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
                        style: TextStyle(
                          fontSize: 16, // Smaller emoji size
                          fontFamily:
                              'SpaceMono', // SpaceMono font for symbols
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: GoogleFonts.varelaRound().fontFamily,
                        ),
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
            SizedBox(height: 18.0),
            DropdownButtonFormField<String>(
              value: toCurrency,
              dropdownColor: Colors.black,
              decoration: InputDecoration(
                labelText: 'To',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13), // Round corners
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(13), // Round corners
                ),
                prefixIcon:
                    Icon(Icons.arrow_downward_outlined, color: Colors.white), // Outline icon
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
                        style: TextStyle(
                          fontSize: 16, // Smaller emoji size
                          fontFamily:
                              'SpaceMono', // SpaceMono font for symbols
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: GoogleFonts.varelaRound().fontFamily,
                        ),
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
            SizedBox(height: 39.0),
            SizedBox(
              width: double.infinity, // Make button full width
              height: 52, // Match dropdown height
              child: ElevatedButton(
                onPressed: convertCurrency,
                child: Text(
                  'Convert',
                  style: TextStyle(
                    color: Colors.black, // Black text color
                    fontFamily: GoogleFonts.varelaRound().fontFamily,
                    fontSize: 18,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // White button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Round corners
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
