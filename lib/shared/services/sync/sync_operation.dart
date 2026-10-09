enum SyncStatus { pending, syncing, synced, failed }

enum SyncOperationType { set, delete }

/// Tek bir yerel değişikliğin uzak kopyaya aktarım kaydı.
class SyncOperation {
  SyncOperation({
    required this.id,
    required this.documentPath,
    required this.type,
    required this.status,
    required this.enqueuedAt,
    this.data,
    this.merge = false,
    this.attempts = 0,
    this.lastError,
    this.completedAt,
  });

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
    id: json['id'] as String? ?? '',
    documentPath: json['documentPath'] as String? ?? '',
    type: json['type'] == 'delete'
        ? SyncOperationType.delete
        : SyncOperationType.set,
    status: _statusFromName(json['status'] as String?),
    enqueuedAt:
        DateTime.tryParse(json['enqueuedAt'] as String? ?? '') ??
        DateTime.now(),
    data: json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : null,
    merge: json['merge'] == true,
    attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    lastError: json['lastError'] as String?,
    completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
  );

  final String id;
  final String documentPath;
  final SyncOperationType type;
  final Map<String, dynamic>? data;
  final bool merge;
  SyncStatus status;
  final DateTime enqueuedAt;
  int attempts;
  String? lastError;
  DateTime? completedAt;

  bool get isOpen =>
      status == SyncStatus.pending || status == SyncStatus.failed;

  SyncOperation copyWith({
    SyncStatus? status,
    int? attempts,
    String? lastError,
    DateTime? completedAt,
  }) {
    return SyncOperation(
      id: id,
      documentPath: documentPath,
      type: type,
      data: data,
      merge: merge,
      status: status ?? this.status,
      enqueuedAt: enqueuedAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'documentPath': documentPath,
    'type': type == SyncOperationType.delete ? 'delete' : 'set',
    'status': status.name,
    'enqueuedAt': enqueuedAt.toIso8601String(),
    'data': data,
    'merge': merge,
    'attempts': attempts,
    'lastError': lastError,
    'completedAt': completedAt?.toIso8601String(),
  };

  static SyncStatus _statusFromName(String? name) => switch (name) {
    'syncing' => SyncStatus.syncing,
    'synced' => SyncStatus.synced,
    'failed' => SyncStatus.failed,
    _ => SyncStatus.pending,
  };
}
