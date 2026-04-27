import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/fcfa_formatter.dart';
import '../domain/product_model.dart';

class QrLabelScreen extends StatefulWidget {
  const QrLabelScreen({super.key, required this.product});

  final ProductModel product;

  @override
  State<QrLabelScreen> createState() => _QrLabelScreenState();
}

class _QrLabelScreenState extends State<QrLabelScreen> {
  bool _isPrinting = false;

  Future<void> _sharePdf() async {
    setState(() => _isPrinting = true);
    try {
      final pdfBytes = await _buildPdf();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
            '${widget.product.name.replaceAll(' ', '_')}_label.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<Uint8List> _buildPdf() async {
    final doc = pw.Document();
    final qrImageBytes = await _buildQrImageBytes();

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
            58 * PdfPageFormat.mm, 40 * PdfPageFormat.mm),
        margin: const pw.EdgeInsets.all(4 * PdfPageFormat.mm),
        build: (_) => pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              widget.product.name,
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
              maxLines: 2,
            ),
            pw.SizedBox(height: 2 * PdfPageFormat.mm),
            pw.Text(
              formatFCFA(widget.product.price),
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2 * PdfPageFormat.mm),
            pw.Image(
              pw.MemoryImage(qrImageBytes),
              width: 25 * PdfPageFormat.mm,
              height: 25 * PdfPageFormat.mm,
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  Future<Uint8List> _buildQrImageBytes() async {
    final painter = QrPainter(
      data: widget.product.id,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
    final imageData = await painter.toImageData(300);
    return imageData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Étiquette QR')),
      body: Padding(
        padding: const EdgeInsets.all(AkomSpacing.lg),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AkomSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.product.name,
                          style: AkomTextStyles.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AkomSpacing.sm),
                        Text(
                          formatFCFA(widget.product.price),
                          style: AkomTextStyles.priceLarge,
                        ),
                        const SizedBox(height: AkomSpacing.lg),
                        QrImageView(
                          data: widget.product.id,
                          version: QrVersions.auto,
                          size: 200,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        ),
                        const SizedBox(height: AkomSpacing.md),
                        Text(
                          'ID: ${widget.product.id.substring(0, 8)}…',
                          style: AkomTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AkomSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isPrinting ? null : _sharePdf,
                icon: _isPrinting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.print_outlined),
                label: Text(_isPrinting
                    ? 'Génération…'
                    : 'Imprimer / Partager le PDF'),
              ),
            ),
            const SizedBox(height: AkomSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Terminer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
