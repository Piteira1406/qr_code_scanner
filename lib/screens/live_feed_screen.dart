import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';

/// Constants for this screen
const Color _primaryColor = AppColors.primaryStart;

/// Live feed screen showing real-time check-ins with validation controls.
class LiveFeedScreen extends StatefulWidget {
  final Event event;

  const LiveFeedScreen({super.key, required this.event});

  @override
  State<LiveFeedScreen> createState() => _LiveFeedScreenState();
}

class _LiveFeedScreenState extends State<LiveFeedScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _filterStatus = 'all'; // all, pending, approved, rejected

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.event.name, style: const TextStyle(fontSize: 18)),
            Text(
              'Monitorização em Tempo Real',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          // Export PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _exportPdf(user),
            tooltip: 'Exportar PDF',
          ),
          // Filter dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filterStatus = value),
            itemBuilder: (context) => [
              _buildFilterItem('all', 'Todos', Icons.list),
              _buildFilterItem('pending', 'Pendentes', Icons.pending),
              _buildFilterItem('approved', 'Aprovados', Icons.check_circle),
              _buildFilterItem('rejected', 'Rejeitados', Icons.cancel),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Event info header
          _buildEventHeader(),

          // Live feed list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firebaseService.getLiveEventCheckIns(widget.event.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Erro: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final checkIns = snapshot.data ?? [];
                final filteredCheckIns = _filterCheckIns(checkIns);

                if (filteredCheckIns.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredCheckIns.length,
                  itemBuilder: (context, index) {
                    final item = filteredCheckIns[index];
                    return _buildCheckInCard(item, user?.id ?? '');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildFilterItem(
    String value,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: _filterStatus == value ? _primaryColor : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: _filterStatus == value
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: _primaryColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.event, color: _primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.location,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_formatDateTime(widget.event.startTime)} - ${_formatTime(widget.event.endTime)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.event.isOngoing ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.event.isOngoing ? 'A Decorrer' : 'Agendado',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterCheckIns(
    List<Map<String, dynamic>> checkIns,
  ) {
    if (_filterStatus == 'all') return checkIns;

    return checkIns.where((item) {
      final checkIn = item['checkIn'] as CheckIn;
      return checkIn.status.name == _filterStatus;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _filterStatus == 'all'
                ? Icons.people_outline
                : Icons.filter_alt_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _filterStatus == 'all'
                ? 'Ainda não há check-ins'
                : 'Nenhum check-in com este filtro',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Os check-ins aparecerão aqui em tempo real',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInCard(Map<String, dynamic> item, String professorId) {
    final checkIn = item['checkIn'] as CheckIn;
    final userName = item['userName'] as String;
    final userNumber = item['userNumber'] as String;
    final userEmail = item['userEmail'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and status
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(
                    checkIn.status,
                  ).withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    color: _getStatusColor(checkIn.status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$userNumber • $userEmail',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(checkIn.status),
              ],
            ),

            const SizedBox(height: 12),

            // Check-in details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.access_time,
                      'Hora',
                      checkIn.formattedTime,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.calendar_today,
                      'Data',
                      checkIn.formattedDate,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.location_on,
                      'Distância',
                      '${checkIn.distanceToEvent.toStringAsFixed(0)}m',
                    ),
                  ),
                ],
              ),
            ),

            // Actions (only for pending)
            if (checkIn.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectCheckIn(checkIn.id, professorId),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text(
                        'Rejeitar',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveCheckIn(checkIn.id, professorId),
                      icon: const Icon(Icons.check),
                      label: const Text('Aprovar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Validation info (for validated check-ins)
            if (!checkIn.isPending && checkIn.validatedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Validado em ${_formatDateTime(checkIn.validatedAt!)}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatusBadge(CheckInStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(CheckInStatus status) {
    return switch (status) {
      CheckInStatus.pending => Colors.orange,
      CheckInStatus.approved => Colors.green,
      CheckInStatus.rejected => Colors.red,
    };
  }

  String _getStatusLabel(CheckInStatus status) {
    return switch (status) {
      CheckInStatus.pending => 'Pendente',
      CheckInStatus.approved => 'Aprovado',
      CheckInStatus.rejected => 'Rejeitado',
    };
  }

  Future<void> _approveCheckIn(String checkInId, String professorId) async {
    try {
      await _firebaseService.approveCheckIn(checkInId, professorId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in aprovado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectCheckIn(String checkInId, String professorId) async {
    try {
      await _firebaseService.rejectCheckIn(checkInId, professorId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in rejeitado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportPdf(dynamic user) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('A gerar PDF...')));

      final checkIns = await _firebaseService.getEventCheckInsForExport(
        widget.event.id,
      );

      await PdfService.generateAttendancePdf(
        event: widget.event,
        checkIns: checkIns,
        professorName: user?.name ?? 'Professor',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
