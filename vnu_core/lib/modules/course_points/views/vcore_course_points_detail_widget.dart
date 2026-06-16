import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/common/grade_scale_helper.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_core/models/diem_hoc_phan_model.dart';
import 'package:vnu_core/models/diem_thi_hoc_ky_model.dart';
import 'package:vnu_core/repository/app_repository.dart';

class VcoreCoursePointsDetailWidget extends StatefulWidget {
  final String kieuTruong;
  final DiemThiHocKyModel diemThiHocKyModel;

  const VcoreCoursePointsDetailWidget({
    super.key,
    required this.kieuTruong,
    required this.diemThiHocKyModel,
  });

  @override
  State<VcoreCoursePointsDetailWidget> createState() =>
      _VcoreCoursePointsDetailWidgetState();
}

class _VcoreCoursePointsDetailWidgetState
    extends State<VcoreCoursePointsDetailWidget> {
  bool isLoadingDiemHocPhan = true;
  List<DiemHocPhanModel> listDiemMonHoc = [];

  @override
  void initState() {
    super.initState();
    _getDiemHocPhanHocKy();
  }

  Future<void> _getDiemHocPhanHocKy() async {
    setState(() {
      isLoadingDiemHocPhan = true;
    });

    try {
      final response = await ApiRepository().getDiemHocPhanHocKyMobile(
        widget.diemThiHocKyModel.idHocKy ?? '',
        widget.kieuTruong,
        widget.diemThiHocKyModel.idHocPhan ?? '',
      );

      if (!mounted) return;

      setState(() {
        listDiemMonHoc = response;
        isLoadingDiemHocPhan = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingDiemHocPhan = false;
      });

      snackBarError(e.toString());
    }
  }

  double? _score10Value() {
    final raw = widget.diemThiHocKyModel.diemHe10;
    if (raw == null || raw.trim().isEmpty) return null;
    return double.tryParse(raw.replaceAll(',', '.'));
  }

  _ScoreTheme _scoreTheme(double? score10) {
    if (score10 == null) {
      return const _ScoreTheme(
        label: 'Chưa có điểm',
        statusText: 'Chưa có dữ liệu đánh giá',
        accentColor: Color(0xFF6B7280),
        softColor: Color(0xFFF3F4F6),
        borderColor: Color(0xFFE5E7EB),
        icon: Icons.help_outline_rounded,
      );
    }

    if (score10 >= 8.5) {
      return const _ScoreTheme(
        label: 'Điểm cao',
        statusText: 'Kết quả học phần rất tốt',
        accentColor: Color(0xFF16A34A),
        softColor: Color(0xFFEAFBF0),
        borderColor: Color(0xFFB7E4C7),
        icon: Icons.workspace_premium_rounded,
      );
    }

    if (score10 >= 7.0) {
      return const _ScoreTheme(
        label: 'Điểm khá',
        statusText: 'Kết quả học phần ổn định',
        accentColor: Color(0xFF2563EB),
        softColor: Color(0xFFEFF6FF),
        borderColor: Color(0xFFBFDBFE),
        icon: Icons.trending_up_rounded,
      );
    }

    if (score10 >= 5.0) {
      return const _ScoreTheme(
        label: 'Trung bình',
        statusText: 'Đã đạt mức yêu cầu',
        accentColor: Color(0xFFF59E0B),
        softColor: Color(0xFFFFF7ED),
        borderColor: Color(0xFFFED7AA),
        icon: Icons.remove_circle_outline_rounded,
      );
    }

    return const _ScoreTheme(
      label: 'Cần cải thiện',
      statusText: 'Cần chú ý học phần này',
      accentColor: Color(0xFFDC2626),
      softColor: Color(0xFFFFF1F2),
      borderColor: Color(0xFFFECDD3),
      icon: Icons.warning_amber_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final score10 = _score10Value();
    final theme = _scoreTheme(score10);

    final scoreText =
        widget.diemThiHocKyModel.diemHe10?.trim().isNotEmpty == true
        ? widget.diemThiHocKyModel.diemHe10!.trim()
        : '--';

    final letterGrade = _displayText(widget.diemThiHocKyModel.diemHeChu);

    final score4 = _displayText(widget.diemThiHocKyModel.diemHe4);

    final isPassed = score10 != null
        ? GradeScaleHelper.isPassed(score10)
        : false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCourseHeader(),
          const SizedBox(height: 16),

          _buildOverallPointCard(
            theme: theme,
            score10Text: scoreText,
            letterGrade: letterGrade,
            score4: score4,
            isPassed: isPassed,
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const Icon(
                Icons.insert_chart_outlined_rounded,
                size: 20,
                color: Color(0xFF18A957),
              ),
              const SizedBox(width: 8),
              Text(
                'Điểm thành phần',
                style: TextStyles.bold.copyWith(
                  fontSize: AppFontSizes.mediumLarge,
                  color: AppColors.textTitle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (isLoadingDiemHocPhan)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          else if (listDiemMonHoc.isEmpty)
            _buildEmptyState()
          else
            ...listDiemMonHoc.map(_buildPointItem).toList(),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCourseHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.diemThiHocKyModel.tenHocPhan ?? 'Học phần',
          style: TextStyles.bold.copyWith(
            fontSize: AppFontSizes.extraLarge,
            color: AppColors.textTitle,
            height: 1.22,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSoftTag(
              icon: Icons.qr_code_2_rounded,
              text: widget.diemThiHocKyModel.maHocPhan ?? '--',
            ),
            _buildSoftTag(
              icon: Icons.confirmation_number_outlined,
              text: '${widget.diemThiHocKyModel.soTinChi ?? '0'} tín chỉ',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverallPointCard({
    required _ScoreTheme theme,
    required String score10Text,
    required String letterGrade,
    required String score4,
    required bool isPassed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.accentColor.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.softColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(theme.icon, color: theme.accentColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng quan điểm',
                      style: TextStyles.bold.copyWith(
                        fontSize: AppFontSizes.mediumLarge,
                        color: AppColors.textTitle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      theme.statusText,
                      style: TextStyles.medium.copyWith(
                        fontSize: AppFontSizes.small,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.softColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Text(
                  score10Text,
                  textAlign: TextAlign.center,
                  style: TextStyles.extraBold.copyWith(
                    fontSize: 26,
                    height: 1,
                    color: theme.accentColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  label: 'Hệ 10',
                  value: score10Text,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricBox(
                  label: 'Điểm chữ',
                  value: letterGrade,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricBox(
                  label: 'Hệ 4',
                  value: score4,
                  theme: theme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isPassed
                  ? const Color(0xFFEAFBF0)
                  : const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPassed
                    ? const Color(0xFFB7E4C7)
                    : const Color(0xFFFECDD3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 18,
                  color: isPassed
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                Text(
                  isPassed ? 'Đạt học phần' : 'Chưa đạt học phần',
                  style: TextStyles.bold.copyWith(
                    fontSize: AppFontSizes.small,
                    color: isPassed
                        ? const Color(0xFF166534)
                        : const Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required _ScoreTheme theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.medium.copyWith(
              fontSize: AppFontSizes.extraSmall,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyles.extraBold.copyWith(
              fontSize: AppFontSizes.mediumLarge,
              color: AppColors.textTitle,
            ),
          ),
        ],
      ),
    );
  }

  String _displayText(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? '--' : text;
  }

  Widget _buildPointItem(DiemHocPhanModel diemHocPhan) {
    final rawScore = diemHocPhan.diemHe10?.trim() ?? '';
    final componentScore = rawScore.isEmpty
        ? null
        : double.tryParse(rawScore.replaceAll(',', '.'));
    final theme = _scoreTheme(componentScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.018),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.softColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.insert_chart_outlined_rounded,
              color: theme.accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diemHocPhan.loaiDiemHocPhan ?? 'Điểm thành phần',
                  style: TextStyles.bold.copyWith(
                    fontSize: AppFontSizes.medium,
                    color: AppColors.textTitle,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _buildInlineInfo(
                      label: 'Trọng số',
                      value: diemHocPhan.trongSo ?? '--',
                    ),
                    _buildInlineInfo(
                      label: 'Điểm',
                      value: rawScore.isEmpty ? '--' : rawScore,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            constraints: const BoxConstraints(minWidth: 58),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.softColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              rawScore.isEmpty ? '--' : rawScore,
              textAlign: TextAlign.center,
              style: TextStyles.extraBold.copyWith(
                fontSize: AppFontSizes.mediumLarge,
                color: theme.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineInfo({required String label, required String value}) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyles.medium.copyWith(
              fontSize: AppFontSizes.extraSmall,
              color: AppColors.textSecondary,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyles.bold.copyWith(
              fontSize: AppFontSizes.extraSmall,
              color: AppColors.textTitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.grey.shade500,
            size: 26,
          ),
          const SizedBox(height: 8),
          Text(
            'Chưa có thông tin điểm thành phần',
            textAlign: TextAlign.center,
            style: TextStyles.medium.copyWith(
              fontSize: AppFontSizes.medium,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoftTag({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF18A957)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreTheme {
  final String label;
  final String statusText;
  final Color accentColor;
  final Color softColor;
  final Color borderColor;
  final IconData icon;

  const _ScoreTheme({
    required this.label,
    required this.statusText,
    required this.accentColor,
    required this.softColor,
    required this.borderColor,
    required this.icon,
  });
}
