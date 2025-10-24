import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/page_model.dart';
import '../../data/models/block_model.dart';
import '../utils/app_logger.dart';
import '../constants/app_constants.dart';

class DatabaseService {
  late Isar _isar;
  bool _initialized = false;

  bool get isInitialized => _initialized;
  Isar get isar => _isar;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/${AppConstants.databaseName}';

      _isar = await Isar.open(
        [
          PageModelSchema,
          BlockModelSchema,
        ],
        directory: dbPath,
        inspector: true, // Enable for debugging
      );

      _initialized = true;
      AppLogger.info('Database initialized successfully at: $dbPath');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize database', e, stackTrace);
      rethrow;
    }
  }

  // Page operations
  Future<List<PageModel>> getAllPages({bool includeDeleted = false}) async {
    try {
      if (!_initialized) await initialize();

      return await _isar.pageModels
          .where()
          .filter()
          .optional(!includeDeleted, (q) => q.isDeletedEqualTo(false))
          .sortByUpdatedAtDesc()
          .findAll();
    } catch (e) {
      AppLogger.error('Failed to get all pages', e);
      rethrow;
    }
  }

  Future<PageModel?> getPageById(int id) async {
    try {
      if (!_initialized) await initialize();

      return await _isar.pageModels.get(id);
    } catch (e) {
      AppLogger.error('Failed to get page by id: $id', e);
      return null;
    }
  }

  Future<PageModel?> getPageByRemoteId(String remoteId) async {
    try {
      if (!_initialized) await initialize();

      return await _isar.pageModels
          .where()
          .filter()
          .remoteIdEqualTo(remoteId)
          .findFirst();
    } catch (e) {
      AppLogger.error('Failed to get page by remote id: $remoteId', e);
      return null;
    }
  }

  Future<int> savePage(PageModel page) async {
    try {
      if (!_initialized) await initialize();

      page.updatedAt = DateTime.now();

      return await _isar.writeTxn(() async {
        if (page.id == 0) {
          // New page
          return await _isar.pageModels.put(page);
        } else {
          // Update existing page
          await _isar.pageModels.put(page);
          return page.id;
        }
      });
    } catch (e) {
      AppLogger.error('Failed to save page', e);
      rethrow;
    }
  }

  Future<void> deletePage(int id) async {
    try {
      if (!_initialized) await initialize();

      await _isar.writeTxn(() async {
        await _isar.pageModels.delete(id);
      });
    } catch (e) {
      AppLogger.error('Failed to delete page: $id', e);
      rethrow;
    }
  }

  // Block operations
  Future<List<BlockModel>> getBlocksByPageId(String pageId, {bool includeDeleted = false}) async {
    try {
      if (!_initialized) await initialize();

      return await _isar.blockModels
          .where()
          .filter()
          .pageIdEqualTo(pageId)
          .optional(includeDeleted, (q) => q.isDeletedEqualTo(true))
          .sortByOrder()
          .findAll();
    } catch (e) {
      AppLogger.error('Failed to get blocks for page: $pageId', e);
      return [];
    }
  }

  Future<BlockModel?> getBlockByRemoteId(String remoteId) async {
    try {
      if (!_initialized) await initialize();

      return await _isar.blockModels
          .where()
          .filter()
          .remoteIdEqualTo(remoteId)
          .findFirst();
    } catch (e) {
      AppLogger.error('Failed to get block by remote id: $remoteId', e);
      return null;
    }
  }

  Future<int> saveBlock(BlockModel block) async {
    try {
      if (!_initialized) await initialize();

      block.updatedAt = DateTime.now();

      return await _isar.writeTxn(() async {
        if (block.id == 0) {
          // New block
          return await _isar.blockModels.put(block);
        } else {
          // Update existing block
          await _isar.blockModels.put(block);
          return block.id;
        }
      });
    } catch (e) {
      AppLogger.error('Failed to save block', e);
      rethrow;
    }
  }

  Future<void> deleteBlock(int id) async {
    try {
      if (!_initialized) await initialize();

      await _isar.writeTxn(() async {
        await _isar.blockModels.delete(id);
      });
    } catch (e) {
      AppLogger.error('Failed to delete block: $id', e);
      rethrow;
    }
  }

  // Sync operations
  Future<List<PageModel>> getPendingSyncPages() async {
    try {
      if (!_initialized) await initialize();

      return await _isar.pageModels
          .where()
          .filter()
          .syncStatusEqualTo(SyncStatus.pending)
          .findAll();
    } catch (e) {
      AppLogger.error('Failed to get pending sync pages', e);
      return [];
    }
  }

  Future<List<BlockModel>> getPendingSyncBlocks() async {
    try {
      if (!_initialized) await initialize();

      return await _isar.blockModels
          .where()
          .filter()
          .syncStatusEqualTo(SyncStatus.pending)
          .findAll();
    } catch (e) {
      AppLogger.error('Failed to get pending sync blocks', e);
      return [];
    }
  }

  // Cleanup operations
  Future<void> clearAllData() async {
    try {
      if (!_initialized) await initialize();

      await _isar.writeTxn(() async {
        await _isar.clear();
      });

      AppLogger.info('All data cleared from database');
    } catch (e) {
      AppLogger.error('Failed to clear database', e);
      rethrow;
    }
  }

  Future<void> close() async {
    if (_initialized) {
      await _isar.close();
      _initialized = false;
      AppLogger.info('Database closed');
    }
  }
}

// Provider for DatabaseService
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});