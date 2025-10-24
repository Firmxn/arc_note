import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/block_model.dart';
import '../datasources/local_block_datasource.dart';
import '../datasources/remote_block_datasource.dart';
import 'base_repository.dart';

class BlockRepository implements BaseRepository<BlockModel, int> {
  final LocalBlockDataSource _localDataSource;
  final RemoteBlockDataSource _remoteDataSource;

  BlockRepository({
    required LocalBlockDataSource localDataSource,
    required RemoteBlockDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<RepositoryResult<BlockModel>> getById(int id) async {
    try {
      final block = await _localDataSource.getById(id);
      if (block == null) {
        return RepositoryResult.failure('Block with id $id not found');
      }
      return RepositoryResult.success(block);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to get block with id $id',
        RepositoryException('Get by id failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<RepositoryResult<List<BlockModel>>> getAll({bool includeDeleted = false}) async {
    try {
      final blocks = await _localDataSource.getAll(includeDeleted: includeDeleted);
      return RepositoryResult.success(blocks);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to get all blocks',
        RepositoryException('Get all failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<RepositoryResult<BlockModel>> save(BlockModel block) async {
    try {
      // Save locally first
      block.syncStatus = SyncStatus.pending;
      final savedBlock = await _localDataSource.save(block);

      // Try to sync with remote
      final remoteResult = await _remoteDataSource.save(savedBlock);

      if (remoteResult.success && remoteResult.data != null) {
        // Update local with remote data
        savedBlock.remoteId = remoteResult.data!.remoteId;
        savedBlock.syncStatus = SyncStatus.synced;
        final updatedBlock = await _localDataSource.save(savedBlock);
        return RepositoryResult.success(updatedBlock);
      } else {
        // Remote sync failed, but local save succeeded
        return RepositoryResult.success(savedBlock);
      }
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to save block',
        RepositoryException('Save failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<RepositoryResult<bool>> delete(int id) async {
    try {
      // Soft delete locally
      final block = await _localDataSource.getById(id);
      if (block == null) {
        return RepositoryResult.failure('Block with id $id not found');
      }

      block.isDeleted = true;
      block.syncStatus = SyncStatus.pending;
      await _localDataSource.save(block);

      // Try to delete from remote
      if (block.remoteId != null) {
        final remoteResult = await _remoteDataSource.delete(block.remoteId!);
        if (remoteResult.success) {
          // Hard delete locally if remote delete succeeded
          await _localDataSource.delete(id);
        }
      }

      return RepositoryResult.success(true);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to delete block',
        RepositoryException('Delete failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<RepositoryResult<bool>> deleteMultiple(List<int> ids) async {
    try {
      bool allSucceeded = true;
      String? firstError;

      for (final id in ids) {
        final result = await delete(id);
        if (!result.success && firstError == null) {
          firstError = result.error;
          allSucceeded = false;
        }
      }

      return allSucceeded
          ? RepositoryResult.success(true)
          : RepositoryResult.failure(firstError ?? 'Delete multiple failed');
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to delete multiple blocks',
        RepositoryException('Delete multiple failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<RepositoryResult<List<BlockModel>>> getPendingSync() async {
    try {
      final blocks = await _localDataSource.getPendingSync();
      return RepositoryResult.success(blocks);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to get pending sync blocks',
        RepositoryException('Get pending sync failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<RepositoryResult<BlockModel>> updateSyncStatus(int id, SyncStatus status) async {
    try {
      final block = await _localDataSource.getById(id);
      if (block == null) {
        return RepositoryResult.failure('Block with id $id not found');
      }

      block.syncStatus = status;
      final updatedBlock = await _localDataSource.save(block);
      return RepositoryResult.success(updatedBlock);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to update sync status',
        RepositoryException('Update sync status failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<RepositoryResult<List<BlockModel>>> query(
    QueryBuilder<BlockModel, BlockModel, QFilterCondition> queryBuilder,
  ) async {
    try {
      final blocks = await _localDataSource.query(queryBuilder);
      return RepositoryResult.success(blocks);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to query blocks',
        RepositoryException('Query failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  // Additional methods specific to BlockRepository
  Future<RepositoryResult<BlockModel>> getByRemoteId(String remoteId) async {
    try {
      final block = await _localDataSource.getByRemoteId(remoteId);
      if (block == null) {
        return RepositoryResult.failure('Block with remote id $remoteId not found');
      }
      return RepositoryResult.success(block);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to get block by remote id',
        RepositoryException('Get by remote id failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  Future<RepositoryResult<List<BlockModel>>> getBlocksByPageId(String pageId, {bool includeDeleted = false}) async {
    try {
      final blocks = await _localDataSource.getBlocksByPageId(pageId, includeDeleted: includeDeleted);
      return RepositoryResult.success(blocks);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to get blocks for page',
        RepositoryException('Get blocks by page id failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  Future<RepositoryResult<List<BlockModel>>> saveMultiple(List<BlockModel> blocks) async {
    try {
      bool allSucceeded = true;
      String? firstError;
      final savedBlocks = <BlockModel>[];

      for (final block in blocks) {
        final result = await save(block);
        if (result.success && result.data != null) {
          savedBlocks.add(result.data!);
        } else {
          if (firstError == null) firstError = result.error;
          allSucceeded = false;
        }
      }

      return allSucceeded
          ? RepositoryResult.success(savedBlocks)
          : RepositoryResult.failure(firstError ?? 'Save multiple failed');
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to save multiple blocks',
        RepositoryException('Save multiple failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  Future<RepositoryResult<bool>> reorderBlocks(List<BlockModel> blocks) async {
    try {
      // Update order for all blocks
      bool allSucceeded = true;
      String? firstError;

      for (int i = 0; i < blocks.length; i++) {
        final block = blocks[i].copyWith(order: i.toDouble());
        final result = await save(block);
        if (!result.success && firstError == null) {
          firstError = result.error;
          allSucceeded = false;
        }
      }

      return allSucceeded
          ? RepositoryResult.success(true)
          : RepositoryResult.failure(firstError ?? 'Reorder failed');
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to reorder blocks',
        RepositoryException('Reorder failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  Future<RepositoryResult<bool>> deleteBlocksByPageId(String pageId) async {
    try {
      final blocks = await _localDataSource.getBlocksByPageId(pageId);
      final ids = blocks.map((b) => b.id).toList();
      return await deleteMultiple(ids);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to delete blocks by page id',
        RepositoryException('Delete blocks by page id failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }
}

// Provider for BlockRepository
final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  final localDataSource = ref.watch(localBlockDataSourceProvider);
  final remoteDataSource = ref.watch(remoteBlockDataSourceProvider);
  return BlockRepository(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});