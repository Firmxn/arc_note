import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/page_model.dart';
import '../datasources/local_page_datasource.dart';
import '../datasources/remote_page_datasource.dart';
import 'base_repository.dart';

class PageRepository implements BaseRepository<PageModel, int> {
  final LocalPageDataSource _localDataSource;
  final RemotePageDataSource _remoteDataSource;

  PageRepository({
    required LocalPageDataSource localDataSource,
    required RemotePageDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<RepositoryResult<PageModel>> getById(int id) async {
    try {
      final page = await _localDataSource.getById(id);
      if (page == null) {
        return RepositoryResult.failure('Page with id $id not found');
      }
      return RepositoryResult.success(page);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to get page with id $id',
        RepositoryException('Get by id failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<RepositoryResult<List<PageModel>>> getAll({bool includeDeleted = false}) async {
    try {
      final pages = await _localDataSource.getAll(includeDeleted: includeDeleted);
      return RepositoryResult.success(pages);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to get all pages',
        RepositoryException('Get all failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<RepositoryResult<PageModel>> save(PageModel page) async {
    try {
      // Save locally first
      page.syncStatus = SyncStatus.pending;
      final savedPage = await _localDataSource.save(page);

      // Try to sync with remote
      final remoteResult = await _remoteDataSource.save(savedPage);

      if (remoteResult.success && remoteResult.data != null) {
        // Update local with remote data
        savedPage.remoteId = remoteResult.data!.remoteId;
        savedPage.syncStatus = SyncStatus.synced;
        final updatedPage = await _localDataSource.save(savedPage);
        return RepositoryResult.success(updatedPage);
      } else {
        // Remote sync failed, but local save succeeded
        return RepositoryResult.success(savedPage);
      }
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to save page',
        RepositoryException('Save failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<RepositoryResult<bool>> delete(int id) async {
    try {
      // Soft delete locally
      final page = await _localDataSource.getById(id);
      if (page == null) {
        return RepositoryResult.failure('Page with id $id not found');
      }

      page.isDeleted = true;
      page.syncStatus = SyncStatus.pending;
      await _localDataSource.save(page);

      // Try to delete from remote
      if (page.remoteId != null) {
        final remoteResult = await _remoteDataSource.delete(page.remoteId!);
        if (remoteResult.success) {
          // Hard delete locally if remote delete succeeded
          await _localDataSource.delete(id);
        }
      }

      return RepositoryResult.success(true);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to delete page',
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
        'Failed to delete multiple pages',
        RepositoryException('Delete multiple failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<RepositoryResult<List<PageModel>>> getPendingSync() async {
    try {
      final pages = await _localDataSource.getPendingSync();
      return RepositoryResult.success(pages);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to get pending sync pages',
        RepositoryException('Get pending sync failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<RepositoryResult<PageModel>> updateSyncStatus(int id, SyncStatus status) async {
    try {
      final page = await _localDataSource.getById(id);
      if (page == null) {
        return RepositoryResult.failure('Page with id $id not found');
      }

      page.syncStatus = status;
      final updatedPage = await _localDataSource.save(page);
      return RepositoryResult.success(updatedPage);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to update sync status',
        RepositoryException('Update sync status failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<RepositoryResult<List<PageModel>>> query(
    QueryBuilder<PageModel, PageModel, QFilterCondition> queryBuilder,
  ) async {
    try {
      final pages = await _localDataSource.query(queryBuilder);
      return RepositoryResult.success(pages);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to query pages',
        RepositoryException('Query failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  // Additional methods specific to PageRepository
  Future<RepositoryResult<PageModel>> getByRemoteId(String remoteId) async {
    try {
      final page = await _localDataSource.getByRemoteId(remoteId);
      if (page == null) {
        return RepositoryResult.failure('Page with remote id $remoteId not found');
      }
      return RepositoryResult.success(page);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to get page by remote id',
        RepositoryException('Get by remote id failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }

  Future<RepositoryResult<List<PageModel>>> searchByTitle(String query) async {
    try {
      final pages = await _localDataSource.searchByTitle(query);
      return RepositoryResult.success(pages);
    } catch (e, stackTrace) {
      return RepositoryResult.failure(
        'Failed to search pages by title',
        RepositoryException('Search by title failed', originalError: e, stackTrace: stackTrace),
      );
    }
  }
}

// Provider for PageRepository
final pageRepositoryProvider = Provider<PageRepository>((ref) {
  final localDataSource = ref.watch(localPageDataSourceProvider);
  final remoteDataSource = ref.watch(remotePageDataSourceProvider);
  return PageRepository(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});