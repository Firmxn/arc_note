import 'package:isar/isar.dart';

// Generic result class for repository operations
class RepositoryResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final Exception? exception;

  RepositoryResult.success(this.data)
      : success = true,
        error = null,
        exception = null;

  RepositoryResult.failure(this.error, [this.exception])
      : success = false,
        data = null;
}

// Base repository interface
abstract class BaseRepository<T, ID> {
  // CRUD operations
  Future<RepositoryResult<T>> getById(ID id);
  Future<RepositoryResult<List<T>>> getAll({bool includeDeleted = false});
  Future<RepositoryResult<T>> save(T entity);
  Future<RepositoryResult<bool>> delete(ID id);
  Future<RepositoryResult<bool>> deleteMultiple(List<ID> ids);

  // Sync operations
  Future<RepositoryResult<List<T>>> getPendingSync();
  Future<RepositoryResult<T>> updateSyncStatus(ID id, SyncStatus status);

  // Query operations
  Future<RepositoryResult<List<T>>> query(
    QueryBuilder<T, T, QFilterCondition> queryBuilder,
  );
}

// Sync status enum
enum SyncStatus {
  pending,
  synced,
  conflict,
  error
}

// Base entity interface
abstract class BaseEntity {
  String? get remoteId;
  DateTime get createdAt;
  DateTime get updatedAt;
  bool get isDeleted;
  SyncStatus get syncStatus;

  BaseEntity copyWith({
    String? remoteId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    SyncStatus? syncStatus,
  });
}

// Generic repository exception
class RepositoryException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  RepositoryException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'RepositoryException: $message';
  }
}