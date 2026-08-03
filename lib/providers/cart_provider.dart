import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../services/db_service.dart';

class CartProvider with ChangeNotifier {
  // Store details
  String _storeName = "SUPER MART";
  String _storeCity = "Rajkot";
  String _storeState = "Gujarat";
  bool _isFirstInstall = true;

  String get storeName => _storeName;
  String get storeCity => _storeCity;
  String get storeState => _storeState;
  String get storeAddress => "$_storeCity, $_storeState";
  bool get isFirstInstall => _isFirstInstall;

  // City and State Dropdown Dataset
  static const Map<String, List<String>> stateCityMap = {
    'Gujarat': ['Rajkot', 'Ahmedabad', 'Surat', 'Vadodara', 'Bhavnagar', 'Jamnagar', 'Junagadh', 'Gandhinagar', 'Anand'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Thane', 'Aurangabad', 'Solapur'],
    'Rajasthan': ['Jaipur', 'Udaipur', 'Jodhpur', 'Kota', 'Ajmer', 'Bikaner'],
    'Delhi': ['New Delhi', 'North Delhi', 'South Delhi', 'East Delhi'],
    'Karnataka': ['Bengaluru', 'Mysuru', 'Hubballi', 'Mangaluru', 'Belagavi'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Agra', 'Varanasi', 'Noida', 'Ghaziabad'],
    'Madhya Pradesh': ['Bhopal', 'Indore', 'Gwalior', 'Jabalpur', 'Ujjain'],
    'Punjab': ['Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala'],
    'West Bengal': ['Kolkata', 'Howrah', 'Durgapur', 'Siliguri'],
  };

  Future<void> loadStoreSettings() async {
    try {
      final sp = await SharedPreferences.getInstance();
      _storeName = sp.getString('storeName') ?? "SUPER MART";
      _storeCity = sp.getString('storeCity') ?? "Rajkot";
      _storeState = sp.getString('storeState') ?? "Gujarat";
      _isFirstInstall = sp.getBool('isFirstInstall') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading store settings: $e");
    }
  }

  Future<void> updateStoreSettings(String name, String city, String state) async {
    _storeName = name.trim().isEmpty ? "SUPER MART" : name.trim();
    _storeCity = city.trim().isEmpty ? "Rajkot" : city.trim();
    _storeState = state.trim().isEmpty ? "Gujarat" : state.trim();
    _isFirstInstall = false;
    notifyListeners();

    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('storeName', _storeName);
      await sp.setString('storeCity', _storeCity);
      await sp.setString('storeState', _storeState);
      await sp.setBool('isFirstInstall', false);
    } catch (e) {
      debugPrint("Error saving store settings: $e");
    }
  }

  Future<void> markFirstInstallDone() async {
    _isFirstInstall = false;
    notifyListeners();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('isFirstInstall', false);
    } catch (e) {
      debugPrint("Error setting first install flag: $e");
    }
  }

  // Customer details
  String _customerName = "Guest Customer";
  String _customerPhone = "";

  String get customerName => _customerName;
  String get customerPhone => _customerPhone;

  void setCustomerInfo(String name, String phone) {
    _customerName = name.trim().isEmpty ? "Guest Customer" : name.trim();
    _customerPhone = phone.trim();
    notifyListeners();
  }

  // Products List
  List<Product> _availableProducts = [];
  final bool _isLoading = false;

  List<Product> get availableProducts => _availableProducts;
  bool get isLoading => _isLoading;

  CartProvider() {
    _availableProducts = List.from(_defaultProducts);
    loadStoreSettings();
    loadProductsFromDb();
  }

  Future<void> loadProductsFromDb() async {
    try {
      final productsFromDb = await DbService.getProducts();
      if (productsFromDb.isNotEmpty) {
        _availableProducts = productsFromDb;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading products from DB: $e");
    }
  }

  final List<Product> _defaultProducts = const [
    Product(
      id: 'p1',
      name: 'Milk',
      price: 35.0,
      unit: 'pack',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF1E88E5),
    ),
    Product(
      id: 'p2',
      name: 'Bread',
      price: 40.0,
      unit: 'pack',
      icon: Icons.bakery_dining_rounded,
      color: Color(0xFFFFB300),
    ),
    Product(
      id: 'p3',
      name: 'Butter',
      price: 60.0,
      unit: 'pack',
      icon: Icons.kitchen_rounded,
      color: Color(0xFFFB8C00),
    ),
    Product(
      id: 'p4',
      name: 'Rice',
      price: 90.0,
      unit: 'kg',
      icon: Icons.rice_bowl_rounded,
      color: Color(0xFF7CB342),
    ),
    Product(
      id: 'p5',
      name: 'Sugar',
      price: 50.0,
      unit: 'kg',
      icon: Icons.grain_rounded,
      color: Color(0xFF00ACC1),
    ),
    Product(
      id: 'p6',
      name: 'Tea',
      price: 120.0,
      unit: 'pack',
      icon: Icons.emoji_food_beverage_rounded,
      color: Color(0xFF8D6E63),
    ),
  ];

  Future<void> addProduct(Product product) async {
    _availableProducts.add(product);
    notifyListeners();
    try {
      await DbService.insertProduct(product);
    } catch (e) {
      debugPrint("Error saving product to DB: $e");
    }
  }

  Future<void> updateProduct(Product updatedProduct) async {
    final index = _availableProducts.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      _availableProducts[index] = updatedProduct;
    }
    if (_cartItems.containsKey(updatedProduct.id)) {
      final currentQty = _cartItems[updatedProduct.id]!.quantity;
      _cartItems[updatedProduct.id] = CartItem(product: updatedProduct, quantity: currentQty);
    }
    notifyListeners();
    try {
      await DbService.insertProduct(updatedProduct);
    } catch (e) {
      debugPrint("Error updating product in DB: $e");
    }
  }

  Future<void> removeProduct(String productId) async {
    _availableProducts.removeWhere((p) => p.id == productId);
    _cartItems.remove(productId);
    notifyListeners();
    try {
      await DbService.deleteProduct(productId);
    } catch (e) {
      debugPrint("Error deleting product from DB: $e");
    }
  }

  // Cart items state (productId -> CartItem)
  final Map<String, CartItem> _cartItems = {};

  List<CartItem> get cartItemsList => _cartItems.values.toList();
  Map<String, CartItem> get cartItems => _cartItems;

  int get totalItemCount {
    int total = 0;
    _cartItems.forEach((_, item) {
      total += item.quantity;
    });
    return total;
  }

  int getQuantity(String productId) {
    if (_cartItems.containsKey(productId)) {
      return _cartItems[productId]!.quantity;
    }
    return 0;
  }

  void addToCart(Product product) {
    if (_cartItems.containsKey(product.id)) {
      _cartItems[product.id]!.quantity += 1;
    } else {
      _cartItems[product.id] = CartItem(product: product, quantity: 1);
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int delta) {
    if (!_cartItems.containsKey(productId)) return;

    final currentQty = _cartItems[productId]!.quantity;
    final newQty = currentQty + delta;

    if (newQty <= 0) {
      _cartItems.remove(productId);
    } else {
      _cartItems[productId]!.quantity = newQty;
    }
    notifyListeners();
  }

  void setQuantity(String productId, int newQty) {
    if (!_cartItems.containsKey(productId)) return;
    if (newQty <= 0) {
      _cartItems.remove(productId);
    } else {
      _cartItems[productId]!.quantity = newQty;
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _customerName = "Guest Customer";
    _customerPhone = "";
    notifyListeners();
  }

  // --- Calculations ---

  /// Calculate Subtotal: Sum of item total prices
  double get subtotal {
    double total = 0.0;
    _cartItems.forEach((_, item) {
      total += item.totalPrice;
    });
    return total;
  }

  /// GST: Fixed 18% of Subtotal
  double get gst {
    return double.parse((subtotal * 0.18).toStringAsFixed(2));
  }

  /// Discount percentage: 10% if subtotal > 1000, otherwise 5%
  int get discountPercent {
    return subtotal > 1000 ? 10 : 5;
  }

  /// Calculate Discount amount based on discount percentage
  double get discount {
    return double.parse((subtotal * (discountPercent / 100.0)).toStringAsFixed(2));
  }

  /// Calculate Grand Total = Subtotal + GST - Discount
  double get grandTotal {
    return double.parse((subtotal + gst - discount).toStringAsFixed(2));
  }
}
