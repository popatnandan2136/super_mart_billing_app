import 'package:flutter_test/flutter_test.dart';
import 'package:super_mart_billing_app/providers/cart_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CartProvider Calculation Tests', () {
    late CartProvider cart;

    setUp(() {
      cart = CartProvider();
    });

    test('Initial cart is empty', () {
      expect(cart.cartItemsList.length, 0);
      expect(cart.totalItemCount, 0);
      expect(cart.subtotal, 0.0);
      expect(cart.gst, 0.0);
      expect(cart.discount, 0.0);
      expect(cart.grandTotal, 0.0);
    });

    test('Add items and verify Subtotal, GST 18%, 5% Discount, and Grand Total', () {
      // Milk (₹35 x 2 = ₹70)
      // Bread (₹40 x 1 = ₹40)
      // Butter (₹60 x 3 = ₹180)
      final milk = cart.availableProducts.firstWhere((p) => p.name == 'Milk');
      final bread = cart.availableProducts.firstWhere((p) => p.name == 'Bread');
      final butter = cart.availableProducts.firstWhere((p) => p.name == 'Butter');

      cart.addToCart(milk);
      cart.addToCart(milk); // 2 Milk
      cart.addToCart(bread); // 1 Bread
      cart.addToCart(butter);
      cart.addToCart(butter);
      cart.addToCart(butter); // 3 Butter

      expect(cart.totalItemCount, 6);
      expect(cart.subtotal, 290.0); // 70 + 40 + 180 = 290
      expect(cart.gst, 52.20); // 18% of 290 = 52.20
      expect(cart.discountPercent, 5); // <= 1000 => 5%
      expect(cart.discount, 14.50); // 5% of 290 = 14.50
      expect(cart.grandTotal, 327.70); // 290 + 52.20 - 14.50 = 327.70
    });

    test('Verify 10% Discount when subtotal > ₹1000', () {
      final tea = cart.availableProducts.firstWhere((p) => p.name == 'Tea'); // ₹120

      // Add 10 Teas = ₹1200 subtotal
      for (int i = 0; i < 10; i++) {
        cart.addToCart(tea);
      }

      expect(cart.subtotal, 1200.0);
      expect(cart.discountPercent, 10); // > 1000 => 10%
      expect(cart.discount, 120.0); // 10% of 1200 = 120.0
      expect(cart.gst, 216.0); // 18% of 1200 = 216.0
      expect(cart.grandTotal, 1200.0 + 216.0 - 120.0); // 1296.0
    });

    test('Update item quantity and remove item', () {
      final rice = cart.availableProducts.firstWhere((p) => p.name == 'Rice'); // ₹90
      cart.addToCart(rice);
      expect(cart.getQuantity(rice.id), 1);

      cart.updateQuantity(rice.id, 2); // Qty becomes 3
      expect(cart.getQuantity(rice.id), 3);
      expect(cart.subtotal, 270.0);

      cart.removeFromCart(rice.id);
      expect(cart.getQuantity(rice.id), 0);
      expect(cart.subtotal, 0.0);
    });
  });
}
