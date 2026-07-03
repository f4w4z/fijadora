import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DispatchModel {
  adminAssigned,
  firstComeGrab,
}

final dispatchModelProvider = StateProvider<DispatchModel>((ref) {
  return DispatchModel.adminAssigned;
});
