import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Screen for professors to view attendance records.
class ProfessorAttendanceScreen extends StatefulWidget {
  const ProfessorAttendanceScreen({super.key});

  @override
  State<ProfessorAttendanceScreen> createState() =>
      _ProfessorAttendanceScreenState();
}

class _ProfessorAttendanceScreenState extends State<ProfessorAttendanceScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Event> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = 'Utilizador não encontrado';
      });
      return;
    }

    try {
      _firebaseService
          .getProfessorEvents(user.id)
          .listen(
            (events) {
              if (mounted) {
                setState(() {
                  _events = events;
                  _isLoading = false;
                });
              }
            },
            onError: (e) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _error = 'Erro ao carregar eventos';
                });
              }
            },
          );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erro ao carregar eventos';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryStart, AppColors.primaryEnd],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Histórico de Presenças',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _error = null;
                        });
                        _loadEvents();
                      },
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            )
          else if (_events.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.event_busy_rounded,
                        size: 40,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sem aulas registadas',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gere um QR Code para começar a registar presenças',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildEventCard(_events[index]),
                  childCount: _events.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showEventDetails(event),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryStart,
                            AppColors.primaryEnd,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.class_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: AppTextStyles.bodyBold.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.location,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(event),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoItem(
                      Icons.calendar_today_rounded,
                      _formatDate(event.startTime),
                    ),
                    const SizedBox(width: 24),
                    _buildInfoItem(
                      Icons.access_time_rounded,
                      '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<int>(
                  future: _firebaseService.getEventCheckInCount(event.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$count ${count == 1 ? 'presença' : 'presenças'} registadas',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Event event) {
    final now = DateTime.now();
    final isActive =
        now.isAfter(event.startTime) && now.isBefore(event.endTime);
    final isPast = now.isAfter(event.endTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withAlpha(26)
            : isPast
            ? AppColors.textTertiary.withAlpha(26)
            : AppColors.info.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive
            ? 'Ativa'
            : isPast
            ? 'Terminada'
            : 'Agendada',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive
              ? AppColors.success
              : isPast
              ? AppColors.textTertiary
              : AppColors.info,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _showEventDetails(Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _EventDetailsSheet(event: event, firebaseService: _firebaseService),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _EventDetailsSheet extends StatelessWidget {
  final Event event;
  final FirebaseService firebaseService;

  const _EventDetailsSheet({
    required this.event,
    required this.firebaseService,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryStart,
                            AppColors.primaryEnd,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.class_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.location,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Attendance list
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: firebaseService.getEventCheckIns(event.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erro ao carregar presenças',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      );
                    }

                    final checkIns = snapshot.data ?? [];

                    if (checkIns.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off_rounded,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sem presenças registadas',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      itemCount: checkIns.length,
                      itemBuilder: (context, index) {
                        final item = checkIns[index];
                        final checkIn = item['checkIn'] as CheckIn;
                        final userName = item['userName'] as String;
                        final userNumber = item['userNumber'] as String;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.success.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: AppTextStyles.bodyBold.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Nº $userNumber',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    checkIn.formattedTime,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${checkIn.distanceToEvent.toStringAsFixed(0)}m',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
