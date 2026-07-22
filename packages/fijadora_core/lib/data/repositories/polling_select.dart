import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// A refreshing stream backed by a one-time PostgREST query.
///
/// The app's realtime `.stream()` requires each table to be added to the
/// `supabase_realtime` publication. For admin/management screens that don't
/// need sub-second live updates, polling `.select()` is simpler and works
/// without that publication.
Stream<List<T>> pollingSelect<T>({
  required sb.SupabaseClient client,
  required String table,
  required T Function(Map<String, dynamic>) fromJson,
  String? eqColumn,
  String? eqValue,
  String? orderBy,
  bool ascending = false,
  Duration interval = const Duration(seconds: 5),
}) {
  Future<List<T>> fetch() async {
    final base = client.from(table).select();
    final filtered = (eqColumn != null && eqValue != null)
        ? base.eq(eqColumn, eqValue)
        : base;
    final data = await (orderBy == null ? filtered : filtered.order(orderBy, ascending: ascending));
    return (data as List).map((json) => fromJson(json as Map<String, dynamic>)).toList();
  }

  final controller = StreamController<List<T>>(sync: false);
  Timer? timer;

  Future<void> emit() async {
    try {
      final rows = await fetch();
      if (!controller.isClosed) controller.add(rows);
    } catch (e) {
      if (!controller.isClosed) controller.addError(e);
    }
  }

  emit();
  timer = Timer.periodic(interval, (_) => emit());

  controller.onCancel = () {
    timer?.cancel();
    controller.close();
  };

  return controller.stream;
}
