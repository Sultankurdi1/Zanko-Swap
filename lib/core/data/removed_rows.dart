import 'dart:async';

/// Supabase realtime does not send delete events to filtered streams, so a
/// deleted row would stay on screen until the app restarts. Code that deletes
/// a row calls [mark]; streams wrapped with [hide] drop it right away.
class RemovedRows {
  static final _ids = <String, Set<String>>{};
  static final _changes = StreamController<String>.broadcast();

  static void mark(String table, Object? id) {
    if (id == null) return;
    (_ids[table] ??= <String>{}).add('$id');
    _changes.add(table);
  }

  static void unmark(String table, Object? id) {
    if (_ids[table]?.remove('$id') ?? false) _changes.add(table);
  }

  static bool isRemoved(String table, Object? id) =>
      _ids[table]?.contains('$id') ?? false;

  static Stream<List<T>> hide<T>(
    String table,
    Stream<List<T>> source,
    Object? Function(T row) idOf,
  ) {
    return Stream<List<T>>.multi((out) {
      List<T>? last;
      void emit() {
        final rows = last;
        if (rows != null && !out.isClosed) {
          out.add(rows.where((r) => !isRemoved(table, idOf(r))).toList());
        }
      }

      final sourceSub = source.listen(
        (rows) {
          last = rows;
          emit();
        },
        onError: out.addError,
        onDone: out.close,
      );
      final changeSub = _changes.stream
          .where((t) => t == table)
          .listen((_) => emit());
      out.onPause = sourceSub.pause;
      out.onResume = sourceSub.resume;
      out.onCancel = () async {
        await changeSub.cancel();
        await sourceSub.cancel();
      };
    }, isBroadcast: source.isBroadcast);
  }
}
