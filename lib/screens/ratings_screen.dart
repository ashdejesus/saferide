import 'package:flutter/material.dart';

import '../widgets/section_header.dart';

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  double _driverRating = 3;
  double _vehicleRating = 3;
  double _routeRating = 3;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeader(title: 'Rate Your Experience'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(
                    Icons.star_rounded,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                _RatingRow(
                  icon: Icons.person,
                  label: 'Driver',
                  rating: _driverRating,
                  onChanged: (value) {
                    setState(() {
                      _driverRating = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _RatingRow(
                  icon: Icons.directions_bus,
                  label: 'Vehicle Condition',
                  rating: _vehicleRating,
                  onChanged: (value) {
                    setState(() {
                      _vehicleRating = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _RatingRow(
                  icon: Icons.route,
                  label: 'Route & Timing',
                  rating: _routeRating,
                  onChanged: (value) {
                    setState(() {
                      _routeRating = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Text('Additional Feedback', style: textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Share your experience (optional)',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      // TODO: Submit ratings
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for your feedback!'),
                        ),
                      );
                      setState(() {
                        _driverRating = 3;
                        _vehicleRating = 3;
                        _routeRating = 3;
                        _feedbackController.clear();
                      });
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Submit Feedback'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text('Your Ratings Help', style: textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Your feedback helps improve service quality and ensures safer rides for everyone in the community.',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.icon,
    required this.label,
    required this.rating,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double rating;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurface),
            const SizedBox(width: 8),
            Text(label, style: textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: _getLabelForRating(rating),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 40,
              child: Text(
                rating.toStringAsFixed(0),
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < rating.floor() ? Icons.star : Icons.star_border,
              color: colorScheme.primary,
              size: 24,
            );
          }),
        ),
      ],
    );
  }

  String _getLabelForRating(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Poor';
    return 'Very Poor';
  }
}
