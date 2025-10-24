import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/dependency_injection.dart';
import '../../core/constants/app_constants.dart';
import '../models/block_model.dart';
import '../repositories/base_repository.dart';

class RemoteBlockDataSource {
  final SupabaseService _supabaseService;

  RemoteBlockDataSource(this._supabaseService);

  Future<RepositoryResult<BlockModel?>> save(BlockModel block) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.blocksTable)
          .upsert({
            'id': block.remoteId,
            'page_id': block.pageId,
            'type': block.type.name,
            'content': block.content,
            'order': block.order,
            'created_at': block.createdAt.toIso8601String(),
            'updated_at': block.updatedAt.toIso8601String(),
            'user_id': block.userId,
            'is_deleted': block.isDeleted,
          })
          .select()
          .single();

      if (response != null) {
        final remoteBlock = BlockModel.fromJson(response);
        return RepositoryResult.success(remoteBlock);
      } else {
        return RepositoryResult.failure('Failed to save block: No response from server');
      }
    } catch (e) {
      return RepositoryResult.failure(
        'Failed to save block to remote',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<RepositoryResult<bool>> delete(String remoteId) async {
    try {
      await _supabaseService.client
          .from(AppConstants.blocksTable)
          .delete()
          .eq('id', remoteId);

      return RepositoryResult.success(true);
    } catch (e) {
      return RepositoryResult.failure(
        'Failed to delete block from remote',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<RepositoryResult<BlockModel?>> getById(String remoteId) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.blocksTable)
          .select()
          .eq('id', remoteId)
          .single();

      if (response != null) {
        final block = BlockModel.fromJson(response);
        return RepositoryResult.success(block);
      } else {
        return RepositoryResult.success(null);
      }
    } catch (e) {
      return RepositoryResult.failure(
        'Failed to get block from remote',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<RepositoryResult<List<BlockModel>>> getAll({String? userId}) async {
    try {
      QueryBuilder query = _supabaseService.client.from(AppConstants.blocksTable).select();

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final response = await query;

      if (response != null) {
        final blocks = (response as List)
            .map((json) => BlockModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return RepositoryResult.success(blocks);
      } else {
        return RepositoryResult.success([]);
      }
    } catch (e) {
      return RepositoryResult.failure(
        'Failed to get all blocks from remote',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<RepositoryResult<List<BlockModel>>> getBlocksByPageId(String pageId, {String? userId}) async {
    try {
      QueryBuilder query = _supabaseService.client
          .from(AppConstants.blocksTable)
          .select()
          .eq('page_id', pageId);

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      query = query.order('order', ascending: true);

      final response = await query;

      if (response != null) {
        final blocks = (response as List)
            .map((json) => BlockModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return RepositoryResult.success(blocks);
      } else {
        return RepositoryResult.success([]);
      }
    } catch (e) {
      return RepositoryResult.failure(
        'Failed to get blocks for page from remote',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<RepositoryResult<List<BlockModel>>> getUpdatedAfter(DateTime updatedAt, {String? userId}) async {
    try {
      QueryBuilder query = _supabaseService.client
          .from(AppConstants.blocksTable)
          .select()
          .gt('updated_at', updatedAt.toIso8601String());

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final response = await query;

      if (response != null) {
        final blocks = (response as List)
            .map((json) => BlockModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return RepositoryResult.success(blocks);
      } else {
        return RepositoryResult.success([]);
      }
    } catch (e) {
      return RepositoryResult.failure(
        'Failed to get updated blocks from remote',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<RepositoryResult<List<BlockModel>>> saveMultiple(List<BlockModel> blocks) async {
    try {
      final data = blocks.map((block) => {
        'id': block.remoteId,
        'page_id': block.pageId,
        'type': block.type.name,
        'content': block.content,
        'order': block.order,
        'created_at': block.createdAt.toIso8601String(),
        'updated_at': block.updatedAt.toIso8601String(),
        'user_id': block.userId,
        'is_deleted': block.isDeleted,
      }).toList();

      final response = await _supabaseService.client
          .from(AppConstants.blocksTable)
          .upsert(data)
          .select();

      if (response != null) {
        final savedBlocks = (response as List)
            .map((json) => BlockModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return RepositoryResult.success(savedBlocks);
      } else {
        return RepositoryResult.failure('Failed to save blocks: No response from server');
      }
    } catch (e) {
      return RepositoryResult.failure(
        'Failed to save blocks to remote',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<RepositoryResult<bool>> deleteMultiple(List<String> remoteIds) async {
    try {
      await _supabaseService.client
          .from(AppConstants.blocksTable)
          .delete()
          .in_('id', remoteIds);

      return RepositoryResult.success(true);
    } catch (e) {
      return RepositoryResult.failure(
        'Failed to delete blocks from remote',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<RepositoryResult<List<BlockModel>>> getConflictBlocks({String? userId}) async {
    try {
      QueryBuilder query = _supabaseService.client
          .from(AppConstants.blocksTable)
          .select()
          .eq('sync_status', 'conflict');

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final response = await query;

      if (response != null) {
        final blocks = (response as List)
            .map((json) => BlockModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return RepositoryResult.success(blocks);
      } else {
        return RepositoryResult.success([]);
      }
    } catch (e) {
      return RepositoryResult.failure(
        'Failed to get conflict blocks from remote',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }
}

// Provider for RemoteBlockDataSource
final remoteBlockDataSourceProvider = Provider<RemoteBlockDataSource>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return RemoteBlockDataSource(supabaseService);
});