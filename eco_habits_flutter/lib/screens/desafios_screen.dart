import 'package:flutter/material.dart';
import '../models/constants.dart';
import '../models/habit.dart';
import '../widgets/app_top_bar.dart';

class DesafiosScreen extends StatefulWidget {
  final List<Habit> habits;
  final VoidCallback onNavigateToHabitos;

  const DesafiosScreen({
    super.key,
    required this.habits,
    required this.onNavigateToHabitos,
  });

  @override
  State<DesafiosScreen> createState() => _DesafiosScreenState();
}

class _DesafiosScreenState extends State<DesafiosScreen> {
  void _toggleHabit(Habit habit) {
    if (habit.done) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'CONFIRMAR',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          content: Text('Deseja desmarcar "${habit.name}"?',
              style: const TextStyle(fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancelar', style: TextStyle(color: kTextMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              onPressed: () {
                setState(() => habit.done = false);
                Navigator.pop(context);
              },
              child: const Text('Desmarcar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      setState(() => habit.done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppTopBar(title: 'Progresso'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BarChart(),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: kGreenDark, width: 1.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'MARQUE SEUS FEITOS DE HOJE',
                  ),
                ),
                const SizedBox(height: 10),
                ...widget.habits.map((h) => _HabitItem(
                      habit: h,
                      onTap: () => _toggleHabit(h),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Gráfico de barras ──────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final max = kBarData.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(kBarData.length, (i) {
            final h = (kBarData[i] / max) * 90;
            final color = kBarData[i] < 45 ? kGreenDark : kGreenBar;
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    kMonths[i],
                    style: const TextStyle(
                        fontSize: 7,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Item de hábito ─────────────────────────────────────────────────
class _HabitItem extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;

  const _HabitItem({required this.habit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(
              kCatIcons[habit.category] ?? Icons.eco,
              color: kGreenDark,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                habit.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: habit.done ? kGreen : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: habit.done ? kGreen : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: habit.done
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
