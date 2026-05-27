import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../constants.dart';
import '../widgets/common.dart';

class WriteupsBoardScreen extends StatefulWidget {
  const WriteupsBoardScreen({super.key});

  @override
  State<WriteupsBoardScreen> createState() => _WriteupsBoardScreenState();
}

class _WriteupsBoardScreenState extends State<WriteupsBoardScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _showForm = false;
  int? _editingWriteupId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadWriteups();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _startEdit(dynamic writeup) {
    setState(() {
      _editingWriteupId = writeup.id;
      _titleController.text = writeup.title;
      _contentController.text = writeup.content;
      _tagsController.text = writeup.tags ?? '';
      _showForm = true;
    });
  }

  void _cancelForm() {
    setState(() {
      _showForm = false;
      _editingWriteupId = null;
      _titleController.clear();
      _contentController.clear();
      _tagsController.clear();
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
                    AppStrings.notebook,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppDimensions.fontSizeHeading,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  AppButton(
                    text: _showForm ? AppStrings.cancel : AppStrings.newWriteup,
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
                'Log progress diaries, design briefs, snippets, and blockers.',
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
              if (state.writeups.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: AppDimensions.iconXL,
                          color: AppColors.iconSubtle,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'The notebook is empty. Post the first update!',
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
                  itemCount: state.writeups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final writeup = state.writeups[index];
                    return _buildWriteupCard(writeup, state);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForm(AppState state) {
    final isEditing = _editingWriteupId != null;
    return AppCard(
      borderRadius: AppDimensions.borderRadiusXL,
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? AppStrings.editWriteup : AppStrings.newWriteup,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppDimensions.fontSizeTitle,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          AppTextField(
            controller: _titleController,
            hint: 'Title...',
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: _contentController,
            hint: 'Notes, blockers, progress...',
            maxLines: 5,
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: _tagsController,
            hint: 'Tags: success, blockers...',
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty ||
                    _contentController.text.isEmpty) return;
                final tags = _tagsController.text.isEmpty
                    ? null
                    : _tagsController.text;
                if (isEditing) {
                  await state.updateWriteup(
                    _editingWriteupId!,
                    _titleController.text,
                    _contentController.text,
                    tags,
                  );
                } else {
                  await state.addWriteup(
                    _titleController.text,
                    _contentController.text,
                    tags,
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
                isEditing ? AppStrings.updateNote : AppStrings.postNote,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteupCard(dynamic writeup, AppState state) {
    return AppCard(
      borderRadius: AppDimensions.borderRadiusXL,
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.fillMedium,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: AppDimensions.iconSmall,
                  color: AppColors.iconDefault,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${writeup.username}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppDimensions.fontSizeLarge,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDate(writeup.createdAt),
                      style: TextStyle(
                        color: AppColors.textSubtle,
                        fontSize: AppDimensions.fontSizeXS,
                      ),
                    ),
                  ],
                ),
              ),
              if (writeup.userId == 1) ...[
                IconButton(
                  onPressed: () => _startEdit(writeup),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: AppDimensions.iconMedium,
                    color: AppColors.iconFaint,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text(
                          AppStrings.deleteWriteup,
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        content: Text(
                          'This writeup will be permanently removed.',
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
                      await state.deleteWriteup(writeup.id);
                    }
                  },
                  icon: Icon(
                    Icons.delete_outline,
                    size: AppDimensions.iconMedium,
                    color: AppColors.iconFaint,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            writeup.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppDimensions.fontSizeXL,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              writeup.content,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppDimensions.fontSizeMedium,
                height: 1.5,
              ),
            ),
          ),
          if (writeup.tags != null && writeup.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (writeup.tags as String)
                  .split(',')
                  .map((tag) => tag.trim())
                  .where((tag) => tag.isNotEmpty)
                  .map((tag) => AppBadge(text: tag, icon: Icons.label_outline))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = _monthName(date.month);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month ${date.day}, $hour:$minute';
  }

  String _monthName(int month) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month];
  }
}
