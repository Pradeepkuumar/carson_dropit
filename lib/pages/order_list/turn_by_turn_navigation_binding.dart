import 'package:get/get.dart';
import 'turn_by_turn_navigation_controller.dart';

class TurnByTurnNavigationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TurnByTurnNavigationController>(
      () => TurnByTurnNavigationController(),
    );
  }
}
