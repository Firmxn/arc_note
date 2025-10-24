import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'database_service.dart';
import 'supabase_service.dart';
import 'retry_service.dart';

// Service container for dependency injection
class ServiceContainer {
  static Future<void> initialize() async {
    try {
      // Initialize Supabase
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL'] ?? '',
        anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      );

      // Initialize local database
      final databaseService = DatabaseService();
      await databaseService.initialize();

      print('✅ ServiceContainer initialization completed');
    } catch (e, stackTrace) {
      print('❌ ServiceContainer initialization failed: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

// Providers for dependency injection

// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Environment providers
final supabaseUrlProvider = Provider<String>((ref) {
  return dotenv.env['SUPABASE_URL'] ?? '';
});

final supabaseAnonKeyProvider = Provider<String>((ref) {
  return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
});

// Service providers
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseService(client);
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Service providers (will be implemented in subsequent tasks)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseServiceProvider));
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(supabaseServiceProvider),
    ref.watch(databaseServiceProvider),
  );
});

// AuthService implementation
class AuthService {
  final SupabaseService _supabaseService;

  AuthService(this._supabaseService);

  // Get current user
  User? get currentUser => _supabaseService.auth.currentUser;

  // Get current session
  Session? get currentSession => _supabaseService.auth.currentSession;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabaseService.auth.onAuthStateChange;

  // Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _supabaseService.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );

      if (response.user != null) {
        return AuthResult.success(response.user!);
      } else {
        return AuthResult.failure('Sign up failed: No user returned');
      }
    } catch (e) {
      return AuthResult.failure('Sign up failed: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return AuthResult.success(response.user!);
      } else {
        return AuthResult.failure('Sign in failed: No user returned');
      }
    } catch (e) {
      return AuthResult.failure('Sign in failed: ${e.toString()}');
    }
  }

  // Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      final response = await _supabaseService.auth.signInWithOAuth(
        Provider.google,
        redirectTo: 'io.supabase.arcnote://login-callback',
      );

      return AuthResult.success(response.user!);
    } catch (e) {
      return AuthResult.failure('Google sign in failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<AuthResult> signOut() async {
    try {
      await _supabaseService.auth.signOut();
      return AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure('Sign out failed: ${e.toString()}');
    }
  }

  // Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _supabaseService.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.arcnote://reset-password',
      );
      return AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure('Password reset failed: ${e.toString()}');
    }
  }

  // Update password
  Future<AuthResult> updatePassword(String newPassword) async {
    try {
      await _supabaseService.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return AuthResult.success(currentUser);
    } catch (e) {
      return AuthResult.failure('Password update failed: ${e.toString()}');
    }
  }

  // Update user profile
  Future<AuthResult> updateProfile({
    String? displayName,
    String? email,
  }) async {
    try {
      final attributes = UserAttributes();
      if (displayName != null) {
        attributes.data = {'display_name': displayName};
      }
      if (email != null) {
        attributes.email = email;
      }

      final updatedUser = await _supabaseService.auth.updateUser(attributes);
      return AuthResult.success(updatedUser.user!);
    } catch (e) {
      return AuthResult.failure('Profile update failed: ${e.toString()}');
    }
  }

  // Refresh session
  Future<AuthResult> refreshSession() async {
    try {
      final session = await _supabaseService.auth.refreshSession();
      if (session.user != null) {
        return AuthResult.success(session.user!);
      } else {
        return AuthResult.failure('Session refresh failed: No user returned');
      }
    } catch (e) {
      return AuthResult.failure('Session refresh failed: ${e.toString()}');
    }
  }
}

// Auth result class
class AuthResult {
  final bool success;
  final User? user;
  final String? error;

  AuthResult.success(this.user)
      : success = true,
        error = null;

  AuthResult.failure(this.error)
      : success = false,
        user = null;
}

// SyncService implementation
class SyncService {
  final SupabaseService _supabaseService;
  final DatabaseService _databaseService;

  SyncService(this._supabaseService, this._databaseService);

  // Sync result class
  static class SyncResult {
    final bool success;
    final int syncedPages;
    final int syncedBlocks;
    final int conflicts;
    final int errors;
    final List<String> errorMessages;

    SyncResult({
      this.success = false,
      this.syncedPages = 0,
      this.syncedBlocks = 0,
      this.conflicts = 0,
      this.errors = 0,
      this.errorMessages = const [],
    });

    SyncResult.success({
      required int syncedPages,
      required int syncedBlocks,
      int conflicts = 0,
      List<String> errorMessages = const [],
    }) : success = true,
         syncedPages = syncedPages,
         syncedBlocks = syncedBlocks,
         conflicts = conflicts,
         errors = errorMessages.length,
         errorMessages = errorMessages;

    SyncResult.failure(List<String> errorMessages)
        : success = false,
          syncedPages = 0,
          syncedBlocks = 0,
          conflicts = 0,
          errors = errorMessages.length,
          errorMessages = errorMessages;
  }

  // Full sync - bidirectional synchronization
  Future<SyncResult> performFullSync(String userId) async {
    try {
      AppLogger.info('Starting full sync for user: $userId');

      final errorMessages = <String>[];
      int syncedPages = 0;
      int syncedBlocks = 0;
      int conflicts = 0;

      // Check connectivity
      final isConnected = await _supabaseService.isConnected();
      if (!isConnected) {
        errorMessages.add('No internet connection');
        return SyncResult.failure(errorMessages);
      }

      // Step 1: Push pending local changes
      final pushResult = await _pushLocalChanges(userId);
      if (!pushResult.success) {
        errorMessages.addAll(pushResult.errorMessages);
      } else {
        syncedPages += pushResult.syncedPages;
        syncedBlocks += pushResult.syncedBlocks;
        conflicts += pushResult.conflicts;
      }

      // Step 2: Pull remote changes
      final pullResult = await _pullRemoteChanges(userId);
      if (!pullResult.success) {
        errorMessages.addAll(pullResult.errorMessages);
      } else {
        syncedPages += pullResult.syncedPages;
        syncedBlocks += pullResult.syncedBlocks;
        conflicts += pullResult.conflicts;
      }

      // Step 3: Resolve conflicts
      if (conflicts > 0) {
        await _resolveConflicts(userId);
      }

      AppLogger.info('Full sync completed: Pages: $syncedPages, Blocks: $syncedBlocks, Conflicts: $conflicts');

      return errorMessages.isEmpty
          ? SyncResult.success(
              syncedPages: syncedPages,
              syncedBlocks: syncedBlocks,
              conflicts: conflicts,
            )
          : SyncResult.failure(errorMessages);
    } catch (e, stackTrace) {
      AppLogger.error('Full sync failed', e, stackTrace);
      return SyncResult.failure(['Unexpected error during sync: ${e.toString()}']);
    }
  }

  // Push local changes to remote
  Future<SyncResult> _pushLocalChanges(String userId) async {
    try {
      int syncedPages = 0;
      int syncedBlocks = 0;
      int conflicts = 0;
      final errorMessages = <String>[];

      // Get pending pages
      final pendingPages = await _databaseService.getPendingSyncPages();

      for (final page in pendingPages) {
        if (page.userId != userId) continue;

        try {
          final remoteData = {
            'id': page.remoteId,
            'title': page.title,
            'content': page.content,
            'created_at': page.createdAt.toIso8601String(),
            'updated_at': page.updatedAt.toIso8601String(),
            'user_id': page.userId,
            'is_deleted': page.isDeleted,
          };

          final response = await _supabaseService.client
              .from('pages')
              .upsert(remoteData)
              .select()
              .single();

          if (response != null) {
            // Update local page with remote data
            page.remoteId = response['id'] as String;
            page.syncStatus = SyncStatus.synced;
            await _databaseService.savePage(page);
            syncedPages++;
          }
        } catch (e) {
          AppLogger.error('Failed to sync page ${page.id}', e);
          page.syncStatus = SyncStatus.error;
          await _databaseService.savePage(page);
          errorMessages.add('Failed to sync page: ${e.toString()}');
        }
      }

      // Get pending blocks
      final pendingBlocks = await _databaseService.getPendingSyncBlocks();

      for (final block in pendingBlocks) {
        if (block.userId != userId) continue;

        try {
          final remoteData = {
            'id': block.remoteId,
            'page_id': block.pageId,
            'type': block.type.name,
            'content': block.content,
            'order': block.order,
            'created_at': block.createdAt.toIso8601String(),
            'updated_at': block.updatedAt.toIso8601String(),
            'user_id': block.userId,
            'is_deleted': block.isDeleted,
          };

          final response = await _supabaseService.client
              .from('blocks')
              .upsert(remoteData)
              .select()
              .single();

          if (response != null) {
            // Update local block with remote data
            block.remoteId = response['id'] as String;
            block.syncStatus = SyncStatus.synced;
            await _databaseService.saveBlock(block);
            syncedBlocks++;
          }
        } catch (e) {
          AppLogger.error('Failed to sync block ${block.id}', e);
          block.syncStatus = SyncStatus.error;
          await _databaseService.saveBlock(block);
          errorMessages.add('Failed to sync block: ${e.toString()}');
        }
      }

      return SyncResult.success(
        syncedPages: syncedPages,
        syncedBlocks: syncedBlocks,
        errorMessages: errorMessages,
      );
    } catch (e) {
      return SyncResult.failure(['Failed to push local changes: ${e.toString()}']);
    }
  }

  // Pull remote changes
  Future<SyncResult> _pullRemoteChanges(String userId) async {
    try {
      int syncedPages = 0;
      int syncedBlocks = 0;
      int conflicts = 0;
      final errorMessages = <String>[];

      // Get last sync timestamp (could be stored in preferences)
      final lastSyncTime = DateTime.now().subtract(const Duration(hours: 24));

      // Pull updated pages
      final pagesResponse = await _supabaseService.client
          .from('pages')
          .select()
          .eq('user_id', userId)
          .gt('updated_at', lastSyncTime.toIso8601String());

      if (pagesResponse != null) {
        for (final pageData in pagesResponse) {
          try {
            final remotePage = PageModel.fromJson(pageData as Map<String, dynamic>);
            final localPage = await _databaseService.getPageByRemoteId(remotePage.remoteId!);

            if (localPage == null) {
              // New page from remote
              remotePage.syncStatus = SyncStatus.synced;
              await _databaseService.savePage(remotePage);
              syncedPages++;
            } else {
              // Check for conflicts
              if (localPage.updatedAt.isBefore(remotePage.updatedAt)) {
                // Remote is newer, update local
                remotePage.id = localPage.id; // Keep local ID
                remotePage.syncStatus = SyncStatus.synced;
                await _databaseService.savePage(remotePage);
                syncedPages++;
              } else if (!localPage.isSameAs(remotePage)) {
                // Conflict detected
                localPage.syncStatus = SyncStatus.conflict;
                await _databaseService.savePage(localPage);
                conflicts++;
              }
            }
          } catch (e) {
            AppLogger.error('Failed to process remote page', e);
            errorMessages.add('Failed to process remote page: ${e.toString()}');
          }
        }
      }

      // Pull updated blocks
      final blocksResponse = await _supabaseService.client
          .from('blocks')
          .select()
          .eq('user_id', userId)
          .gt('updated_at', lastSyncTime.toIso8601String());

      if (blocksResponse != null) {
        for (final blockData in blocksResponse) {
          try {
            final remoteBlock = BlockModel.fromJson(blockData as Map<String, dynamic>);
            final localBlock = await _databaseService.getBlockByRemoteId(remoteBlock.remoteId!);

            if (localBlock == null) {
              // New block from remote
              remoteBlock.syncStatus = SyncStatus.synced;
              await _databaseService.saveBlock(remoteBlock);
              syncedBlocks++;
            } else {
              // Check for conflicts
              if (localBlock.updatedAt.isBefore(remoteBlock.updatedAt)) {
                // Remote is newer, update local
                remoteBlock.id = localBlock.id; // Keep local ID
                remoteBlock.syncStatus = SyncStatus.synced;
                await _databaseService.saveBlock(remoteBlock);
                syncedBlocks++;
              } else if (!localBlock.isSameAs(remoteBlock)) {
                // Conflict detected
                localBlock.syncStatus = SyncStatus.conflict;
                await _databaseService.saveBlock(localBlock);
                conflicts++;
              }
            }
          } catch (e) {
            AppLogger.error('Failed to process remote block', e);
            errorMessages.add('Failed to process remote block: ${e.toString()}');
          }
        }
      }

      return SyncResult.success(
        syncedPages: syncedPages,
        syncedBlocks: syncedBlocks,
        conflicts: conflicts,
        errorMessages: errorMessages,
      );
    } catch (e) {
      return SyncResult.failure(['Failed to pull remote changes: ${e.toString()}']);
    }
  }

  // Resolve conflicts using last-write-wins strategy
  Future<void> _resolveConflicts(String userId) async {
    try {
      // Get all conflicted pages
      final conflictedPages = await _databaseService.getAllPages()
          .then((pages) => pages.where((p) => p.syncStatus == SyncStatus.conflict && p.userId == userId));

      for (final localPage in conflictedPages) {
        if (localPage.remoteId != null) {
          try {
            // Get remote version
            final remoteResponse = await _supabaseService.client
                .from('pages')
                .select()
                .eq('id', localPage.remoteId)
                .single();

            if (remoteResponse != null) {
              final remotePage = PageModel.fromJson(remoteResponse as Map<String, dynamic>);

              // Last-write-wins resolution
              final resolvedPage = localPage.mergeWith(remotePage);
              resolvedPage.syncStatus = SyncStatus.synced;
              await _databaseService.savePage(resolvedPage);

              // Push resolution to remote
              final updateData = {
                'title': resolvedPage.title,
                'content': resolvedPage.content,
                'updated_at': resolvedPage.updatedAt.toIso8601String(),
              };

              await _supabaseService.client
                  .from('pages')
                  .update(updateData)
                  .eq('id', resolvedPage.remoteId);
            }
          } catch (e) {
            AppLogger.error('Failed to resolve page conflict', e);
          }
        }
      }

      // Get all conflicted blocks
      final conflictedBlocks = await _databaseService.getBlocksByPageId('')
          .then((blocks) => blocks.where((b) => b.syncStatus == SyncStatus.conflict && b.userId == userId));

      for (final localBlock in conflictedBlocks) {
        if (localBlock.remoteId != null) {
          try {
            // Get remote version
            final remoteResponse = await _supabaseService.client
                .from('blocks')
                .select()
                .eq('id', localBlock.remoteId)
                .single();

            if (remoteResponse != null) {
              final remoteBlock = BlockModel.fromJson(remoteResponse as Map<String, dynamic>);

              // Last-write-wins resolution
              final resolvedBlock = localBlock.mergeWith(remoteBlock);
              resolvedBlock.syncStatus = SyncStatus.synced;
              await _databaseService.saveBlock(resolvedBlock);

              // Push resolution to remote
              final updateData = {
                'content': resolvedBlock.content,
                'order': resolvedBlock.order,
                'updated_at': resolvedBlock.updatedAt.toIso8601String(),
              };

              await _supabaseService.client
                  .from('blocks')
                  .update(updateData)
                  .eq('id', resolvedBlock.remoteId);
            }
          } catch (e) {
            AppLogger.error('Failed to resolve block conflict', e);
          }
        }
      }
    } catch (e) {
      AppLogger.error('Failed to resolve conflicts', e);
    }
  }

  // Quick sync for single item with retry logic
  Future<bool> syncPage(int pageId, String userId) async {
    try {
      final page = await _databaseService.getPageById(pageId);
      if (page == null || page.userId != userId) return false;

      if (page.syncStatus == SyncStatus.pending) {
        final remoteData = {
          'id': page.remoteId,
          'title': page.title,
          'content': page.content,
          'updated_at': page.updatedAt.toIso8601String(),
        };

        final result = await NetworkRetryService.executeNetworkOperation<Map<String, dynamic>>(
          () async {
            final response = await _supabaseService.client
                .from('pages')
                .upsert(remoteData)
                .select()
                .single();
            return response as Map<String, dynamic>;
          },
          operationName: 'sync_page_${pageId}',
        );

        if (result.success && result.data != null) {
          page.remoteId = result.data!['id'] as String;
          page.syncStatus = SyncStatus.synced;
          await _databaseService.savePage(page);
          return true;
        } else {
          // Mark as error if sync failed after retries
          page.syncStatus = SyncStatus.error;
          await _databaseService.savePage(page);
          return false;
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('Failed to sync page', e);
      return false;
    }
  }

  Future<bool> syncBlock(int blockId, String userId) async {
    try {
      final block = await _databaseService.getBlockById(blockId);
      if (block == null || block.userId != userId) return false;

      if (block.syncStatus == SyncStatus.pending) {
        final remoteData = {
          'id': block.remoteId,
          'page_id': block.pageId,
          'type': block.type.name,
          'content': block.content,
          'order': block.order,
          'updated_at': block.updatedAt.toIso8601String(),
        };

        final result = await NetworkRetryService.executeNetworkOperation<Map<String, dynamic>>(
          () async {
            final response = await _supabaseService.client
                .from('blocks')
                .upsert(remoteData)
                .select()
                .single();
            return response as Map<String, dynamic>;
          },
          operationName: 'sync_block_${blockId}',
        );

        if (result.success && result.data != null) {
          block.remoteId = result.data!['id'] as String;
          block.syncStatus = SyncStatus.synced;
          await _databaseService.saveBlock(block);
          return true;
        } else {
          // Mark as error if sync failed after retries
          block.syncStatus = SyncStatus.error;
          await _databaseService.saveBlock(block);
          return false;
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('Failed to sync block', e);
      return false;
    }
  }

  // Retry failed sync operations
  Future<SyncResult> retryFailedOperations(String userId) async {
    try {
      int retriedPages = 0;
      int retriedBlocks = 0;
      final errorMessages = <String>[];

      // Retry pages with error status
      final errorPages = await _databaseService.getAllPages()
          .then((pages) => pages.where((p) => p.syncStatus == SyncStatus.error && p.userId == userId));

      for (final page in errorPages) {
        page.syncStatus = SyncStatus.pending; // Reset to pending for retry
        await _databaseService.savePage(page);

        final success = await syncPage(page.id, userId);
        if (success) {
          retriedPages++;
        } else {
          errorMessages.add('Failed to retry page: ${page.title}');
        }
      }

      // Retry blocks with error status
      final errorBlocks = await _databaseService.getPendingSyncBlocks()
          .then((blocks) => blocks.where((b) => b.syncStatus == SyncStatus.error && b.userId == userId));

      for (final block in errorBlocks) {
        block.syncStatus = SyncStatus.pending; // Reset to pending for retry
        await _databaseService.saveBlock(block);

        final success = await syncBlock(block.id, userId);
        if (success) {
          retriedBlocks++;
        } else {
          errorMessages.add('Failed to retry block: ${block.id}');
        }
      }

      return SyncResult.success(
        syncedPages: retriedPages,
        syncedBlocks: retriedBlocks,
        errorMessages: errorMessages,
      );
    } catch (e) {
      return SyncResult.failure(['Failed to retry operations: ${e.toString()}']);
    }
  }
}