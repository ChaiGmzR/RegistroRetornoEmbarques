import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/shipping_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/box_id_entry.dart';
import '../../models/mock_data.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/shimmer_loading.dart';
import '../scan/scan_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();

  List<BoxIdEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final cached = _visibleEntries(CacheService.getHistory());
    if (cached != null) {
      setState(() {
        _entries = cached;
        _isLoading = false;
      });
    }

    if (AuthService.useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) {
        return;
      }
      setState(() {
        _entries = _visibleEntries(MockData.recentScans) ?? [];
        _isLoading = false;
      });
      CacheService.setHistory(_entries);
      return;
    }

    try {
      final entries = await ShippingService.getHistory();
      if (!mounted) {
        return;
      }
      setState(() {
        _entries = _visibleEntries(entries) ?? [];
        _isLoading = false;
      });
      CacheService.setHistory(_entries);
    } catch (_) {
      if (!mounted) {
        return;
      }
      if (_isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<BoxIdEntry> get _filteredEntries {
    var entries = _entries;
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      entries = entries
          .where((e) =>
              e.boxId.toLowerCase().contains(query) ||
              (e.folio?.toLowerCase().contains(query) ?? false) ||
              (e.partNumber?.toLowerCase().contains(query) ?? false) ||
              (e.detail?.toLowerCase().contains(query) ?? false))
          .toList();
    }
    return entries;
  }

  List<BoxIdEntry>? _visibleEntries(List<BoxIdEntry>? entries) {
    return entries
        ?.where(
          (entry) => entry.status == MovementType.materialReturn,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entries = _filteredEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Retornos'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppTextField(
              label: 'Buscar',
              hint: 'No. de parte, folio o detalle',
              prefixIcon: Icons.search_rounded,
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${entries.length} resultado${entries.length != 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Icon(
                  Icons.sort_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextDisabled
                      : AppColors.lightTextDisabled,
                ),
                const SizedBox(width: 4),
                Text(
                  'Más reciente',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const ScanListShimmer()
                : entries.isEmpty
                    ? _buildEmptyState(theme, isDark)
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return ScanEntryCard(
                              entry: entry,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppConstants.scanResultRoute,
                                arguments: ScanResultArguments(
                                  boxId: entry.boxId,
                                  status: entry.status,
                                  scannedAt: entry.scannedAt,
                                  partNumber: entry.partNumber,
                                  quantity: entry.quantity,
                                  rawCode: entry.rawCode,
                                  detail: entry.detail,
                                  notes: entry.notes,
                                  compactDetailView: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: isDark
                ? AppColors.darkTextDisabled
                : AppColors.lightTextDisabled,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin resultados',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'No se encontraron retornos con esta búsqueda.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
