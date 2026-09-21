import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../pages/dashboard/controller/rider_dashboard_controller.dart';
import '../utils/colors.dart';
import 'global.dart';
import 'rider_avatar.dart';

// Runs as a Get.dialog (global overlay) rather than an in-tree Visibility,
// so it works no matter which screen is on top - the Account screen and
// the dashboard's own header both call this the same way.
void showUpdateProfileDialog() {
  Get.dialog(const _UpdateProfileDialog(), barrierDismissible: false);
}

class _UpdateProfileDialog extends StatelessWidget {
  const _UpdateProfileDialog();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RiderDashboardController>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          decoration: utils.boxDecorationWhite(),
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Form(
                key: controller.profileFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Update Profile",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Avatar
                    Center(
                      child: Stack(
                        children: [
                          buildRiderAvatar(
                            controller: controller,
                            radius: 60,
                            backgroundColor: Colors.grey[200]!,
                            fallback:
                                Icon(Icons.person, size: 50, color: Colors.grey[400]),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: controller.showImageSourceDialog,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryThemeColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text("Address",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.address,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        focusColor: AppColors.primaryThemeColor,
                        hintText: "Enter your complete address",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.primaryThemeColor, width: 2),
                        ),
                      ),
                      cursorColor: AppColors.primaryThemeColor,
                      validator: controller.validateAddress,
                    ),
                    const SizedBox(height: 16),
                    Text("Phone Number",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.phone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: "Enter your phone number",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.primaryThemeColor, width: 2),
                        ),
                      ),
                      cursorColor: AppColors.primaryThemeColor,
                      validator: controller.validatePhone,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Cancel",
                                style: TextStyle(color: Colors.black54)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              bool success = await controller.updateProfileDetails();
                              if (success) Get.back();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: AppColors.primaryThemeColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Update",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
