import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';

class CommunicationService {
  /// Generate plain text bill receipt formatted as required
  static String generateReceiptPlainText(CartProvider cart) {
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy hh:mm a').format(now);

    final buffer = StringBuffer();
    buffer.writeln("=========================");
    buffer.writeln("       ${cart.storeName.toUpperCase()}       ");
    buffer.writeln("    ${cart.storeCity}, ${cart.storeState}    ");
    buffer.writeln("=========================");
    buffer.writeln("Date: $formattedDate");
    if (cart.customerName.isNotEmpty && cart.customerName != "Guest Customer") {
      buffer.writeln("Customer: ${cart.customerName}");
    }
    buffer.writeln("-------------------------");

    for (final item in cart.cartItemsList) {
      final name = item.product.name;
      final qty = item.quantity;
      final price = item.product.price.toStringAsFixed(0);
      final total = item.totalPrice.toStringAsFixed(0);
      buffer.writeln("$name   $qty × $price = $total");
    }

    buffer.writeln("-------------------------");
    buffer.writeln("Subtotal       ₹${cart.subtotal.toStringAsFixed(cart.subtotal.truncateToDouble() == cart.subtotal ? 0 : 2)}");
    buffer.writeln("GST (18%)      ₹${cart.gst.toStringAsFixed(2)}");
    buffer.writeln("Discount       ₹${cart.discount.toStringAsFixed(2)}");
    buffer.writeln("-------------------------");
    buffer.writeln("Grand Total    ₹${cart.grandTotal.toStringAsFixed(2)}");
    buffer.writeln("=========================");
    buffer.writeln("Thank You!");
    buffer.writeln("Visit Again 😊");

    return buffer.toString();
  }

  /// Launch WhatsApp with pre-filled receipt to customer phone number
  static Future<bool> sendWhatsAppReceipt({required String phone, required String receiptText}) async {
    try {
      final cleanPhone = _formatPhoneNumber(phone);
      final encodedText = Uri.encodeComponent(receiptText);

      final whatsappUri = Uri.parse("https://wa.me/$cleanPhone?text=$encodedText");
      final whatsappAppUri = Uri.parse("whatsapp://send?phone=$cleanPhone&text=$encodedText");

      if (await canLaunchUrl(whatsappAppUri)) {
        return await launchUrl(whatsappAppUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(whatsappUri)) {
        return await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(whatsappUri, mode: LaunchMode.externalNonBrowserApplication);
      }
    } catch (e) {
      debugPrint("Error launching WhatsApp: $e");
      return false;
    }
  }

  /// Launch SMS app with pre-filled receipt to customer phone number
  static Future<bool> sendSMSReceipt({required String phone, required String receiptText}) async {
    try {
      final cleanPhone = _formatPhoneNumber(phone);
      final encodedText = Uri.encodeComponent(receiptText);

      final smsUri = Uri.parse("sms:$cleanPhone?body=$encodedText");
      final altSmsUri = Uri.parse("sms:$cleanPhone&body=$encodedText");

      if (await canLaunchUrl(smsUri)) {
        return await launchUrl(smsUri);
      } else if (await canLaunchUrl(altSmsUri)) {
        return await launchUrl(altSmsUri);
      } else {
        return await launchUrl(smsUri, mode: LaunchMode.externalNonBrowserApplication);
      }
    } catch (e) {
      debugPrint("Error launching SMS: $e");
      return false;
    }
  }

  static String _formatPhoneNumber(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return "91$digits"; // Default Indian country code +91
    }
    return digits;
  }
}
