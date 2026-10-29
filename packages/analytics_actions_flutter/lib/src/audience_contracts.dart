/// `shipglows.audience.v1`: first-party audience report of a project.
///
/// Produced by `GET /api/analytics/report` (ContentGlows) from the
/// `@shipglows/astro-engine/analytics` tracker. Every figure is an anonymous
/// aggregate: groups under [AudienceReport.minGroupVisitors] are left out and
/// counts are rounded to the nearest ten by the backend. Paths and labels are
/// untrusted site data, shown as text only.
library;

const audienceSchemaVersion = 'shipglows.audience.v1';
const _maxRows = 200;

const _invalid = FormatException('Invalid or unsupported audience report');

void _keys(Map<String, dynamic> value, Set<String> allowed) {
  if (value.keys.any((key) => !allowed.contains(key))) throw _invalid;
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) throw _invalid;
  return Map<String, dynamic>.from(value);
}

String _text(Object? value, int max) {
  if (value is! String || value.isEmpty || value.length > max) throw _invalid;
  return value;
}

String? _optionalText(Object? value, int max) =>
    value == null ? null : _text(value, max);

int _count(Object? value) {
  if (value is! num || !value.isFinite || value < 0 || value != value.roundToDouble()) {
    throw _invalid;
  }
  return value.toInt();
}

double? _number(Object? value, {double? max}) {
  if (value == null) return null;
  if (value is! num || !value.isFinite || value < 0) throw _invalid;
  if (max != null && value > max) throw _invalid;
  return value.toDouble();
}

List<T> _rows<T>(Object? value, T Function(Map<String, dynamic>) parse) {
  if (value is! List || value.length > _maxRows) throw _invalid;
  return value.map((row) => parse(_map(row))).toList(growable: false);
}

class AudienceOverview {
  const AudienceOverview({
    required this.visitors,
    required this.newVisitors,
    required this.returningVisitors,
    required this.visits,
    required this.pageviews,
    this.visitsPerVisitor,
    this.pagesPerVisit,
    this.avgEngagedSeconds,
  });
  final int visitors, newVisitors, returningVisitors, visits, pageviews;
  final double? visitsPerVisitor, pagesPerVisit, avgEngagedSeconds;

  factory AudienceOverview.fromJson(Map<String, dynamic> json) {
    _keys(json, {
      'visitors',
      'newVisitors',
      'returningVisitors',
      'visits',
      'pageviews',
      'visitsPerVisitor',
      'pagesPerVisit',
      'avgEngagedSeconds',
      'period',
    });
    return AudienceOverview(
      visitors: _count(json['visitors']),
      newVisitors: _count(json['newVisitors']),
      returningVisitors: _count(json['returningVisitors']),
      visits: _count(json['visits']),
      pageviews: _count(json['pageviews']),
      visitsPerVisitor: _number(json['visitsPerVisitor']),
      pagesPerVisit: _number(json['pagesPerVisit']),
      avgEngagedSeconds: _number(json['avgEngagedSeconds']),
    );
  }
}

class AudiencePage {
  const AudiencePage({
    required this.path,
    required this.visitors,
    required this.views,
    this.avgEngagedSeconds,
    this.reached25,
    this.reached50,
    this.reached75,
    this.reached100,
  });
  final String path;
  final int visitors, views;
  final double? avgEngagedSeconds, reached25, reached50, reached75, reached100;

  factory AudiencePage.fromJson(Map<String, dynamic> json) {
    _keys(json, {
      'path',
      'visitors',
      'views',
      'avgEngagedSeconds',
      'reached25',
      'reached50',
      'reached75',
      'reached100',
    });
    return AudiencePage(
      path: _text(json['path'], 2048),
      visitors: _count(json['visitors']),
      views: _count(json['views']),
      avgEngagedSeconds: _number(json['avgEngagedSeconds']),
      reached25: _number(json['reached25'], max: 1),
      reached50: _number(json['reached50'], max: 1),
      reached75: _number(json['reached75'], max: 1),
      reached100: _number(json['reached100'], max: 1),
    );
  }
}

/// Per author, category, page type or language.
class AudienceGroup {
  const AudienceGroup({
    required this.key,
    required this.visitors,
    required this.views,
    this.avgEngagedSeconds,
  });
  final String key;
  final int visitors, views;
  final double? avgEngagedSeconds;

  factory AudienceGroup.fromJson(Map<String, dynamic> json) {
    _keys(json, {'key', 'visitors', 'views', 'avgEngagedSeconds'});
    return AudienceGroup(
      key: _text(json['key'], 200),
      visitors: _count(json['visitors']),
      views: _count(json['views']),
      avgEngagedSeconds: _number(json['avgEngagedSeconds']),
    );
  }
}

class AudienceTransition {
  const AudienceTransition({
    required this.fromPath,
    required this.toPath,
    required this.visitors,
  });
  final String fromPath, toPath;
  final int visitors;

  factory AudienceTransition.fromJson(Map<String, dynamic> json) {
    _keys(json, {'fromPath', 'toPath', 'visitors'});
    return AudienceTransition(
      fromPath: _text(json['fromPath'], 2048),
      toPath: _text(json['toPath'], 2048),
      visitors: _count(json['visitors']),
    );
  }
}

/// Pages of a first visit, by how many of those visitors came back later.
class AudienceReturn {
  const AudienceReturn({
    required this.path,
    required this.firstVisitVisitors,
    required this.returnedVisitors,
    required this.returnRate,
  });
  final String path;
  final int firstVisitVisitors, returnedVisitors;
  final double returnRate;

  factory AudienceReturn.fromJson(Map<String, dynamic> json) {
    _keys(json, {'path', 'firstVisitVisitors', 'returnedVisitors', 'returnRate'});
    return AudienceReturn(
      path: _text(json['path'], 2048),
      firstVisitVisitors: _count(json['firstVisitVisitors']),
      returnedVisitors: _count(json['returnedVisitors']),
      returnRate: _number(json['returnRate'], max: 1)!,
    );
  }
}

/// Outbound host, download path or `data-sg-track` label.
class AudienceClick {
  const AudienceClick({this.target, this.label, required this.visitors});
  final String? target, label;
  final int visitors;

  factory AudienceClick.fromJson(Map<String, dynamic> json) {
    _keys(json, {'target', 'label', 'visitors'});
    final click = AudienceClick(
      target: _optionalText(json['target'], 500),
      label: _optionalText(json['label'], 100),
      visitors: _count(json['visitors']),
    );
    if (click.target == null && click.label == null) throw _invalid;
    return click;
  }
}

/// UTM acquisition, from visitors who accepted the site's consent banner.
class AudienceCampaign {
  const AudienceCampaign({
    this.source,
    this.medium,
    this.campaign,
    required this.visitors,
  });
  final String? source, medium, campaign;
  final int visitors;

  factory AudienceCampaign.fromJson(Map<String, dynamic> json) {
    _keys(json, {'source', 'medium', 'campaign', 'visitors'});
    return AudienceCampaign(
      source: _optionalText(json['source'], 200),
      medium: _optionalText(json['medium'], 200),
      campaign: _optionalText(json['campaign'], 200),
      visitors: _count(json['visitors']),
    );
  }
}

/// Page views of every tracker on the project's domains (legacy script
/// included): no visitor dimension, pages under 10 views hidden.
class AudienceTraffic {
  const AudienceTraffic({
    required this.pageviews,
    required this.uniquePages,
    required this.topPages,
  });
  final int pageviews, uniquePages;
  final List<AudienceTrafficPage> topPages;

  factory AudienceTraffic.fromJson(Map<String, dynamic> json) {
    _keys(json, {'pageviews', 'uniquePages', 'topPages'});
    return AudienceTraffic(
      pageviews: _count(json['pageviews']),
      uniquePages: _count(json['uniquePages']),
      topPages: _rows(json['topPages'], AudienceTrafficPage.fromJson),
    );
  }
}

class AudienceTrafficPage {
  const AudienceTrafficPage({required this.path, required this.views});
  final String path;
  final int views;

  factory AudienceTrafficPage.fromJson(Map<String, dynamic> json) {
    _keys(json, {'path', 'views'});
    return AudienceTrafficPage(
      path: _text(json['path'], 2048),
      views: _count(json['views']),
    );
  }
}

class AudienceReport {
  const AudienceReport({
    required this.projectId,
    required this.period,
    required this.status,
    required this.generatedAt,
    required this.minGroupVisitors,
    required this.pages,
    required this.authors,
    required this.categories,
    required this.transitions,
    required this.returns,
    required this.clicks,
    required this.campaigns,
    required this.limitations,
    this.overview,
    this.traffic,
    this.reason,
  });

  final String projectId, period;

  /// `ready`, `empty` (no tracked visit) or `insufficient` (fewer visitors
  /// than [minGroupVisitors]: figures stay hidden to remain anonymous).
  final String status;
  final DateTime generatedAt;
  final int minGroupVisitors;

  /// Why the report is `empty` or `insufficient`, when the backend knows.
  final String? reason;
  final AudienceTraffic? traffic;
  final AudienceOverview? overview;
  final List<AudiencePage> pages;
  final List<AudienceGroup> authors, categories;
  final List<AudienceTransition> transitions;
  final List<AudienceReturn> returns;
  final List<AudienceClick> clicks;
  final List<AudienceCampaign> campaigns;
  final List<String> limitations;

  bool get isReady => status == 'ready';

  factory AudienceReport.fromJson(Map<String, dynamic> json) {
    _keys(json, {
      'schemaVersion',
      'projectId',
      'period',
      'status',
      'generatedAt',
      'minGroupVisitors',
      'reason',
      'traffic',
      'overview',
      'pages',
      'authors',
      'categories',
      'transitions',
      'returns',
      'clicks',
      'campaigns',
      'limitations',
    });
    if (json['schemaVersion'] != audienceSchemaVersion) {
      throw const FormatException('Unsupported audience contract');
    }
    final status = json['status'];
    if (!const {'ready', 'empty', 'insufficient'}.contains(status)) {
      throw _invalid;
    }
    final generatedAt = DateTime.tryParse(_text(json['generatedAt'], 40));
    if (generatedAt == null) throw _invalid;
    final limitations = json['limitations'];
    if (limitations is! List || limitations.length > 20) throw _invalid;
    return AudienceReport(
      projectId: _text(json['projectId'], 128),
      period: _text(json['period'], 8),
      status: status as String,
      generatedAt: generatedAt.toUtc(),
      minGroupVisitors: _count(json['minGroupVisitors']),
      reason: _optionalText(json['reason'], 500),
      traffic: json['traffic'] == null
          ? null
          : AudienceTraffic.fromJson(_map(json['traffic'])),
      overview: json['overview'] == null
          ? null
          : AudienceOverview.fromJson(_map(json['overview'])),
      pages: _rows(json['pages'], AudiencePage.fromJson),
      authors: _rows(json['authors'], AudienceGroup.fromJson),
      categories: _rows(json['categories'], AudienceGroup.fromJson),
      transitions: _rows(json['transitions'], AudienceTransition.fromJson),
      returns: _rows(json['returns'], AudienceReturn.fromJson),
      clicks: _rows(json['clicks'], AudienceClick.fromJson),
      campaigns: _rows(json['campaigns'], AudienceCampaign.fromJson),
      limitations: limitations.map((value) => _text(value, 500)).toList(growable: false),
    );
  }
}
