import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'map.dart';

// Entry point of the application.
void main() {
  runApp(MyApp());
}

// Custom theme data with black and white colors (Update)
final ThemeData appThemeData = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.black,
  scaffoldBackgroundColor: Colors.black,
  hintColor: Colors.white,
  canvasColor: Colors.black,
  fontFamily: 'VarelaRound',
  splashColor: Colors.grey[800],
  highlightColor: Colors.grey[800],
  tabBarTheme: TabBarTheme(
    labelColor: Colors.white,
    unselectedLabelColor: Colors.white60,
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: Colors.white, width: 2),
    ),
    overlayColor: WidgetStateProperty.all(Colors.grey[850]),
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.white, fontFamily: 'VarelaRound'),
    bodyMedium: TextStyle(color: Colors.white, fontFamily: 'VarelaRound'),
    titleLarge: TextStyle(color: Colors.white, fontFamily: 'VarelaRound'),
  ),
);

// Mapping of currency codes to names and colors.
Map<String, String> currencyNamesEn = CurrencyMaps.currencyNamesEn;
Map<String, String> currencyNamesFa = CurrencyMaps.currencyNamesFa;
Map<String, String> currencySymbols = CurrencyMaps.currencySymbols;
Map<String, Color> currencyColors = CurrencyMaps.currencyColors;

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
            // Logo image from assets
            Image.asset(
              'assets/icons/1024-2.png', 
              width: 72,  // Adjust logo width
              height: 72, // Adjust logo height
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.6), // Pushes loading indicator down
            // Smaller loading animation
            SizedBox(
              width: 18,  // Reduced width
              height: 18, // Reduced height
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

// Price Storage Manager
class PriceStorageManager {
  static const String PRICE_KEY = 'last_prices';

  static Future<void> savePrices(Map<String, dynamic> prices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PRICE_KEY, json.encode(prices));
  }

  static Future<Map<String, dynamic>> loadPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final String? priceData = prefs.getString(PRICE_KEY);
    if (priceData != null) {
      return json.decode(priceData);
    }
    return {};
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

  // Loading state
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadPreviousPrices();
    fetchData();
  }

  // Load previous prices using PriceStorageManager
  Future<void> loadPreviousPrices() async {
    previousCurrencyData = await PriceStorageManager.loadPrices();
  }

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
        // Load previous currency data before updating
        await loadPreviousPrices();

        setState(() {
          // Update currencyData with new data
          currencyData = json.decode(response.body);

          // Save new currency data
          PriceStorageManager.savePrices(currencyData);

          // Prepare currency codes list
          currencyCodes = currencyData.keys.toList();
          currencyCodes.remove('irr'); // Remove 'irr' for Price page
          // Note: Do not remove excluded currencies here

          isLoading = false; // Stop loading
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
            backgroundColor: const Color.fromARGB(250, 12, 12, 12),
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
              backgroundColor: const Color.fromARGB(250, 12, 12, 12),
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
              backgroundColor: const Color.fromARGB(250, 12, 12, 12),
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
            backgroundColor: const Color.fromARGB(250, 12, 12, 12),
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
          backgroundColor: const Color.fromARGB(250, 12, 12, 12),
        ),
      );
    }
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
        // AppBar with refresh action and profile icon
        appBar: AppBar(
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            'Keefi', // Application name
            style: TextStyle(
              fontFamily: 'VarelaRound', // Use VarelaRound font
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 15.0, top: 0.5), // Left padding for profile icon
            child: IconButton(
            icon: Icon(
              CupertinoIcons.app_badge,
              size: 21.0, // You can set the size here as well
            ),
              onPressed: () {
                // TODO: Implement profile page navigation
              },
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 15.0, top: 0.5), // Right padding for refresh icon
              child: IconButton(
                icon: Icon(
                  CupertinoIcons.arrow_2_circlepath,
                  size: 21.0,
                  ),
                onPressed: fetchData,
              ),
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
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : TabBarView(
                children: [
                  // Pass a UniqueKey to force rebuild of PriceTab when data changes
                  PriceTab(
                    key: ValueKey(currencyData), // Add this line
                    currencyData: currencyData,
                    previousCurrencyData: previousCurrencyData,
                    currencyCodes: currencyCodes,
                    crossAxisCount: crossAxisCount, searchQuery: '',
                  ),
                  ConvertTab(currencyData: currencyData),
                ],
              ),
      ),
    );
  }
}

// Widget for the 'Price' tab.
class PriceTab extends StatefulWidget {
  final Map<String, dynamic> currencyData;
  final Map<String, dynamic> previousCurrencyData;
  final List<String> currencyCodes;
  final int crossAxisCount;

  PriceTab({
    required this.currencyData,
    required this.previousCurrencyData,
    required this.currencyCodes,
    required this.crossAxisCount, required ValueKey<Map<String, dynamic>> key, required String searchQuery,
  });

  @override
  _PriceTabState createState() => _PriceTabState();
}

class _PriceTabState extends State<PriceTab> {
  // List to keep track of pinned currencies
  List<String> pinnedCurrencies = [];

  // Map to control the opacity of each card for the fade animation
  Map<String, bool> _cardVisibility = {};

  // For search functionality
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  // Scroll controller to monitor scrolling
  final ScrollController _scrollController = ScrollController();

  // Variables to control search bar appearance
  double _searchBarOpacity = 1.0;
  double _searchBarHeight = 90.0; // Adjustable search bar height
  Color _searchBarBackgroundColor = const Color.fromARGB(255, 33, 33, 33)
      .withOpacity(0.5); // Adjustable background color
  Duration _searchBarAnimationDuration =
      Duration(milliseconds: 240); // Adjustable animation duration

  // Variables to control hint text opacity
  double _hintTextOpacity = 1.0; // Control the opacity of hint text

  // Variables to control text alignment and direction
  TextAlign textAlign = TextAlign.left;
  TextDirection textDirection = TextDirection.ltr;

  // Variable to control font family
  String fontFamily = 'VarelaRound'; // Default font

  @override
  void initState() {
    super.initState();
    loadPinnedCurrencies(); // Load pinned currencies on startup
    _scrollController.addListener(_onScroll); // Add scroll listener
  }

  // Function to adjust search bar and hint text opacity and height based on scroll position
  void _onScroll() {
    setState(() {
      if (_scrollController.offset >= 0 && _scrollController.offset <= 50) {
        double scrollRatio = _scrollController.offset / 50;

        // Fade out the hint text earlier
        _hintTextOpacity =
            1.0 - (scrollRatio * 1.5); // Adjust multiplier to control fade speed
        if (_hintTextOpacity < 0.0) _hintTextOpacity = 0.0;

        // Fade out and collapse the search bar
        _searchBarOpacity = 1.0 - scrollRatio;
        _searchBarHeight = 90.0 - (scrollRatio * 90.0); // 90.0 is the initial height

        if (_searchBarOpacity < 0.0) _searchBarOpacity = 0.0;
        if (_searchBarHeight < 0.0) _searchBarHeight = 0.0;
      } else if (_scrollController.offset > 50) {
        // Fully collapsed
        _hintTextOpacity = 0.0;
        _searchBarOpacity = 0.0;
        _searchBarHeight = 0.0;
      } else {
        // Fully expanded
        _hintTextOpacity = 1.0;
        _searchBarOpacity = 1.0;
        _searchBarHeight = 90.0; // Reset to initial height
      }
    });
  }

  // Load pinned currencies from SharedPreferences
  Future<void> loadPinnedCurrencies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      pinnedCurrencies = prefs.getStringList('pinnedCurrencies') ?? [];
      // Initialize the visibility map
      for (var code in pinnedCurrencies) {
        _cardVisibility[code] = true;
      }
    });
  }

  // Save pinned currencies to SharedPreferences
  Future<void> savePinnedCurrencies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('pinnedCurrencies', pinnedCurrencies);
  }

  // Function to pin or unpin a currency with fade animation
  void _togglePinCurrency(String code) {
    HapticFeedback.mediumImpact(); // Medium vibration on long press

    setState(() {
      if (pinnedCurrencies.contains(code)) {
        // Unpin the currency with fade out animation
        _cardVisibility[code] = false;
        Future.delayed(Duration(milliseconds: 300), () {
          setState(() {
            pinnedCurrencies.remove(code);
            _cardVisibility.remove(code);
            savePinnedCurrencies(); // Save the updated list
          });
        });
      } else {
        if (pinnedCurrencies.length >= 6) {
          // Show snackbar if more than 6 currencies are pinned
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You have reached the maximum capacity of pinned cards.',
                style: TextStyle(color: Colors.white), // Set text color to white
              ),
              backgroundColor:
                  Color.fromARGB(250, 12, 12, 12), // Set background color
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Pin the currency with fade in animation
          pinnedCurrencies.add(code);
          _cardVisibility[code] = false;
          savePinnedCurrencies(); // Save the updated list
          // Start fade-in animation
          Future.delayed(Duration(milliseconds: 90), () {
            setState(() {
              _cardVisibility[code] = true;
            });
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter currencies based on search query
    List<String> filteredCurrencyCodes = widget.currencyCodes.where((code) {
      String nameEn = currencyNamesEn[code.toLowerCase()]?.toLowerCase() ?? '';
      String nameFa = currencyNamesFa[code.toLowerCase()]?.toLowerCase() ?? '';
      String symbol = code.toLowerCase();

      bool matchesQuery = nameEn.contains(searchQuery) ||
          nameFa.contains(searchQuery) ||
          symbol.contains(searchQuery);

      if (searchQuery.isEmpty) {
        // If no search query, exclude currencies in excludedCurrencies
        return !excludedCurrencies.contains(code);
      } else {
        // If there's a search query, include all currencies that match
        return matchesQuery;
      }
    }).toList();

    // Separate pinned and unpinned currencies
    List<String> pinnedList = [];
    List<String> unpinnedList = [];

    for (String code in filteredCurrencyCodes) {
      if (pinnedCurrencies.contains(code)) {
        pinnedList.add(code);
      } else {
        unpinnedList.add(code);
      }
    }

    // Final list of currencies, with pinned ones at the top
    List<String> finalCurrencyList = [...pinnedList, ...unpinnedList];

    if (widget.currencyData.isEmpty) {
      return Center(child: CircularProgressIndicator());
    } else {
      return Column(
        children: [
          // Search Bar
          AnimatedContainer(
            duration: _searchBarAnimationDuration, // Adjustable duration
            height: _searchBarHeight,
            curve: Curves.easeOut,
            child: Opacity(
              opacity: _searchBarOpacity,
              child: Container(
                margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  controller: searchController,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: fontFamily, // Use dynamic font family
                  ),
                  decoration: InputDecoration(
                    hintText: 'Chand?!',
                    hintStyle: TextStyle(
                      color: const Color.fromARGB(150, 150, 150, 150)
                          .withOpacity(_hintTextOpacity),
                      fontFamily: fontFamily, // Use dynamic font family
                    ),
                    suffixIcon: Icon(
                      CupertinoIcons.search,
                      color: const Color.fromARGB(150, 150, 150, 150)
                          .withOpacity(_hintTextOpacity),
                    ),
                    filled: true,
                    fillColor: _searchBarBackgroundColor, // Adjustable background color
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 17, vertical: 17),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();

                      // Check if the input is Persian/Farsi
                      RegExp persianRegex = RegExp(r'[\u0600-\u06FF]');
                      if (persianRegex.hasMatch(value)) {
                        // Input contains Persian characters
                        textAlign = TextAlign.right;
                        textDirection = TextDirection.rtl;
                        fontFamily = 'Vazirmatn'; // Use Vazirmatn font
                      } else {
                        // Input does not contain Persian characters
                        textAlign = TextAlign.left;
                        textDirection = TextDirection.ltr;
                        fontFamily = 'VarelaRound'; // Use VarelaRound font
                      }
                    });
                  },
                  cursorColor: Colors.white,
                  textAlign: textAlign,
                  textDirection: textDirection,
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              controller: _scrollController, // Use the scroll controller
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16), // Cards Spacing
              itemCount: finalCurrencyList.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    widget.crossAxisCount, // Number of columns based on device
                childAspectRatio: 1.35,
                crossAxisSpacing: 15.0,
                mainAxisSpacing: 15.0,
              ),
              itemBuilder: (BuildContext context, int index) {
                String code = finalCurrencyList[index];
                Map<String, dynamic> data = widget.currencyData[code];

                // Determine if this card is pinned
                bool isPinned = pinnedCurrencies.contains(code);

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
                  Widget? priceChangeIcon; // Widget to display the price change icon

                  if (widget.previousCurrencyData.isNotEmpty &&
                      widget.previousCurrencyData.containsKey(code)) {
                    double previousPriceValue =
                        widget.previousCurrencyData[code]['buy'].toDouble();
                    double diff = priceValue - previousPriceValue;
                    if (diff != 0) {
                      // Remove '+' and '-' signs
                      String diffStr = formatPrice(diff.abs());
                      diffColor = diff > 0
                          ? Color.fromARGB(239, 167, 255, 204) // Green
                          : Color.fromARGB(242, 255, 192, 192); // Red
                      priceDifference = diffStr;

                      // Set the price change icon
                      if (diff > 0) {
                        priceChangeIcon = Icon(
                          CupertinoIcons.arrow_up_circle,
                          color: Color.fromARGB(239, 167, 255, 204),
                          size: 13.0,
                        );
                      } else if (diff < 0) {
                        priceChangeIcon = Icon(
                          CupertinoIcons.arrow_down_circle,
                          color: Color.fromARGB(242, 255, 192, 192),
                          size: 13.0,
                        );
                      }
                    }
                  }

                  // Get background color
                  Color bgColor = currencyColors[code.toLowerCase()] ??
                      const Color.fromARGB(255, 15, 15, 15);

                  // Use AnimatedOpacity for fade animation
                  return AnimatedOpacity(
                    opacity: _cardVisibility[code] == false ? 0.0 : 1.0,
                    duration: Duration(milliseconds: 300),
                    child: GestureDetector(
                      onLongPress: () => _togglePinCurrency(code),
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
                                  fontSize: 21,
                                  fontFamily: 'SpaceMono',
                                ),
                              ),
                            ),
                            // Top right: Currency code and badges
                            Positioned(
                              top: 15,
                              right: 15,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Pin badge to the left of the currency badge
                                  if (isPinned)
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color.fromARGB(210, 124, 124, 124)
                                            .withOpacity(0.25),
                                      ),
                                      child: Icon(
                                        Icons.star_rounded, // Use the star icon
                                        size: 16,
                                        color: const Color.fromARGB(
                                            200, 255, 255, 255),
                                      ),
                                    ),
                                  if (isPinned)
                                    SizedBox(width: 6), // Spacing between badges
                                  // Currency code badge
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      color: Color.fromARGB(210, 124, 124, 124)
                                          .withOpacity(0.25),
                                    ),
                                    child: Text(
                                      code.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontFamily: 'SpaceMono',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Positioning the price difference above the main price
                            Positioned(
                              bottom: 50, // Adjust as needed
                              left: 15,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Price difference with icon
                                  if (priceDifference != '')
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        if (priceChangeIcon != null) priceChangeIcon,
                                        SizedBox(width: 4),
                                        Text(
                                          priceDifference,
                                          style: TextStyle(
                                            color: diffColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            // Bottom left: Price number and symbol
                            Positioned(
                              bottom: 15,
                              left: 15,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    priceNumber,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'VarelaRound',
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    priceSymbol,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontFamily: 'VarelaRound',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  return Container();
                }
              },
            ),
          ),
        ],
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

    String fromName = currencyNamesEn[fromCurrency.toLowerCase()] ?? fromCurrency.toUpperCase();
    String toName = currencyNamesEn[toCurrency.toLowerCase()] ?? toCurrency.toUpperCase();

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
        backgroundColor: Color.fromARGB(250, 12, 12, 12), // Darker Snackbar
      ),
    );
  }

  // Function to show the currency selection bottom sheet
  void _showCurrencySelectionSheet(bool isFromCurrency) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Make background transparent to see dimmed effect
      isScrollControlled: true,
      builder: (context) {
        return CurrencySelectionSheet(
          currencyData: widget.currencyData,
          isFromCurrency: isFromCurrency,
          onCurrencySelected: (String code) {
            setState(() {
              if (isFromCurrency) {
                fromCurrency = code;
              } else {
                toCurrency = code;
              }
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currencyData.isEmpty) {
      return Center(child: CircularProgressIndicator());
    } else {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Column(
          children: [
            // Amount TextField with numeric keyboard
            TextField(
              controller: amountController,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'VarelaRound',
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
                prefixIcon: Icon(CupertinoIcons.number, color: Colors.white,
                size: 21.0),
              ),
              keyboardType: TextInputType.number, // Use numeric keyboard
              onChanged: (value) {
                try {
                  amount = double.parse(value);
                } catch (e) {
                  amount = 1.0;
                }
              },
            ),
            SizedBox(height: 18.0),
            // From Currency Selection Button
            GestureDetector(
              onTap: () => _showCurrencySelectionSheet(true),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.arrow_up, color: Colors.white,
                    size: 21.0),
                    SizedBox(width: 12.0),
                    Text(
                      currencyNamesEn[fromCurrency.toLowerCase()] ?? fromCurrency.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'VarelaRound',
                        fontSize: 16.0,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      CupertinoIcons.chevron_down, color: Colors.white,
                      size: 14.0,),
                  ],
                ),
              ),
            ),
            SizedBox(height: 18.0),
            // To Currency Selection Button
            GestureDetector(
              onTap: () => _showCurrencySelectionSheet(false),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.arrow_down, color: Colors.white,
                    size: 21.0),
                    SizedBox(width: 12.0),
                    Text(
                      currencyNamesEn[toCurrency.toLowerCase()] ?? toCurrency.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'VarelaRound',
                        fontSize: 16.0,
                      ),
                    ),
                    Spacer(),
                    Icon(CupertinoIcons.chevron_down, color: Colors.white,
                    size: 14.0),
                  ],
                ),
              ),
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
                    fontFamily: 'VarelaRound',
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

// Currency Selection Bottom Sheet Widget
class CurrencySelectionSheet extends StatefulWidget {
  final Map<String, dynamic> currencyData;
  final bool isFromCurrency;
  final Function(String) onCurrencySelected;

  CurrencySelectionSheet({
    required this.currencyData,
    required this.isFromCurrency,
    required this.onCurrencySelected,
  });

  @override
  _CurrencySelectionSheetState createState() => _CurrencySelectionSheetState();
}

class _CurrencySelectionSheetState extends State<CurrencySelectionSheet> {
  TextEditingController searchController = TextEditingController();
  List<String> currencyCodes = [];

  @override
  void initState() {
    super.initState();
    currencyCodes = List<String>.from(widget.currencyData.keys);
  }

  @override
  Widget build(BuildContext context) {
    // Filter currencies based on search query
    String query = searchController.text.toLowerCase();
    List<String> filteredCurrencyCodes = currencyCodes.where((code) {
      String nameEn = currencyNamesEn[code.toLowerCase()]?.toLowerCase() ?? '';
      String nameFa = currencyNamesFa[code.toLowerCase()]?.toLowerCase() ?? '';
      String symbol = code.toLowerCase();
      return nameEn.contains(query) || nameFa.contains(query) || symbol.contains(query);
    }).toList();

    return GestureDetector(
      onTap: () {
        // Close the bottom sheet when tapping outside
        Navigator.of(context).pop();
      },
      child: Container(
        color: Colors.black.withOpacity(0.4), // Dimmed background
        child: GestureDetector(
          onTap: () {}, // Prevent closing when tapping inside
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              // Rounded corners at the top
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(21),
                ),
              ),
              height: MediaQuery.of(context).size.height * 0.7, // 70% height
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 5,
                    margin: EdgeInsets.symmetric(vertical: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Search Field
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: searchController,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'VarelaRound',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black, // Black background for search field
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        prefixIcon: Icon(CupertinoIcons.search, color: Colors.white70,
                        size: 21.0),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  SizedBox(height: 12.0),
                  // Currency List
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCurrencyCodes.length,
                      itemBuilder: (context, index) {
                        String code = filteredCurrencyCodes[index];
                        String nameEn = currencyNamesEn[code.toLowerCase()] ?? code.toUpperCase();
                        // String nameFa = currencyNamesFa[code.toLowerCase()] ?? code.toUpperCase();
                        String symbol = currencySymbols[code.toLowerCase()] ?? '';

                        return ListTile(
                          leading: Text(
                            symbol,
                            style: TextStyle(
                              fontSize: 21,
                              fontFamily: 'SpaceMono',
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            '$nameEn', //$nameEn - $nameFa
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'VarelaRound',
                            ),
                          ),
                          onTap: () {
                            widget.onCurrencySelected(code);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
