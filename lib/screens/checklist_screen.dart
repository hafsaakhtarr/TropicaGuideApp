import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});
  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final List<Map<String, dynamic>> _tasks = [
    // PRE-DEPARTURE
    {'cat': 'PRE-DEPARTURE', 'name': 'Book flights',             'done': true,  'who': 'Alex'},
    {'cat': 'PRE-DEPARTURE', 'name': 'Reserve accommodations',   'done': true,  'who': 'Maria'},
    {'cat': 'PRE-DEPARTURE', 'name': 'Apply for travel visas',   'done': false, 'who': 'Kai'},
    {'cat': 'PRE-DEPARTURE', 'name': 'Get travel vaccinations',  'done': false, 'who': 'All'},
    // ACTIVITIES
    {'cat': 'ACTIVITIES',    'name': 'Book cooking class · Day 3','done': true,  'who': 'Alex'},
    {'cat': 'ACTIVITIES',    'name': 'Reserve temple tour guide', 'done': false, 'who': 'Maria'},
    // BUDGET
    {'cat': 'BUDGET',        'name': 'Set group spending limit',  'done': true,  'who': 'Alex'},
    {'cat': 'BUDGET',        'name': 'Create shared expense pool','done': false, 'who': 'Maria'},
  ];

  int get _done  => _tasks.where((t) => t['done'] == true).length;
  int get _total => 20; // matches PDF "13 of 20"

  @override
  Widget build(BuildContext context) {
    final double pct = _done / _total;
    final cats = <String>[];
    for (final t in _tasks) {
      if (!cats.contains(t['cat'])) cats.add(t['cat'] as String);
    }

    return Scaffold(
      backgroundColor: TColors.bg,
      bottomNavigationBar: TBottomNav(currentIndex: 2, onTap: (_) {}),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: TColors.lime,
        foregroundColor: TColors.bg,
        mini: true,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ──────────────────────────────────────────────────
              Text('CHECKLIST · PHASE 3',
                  style: TText.caption.copyWith(color: TColors.limeText)),
              const SizedBox(height: 6),
              Text('Trip Checklist', style: TText.h1),
              const SizedBox(height: 2),
              Text('Shared across all travelers', style: TText.body),

              const SizedBox(height: 20),

              // ── Progress card — circular + stats (matches PDF) ───────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    // Circular progress ring
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: pct,
                            strokeWidth: 5,
                            backgroundColor: TColors.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(TColors.lime),
                          ),
                          Center(
                            child: Text(
                              '${(_done / _total * 100).round()}%',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: TColors.limeText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Stats text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_done} of $_total tasks done',
                          style: TText.h2,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_total - _done} remaining',
                          style: TText.body.copyWith(color: TColors.limeText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Task list by category ────────────────────────────────────
              for (final cat in cats) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(cat, style: TText.caption),
                ),
                ...(_tasks.where((t) => t['cat'] == cat).map((task) =>
                  _CheckRow(
                    task: task,
                    onToggle: () =>
                        setState(() => task['done'] = !(task['done'] as bool)),
                  ),
                )),
                const SizedBox(height: 14),
              ],

              // Add task button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18, color: TColors.lime),
                  label: const Text(
                    'Add Task',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: TColors.lime,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: TColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Single checklist row ─────────────────────────────────────────────────────
class _CheckRow extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onToggle;
  const _CheckRow({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final bool done = task['done'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Circle checkbox
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: done ? TColors.lime : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? TColors.lime : TColors.textMuted,
                  width: 1.5,
                ),
              ),
              child: done
                  ? const Icon(Icons.check, color: TColors.bg, size: 13)
                  : null,
            ),
          ),

          const SizedBox(width: 14),

          // Task name
          Expanded(
            child: Text(
              task['name'] as String,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: done ? TColors.textMuted : TColors.textPrimary,
                decoration: done ? TextDecoration.lineThrough : null,
                decorationColor: TColors.textMuted,
              ),
            ),
          ),

          // Assignee label — Alex, Maria, Kai, All
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: TColors.surface2,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: TColors.border, width: 0.5),
            ),
            child: Text(
              task['who'] as String,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: TColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}