import 'package:flutter/material.dart';

import '../models/passenger_trust_metrics.dart';
import '../services/passenger_reporting_service.dart';
import '../widgets/section_header.dart';

/// Widget that displays passenger reporting summary and history
class PassengerReportingSummaryWidget extends StatefulWidget {
  const PassengerReportingSummaryWidget({super.key, required this.tripId});

  final int tripId;

  @override
  State<PassengerReportingSummaryWidget> createState() =>
      _PassengerReportingSummaryWidgetState();
}

class _PassengerReportingSummaryWidgetState
    extends State<PassengerReportingSummaryWidget> {
  late final PassengerReportingService _reportingService;

  @override
  void initState() {
    super.initState();
    _reportingService = PassengerReportingService();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: 'Community Reports'),
        StreamBuilder<List<ReportWithTrust>>(
          stream: _reportingService.getReportsForTrip(widget.tripId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Error loading reports: ${snapshot.error}'),
              );
            }

            final reports = snapshot.data ?? [];

            if (reports.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No reports for this trip yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                return _ReportCard(report: reports[index]);
              },
            );
          },
        ),
      ],
    );
  }
}

class _ReportCard extends StatefulWidget {
  const _ReportCard({required this.report});

  final ReportWithTrust report;

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  late final PassengerReportingService _reportingService;
  bool _isExpanded = false;
  bool _isVerified = false;
  bool _isFlagged = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reportingService = PassengerReportingService();
    _isVerified = widget.report.isVerified;
    _isFlagged = widget.report.isFlagged;
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 5:
        return Colors.red;
      case 4:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 2:
        return Colors.yellow;
      default:
        return Colors.green;
    }
  }

  String _getSeverityLabel(int severity) {
    switch (severity) {
      case 5:
        return 'Critical';
      case 4:
        return 'High';
      case 3:
        return 'Medium';
      case 2:
        return 'Low';
      default:
        return 'Minimal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final severityColor = _getSeverityColor(widget.report.severity);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getSeverityLabel(widget.report.severity),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: severityColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.report.category,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Weighted severity: ${widget.report.weightedSeverity}/5',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() => _isExpanded = !_isExpanded);
                  },
                  child: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ),
              ],
            ),
            // Trust badge
            const SizedBox(height: 12),
            _TrustBadge(trust: widget.report.passengerTrust),
            // Expanded content
            if (_isExpanded) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              if (widget.report.description != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.report.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: !_isVerified && !_isLoading
                          ? () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );
                              try {
                                setState(() => _isLoading = true);
                                final reportId = widget.report.reportId
                                    .toString();
                                await _reportingService.verifyReport(reportId);
                                if (!mounted) return;
                                setState(() => _isVerified = true);
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Report verified and trust updated!',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            }
                          : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Verify'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: !_isFlagged && !_isLoading
                          ? () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );
                              try {
                                setState(() => _isLoading = true);
                                final reportId = widget.report.reportId
                                    .toString();
                                await _reportingService.flagReport(
                                  reportId,
                                  'Flagged by community member',
                                );
                                if (!mounted) return;
                                setState(() => _isFlagged = true);
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Report flagged for review.'),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            }
                          : null,
                      icon: const Icon(Icons.flag),
                      label: const Text('Flag'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.trust});

  final double trust;

  Color _getTrustColor() {
    if (trust >= 0.8) return Colors.green;
    if (trust >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getTrustLabel() {
    if (trust >= 0.8) return 'Highly Trusted';
    if (trust >= 0.6) return 'Trusted';
    return 'Unverified';
  }

  @override
  Widget build(BuildContext context) {
    final trustColor = _getTrustColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: trustColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: trustColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 14, color: trustColor),
          const SizedBox(width: 6),
          Text(
            _getTrustLabel(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: trustColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${(trust * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: trustColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget showing aggregate report statistics for a time period
class ReportStatisticsWidget extends StatefulWidget {
  const ReportStatisticsWidget({
    super.key,
    required this.startTime,
    required this.endTime,
  });

  final DateTime startTime;
  final DateTime endTime;

  @override
  State<ReportStatisticsWidget> createState() => _ReportStatisticsWidgetState();
}

class _ReportStatisticsWidgetState extends State<ReportStatisticsWidget> {
  late final PassengerReportingService _reportingService;

  @override
  void initState() {
    super.initState();
    _reportingService = PassengerReportingService();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reportingService.getReportStatistics(
        startTime: widget.startTime,
        endTime: widget.endTime,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Error loading statistics: ${snapshot.error}'),
          );
        }

        final stats = snapshot.data ?? {};
        final totalReports = stats['totalReports'] as int? ?? 0;
        final categories = stats['categories'] as Map<String, int>? ?? {};
        final avgSeverity = stats['averageSeverity'] as double? ?? 0.0;
        final totalVerifications = stats['totalVerifications'] as int? ?? 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBox(
                      label: 'Total Reports',
                      value: totalReports.toString(),
                      icon: Icons.assignment,
                    ),
                    _StatBox(
                      label: 'Avg Severity',
                      value: avgSeverity.toStringAsFixed(1),
                      icon: Icons.trending_up,
                    ),
                    _StatBox(
                      label: 'Verifications',
                      value: totalVerifications.toString(),
                      icon: Icons.check_circle,
                    ),
                  ],
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'By Category',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.entries.map((e) {
                      return Chip(label: Text('${e.key} (${e.value})'));
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
