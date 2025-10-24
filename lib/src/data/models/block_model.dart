import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'block_model.g.dart';

@collection
@JsonSerializable()
class BlockModel {
  final Id id = Isar.autoIncrement;

  @JsonKey(name: 'remote_id')
  @Index(unique: true, replace: true)
  String? remoteId;

  @JsonKey(name: 'page_id')
  @Index()
  String pageId;

  @JsonKey(name: 'page_local_id')
  int? pageLocalId;

  @JsonKey(name: 'type')
  @Index()
  BlockType type;

  @JsonKey(name: 'content')
  Map<String, dynamic> content;

  @JsonKey(name: 'order')
  double order;

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

  BlockModel({
    required this.pageId,
    required this.type,
    required this.content,
    this.order = 0.0,
    this.remoteId,
    this.pageLocalId,
    String? userId,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.pending,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : userId = userId,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Copy with method for immutability
  BlockModel copyWith({
    String? pageId,
    int? pageLocalId,
    BlockType? type,
    Map<String, dynamic>? content,
    double? order,
    String? remoteId,
    String? userId,
    bool? isDeleted,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BlockModel(
      pageId: pageId ?? this.pageId,
      pageLocalId: pageLocalId ?? this.pageLocalId,
      type: type ?? this.type,
      content: content ?? this.content,
      order: order ?? this.order,
      remoteId: remoteId ?? this.remoteId,
      userId: userId ?? this.userId,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // JSON serialization
  factory BlockModel.fromJson(Map<String, dynamic> json) => _$BlockModelFromJson(json);

  Map<String, dynamic> toJson() => _$BlockModelToJson(this);

  // Helper methods for content
  String get textContent {
    return content['text'] ?? '';
  }

  void setTextContent(String text) {
    content['text'] = text;
  }

  // Sync-related methods
  BlockModel markForSync() {
    return copyWith(
      syncStatus: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );
  }

  BlockModel markAsSynced() {
    return copyWith(
      syncStatus: SyncStatus.synced,
    );
  }

  BlockModel markAsConflict() {
    return copyWith(
      syncStatus: SyncStatus.conflict,
    );
  }

  BlockModel markAsError() {
    return copyWith(
      syncStatus: SyncStatus.error,
    );
  }

  BlockModel softDelete() {
    return copyWith(
      isDeleted: true,
      syncStatus: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );
  }

  // Comparison for sync conflicts
  bool isNewerThan(BlockModel other) {
    return updatedAt.isAfter(other.updatedAt);
  }

  bool isSameAs(BlockModel other) {
    return pageId == other.pageId &&
           type == other.type &&
           content.toString() == other.content.toString() &&
           order == other.order &&
           isDeleted == other.isDeleted;
  }

  // Merge with another block (for conflict resolution)
  BlockModel mergeWith(BlockModel other) {
    // Last-write-wins strategy
    if (isNewerThan(other)) {
      return copyWith(
        syncStatus: SyncStatus.pending,
      );
    } else {
      return other.copyWith(
        id: id, // Keep local ID
        remoteId: remoteId, // Keep remote ID if exists
        pageLocalId: pageLocalId, // Keep local page ID
      );
    }
  }

  // Helper methods for content
  Map<String, dynamic> get deepCloneContent {
    return Map<String, dynamic>.from(content);
  }

  void updateContent(Map<String, dynamic> newContent) {
    content.clear();
    content.addAll(newContent);
    updatedAt = DateTime.now();
  }

  @override
  String toString() {
    return 'BlockModel{id: $id, remoteId: $remoteId, pageId: $pageId, type: $type, order: $order}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlockModel &&
           other.id == id &&
           other.remoteId == remoteId &&
           other.pageId == other.pageId &&
           other.type == type &&
           other.content.toString() == content.toString() &&
           other.order == order &&
           other.userId == userId &&
           other.isDeleted == isDeleted &&
           other.syncStatus == syncStatus;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      remoteId,
      pageId,
      type,
      content.toString(),
      order,
      userId,
      isDeleted,
      syncStatus,
    );
  }
}

@enumerated
enum BlockType {
  text,
  heading,
  list,
  image,
  code,
  quote,
  divider,
  checkbox,
}

@enumerated
enum SyncStatus {
  pending,
  synced,
  conflict,
  error
}