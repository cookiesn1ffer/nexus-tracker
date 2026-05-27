import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../constants.dart';
import '../widgets/common.dart';

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
  int? _editingRuleId;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _startEdit(dynamic rule) {
    setState(() {
      _editingRuleId = rule.id;
      _titleController.text = rule.title;
      _descController.text = rule.description ?? '';
      _frequency = rule.frequency;
      _difficulty = rule.difficulty;
      _showForm = true;
    });
  }

  void _cancelForm() {
    setState(() {
      _showForm = false;
      _editingRuleId = null;
      _titleController.clear();
      _descController.clear();
      _frequency = 'daily';
      _difficulty = 'medium';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingScreen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    AppStrings.groundRules,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppDimensions.fontSizeHeading,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  AppButton(
                    text: _showForm ? AppStrings.cancel : AppStrings.newRule,
                    icon: _showForm ? Icons.close : Icons.add,
                    isPrimary: !_showForm,
                    onPressed: () {
                      if (_showForm) {
                        _cancelForm();
                      } else {
                        setState(() => _showForm = true);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Define your daily habits and targets.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: AppDimensions.fontSizeMedium,
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
                          size: AppDimensions.iconXL,
                          color: AppColors.iconSubtle,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No rules yet. Create your first!',
                          style: TextStyle(
                            color: AppColors.textFaint,
                            fontSize: AppDimensions.fontSizeLarge,
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
    final isEditing = _editingRuleId != null;
    return AppCard(
      borderRadius: AppDimensions.borderRadiusXL,
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? AppStrings.editRule : AppStrings.newRule,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppDimensions.fontSizeTitle,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          AppTextField(
            controller: _titleController,
            hint: 'Title (e.g. Code 1 hour)',
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: _descController,
            hint: 'Description (optional)',
            maxLines: 2,
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.frequency,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: AppDimensions.fontSizeXS,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    AppDropdown(
                      value: _frequency,
                      items: AppStrings.frequencies,
                      onChanged: (v) => setState(() => _frequency = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.paddingLarge),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.difficulty,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: AppDimensions.fontSizeXS,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    AppDropdown(
                      value: _difficulty,
                      items: AppStrings.difficulties,
                      onChanged: (v) => setState(() => _difficulty = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty) return;
                if (isEditing) {
                  await state.updateRule(
                    _editingRuleId!,
                    _titleController.text,
                    _descController.text,
                    _frequency,
                    _difficulty,
                  );
                } else {
                  await state.addRule(
                    _titleController.text,
                    _descController.text,
                    _frequency,
                    _difficulty,
                  );
                }
                _cancelForm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                ),
              ),
              child: Text(
                isEditing ? AppStrings.updateRule : AppStrings.createRule,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(dynamic rule, AppState state) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppDimensions.fontSizeXL,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (rule.description != null && rule.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      rule.description,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: AppDimensions.fontSizeSmall2,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AppBadge(text: rule.frequency),
                    const SizedBox(width: 8),
                    AppBadge(text: rule.difficulty),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _startEdit(rule),
            icon: Icon(
              Icons.edit_outlined,
              color: AppColors.iconFaint,
              size: AppDimensions.iconLarge,
            ),
          ),
          IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text(
                    AppStrings.deleteRule,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  content: Text(
                    'Are you sure you want to delete "${rule.title}"?',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        AppStrings.cancel,
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        AppStrings.delete,
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
              color: AppColors.iconFaint,
              size: AppDimensions.iconLarge,
            ),
          ),
        ],
      ),
    );
  }
}
