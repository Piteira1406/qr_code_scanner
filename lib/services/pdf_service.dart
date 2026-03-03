import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

/// Service for generating PDF attendance sheets.
class PdfService {
  /// Generate and display/print an attendance PDF for an event.
  static Future<void> generateAttendancePdf({
    required Event event,
    required List<Map<String, dynamic>> checkIns,
    required String professorName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(event, professorName),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummary(event, checkIns),
          pw.SizedBox(height: 20),
          _buildAttendanceTable(checkIns),
          pw.SizedBox(height: 30),
          _buildSignatureSection(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Folha_Presencas_${event.name.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildHeader(Event event, String professorName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ISTEC',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.Text(
                  'Sistema de Check-in Digital',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'FOLHA DE PRESENÇAS',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _formatDate(DateTime.now()),
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.blue900, thickness: 2),
        pw.SizedBox(height: 15),
        // Event info
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Evento:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          event.name,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Docente:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          professorName,
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Local:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          event.location,
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Data/Hora:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          '${_formatDateTime(event.startTime)} - ${_formatTime(event.endTime)}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 15),
      ],
    );
  }

  static pw.Widget _buildSummary(
    Event event,
    List<Map<String, dynamic>> checkIns,
  ) {
    final approved = checkIns.where((c) {
      final checkIn = c['checkIn'] as CheckIn;
      return checkIn.status == CheckInStatus.approved;
    }).length;

    final pending = checkIns.where((c) {
      final checkIn = c['checkIn'] as CheckIn;
      return checkIn.status == CheckInStatus.pending;
    }).length;

    final rejected = checkIns.where((c) {
      final checkIn = c['checkIn'] as CheckIn;
      return checkIn.status == CheckInStatus.rejected;
    }).length;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryBox('Total', checkIns.length, PdfColors.blue),
        _buildSummaryBox('Aprovados', approved, PdfColors.green),
        _buildSummaryBox('Pendentes', pending, PdfColors.orange),
        _buildSummaryBox('Rejeitados', rejected, PdfColors.red),
      ],
    );
  }

  static pw.Widget _buildSummaryBox(String label, int value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value.toString(),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _buildAttendanceTable(List<Map<String, dynamic>> checkIns) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5), // #
        1: const pw.FlexColumnWidth(2), // Nome
        2: const pw.FlexColumnWidth(1), // Nº Aluno
        3: const pw.FlexColumnWidth(1), // Hora
        4: const pw.FlexColumnWidth(1), // Status
        5: const pw.FlexColumnWidth(1), // Assinatura
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue900),
          children: [
            _buildTableHeader('#'),
            _buildTableHeader('Nome'),
            _buildTableHeader('Nº Aluno'),
            _buildTableHeader('Hora'),
            _buildTableHeader('Status'),
            _buildTableHeader('Assinatura'),
          ],
        ),
        // Data rows
        ...checkIns.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final checkIn = item['checkIn'] as CheckIn;
          final userName = item['userName'] as String;
          final userNumber = item['userNumber'] as String;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index.isEven ? PdfColors.white : PdfColors.grey50,
            ),
            children: [
              _buildTableCell('${index + 1}'),
              _buildTableCell(userName),
              _buildTableCell(userNumber),
              _buildTableCell(checkIn.formattedTime),
              _buildStatusCell(checkIn.status),
              _buildTableCell(''), // Empty for signature
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildStatusCell(CheckInStatus status) {
    PdfColor color;
    String text;

    switch (status) {
      case CheckInStatus.approved:
        color = PdfColors.green;
        text = 'Aprovado';
        break;
      case CheckInStatus.pending:
        color = PdfColors.orange;
        text = 'Pendente';
        break;
      case CheckInStatus.rejected:
        color = PdfColors.red;
        text = 'Rejeitado';
        break;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: pw.BoxDecoration(
          color: color.shade(50),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            color: color,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  static pw.Widget _buildSignatureSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 200,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400),
                ),
              ),
              child: pw.SizedBox(height: 40),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Assinatura do Docente',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 200,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400),
                ),
              ),
              child: pw.SizedBox(height: 40),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Data',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Documento gerado automaticamente pelo Sistema ISTEC Check-in',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
