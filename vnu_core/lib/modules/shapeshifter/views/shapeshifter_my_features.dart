import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/modules/shapeshifter/models/shapeshifter_feature.dart';
import 'package:vnu_core/modules/shapeshifter/repository/shapeshifter_repository.dart';
import 'package:vnu_core/modules/shapeshifter/services/shapeshifter_launcher.dart';

enum ShapeshifterMyLayout { studentList, admittedGrid }

/// API-driven Shapeshifter entries for the "My" area.
///
/// IMPORTANT: audience filtering is performed by the Mobile API from the
/// authenticated principal. This widget never decides whether the user is a
/// STUDENT or APPLICANT/Admitted Student.
class ShapeshifterMyFeatures extends StatefulWidget {
  const ShapeshifterMyFeatures({
    super.key,
    required this.layout,
    this.showSectionTitle = true,
    this.admittedLeadingItems = const <Widget>[],
  });

  final ShapeshifterMyLayout layout;
  final bool showSectionTitle;

  /// Native cards that must appear before dynamic Shapeshifter features in
  /// the Admitted Student My screen. They share the same horizontal strip so
  /// exactly three cards are visible and extra services can be swiped sideways.
  final List<Widget> admittedLeadingItems;

  @override
  State<ShapeshifterMyFeatures> createState() => _ShapeshifterMyFeaturesState();
}

class _ShapeshifterMyFeaturesState extends State<ShapeshifterMyFeatures> {
  late Future<List<ShapeshifterFeature>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ShapeshifterFeature>> _load() async {
    final bool admitted = widget.layout == ShapeshifterMyLayout.admittedGrid;

    try {
      if (!admitted) {
        debugPrint('[SHAPE_MY] GET features placement=MY layout=student');
        final List<ShapeshifterFeature> features =
            await ShapeshifterRepository().getFeatures(
          placement: ShapeshifterPlacement.my,
        );
        debugPrint(
          '[SHAPE_MY] student MY loaded=${features.length} ' +
              features.map((feature) => feature.code).join(','),
        );
        return features;
      }

      // Admitted Student has only one service hub (YourSpace/My), while the
      // registry can place a feature in HOME, MY, or both. Query both
      // placements with the APPLICANT token and merge by feature code so a
      // feature enabled for admitted students is not lost only because it was
      // configured as HOME in Admin. The Mobile API remains the authority for
      // enabled/time-window/audience filtering.
      debugPrint('[SHAPE_MY] GET features placement=MY+HOME layout=admitted');
      final List<List<ShapeshifterFeature>> result = await Future.wait(
        <Future<List<ShapeshifterFeature>>>[
          ShapeshifterRepository().getFeatures(
            placement: ShapeshifterPlacement.my,
          ),
          ShapeshifterRepository().getFeatures(
            placement: ShapeshifterPlacement.home,
          ),
        ],
      );

      final List<ShapeshifterFeature> myFeatures = result[0];
      final List<ShapeshifterFeature> homeFeatures = result[1];
      final Map<String, ShapeshifterFeature> merged =
          <String, ShapeshifterFeature>{};

      // Keep MY order first; append HOME-only features afterwards. Dart maps
      // preserve insertion order, so Admin ordering remains predictable.
      for (final ShapeshifterFeature feature in myFeatures) {
        merged[feature.code] = feature;
      }
      for (final ShapeshifterFeature feature in homeFeatures) {
        merged.putIfAbsent(feature.code, () => feature);
      }

      final List<ShapeshifterFeature> features = merged.values.toList();
      debugPrint(
        '[SHAPE_MY] admitted MY=${myFeatures.length} HOME=${homeFeatures.length} ' +
            'merged=${features.length} ' +
            features.map((feature) => feature.code).join(','),
      );
      return features;
    } catch (error, stackTrace) {
      debugPrint('[SHAPE_MY] load error: $error');
      debugPrintStack(label: '[SHAPE_MY] stack', stackTrace: stackTrace);
      rethrow;
    }
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ShapeshifterFeature>>(
      future: _future,
      builder: (context, snapshot) {
        final bool admitted = widget.layout == ShapeshifterMyLayout.admittedGrid;

        if (snapshot.connectionState == ConnectionState.waiting) {
          // Native Admission services must remain immediately usable while the
          // dynamic registry is loading.
          if (admitted && widget.admittedLeadingItems.isNotEmpty) {
            return _admittedGrid(context, const <ShapeshifterFeature>[]);
          }
          return _loading();
        }
        if (snapshot.hasError) {
          if (admitted && widget.admittedLeadingItems.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _admittedGrid(context, const <ShapeshifterFeature>[]),
                _errorRetry(),
              ],
            );
          }
          return _errorRetry();
        }
        final features = snapshot.data ?? const <ShapeshifterFeature>[];

        // Không ẩn toàn bộ khu vực MY khi API trả danh sách rỗng. Với Student,
        // header + nút reload phải luôn còn để người dùng có thể gọi lại registry
        // ngay sau khi Admin vừa bật thêm chức năng. Với Applicant, các card native
        // vẫn hiển thị và feature động sẽ xuất hiện ngay sau lần reload kế tiếp.
        return widget.layout == ShapeshifterMyLayout.studentList
            ? _studentList(context, features)
            : _admittedGrid(context, features);
      },
    );
  }

  Widget _errorRetry() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Text(
              'Chưa tải được chức năng mở rộng.',
              style: TextStyle(
                color: Color(0xFF667085),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }

  Widget _loading() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: LinearProgressIndicator(minHeight: 2),
    );
  }

  Widget _studentList(
    BuildContext context,
    List<ShapeshifterFeature> features,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showSectionTitle)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 2, 12, 10),
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'DỊCH VỤ CỦA BẠN',
                    style: TextStyle(
                      color: AppColors.brandGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Tải lại chức năng mới nhất',
                  child: IconButton(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                    color: AppColors.brandGreen,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        if (features.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 2, 20, 10),
            child: Text(
              'Chưa có chức năng mở rộng được bật cho tài khoản này.',
              style: TextStyle(
                color: Color(0xFF667085),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          for (int i = 0; i < features.length; i++) ...[
            _StudentFeatureTile(feature: features[i]),
            if (i != features.length - 1) const SizedBox(height: 12),
          ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _admittedGrid(
    BuildContext context,
    List<ShapeshifterFeature> features,
  ) {
    final List<Widget> cards = <Widget>[
      ...widget.admittedLeadingItems,
      ...features.map((feature) => _AdmittedFeatureCard(feature: feature)),
    ];

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showSectionTitle)
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 16, bottom: 14),
            child: Text(
              'DỊCH VỤ MỞ RỘNG',
              style: TextStyle(
                color: AppColors.brandGreen,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            const double gap = 12;
            final double availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final double cardWidth =
                ((availableWidth - (gap * 2)) / 3).clamp(82.0, 180.0).toDouble();
            final double cardHeight = cardWidth / 0.85;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                SizedBox(
                  height: cardHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    physics: cards.length > 3
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    itemCount: cards.length,
                    separatorBuilder: (_, __) => const SizedBox(width: gap),
                    itemBuilder: (context, index) => SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: cards[index],
                    ),
                  ),
                ),
                if (cards.length > 3) ...[
                  const SizedBox(height: 7),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.swipe_left_rounded,
                        size: 15,
                        color: Color(0xFF667085),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'K\u00e9o ngang \u0111\u1ec3 xem th\u00eam',
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

}

class _StudentFeatureTile extends StatelessWidget {
  const _StudentFeatureTile({required this.feature});
  final ShapeshifterFeature feature;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => ShapeshifterLauncher().open(context, feature),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F3F5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              _ShapeIcon(feature: feature, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  feature.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdmittedFeatureCard extends StatelessWidget {
  const _AdmittedFeatureCard({required this.feature});
  final ShapeshifterFeature feature;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => ShapeshifterLauncher().open(context, feature),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      feature.primaryColor.withOpacity(0.08),
                      feature.secondaryColor.withOpacity(0.20),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: _ShapeIcon(feature: feature, size: 30),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  feature.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkNavy,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShapeIcon extends StatelessWidget {
  const _ShapeIcon({required this.feature, required this.size});
  final ShapeshifterFeature feature;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = feature.iconUrl?.trim() ?? '';
    if (url.isEmpty) {
      return Icon(Icons.widgets_rounded, size: size, color: feature.primaryColor);
    }
    final isSvg = Uri.tryParse(url)?.path.toLowerCase().endsWith('.svg') ?? false;
    if (isSvg) {
      return SvgPicture.network(
        url,
        width: size,
        height: size,
        placeholderBuilder: (_) =>
            Icon(Icons.widgets_rounded, size: size, color: feature.primaryColor),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorWidget: (_, __, ___) =>
          Icon(Icons.widgets_rounded, size: size, color: feature.primaryColor),
    );
  }
}
