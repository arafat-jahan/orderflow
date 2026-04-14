import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';

class InvoiceService {
  static Future<void> generateInvoice({
    required Order order,
    required String currency,
    required String agencyName,
    String? logoPath,
    String? paypalLink,
    String? stripeLink,
    String? bankDetails,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('MMM dd, yyyy').format(now);
    final dueDate = now.add(const Duration(days: 7));
    final deadlineStr = DateFormat('MMM dd, yyyy').format(dueDate);
    final invoiceNo =
        'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    pw.ImageProvider? logoImage;
    if (logoPath != null && logoPath.isNotEmpty) {
      try {
        final bytes = await rootBundle.load(logoPath);
        logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (e) {
        // Fallback to text if image fails to load
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('INVOICE',
                          style: pw.TextStyle(
                              fontSize: 40,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900)),
                      pw.SizedBox(height: 8),
                      pw.Text(invoiceNo,
                          style: const pw.TextStyle(color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          width: 60,
                          height: 60,
                          child: pw.Image(logoImage),
                        )
                      else
                        pw.Text(agencyName.toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Freelance Solutions',
                          style: const pw.TextStyle(color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 60),

              // Billing Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILLED TO',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                      pw.SizedBox(height: 8),
                      pw.Text(order.clientName,
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('DATE ISSUED',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text(dateStr),
                      pw.SizedBox(height: 12),
                      pw.Text('DUE DATE',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text(deadlineStr),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 60),

              // Table Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                        child: pw.Text('DESCRIPTION',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                    pw.Container(
                        width: 100,
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text('AMOUNT',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
              ),

              // Table Item
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(order.title,
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text('Project completed on time with all milestones.',
                              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                    pw.Container(
                      width: 100,
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text('${currency.split(' ').last}${order.price.toInt()}',
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              pw.Divider(color: PdfColors.grey300),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.SizedBox(height: 24),
                      pw.Row(
                        children: [
                          pw.Text('TOTAL DUE',
                              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(width: 40),
                          pw.Text('${currency.split(' ').last}${order.price.toInt()}',
                              style: pw.TextStyle(
                                  fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // Payment Section
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 20),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('PAYMENT INSTRUCTIONS',
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey600)),
                        pw.SizedBox(height: 12),
                        if (stripeLink != null && stripeLink.isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text('Pay via Stripe: $stripeLink',
                                style: const pw.TextStyle(fontSize: 9)),
                          ),
                        if (paypalLink != null && paypalLink.isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text('Pay via PayPal: $paypalLink',
                                style: const pw.TextStyle(fontSize: 9)),
                          ),
                        if (bankDetails != null && bankDetails.isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text('Bank Transfer: $bankDetails',
                                style: const pw.TextStyle(fontSize: 9)),
                          ),
                      ],
                    ),
                  ),
                  if ((paypalLink != null && paypalLink.isNotEmpty) ||
                      (stripeLink != null && stripeLink.isNotEmpty))
                    pw.Column(
                      children: [
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: stripeLink != null && stripeLink.isNotEmpty
                              ? stripeLink
                              : paypalLink!,
                          width: 80,
                          height: 80,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Scan to Pay',
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.grey600)),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Divider(color: PdfColors.grey200),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('Thank you for your business!',
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
