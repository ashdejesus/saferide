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
    'Sudden Braking',
    'Sharp Turning',
    'Pothole',
    'Reckless Driving',
    'Accident',
    'Hazard',
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

    final recentEvent = controller.getRecentSensorEventCategory();
    final displayCategory = _category ?? recentEvent;
    final displaySeverity = _category == null && recentEvent != null
        ? 4.0
        : _severity;

    final items = <Widget>[
      const SectionHeader(title: 'Incident Report'),
      _IntroCard(isTracking: controller.isTracking),
      _TrustMetricsCard(
        metrics:
            _userTrustMetrics ??
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
        category: displayCategory,
        severity: displaySeverity,
        descriptionController: _descriptionController,
        isTracking: controller.isTracking,
        recentEvent: recentEvent,
        isAutoDetected: _category == null && recentEvent != null,
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
                final finalCategory = _category ?? recentEvent;
                if (finalCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select an incident category.'),
                    ),
                  );
                  return;
                }

                final int finalSeverity =
                    _category == null && recentEvent != null
                    ? 4
                    : _severity.round();

                final bool? confirm = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    final theme = Theme.of(context);
                    final colorScheme = theme.colorScheme;

                    Color severityColor;
                    if (finalSeverity >= 5) {
                      severityColor = Colors.red;
                    } else if (finalSeverity == 4) {
                      severityColor = Colors.orange;
                    } else if (finalSeverity == 3) {
                      severityColor = Colors.amber.shade700;
                    } else if (finalSeverity == 2) {
                      severityColor = Colors.lightGreen;
                    } else {
                      severityColor = Colors.green;
                    }

                    IconData catIcon = Icons.report;
                    switch (finalCategory) {
                      case 'Speeding':
                        catIcon = Icons.speed;
                        break;
                      case 'Sudden Braking':
                        catIcon = Icons.car_crash;
                        break;
                      case 'Sharp Turning':
                        catIcon = Icons.turn_sharp_right;
                        break;
                      case 'Pothole':
                        catIcon = Icons.moving;
                        break;
                      case 'Reckless Driving':
                        catIcon = Icons.warning_amber;
                        break;
                      case 'Accident':
                        catIcon = Icons.medical_services;
                        break;
                      case 'Hazard':
                        catIcon = Icons.construction;
                        break;
                    }

                    return SafeArea(
                      child: Container(
                        padding: EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 16,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: severityColor.withValues(alpha: 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, -8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.4,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: severityColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                catIcon,
                                size: 48,
                                color: severityColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Confirm Report',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.category,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      finalCategory,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.monitor_heart,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Severity: $finalSeverity of 5',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: List.generate(5, (index) {
                                            return Expanded(
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  right: 4,
                                                ),
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: index < finalSeverity
                                                      ? severityColor
                                                      : colorScheme
                                                            .outlineVariant
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_descriptionController.text.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.notes,
                                          size: 18,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Notes',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _descriptionController.text,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text('Edit'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.send, size: 18),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    label: const Text('Submit Report'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: severityColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );

                if (confirm != true) return;

                await controller.addReport(
                  category: finalCategory,
                  severity: finalSeverity,
                  description: _descriptionController.text,
                );
                if (!context.mounted) return;
                _descriptionController.clear();
                setState(() {
                  _severity = 3;
                  _category = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      controller.testMode
                          ? 'Test report simulated (not saved).'
                          : 'Report submitted and syncing to community.',
                    ),
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
    if (!isTracking) {
      return Card(
        color: colorScheme.errorContainer.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.error.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.location_off, color: colorScheme.error, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Required',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You must start a trip on the Dashboard to submit incident reports.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.report_gmailerrorred,
                color: colorScheme.onPrimaryContainer,
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
                    'Reports are tied to your current trip.',
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
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: trustColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: trustColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getTrustLabel(metrics.overallTrust),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: trustColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                TweenAnimationBuilder<double>(
                  key: ValueKey(metrics.overallTrust),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0.0, end: metrics.overallTrust),
                  builder: (context, val, _) => Text(
                    '${(val * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: trustColor,
                      fontWeight: FontWeight.bold,
                    ),
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
              icon: Icons.notifications,
            ),
            if (metrics.totalReports > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 12,
                  children: [
                    Chip(
                      label: Text('${metrics.totalReports} reports'),
                      avatar: const Icon(
                        Icons.assignment,
                        size: 16,
                        color: Colors.green,
                      ),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    ),
                    Chip(
                      label: Text('${metrics.verifiedCount} verified'),
                      avatar: const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
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
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(value),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0.0, end: value),
                  builder: (context, val, _) =>
                      LinearProgressIndicator(value: val, minHeight: 6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TweenAnimationBuilder<double>(
          key: ValueKey(value),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0.0, end: value),
          builder: (context, val, _) {
            final percentage = (val * 100).toStringAsFixed(0);
            return Text(
              '$percentage%',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            );
          },
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 20,
          ),
          leading: Icon(Icons.lightbulb_outline, color: colorScheme.primary),
          title: Text(
            'Reporting Guidelines',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          children: const [
            _GuidelineItem(
              title: 'Be Accurate',
              description: 'Accurate reports build your trust score.',
            ),
            SizedBox(height: 12),
            _GuidelineItem(
              title: 'Stay Consistent',
              description:
                  'Consistent reporting patterns increase community trust.',
            ),
            SizedBox(height: 12),
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
    this.recentEvent,
    this.isAutoDetected = false,
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
  final String? recentEvent;
  final bool isAutoDetected;

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
              Row(
                children: [
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: isAutoDetected
                        ? Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Container(
                              key: const ValueKey('auto-badge'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Auto-detected',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty-badge')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((item) {
                  final isSelected = category == item;

                  IconData icon = Icons.report;
                  switch (item) {
                    case 'Speeding':
                      icon = Icons.speed;
                      break;
                    case 'Sudden Braking':
                      icon = Icons.car_crash;
                      break;
                    case 'Sharp Turning':
                      icon = Icons.turn_sharp_right;
                      break;
                    case 'Pothole':
                      icon = Icons.moving;
                      break;
                    case 'Reckless Driving':
                      icon = Icons.warning_amber;
                      break;
                    case 'Accident':
                      icon = Icons.medical_services;
                      break;
                    case 'Hazard':
                      icon = Icons.construction;
                      break;
                  }

                  return ChoiceChip(
                    label: Text(item),
                    avatar: Icon(
                      icon,
                      size: 18,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (index) {
                  final val = index + 1;
                  final isSelected = severity.round() == val;
                  Color color;
                  if (val == 5)
                    color = Colors.red;
                  else if (val == 4)
                    color = Colors.orange;
                  else if (val == 3)
                    color = Colors.amber.shade700;
                  else if (val == 2)
                    color = Colors.lightGreen;
                  else
                    color = Colors.green;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onSeverityChanged(val.toDouble()),
                      child: Container(
                        margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color
                              : color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : color.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          val.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
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
                            const SnackBar(
                              content: Text(
                                'Please select an incident category.',
                              ),
                            ),
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
