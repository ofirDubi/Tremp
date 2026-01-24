import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing user profile and settings
class ProfileProvider extends ChangeNotifier {
  // User profile data
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';

  // Language setting
  String _languageCode = 'he'; // Hebrew default

  // Trip history (simplified - in real app would come from API)
  List<TripRecord> _tripHistory = [];

  ProfileProvider() {
    _loadSavedData();
  }

  // Getters
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  String get languageCode => _languageCode;
  List<TripRecord> get tripHistory => List.unmodifiable(_tripHistory);

  /// Get greeting based on user name
  String get greeting {
    if (_userName.isNotEmpty) {
      return _getLocalizedGreeting(_userName);
    }
    return _getLocalizedGreeting(null);
  }

  String _getLocalizedGreeting(String? name) {
    switch (_languageCode) {
      case 'he':
        return name != null ? 'שלום, $name!' : 'שלום!';
      case 'ar':
        return name != null ? 'مرحبا، $name!' : 'مرحبا!';
      case 'en':
      default:
        return name != null ? 'Hello, $name!' : 'Hello!';
    }
  }

  /// Get language display name
  String get languageDisplayName {
    switch (_languageCode) {
      case 'he':
        return 'עברית';
      case 'ar':
        return 'العربية';
      case 'en':
      default:
        return 'English';
    }
  }

  /// Get available languages
  static List<LanguageOption> get availableLanguages => const [
        LanguageOption(code: 'he', name: 'עברית', nativeName: 'Hebrew'),
        LanguageOption(code: 'en', name: 'English', nativeName: 'English'),
        LanguageOption(code: 'ar', name: 'العربية', nativeName: 'Arabic'),
      ];

  /// Update user name
  Future<void> setUserName(String name) async {
    _userName = name;
    await _saveProfile();
    notifyListeners();
  }

  /// Update user email
  Future<void> setUserEmail(String email) async {
    _userEmail = email;
    await _saveProfile();
    notifyListeners();
  }

  /// Update user phone
  Future<void> setUserPhone(String phone) async {
    _userPhone = phone;
    await _saveProfile();
    notifyListeners();
  }

  /// Update profile data in one call
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    if (name != null) _userName = name;
    if (email != null) _userEmail = email;
    if (phone != null) _userPhone = phone;
    await _saveProfile();
    notifyListeners();
  }

  /// Change language
  Future<void> setLanguage(String code) async {
    if (_languageCode != code) {
      _languageCode = code;
      await _saveLanguage();
      notifyListeners();
    }
  }

  /// Add a trip to history (for demonstration)
  Future<void> addTripRecord(TripRecord trip) async {
    _tripHistory.insert(0, trip);
    // Keep only last 50 trips
    if (_tripHistory.length > 50) {
      _tripHistory = _tripHistory.take(50).toList();
    }
    await _saveTripHistory();
    notifyListeners();
  }

  /// Clear trip history
  Future<void> clearTripHistory() async {
    _tripHistory = [];
    await _saveTripHistory();
    notifyListeners();
  }

  /// Load all saved data from SharedPreferences
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load profile
    _userName = prefs.getString('profile_name') ?? '';
    _userEmail = prefs.getString('profile_email') ?? '';
    _userPhone = prefs.getString('profile_phone') ?? '';

    // Load language
    _languageCode = prefs.getString('language_code') ?? 'he';

    // Load trip history
    final historyJson = prefs.getString('trip_history');
    if (historyJson != null) {
      try {
        final historyList = json.decode(historyJson) as List<dynamic>;
        _tripHistory = historyList
            .map((e) => TripRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _tripHistory = [];
      }
    }

    notifyListeners();
  }

  /// Save profile to SharedPreferences
  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _userName);
    await prefs.setString('profile_email', _userEmail);
    await prefs.setString('profile_phone', _userPhone);
  }

  /// Save language to SharedPreferences
  Future<void> _saveLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', _languageCode);
  }

  /// Save trip history to SharedPreferences
  Future<void> _saveTripHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'trip_history',
      json.encode(_tripHistory.map((e) => e.toJson()).toList()),
    );
  }
}

/// Language option model
class LanguageOption {
  final String code;
  final String name;
  final String nativeName;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}

/// A trip record for history
class TripRecord {
  final String id;
  final String origin;
  final String destination;
  final DateTime timestamp;
  final int durationMinutes;
  final String? lineNumber;

  const TripRecord({
    required this.id,
    required this.origin,
    required this.destination,
    required this.timestamp,
    required this.durationMinutes,
    this.lineNumber,
  });

  factory TripRecord.fromJson(Map<String, dynamic> json) {
    return TripRecord(
      id: json['id'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      durationMinutes: json['duration_minutes'] as int,
      lineNumber: json['line_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origin': origin,
      'destination': destination,
      'timestamp': timestamp.toIso8601String(),
      'duration_minutes': durationMinutes,
      'line_number': lineNumber,
    };
  }
}
