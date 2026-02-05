import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/trip_controller.dart';
import '../widgets/section_header.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  String _category = _categories.first;
  double _severity = 3;
  final TextEditingController _descriptionController = TextEditingController();

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

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TripController>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeader(title: 'Incident Report'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      final isSelected = _category == category;
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _category = category;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Severity: ${_severity.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: _severity,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _severity.toStringAsFixed(0),
                    onChanged: (value) {
                      setState(() {
                        _severity = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: controller.isTracking
                        ? () async {
                            await controller.addReport(
                              category: _category,
                              severity: _severity.round(),
                              description: _descriptionController.text,
                            );
                            if (!context.mounted) return;
                            _descriptionController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Report saved locally.'),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Report'),
                  ),
                  if (!controller.isTracking)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Start a trip to submit reports.'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
