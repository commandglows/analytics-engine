import 'package:flutter/material.dart';
import 'contracts.dart';

typedef AnalyticsPrepare =
    Future<void> Function(AnalyticsOpportunity opportunity);
typedef AnalyticsTranslate = String Function(String message);

/// Hosts supply semantic spacing and their own Material theme.
class AnalyticsOpportunitiesView extends StatefulWidget {
  const AnalyticsOpportunitiesView({
    super.key,
    required this.snapshot,
    required this.onPrepare,
    required this.translate,
    required this.inset,
    required this.gap,
    this.onError,
  });
  final AnalyticsSnapshot snapshot;
  final AnalyticsPrepare onPrepare;
  final AnalyticsTranslate translate;
  final double inset, gap;
  final void Function(Object error)? onError;

  @override
  State<AnalyticsOpportunitiesView> createState() =>
      _AnalyticsOpportunitiesViewState();
}

class _AnalyticsOpportunitiesViewState
    extends State<AnalyticsOpportunitiesView> {
  String? _preparing;
  String? _failed;

  @override
  void didUpdateWidget(covariant AnalyticsOpportunitiesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot.projectId != widget.snapshot.projectId ||
        oldWidget.snapshot.snapshotId != widget.snapshot.snapshotId) {
      _preparing = null;
      _failed = null;
    }
  }

  Future<void> _prepare(AnalyticsOpportunity item) async {
    final snapshot = widget.snapshot;
    setState(() {
      _preparing = item.id;
      _failed = null;
    });
    try {
      await widget.onPrepare(item);
    } catch (error) {
      if (mounted && identical(widget.snapshot, snapshot)) {
        setState(() => _failed = item.id);
        widget.onError?.call(error);
      }
    } finally {
      if (mounted && identical(widget.snapshot, snapshot)) {
        setState(() => _preparing = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final tr = widget.translate;
    final theme = Theme.of(context);
    final stateLabel = switch (snapshot.status) {
      'stale' => 'These measurements need a new sync before preparing a brief.',
      'partial' =>
        'These measurements are partial. Wait for complete evidence.',
      'empty' =>
        'Sync Search Console to discover opportunities for this project.',
      _ =>
        snapshot.opportunities.isEmpty
            ? 'No supported opportunity in this snapshot. No change is recommended.'
            : 'Choose one improvement to prepare. Nothing is published.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr('Where to focus'), style: theme.textTheme.titleLarge),
        SizedBox(height: widget.gap),
        Text(tr(stateLabel)),
        if (snapshot.generatedAt != null)
          Text(
            '${tr('Snapshot')}: ${snapshot.generatedAt!.toIso8601String()}',
            style: theme.textTheme.bodySmall,
          ),
        for (final item in snapshot.opportunities) ...[
          SizedBox(height: widget.gap),
          Card(
            child: Padding(
              padding: EdgeInsets.all(widget.inset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(item.title, style: theme.textTheme.titleMedium),
                  SizedBox(height: widget.gap),
                  Text(item.summary),
                  if (item.url != null) SelectableText(item.url!),
                  Text(
                    tr(
                      'Hypothesis to review; no causal improvement is proven.',
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(tr('See evidence')),
                    children: [
                      for (final evidence in item.evidence)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${evidence.metric}: ${evidence.displayValue}',
                          ),
                          subtitle: Text(
                            '${evidence.sourceLabel} · ${evidence.start} → ${evidence.end}',
                          ),
                        ),
                    ],
                  ),
                  if (item.blockedReason != null && !item.canPrepare)
                    Text(tr(item.blockedReason!)),
                  if (_failed == item.id)
                    Text(
                      tr('The brief could not be prepared. Try again.'),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton(
                      onPressed:
                          snapshot.canPrepare &&
                              item.canPrepare &&
                              _preparing == null
                          ? () => _prepare(item)
                          : null,
                      child: Text(
                        _preparing == item.id
                            ? tr('Preparing…')
                            : tr('Prepare an improvement brief'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (snapshot.limitations.isNotEmpty) ...[
          SizedBox(height: widget.gap),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(tr('Measurement limits')),
            children: snapshot.limitations
                .map(
                  (value) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr(value)),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
