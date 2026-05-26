import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class RulesManagerScreen extends StatefulWidget {
  const RulesManagerScreen({super.key});

  @override
  State<RulesManagerScreen> createState() => _RulesManagerScreenState();
}

class _RulesManagerScreenState extends State<RulesManagerScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _frequency = 'daily';
  String _difficulty = 'medium';
  bool _showForm = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ground Rules',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _showForm = !_showForm);
                    },
                    icon: Icon(
                      _showForm ? Icons.close : Icons.add,
                      size: 16,
                    ),
                    label: Text(_showForm ? 'Cancel' : 'New Rule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showForm
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white,
                      foregroundColor: _showForm ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Define your daily habits and targets.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
              if (_showForm) ...[
                const SizedBox(height: 20),
                _buildForm(state),
              ],
              const SizedBox(height: 24),
              if (state.rules.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.rule_folder_outlined,
                          size: 48,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No rules yet. Create your first!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.rules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final rule = state.rules[index];
                    return _buildRuleCard(rule, state);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForm(AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Rule',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(_titleController, 'Title (e.g. Code 1 hour)'),
          const SizedBox(height: 10),
          _buildTextField(_descController, 'Description (optional)', maxLines: 2),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FREQUENCY',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _frequency,
                      items: const ['daily', 'weekly', 'one-time'],
                      onChanged: (v) => setState(() => _frequency = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIFFICULTY',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _difficulty,
                      items: const ['easy', 'medium', 'hard'],
                      onChanged: (v) => setState(() => _difficulty = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty) return;
                await state.addRule(
                  _titleController.text,
                  _descController.text,
                  _frequency,
                  _difficulty,
                );
                _titleController.clear();
                _descController.clear();
                setState(() => _showForm = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Create Rule',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(dynamic rule, AppState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (rule.description != null && rule.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      rule.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Text(
                        rule.frequency.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Text(
                        rule.difficulty.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF111111),
                  title: const Text(
                    'Delete Rule',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    'Are you sure you want to delete "${rule.title}"?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await state.deleteRule(rule.id);
              }
            },
            icon: Icon(
              Icons.delete_outline,
              color: Colors.white.withOpacity(0.2),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF111111),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white.withOpacity(0.3),
          ),
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item[0].toUpperCase() + item.substring(1),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
