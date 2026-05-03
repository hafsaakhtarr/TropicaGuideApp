import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

class PackingScreen extends StatefulWidget {
  const PackingScreen({super.key});

  @override
  State<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends State<PackingScreen> {
  final List<Map<String, dynamic>> _items = [
    {'name': 'Passport', 'packed': true},
    {'name': 'Sunglasses', 'packed': false},
    {'name': 'Swimwear', 'packed': true},
    {'name': 'Sunscreen', 'packed': false},
    {'name': 'Hat', 'packed': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.bg,
      bottomNavigationBar: TBottomNav(
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation
          switch (index) {
            case 0:
              // Already on packing
              break;
            case 1:
              Navigator.pushNamed(context, '/optimizer');
              break;
            case 2:
              Navigator.pushNamed(context, '/checklist');
              break;
            case 3:
              // Profile or something
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
              Text('Packing List', style: TText.h1),
              const SizedBox(height: 20),
              ..._items.map((item) => _PackingItem(
                name: item['name'],
                packed: item['packed'],
                onChanged: (packed) {
                  setState(() {
                    item['packed'] = packed;
                  });
                },
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackingItem extends StatelessWidget {
  final String name;
  final bool packed;
  final ValueChanged<bool> onChanged;

  const _PackingItem({
    required this.name,
    required this.packed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: TColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Checkbox(
            value: packed,
            onChanged: (value) => onChanged(value ?? false),
            activeColor: TColors.lime,
          ),
          const SizedBox(width: 10),
          Text(name, style: packed ? TText.body.copyWith(decoration: TextDecoration.lineThrough) : TText.body),
        ],
      ),
    );
  }
}