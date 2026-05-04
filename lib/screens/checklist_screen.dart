import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});
  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final TextEditingController _ctrl = TextEditingController();

  // ✅ FIX — lazy getter instead of final field
  CollectionReference get _ref =>
      FirebaseFirestore.instance.collection('checklist');

  // Add task to Firestore
  Future<void> _addTask() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    await _ref.add({
      'name': name,
      'done': false,
      'who': 'All',
      'cat': 'GENERAL',
      'createdAt': FieldValue.serverTimestamp(),
    });
    _ctrl.clear();
  }

  // Toggle done in Firestore
  Future<void> _toggle(String docId, bool current) async {
    await _ref.doc(docId).update({'done': !current});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.bg,
      bottomNavigationBar: TBottomNav(currentIndex: 2, onTap: (_) {}),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _ref.orderBy('createdAt').snapshots(),
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: TColors.lime),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading data', style: TText.body),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            final doneCount = docs.where((d) =>
                (d.data() as Map<String, dynamic>)['done'] == true).length;
            final total = docs.length;
            final pct = total == 0 ? 0.0 : doneCount / total;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Header
                  Text('CHECKLIST · PHASE 3',
                      style: TText.caption.copyWith(color: TColors.limeText)),
                  const SizedBox(height: 6),
                  Text('Trip Checklist', style: TText.h1),
                  const SizedBox(height: 2),
                  Text('Shared across all travelers', style: TText.body),
                  const SizedBox(height: 20),

                  // Progress ring card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TColors.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64, height: 64,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: pct,
                                strokeWidth: 5,
                                backgroundColor: TColors.border,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    TColors.lime),
                              ),
                              Center(
                                child: Text(
                                  '${(pct * 100).round()}%',
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: TColors.limeText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$doneCount of $total tasks done',
                                style: TText.h2),
                            const SizedBox(height: 3),
                            Text('${total - doneCount} remaining',
                                style: TText.body
                                    .copyWith(color: TColors.limeText)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Add task input row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: TColors.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add a new task...',
                            hintStyle: const TextStyle(color: TColors.textMuted),
                            filled: true,
                            fillColor: TColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: TColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: TColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: TColors.lime, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          onSubmitted: (_) => _addTask(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _addTask,
                        child: Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            color: TColors.lime,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add,
                              color: TColors.bg, size: 24),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Task list from Firestore
                  Text('TASKS', style: TText.caption),
                  const SizedBox(height: 10),

                  if (docs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'No tasks yet. Add your first task above!',
                        style: TText.body,
                      ),
                    ),

                  ...docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _CheckRow(
                      task: data,
                      onToggle: () => _toggle(doc.id, data['done'] == true),
                    );
                  }),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Single task row
class _CheckRow extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onToggle;
  const _CheckRow({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final bool done = task['done'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22, height: 22,
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
          Expanded(
            child: Text(
              task['name'] ?? '',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: TColors.surface2,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: TColors.border, width: 0.5),
            ),
            child: Text(
              task['who'] ?? 'All',
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