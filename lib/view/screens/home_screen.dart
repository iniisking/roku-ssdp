import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' hide DeviceType;
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/models/device_model.dart';
import '../../presentation/controllers/roku_controller.dart';
import '../widgets/custom_text_widget.dart';
import '../widgets/colors.dart';
import 'control_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Consumer<RokuController>(
          builder: (context, controller, child) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(controller),
                  SizedBox(height: 32.h),

                  // Discovery Card
                  _buildDiscoveryCard(context, controller),
                  SizedBox(height: 24.h),

                  // Control Section
                  if (controller.selectedDevice != null) ...[
                    _buildSelectedDeviceCard(context, controller),
                    SizedBox(height: 24.h),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(RokuController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextWidget(
                    text: 'Roku Controller',
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  SizedBox(height: 8.h),
                  CustomTextWidget(
                    text: 'Discover and control Roku & Google TV devices',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                    color: textColor3,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            // Test Mode Toggle
            Container(
              decoration: BoxDecoration(
                color: controller.testMode
                    ? warningColor.withOpacity(0.2)
                    : surfaceColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: controller.testMode ? warningColor : grey700,
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.toggleTestMode(),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bug_report_rounded,
                          color: controller.testMode
                              ? warningColor
                              : textColor3,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        CustomTextWidget(
                          text: controller.testMode ? 'Test' : 'Live',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: controller.testMode
                              ? warningColor
                              : textColor3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (controller.testMode) ...[
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: warningColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: warningColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: warningColor,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: CustomTextWidget(
                    text:
                        'Test Mode: Using mock devices. Control buttons will simulate commands.',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: warningColor,
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDiscoveryCard(BuildContext context, RokuController controller) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardColor, surfaceColorLight],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomTextWidget(
                  text: 'Device Discovery',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                Row(
                  children: [
                    Icon(Icons.tv_rounded, color: primaryColor, size: 18.sp),
                    SizedBox(width: 4.w),
                    Icon(Icons.cast_rounded, color: accentColor, size: 18.sp),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Discover Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryColor, primaryColor2]),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: controller.isDiscovering
                      ? null
                      : () => controller.discoverDevices(),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: textColor,
                          size: 22.sp,
                        ),
                        SizedBox(width: 12.w),
                        CustomTextWidget(
                          text: 'Discover Devices',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Test Mode Mock Devices
            if (controller.testMode && !controller.isDiscovering) ...[
              _buildMockDevicesSection(context, controller),
              SizedBox(height: 16.h),
            ],

            // Status Content
            if (controller.isDiscovering)
              _buildShimmerLoading()
            else if (controller.hasDevices)
              _buildDeviceDropdown(controller)
            else if (controller.error != null)
              _buildErrorCard(controller.error!)
            else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: grey700,
      highlightColor: grey600,
      child: Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: grey700,
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  Widget _buildDeviceDropdown(RokuController controller) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: grey700, width: 1),
      ),
      child: DropdownButton<DeviceModel>(
        value: controller.selectedDevice,
        isExpanded: true,
        dropdownColor: surfaceColor,
        underline: const SizedBox(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: primaryColor,
          size: 24.sp,
        ),
        hint: CustomTextWidget(
          text: 'Select a device',
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: textColor3,
        ),
        items: controller.discoveredDevices.map((device) {
          final isRoku = device.type == DeviceType.roku;
          return DropdownMenuItem(
            value: device,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: isRoku
                        ? primaryColor.withOpacity(0.2)
                        : accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    isRoku ? Icons.tv_rounded : Icons.cast_rounded,
                    color: isRoku ? primaryColor : accentColor,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomTextWidget(
                        text: device.displayName,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        maxLines: 1,
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: isRoku
                                  ? primaryColor.withOpacity(0.15)
                                  : accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: CustomTextWidget(
                              text: isRoku ? 'Roku' : 'Google TV',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: isRoku ? primaryColor : accentColor,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          CustomTextWidget(
                            text: device.ipAddress,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: textColor3,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) => controller.selectDevice(value),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: errorColor, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: CustomTextWidget(
              text: error,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: errorColor,
              maxLines: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          Icon(Icons.devices_other_rounded, color: grey600, size: 48.sp),
          SizedBox(height: 16.h),
          CustomTextWidget(
            text: 'No devices found',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: textColor2,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          CustomTextWidget(
            text:
                'Tap Discover to search for Roku and Google TV devices on your network',
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: textColor3,
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildMockDevicesSection(
    BuildContext context,
    RokuController controller,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: warningColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_rounded, color: warningColor, size: 20.sp),
              SizedBox(width: 8.w),
              CustomTextWidget(
                text: 'Mock Devices',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: warningColor,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...controller.mockDevices.map(
            (device) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            device.type == DeviceType.roku
                                ? Icons.tv_rounded
                                : Icons.cast_rounded,
                            color: device.type == DeviceType.roku
                                ? primaryColor
                                : accentColor,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomTextWidget(
                                  text: device.displayName,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                  maxLines: 1,
                                ),
                                CustomTextWidget(
                                  text: device.ipAddress,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: textColor3,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    onPressed: () =>
                        controller.removeMockDevice(device.ipAddress),
                    icon: Icon(
                      Icons.close_rounded,
                      color: errorColor,
                      size: 20.sp,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),
          ElevatedButton.icon(
            onPressed: () => _showAddMockDeviceDialog(context, controller),
            icon: Icon(Icons.add_rounded, size: 18.sp),
            label: CustomTextWidget(
              text: 'Add Mock Device',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: warningColor.withOpacity(0.2),
              foregroundColor: warningColor,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMockDeviceDialog(
    BuildContext context,
    RokuController controller,
  ) {
    final textController = TextEditingController();
    DeviceType selectedType = DeviceType.roku;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: surfaceColor,
          title: CustomTextWidget(
            text: 'Add Mock Device',
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextWidget(
                text: 'Device Type',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: textColor2,
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => selectedType = DeviceType.roku),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: selectedType == DeviceType.roku
                              ? primaryColor.withOpacity(0.2)
                              : cardColor,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: selectedType == DeviceType.roku
                                ? primaryColor
                                : grey700,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.tv_rounded,
                              color: selectedType == DeviceType.roku
                                  ? primaryColor
                                  : textColor3,
                              size: 18.sp,
                            ),
                            SizedBox(width: 8.w),
                            CustomTextWidget(
                              text: 'Roku',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: selectedType == DeviceType.roku
                                  ? primaryColor
                                  : textColor3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => selectedType = DeviceType.googleTv),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: selectedType == DeviceType.googleTv
                              ? accentColor.withOpacity(0.2)
                              : cardColor,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: selectedType == DeviceType.googleTv
                                ? accentColor
                                : grey700,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cast_rounded,
                              color: selectedType == DeviceType.googleTv
                                  ? accentColor
                                  : textColor3,
                              size: 18.sp,
                            ),
                            SizedBox(width: 8.w),
                            CustomTextWidget(
                              text: 'Google TV',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: selectedType == DeviceType.googleTv
                                  ? accentColor
                                  : textColor3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              CustomTextWidget(
                text: 'IP Address',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: textColor2,
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: textController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: '192.168.1.100',
                  hintStyle: TextStyle(color: textColor3),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: grey700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: grey700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(
                      color: selectedType == DeviceType.roku
                          ? primaryColor
                          : accentColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: CustomTextWidget(
                text: 'Cancel',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: textColor3,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final ip = textController.text.trim();
                if (ip.isNotEmpty) {
                  controller.addMockDevice(ip, selectedType);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedType == DeviceType.roku
                    ? primaryColor
                    : accentColor,
              ),
              child: CustomTextWidget(
                text: 'Add',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDeviceCard(
    BuildContext context,
    RokuController controller,
  ) {
    final device = controller.selectedDevice!;
    final isRoku = device.type == DeviceType.roku;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isRoku
                    ? primaryColor.withOpacity(0.2)
                    : accentColor.withOpacity(0.2),
                primaryColor2.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isRoku
                  ? primaryColor.withOpacity(0.3)
                  : accentColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isRoku
                      ? primaryColor.withOpacity(0.3)
                      : accentColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: isRoku ? primaryColor : accentColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextWidget(
                      text: 'Connected Device',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: textColor3,
                    ),
                    SizedBox(height: 4.h),
                    CustomTextWidget(
                      text: device.displayName,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      maxLines: 1,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: isRoku
                                ? primaryColor.withOpacity(0.2)
                                : accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: CustomTextWidget(
                            text: isRoku ? 'Roku' : 'Google TV',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: isRoku ? primaryColor : accentColor,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        CustomTextWidget(
                          text: device.ipAddress,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: textColor3,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        // Open Remote Control Button
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isRoku
                  ? [primaryColor, primaryColor2]
                  : [accentColor, accentColor2],
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: (isRoku ? primaryColor : accentColor).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  PageTransition(
                    isIos: Platform.isIOS,
                    type: PageTransitionType.rightToLeft,
                    alignment: Alignment.center,
                    duration: const Duration(milliseconds: 270),
                    curve: Curves.easeInOut,
                    child: const ControlScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 18.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.gamepad_rounded, color: textColor, size: 24.sp),
                    SizedBox(width: 12.w),
                    CustomTextWidget(
                      text: 'Open Remote Control',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: textColor,
                      size: 20.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
