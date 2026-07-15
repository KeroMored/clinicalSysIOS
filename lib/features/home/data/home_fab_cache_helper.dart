import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/home_cache_service.dart';

/// Helper class للتعامل مع FAB queries caching
/// يقلل من 7 reads إلى 0 reads بعد أول مرة
class HomeFABCacheHelper {
  /// Load FAB queries with caching
  /// Returns cached data if available, otherwise loads from Firestore
  static Future<Map<String, dynamic>> loadFABQueries(String userEmail) async {
    try {
      // Try cache first
      final cached = await HomeCacheService.getCachedFABResults(userEmail);
      
      if (cached != null) {
        print('✅ [FAB Cache] Using cached results - 0 reads');
        return cached;
      }
      
      print('📥 [FAB Cache] Loading from Firestore - 7 reads');
      
      // Load from Firestore
      final pharmacies = await FirebaseFirestore.instance
          .collection('pharmacies')
          .where('authEmails', arrayContains: userEmail)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();
      
      // Clinics: Get both owner clinics AND secretary clinics
      final authClinics = await FirebaseFirestore.instance
          .collection('clinics')
          .where('authEmails', arrayContains: userEmail)
          .get();
      
      final secretaryClinics = await FirebaseFirestore.instance
          .collection('clinics')
          .where('secretaryEmails', arrayContains: userEmail)
          .get();
      
      // Combine clinic docs (remove duplicates)
      final Map<String, QueryDocumentSnapshot> clinicMap = {};
      for (var doc in authClinics.docs) {
        clinicMap[doc.id] = doc;
      }
      for (var doc in secretaryClinics.docs) {
        clinicMap[doc.id] = doc;
      }
      final clinicDocs = clinicMap.values.toList();
      
      final results = await Future.wait([
        Future.value(pharmacies),
        FirebaseFirestore.instance
            .collection('laboratories')
            .where('authEmails', arrayContains: userEmail)
            .where('status', isEqualTo: 'approved')
            .limit(1)
            .get(),
        FirebaseFirestore.instance
            .collection('radiology_centers')
            .where('authEmails', arrayContains: userEmail)
            .where('isApproved', isEqualTo: true)
            .limit(1)
            .get(),
        FirebaseFirestore.instance
            .collection('gyms')
            .where('authEmails', arrayContains: userEmail)
            .where('isApproved', isEqualTo: true)
            .limit(1)
            .get(),
        FirebaseFirestore.instance
            .collection('settingsforpatiants')
            .limit(1)
            .get(),
        FirebaseFirestore.instance
            .collection('medical_supplies')
            .where('authEmails', arrayContains: userEmail)
            .where('status', isEqualTo: 'approved')
            .limit(1)
            .get(),
      ]);
      
      // Convert to cacheable format
      final cacheData = {
        'pharmacies': _snapshotToCacheMap(results[0]),
        'clinics': _docsListToCacheMap(clinicDocs),  // Use custom function for combined docs
        'laboratories': _snapshotToCacheMap(results[1]),
        'radiology_centers': _snapshotToCacheMap(results[2]),
        'gyms': _snapshotToCacheMap(results[3]),
        'settings': _snapshotToCacheMap(results[4]),
        'medical_supplies': _snapshotToCacheMap(results[5]),
      };
      
      // Cache the results for future use
      await HomeCacheService.cacheFABResults(
        userId: userEmail,
        results: cacheData,
      );
      
      print('💾 [FAB Cache] Cached results for future use');
      
      return cacheData;
    } catch (e) {
      print('❌ [FAB Cache] Error: $e');
      rethrow;
    }
  }

  /// Convert QuerySnapshot to cacheable map format
  static Map<String, dynamic> _snapshotToCacheMap(QuerySnapshot snapshot) {
    return {
      'isEmpty': snapshot.docs.isEmpty,
      'size': snapshot.docs.length,
      'docs': snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'data': data is Map<String, dynamic> ? data : {},
        };
      }).toList(),
    };
  }

  /// Convert list of QueryDocumentSnapshot to cacheable map format
  static Map<String, dynamic> _docsListToCacheMap(List<QueryDocumentSnapshot> docs) {
    return {
      'isEmpty': docs.isEmpty,
      'size': docs.length,
      'docs': docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'data': data is Map<String, dynamic> ? data : {},
        };
      }).toList(),
    };
  }

  /// Check if a collection is empty in cached data
  static bool isCollectionEmpty(
    Map<String, dynamic> cacheData,
    String collectionName,
  ) {
    final collection = cacheData[collectionName] as Map<String, dynamic>?;
    return collection?['isEmpty'] == true || collection == null;
  }

  /// Get documents from a collection in cached data
  static List<Map<String, dynamic>> getCollectionDocs(
    Map<String, dynamic> cacheData,
    String collectionName,
  ) {
    final collection = cacheData[collectionName] as Map<String, dynamic>?;
    if (collection == null) return [];
    
    final docs = collection['docs'] as List?;
    if (docs == null) return [];
    
    return docs.map((doc) => doc as Map<String, dynamic>).toList();
  }

  /// Get first document data from a collection
  static Map<String, dynamic>? getFirstDocData(
    Map<String, dynamic> cacheData,
    String collectionName,
  ) {
    final docs = getCollectionDocs(cacheData, collectionName);
    if (docs.isEmpty) return null;
    
    final firstDoc = docs.first;
    return {
      'id': firstDoc['id'],
      ...firstDoc['data'] as Map<String, dynamic>,
    };
  }

  /// Clear FAB cache (call when user adds/edits a location)
  static Future<void> clearCache() async {
    await HomeCacheService.clearFABCache();
    print('🗑️ [FAB Cache] Cache cleared');
  }
}
