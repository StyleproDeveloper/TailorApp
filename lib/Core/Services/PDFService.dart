import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PDFService {
  // Helper to format currency with rupee symbol
  // Note: Default PDF fonts may not support ₹ symbol, so we use "Rs." which is universally supported
  // To use ₹ symbol, you would need to load a custom font (like Roboto) that supports it
  static String _formatCurrency(double amount, {bool showDecimals = false}) {
    final formatted = showDecimals 
        ? NumberFormat('#,##0.00').format(amount)
        : NumberFormat('#,##0').format(amount);
    // Using "Rs." prefix which is supported by all PDF fonts
    // This ensures proper display across all PDF viewers
    return 'Rs. $formatted';
  }

  /// Generate and print/share order invoice PDF
  static Future<void> generateOrderInvoice({
    required Map<String, dynamic> order,
    required Map<String, dynamic> shopInfo,
    required Map<int, String> dressTypeNames,
    String? billingTerms,
    List<dynamic>? paymentHistory,
  }) async {
    try {
      // Create PDF document with Unicode support
      final pdf = pw.Document();

      // Calculate totals
      final items = order['items'] as List<dynamic>? ?? [];
      double itemsTotal = 0.0;
      for (var item in items) {
        final amount = (item['amount'] ?? 0).toDouble();
        itemsTotal += amount;
      }

      final additionalCosts = order['additionalCosts'] as List<dynamic>? ?? [];
      double additionalCostsTotal = 0.0;
      for (var cost in additionalCosts) {
        final amount = (cost['additionalCost'] ?? 0).toDouble();
        additionalCostsTotal += amount;
      }

      double subtotalValue = itemsTotal + additionalCostsTotal;
      if (additionalCostsTotal == 0.0 && 
          order['estimationCost'] != null && 
          itemsTotal > 0.0) {
        final estimationCost = (order['estimationCost'] ?? 0).toDouble();
        if (estimationCost > itemsTotal) {
          subtotalValue = estimationCost;
        } else {
          subtotalValue = itemsTotal;
        }
      } else if (subtotalValue == 0.0 && order['estimationCost'] != null) {
        subtotalValue = (order['estimationCost'] ?? 0).toDouble();
      }

      // Apply discount to subtotal
      final discountAmount = (order['discount'] ?? 0).toDouble();
      final subtotalAfterDiscount = (subtotalValue - discountAmount).clamp(0.0, double.infinity);

      final courierCharge = (order['courierCharge'] ?? 0).toDouble();
      // Calculate GST on discounted subtotal (18%)
      final gstAmount = order['gst'] == true ? (subtotalAfterDiscount * 0.18) : 0.0;
      final advanceReceived = (order['advancereceived'] ?? 0).toDouble();
      // Final total: discounted subtotal + courier + GST
      final total = subtotalAfterDiscount + courierCharge + gstAmount;
      // Use paidAmount which includes advance + all payments
      final totalPaid = (order['paidAmount'] ?? 0).toDouble();
      final balance = total - totalPaid;

      // Format dates
      final orderDate = order['createdAt'] != null
          ? DateFormat('MMM dd, yyyy').format(DateTime.parse(order['createdAt']))
          : 'N/A';
      
      String deliveryDate = 'Not Set';
      if (order['deliveryDate'] != null && order['deliveryDate'].toString().isNotEmpty) {
        try {
          deliveryDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(order['deliveryDate']));
        } catch (e) {
          deliveryDate = order['deliveryDate'].toString();
        }
      }

      final advanceReceivedDateStr = order['advanceReceivedDate']?.toString() ?? '';
      final advanceReceivedDate = advanceReceivedDateStr.trim().isNotEmpty
          ? DateFormat('MMM dd, yyyy').format(DateTime.parse(advanceReceivedDateStr))
          : 'Not Received';

      // Get stitching type
      String stitchingType = 'Stitching';
      final stitchingTypeValue = order['stitchingType'];
      if (stitchingTypeValue == 1) {
        stitchingType = 'Stitching';
      } else if (stitchingTypeValue == 2) {
        stitchingType = 'Alter';
      } else if (stitchingTypeValue == 3) {
        stitchingType = 'Material';
      }

      // Build shop address
      final shopAddress = _buildAddress(
        addressLine1: shopInfo['addressLine1'],
        street: shopInfo['street'],
        city: shopInfo['city'],
        state: shopInfo['state'],
        postalCode: shopInfo['postalCode'],
      );

      // Build customer address (if available)
      final customerAddress = _buildAddress(
        addressLine1: order['customer_addressLine1'],
        street: order['customer_street'],
        city: order['customer_city'],
        state: order['customer_state'],
        postalCode: order['customer_postalCode'],
      );

      // Add PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              _buildHeader(shopInfo, order['orderId']),
              pw.SizedBox(height: 20),

              // Order and Customer Info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Shop Info (Left)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'From:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          shopInfo['shopName']?.toString() ?? 'Shop Name',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (shopAddress.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            shopAddress,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                        if (shopInfo['mobile'] != null) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Phone: ${shopInfo['mobile']}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                        if (shopInfo['email'] != null) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Email: ${shopInfo['email']}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 40),
                  // Customer Info (Right)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Bill To:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          order['customer_name']?.toString() ?? 'Customer Name',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (customerAddress.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            customerAddress,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                        if (order['customer_mobile'] != null) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Phone: ${order['customer_mobile']}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Items Table
              _buildItemsTable(items, dressTypeNames),
              pw.SizedBox(height: 10),

              // Additional Costs
              if (additionalCosts.isNotEmpty) ...[
                _buildAdditionalCostsTable(additionalCosts),
                pw.SizedBox(height: 10),
              ],

              // Summary Section
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 250,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildSummaryRow('Subtotal:', subtotalValue),
                      if (discountAmount > 0) ...[
                        _buildSummaryRow('Discount:', -discountAmount, color: PdfColors.red),
                        _buildSummaryRow('Subtotal After Discount:', subtotalAfterDiscount),
                      ],
                      if (courierCharge > 0)
                        _buildSummaryRow('Courier Charge:', courierCharge),
                      if (gstAmount > 0)
                        _buildSummaryRow('GST (18%):', gstAmount),
                      pw.Divider(),
                      _buildSummaryRow('Total:', total, isBold: true),
                      pw.SizedBox(height: 8),
                      _buildSummaryRow('Total Paid:', totalPaid, isBold: true),
                      pw.Divider(),
                      _buildSummaryRow(
                        'Balance Due:',
                        balance,
                        isBold: true,
                        color: balance > 0 ? PdfColors.red : PdfColors.green,
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Payment History Section (show if there are payments or advance received)
              if ((paymentHistory != null && paymentHistory.isNotEmpty) || advanceReceived > 0) ...[
                _buildPaymentHistoryTable(
                  paymentHistory ?? [],
                  advanceReceived,
                  advanceReceivedDate,
                ),
                pw.SizedBox(height: 20),
              ],

              // Terms and Conditions (if billing terms are provided)
              if (billingTerms != null && billingTerms.isNotEmpty) ...[
                _buildTermsAndConditions(billingTerms),
                pw.SizedBox(height: 20),
              ],

              // Footer
              _buildFooter(shopInfo),
            ];
          },
        ),
      );

      // Print or share PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      throw Exception('Error generating PDF: $e');
    }
  }

  static pw.Widget _buildHeader(Map<String, dynamic> shopInfo, dynamic orderId) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              shopInfo['shopName']?.toString() ?? 'Style Pros',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            if (shopInfo['yourName'] != null) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                shopInfo['yourName'].toString(),
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
            ],
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Order #ORD${orderId?.toString().padLeft(3, '0') ?? '000'}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(List<dynamic> items, Map<int, String> dressTypeNames) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Item #', isHeader: true),
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Delivery Date', isHeader: true),
            _buildTableCell('Amount', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        // Items
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value as Map<String, dynamic>;
          final dressTypeId = item['dressTypeId'];
          final dressTypeName = dressTypeNames[dressTypeId] ?? 'Dress Type $dressTypeId';
          
          String deliveryDate = 'Not Set';
          if (item['delivery_date'] != null && item['delivery_date'].toString().isNotEmpty) {
            try {
              deliveryDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(item['delivery_date']));
            } catch (e) {
              deliveryDate = item['delivery_date'].toString();
            }
          }

          final amount = (item['amount'] ?? 0).toDouble();
          final specialInstructions = item['special_instructions']?.toString() ?? '';

          return pw.TableRow(
            children: [
              _buildTableCell('${index + 1}'),
              _buildTableCell(
                '$dressTypeName${specialInstructions.isNotEmpty ? '\n$specialInstructions' : ''}',
              ),
              _buildTableCell(deliveryDate),
              _buildTableCell(
                _formatCurrency(amount),
                align: pw.TextAlign.right,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildAdditionalCostsTable(List<dynamic> additionalCosts) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Additional Costs', isHeader: true),
            _buildTableCell('Amount', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        // Items
        ...additionalCosts.map((cost) {
          final description = cost['additionalCostName']?.toString() ?? 'Additional Cost';
          final amount = (cost['additionalCost'] ?? 0).toDouble();

          return pw.TableRow(
            children: [
              _buildTableCell(description),
              _buildTableCell(
                _formatCurrency(amount),
                align: pw.TextAlign.right,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    double fontSize = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          // Use default font which should support Unicode
          // If rupee symbol doesn't render, consider loading a custom font
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, {double fontSize = 10, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            _formatCurrency(amount, showDecimals: true),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTermsAndConditions(String terms) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Terms and Conditions',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            terms,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.left,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(Map<String, dynamic> shopInfo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          if (shopInfo['mobile'] != null || shopInfo['email'] != null)
            pw.Text(
              [
                if (shopInfo['mobile'] != null) 'Phone: ${shopInfo['mobile']}',
                if (shopInfo['email'] != null) 'Email: ${shopInfo['email']}',
              ].join(' | '),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          pw.SizedBox(height: 4),
          pw.Text(
            'This is a computer-generated invoice.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static String _buildAddress({
    dynamic addressLine1,
    dynamic street,
    dynamic city,
    dynamic state,
    dynamic postalCode,
  }) {
    final parts = <String>[];
    if (addressLine1 != null && addressLine1.toString().isNotEmpty) {
      parts.add(addressLine1.toString());
    }
    if (street != null && street.toString().isNotEmpty) {
      parts.add(street.toString());
    }
    if (city != null && city.toString().isNotEmpty) {
      parts.add(city.toString());
    }
    if (state != null && state.toString().isNotEmpty) {
      parts.add(state.toString());
    }
    if (postalCode != null && postalCode.toString().isNotEmpty) {
      parts.add(postalCode.toString());
    }
    return parts.join(', ');
  }

  static pw.Widget _buildPaymentHistoryTable(
    List<dynamic> payments,
    double advanceReceived,
    String advanceReceivedDate,
  ) {
    final allPayments = <Map<String, dynamic>>[];

    // Add advance payment if exists
    if (advanceReceived > 0) {
      allPayments.add({
        'type': 'Advance Payment',
        'amount': advanceReceived,
        'date': advanceReceivedDate,
        'notes': null,
      });
    }

    // Add all other payments
    for (var payment in payments) {
      final paymentType = payment['paymentType'] ?? 'partial';
      String typeLabel = 'Payment';
      switch (paymentType) {
        case 'advance':
          typeLabel = 'Advance Payment';
          break;
        case 'partial':
          typeLabel = 'Partial Payment';
          break;
        case 'final':
          typeLabel = 'Final Payment';
          break;
        case 'other':
          typeLabel = 'Other Payment';
          break;
      }

      String paymentDate = 'N/A';
      if (payment['paymentDate'] != null && payment['paymentDate'].toString().isNotEmpty) {
        try {
          paymentDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(payment['paymentDate']));
        } catch (e) {
          paymentDate = payment['paymentDate'].toString();
        }
      }

      allPayments.add({
        'type': typeLabel,
        'amount': (payment['paidAmount'] ?? 0).toDouble(),
        'date': paymentDate,
        'notes': payment['notes']?.toString(),
      });
    }

    if (allPayments.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Payment History',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Payment Type', isHeader: true),
                  _buildTableCell('Date', isHeader: true),
                  _buildTableCell('Amount', isHeader: true, align: pw.TextAlign.right),
                ],
              ),
              // Payment rows
              ...allPayments.map((payment) {
                return pw.TableRow(
                  children: [
                    _buildTableCell(
                      payment['type'] as String,
                      fontSize: 9,
                    ),
                    _buildTableCell(
                      payment['date'] as String,
                      fontSize: 9,
                    ),
                    _buildTableCell(
                      _formatCurrency(payment['amount'] as double),
                      align: pw.TextAlign.right,
                      fontSize: 9,
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
          // Notes section if any payment has notes
          if (allPayments.any((p) => p['notes'] != null && (p['notes'] as String).isNotEmpty)) ...[
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 8),
            ...allPayments.where((p) => p['notes'] != null && (p['notes'] as String).isNotEmpty).map((payment) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${payment['type']}: ',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        payment['notes'] as String,
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}

