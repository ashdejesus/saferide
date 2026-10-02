import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_database.dart';
import '../data/mock_routes.dart';
import '../models/trip.dart';
import '../models/passenger_trust_metrics.dart';
import '../state/trip_controller.dart';

class AlgoSimulatorScreen extends StatefulWidget {
  const AlgoSimulatorScreen({super.key});

  @override
  State<AlgoSimulatorScreen> createState() => _AlgoSimulatorScreenState();
}

class _AlgoSimulatorScreenState extends State<AlgoSimulatorScreen> {
  // ── Inputs ─────────────────────────────────────────────────────────────
  double _vehicleMultiplier = 0.75;
  double _roadCondition = 0.5;
  double _trafficDensity = 0.5;
  double _envNoise = 0.5;

  double _speed = 45.0;
  double _deceleration = 3.0;
  double _turning = 1.0;
  double _pothole = 2.0;

  bool _hasReport = false;
  double _rating = 1.0;
  double _trust = 0.8;

  // ── State variables for output ──────────────────────────────────────────
  double _mc = 1.0;
  double _speedLimit = 60.0;
  double _rSens = 0.0;
  double _rRep = 0.0;
  double _rTrip = 0.0;
  int _safetyScore = 100;
  final List<String> _logs = [];

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    _logs.clear();
    
    // Context Adjustments
    _mc = 1 + (0.3 * (1 - _roadCondition)) + (0.2 * _trafficDensity) + (0.1 * _envNoise);
    _logs.add('Context Multiplier (Mc) calculated as ${_mc.toStringAsFixed(2)}x');

    const baseSpeed = 60.0;
    const baseBrake = 4.0;
    const baseTurn = 2.0;
    const basePothole = 3.0;

    _speedLimit = baseSpeed * _vehicleMultiplier * _mc;
    final threshBrake = baseBrake * _vehicleMultiplier * _mc;
    final threshTurn = baseTurn * _vehicleMultiplier * _mc;
    final threshPothole = basePothole * _vehicleMultiplier * _mc;

    // Sensor Risk
    int eventsDetected = 0;
    double riskSum = 0;
    const wSpeed = 0.35, wBrake = 0.25, wTurn = 0.20, wPothole = 0.15;

    if (_speed > _speedLimit) {
      eventsDetected++;
      riskSum += wSpeed;
      _logs.add('⚠️ Overspeeding Detected (${_speed.toStringAsFixed(1)} > ${_speedLimit.toStringAsFixed(1)} km/h)');
    }
    if (_deceleration > threshBrake) {
      eventsDetected++;
      riskSum += wBrake;
      _logs.add('⚠️ Harsh Braking Detected (${_deceleration.toStringAsFixed(1)} > ${threshBrake.toStringAsFixed(1)} m/s²)');
    }
    if (_turning > threshTurn) {
      eventsDetected++;
      riskSum += wTurn;
      _logs.add('⚠️ Sharp Turn Detected (${_turning.toStringAsFixed(1)} > ${threshTurn.toStringAsFixed(1)} rad/s)');
    }
    if (_pothole > threshPothole) {
      eventsDetected++;
      riskSum += wPothole;
      _logs.add('⚠️ Pothole Impact Detected (${_pothole.toStringAsFixed(1)} > ${threshPothole.toStringAsFixed(1)} m/s²)');
    }

    _rSens = (riskSum / _mc).clamp(0.0, 1.0);
    _logs.add('Sensor Events: $eventsDetected. Base Risk Sum: ${riskSum.toStringAsFixed(2)}');
    _logs.add('R_sens (adjusted by Mc): ${_rSens.toStringAsFixed(2)}');

    // Report Risk & Fusion
    double lambda = 1.0;
    double penalty = 0;
    
    if (_hasReport) {
      final normalizedRating = (_rating - 1) / 4.0;
      _rRep = normalizedRating * _trust;
      
      lambda = max(0.2, 1.0 - (0.2 * 1)); 
      
      penalty = 0.2 * (_rSens - _rRep).abs();
      
      _logs.add('R_rep calculated as ${_rRep.toStringAsFixed(2)} based on rating ${_rating.toInt()} and trust ${_trust.toStringAsFixed(2)}');
      _logs.add('Sensor Weight (Lambda): ${lambda.toStringAsFixed(2)}');
      _logs.add('Discrepancy Penalty: +${penalty.toStringAsFixed(3)}');
    } else {
      _rRep = 0.0;
      _logs.add('No passenger reports. R_trip relies purely on R_sens.');
    }

    _rTrip = (lambda * _rSens) + ((1 - lambda) * _rRep) + penalty;
    _rTrip = _rTrip.clamp(0.0, 1.0);
    _safetyScore = ((1 - _rTrip) * 100).round();

    setState(() {});
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Algorithm Simulator'),
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
        actions: [],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          final inputsView = ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              _SectionHeader(title: 'Context Variables', icon: Icons.public, cs: cs),
              _M3Card(
                cs: cs,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: DropdownButtonFormField<double>(
                        value: _vehicleMultiplier,
                        decoration: InputDecoration(
                          labelText: 'Vehicle Type',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 0.75, child: Text('Jeepney (x0.75)')),
                          DropdownMenuItem(value: 1.20, child: Text('Bus (x1.20)')),
                          DropdownMenuItem(value: 0.65, child: Text('Tricycle (x0.65)')),
                        ],
                        onChanged: (v) { if (v != null) setState(() { _vehicleMultiplier = v; _calculate(); }); },
                      ),
                    ),
                    _M3Slider(label: 'Road Condition', value: _roadCondition, min: 0, max: 1, minLabel: 'Poor', maxLabel: 'Smooth', icon: Icons.edit_road, cs: cs, onChanged: (v) { _roadCondition = v; _calculate(); }),
                    _M3Slider(label: 'Traffic Density', value: _trafficDensity, min: 0, max: 1, minLabel: 'Light', maxLabel: 'Heavy', icon: Icons.traffic, cs: cs, onChanged: (v) { _trafficDensity = v; _calculate(); }),
                    _M3Slider(label: 'Environmental Noise', value: _envNoise, min: 0, max: 1, minLabel: 'Quiet', maxLabel: 'Loud', icon: Icons.volume_up, cs: cs, onChanged: (v) { _envNoise = v; _calculate(); }),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _SectionHeader(title: 'Sensor Readings', icon: Icons.sensors, cs: cs),
              _M3Card(
                cs: cs,
                child: Column(
                  children: [
                    _M3Slider(label: 'Average Speed', value: _speed, min: 0, max: 120, unit: 'km/h', icon: Icons.speed, cs: cs, divisions: 120, onChanged: (v) { _speed = v; _calculate(); }),
                    _M3Slider(label: 'Max Deceleration', value: _deceleration, min: 0, max: 10, unit: 'm/s²', icon: Icons.call_received, cs: cs, onChanged: (v) { _deceleration = v; _calculate(); }),
                    _M3Slider(label: 'Max Turning', value: _turning, min: 0, max: 5, unit: 'rad/s', icon: Icons.turn_right, cs: cs, onChanged: (v) { _turning = v; _calculate(); }),
                    _M3Slider(label: 'Pothole Impact', value: _pothole, min: 0, max: 15, unit: 'm/s²', icon: Icons.warning_amber, cs: cs, onChanged: (v) { _pothole = v; _calculate(); }),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _SectionHeader(title: 'Crowdsourcing Reports', icon: Icons.groups, cs: cs),
              _M3Card(
                cs: cs,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Passenger Submitted a Report', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Inject a crowd report into the fusion algorithm'),
                      activeColor: cs.primary,
                      value: _hasReport,
                      onChanged: (v) { setState(() { _hasReport = v; _calculate(); }); },
                    ),
                    if (_hasReport) ...[
                      const Divider(height: 1),
                      _M3Slider(label: 'Risk Rating', value: _rating, min: 1, max: 5, minLabel: 'Safe', maxLabel: 'Dangerous', icon: Icons.star, cs: cs, divisions: 4, onChanged: (v) { _rating = v; _calculate(); }),
                      _M3Slider(label: 'Passenger Trust Score', value: _trust, min: 0, max: 1, minLabel: 'Untrusted', maxLabel: 'Trusted', icon: Icons.verified_user, cs: cs, onChanged: (v) { _trust = v; _calculate(); }),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );

          final outputsView = Container(
            decoration: BoxDecoration(
              color: isWide ? cs.surfaceContainerLowest : Colors.transparent,
              border: isWide ? Border(left: BorderSide(color: cs.outlineVariant)) : null,
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    children: [
                      _SectionHeader(title: 'Algorithm Diagnostics', icon: Icons.analytics, cs: cs),
                      _ScoreBanner(score: _safetyScore, cs: cs),
                      const SizedBox(height: 12),
                      _ScoreLegend(
                        items: const [
                          (color: Colors.green, label: '80-100 Safe'),
                          (color: Colors.orange, label: '35-79 Moderate'),
                          (color: Colors.red, label: '0-34 Risky'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.6,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _M3StatCard(title: 'Context Multiplier', value: '${_mc.toStringAsFixed(2)}x', icon: Icons.tune, cs: cs),
                          _M3StatCard(title: 'Adaptive Speed Limit', value: '${_speedLimit.toStringAsFixed(1)}', unit: 'km/h', icon: Icons.speed, cs: cs),
                          _M3StatCard(title: 'Sensor Risk (R_sens)', value: _rSens.toStringAsFixed(2), icon: Icons.sensors, cs: cs, isRisk: true),
                          _M3StatCard(title: 'Report Risk (R_rep)', value: _hasReport ? _rRep.toStringAsFixed(2) : 'N/A', icon: Icons.groups, cs: cs, isRisk: true),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 250,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: isWide ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(top: BorderSide(color: cs.outlineVariant)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.terminal, size: 20, color: cs.primary),
                          const SizedBox(width: 8),
                          Text('Calculation Log', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _logs.length,
                          itemBuilder: (context, i) {
                            final log = _logs[i];
                            final isAlert = log.startsWith('⚠️');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isAlert ? '!' : '>', style: TextStyle(fontFamily: 'monospace', color: isAlert ? cs.error : cs.outline, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(log, style: TextStyle(
                                      fontFamily: 'monospace', 
                                      fontSize: 13,
                                      color: isAlert ? cs.error : cs.onSurfaceVariant,
                                      fontWeight: isAlert ? FontWeight.bold : FontWeight.normal
                                    )),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(flex: 5, child: inputsView),
                Expanded(flex: 4, child: outputsView),
              ],
            );
          } else {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [Tab(text: 'Inputs'), Tab(text: 'Outputs')],
                    labelColor: cs.primary,
                    indicatorColor: cs.primary,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [inputsView, outputsView],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// M3 EXPRESSIVE UI COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final ColorScheme cs;

  const _SectionHeader({required this.title, required this.icon, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
        ],
      ),
    );
  }
}

class _M3Card extends StatelessWidget {
  final Widget child;
  final ColorScheme cs;

  const _M3Card({required this.child, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _M3Slider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String? unit;
  final String? minLabel;
  final String? maxLabel;
  final IconData icon;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final ColorScheme cs;

  const _M3Slider({
    required this.label, required this.value, required this.min, required this.max, 
    this.unit, this.minLabel, this.maxLabel, required this.icon, this.divisions, 
    required this.onChanged, required this.cs
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${value.toStringAsFixed(unit == null ? 2 : 1)}${unit != null ? ' $unit' : ''}', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer, fontSize: 12)
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: cs.primary,
              inactiveTrackColor: cs.surfaceContainerHighest,
              thumbColor: cs.primary,
              overlayColor: cs.primary.withOpacity(0.12),
              trackHeight: 6,
            ),
            child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
          ),
          if (minLabel != null && maxLabel != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(minLabel!, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                  Text(maxLabel!, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _M3StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? unit;
  final IconData icon;
  final ColorScheme cs;
  final bool isRisk;

  const _M3StatCard({required this.title, required this.value, this.unit, required this.icon, required this.cs, this.isRisk = false});

  @override
  Widget build(BuildContext context) {
    final double? numVal = double.tryParse(value);
    Color valueColor = cs.onSurface;
    if (isRisk && numVal != null) {
      if (numVal < 0.4) valueColor = Colors.green;
      else if (numVal < 0.65) valueColor = Colors.orange;
      else valueColor = Colors.red;
    } else {
      valueColor = cs.primary;
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: valueColor)),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(unit!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ]
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBanner extends StatelessWidget {
  final int score;
  final ColorScheme cs;

  const _ScoreBanner({required this.score, required this.cs});

  Color _riskColor(double v) {
    if (v < 0.40) return Colors.green;
    if (v < 0.65) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(1 - score / 100);
    final text  = score >= 80 ? 'SAFE RIDE' : score >= 35 ? 'MODERATE RISK' : 'DANGEROUS RIDE';
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 500),
      builder: (_, v, child) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.2), color.withOpacity(0.05)]
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 72, height: 72,
              child: Stack(
                alignment: Alignment.center, 
                children: [
                  CircularProgressIndicator(
                    value: v, strokeWidth: 8, strokeCap: StrokeCap.round,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                  Text('$score', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
                ]
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Final Safety Score', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  Text(text, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, height: 1.2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreLegend extends StatelessWidget {
  const _ScoreLegend({required this.items});
  final List<({Color color, String label})> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
