enum MutationOp { create, update, delete }

enum MutationSyncState { pending, failed }

/// A single outstanding local write for one entity - at most one per entityId (a new local
/// edit/delete coalesces into the existing record rather than appending a second one). See
/// `MutationStore` for storage and the offline write-queue plan for the coalescing rules.
class PendingMutation {
  PendingMutation({
    required this.entityType,
    required this.entityId,
    required this.op,
    required this.payload,
    required this.queuedAt,
    this.attempts = 0,
    this.state = MutationSyncState.pending,
    this.dirty = false,
  });

  final String entityType;
  final String entityId;
  final MutationOp op;
  // Full merged field-set for create/update; null for delete.
  final Map<String, dynamic>? payload;
  // Bumped on every local edit that coalesces into this record - the only signal available
  // for last-write-wins comparison until the backend exposes a server-side updatedAt.
  final DateTime queuedAt;
  final int attempts;
  final MutationSyncState state;
  // Edited again while a flush for this entityId was in flight - triggers an immediate
  // re-flush once the in-flight attempt resolves, rather than losing the edit.
  final bool dirty;

  PendingMutation copyWith({
    MutationOp? op,
    Map<String, dynamic>? payload,
    DateTime? queuedAt,
    int? attempts,
    MutationSyncState? state,
    bool? dirty,
  }) {
    return PendingMutation(
      entityType: entityType,
      entityId: entityId,
      op: op ?? this.op,
      payload: payload ?? this.payload,
      queuedAt: queuedAt ?? this.queuedAt,
      attempts: attempts ?? this.attempts,
      state: state ?? this.state,
      dirty: dirty ?? this.dirty,
    );
  }

  factory PendingMutation.fromJson(Map<String, dynamic> json) {
    return PendingMutation(
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      op: MutationOp.values.byName(json['op'] as String),
      payload: (json['payload'] as Map<String, dynamic>?),
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      attempts: json['attempts'] as int? ?? 0,
      state: MutationSyncState.values.byName(json['state'] as String? ?? 'pending'),
      dirty: json['dirty'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'entityType': entityType,
    'entityId': entityId,
    'op': op.name,
    'payload': payload,
    'queuedAt': queuedAt.toIso8601String(),
    'attempts': attempts,
    'state': state.name,
    'dirty': dirty,
  };
}
