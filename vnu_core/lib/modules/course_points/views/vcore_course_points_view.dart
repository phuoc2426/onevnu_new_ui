import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uuid/uuid.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/extensions/extension_string.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/modules/course_points/controllers/vcore_course_points_controller.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

import '../../../ai_radar/models/ai_radar_analysis.dart';
import '../../exam_schedule/views/vcore_dropdown_select_widget.dart';

class VcoreCoursePointsView extends GetView<VcoreCoursePointsController> {
  const VcoreCoursePointsView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VcoreCoursePointsController>(
      init: VcoreCoursePointsController(),
      tag: const Uuid().v4(),
      builder: (controller) {
        return ProgressHubWidget(
          contextComplete: (hubContext) {
            controller.context = hubContext;
            if (controller.danhSachKieuTruong.isEmpty) {
              controller.getDanhSachKieuTruong();
            }
          },
          child: VcoreModuleScaffold(
            title: 'Xem điểm môn học',
            body: Obx(() {
              final courses = controller.diemThiHocKy.toList();
              final gpa = controller.diemTrungBinhHocKy.value;
              final analysis = controller.aiRadarAnalysis.value;
              final isLoading = controller.isLoadingAi.value;
              final loadingText = controller.loadingStateText.value;

              if (isLoading) {
                return _buildLoadingState(loadingText);
              }

              return SmartRefresher(
                controller: controller.refreshController,
                enablePullUp: false,
                onRefresh: controller.refreshData,
                onLoading: controller.loadMoreData,
                header: const WaterDropHeader(
                  waterDropColor: AppColors.primary,
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    _buildTopHeaderRow(context, controller, analysis),
                    const SizedBox(height: 14),
                    if (analysis == null) ...[
                      _AiRadarPromotionalCard(
                        onStart: () => controller.runAiAnalysis(),
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      _AnimatedCourseRadarCard(
                        analysis: analysis,
                        courseCount: courses.length,
                      ),
                      const SizedBox(height: 4),
                    ],
                    _GpaSummaryCard(gpa: gpa),
                    if (analysis != null) ...[
                      const SizedBox(height: 14),
                      _buildCapabilityAnalysisList(analysis),
                    ],
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(String loadingText) {
    return Container(
      color: Colors.white.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loadingText,
              style: TextStyles.bold.copyWith(
                fontSize: 16,
                color: AppColors.primaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Hệ thống đang xử lý dữ liệu offline...',
              style: TextStyles.medium.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeaderRow(
    BuildContext context,
    VcoreCoursePointsController controller,
    AiRadarAnalysis? analysis,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _showFilterBottomSheet(context, controller),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.greenAccent, width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 14,
                  color: AppColors.greenAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  'Xem điểm khác',
                  style: TextStyles.semiBold.copyWith(
                    fontSize: 12,
                    color: AppColors.greenAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context, VcoreCoursePointsController controller) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Xem điểm khác',
                    style: TextStyles.bold.copyWith(
                      fontSize: 16,
                      color: AppColors.textTitle,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (controller.danhSachKieuTruong.isNotEmpty) ...[
                Text(
                  'Đơn vị đào tạo',
                  style: TextStyles.bold.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                VcoreDropdownSelectWidget(
                  items: controller.danhSachKieuTruong.map((e) => e.toDisplayName()).toList(),
                  hint: 'Chọn trường',
                  value: controller.kieuTruong.value?.toDisplayName(),
                  onSelected: (value) {
                    final kieuTruong = controller.danhSachKieuTruong.firstWhereOrNull(
                      (e) => e.toDisplayName() == value,
                    );
                    if (kieuTruong != null) {
                      controller.kieuTruong.value = kieuTruong;
                      controller.getDanhSachHocKy();
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  controller.isTheoChuongTrinhDaoTao.toggle();
                  controller.refreshData();
                },
                child: Row(
                  children: [
                    Obx(() => Icon(
                      controller.isTheoChuongTrinhDaoTao.value
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_outlined,
                      color: AppColors.primary,
                      size: 24,
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Xem cả các môn ngoài chương trình đào tạo',
                        style: TextStyles.semiBold.copyWith(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.aiRadarAnalysis.value != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      controller.runAiAnalysis();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Quét lại',
                      style: TextStyles.bold.copyWith(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildCapabilityAnalysisList(AiRadarAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10, top: 6),
          child: Text(
            'Phân tích chi tiết năng lực',
            style: TextStyles.extraBold.copyWith(
              color: AppColors.textTitle,
              fontSize: 16,
            ),
          ),
        ),
        ...analysis.dimensions.map((dim) => _CapabilityDimensionCard(dimension: dim)),
      ],
    );
  }
}

class _AiRadarPromotionalCard extends StatelessWidget {
  const _AiRadarPromotionalCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Phân tích Năng lực học tập bằng AI',
            style: TextStyles.extraBold.copyWith(
              color: AppColors.textTitle,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Hệ thống AI sẽ phân tích các học phần đã tích lũy của bạn, suy luận ngành học và tự động thiết kế bộ 6-10 mũi nhọn năng lực chuẩn để đánh giá chuyên sâu.',
            style: TextStyles.regular.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Bắt đầu phân tích',
                style: TextStyles.bold.copyWith(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _AnimatedCourseRadarCard extends StatefulWidget {
  const _AnimatedCourseRadarCard({
    required this.analysis,
    required this.courseCount,
  });

  final AiRadarAnalysis analysis;
  final int courseCount;

  @override
  State<_AnimatedCourseRadarCard> createState() => _AnimatedCourseRadarCardState();
}

class _AnimatedCourseRadarCardState extends State<_AnimatedCourseRadarCard> with TickerProviderStateMixin {
  late final AnimationController _polygonController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _polygonController,
            builder: (context, _) {
              return SizedBox(
                height: 350,
                width: double.infinity,
                child: CustomPaint(
                  painter: _CourseRadarPainter(
                    dimensions: widget.analysis.dimensions,
                    progress: Curves.easeOutCubic.transform(_polygonController.value),
                  ),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _polygonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedCourseRadarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.analysis.dimensions.map((e) => '${e.code}:${e.score}').join('|') !=
        widget.analysis.dimensions.map((e) => '${e.code}:${e.score}').join('|')) {
      _polygonController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _polygonController.dispose();
    super.dispose();
  }
}

class _CourseRadarPainter extends CustomPainter {
  _CourseRadarPainter({
    required this.dimensions,
    required this.progress,
  });

  final List<RadarDimension> dimensions;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (dimensions.length < 3) return;

    final center = Offset(size.width / 2, size.height / 2 + 10);
    final radius = math.min(size.width, size.height) * 0.26;
    final count = dimensions.length;
    const startAngle = -math.pi / 2;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.primary.withValues(alpha: 0.13);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.primary.withValues(alpha: 0.35);

    final axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.primary.withValues(alpha: 0.12);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withValues(alpha: 0.19);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary;

    for (var level = 1; level <= 5; level++) {
      final r = radius * level / 5;
      final path = Path();
      for (var i = 0; i < count; i++) {
        final angle = startAngle + 2 * math.pi * i / count;
        final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, level == 5 ? borderPaint : gridPaint);
    }

    for (var i = 0; i < count; i++) {
      final angle = startAngle + 2 * math.pi * i / count;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(center, end, axisPaint);
    }

    final polygon = Path();
    final points = <Offset>[];
    for (var i = 0; i < count; i++) {
      final value = (dimensions[i].score.clamp(0, 100) / 100) * progress;
      final angle = startAngle + 2 * math.pi * i / count;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius * value;
      points.add(point);
      if (i == 0) {
        polygon.moveTo(point.dx, point.dy);
      } else {
        polygon.lineTo(point.dx, point.dy);
      }
    }
    polygon.close();

    if (progress > 0.02) {
      canvas.drawPath(polygon, fillPaint);
      canvas.drawPath(polygon, linePaint);
    }

    for (var i = 0; i < count; i++) {
      final angle = startAngle + 2 * math.pi * i / count;
      final labelPoint = center + Offset(math.cos(angle), math.sin(angle)) * (radius + 26);
      _paintText(
        canvas,
        text: '${dimensions[i].code}\n${dimensions[i].score.round()}',
        center: labelPoint,
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      );
    }

    for (final point in points) {
      canvas.drawCircle(
        point,
        7,
        Paint()..color = AppColors.primary.withValues(alpha: 0.13),
      );
      canvas.drawCircle(
        point,
        4.2,
        Paint()..color = AppColors.primary,
      );
    }
  }

  void _paintText(
    Canvas canvas, {
    required String text,
    required Offset center,
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: TextStyles.fontName,
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.05,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 62);

    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CourseRadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.dimensions.map((e) => '${e.code}:${e.score}').join('|') !=
            dimensions.map((e) => '${e.code}:${e.score}').join('|');
  }
}

class _CapabilityDimensionCard extends StatefulWidget {
  const _CapabilityDimensionCard({required this.dimension});

  final RadarDimension dimension;

  @override
  State<_CapabilityDimensionCard> createState() => _CapabilityDimensionCardState();
}

class _CapabilityDimensionCardState extends State<_CapabilityDimensionCard> {
  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor(widget.dimension.level);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          title: Row(
            children: [
              Container(
                width: 44,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.dimension.code,
                  style: TextStyles.extraBold.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.dimension.nameVi,
                      style: TextStyles.bold.copyWith(
                        color: AppColors.textTitle,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: levelColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.dimension.level.toUpperCase(),
                            style: TextStyles.bold.copyWith(
                              color: levelColor,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Relevance: ${widget.dimension.evidenceCourses.length} môn',
                            style: TextStyles.medium.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${widget.dimension.score.round()}',
                style: TextStyles.extraBold.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.borderLight, height: 16),
                  Text(
                    'Chi tiết mũi nhọn:',
                    style: TextStyles.bold.copyWith(
                      color: AppColors.textTitle,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.dimension.descriptionVi,
                    style: TextStyles.regular.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Lý do chấm điểm:',
                    style: TextStyles.bold.copyWith(
                      color: AppColors.textTitle,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.dimension.reasonVi,
                    style: TextStyles.regular.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.dimension.missingEvidenceVi.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warningBoxBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warningBoxBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.warningBoxText, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.dimension.missingEvidenceVi,
                              style: TextStyles.medium.copyWith(
                                color: AppColors.warningBoxText,
                                fontSize: 11.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Text(
                    'Bằng chứng học phần:',
                    style: TextStyles.bold.copyWith(
                      color: AppColors.textTitle,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (widget.dimension.evidenceCourses.isEmpty)
                    Text(
                      'Không tìm thấy học phần liên quan.',
                      style: TextStyles.italic.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    )
                  else
                    ...widget.dimension.evidenceCourses.map((ev) => _EvidenceCourseRow(evidence: ev)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'rất mạnh':
        return AppColors.gradeVeryStrong;
      case 'mạnh':
        return AppColors.gradeStrong;
      case 'khá':
        return AppColors.gradeFair;
      case 'trung bình':
        return AppColors.gradeAverage;
      case 'yếu':
      default:
        return AppColors.gradeWeak;
    }
  }
}

class _EvidenceCourseRow extends StatelessWidget {
  const _EvidenceCourseRow({required this.evidence});

  final EvidenceCourse evidence;

  @override
  Widget build(BuildContext context) {
    Color impactColor = Colors.grey;
    IconData impactIcon = Icons.info_outline;

    if (evidence.impact == 'positive') {
      impactColor = AppColors.gradeStrong;
      impactIcon = Icons.add_circle_outline;
    } else if (evidence.impact == 'negative') {
      impactColor = AppColors.gradeWeak;
      impactIcon = Icons.remove_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(impactIcon, color: impactColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        evidence.courseName,
                        style: TextStyles.bold.copyWith(
                          color: AppColors.textTitle,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Điểm: ${evidence.grade.toStringAsFixed(1)}',
                      style: TextStyles.bold.copyWith(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  evidence.reasonVi,
                  style: TextStyles.regular.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GpaSummaryCard extends StatelessWidget {
  const _GpaSummaryCard({required this.gpa});

  final DiemTrungBinhModel? gpa;

  @override
  Widget build(BuildContext context) {
    final gpa4Total = _text(gpa?.diemTrungBinhHe4TichLuyDenHocKyHienTai);
    final gpa10Total = _text(gpa?.diemTrungBinhHe10TichLuyDenHocKyHienTai);
    final tcTotal = _text(gpa?.tongSoTinChiTichLuyTichLuyDenHocKyHienTai);
    final tcFailed = _text(gpa?.tongSoTinChiTruotTichLuyDenHocKyHienTai);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
        boxShadow: [
          AppColors.cardShadow,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông số GPA tích lũy',
            style: TextStyles.extraBold.copyWith(
              color: AppColors.textTitle,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GpaBigMetric(
                  label: 'GPA tích lũy hệ 4',
                  value: gpa4Total,
                  icon: Icons.timeline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GpaBigMetric(
                  label: 'GPA tích lũy hệ 10',
                  value: gpa10Total,
                  icon: Icons.auto_graph_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SmallInfo(
                  label: 'Tổng TC tích lũy',
                  value: tcTotal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallInfo(
                  label: 'Tổng TC trượt',
                  value: tcFailed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _text(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? '--' : text;
  }
}

class _GpaBigMetric extends StatelessWidget {
  const _GpaBigMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyles.extraBold.copyWith(
              color: AppColors.primaryDark,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyles.semiBold.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  const _SmallInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.extraBold.copyWith(
              color: AppColors.textTitle,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.semiBold.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: TextStyles.bold.copyWith(
          color: Colors.white,
          fontSize: 11,
        ),
      ),
    );
  }
}
