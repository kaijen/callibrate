import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/calibration_math.dart';
import '../../../core/utils/format_utils.dart';
import '../../../shared/widgets/estimate_inputs.dart';
import '../../../shared/widgets/feedback_sheet.dart';

// Lokaler autoDispose-Provider – bleibt screen-privat

final _estimateProvider =
    StateNotifierProvider.autoDispose<EstimateFormNotifier, EstimateFormState>(
        (_) => EstimateFormNotifier());

// --- Screen ---

class EstimateScreen extends ConsumerStatefulWidget {
  final int questionId;

  const EstimateScreen({super.key, required this.questionId});

  @override
  ConsumerState<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends ConsumerState<EstimateScreen> {
  // Einmal laden statt bei jedem Rebuild eine neue DB-Abfrage zu starten.
  late final Future<(Question, Estimate?)> _future = _load();

  Future<(Question, Estimate?)> _load() async {
    final db = ref.read(appDatabaseProvider);
    final question = await db.getQuestion(widget.questionId);
    final estimate = await db.getEstimateForQuestion(widget.questionId);
    return (question, estimate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schätzung abgeben')),
      body: FutureBuilder<(Question, Estimate?)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Fehler: ${snapshot.error}'));
          }
          final (question, existing) = snapshot.data!;
          return _EstimateBody(question: question, existingEstimate: existing);
        },
      ),
    );
  }
}

// --- Body ---

class _EstimateBody extends ConsumerStatefulWidget {
  final Question question;
  final Estimate? existingEstimate;

  const _EstimateBody({required this.question, this.existingEstimate});

  @override
  ConsumerState<_EstimateBody> createState() => _EstimateBodyState();
}

class _EstimateBodyState extends ConsumerState<_EstimateBody> {
  late final TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    // Nur befüllen wenn keine Unit aus der Frage selbst bekannt ist
    final knownUnit = widget.question.unit ?? widget.existingEstimate?.unit;
    _unitController = TextEditingController(
      text: knownUnit == null ? (widget.existingEstimate?.unit ?? '') : '',
    );

    // Bestehende Schätzung ins Formular übernehmen, damit beim Bearbeiten
    // nicht wieder die Defaults (90 %, keine Auswahl) erscheinen.
    final existing = widget.existingEstimate;
    if (existing != null) {
      ref.read(_estimateProvider.notifier).initFrom(
            binaryChoice: existing.binaryChoice,
            confidenceLevel: existing.confidenceLevel,
            lowerBoundText:
                existing.lowerBound != null ? formatNum(existing.lowerBound) : '',
            upperBoundText:
                existing.upperBound != null ? formatNum(existing.upperBound) : '',
          );
    }
  }

  @override
  void dispose() {
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_estimateProvider);
    final notifier = ref.read(_estimateProvider.notifier);
    final db = ref.watch(appDatabaseProvider);
    final type = widget.question.predictionType;

    final categoryLabel =
        widget.question.category == 'epistemic' ? 'Epistemisch' : 'Aleatorisch';

    // Unit aus Frage (Import/Erstellung) hat Vorrang vor manuellem Eingabefeld
    final knownUnit = widget.question.unit ?? widget.existingEstimate?.unit;
    final unit = knownUnit ?? _unitController.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              categoryLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.question.questionText,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          if (type == 'binary') ...[
            BinaryEstimateInput(state: state, notifier: notifier),
          ] else if (type == 'factual') ...[
            FactualEstimateInput(state: state, notifier: notifier),
          ] else if (type == 'interval') ...[
            if (knownUnit != null) ...[
              Row(
                children: [
                  const Icon(Icons.straighten, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Einheit: $knownUnit',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ] else ...[
              TextField(
                controller: _unitController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Einheit (optional)',
                  hintText: 'z.B. m, °C, kg',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            IntervalEstimateInput(
              state: state,
              notifier: notifier,
              unit: unit.isEmpty ? null : unit,
            ),
          ],
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Schätzung speichern'),
              onPressed: () => _save(context, ref, db, type, state),
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(category: widget.question.category),
        ],
      ),
    );
  }

  String? _validate(EstimateFormState state, String type) {
    if (type == 'binary' && state.binaryChoice == null) {
      return 'Bitte wähle Ja oder Nein.';
    }
    if (type == 'factual' && state.binaryChoice == null) {
      return 'Bitte wähle Wahr oder Falsch.';
    }
    if (type == 'interval') {
      final lower = double.tryParse(state.lowerBoundText.replaceAll(',', '.'));
      final upper = double.tryParse(state.upperBoundText.replaceAll(',', '.'));
      if (lower == null || upper == null) {
        return 'Bitte gib gültige Zahlen für beide Grenzen ein.';
      }
      if (lower >= upper) {
        return 'Die untere Grenze muss kleiner als die obere sein.';
      }
    }
    return null;
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    AppDatabase db,
    String type,
    EstimateFormState state,
  ) async {
    final error = _validate(state, type);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final probability = computeEstimateProbability(state, type);
    drift.Value<double?> lowerBound = const drift.Value(null);
    drift.Value<double?> upperBound = const drift.Value(null);
    drift.Value<bool?> binaryChoice = const drift.Value(null);
    drift.Value<String?> unit = const drift.Value(null);

    if (type == 'binary' || type == 'factual') {
      binaryChoice = drift.Value(state.binaryChoice!);
    } else if (type == 'interval') {
      final lower = double.parse(state.lowerBoundText.replaceAll(',', '.'));
      final upper = double.parse(state.upperBoundText.replaceAll(',', '.'));
      lowerBound = drift.Value(lower);
      upperBound = drift.Value(upper);
      final unitText =
          widget.question.unit ?? widget.existingEstimate?.unit ?? _unitController.text.trim();
      if (unitText.isNotEmpty) unit = drift.Value(unitText);
    }

    await db.upsertEstimate(
      EstimatesCompanion.insert(
        questionId: widget.question.id,
        probability: probability,
        confidenceLevel: drift.Value(state.confidenceLevel),
        lowerBound: lowerBound,
        upperBound: upperBound,
        binaryChoice: binaryChoice,
        unit: unit,
      ),
    );

    final resolution = await db.getResolutionForQuestion(widget.question.id);
    if (resolution != null && context.mounted) {
      // Für Intervall-Typ: Outcome anhand der neuen Grenzen + gespeichertem
      // Messwert neu berechnen, da die ursprüngliche Auflösung andere Grenzen
      // hatte.
      bool effectiveOutcome = resolution.outcome;
      if (widget.question.predictionType == 'interval' &&
          resolution.numericOutcome != null) {
        final lower = lowerBound.value;
        final upper = upperBound.value;
        if (lower != null && upper != null) {
          final actual = resolution.numericOutcome!;
          effectiveOutcome = actual >= lower && actual <= upper;
          if (effectiveOutcome != resolution.outcome) {
            await db.updateResolutionOutcome(widget.question.id, effectiveOutcome);
          }
        }
      }
      if (!context.mounted) return;
      await _showFeedback(context, db, effectiveOutcome, probability, resolution);
      if (context.mounted) context.pop();
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schätzung gespeichert.')),
      );
      context.pop();
    }
  }

  Future<void> _showFeedback(
    BuildContext context,
    AppDatabase db,
    bool outcome,
    double probability,
    Resolution? resolution,
  ) async {
    final allViews = await db.getAllPredictionViews();
    if (!context.mounted) return;

    final resolved = allViews
        .where((v) => v.status == PredictionStatus.resolved)
        .toList();
    final type = widget.question.predictionType;

    List<({double probability, double outcome})> toPairs(
            List<PredictionView> views) =>
        views.map(CalibrationStats.pairFor).toList();

    final overallStats = CalibrationStats.compute(toPairs(resolved));
    final typeResolved =
        resolved.where((v) => v.question.predictionType == type).toList();
    final typeStats = CalibrationStats.compute(toPairs(typeResolved));

    final estimate = await db.getEstimateForQuestion(widget.question.id);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CalibrationFeedbackSheet(
        outcome: outcome,
        estimate: estimate,
        predictionType: type,
        overallStats: overallStats,
        typeStats: typeStats,
        resolution: resolution,
      ),
    );
  }
}

// --- Info Card ---

class _InfoCard extends StatelessWidget {
  final String category;

  const _InfoCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final isEpistemic = category == 'epistemic';
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isEpistemic ? Icons.book_outlined : Icons.casino_outlined,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isEpistemic
                    ? 'Epistemische Fragen haben eine feststehende Antwort – deine Unsicherheit betrifft dein Wissen.'
                    : 'Aleatorische Ereignisse sind zufällig – kein Wissen kann die Unsicherheit vollständig auflösen.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
