import 'package:flutter/material.dart';

import '../database_helper.dart';

const _accent = Color(0xFF2196F3);

class HabitEditScreen extends StatefulWidget {
  final Habit? habit;
  const HabitEditScreen({super.key, this.habit});

  @override
  State<HabitEditScreen> createState() => _HabitEditScreenState();
}

class _HabitEditScreenState extends State<HabitEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.habit!.name;
      _descController.text = widget.habit!.description;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final habit = Habit(
      id: widget.habit?.id,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
    );

    if (_isEditing) {
      await _db.updateHabit(habit);
    } else {
      await _db.createHabit(habit);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить привычку?'),
        content: const Text('Все отметки выполнения также будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.deleteHabit(widget.habit!.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать' : 'Новая привычка'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              maxLength: 50,
              style: const TextStyle(color: Color(0xFF1A1A1A)),
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Например: Пить воду',
                counterText: '',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название';
                }
                if (value.trim().length > 50) return 'Не более 50 символов';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              maxLength: 200,
              maxLines: 3,
              style: const TextStyle(color: Color(0xFF1A1A1A)),
              decoration: const InputDecoration(
                labelText: 'Описание (необязательно)',
                hintText: 'Зачем вам эта привычка?',
                counterText: '',
              ),
              validator: (value) {
                if (value != null && value.trim().length > 200) {
                  return 'Не более 200 символов';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(_isEditing ? 'Сохранить' : 'Добавить'),
              ),
            ),
            const SizedBox(height: 12),
            if (_isEditing)
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: BorderSide(color: _accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Удалить'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}