import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/dependency_injection.dart';
import '../../core/constants/app_constants.dart';
import '../models/page_model.dart';
import '../repositories/base_repository.dart';

class RemotePageDataSource {
  final SupabaseService _supabaseService;

  RemotePageDataSource(this._supabaseService);

  Future<RepositoryResult<PageModel?>> save(PageModel page) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.pagesTable)
          .upsert({
            'id': page.remoteId,
            'title': page.title,
            'content': page.content,
            'created_at': page.createdAt.toIso8601String(),
            'updated_at': page.updatedAt.toIso8601String(),
            'user_id': page.userId,
            'is_deleted': page.isDeleted,
          })
          .select()
          .single();

      if (response != null) {
        final remotePage = PageModel.fromJson(response);
        return RepositoryResult.success(remotePage);
      } else {
        return RepositoryResult.failure('Failed to save page: No response from server');
      }
    } catch (e) {
      return RepositoryResult.failure(
        'Failed to save page to remote',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<RepositoryResult<bool>> delete(String remoteId) async {
    try {
      await _supabaseService.client
          .from(AppConstants.pagesTable)
          .delete()
          .eq('id', remoteId);

      return RepositoryResult.success(true);
    } catch (e) {
      return RepositoryResult.failure(
        'Failed to delete page from remote',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<RepositoryResult<PageModel?>> getById(String remoteId) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.pagesTable)
          .select()
          .eq('id', remoteId)
          .single();

      if (response != null) {
        final page = PageModel.fromJson(response);
        return RepositoryResult.success(page);
      } else {
        return RepositoryResult.success(null);
      }
    } catch (e) {
      return RepositoryResult.failure(
        'Failed to get page from remote',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<RepositoryResult<List<PageModel>>> getAll({String? userId}) async {
    try {
      QueryBuilder query = _supabaseService.client.from(AppConstants.pagesTable).select();

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final response = await query;

      if (response != null) {
        final pages = (response as List)
            .map((json) => PageModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return RepositoryResult.success(pages);
      } else {
        return RepositoryResult.success([]);
      }
    } catch (e) {
      return RepositoryResult.failure(
        'Failed to get all pages from remote',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<RepositoryResult<List<PageModel>>> getUpdatedAfter(DateTime updatedAt) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.pagesTable)
          .select()
          .gt('updated_at', updatedAt.toIso8601String());

      if (response != null) {
        final pages = (response as List)
            .map((json) => PageModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return RepositoryResult.success(pages);
      } else {
        return RepositoryResult.success([]);
      }
    } catch (e) {
      return RepositoryResult.failure(
        'Failed to get updated pages from remote',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<RepositoryResult<List<PageModel>>> searchByTitle(String query, {String? userId}) async {
    try {
      QueryBuilder dbQuery = _supabaseService.client
          .from(AppConstants.pagesTable)
          .select()
          .ilike('title', '%$query%');

      if (userId != null) {
        dbQuery = dbQuery.eq('user_id', userId);
      }

      final response = await dbQuery;

      if (response != null) {
        final pages = (response as List)
            .map((json) => PageModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return RepositoryResult.success(pages);
      } else {
        return RepositoryResult.success([]);
      }
    } catch (e) {
      return RepositoryResult.failure(
        'Failed to search pages in remote',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }
}

// Provider for RemotePageDataSource
final remotePageDataSourceProvider = Provider<RemotePageDataSource>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return RemotePageDataSource(supabaseService);
});