import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/log_service.dart';

/// Tab de logs - affiche les logs de l'app en temps réel.
class LogsTab extends StatefulWidget {
  const LogsTab({super.key});

  @override
  State<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<LogsTab> {
  final _scrollController = ScrollController();
  StreamSubscription<LogEntry>? _subscription;
  List<LogEntry> _logs = [];
  final Set<LogLevel> _activeFilters = LogLevel.values.toSet();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _logs = List.from(logService.logs);
    _subscription = logService.stream.listen(_onNewLog);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onNewLog(LogEntry entry) {
    setState(() => _logs.add(entry));
    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _toggleFilter(LogLevel level) {
    setState(() {
      if (_activeFilters.contains(level)) {
        _activeFilters.remove(level);
      } else {
        _activeFilters.add(level);
      }
    });
  }

  void _clearLogs() {
    logService.clear();
    setState(() => _logs.clear());
  }

  void _exportLogs() {
    final exported = logService.export();
    Clipboard.setData(ClipboardData(text: exported));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copiés dans le presse-papier')),
    );
  }

  void _addTestLog() {
    logService.info('Test log entry', source: 'DevConsole');
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs =
        _logs.where((l) => _activeFilters.contains(l.level)).toList();

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Filters - scrollable
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: LogLevel.values
                        .map((level) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: FilterChip(
                                label: Text(_getLevelLabel(level),
                                    style: const TextStyle(fontSize: 11)),
                                selected: _activeFilters.contains(level),
                                onSelected: (_) => _toggleFilter(level),
                                avatar: Text(_getLevelIcon(level),
                                    style: const TextStyle(fontSize: 12)),
                                visualDensity: VisualDensity.compact,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),

              // Actions
              IconButton(
                icon: Icon(
                    _autoScroll ? Icons.arrow_downward : Icons.pause,
                    size: 18),
                onPressed: () => setState(() => _autoScroll = !_autoScroll),
                tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: _addTestLog,
                tooltip: 'Add test log',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: _exportLogs,
                tooltip: 'Export logs',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: _clearLogs,
                tooltip: 'Clear logs',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Logs list
        Expanded(
          child: filteredLogs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) =>
                      _buildLogEntry(filteredLogs[index]),
                ),
        ),

        // Status bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Text(
                '${filteredLogs.length} / ${_logs.length} logs',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                _autoScroll ? 'Live' : 'Paused',
                style: TextStyle(
                  fontSize: 11,
                  color: _autoScroll ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Aucun log', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addTestLog,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Ajouter un log test'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(LogEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getLevelColor(entry.level).withValues(alpha: 0.05),
        border: Border(
            bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            entry.formattedTime,
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.grey[500]),
          ),
          const SizedBox(width: 8),

          // Level icon
          Text(entry.levelIcon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),

          // Source
          if (entry.source != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: _getLevelColor(entry.level).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.source!,
                style: TextStyle(
                    fontSize: 10,
                    color: _getLevelColor(entry.level),
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message
          Expanded(
            child: SelectableText(
              entry.message,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _getLevelLabel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'Debug';
      case LogLevel.info:
        return 'Info';
      case LogLevel.warning:
        return 'Warn';
      case LogLevel.error:
        return 'Error';
    }
  }

  String _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }
}
