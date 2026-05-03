import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

class OptimizerScreen extends StatefulWidget {
  const OptimizerScreen({super.key});
  @override
  State<OptimizerScreen> createState() => _OptimizerScreenState();
}

class _OptimizerScreenState extends State<OptimizerScreen> {
  double _distanceWeight  = 0.70;
  double _budgetCap       = 0.50; // maps to $150/day at 0.50
  double _hoursPriority   = 1.0;  // High

  // Activity list with move info — matches PDF exactly
  final List<Map<String, dynamic>> _activities = [
    {
      'rank': 1,
      'name': 'Tanah Lot Temple',
      'reason': 'Opens at 7am · nearest · \$12',
      'move': null,
      'moveUp': true,
    },
    {
      'rank': 2,
      'name': 'Jatiluwih Terraces',
      'reason': '↑ moved up — closes at 5pm',
      'move': '+2',
      'moveUp': true,
    },
    {
      'rank': 3,
      'name': 'Seminyak Beach',
      'reason': '↓ budget conflict resolved',
      'move': '-1',
      'moveUp': false,
    },
    {
      'rank': 4,
      'name': 'Jimbaran Dinner',
      'reason': 'Booked · evening slot locked',
      'move': null,
      'moveUp': true,
    },
  ];

  String get _budgetLabel {
    final val = (_budgetCap * 300).round();
    return '\$$val/day';
  }

  String get _hoursLabel {
    if (_hoursPriority > 0.66) return 'High';
    if (_hoursPriority > 0.33) return 'Medium';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.bg,
      bottomNavigationBar: TBottomNav(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/packing');
              break;
            case 1:
              // Already on optimizer
              break;
            case 2:
              Navigator.pushNamed(context, '/checklist');
              break;
            case 3:
              // Profile
              break;
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ──────────────────────────────────────────────────
              Text('OPTIMIZER · REQUIRED',
                  style: TText.caption.copyWith(color: TColors.limeText)),
              const SizedBox(height: 6),
              Text('AI Optimizer', style: TText.h1),
              const SizedBox(height: 4),
              Text('Adjust constraints to reorder activities', style: TText.body),

              const SizedBox(height: 24),

              // ── Constraint sliders ───────────────────────────────────────
              _SliderRow(
                label: 'Distance weight',
                value: _distanceWeight,
                displayText: '${(_distanceWeight * 100).round()}%',
                onChanged: (v) => setState(() => _distanceWeight = v),
              ),
              const SizedBox(height: 18),
              _SliderRow(
                label: 'Budget cap',
                value: _budgetCap,
                displayText: _budgetLabel,
                onChanged: (v) => setState(() => _budgetCap = v),
              ),
              const SizedBox(height: 18),
              _SliderRow(
                label: 'Opening hours priority',
                value: _hoursPriority,
                displayText: _hoursLabel,
                onChanged: (v) => setState(() => _hoursPriority = v),
              ),

              const SizedBox(height: 28),

              // ── Optimized order label ────────────────────────────────────
              Text('OPTIMIZED ORDER', style: TText.caption),
              const SizedBox(height: 12),

              // ── Activity ranked list ─────────────────────────────────────
              ..._activities.map((a) => _ActivityRankCard(activity: a)),

              const SizedBox(height: 28),

              // ── Apply button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.lime,
                    foregroundColor: TColors.bg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  child: const Text('Apply to Itinerary'),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: Text('AI ITINERARY OPTIMIZER',
                    style: TText.caption.copyWith(letterSpacing: 1.5)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Slider row widget ────────────────────────────────────────────────────────
class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final String displayText;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.displayText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TText.body),
            Text(displayText, style: TText.limeStyle),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: TColors.lime,
            inactiveTrackColor: TColors.border,
            thumbColor: TColors.lime,
            overlayColor: TColors.lime.withOpacity(0.1),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(value: value, onChanged: onChanged),
        ),
      ],
    );
  }
}

// ─── Ranked activity card ─────────────────────────────────────────────────────
class _ActivityRankCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  const _ActivityRankCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final String? move   = activity['move'] as String?;
    final bool moveUp    = activity['moveUp'] as bool;
    final bool hasMoved  = move != null;
    final int rank       = activity['rank'] as int;

    // Rank 1 gets lime highlight like in the PDF
    final bool isTop = rank == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isTop
            ? TColors.lime.withOpacity(0.08)
            : TColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop ? TColors.lime.withOpacity(0.3) : TColors.border,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Rank number circle
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isTop
                  ? TColors.lime.withOpacity(0.2)
                  : TColors.surface2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: isTop ? TColors.lime : TColors.textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Name + reason
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity['name'] as String, style: TText.label),
                const SizedBox(height: 2),
                Text(activity['reason'] as String, style: TText.body.copyWith(fontSize: 11)),
              ],
            ),
          ),

          // Move badge — ↑+2 or ↓-1 like in PDF
          if (hasMoved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: moveUp
                    ? TColors.lime.withOpacity(0.12)
                    : TColors.coral.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: moveUp
                      ? TColors.lime.withOpacity(0.3)
                      : TColors.coral.withOpacity(0.3),
                ),
              ),
              child: Text(
                moveUp ? '↑ $move' : '↓ $move',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: moveUp ? TColors.limeText : TColors.coral,
                ),
              ),
            ),
        ],
      ),
    );
  }
}