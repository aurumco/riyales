import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

// Entry point of the application.
void main() {
  runApp(MyApp());
}

// Custom theme data with black and white colors using custom fonts from assets.
final ThemeData appThemeData = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.black,
  scaffoldBackgroundColor: Colors.black,
  hintColor: Colors.white,
  canvasColor: Colors.black,
  fontFamily: 'Vazirmatn', // Use Vazirmatn font from assets
  tabBarTheme: TabBarTheme(
    labelColor: Colors.white, // Active tab text color
    unselectedLabelColor: Colors.white60, // Inactive tab text color
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: Colors.white, width: 2), // Active tab underline
    ),
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn'),
    bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn'),
    titleLarge: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn'),
  ),
);

// Mapping of currency codes to English names.
Map<String, String> currencyNamesEn = {
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
  'usd': const Color.fromARGB(103, 160, 121, 85),
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

// Mapping of currency codes to Persian names.
Map<String, String> currencyNamesFa = {
  'usd': 'دلار آمریکا',
  'eur': 'یورو',
  'gbp': 'پوند بریتانیا',
  'chf': 'فرانک سوئیس',
  'cad': 'دلار کانادا',
  'aud': 'دلار استرالیا',
  'sek': 'کرون سوئد',
  'nok': 'کرون نروژ',
  'rub': 'روبل روسیه',
  'thb': 'بات تایلند',
  'sgd': 'دلار سنگاپور',
  'hkd': 'دلار هنگ کنگ',
  'azn': 'منات آذربایجان',
  'amd': 'درام ارمنستان',
  'dkk': 'کرون دانمارک',
  'aed': 'درهم امارات',
  'jpy': 'ین ژاپن',
  'try': 'لیر ترکیه',
  'cny': 'یوان چین',
  'sar': 'ریال عربستان',
  'inr': 'روپیه هند',
  'irr': 'تومان ایران',
  'myr': 'رینگیت مالزی',
  'afn': 'افغانی افغانستان',
  'kwd': 'دینار کویت',
  'iqd': 'دینار عراق',
  'bhd': 'دینار بحرین',
  'omr': 'ریال عمان',
  'qar': 'ریال قطر',
  'emami1': 'سکه امامی',
  'azadi1g': 'سکه بهار آزادی گرمی',
  'azadi1': 'سکه تمام بهار آزادی',
  'azadi1_2': 'نیم سکه بهار آزادی',
  'azadi1_4': 'ربع سکه بهار آزادی',
  'mithqal': 'مثقال',
  'gol18': 'طلای ۱۸ عیار',
  'ounce': 'اونس طلا',
  'bitcoin': 'بیت‌کوین',
};


// Function to format numbers with commas and K/M notation.
String formatPrice(double price) {
  if (price >= 1000000) {
    return '${(price / 1000000).toStringAsFixed(1)}M';
  } else if (price >= 1000) {
    return '${(price / 1000).toStringAsFixed(1)}K';
  } else {
    return price.toStringAsFixed(2);
  }
}

// List of currencies to exclude from the main screen.
// You can modify this list to hide currencies you don't want to display.
List<String> excludedCurrencies = ['irr', 'amd']; // Example: ['usd', 'eur']

Future<void> requestInternetPermission() async {
  await Permission.storage.request();
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

    // Navigate to HomeScreen after 2 seconds or when data is fetched.
    Timer(Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Splash screen with logo and loading animation.
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo image from assets.
            Image.asset(
              'assets/icons/1024.png', // Path to your logo image
              width: 200, // Adjust logo size here
              height: 200, // Adjust logo size here
            ),
            SizedBox(height: 20),
            // Loading animation at the bottom.
            SizedBox(
              width: 36, // Loading indicator size less than 40 pixels
              height: 36,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ],
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

  // Fetch data from the API.
  Future<void> fetchData() async {
    // Start loading
    setState(() {
      isLoading = true;
    });

    // Set a timeout for the API request
    try {
      final response = await http
          .get(Uri.parse('https://bonbast.amirhn.com/latest'))
          .timeout(Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('The connection has timed out!');
      });

      if (response.statusCode == 200) {
        setState(() {
          previousCurrencyData = Map.from(currencyData);
          currencyData = json.decode(response.body);

          // Remove 'irr' from currencyCodes for Price page
          currencyCodes = currencyData.keys.toList();
          currencyCodes.remove('irr');

          // Remove excluded currencies
          currencyCodes.removeWhere((code) => excludedCurrencies.contains(code));

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        // Show error message in a Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server is busy, please try again later.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.grey[800],
          ),
        );
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoading = false;
      });
      // Check internet connection
      try {
        final connectivityTest = await http
            .get(Uri.parse('https://www.google.com'))
            .timeout(Duration(seconds: 5));
        if (connectivityTest.statusCode == 200) {
          // Internet is connected, server is busy
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Server is busy, please try again later.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.grey[800],
            ),
          );
        } else {
          // No internet connection
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No internet connection.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.grey[800],
            ),
          );
        }
      } catch (e) {
        // No internet connection
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No internet connection.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.grey[800],
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Show generic error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.grey[800],
        ),
      );
    }
  }

  // Method to save currency data
  Future<void> saveCurrencyData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('currencyData', json.encode(currencyData));
  }

  // Method to load currency data
  Future<void> loadCurrencyData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('currencyData');
    if (data != null) {
      setState(() {
        currencyData = json.decode(data);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadCurrencyData(); // Load previous data on startup
    fetchData();
  }

  // Build the application.
  @override
  Widget build(BuildContext context) {
    // Determine number of columns based on screen width
    int crossAxisCount = 2; // Default for mobile
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 1200) {
      crossAxisCount = 4; // Desktop
    } else if (screenWidth >= 800) {
      crossAxisCount = 3; // Tablet
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // Added AppBar with iOS-style icons
        appBar: AppBar(
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            'سکـه', // Application name in Persian
            style: TextStyle(
              fontFamily: 'Vazirmatn', // Use Vazirmatn font
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
                        hintStyle: TextStyle(color: Colors.white60),
                        suffixIcon:
                            Icon(Icons.search_outlined, color: Colors.white60),
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
                          crossAxisCount: crossAxisCount, // Pass the crossAxisCount
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
  final int crossAxisCount;

  PriceTab({
    required this.currencyData,
    required this.previousCurrencyData,
    required this.currencyCodes,
    required this.searchQuery,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    List<String> filteredCurrencyCodes = currencyCodes.where((code) {
      String nameEn =
          currencyNamesEn[code.toLowerCase()]?.toLowerCase() ?? '';
      String nameFa =
          currencyNamesFa[code.toLowerCase()]?.toLowerCase() ?? '';
      String symbol = code.toLowerCase();
      return nameEn.contains(searchQuery) ||
          nameFa.contains(searchQuery) ||
          symbol.contains(searchQuery);
    }).toList();

    if (currencyData.isEmpty) {
      return Center(child: CircularProgressIndicator());
    } else {
      return GridView.builder(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16),
        itemCount: filteredCurrencyCodes.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount, // Number of columns based on device
          childAspectRatio: 1.5, // To make cards square
          crossAxisSpacing: 15.0, // Adjust spacing between cards
          mainAxisSpacing: 15.0, // Adjust spacing between cards
        ),
        itemBuilder: (BuildContext context, int index) {
          String code = filteredCurrencyCodes[index];
          Map<String, dynamic> data = currencyData[code];
          if (data['buy'] != null) {
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
                          fontFamily: 'SpaceMono', // Use SpaceMono font
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
                                fontSize:
                                    12, // Adjust badge font size here
                                fontFamily:
                                    'SpaceMono', // Use Space Mono font
                              ),
                            ),
                          ),
                          SizedBox(height: 6),
                          // Display currency name in English and Persian
                          Text(
                            '${currencyNamesEn[code.toLowerCase()] ?? ''} / ${currencyNamesFa[code.toLowerCase()] ?? ''}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 0,
                              fontFamily: 'Vazirmatn',
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
                            crossAxisAlignment:
                                CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                priceNumber,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      24, // Adjust price font size here
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'VarelaRound',
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                priceSymbol,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize:
                                      14, // Adjust symbol font size here
                                  fontFamily: 'VarelaRound',
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
        currencyNamesEn[fromCurrency.toLowerCase()] ?? fromCurrency.toUpperCase();
    String toName =
        currencyNamesEn[toCurrency.toLowerCase()] ?? toCurrency.toUpperCase();

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
      List<String> currencyCodes =
          List<String>.from(widget.currencyData.keys);

      return Padding(
        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Vazirmatn',
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
                prefixIcon: Icon(Icons.arrow_upward_outlined,
                    color: Colors.white), // Outline icon
              ),
              items: currencyCodes.map((String code) {
                String name =
                    currencyNamesEn[code.toLowerCase()] ?? code.toUpperCase();
                String symbol = currencySymbols[code.toLowerCase()] ?? '';
                return DropdownMenuItem<String>(
                  value: code,
                  child: Row(
                    children: [
                      Text(
                        symbol,
                        style: TextStyle(
                          fontSize: 16, // Smaller emoji size
                          fontFamily: 'SpaceMono', // SpaceMono font for symbols
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Vazirmatn',
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
                prefixIcon: Icon(Icons.arrow_downward_outlined,
                    color: Colors.white), // Outline icon
              ),
              items: currencyCodes.map((String code) {
                String name =
                    currencyNamesEn[code.toLowerCase()] ?? code.toUpperCase();
                String symbol = currencySymbols[code.toLowerCase()] ?? '';
                return DropdownMenuItem<String>(
                  value: code,
                  child: Row(
                    children: [
                      Text(
                        symbol,
                        style: TextStyle(
                          fontSize: 16, // Smaller emoji size
                          fontFamily: 'SpaceMono', // SpaceMono font for symbols
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Vazirmatn',
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
                    fontFamily: 'Vazirmatn',
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
