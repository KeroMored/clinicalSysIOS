import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service للتخزين المؤقت لبيانات الصفحة الرئيسية
/// يقلل عدد الـ Firestore reads بشكل كبير
class HomeCacheService {
  static const String _fabCacheKey = 'home_fab_cache';
  static const String _fabCacheTimeKey = 'home_fab_cache_time';
  static const String _featuredCacheKey = 'home_featured_cache';
  static const String _featuredCacheTimeKey = 'home_featured_cache_time';
  static const String _offersCacheKey = 'home_offers_cache';
  static const String _offersCacheTimeKey = 'home_offers_cache_time';

  /// Cache الـ FAB results (Floating Action Button queries)
  /// يتحفظ لحد ما المستخدم يضيف/يعدل مكان
  static Future<void> cacheFABResults({
    required String userId,
    required Map<String, dynamic> results,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'userId': userId,
        'results': results,
      };
      await prefs.setString(_fabCacheKey, json.encode(cacheData));
      await prefs.setInt(_fabCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching FAB results: $e');
    }
  }

  /// Get cached FAB results
  /// Returns null if cache expired or not found
  static Future<Map<String, dynamic>?> getCachedFABResults(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheStr = prefs.getString(_fabCacheKey);
      if (cacheStr == null) return null;

      final cacheData = json.decode(cacheStr) as Map<String, dynamic>;
      
      // التحقق من أن الـ cache للمستخدم الصحيح
      if (cacheData['userId'] != userId) return null;

      return cacheData['results'] as Map<String, dynamic>;
    } catch (e) {
      print('Error getting cached FAB results: $e');
      return null;
    }
  }

  /// Clear FAB cache (عند إضافة/تعديل مكان)
  static Future<void> clearFABCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fabCacheKey);
      await prefs.remove(_fabCacheTimeKey);
    } catch (e) {
      print('Error clearing FAB cache: $e');
    }
  }

  /// Cache الـ Featured Locations لحد 12 بالليل
  static Future<void> cacheFeaturedLocations(List<Map<String, dynamic>> locations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_featuredCacheKey, json.encode(locations));
      await prefs.setInt(_featuredCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching featured locations: $e');
    }
  }

  /// Get cached featured locations
  /// Returns null if cache expired (بعد 12 بالليل) or not found
  static Future<List<Map<String, dynamic>>?> getCachedFeaturedLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheStr = prefs.getString(_featuredCacheKey);
      final cacheTime = prefs.getInt(_featuredCacheTimeKey);
      
      if (cacheStr == null || cacheTime == null) return null;

      final cachedDate = DateTime.fromMillisecondsSinceEpoch(cacheTime);
      final now = DateTime.now();
      
      // التحقق: هل الـ cache من نفس اليوم؟
      final isSameDay = cachedDate.year == now.year &&
          cachedDate.month == now.month &&
          cachedDate.day == now.day;
      
      // إذا اليوم اتغير، يبقى الـ cache expired
      if (!isSameDay) {
        await clearFeaturedCache();
        return null;
      }

      final locations = json.decode(cacheStr) as List;
      return locations.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting cached featured locations: $e');
      return null;
    }
  }

  /// Clear featured cache
  static Future<void> clearFeaturedCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_featuredCacheKey);
      await prefs.remove(_featuredCacheTimeKey);
    } catch (e) {
      print('Error clearing featured cache: $e');
    }
  }

  /// Cache الـ Offers لمدة 6 ساعات (للصفحة الرئيسية فقط)
  /// ملاحظة: صفحة "العروض والخصومات" تستخدم real-time بدون cache
  static Future<void> cacheOffers(List<Map<String, dynamic>> offers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_offersCacheKey, json.encode(offers));
      await prefs.setInt(_offersCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching offers: $e');
    }
  }

  /// Get cached offers
  /// Returns null if cache expired (> 6 hours) or not found
  /// يستخدم فقط في الصفحة الرئيسية (carousel)
  static Future<List<Map<String, dynamic>>?> getCachedOffers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheStr = prefs.getString(_offersCacheKey);
      final cacheTime = prefs.getInt(_offersCacheTimeKey);
      
      if (cacheStr == null || cacheTime == null) return null;

      final cachedDate = DateTime.fromMillisecondsSinceEpoch(cacheTime);
      final now = DateTime.now();
      
      // التحقق: هل مر أكثر من 6 ساعات؟
      final difference = now.difference(cachedDate);
      if (difference.inHours > 6) {
        await clearOffersCache();
        return null;
      }

      final offers = json.decode(cacheStr) as List;
      return offers.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting cached offers: $e');
      return null;
    }
  }

  /// Clear offers cache
  static Future<void> clearOffersCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_offersCacheKey);
      await prefs.remove(_offersCacheTimeKey);
    } catch (e) {
      print('Error clearing offers cache: $e');
    }
  }

  /// Clear all home caches
  static Future<void> clearAllCaches() async {
    await clearFABCache();
    await clearFeaturedCache();
    await clearOffersCache();
  }
}
