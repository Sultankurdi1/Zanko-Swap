import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:zankoswap/core/data/removed_rows.dart';

void main() {
  test('a deleted row leaves the list without a new server event', () async {
    final source = StreamController<List<String>>.broadcast();
    final seen = <List<String>>[];
    final sub = RemovedRows.hide('t1', source.stream, (r) => r).listen(seen.add);

    source.add(['a', 'b', 'c']);
    await Future<void>.delayed(Duration.zero);
    RemovedRows.mark('t1', 'b');
    await Future<void>.delayed(Duration.zero);
    RemovedRows.unmark('t1', 'b');
    await Future<void>.delayed(Duration.zero);

    expect(seen, [
      ['a', 'b', 'c'],
      ['a', 'c'],
      ['a', 'b', 'c'],
    ]);
    await sub.cancel();
    await source.close();
  });

  test('other tables are not affected', () async {
    final source = StreamController<List<String>>();
    final seen = <List<String>>[];
    final sub = RemovedRows.hide('t2', source.stream, (r) => r).listen(seen.add);
    source.add(['x']);
    await Future<void>.delayed(Duration.zero);
    RemovedRows.mark('other', 'x');
    await Future<void>.delayed(Duration.zero);
    expect(seen, [
      ['x'],
    ]);
    await sub.cancel();
  });
}
