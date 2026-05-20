import 'package:flutter/material.dart';
import '../models/constants.dart';
import '../models/habit.dart';
import '../widgets/app_top_bar.dart';

class HabitosScreen extends StatefulWidget {
  final List<Habit> habits;
  final VoidCallback onNavigateToDesafios;

  const HabitosScreen({
    super.key,
    required this.habits,
    required this.onNavigateToDesafios,
  });

  @override
  State<HabitosScreen> createState() => _HabitosScreenState();
}

class _HabitosScreenState extends State<HabitosScreen> {
  int _nextId = 10;

  // ── CRUD ──────────────────────────────────────────────────────────
  void _openAddModal() => _openHabitModal(null);

  void _openEditModal(Habit habit) => _openHabitModal(habit);

  void _openHabitModal(Habit? editing) {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    String selectedCat = editing?.category ?? 'transporte';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            editing == null ? 'NOVO HÁBITO' : 'EDITAR HÁBITO',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nome do hábito',
                  style: TextStyle(fontSize: 11, color: kTextMuted)),
              const SizedBox(height: 4),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Ex: Andar de bicicleta',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              const Text('Categoria',
                  style: TextStyle(fontSize: 11, color: kTextMuted)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: selectedCat,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12, color: Color(0xFF111111)),
                items: kCatLabels.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (val) => setModalState(() => selectedCat = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancelar', style: TextStyle(color: kTextMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kGreen),
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                setState(() {
                  if (editing == null) {
                    widget.habits.add(Habit(
                        id: _nextId++, name: name, category: selectedCat));
                  } else {
                    editing.name = name;
                    editing.category = selectedCat;
                  }
                });
                Navigator.pop(context);
              },
              child:
                  const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _openDeleteModal(Habit habit) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'REMOVER HÁBITO',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        content: Text(
          'Tem certeza que deseja remover "${habit.name}"? Esta ação não pode ser desfeita.',
          style: const TextStyle(fontSize: 13, color: kTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: kTextMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              setState(
                  () => widget.habits.removeWhere((h) => h.id == habit.id));
              Navigator.pop(context);
            },
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Resumo ────────────────────────────────────────────────────────
  Widget _buildResumo() {
    final done = widget.habits.where((h) => h.done).length;
    final total = widget.habits.length;
    final pct = total > 0 ? (done / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMO DO DIA',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCCCCCC)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ResumoCell(
                          title: 'PROGRESSO DOS HÁBITOS',
                          borderRight: true,
                          borderBottom: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _BulletText(
                                  'Você completou $done de $total hábitos hoje'),
                              _BulletText('Progresso — $pct% concluído'),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: _ResumoCell(
                          title: 'SEQUÊNCIA',
                          borderBottom: true,
                          child: Column(
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 26)),
                              const SizedBox(height: 4),
                              const Text(
                                'Você está há 5 dias consecutivos praticando hábitos sustentáveis.',
                                style: TextStyle(
                                    fontSize: 9, color: Color(0xFF333333)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ResumoCell(
                          title: 'IMPACTO',
                          borderRight: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              _BulletText(
                                  'Suas ações geraram um impacto positivo no meio ambiente.'),
                              SizedBox(height: 3),
                              _BulletText(
                                  'Você economizou aproximadamente 12 litros de água e ajudou a reduzir a emissão de 0,5 kg de CO₂.'),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: _ResumoCell(
                          title: 'DESTAQUE DO DIA',
                          child: const _BulletText(
                            'O hábito que mais se destacou hoje foi Reciclagem correta, demonstrando sua preocupação com o descarte adequado.',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Lista + Histórico ─────────────────────────────────────────────
  Widget _buildBottomCards() {
    final done = widget.habits.where((h) => h.done).length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lista de hábitos
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.list, size: 14, color: kGreenDark),
                    SizedBox(width: 5),
                    Text('Lista de hábitos',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Acompanhe e construa uma rotina mais sustentável',
                  style: TextStyle(fontSize: 9, color: kTextMuted),
                ),
                const SizedBox(height: 8),
                ...widget.habits.map((h) => _HabitListItem(
                      habit: h,
                      onEdit: () => _openEditModal(h),
                      onDelete: () => _openDeleteModal(h),
                    )),
                const Divider(height: 16, thickness: 0.5),
                GestureDetector(
                  onTap: () {
                    if (widget.habits.isNotEmpty)
                      _openDeleteModal(widget.habits.last);
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.remove, size: 13, color: Colors.red),
                      SizedBox(width: 5),
                      Text('Remover hábito',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.red)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _openAddModal,
                  child: Row(
                    children: const [
                      Icon(Icons.add, size: 13, color: kGreenDark),
                      SizedBox(width: 5),
                      Text('Adicionar hábito',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: kGreenDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Histórico
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.history, size: 14, color: kGreenDark),
                    SizedBox(width: 5),
                    Text('Histórico',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 2),
                const Text('Acompanhe suas atividades',
                    style: TextStyle(fontSize: 9, color: kTextMuted)),
                const SizedBox(height: 12),
                const Center(
                    child: Icon(Icons.calendar_today_outlined,
                        size: 28, color: Colors.grey)),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    done > 0
                        ? '$done hábito(s) concluídos hoje.\nContinue assim! 🌱'
                        : 'Nenhum histórico ainda.\n\nComplete seus hábitos diários para acompanhar seu progresso.',
                    style: const TextStyle(fontSize: 9, color: kTextMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppTopBar(title: 'Hábitos'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _buildResumo(),
                _buildBottomCards(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Célula do resumo ───────────────────────────────────────────────
class _ResumoCell extends StatelessWidget {
  final String title;
  final Widget child;
  final bool borderRight;
  final bool borderBottom;

  const _ResumoCell({
    required this.title,
    required this.child,
    this.borderRight = false,
    this.borderBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(
          right: borderRight
              ? const BorderSide(color: Color(0xFFCCCCCC))
              : BorderSide.none,
          bottom: borderBottom
              ? const BorderSide(color: Color(0xFFCCCCCC))
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: kGreenDark,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

// ── Bullet text ────────────────────────────────────────────────────
class _BulletText extends StatelessWidget {
  final String text;
  const _BulletText(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ',
            style: TextStyle(fontSize: 9, color: Color(0xFF333333))),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 9, color: Color(0xFF333333))),
        ),
      ],
    );
  }
}

// ── Item da lista de hábitos ───────────────────────────────────────
class _HabitListItem extends StatelessWidget {
  final Habit habit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HabitListItem(
      {required this.habit, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              habit.name.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: kGreenDark,
                  letterSpacing: 0.3),
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EC),
                  borderRadius: BorderRadius.circular(5)),
              child:
                  const Icon(Icons.edit_outlined, size: 12, color: kGreenDark),
            ),
          ),
          const SizedBox(width: 3),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                  color: const Color(0xFFFCE8E8),
                  borderRadius: BorderRadius.circular(5)),
              child: const Icon(Icons.delete_outline,
                  size: 12, color: Color(0xFFC0392B)),
            ),
          ),
        ],
      ),
    );
  }
}
