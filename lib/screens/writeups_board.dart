import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

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
                    'Notebook',
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
                    label: Text(_showForm ? 'Cancel' : 'New Writeup'),
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
                'Log progress diaries, design briefs, snippets, and blockers.',
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
              if (state.writeups.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 48,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'The notebook is empty. Post the first update!',
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
            'New Writeup',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(_titleController, 'Title...'),
          const SizedBox(height: 10),
          _buildTextField(
            _contentController,
            'Notes, blockers, progress...',
            maxLines: 5,
          ),
          const SizedBox(height: 10),
          _buildTextField(_tagsController, 'Tags: success, blockers...'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty ||
                    _contentController.text.isEmpty) return;
                await state.addWriteup(
                  _titleController.text,
                  _contentController.text,
                  _tagsController.text.isEmpty
                      ? null
                      : _tagsController.text,
                );
                _titleController.clear();
                _contentController.clear();
                _tagsController.clear();
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
                'Post Note',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteupCard(dynamic writeup, AppState state) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 14,
                  color: Colors.white.withOpacity(0.4),
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
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDate(writeup.createdAt),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.25),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (writeup.userId == 1)
                IconButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF111111),
                        title: const Text(
                          'Delete Writeup',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          'This writeup will be permanently removed.',
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
                      await state.deleteWriteup(writeup.id);
                    }
                  },
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            writeup.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              writeup.content,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
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
                  .map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.label_outline,
                        size: 10,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tag.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
}
