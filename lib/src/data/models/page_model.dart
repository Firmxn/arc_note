import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_model.g.dart';

@collection
@JsonSerializable()
class PageModel {
  final Id id = Isar.autoIncrement;

  @JsonKey(name: 'remote_id')
  @Index(unique: true, replace: true)
  String? remoteId;

  @JsonKey(name: 'title')
  String title;

  @JsonKey(name: 'content')
  String? content;

  @JsonKey(name: 'created_at')
  late DateTime createdAt;

  @JsonKey(name: 'updated_at')
  late DateTime updatedAt;

  @JsonKey(name: 'user_id')
  String? userId;

  @JsonKey(name: 'is_deleted')
  bool isDeleted;

  @JsonKey(name: 'sync_status')
  @Index()
  SyncStatus syncStatus;

  PageModel({
    required this.title,
    this.content,
    this.remoteId,
    String? userId,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.pending,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : userId = userId,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Copy with method for immutability
  PageModel copyWith({
    String? title,
    String? content,
    String? remoteId,
    String? userId,
    bool? isDeleted,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PageModel(
      title: title ?? this.title,
      content: content ?? this.content,
      remoteId: remoteId ?? this.remoteId,
      userId: userId ?? this.userId,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // JSON serialization
  factory PageModel.fromJson(Map<String, dynamic> json) => _$PageModelFromJson(json);

  Map<String, dynamic> toJson() => _$PageModelToJson(this);

  // Isar serialization
  factory PageModel.fromIsar(Id id, PageModel page) {
    final newPage = PageModel(
      title: page.title,
      content: page.content,
      remoteId: page.remoteId,
      userId: page.userId,
      isDeleted: page.isDeleted,
      syncStatus: page.syncStatus,
      createdAt: page.createdAt,
      updatedAt: page.updatedAt,
    );
    newPage.id = id;
    return newPage;
  }

  // Sync-related methods
  PageModel markForSync() {
    return copyWith(
      syncStatus: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );
  }

  PageModel markAsSynced() {
    return copyWith(
      syncStatus: SyncStatus.synced,
    );
  }

  PageModel markAsConflict() {
    return copyWith(
      syncStatus: SyncStatus.conflict,
    );
  }

  PageModel markAsError() {
    return copyWith(
      syncStatus: SyncStatus.error,
    );
  }

  PageModel softDelete() {
    return copyWith(
      isDeleted: true,
      syncStatus: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );
  }

  // Comparison for sync conflicts
  bool isNewerThan(PageModel other) {
    return updatedAt.isAfter(other.updatedAt);
  }

  bool isSameAs(PageModel other) {
    return title == other.title &&
           content == other.content &&
           isDeleted == other.isDeleted;
  }

  // Merge with another page (for conflict resolution)
  PageModel mergeWith(PageModel other) {
    // Last-write-wins strategy
    if (isNewerThan(other)) {
      return copyWith(
        syncStatus: SyncStatus.pending,
      );
    } else {
      return other.copyWith(
        id: id, // Keep local ID
        remoteId: remoteId, // Keep remote ID if exists
      );
    }
  }

  @override
  String toString() {
    return 'PageModel{id: $id, remoteId: $remoteId, title: $title, syncStatus: $syncStatus}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageModel &&
           other.id == id &&
           other.remoteId == remoteId &&
           other.title == title &&
           other.content == content &&
           other.userId == userId &&
           other.isDeleted == isDeleted &&
           other.syncStatus == syncStatus;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      remoteId,
      title,
      content,
      userId,
      isDeleted,
      syncStatus,
    );
  }
}

@enumerated
enum SyncStatus {
  pending,
  synced,
  conflict,
  error
}