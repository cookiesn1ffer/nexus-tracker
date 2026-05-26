import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  final int activeIndex;
  final Function(int) onNavigate;

  const AppLayout({
    super.key,
    required this.child,
    required this.activeIndex,
    required this.onNavigate,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_rounded, 'label': 'Dashboard'},
    {'icon': Icons.rule_rounded, 'label': 'Ground Rules'},
    {'icon': Icons.menu_book_rounded, 'label': 'Writeups'},
    {'icon': Icons.bar_chart_rounded, 'label': 'Analytics'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: !isDesktop
          ? AppBar(
              backgroundColor: const Color(0xFF080808),
              elevation: 0,
              title: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'NEXUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              actions: [
                PopupMenuButton<String>(
                  color: const Color(0xFF111111),
                  icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.5)),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'reset',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever_rounded, color: Colors.red.withOpacity(0.7), size: 18),
                          const SizedBox(width: 8),
                          const Text('Reset Data', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      onTap: () => Future.delayed(
                        const Duration(milliseconds: 100),
                        () => _showResetDialog(context),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 240,
              decoration: BoxDecoration(
                color: const Color(0xFF080808),
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              child: Column(
                children: [
                  _buildLogo(),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _navItems.length,
                      itemBuilder: (context, index) {
                        final item = _navItems[index];
                        final isActive = widget.activeIndex == index;
                        return _NavItem(
                          icon: item['icon'] as IconData,
                          label: item['label'] as String,
                          isActive: isActive,
                          onTap: () => widget.onNavigate(index),
                        );
                      },
                    ),
                  ),
                  _buildResetButton(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? Container(
              decoration: BoxDecoration(
                color: const Color(0xFF080808).withOpacity(0.96),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(_navItems.length, (index) {
                      final item = _navItems[index];
                      final isActive = widget.activeIndex == index;
                      return _BottomNavItem(
                        icon: item['icon'] as IconData,
                        label: item['label'] as String,
                        isActive: isActive,
                        onTap: () => widget.onNavigate(index),
                      );
                    }),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: () => _showResetDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                Icons.delete_forever_rounded,
                size: 18,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(width: 12),
              Text(
                'Reset Data',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text(
          'Reset All Data?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will permanently delete all your rules, checklists, writeups, and progress. This cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AppState>().resetAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data reset. Starting fresh.'),
                    backgroundColor: Color(0xFF222222),
                  ),
                );
              }
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
              color: Colors.white.withOpacity(0.05),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NEXUS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                  color: Colors.white.withOpacity(0.03),
                ),
                child: Text(
                  'TRACKER',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive
                ? Colors.white.withOpacity(0.07)
                : Colors.transparent,
            border: isActive
                ? Border.all(color: Colors.white.withOpacity(0.09))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
