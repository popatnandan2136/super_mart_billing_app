import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import '../providers/cart_provider.dart';

class PdfService {
  /// Generate PDF bill byte array
  static Future<Uint8List> generateBillPdf(CartProvider cart) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy  hh:mm a').format(now);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              width: 350,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey700, width: 1.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // --- Header ---
                  pw.Text(
                    "=========================",
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    cart.storeName,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.Text(
                    cart.storeAddress,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "=========================",
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // --- Date & Customer Info ---
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Date:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(formattedDate, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  if (cart.customerName.isNotEmpty && cart.customerName != "Guest Customer")
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("Customer:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          pw.Text(cart.customerName, style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  pw.SizedBox(height: 10),

                  // --- Items List ---
                  pw.Container(
                    child: pw.Column(
                      children: cart.cartItemsList.map((item) {
                        final qtyStr = item.quantity.toString();
                        final unitPriceStr = item.product.price.toStringAsFixed(0);
                        final totalStr = item.totalPrice.toStringAsFixed(0);

                        return pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                flex: 4,
                                child: pw.Text(
                                  item.product.name,
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 4,
                                child: pw.Text(
                                  "$qtyStr x $unitPriceStr",
                                  textAlign: pw.TextAlign.center,
                                  style: const pw.TextStyle(fontSize: 12),
                                ),
                              ),
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  "=  Rs. $totalStr",
                                  textAlign: pw.TextAlign.right,
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  pw.SizedBox(height: 10),
                  pw.Text(
                    "--------------------------------------------------",
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                  pw.SizedBox(height: 6),

                  // --- Subtotal, GST, Discount ---
                  _buildPdfSummaryRow("Subtotal", "Rs. ${cart.subtotal.toStringAsFixed(2)}"),
                  pw.SizedBox(height: 4),
                  _buildPdfSummaryRow("GST (18%)", "Rs. ${cart.gst.toStringAsFixed(2)}"),
                  pw.SizedBox(height: 4),
                  _buildPdfSummaryRow(
                    "Discount (${cart.discountPercent}%)",
                    "- Rs. ${cart.discount.toStringAsFixed(2)}",
                    isDiscount: true,
                  ),

                  pw.SizedBox(height: 6),
                  pw.Text(
                    "--------------------------------------------------",
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                  pw.SizedBox(height: 6),

                  // --- Grand Total ---
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Grand Total",
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        "Rs. ${cart.grandTotal.toStringAsFixed(2)}",
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900,
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 12),
                  pw.Text(
                    "=========================",
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // --- Footer ---
                  pw.Text(
                    "Thank You!",
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "Visit Again :-)",
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfSummaryRow(String label, String value, {bool isDiscount = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 11, color: isDiscount ? PdfColors.red700 : PdfColors.grey800),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: isDiscount ? PdfColors.red700 : PdfColors.black,
          ),
        ),
      ],
    );
  }

  /// Save PDF to device Downloads folder with proper permission handling
  static Future<File?> savePdfToDownloads(CartProvider cart) async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }

      Directory? downloadsDir;
      if (!kIsWeb && Platform.isAndroid) {
        final dir = Directory('/storage/emulated/0/Download');
        if (await dir.exists()) {
          downloadsDir = dir;
        } else {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (!kIsWeb) {
        downloadsDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null) return null;

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = "SuperMart_Bill_$timestamp.pdf";
      final file = File("${downloadsDir.path}/$fileName");

      final pdfBytes = await generateBillPdf(cart);
      await file.writeAsBytes(pdfBytes);
      return file;
    } catch (e) {
      debugPrint("Error saving PDF to Downloads: $e");
      return null;
    }
  }

  /// Open/View local PDF file using OpenFilex
  static Future<void> openPdfFile(String filePath) async {
    try {
      await OpenFilex.open(filePath);
    } catch (e) {
      debugPrint("Error opening file: $e");
    }
  }
}
