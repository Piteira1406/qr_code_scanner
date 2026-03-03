import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/firebase_service.dart';
import 'live_feed_screen.dart';

/// Screen for managing events (CRUD operations).
class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      return const Center(child: Text('Utilizador não autenticado'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Eventos')),
      body: StreamBuilder<List<Event>>(
        stream: _firebaseService.getProfessorEvents(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erro: ${snapshot.error}'),
                ],
              ),
            );
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return _buildEventCard(events[index], user.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Sem eventos criados',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie um evento através do Gerador de QR Code',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event, String professorId) {
    final now = DateTime.now();
    final isPast = event.endTime.isBefore(now);
    final isOngoing = event.isOngoing;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getEventStatusColor(
                event,
                isPast,
                isOngoing,
              ).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  color: _getEventStatusColor(event, isPast, isOngoing),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildEventStatusBadge(event, isPast, isOngoing),
              ],
            ),
          ),

          // Event details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.location_on, event.location),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.schedule,
                  '${_formatDateTime(event.startTime)} - ${_formatTime(event.endTime)}',
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.description, event.description),
                ],
                if (event.maxCapacity != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.people,
                    'Capacidade: ${event.maxCapacity}',
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Live Feed
                _buildActionButton(
                  icon: Icons.live_tv,
                  label: 'Live Feed',
                  color: Colors.blue,
                  onPressed: () => _openLiveFeed(event),
                ),

                // Edit
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Editar',
                  color: Colors.orange,
                  onPressed: () => _showEditDialog(event),
                ),

                // Close/Reopen
                if (!isPast)
                  _buildActionButton(
                    icon: event.isActive ? Icons.block : Icons.play_arrow,
                    label: event.isActive ? 'Fechar' : 'Reabrir',
                    color: event.isActive ? Colors.grey : Colors.green,
                    onPressed: () => _toggleEventStatus(event),
                  ),

                // Delete
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Eliminar',
                  color: Colors.red,
                  onPressed: () => _confirmDelete(event),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: Colors.grey[700])),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildEventStatusBadge(Event event, bool isPast, bool isOngoing) {
    String label;
    Color color;

    if (event.isClosed) {
      label = 'Fechado';
      color = Colors.grey;
    } else if (isPast) {
      label = 'Terminado';
      color = Colors.grey;
    } else if (isOngoing) {
      label = 'A Decorrer';
      color = Colors.green;
    } else {
      label = 'Agendado';
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getEventStatusColor(Event event, bool isPast, bool isOngoing) {
    if (event.isClosed || isPast) return Colors.grey;
    if (isOngoing) return Colors.green;
    return Colors.blue;
  }

  void _openLiveFeed(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LiveFeedScreen(event: event)),
    );
  }

  void _showEditDialog(Event event) {
    final nameController = TextEditingController(text: event.name);
    final descriptionController = TextEditingController(
      text: event.description,
    );
    final locationController = TextEditingController(text: event.location);
    final latController = TextEditingController(
      text: event.latitude.toString(),
    );
    final lngController = TextEditingController(
      text: event.longitude.toString(),
    );
    final capacityController = TextEditingController(
      text: event.maxCapacity?.toString() ?? '',
    );

    DateTime startTime = event.startTime;
    DateTime endTime = event.endTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Evento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Evento',
                    prefixIcon: Icon(Icons.event),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Localização',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          prefixIcon: Icon(Icons.my_location),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: lngController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          prefixIcon: Icon(Icons.my_location),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capacityController,
                  decoration: const InputDecoration(
                    labelText: 'Capacidade Máxima (opcional)',
                    prefixIcon: Icon(Icons.people),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                // Date/Time pickers
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.play_arrow),
                  title: const Text('Início'),
                  subtitle: Text(_formatDateTime(startTime)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startTime,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(startTime),
                      );
                      if (time != null) {
                        setDialogState(() {
                          startTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.stop),
                  title: const Text('Fim'),
                  subtitle: Text(_formatDateTime(endTime)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endTime,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(endTime),
                      );
                      if (time != null) {
                        setDialogState(() {
                          endTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedEvent = event.copyWith(
                  name: nameController.text,
                  description: descriptionController.text,
                  location: locationController.text,
                  latitude:
                      double.tryParse(latController.text) ?? event.latitude,
                  longitude:
                      double.tryParse(lngController.text) ?? event.longitude,
                  startTime: startTime,
                  endTime: endTime,
                  maxCapacity: int.tryParse(capacityController.text),
                );

                try {
                  await _firebaseService.updateEvent(updatedEvent);
                  if (context.mounted) Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Evento atualizado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Erro: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleEventStatus(Event event) async {
    try {
      if (event.isActive) {
        await _firebaseService.closeEvent(event.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Evento fechado')));
        }
      } else {
        await _firebaseService.reopenEvent(event.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Evento reaberto'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDelete(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Evento'),
        content: Text(
          'Tem a certeza que deseja eliminar "${event.name}"?\n\n'
          'Esta ação irá também eliminar todos os check-ins associados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firebaseService.deleteEvent(event.id);
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Evento eliminado'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Erro: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
