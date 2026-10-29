import 'package:flutter/material.dart';
import 'audience_contracts.dart';
import 'opportunities_view.dart' show AnalyticsTranslate;

/// Host action offered on a report that is not ready (open settings, show
/// setup instructions…), chosen from the report's `reasonCode`.
class AudienceAction {
  const AudienceAction({required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
}

typedef AudienceActionFor = AudienceAction? Function(String reasonCode);

/// Read-only audience report. Hosts supply semantic spacing and their own
/// Material theme; every figure is an anonymous aggregate from the backend.
class AudienceReportView extends StatelessWidget {
  const AudienceReportView({
    super.key,
    required this.report,
    required this.translate,
    required this.inset,
    required this.gap,
    this.maxRows = 10,
    this.actionFor,
  });
  final AudienceReport report;
  final AnalyticsTranslate translate;
  final double inset, gap;
  final int maxRows;

  /// Optional host action for a report that is not ready.
  final AudienceActionFor? actionFor;

  @override
  Widget build(BuildContext context) {
    final tr = translate;
    final theme = Theme.of(context);
    final overview = report.overview;
    final reasonCode = report.reasonCode;
    final action = reasonCode == null ? null : actionFor?.call(reasonCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr('How your content is read'), style: theme.textTheme.titleLarge),
        SizedBox(height: gap),
        if (report.isReady)
          Text(
            tr('Anonymous aggregates; small groups are hidden and counts are rounded.'),
            style: theme.textTheme.bodySmall,
          )
        else
          _NotReadyCard(
            report: report,
            action: action,
            translate: tr,
            inset: inset,
            gap: gap,
          ),
        if (report.traffic case final traffic?)
          _Section(
            title: tr('Site traffic'),
            empty: '',
            gap: gap,
            children: [
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _StatCard(
                    inset: inset,
                    child: _Stat(label: tr('Page views'), value: _count(traffic.pageviews)),
                  ),
                  _StatCard(
                    inset: inset,
                    child: _Stat(label: tr('Pages viewed'), value: '${traffic.uniquePages}'),
                  ),
                ],
              ),
              for (final page in traffic.topPages.take(maxRows))
                _Row(title: page.path, subtitle: '${_count(page.views)} ${tr('views')}'),
            ],
          ),
        if (report.isReady && overview != null) ...[
          SizedBox(height: gap),
          Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              _Stat(label: tr('Visitors'), value: _count(overview.visitors)),
              _Stat(label: tr('Returning visitors'), value: _count(overview.returningVisitors)),
              _Stat(label: tr('Visits'), value: _count(overview.visits)),
              _Stat(label: tr('Page views'), value: _count(overview.pageviews)),
              if (overview.pagesPerVisit != null)
                _Stat(label: tr('Pages per visit'), value: overview.pagesPerVisit!.toStringAsFixed(1)),
              if (overview.avgEngagedSeconds != null)
                _Stat(label: tr('Attention time'), value: _duration(overview.avgEngagedSeconds!)),
            ].map((stat) => _StatCard(inset: inset, child: stat)).toList(),
          ),
          _Section(
            title: tr('What gets read'),
            empty: tr('No page reaches the anonymity threshold yet.'),
            gap: gap,
            children: [
              for (final page in report.pages.take(maxRows))
                _Row(
                  title: page.path,
                  subtitle: [
                    '${_count(page.visitors)} ${tr('visitors')}',
                    if (page.avgEngagedSeconds != null) _duration(page.avgEngagedSeconds!),
                    if (page.reached75 != null) '${_percent(page.reached75!)} ${tr('read to 75 %')}',
                  ].join(' · '),
                  semantic: page.reached75,
                ),
            ],
          ),
          _Section(
            title: tr('Pages that bring readers back'),
            empty: tr('Not enough first visits to compare yet.'),
            gap: gap,
            children: [
              for (final item in report.returns.take(maxRows))
                _Row(
                  title: item.path,
                  subtitle:
                      '${_percent(item.returnRate)} ${tr('came back')} · ${_count(item.firstVisitVisitors)} ${tr('first visits')}',
                  semantic: item.returnRate,
                ),
            ],
          ),
          _Section(
            title: tr('Common paths'),
            empty: tr('No path is frequent enough to show.'),
            gap: gap,
            children: [
              for (final item in report.transitions.take(maxRows))
                _Row(
                  title: '${item.fromPath} → ${item.toPath}',
                  subtitle: '${_count(item.visitors)} ${tr('visitors')}',
                ),
            ],
          ),
          _Section(
            title: tr('Authors'),
            empty: tr('No author reaches the anonymity threshold yet.'),
            gap: gap,
            children: [for (final item in report.authors.take(maxRows)) _groupRow(item, tr)],
          ),
          if (report.categories.isNotEmpty)
            _Section(
              title: tr('Categories'),
              empty: '',
              gap: gap,
              children: [for (final item in report.categories.take(maxRows)) _groupRow(item, tr)],
            ),
          _Section(
            title: tr('Clicks'),
            empty: tr('No outbound link, download or tracked button yet.'),
            gap: gap,
            children: [
              for (final item in report.clicks.take(maxRows))
                _Row(
                  title: [item.label, item.target].whereType<String>().join(' · '),
                  subtitle: '${_count(item.visitors)} ${tr('visitors')}',
                ),
            ],
          ),
          if (report.campaigns.isNotEmpty)
            _Section(
              title: tr('Campaigns (visitors who consented)'),
              empty: '',
              gap: gap,
              children: [
                for (final item in report.campaigns.take(maxRows))
                  _Row(
                    title: [item.source, item.medium, item.campaign].whereType<String>().join(' / '),
                    subtitle: '${_count(item.visitors)} ${tr('visitors')}',
                  ),
              ],
            ),
        ],
        if (report.isReady && report.limitations.isNotEmpty) ...[
          SizedBox(height: gap),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(tr('Measurement limits')),
            children: [
              for (final value in report.limitations)
                ListTile(contentPadding: EdgeInsets.zero, title: Text(tr(value))),
            ],
          ),
        ],
      ],
    );
  }

  Widget _groupRow(AudienceGroup item, AnalyticsTranslate tr) => _Row(
    title: item.key,
    subtitle: [
      '${_count(item.visitors)} ${tr('visitors')}',
      '${_count(item.views)} ${tr('views')}',
      if (item.avgEngagedSeconds != null) _duration(item.avgEngagedSeconds!),
    ].join(' · '),
  );
}

/// Counts are already rounded to tens by the backend: shown as "≈ 120".
String _count(int value) => '≈ $value';

String _percent(double ratio) => '${(ratio * 100).round()} %';

String _duration(double seconds) {
  final total = seconds.round();
  if (total < 60) return '$total s';
  return '${total ~/ 60} min ${(total % 60).toString().padLeft(2, '0')} s';
}

/// Not-ready state: what is missing, why, and the host's next step.
class _NotReadyCard extends StatelessWidget {
  const _NotReadyCard({
    required this.report,
    required this.action,
    required this.translate,
    required this.inset,
    required this.gap,
  });
  final AudienceReport report;
  final AudienceAction? action;
  final AnalyticsTranslate translate;
  final double inset, gap;

  @override
  Widget build(BuildContext context) {
    final tr = translate;
    final theme = Theme.of(context);
    final (icon, headline) = switch (report.reasonCode) {
      'no_domain' => (Icons.language_outlined, 'Add your site to this project'),
      'domain_unverified' => (Icons.verified_outlined, "Verify your site's domain"),
      'no_tracker' => (Icons.insights_outlined, 'No visit measured yet'),
      'legacy_tracker_only' => (Icons.update_outlined, 'Switch to the audience tracker'),
      'below_threshold' => (Icons.groups_outlined, 'Not enough visitors yet'),
      _ => (Icons.insights_outlined, 'No audience data yet'),
    };
    final action = this.action;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(inset),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(icon, color: theme.colorScheme.primary)),
            SizedBox(width: inset),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(headline), style: theme.textTheme.titleMedium),
                  if (report.reason case final reason?) ...[
                    SizedBox(height: gap / 2),
                    Text(
                      tr(reason),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (action != null) ...[
                    SizedBox(height: gap),
                    FilledButton.icon(
                      onPressed: action.onPressed,
                      icon: Icon(action.icon ?? Icons.arrow_forward_rounded),
                      label: Text(action.label),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: theme.textTheme.titleLarge),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.inset, required this.child});
  final double inset;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Card(child: Padding(padding: EdgeInsets.all(inset), child: child));
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.empty,
    required this.gap,
    required this.children,
  });
  final String title, empty;
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: gap * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(title, style: theme.textTheme.titleMedium)),
          if (children.isEmpty && empty.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: gap),
              child: Text(empty, style: theme.textTheme.bodySmall),
            ),
          ...children,
        ],
      ),
    );
  }
}

/// One aggregate row; [semantic] (0..1) adds a progress bar with its value
/// already spelled out in [subtitle], so color is never the only signal.
class _Row extends StatelessWidget {
  const _Row({required this.title, required this.subtitle, this.semantic});
  final String title, subtitle;
  final double? semantic;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title, maxLines: 2, overflow: TextOverflow.fade, softWrap: true),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(subtitle),
        if (semantic != null)
          ExcludeSemantics(child: LinearProgressIndicator(value: semantic)),
      ],
    ),
  );
}
