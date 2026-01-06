import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' hide DeviceType;
import 'package:provider/provider.dart';
import '../../data/models/device_model.dart';
import '../../presentation/controllers/roku_controller.dart';
import '../widgets/custom_text_widget.dart';
import '../widgets/colors.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomTextWidget(
          text: 'Remote Control',
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      body: SafeArea(
        child: Consumer<RokuController>(
          builder: (context, controller, child) {
            if (controller.selectedDevice == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.devices_other_rounded, color: grey600, size: 64.sp),
                    SizedBox(height: 16.h),
                    CustomTextWidget(
                      text: 'No device selected',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: textColor2,
                    ),
                    SizedBox(height: 8.h),
                    CustomTextWidget(
                      text: 'Please select a device from the home screen',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: textColor3,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final isGoogleTv = controller.selectedDevice?.type == DeviceType.googleTv;

            return SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Device Info Card
                  _buildDeviceInfoCard(controller),
                  SizedBox(height: 32.h),

                  // Google TV Warning
                  if (isGoogleTv) ...[
                    _buildGoogleTvWarning(),
                    SizedBox(height: 24.h),
                  ],

                  // Control Instructions
                  CustomTextWidget(
                    text: 'Use the buttons below to navigate',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: textColor2,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.h),

                  // D-Pad Layout
                  _buildControlButtons(controller),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard(RokuController controller) {
    final device = controller.selectedDevice!;
    final isRoku = device.type == DeviceType.roku;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isRoku
                ? primaryColor.withOpacity(0.2)
                : accentColor.withOpacity(0.2),
            surfaceColorLight,
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isRoku ? primaryColor.withOpacity(0.3) : accentColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isRoku
                  ? primaryColor.withOpacity(0.3)
                  : accentColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              isRoku ? Icons.tv_rounded : Icons.cast_rounded,
              color: isRoku ? primaryColor : accentColor,
              size: 32.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextWidget(
                  text: device.displayName,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  maxLines: 2,
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isRoku
                            ? primaryColor.withOpacity(0.2)
                            : accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: CustomTextWidget(
                        text: isRoku ? 'Roku' : 'Google TV',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isRoku ? primaryColor : accentColor,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    CustomTextWidget(
                      text: device.ipAddress,
                      fontSize: 14.sp,
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
    );
  }

  Widget _buildGoogleTvWarning() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: warningColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: warningColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomTextWidget(
                  text: 'Google TV Remote Control',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: warningColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          CustomTextWidget(
            text:
                'Google TV devices don\'t support simple HTTP remote control. They require the Google Cast SDK with an active Cast session. The buttons may not work without establishing a Cast connection first.',
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            color: textColor2,
            maxLines: 6,
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: warningColor, size: 18.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: CustomTextWidget(
                    text: 'Tip: Use the Google Home app to control your Google TV device.',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: warningColor,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(RokuController controller) {
    // Calculate button size to be consistent and responsive
    final buttonSize = 100.w;
    final spacing = 12.w;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Up Button
          _buildControlButton(
            icon: Icons.keyboard_arrow_up_rounded,
            label: 'Up',
            onPressed: () => controller.pressUp(),
            gradient: [accentColor, accentColor2],
            size: buttonSize,
          ),
          SizedBox(height: spacing),

          // Left, Down, Right Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildControlButton(
                icon: Icons.keyboard_arrow_left_rounded,
                label: 'Left',
                onPressed: () => controller.pressLeft(),
                gradient: [primaryColor, primaryColor2],
                size: buttonSize,
              ),
              SizedBox(width: spacing),
              _buildControlButton(
                icon: Icons.keyboard_arrow_down_rounded,
                label: 'Down',
                onPressed: () => controller.pressDown(),
                gradient: [primaryColor3, primaryColor2],
                size: buttonSize,
              ),
              SizedBox(width: spacing),
              _buildControlButton(
                icon: Icons.keyboard_arrow_right_rounded,
                label: 'Right',
                onPressed: () => controller.pressRight(),
                gradient: [successColor, accentColor],
                size: buttonSize,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required List<Color> gradient,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20.r),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            padding: EdgeInsets.all(12.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: textColor, size: 32.sp),
                SizedBox(height: 6.h),
                CustomTextWidget(
                  text: label,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

