import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// A draggable bottom sheet container with tabs
/// Used on the map home screen for Nearby Routes and Favorites
class BottomSheetContainer extends StatefulWidget {
  /// The tabs to display
  final List<BottomSheetTab> tabs;

  /// Initial tab index
  final int initialTab;

  /// Minimum height as fraction of screen (0.0 - 1.0)
  final double minHeight;

  /// Maximum height as fraction of screen (0.0 - 1.0)
  final double maxHeight;

  /// Callback when the sheet is fully collapsed
  final VoidCallback? onCollapsed;

  const BottomSheetContainer({
    super.key,
    required this.tabs,
    this.initialTab = 0,
    this.minHeight = 0.15,
    this.maxHeight = 0.7,
    this.onCollapsed,
  });

  @override
  State<BottomSheetContainer> createState() => _BottomSheetContainerState();
}

class _BottomSheetContainerState extends State<BottomSheetContainer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late double _currentHeight;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _currentHeight = widget.minHeight;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxScreenHeight) {
    setState(() {
      // Convert drag delta to height change (negative delta means dragging up)
      final heightChange = -details.delta.dy / maxScreenHeight;
      _currentHeight = (_currentHeight + heightChange)
          .clamp(widget.minHeight, widget.maxHeight);
      _isExpanded = _currentHeight > (widget.minHeight + widget.maxHeight) / 2;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    // Snap to either min or max height based on velocity and current position
    final velocity = details.velocity.pixelsPerSecond.dy;
    final shouldExpand = velocity < -500 ||
        (velocity.abs() < 500 && _currentHeight > (widget.minHeight + widget.maxHeight) / 2);

    setState(() {
      _currentHeight = shouldExpand ? widget.maxHeight : widget.minHeight;
      _isExpanded = shouldExpand;
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      _currentHeight = _isExpanded ? widget.maxHeight : widget.minHeight;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * _currentHeight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: AppColors.bottomSheetColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle area
          GestureDetector(
            onVerticalDragUpdate: (details) =>
                _onDragUpdate(details, screenHeight),
            onVerticalDragEnd: _onDragEnd,
            onTap: _toggleExpanded,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          // Tab bar
          if (widget.tabs.length > 1)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                dividerColor: Colors.transparent,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTextStyles.labelLarge,
                unselectedLabelStyle: AppTextStyles.labelLarge,
                tabs: widget.tabs.map((tab) {
                  return Tab(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (tab.icon != null) ...[
                          Icon(tab.icon, size: 18),
                          const SizedBox(width: 6),
                        ],
                        Text(tab.label),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 12),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: widget.tabs.map((tab) => tab.content).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tab configuration for the bottom sheet
class BottomSheetTab {
  final String label;
  final IconData? icon;
  final Widget content;

  const BottomSheetTab({
    required this.label,
    this.icon,
    required this.content,
  });
}
