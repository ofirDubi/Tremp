import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/line.dart';
import '../../providers/lines_browser_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/line_card.dart';
import '../../widgets/shimmer_loading.dart';
import 'line_detail_screen.dart';

/// Lines Browser Screen - Browse and search bus/train lines
/// Phase 6: Implements line browsing with search by number/destination
class LinesBrowserScreen extends StatefulWidget {
  const LinesBrowserScreen({super.key});

  @override
  State<LinesBrowserScreen> createState() => _LinesBrowserScreenState();
}

class _LinesBrowserScreenState extends State<LinesBrowserScreen> {
  late LinesBrowserProvider _provider;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _provider = LinesBrowserProvider();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _provider.searchLines(_searchController.text);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
  }

  void _onLineTap(Line line) {
    // Load line details and navigate
    _provider.loadLineDetails(line.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: _provider,
          child: const LineDetailScreen(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Header with title
              _buildHeader(),

              // Search bar
              _buildSearchBar(),

              // Content: lines list or empty state
              Expanded(
                child: Consumer<LinesBrowserProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.lines.isEmpty) {
                      return _buildLoadingState();
                    }

                    if (provider.error != null && provider.lines.isEmpty) {
                      return _buildErrorState(provider.error!);
                    }

                    return _buildContent(provider);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'קווים',
            style: AppTextStyles.headline2,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Consumer<LinesBrowserProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.searchBarBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'חיפוש קו לפי מספר או יעד',
              hintStyle: AppTextStyles.searchBarHint,
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textTertiary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(LinesBrowserProvider provider) {
    // Show recent lines section if no search query
    if (provider.searchQuery.isEmpty) {
      return CustomScrollView(
        slivers: [
          // Recent lines section
          if (provider.recentLines.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                title: 'קווים אחרונים',
                onClear: provider.clearRecentLines,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final line = provider.recentLines[index];
                  return LineCard(
                    line: line,
                    onTap: () => _onLineTap(line),
                  );
                },
                childCount: provider.recentLines.length,
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
          ],

          // All lines section
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              title: 'כל הקווים',
            ),
          ),
          _buildLinesList(provider.lines),
        ],
      );
    }

    // Show search results
    if (provider.lines.isEmpty) {
      return _buildEmptySearchState();
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            title: 'נמצאו ${provider.lines.length} קווים',
          ),
        ),
        _buildLinesList(provider.lines),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    VoidCallback? onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (onClear != null)
            TextButton(
              onPressed: onClear,
              child: Text(
                'נקה',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLinesList(List<Line> lines) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final line = lines[index];
          return LineCard(
            line: line,
            onTap: () => _onLineTap(line),
          );
        },
        childCount: lines.length,
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      itemBuilder: (context, index) => const LineCardSkeleton(),
    );
  }

  Widget _buildErrorState(String error) {
    // Detect error type and show appropriate message
    if (error.contains('SocketException') || error.contains('Connection refused')) {
      return ErrorState.network(onRetry: () => _provider.loadLines());
    }
    if (error.contains('TimeoutException')) {
      return ErrorState.timeout(onRetry: () => _provider.loadLines());
    }
    return ErrorState(
      title: 'שגיאה בטעינת קווים',
      message: error,
      onRetry: () => _provider.loadLines(),
    );
  }

  Widget _buildEmptySearchState() {
    return EmptyState.noSearchResults(
      subtitle: 'נסה לחפש לפי מספר קו או יעד',
    );
  }
}
