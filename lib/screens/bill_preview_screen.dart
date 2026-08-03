import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';
import '../services/pdf_service.dart';
import '../services/communication_service.dart';

class BillPreviewScreen extends StatefulWidget {
  const BillPreviewScreen({super.key});

  @override
  State<BillPreviewScreen> createState() => _BillPreviewScreenState();
}

class _BillPreviewScreenState extends State<BillPreviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleDownloadPdf(CartProvider cart) async {
    setState(() {
      _isDownloading = true;
    });

    final file = await PdfService.savePdfToDownloads(cart);

    setState(() {
      _isDownloading = false;
    });

    if (!mounted) return;

    if (file != null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF1E293B),
          content: Column(
            mainAxisSize: pwMainAxisSizeMin(context),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF0F9D58), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "PDF saved to Downloads folder!",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // View Option
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      PdfService.openPdfFile(file.path);
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.lightGreenAccent),
                    label: const Text("VIEW", style: TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold)),
                  ),
                  // Print Option
                  TextButton.icon(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      await Printing.layoutPdf(
                        onLayout: (format) => PdfService.generateBillPdf(cart),
                      );
                    },
                    icon: const Icon(Icons.print_rounded, size: 16, color: Colors.cyanAccent),
                    label: const Text("PRINT", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  ),
                  // Share Option
                  TextButton.icon(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      final pdfBytes = await PdfService.generateBillPdf(cart);
                      await Printing.sharePdf(
                        bytes: pdfBytes,
                        filename: 'SuperMart_Bill.pdf',
                      );
                    },
                    icon: const Icon(Icons.share_rounded, size: 16, color: Colors.orangeAccent),
                    label: const Text("SHARE", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to save PDF. Please check storage permissions."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _handleSendReceipt(BuildContext context, CartProvider cart, {required bool isWhatsApp}) async {
    String phone = cart.customerPhone;

    if (phone.isEmpty) {
      final phoneController = TextEditingController();
      final enteredPhone = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isWhatsApp ? "Send via WhatsApp" : "Send via SMS"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter customer's mobile number to send receipt:"),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Mobile Number",
                  hintText: "e.g. 9876543210",
                  prefixIcon: const Icon(Icons.phone_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx, phoneController.text.trim());
              },
              child: const Text("Send"),
            ),
          ],
        ),
      );

      if (enteredPhone == null || enteredPhone.isEmpty) return;
      phone = enteredPhone;
    }

    final receiptText = CommunicationService.generateReceiptPlainText(cart);

    if (isWhatsApp) {
      final success = await CommunicationService.sendWhatsAppReceipt(phone: phone, receiptText: receiptText);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch WhatsApp. Please check if WhatsApp is installed.")),
        );
      }
    } else {
      final success = await CommunicationService.sendSMSReceipt(phone: phone, receiptText: receiptText);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch SMS app.")),
        );
      }
    }
  }

  MainAxisSize pwMainAxisSizeMin(BuildContext context) => MainAxisSize.min;

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy  hh:mm a').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bill Preview & Print"),
        actions: [
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            tooltip: "Download PDF to Device",
            onPressed: _isDownloading ? null : () => _handleDownloadPdf(cart),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long_rounded), text: "Receipt View"),
            Tab(icon: Icon(Icons.picture_as_pdf_rounded), text: "PDF Document"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- Tab 1: Receipt Card View ---
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 360,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Store Header
                        const Text(
                          "=========================",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cart.storeName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Color(0xFF0F9D58),
                          ),
                        ),
                        Text(
                          cart.storeAddress,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "=========================",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),

                        // Date & Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Date:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(formattedDate, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                          ],
                        ),
                        if (cart.customerName.isNotEmpty && cart.customerName != "Guest Customer") ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Customer:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(cart.customerName, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Products Table
                        Column(
                          children: cart.cartItemsList.map((item) {
                            final qtyStr = item.quantity.toString();
                            final unitPriceStr = item.product.price.toStringAsFixed(0);
                            final totalStr = item.totalPrice.toStringAsFixed(0);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      "$qtyStr × $unitPriceStr",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "= $totalStr",
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          "-------------------------",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'monospace', color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 8),

                        // Subtotal
                        _buildReceiptRow("Subtotal", "₹${cart.subtotal.toStringAsFixed(cart.subtotal.truncateToDouble() == cart.subtotal ? 0 : 2)}"),
                        const SizedBox(height: 6),

                        // GST
                        _buildReceiptRow("GST (18%)", "₹${cart.gst.toStringAsFixed(2)}"),
                        const SizedBox(height: 6),

                        // Discount
                        _buildReceiptRow("Discount", "₹${cart.discount.toStringAsFixed(2)}"),

                        const SizedBox(height: 8),
                        const Text(
                          "-------------------------",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'monospace', color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 8),

                        // Grand Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Grand Total",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              "₹${cart.grandTotal.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: Color(0xFF0F9D58),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Footer
                        const Text(
                          "Thank You!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F9D58),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Visit Again 😊",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // --- Tab 2: Live PDF Preview ---
          PdfPreview(
            build: (format) => PdfService.generateBillPdf(cart),
            canChangeOrientation: false,
            canChangePageFormat: false,
            allowPrinting: true,
            allowSharing: true,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Messaging Row: WhatsApp & SMS Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleSendReceipt(context, cart, isWhatsApp: true),
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: const Text("WhatsApp Receipt", style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleSendReceipt(context, cart, isWhatsApp: false),
                      icon: const Icon(Icons.sms_rounded, size: 18),
                      label: const Text("SMS Receipt", style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0288D1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Document Actions Row: Download, Share, Print
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isDownloading ? null : () => _handleDownloadPdf(cart),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text("Download PDF", style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final pdfBytes = await PdfService.generateBillPdf(cart);
                        await Printing.sharePdf(
                          bytes: pdfBytes,
                          filename: 'SuperMart_Bill.pdf',
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text("Share PDF", style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Printing.layoutPdf(
                          onLayout: (format) => PdfService.generateBillPdf(cart),
                        );
                      },
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text("Print Bill", style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
