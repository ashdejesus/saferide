import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/passenger_trust_metrics.dart';
import '../services/passenger_reporting_service.dart';
import '../state/trip_controller.dart';
import '../widgets/section_header.dart';
import '../widgets/split_button.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  String? _category;
  double _severity = 3;
  final TextEditingController _descriptionController = TextEditingController();
  late final AnimationController _animationController;
  late final PassengerReportingService _reportingService;
  PassengerTrustMetrics? _userTrustMetrics;

  static const List<String> _categories = [
    'Speeding',
    'Reckless Overtaking',
    'Sudden Braking',
    'Sharp Turning',
    'Overcrowding',
    'Harassment / Security',
    'Vehicle Condition',
    'Other',
  ];

  StreamSubscription<PassengerTrustMetrics?>? _trustMetricsSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _reportingService = PassengerReportingService();
    _startListeningToTrustMetrics();
  }

  void _startListeningToTrustMetrics() {
    final user = FirebaseAuth.instance.currentUser;
    final passengerId = user?.uid ?? 'guest_user';
    _trustMetricsSubscription = _reportingService
        .streamPassengerTrustMetrics(passengerId)
        .listen((metrics) {
      if (mounted) {
        setState(() {
          _userTrustMetrics = metrics;
        });
      }
    });
  }

  @override
  void dispose() {
    _trustMetricsSubscription?.cancel();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = context.watch<TripController>();
    final colorScheme = Theme.of(context).colorScheme;

    final items = <Widget>[
      const SectionHeader(title: 'Incident Report'),
      _IntroCard(isTracking: controller.isTracking),
      _TrustMetricsCard(
        metrics: _userTrustMetrics ??
            PassengerTrustMetrics(
              passengerId: 'demo_user',
              totalReports: 5,
              consistencyScore: 0.85,
              anomalyScore: 0.1,
              sensorAlignmentScore: 0.90,
              overallTrust: 0.88,
              lastUpdated: DateTime.now(),
              verifiedCount: 4,
              flaggedCount: 0,
            ),
      ),
      _ReportFormCard(
        formKey: _formKey,
        categories: _categories,
        category: _category,
        severity: _severity,
        descriptionController: _descriptionController,
        isTracking: controller.isTracking,
        onCategoryChanged: (value) {
          setState(() {
            _category = value;
          });
        },
        onSeverityChanged: (value) {
          setState(() {
            _severity = value;
          });
        },
        onSave: controller.isTracking
            ? () async {
                if (_category == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an incident category.')),
                  );
                  return;
                }
                await controller.addReport(
                  category: _category!,
                  severity: _severity.round(),
                  description: _descriptionController.text,
                );
                if (!context.mounted) return;
                _descriptionController.clear();
                setState(() {
                  _severity = 3;
                  _category = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report submitted and syncing to community.'),
                  ),
                );
              }
            : null,
        controller: controller,
        onReset: () {
          setState(() {
            _descriptionController.clear();
            _severity = 3;
            _category = null;
          });
        },
      ),
      if (!controller.isTracking)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Start a trip to submit reports.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      _ReportingGuidelinesCard(),
      const SizedBox(height: 80),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (var i = 0; i < items.length; i++)
          _StaggeredItem(
            index: i,
            animation: _animationController,
            child: Padding(
              padding: EdgeInsets.only(bottom: i == 0 ? 12 : 16),
              child: items[i],
            ),
          ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.isTracking});

  final bool isTracking;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.report,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capture what happened',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isTracking
                        ? 'Reports are tied to your current trip.'
                        : 'Start a trip to enable reporting.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustMetricsCard extends StatelessWidget {
  const _TrustMetricsCard({required this.metrics});

  final PassengerTrustMetrics metrics;

  Color _getTrustColor(double trust) {
    if (trust >= 0.8) return Colors.green;
    if (trust >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getTrustLabel(double trust) {
    if (trust >= 0.8) return 'Highly Trusted';
    if (trust >= 0.6) return 'Trusted';
    if (trust >= 0.4) return 'Moderate Trust';
    return 'Building Trust';
  }

  @override
  Widget build(BuildContext context) {
    final trustColor = _getTrustColor(metrics.overallTrust);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: trustColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.verified_user, color: trustColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Trust Score',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTrustLabel(metrics.overallTrust),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: trustColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(metrics.overallTrust * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: trustColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _TrustMetricRow(
              label: 'Consistency',
              value: metrics.consistencyScore,
              icon: Icons.timeline,
            ),
            const SizedBox(height: 12),
            _TrustMetricRow(
              label: 'Alignment with Sensors',
              value: metrics.sensorAlignmentScore,
              icon: Icons.sensors,
            ),
            const SizedBox(height: 12),
            _TrustMetricRow(
              label: 'Anomaly Detection',
              value: 1.0 - metrics.anomalyScore,
              icon: Icons.notification_important,
            ),
            if (metrics.totalReports > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 12,
                  children: [
                    Chip(
                      label: Text('${metrics.totalReports} reports'),
                      avatar: Icon(Icons.assignment, size: 18),
                    ),
                    Chip(
                      label: Text('${metrics.verifiedCount} verified'),
                      avatar: Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Colors.green,
                      ),
                    ),
                    if (metrics.flaggedCount > 0)
                      Chip(
                        label: Text('${metrics.flaggedCount} flagged'),
                        avatar: Icon(
                          Icons.flag,
                          size: 18,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrustMetricRow extends StatelessWidget {
  const _TrustMetricRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final double value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).toStringAsFixed(0);
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: value, minHeight: 6),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$percentage%',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ReportingGuidelinesCard extends StatelessWidget {
  const _ReportingGuidelinesCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Reporting Tips',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _GuidelineItem(
              title: 'Be Accurate',
              description: 'Accurate reports build your trust score.',
            ),
            const SizedBox(height: 10),
            _GuidelineItem(
              title: 'Stay Consistent',
              description:
                  'Consistent reporting patterns increase community trust.',
            ),
            const SizedBox(height: 10),
            _GuidelineItem(
              title: 'Add Details',
              description: 'More context helps validate your report.',
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidelineItem extends StatelessWidget {
  const _GuidelineItem({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportFormCard extends StatelessWidget {
  const _ReportFormCard({
    required this.formKey,
    required this.categories,
    required this.category,
    required this.severity,
    required this.descriptionController,
    required this.isTracking,
    required this.onCategoryChanged,
    required this.onSeverityChanged,
    required this.onSave,
    required this.controller,
    required this.onReset,
  });

  final GlobalKey<FormState> formKey;
  final List<String> categories;
  final String? category;
  final double severity;
  final TextEditingController descriptionController;
  final bool isTracking;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<double> onSeverityChanged;
  final Future<void> Function()? onSave;
  final TripController controller;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((item) {
                  final isSelected = category == item;
                  return FilterChip(
                    label: Text(item),
                    selected: isSelected,
                    onSelected: (_) => onCategoryChanged(item),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Severity: ${severity.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: [
                  for (var value = 1; value <= 5; value++)
                    ButtonSegment<int>(
                      value: value,
                      label: Text(value.toString()),
                    ),
                ],
                selected: {severity.round()},
                onSelectionChanged: (selection) {
                  if (selection.isNotEmpty) {
                    onSeverityChanged(selection.first.toDouble());
                  }
                },
              ),
              const SizedBox(height: 8),
              Slider(
                value: severity,
                min: 1,
                max: 5,
                divisions: 4,
                label: severity.toStringAsFixed(0),
                onChanged: onSeverityChanged,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
              ),
              const SizedBox(height: 20),
              SplitButton(
                label: 'Save Report',
                icon: Icons.save,
                size: SplitButtonSize.medium,
                enabled: isTracking,
                onPressed: isTracking && onSave != null
                    ? () async {
                        await onSave!();
                      }
                    : null,
                menuItems: [
                  SplitButtonMenuItem(
                    label: 'Save & clear form',
                    icon: Icons.refresh,
                    onPressed: () async {
                      if (isTracking && onSave != null) {
                        await onSave!();
                      }
                    },
                  ),
                  SplitButtonMenuItem(
                    label: 'Reset form',
                    icon: Icons.clear,
                    onPressed: onReset,
                  ),
                  SplitButtonMenuItem(
                    label: 'Save as critical',
                    icon: Icons.warning,
                    onPressed: () async {
                      if (isTracking) {
                        if (category == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select an incident category.')),
                          );
                          return;
                        }
                        await controller.addReport(
                          category: category!,
                          severity: 5,
                          description: descriptionController.text,
                        );
                        onReset();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaggeredItem extends StatelessWidget {
  const _StaggeredItem({
    required this.index,
    required this.animation,
    required this.child,
  });

  final int index;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = 0.08 * index;
    final end = (start + 0.6).clamp(0.0, 1.0).toDouble();
    final intervalStart = start.clamp(0.0, 1.0).toDouble();
    final curve = CurvedAnimation(
      parent: animation,
      curve: Interval(intervalStart, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
}
