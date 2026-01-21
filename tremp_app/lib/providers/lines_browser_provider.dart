import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/line.dart';
import '../services/api_service.dart';

/// Provider for lines browser functionality
class LinesBrowserProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Line> _lines = [];
  List<Line> _recentLines = [];
  Line? _selectedLine;
  bool _isLoading = false;
  bool _isLineLoading = false;
  String? _error;
  String? _lineError;
  String _searchQuery = '';
  Timer? _debounceTimer;

  static const String _recentLinesKey = 'recent_lines';
  static const int _maxRecentLines = 10;

  LinesBrowserProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService.mock() {
    _loadRecentLines();
    loadLines();
  }

  /// All loaded lines
  List<Line> get lines => _lines;

  /// Recent lines
  List<Line> get recentLines => _recentLines;

  /// Currently selected line (with full stops data)
  Line? get selectedLine => _selectedLine;

  /// Whether lines are being loaded
  bool get isLoading => _isLoading;

  /// Whether a line detail is being loaded
  bool get isLineLoading => _isLineLoading;

  /// Error message if loading failed
  String? get error => _error;

  /// Error message if line detail loading failed
  String? get lineError => _lineError;

  /// Current search query
  String get searchQuery => _searchQuery;

  /// Load lines from API
  Future<void> loadLines({String? query}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final lines = await _apiService.getLines(query: query);
      _lines = lines;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading lines: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search lines with debounce
  void searchLines(String query) {
    _searchQuery = query;
    notifyListeners();

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Debounce search
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      loadLines(query: query.isEmpty ? null : query);
    });
  }

  /// Load a specific line with full details
  Future<void> loadLineDetails(String lineId) async {
    _isLineLoading = true;
    _lineError = null;
    notifyListeners();

    try {
      final line = await _apiService.getLine(lineId);
      _selectedLine = line;
      _lineError = null;

      // Add to recent lines
      _addToRecentLines(line);
    } catch (e) {
      _lineError = e.toString();
      debugPrint('Error loading line details: $e');
    } finally {
      _isLineLoading = false;
      notifyListeners();
    }
  }

  /// Clear the selected line
  void clearSelectedLine() {
    _selectedLine = null;
    _lineError = null;
    notifyListeners();
  }

  /// Add a line to recent lines
  void _addToRecentLines(Line line) {
    // Remove if already in list
    _recentLines.removeWhere((l) => l.id == line.id);

    // Add to front
    _recentLines.insert(0, line);

    // Trim to max size
    if (_recentLines.length > _maxRecentLines) {
      _recentLines = _recentLines.sublist(0, _maxRecentLines);
    }

    // Save to prefs
    _saveRecentLines();
  }

  /// Load recent lines from shared preferences
  Future<void> _loadRecentLines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_recentLinesKey);
      if (json != null) {
        final List<dynamic> list = jsonDecode(json);
        _recentLines = list
            .map((e) => Line.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading recent lines: $e');
    }
  }

  /// Save recent lines to shared preferences
  Future<void> _saveRecentLines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_recentLines.map((l) => l.toJson()).toList());
      await prefs.setString(_recentLinesKey, json);
    } catch (e) {
      debugPrint('Error saving recent lines: $e');
    }
  }

  /// Clear recent lines
  Future<void> clearRecentLines() async {
    _recentLines.clear();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentLinesKey);
    } catch (e) {
      debugPrint('Error clearing recent lines: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _apiService.dispose();
    super.dispose();
  }
}
