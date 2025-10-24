import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../core/services/database_service.dart';
import '../../core/services/dependency_injection.dart';
import '../models/page_model.dart';

class LocalPageDataSource {
  final DatabaseService _databaseService;

  LocalPageDataSource(this._databaseService);

  Future<PageModel?> getById(int id) async {
    return await _databaseService.getPageById(id);
  }

  Future<PageModel?> getByRemoteId(String remoteId) async {
    return await _databaseService.getPageByRemoteId(remoteId);
  }

  Future<List<PageModel>> getAll({bool includeDeleted = false}) async {
    return await _databaseService.getAllPages(includeDeleted: includeDeleted);
  }

  Future<PageModel> save(PageModel page) async {
    final id = await _databaseService.savePage(page);
    if (id != page.id) {
      // New page was created
      page.id = id;
    }
    return page;
  }

  Future<void> delete(int id) async {
    await _databaseService.deletePage(id);
  }

  Future<List<PageModel>> getPendingSync() async {
    return await _databaseService.getPendingSyncPages();
  }

  Future<List<PageModel>> query(
    QueryBuilder<PageModel, PageModel, QFilterCondition> queryBuilder,
  ) async {
    return await queryBuilder.findAll();
  }

  Future<List<PageModel>> searchByTitle(String query) async {
    final isar = _databaseService.isar;
    return await isar.pageModels
        .where()
        .filter()
        .titleContains(query, caseSensitive: false)
        .isDeletedEqualTo(false)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<List<PageModel>> getByUserId(String userId, {bool includeDeleted = false}) async {
    final isar = _databaseService.isar;
    return await isar.pageModels
        .where()
        .filter()
        .userIdEqualTo(userId)
        .optional(!includeDeleted, (q) => q.isDeletedEqualTo(false))
        .sortByUpdatedAtDesc()
        .findAll();
  }
}

// Provider for LocalPageDataSource
final localPageDataSourceProvider = Provider<LocalPageDataSource>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return LocalPageDataSource(databaseService);
});