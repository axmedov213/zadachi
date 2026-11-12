import 'package:flutter/material.dart';

import '../database_helper.dart';
import 'habit_edit_screen.dart';
import 'stats_screen.dart';

const _accent = Color(0xFF2196F3);

class HabitListScreen extends StatefulWidget {
  const HabitListScreen({super.key});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Habit> _habits = [];
  Map<int, bool> _completions = {};
  bool _isLoading = true;

  String get _today => formatDate(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final habits = await _db.getAllHabits();
    final completions = <int, bool>{};
    for (final habit in habits) {
      completions[habit.id!] = await _db.isCompleted(habit.id!, _today);
    }
    if (!mounted) return;
    setState(() {
      _habits = habits;
      _completions = completions;
      _isLoading = false;
    });
  }

  Future<void> _toggleHabit(int habitId) async {
    await _db.toggleCompletion(habitId, _today);
    await _loadData();
  }

  int get _completedCount => _completions.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    final total = _habits.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Мои привычки',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Color(0xFF1A1A1A)),
            tooltip: 'Статистика',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProgressHeader(context, _completedCount, total),
                const SizedBox(height: 8),
                Expanded(
                  child: _habits.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: _habits.length,
                          itemBuilder: (context, index) {
                            final habit = _habits[index];
                            final isDone = _completions[habit.id] ?? false;
                            return _buildHabitCard(habit, isDone);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HabitEditScreen()),
          );
          _loadData();
        },
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Добавить',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(BuildContext context, int done, int total) {
    final double ratio = total == 0 ? 0 : done / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_accent, Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$done из $total',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'привычек выполнено сегодня',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.track_changes, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Пока нет привычек',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Нажмите «Добавить», чтобы создать первую',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, bool isDone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E4EA)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleHabit(habit.id!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? _accent : Colors.transparent,
                border: Border.all(
                  color: isDone ? _accent : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDone ? Colors.grey[500] : Color(0xFF1A1A1A),
                    decoration:
                        isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (habit.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    habit.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22, color: Color(0xFF1A1A1A)),
            tooltip: 'Редактировать',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HabitEditScreen(habit: habit),
                ),
              );
              _loadData();
            },
          ),
        ],
      ),
    );
  }
}