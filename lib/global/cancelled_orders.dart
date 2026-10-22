import 'package:flutter/foundation.dart';
import '../apis/base_api_response.dart';
import '../pages/my_orders/orders/models/orders_model.dart';
import 'consts.dart';
import 'global.dart';
import 'order_delivered_dialog.dart';

// Shared by the dashboard, order list and active delivery screens so a
// cancelled order is only ever announced once, whichever screen spots it
// first (foreground push or the check on app resume).
final Set<String> _notifiedCancelledAwbs = {};

// False if the rider was already shown this cancellation.
bool markCancellationNotified(String awb) => _notifiedCancelledAwbs.add(awb);

// One order's current details, or null if the request failed.
Future<OrdersData?> fetchDriverOrder(String awb, String feCode) async {
  try {
    final response = await apiProvider.getRequestWithQueryParams(
      "${apiEndPoints.driverOrderDetails}/$awb",
      {apiKeys.feCode: feCode},
    );
    final result = BaseApiResponse.fromJson(response);
    final data = result.data;
    if (result.status_code != 200 || data == null) return null;
    final json = data is List ? (data.isEmpty ? null : data.first) : data;
    return json is Map<String, dynamic> ? OrdersData.fromJson(json) : null;
  } catch (e) {
    debugPrint('Error fetching order $awb: $e');
    return null;
  }
}

// After the app resumes: `gone` are orders that were in the rider's
// assigned list before the re-fetch and aren't any more. Those whose status
// is now CANCELLED get the cancelled dialog, one after another - as long as
// the screen asking is still the one on top once the checks finish.
Future<void> showCancelledOrdersAmong(
  List<OrdersData> gone,
  String feCode, {
  required bool Function() isStillOnTop,
}) async {
  final candidates = gone
      .where((o) => (o.awbNo ?? '').isNotEmpty)
      .where((o) => !_notifiedCancelledAwbs.contains(o.awbNo))
      .toList();
  if (candidates.isEmpty) return;
  final fresh = await Future.wait(
    candidates.map((o) => fetchDriverOrder(o.awbNo!, feCode)),
  );
  final cancelled = <OrdersData>[];
  for (var i = 0; i < candidates.length; i++) {
    final f = fresh[i];
    if (f?.status != CANCELED) continue;
    // Keep the list's copy for display fields the details call may omit.
    final shown = candidates[i];
    shown.status = CANCELED;
    if ((f!.reason ?? '').trim().isNotEmpty) shown.reason = f.reason;
    cancelled.add(shown);
  }
  if (cancelled.isEmpty || !isStillOnTop()) return;
  _showInTurn(cancelled, 0);
}

void _showInTurn(List<OrdersData> orders, int index) {
  if (index >= orders.length) return;
  final order = orders[index];
  if (!markCancellationNotified(order.awbNo!)) {
    _showInTurn(orders, index + 1);
    return;
  }
  showOrderCancelledDialog(
    order: order,
    reason: order.reason,
    buttonLabel: "Got it",
    onContinue: () => _showInTurn(orders, index + 1),
  );
}
