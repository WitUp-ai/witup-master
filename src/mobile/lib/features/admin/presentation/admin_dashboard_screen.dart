import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);

    return isAdmin.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Errore: $e')),
      ),
      data: (admin) {
        if (!admin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Accesso Negato')),
            body: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 64, color: AppTheme.textTertiary),
                  SizedBox(height: 16),
                  Text('Non hai i permessi per accedere a questa sezione.'),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Admin Panel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                Tab(icon: Icon(Icons.people), text: 'Utenti'),
                Tab(icon: Icon(Icons.brush), text: 'Drawings'),
                Tab(icon: Icon(Icons.api), text: 'API & Config'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(),
              _UsersTab(),
              _DrawingsTab(),
              _SystemConfigTab(),
            ],
          ),
        );
      },
    );
  }
}

// ─── OVERVIEW TAB ────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);

    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
      data: (data) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminStatsProvider),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          children: [
            Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spaceM),

            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _StatCard(
                  title: 'Utenti Totali',
                  value: '${data.totalUsers}',
                  icon: Icons.people,
                  color: AppTheme.primaryColor,
                ),
                _StatCard(
                  title: 'Drawings Totali',
                  value: '${data.totalDrawings}',
                  icon: Icons.brush,
                  color: AppTheme.accentColor,
                ),
                _StatCard(
                  title: 'Completati',
                  value: '${data.completedDrawings}',
                  icon: Icons.check_circle,
                  color: AppTheme.successColor,
                ),
                _StatCard(
                  title: 'Falliti',
                  value: '${data.failedDrawings}',
                  icon: Icons.error,
                  color: AppTheme.errorColor,
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spaceL),

            // Success Rate
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: AppTheme.shadowSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tasso di Successo AI',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRoundedRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: data.successRate / 100,
                            minHeight: 12,
                            backgroundColor: AppTheme.textTertiary.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation(
                              data.successRate > 80
                                  ? AppTheme.successColor
                                  : data.successRate > 50
                                      ? AppTheme.warningColor
                                      : AppTheme.errorColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${data.successRate.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${data.pendingDrawings} in coda',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceL),

            // Quick Actions
            Text(
              'Azioni Rapide',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionChip(
                  label: 'Refresh Stats',
                  icon: Icons.refresh,
                  onTap: () => ref.invalidate(adminStatsProvider),
                ),
                _ActionChip(
                  label: 'Supabase Dashboard',
                  icon: Icons.open_in_new,
                  onTap: () {
                    // Would open Supabase dashboard URL
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── USERS TAB ────────────────────────────────────────

bool _isAdminEmail(String? email) =>
    const ['giovanni@witup.ai', 'testuser@gmail.com'].contains(email);

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider);

    return users.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
      data: (userList) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminUsersProvider),
        child: ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          itemCount: userList.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Utenti (${userList.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }
            final user = userList[index - 1];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _isAdminEmail(user['email'])
                      ? AppTheme.primaryColor
                      : AppTheme.accentColor,
                  child: Icon(
                    _isAdminEmail(user['email']) ? Icons.admin_panel_settings : Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  user['email'] ?? 'N/A',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                subtitle: Text(
                  'Piano: ${user['subscription_tier'] ?? 'free'} | '
                  'Drawings: ${user['monthly_drawings_used'] ?? 0}/${user['monthly_drawings_limit'] ?? 5}',
                  style: GoogleFonts.poppins(fontSize: 11),
                ),
                trailing: Chip(
                  label: Text(
                    _isAdminEmail(user['email']) ? 'admin' : 'user',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: _isAdminEmail(user['email'])
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── DRAWINGS TAB ────────────────────────────────────────

class _DrawingsTab extends ConsumerWidget {
  const _DrawingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawings = ref.watch(adminRecentDrawingsProvider);

    return drawings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
      data: (drawingList) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminRecentDrawingsProvider),
        child: ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          itemCount: drawingList.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Drawings Recenti (${drawingList.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }
            final drawing = drawingList[index - 1];
            final status = drawing['model_status'] ?? 'unknown';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _statusIcon(status),
                  color: _statusColor(status),
                ),
                title: Text(
                  drawing['id']?.toString().substring(0, 8) ?? 'N/A',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                subtitle: Text(
                  'User: ${drawing['user_id']?.toString().substring(0, 8) ?? 'N/A'} | '
                  '${drawing['created_at']?.toString().substring(0, 16) ?? ''}',
                  style: GoogleFonts.poppins(fontSize: 11),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      color: _statusColor(status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'processing':
        return Icons.hourglass_top;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.successColor;
      case 'failed':
        return AppTheme.errorColor;
      case 'processing':
        return AppTheme.warningColor;
      case 'pending':
        return AppTheme.infoColor;
      default:
        return AppTheme.textSecondary;
    }
  }
}

// ─── SYSTEM CONFIG TAB (Dynamic Configuration Management) ───────────────

class _SystemConfigTab extends ConsumerWidget {
  const _SystemConfigTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configs = ref.watch(systemConfigProvider);

    return configs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: AppTheme.errorColor, size: 48),
            const SizedBox(height: 16),
            Text('Errore: $e', style: GoogleFonts.poppins()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(systemConfigProvider),
              child: const Text('Riprova'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tabella system_config non trovata. Esegui lo script SQL.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
      data: (configList) {
        final hasConfigs = configList.isNotEmpty;
        final displayList = hasConfigs ? configList : defaultSystemConfigs;

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(systemConfigProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            children: [
              Row(
                children: [
                  Text(
                    'Configurazioni Sistema',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(
                      hasConfigs ? 'Database' : 'Default',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor:
                        hasConfigs ? AppTheme.successColor : AppTheme.warningColor,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Gestisci API Keys e modelli AI dinamicamente',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),

              // Add new config button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddConfigDialog(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Aggiungi Configurazione'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spaceM),

              // Config list
              ...displayList.map((config) => _SystemConfigCard(
                    config: config,
                    onEdit: () => _showEditConfigDialog(context, ref, config),
                    onDelete: () => _showDeleteConfigDialog(context, ref, config),
                  )),

              const SizedBox(height: AppTheme.spaceL),

              // Information box
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceM),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: AppTheme.infoColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Come funziona',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.infoColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Le configurazioni sono memorizzate nel database (tabella system_config). '
                      'L\'app legge dinamicamente queste configurazioni senza bisogno di deploy.',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configurazioni chiave:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._keyConfigs.map((key) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 6, color: AppTheme.textSecondary),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  key,
                                  style: GoogleFonts.poppins(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static const _keyConfigs = [
    'REPLICATE_API_TOKEN - Chiave API per servizi Replicate',
    'MODEL_VISION - Modello Vision AI per validazione disegni',
    'MODEL_3D_GENERATOR - Modello per generazione 3D',
    'PRINTER_API_KEY - Chiave per servizio stampa 3D',
    'SYSTEM_STATUS - Stato sistema (active/maintenance/disabled)',
  ];

  void _showAddConfigDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _SystemConfigDialog(
        title: 'Aggiungi Configurazione',
        onSave: (key, value, description) async {
          final repo = ref.read(systemConfigRepositoryProvider);
          await repo.updateConfig(key, value, description);
          ref.invalidate(systemConfigProvider);
        },
      ),
    );
  }

  void _showEditConfigDialog(BuildContext context, WidgetRef ref, SystemConfig config) {
    showDialog(
      context: context,
      builder: (context) => _SystemConfigDialog(
        title: 'Modifica Configurazione',
        initialKey: config.key,
        initialValue: config.value,
        initialDescription: config.description ?? '',
        onSave: (key, value, description) async {
          final repo = ref.read(systemConfigRepositoryProvider);
          await repo.updateConfig(key, value, description);
          ref.invalidate(systemConfigProvider);
        },
      ),
    );
  }

  void _showDeleteConfigDialog(BuildContext context, WidgetRef ref, SystemConfig config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Configurazione'),
        content: Text(
          'Sei sicuro di voler eliminare la configurazione "${config.key}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(systemConfigRepositoryProvider);
              await repo.deleteConfig(config.key);
              ref.invalidate(systemConfigProvider);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}

class _SystemConfigCard extends StatelessWidget {
  final SystemConfig config;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SystemConfigCard({
    required this.config,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  config.isSensitive ? Icons.vpn_key : Icons.settings,
                  color: config.isSensitive ? AppTheme.accentColor : AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.key,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (config.description != null)
                        Text(
                          config.description!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Modifica'),
                        ],
                      ),
                      onTap: onEdit,
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                          const SizedBox(width: 8),
                          Text(
                            'Elimina',
                            style: TextStyle(color: AppTheme.errorColor),
                          ),
                        ],
                      ),
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      config.isSensitive
                          ? '••••••••${config.value.substring(config.value.length - 4)}'
                          : config.value,
                      style: GoogleFonts.robotoMono(
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: config.value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copiato: ${config.key}'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ultima modifica: ${_formatDate(config.updatedAt)}',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _SystemConfigDialog extends StatefulWidget {
  final String title;
  final String? initialKey;
  final String? initialValue;
  final String? initialDescription;
  final Future<void> Function(String key, String value, String description) onSave;

  const _SystemConfigDialog({
    required this.title,
    this.initialKey,
    this.initialValue,
    this.initialDescription,
    required this.onSave,
  });

  @override
  State<_SystemConfigDialog> createState() => _SystemConfigDialogState();
}

class _SystemConfigDialogState extends State<_SystemConfigDialog> {
  late TextEditingController _keyController;
  late TextEditingController _valueController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.initialKey ?? '');
    _valueController = TextEditingController(text: widget.initialValue ?? '');
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'Key',
                hintText: 'Es: REPLICATE_API_TOKEN',
                border: OutlineInputBorder(),
              ),
              readOnly: widget.initialKey != null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Value',
                hintText: 'Inserisci il valore',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrizione',
                hintText: 'Descrizione umana dello scopo',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () async {
            final key = _keyController.text.trim();
            final value = _valueController.text.trim();
            final description = _descriptionController.text.trim();

            if (key.isEmpty || value.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Key e Value sono obbligatori')),
              );
              return;
            }

            await widget.onSave(key, value, description);
            Navigator.pop(context);
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

// Temporary placeholder for Clipboard import
// Will be replaced with actual import when needed
class Clipboard {
  static void setData(ClipboardData data) {
    // Implementation depends on platform
    // This is a placeholder
  }
}

class ClipboardData {
  final String text;
  const ClipboardData({required this.text});
}

// ─── WIDGETS ────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _ApiConfigCard extends StatelessWidget {
  final String title;
  final String description;
  final String status;
  final Color statusColor;
  final IconData icon;
  final List<String> details;

  const _ApiConfigCard({
    required this.title,
    required this.description,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...details.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: AppTheme.textTertiary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        d,
                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// Utility widget for clipping with rounded rect
class ClipRoundedRect extends StatelessWidget {
  final BorderRadius borderRadius;
  final Widget child;

  const ClipRoundedRect({super.key, required this.borderRadius, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: borderRadius, child: child);
  }
}
