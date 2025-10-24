import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../core/services/database_service.dart';
import '../../core/services/dependency_injection.dart';
import '../models/block_model.dart';

class LocalBlockDataSource {
  final DatabaseService _databaseService;

  LocalBlockDataSource(this._databaseService);

  Future<BlockModel?> getById(int id) async {
    final isar = _databaseService.isar;
    return await isar.blockModels.get(id);
  }

  Future<BlockModel?> getByRemoteId(String remoteId) async {
    final isar = _databaseService.isar;
    return await isar.blockModels
        .where()
        .filter()
        .remoteIdEqualTo(remoteId)
        .findFirst();
  }

  Future<List<BlockModel>> getAll({bool includeDeleted = false}) async {
    final isar = _databaseService.isar;
    return await isar.blockModels
        .where()
        .filter()
        .optional(!includeDeleted, (q) => q.isDeletedEqualTo(false))
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<BlockModel> save(BlockModel block) async {
    final isar = _databaseService.isar;
    final id = await isar.writeTxn(() async {
      if (block.id == 0) {
        // New block
        return await isar.blockModels.put(block);
      } else {
        // Update existing block
        await isar.blockModels.put(block);
        return block.id;
      }
    });

    if (id != block.id) {
      // New block was created
      block.id = id;
    }
    return block;
  }

  Future<void> delete(int id) async {
    final isar = _databaseService.isar;
    await isar.writeTxn(() async {
      await isar.blockModels.delete(id);
    });
  }

  Future<List<BlockModel>> getPendingSync() async {
    final isar = _databaseService.isar;
    return await isar.blockModels
        .where()
        .filter()
        .syncStatusEqualTo(SyncStatus.pending)
        .findAll();
  }

  Future<List<BlockModel>> query(
    QueryBuilder<BlockModel, BlockModel, QFilterCondition> queryBuilder,
  ) async {
    return await queryBuilder.findAll();
  }

  Future<List<BlockModel>> getBlocksByPageId(String pageId, {bool includeDeleted = false}) async {
    final isar = _databaseService.isar;
    return await isar.blockModels
        .where()
        .filter()
        .pageIdEqualTo(pageId)
        .optional(includeDeleted, (q) => q.isDeletedEqualTo(true))
        .optional(!includeDeleted, (q) => q.isDeletedEqualTo(false))
        .sortByOrder()
        .findAll();
  }

  Future<List<BlockModel>> getBlocksByPageLocalId(int pageLocalId, {bool includeDeleted = false}) async {
    final isar = _databaseService.isar;
    return await isar.blockModels
        .where()
        .filter()
        .pageLocalIdEqualTo(pageLocalId)
        .optional(includeDeleted, (q) => q.isDeletedEqualTo(true))
        .optional(!includeDeleted, (q) => q.isDeletedEqualTo(false))
        .sortByOrder()
        .findAll();
  }

  Future<List<BlockModel>> getByUserId(String userId, {bool includeDeleted = false}) async {
    final isar = _databaseService.isar;
    return await isar.blockModels
        .where()
        .filter()
        .userIdEqualTo(userId)
        .optional(!includeDeleted, (q) => q.isDeletedEqualTo(false))
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<List<BlockModel>> getBlocksByType(BlockType type, {bool includeDeleted = false}) async {
    final isar = _databaseService.isar;
    return await isar.blockModels
        .where()
        .filter()
        .typeEqualTo(type)
        .optional(!includeDeleted, (q) => q.isDeletedEqualTo(false))
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<List<BlockModel>> getConflictBlocks() async {
    final isar = _databaseService.isar;
    return await isar.blockModels
        .where()
        .filter()
        .syncStatusEqualTo(SyncStatus.conflict)
        .findAll();
  }

  Future<List<BlockModel>> getErrorBlocks() async {
    final isar = _databaseService.isar;
    return await isar.blockModels
        .where()
        .filter()
        .syncStatusEqualTo(SyncStatus.error)
        .findAll();
  }

  Future<int> getMaxOrderForPage(String pageId) async {
    final isar = _databaseService.isar;
    final result = await isar.blockModels
        .where()
        .filter()
        .pageIdEqualTo(pageId)
        .sortByOrderDesc()
        .findFirst();

    return result?.order.toInt() ?? 0;
  }

  Future<void> updateOrderForPage(String pageId, List<BlockModel> blocks) async {
    final isar = _databaseService.isar;
    await isar.writeTxn(() async {
      for (int i = 0; i < blocks.length; i++) {
        blocks[i].order = i.toDouble();
        await isar.blockModels.put(blocks[i]);
      }
    });
  }

  Future<void> clearAll() async {
    final isar = _databaseService.isar;
    await isar.writeTxn(() async {
      await isar.clear<BlockModel>();
    });
  }
}

// Provider for LocalBlockDataSource
final localBlockDataSourceProvider = Provider<LocalBlockDataSource>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return LocalBlockDataSource(databaseService);
});