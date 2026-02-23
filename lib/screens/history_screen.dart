import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

/// Screen displaying the history of confirmed check-ins.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  /// Navigate to home tab (index 0)
  void _navigateToHome(BuildContext context) {
    final homeState = context.findAncestorStateOfType<HomeScreenState>();
    if (homeState != null) {
      homeState.setTab(0);
    }
  }

  /// Navigate to check-in tab (index 1)
  void _navigateToCheckIn(BuildContext context) {
    final homeState = context.findAncestorStateOfType<HomeScreenState>();
    if (homeState != null) {
      homeState.setTab(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Modern gradient header
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
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => _navigateToHome(context),
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Histórico',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Consumer<CheckInProvider>(
                            builder: (context, provider, _) {
                              if (provider.checkInHistory.isEmpty) {
                                return const SizedBox(width: 48);
                              }
                              return IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    _confirmClearHistory(context, provider),
                                tooltip: 'Limpar Histórico',
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Consumer<CheckInProvider>(
                        builder: (context, provider, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStatBadge(
                                icon: Icons.check_circle,
                                value: '${provider.checkInHistory.length}',
                                label: 'Total',
                              ),
                              const SizedBox(width: 24),
                              _buildStatBadge(
                                icon: Icons.calendar_today,
                                value: _getUniqueEventsCount(
                                  provider.checkInHistory,
                                ).toString(),
                                label: 'Eventos',
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
          ),
          // Content
          Consumer<CheckInProvider>(
            builder: (context, provider, _) {
              if (provider.checkInHistory.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState(context));
              }
              return _buildHistoryList(context, provider.checkInHistory);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withAlpha(204),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getUniqueEventsCount(List<CheckIn> checkIns) {
    return checkIns.map((c) => c.eventName).toSet().length;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryStart.withAlpha(26),
                    AppColors.primaryEnd.withAlpha(26),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 50,
                color: AppColors.primaryStart,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sem Registos',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Os seus check-ins confirmados aparecerão aqui.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryStart, AppColors.primaryEnd],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () => _navigateToCheckIn(context),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Fazer Check-in'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverList _buildHistoryList(BuildContext context, List<CheckIn> checkIns) {
    // Group check-ins by date
    final groupedCheckIns = <String, List<CheckIn>>{};
    for (final checkIn in checkIns) {
      final dateKey = checkIn.formattedDate;
      groupedCheckIns.putIfAbsent(dateKey, () => []).add(checkIn);
    }

    final entries = groupedCheckIns.entries.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final dateKey = entries[index].key;
        final dayCheckIns = entries[index].value;

        return Padding(
          padding: EdgeInsets.only(
            top: index == 0 ? 24 : 8,
            left: 16,
            right: 16,
            bottom: index == entries.length - 1 ? 24 : 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryStart.withAlpha(26),
                            AppColors.primaryEnd.withAlpha(26),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatDateHeader(dateKey),
                        style: TextStyle(
                          color: AppColors.primaryStart,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${dayCheckIns.length} ${dayCheckIns.length == 1 ? 'presença' : 'presenças'}',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Check-in cards
              ...dayCheckIns.map(
                (checkIn) => _buildCheckInCard(context, checkIn),
              ),
            ],
          ),
        );
      }, childCount: entries.length),
    );
  }

  Widget _buildCheckInCard(BuildContext context, CheckIn checkIn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCheckInDetails(context, checkIn),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Success indicator with gradient
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withAlpha(38),
                        AppColors.success.withAlpha(77),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Event details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        checkIn.eventName,
                        style: AppTextStyles.bodyBold.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              checkIn.eventLocation,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        checkIn.formattedTime,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${checkIn.distanceToEvent.toStringAsFixed(0)}m',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateHeader(String dateKey) {
    final parts = dateKey.split('/');
    if (parts.length != 3) return dateKey;

    final day = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final year = int.tryParse(parts[2]) ?? 0;

    final now = DateTime.now();
    final date = DateTime(year, month, day);
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Hoje';
    if (difference == 1) return 'Ontem';
    if (difference < 7) return 'Há $difference dias';

    final months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return '$day de ${months[month - 1]}';
  }

  void _showCheckInDetails(BuildContext context, CheckIn checkIn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Header
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.success.withAlpha(51),
                            AppColors.success.withAlpha(77),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Presença Confirmada',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${checkIn.formattedDate} às ${checkIn.formattedTime}',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 20),
                // Details
                _buildDetailRow(Icons.event, 'Evento', checkIn.eventName),
                _buildDetailRow(
                  Icons.location_on,
                  'Local',
                  checkIn.eventLocation,
                ),
                _buildDetailRow(
                  Icons.straighten,
                  'Distância',
                  '${checkIn.distanceToEvent.toStringAsFixed(1)} metros',
                ),
                _buildDetailRow(
                  Icons.fingerprint,
                  'ID do Check-in',
                  checkIn.id,
                ),
                const SizedBox(height: 24),
                // Close button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryStart, AppColors.primaryEnd],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Fechar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryStart.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryStart),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory(
    BuildContext context,
    CheckInProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(26),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Limpar Histórico',
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'Tem a certeza que deseja apagar todo o histórico de presenças? Esta ação não pode ser revertida.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: AppColors.border),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apagar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await provider.clearHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Histórico apagado'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}
