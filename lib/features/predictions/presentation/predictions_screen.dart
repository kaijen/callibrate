import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/database/app_database.dart';
import 'prediction_card.dart';

enum FilterTab { all, pending, needsResolution, resolved }

class PredictionsScreen extends ConsumerStatefulWidget {
  final FilterTab initialFilter;

  const PredictionsScreen({
    super.key,
    this.initialFilter = FilterTab.all,
  });

  @override
  ConsumerState<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends ConsumerState<PredictionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialFilter.index,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Set<String> _collectTags(List<PredictionView> predictions) {
    return {for (final p in predictions) ...p.tagList};
  }

  @override
  Widget build(BuildContext context) {
    final predictionsAsync = ref.watch(predictionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vorhersagen'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Alle'),
            Tab(text: 'Offen'),
            Tab(text: 'Ausstehend'),
            Tab(text: 'Aufgelöst'),
          ],
        ),
      ),
      body: predictionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (predictions) {
          final allTags = _collectTags(predictions);
          return Column(
            children: [
              if (allTags.isNotEmpty) _buildTagFilter(allTags),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _PredictionList(
                      predictions: predictions,
                      filter: FilterTab.all,
                      selectedTags: _selectedTags,
                    ),
                    _PredictionList(
                      predictions: predictions,
                      filter: FilterTab.pending,
                      selectedTags: _selectedTags,
                    ),
                    _PredictionList(
                      predictions: predictions,
                      filter: FilterTab.needsResolution,
                      selectedTags: _selectedTags,
                    ),
                    _PredictionList(
                      predictions: predictions,
                      filter: FilterTab.resolved,
                      selectedTags: _selectedTags,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/new'),
        tooltip: 'Neue Vorhersage',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTagFilter(Set<String> allTags) {
    final tags = allTags.toList()..sort();
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final tag in tags)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(tag),
                selected: _selectedTags.contains(tag),
                onSelected: (_) => _toggleTag(tag),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

class _PredictionList extends StatelessWidget {
  final List<PredictionView> predictions;
  final FilterTab filter;
  final Set<String> selectedTags;

  const _PredictionList({
    required this.predictions,
    required this.filter,
    required this.selectedTags,
  });

  List<PredictionView> get _filtered {
    var list = switch (filter) {
      FilterTab.all => predictions,
      FilterTab.pending =>
        predictions.where((p) => p.status == PredictionStatus.pending).toList(),
      FilterTab.needsResolution => predictions
          .where((p) => p.status == PredictionStatus.needsResolution)
          .toList(),
      FilterTab.resolved => predictions
          .where((p) => p.status == PredictionStatus.resolved)
          .toList(),
    };
    if (selectedTags.isNotEmpty) {
      list = list
          .where((p) => p.tagList.any(selectedTags.contains))
          .toList();
    }
    return list;
  }

  void _handleTap(BuildContext context, PredictionView prediction) {
    switch (prediction.status) {
      case PredictionStatus.pending:
        context.push('/estimate/${prediction.question.id}');
      case PredictionStatus.needsResolution:
        context.push('/resolve/${prediction.question.id}');
      case PredictionStatus.resolved:
        context.push('/prediction/${prediction.question.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Keine Vorhersagen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final prediction = items[index];
        return PredictionCard(
          prediction: prediction,
          onTap: () => _handleTap(context, prediction),
        );
      },
    );
  }
}
