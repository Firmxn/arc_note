import 'dart:async';
import '../utils/app_logger.dart';

// Retry configuration
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final Set<Type> retryableExceptions;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.retryableExceptions = const {
      TimeoutException,
      SocketException,
      HttpException,
    },
  });
}

// Retry result
class RetryResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final Exception? exception;
  final int attempts;

  RetryResult.success(this.data, this.attempts)
      : success = true,
        error = null,
        exception = null;

  RetryResult.failure(this.error, this.exception, this.attempts)
      : success = false,
        data = null;
}

class RetryService {
  static const RetryConfig defaultConfig = RetryConfig();

  // Execute operation with retry logic
  static Future<RetryResult<T>> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig config = defaultConfig,
    String? operationName,
  }) async {
    Exception? lastException;
    String? lastError;
    int attempts = 0;

    for (int attempt = 1; attempt <= config.maxAttempts; attempt++) {
      attempts = attempt;
      try {
        AppLogger.debug('Attempting operation (attempt $attempt/${config.maxAttempts})',
                       operationName ?? 'Unknown');

        final result = await operation();

        if (attempt > 1) {
          AppLogger.info('Operation succeeded after $attempt attempts', operationName);
        }

        return RetryResult.success(result, attempts);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        lastError = e.toString();

        // Check if exception is retryable
        final isRetryable = config.retryableExceptions.any((type) =>
            type.isInstanceOf(lastException.runtimeType));

        if (!isRetryable || attempt == config.maxAttempts) {
          AppLogger.error('Operation failed permanently after $attempt attempts: $lastError',
                          lastException, operationName);
          return RetryResult.failure(lastError, lastException, attempts);
        }

        // Calculate delay for next attempt
        final delay = _calculateDelay(attempt, config);
        AppLogger.warning('Operation failed (attempt $attempt/$maxAttempts), retrying in ${delay.inSeconds}s: $lastError',
                         operationName);

        await Future.delayed(delay);
      }
    }

    return RetryResult.failure(lastError ?? 'Unknown error', lastException, attempts);
  }

  // Calculate exponential backoff delay
  static Duration _calculateDelay(int attempt, RetryConfig config) {
    final delay = config.initialDelay *
                  (config.backoffMultiplier * (attempt - 1));

    return Duration(
      milliseconds: delay.inMilliseconds.clamp(
        0,
        config.maxDelay.inMilliseconds,
      ),
    );
  }

  // Execute operation with timeout and retry
  static Future<RetryResult<T>> executeWithTimeoutAndRetry<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
    RetryConfig config = defaultConfig,
    String? operationName,
  }) async {
    return executeWithRetry<T>(
      () async {
        return await operation().timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException('Operation timed out after ${timeout.inSeconds}s', timeout);
          },
        );
      },
      config: config,
      operationName: operationName,
    );
  }

  // Batch retry for multiple operations
  static Future<List<RetryResult<T>>> executeBatchWithRetry<T>(
    List<Future<T> Function()> operations, {
    RetryConfig config = defaultConfig,
    String? batchName,
    bool continueOnFailure = true,
  }) async {
    final results = <RetryResult<T>>[];

    for (int i = 0; i < operations.length; i++) {
      final operationName = '${batchName ?? "Batch"} operation ${i + 1}';

      final result = await executeWithRetry<T>(
        operations[i],
        config: config,
        operationName: operationName,
      );

      results.add(result);

      if (!result.success && !continueOnFailure) {
        AppLogger.error('Stopping batch execution due to failure in $operationName');
        break;
      }
    }

    return results;
  }

  // Retry with circuit breaker pattern
  static Future<RetryResult<T>> executeWithCircuitBreaker<T>(
    Future<T> Function() operation,
    CircuitBreaker circuitBreaker, {
    RetryConfig config = defaultConfig,
    String? operationName,
  }) async {
    if (circuitBreaker.isOpen()) {
      return RetryResult.failure(
        'Circuit breaker is open',
        Exception('Circuit breaker is open'),
        0,
      );
    }

    final result = await executeWithRetry<T>(
      operation,
      config: config,
      operationName: operationName,
    );

    if (!result.success) {
      circuitBreaker.recordFailure();
    } else {
      circuitBreaker.recordSuccess();
    }

    return result;
  }
}

// Circuit breaker for preventing cascade failures
class CircuitBreaker {
  final int failureThreshold;
  final Duration recoveryTimeout;

  int _failureCount = 0;
  DateTime? _lastFailureTime;
  bool _isOpen = false;

  CircuitBreaker({
    this.failureThreshold = 5,
    this.recoveryTimeout = const Duration(minutes: 1),
  });

  bool isOpen() {
    if (!_isOpen) return false;

    // Check if recovery timeout has passed
    if (_lastFailureTime != null) {
      final timeSinceLastFailure = DateTime.now().difference(_lastFailureTime!);
      if (timeSinceLastFailure >= recoveryTimeout) {
        _reset();
        return false;
      }
    }

    return true;
  }

  void recordSuccess() {
    if (_isOpen) {
      AppLogger.info('Circuit breaker closing after successful operation');
    }
    _reset();
  }

  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _isOpen = true;
      AppLogger.warning('Circuit breaker opened after $_failureCount failures');
    }
  }

  void _reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    _isOpen = false;
  }

  String get status => _isOpen ? 'OPEN' : 'CLOSED';
  int get failureCount => _failureCount;
}

// Network-specific retry utilities
class NetworkRetryService {
  static const RetryConfig networkConfig = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(seconds: 2),
    backoffMultiplier: 2.0,
    maxDelay: Duration(seconds: 60),
    retryableExceptions: {
      TimeoutException,
      SocketException,
      HttpException,
      FormatException,
    },
  );

  // Retry network operations with exponential backoff
  static Future<RetryResult<T>> executeNetworkOperation<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
    String? operationName,
  }) async {
    return RetryService.executeWithTimeoutAndRetry<T>(
      operation,
      timeout: timeout,
      config: networkConfig,
      operationName: operationName,
    );
  }

  // Check network connectivity before operation
  static Future<RetryResult<T>> executeWithConnectivityCheck<T>(
    Future<T> Function() operation, {
    Future<bool> Function()? connectivityCheck,
    String? operationName,
  }) async {
    // Check connectivity if function is provided
    if (connectivityCheck != null) {
      final isConnected = await connectivityCheck();
      if (!isConnected) {
        return RetryResult.failure(
          'No internet connection',
          Exception('No internet connection'),
          0,
        );
      }
    }

    return executeNetworkOperation<T>(
      operation,
      operationName: operationName,
    );
  }
}

// Import necessary types
import 'dart:io';
import 'package:http/http.dart';