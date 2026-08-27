import 'package:flutter/material.dart';

/// Ví hóa đơn KTX dựng theo đúng cấu trúc của bản HTML sử dụng 2 PNG:
///
/// - wallet_1.png: thân ví / root anchor.
/// - wallet_3.png: túi da phía trước, bám vào đáy wallet_1.png.
/// - Cụm ticket là Flutter widget, nằm dưới wallet_3.png để mép túi che lên.
///
/// Hai ảnh phải được đặt tại:
///   vnu_noi_tru/assets/images/wallet_1.png
///   vnu_noi_tru/assets/images/wallet_3.png
///
/// Không dùng CustomPainter để vẽ lại thân ví.
class DormitoryLeatherWallet3D extends StatelessWidget {
  static const String _walletRootAsset = 'assets/images/wallet_1.png';
  static const String _walletPocketAsset = 'assets/images/wallet_3.png';
  static const String _assetPackage = 'vnu_noi_tru';

  final String totalAmount;
  final int unpaid;
  final int pending;
  final int paid;

  const DormitoryLeatherWallet3D({
    super.key,
    required this.totalAmount,
    required this.unpaid,
    required this.pending,
    required this.paid,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double screenWidth = MediaQuery.sizeOf(context).width;
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screenWidth;

        // HTML: --wallet-width:min(94vw,410px)
        // Parent Flutter thường đã có padding ngang, nên không trừ thêm 6% lần nữa
        // khi constraint nhỏ hơn viewport. Với màn không có padding, vẫn giữ 94vw.
        final double viewportTarget = screenWidth * 0.94;
        final double walletWidth = _minDouble(
          _minDouble(availableWidth, viewportTarget),
          410.0,
        );

        // HTML .crop-1: visible bbox 1282 x 935.
        final double walletHeight = walletWidth * (935.0 / 1282.0);

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: walletWidth,
            height: walletHeight,
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: <Widget>[
                  // 1) ROOT: wallet_1.png.
                  Positioned.fill(
                    child: _CroppedWalletRootImage(
                      width: walletWidth,
                      height: walletHeight,
                    ),
                  ),

                  // 2) Text chỉ ở nửa trên của wallet_1.png.
                  Positioned(
                    left: walletWidth * 0.082,
                    top: walletHeight * 0.085,
                    width: walletWidth * 0.68,
                    child: _WalletInfo(
                      walletWidth: walletWidth,
                      totalAmount: totalAmount,
                    ),
                  ),

                  // 3) NFC giống HTML: right 13%, top 14.5%.
                  Positioned(
                    right: walletWidth * 0.13,
                    top: walletHeight * 0.145,
                    child: IgnorePointer(
                      child: Transform.rotate(
                        angle: 1.5707963267948966,
                        child: Text(
                          ')))',
                          style: TextStyle(
                            color: const Color(0xFFE5FFEF).withOpacity(0.50),
                            fontSize: _clampDouble(
                              walletWidth * 0.0635,
                              20.0,
                              26.0,
                            ),
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4) wallet_3.png là child của wallet_1.png và bám đáy.
                  _PocketAnchor(
                    walletWidth: walletWidth,
                    walletHeight: walletHeight,
                    unpaid: unpaid,
                    pending: pending,
                    paid: paid,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CroppedWalletRootImage extends StatelessWidget {
  final double width;
  final double height;

  const _CroppedWalletRootImage({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // HTML crop-1:
    // width: 112.949%; left: -7.722%; top: -7.807%.
    final double imageWidth = width * 1.12949;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: <Widget>[
        Positioned(
          left: width * -0.07722,
          top: height * -0.07807,
          width: imageWidth,
          child: Image.asset(
            DormitoryLeatherWallet3D._walletRootAsset,
            package: DormitoryLeatherWallet3D._assetPackage,
            fit: BoxFit.fitWidth,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            errorBuilder: _assetErrorBuilder(
              'Thiếu assets/images/wallet_1.png',
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletInfo extends StatelessWidget {
  final double walletWidth;
  final String totalAmount;

  const _WalletInfo({
    required this.walletWidth,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final double titleSize = _clampDouble(
      walletWidth * 0.039,
      13.0,
      16.0,
    );
    final double subSize = _clampDouble(
      walletWidth * 0.029,
      10.0,
      12.0,
    );
    final double amountSize = _clampDouble(
      walletWidth * 0.117,
      36.0,
      48.0,
    );

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              Color(0x2E035C34),
              Color(0x14035C34),
              Color(0x00035C34),
            ],
            stops: <double>[0.0, 0.72, 1.0],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 9,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 17,
                      color: Color(0xFF078C4D),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Hóa đơn & thanh toán',
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: walletWidth * 0.021),
              Text(
                'Tổng còn phải thanh toán',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: subSize,
                  color: const Color(0xFFE9FFF2).withOpacity(0.82),
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                ),
              ),
              SizedBox(height: walletWidth * 0.004),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: totalAmount,
                        style: TextStyle(
                          fontSize: amountSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.8,
                        ),
                      ),
                      TextSpan(
                        text: ' đ',
                        style: TextStyle(
                          fontSize: amountSize * 0.48,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PocketAnchor extends StatelessWidget {
  final double walletWidth;
  final double walletHeight;
  final int unpaid;
  final int pending;
  final int paid;

  const _PocketAnchor({
    required this.walletWidth,
    required this.walletHeight,
    required this.unpaid,
    required this.pending,
    required this.paid,
  });

  @override
  Widget build(BuildContext context) {
    // HTML:
    // --pocket-width: 99%;
    // --pocket-bottom: -1.5%;
    final double pocketWidth = walletWidth * 0.99;
    final double pocketHeight = pocketWidth * (538.0 / 1265.0);

    return Positioned(
      left: (walletWidth - pocketWidth) / 2,
      bottom: walletHeight * -0.015,
      width: pocketWidth,
      height: pocketHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          // Ticket phải render trước wallet_3 để phần da phủ lên sau.
          _TicketAnchor(
            pocketWidth: pocketWidth,
            pocketHeight: pocketHeight,
            unpaid: unpaid,
            pending: pending,
            paid: paid,
          ),

          // 3.png phủ ngoài cùng, vùng giữa transparent cho ticket hiện qua.
          Positioned.fill(
            child: _CroppedPocketImage(
              width: pocketWidth,
              height: pocketHeight,
            ),
          ),
        ],
      ),
    );
  }
}

class _CroppedPocketImage extends StatelessWidget {
  final double width;
  final double height;

  const _CroppedPocketImage({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // HTML crop-3:
    // width: 114.466%; left: -7.194%; top: -88.476%.
    final double imageWidth = width * 1.14466;

    return ClipRect(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: <Widget>[
          Positioned(
            left: width * -0.07194,
            top: height * -0.88476,
            width: imageWidth,
            child: Image.asset(
              DormitoryLeatherWallet3D._walletPocketAsset,
              package: DormitoryLeatherWallet3D._assetPackage,
              fit: BoxFit.fitWidth,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              errorBuilder: _assetErrorBuilder(
                'Thiếu assets/images/wallet_3.png',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketAnchor extends StatelessWidget {
  final double pocketWidth;
  final double pocketHeight;
  final int unpaid;
  final int pending;
  final int paid;

  const _TicketAnchor({
    required this.pocketWidth,
    required this.pocketHeight,
    required this.unpaid,
    required this.pending,
    required this.paid,
  });

  @override
  Widget build(BuildContext context) {
    // HTML:
    // --ticket-width: 88%; --ticket-height: 75%; --ticket-bottom: 7.5%.
    final double ticketWidth = pocketWidth * 0.88;
    final double ticketHeight = pocketHeight * 0.75;
    final double left = (pocketWidth - ticketWidth) / 2;
    final double bottom = pocketHeight * 0.075;

    return Positioned(
      left: left,
      bottom: bottom,
      width: ticketWidth,
      height: ticketHeight,
      child: _TicketRow(
        width: ticketWidth,
        height: ticketHeight,
        unpaid: unpaid,
        pending: pending,
        paid: paid,
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final double width;
  final double height;
  final int unpaid;
  final int pending;
  final int paid;

  const _TicketRow({
    required this.width,
    required this.height,
    required this.unpaid,
    required this.pending,
    required this.paid,
  });

  @override
  Widget build(BuildContext context) {
    final double cutSize = _clampDouble(width * 0.052, 12.0, 18.0);
    final double cutRadius = cutSize / 2;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color(0x21254B33),
                  blurRadius: 8,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _TicketCell(
                    side: _TicketSide.left,
                    type: _TicketType.unpaid,
                    value: unpaid,
                    label: 'Cần trả',
                    showSeparator: true,
                  ),
                ),
                Expanded(
                  child: _TicketCell(
                    side: _TicketSide.middle,
                    type: _TicketType.pending,
                    value: pending,
                    label: 'Chờ xác nhận',
                    showSeparator: true,
                  ),
                ),
                Expanded(
                  child: _TicketCell(
                    side: _TicketSide.right,
                    type: _TicketType.paid,
                    value: paid,
                    label: 'Đã trả',
                    showSeparator: false,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Khuyết tròn giống HTML ở 1/3 và 2/3, trên + dưới.
        Positioned(
          left: width / 3 - cutRadius,
          top: -cutRadius,
          child: _TicketCut(size: cutSize),
        ),
        Positioned(
          left: width * 2 / 3 - cutRadius,
          top: -cutRadius,
          child: _TicketCut(size: cutSize),
        ),
        Positioned(
          left: width / 3 - cutRadius,
          bottom: -cutRadius,
          child: _TicketCut(size: cutSize),
        ),
        Positioned(
          left: width * 2 / 3 - cutRadius,
          bottom: -cutRadius,
          child: _TicketCut(size: cutSize),
        ),
      ],
    );
  }
}

enum _TicketType { unpaid, pending, paid }

enum _TicketSide { left, middle, right }

class _TicketCell extends StatelessWidget {
  final _TicketSide side;
  final _TicketType type;
  final int value;
  final String label;
  final bool showSeparator;

  const _TicketCell({
    required this.side,
    required this.type,
    required this.value,
    required this.label,
    required this.showSeparator,
  });

  @override
  Widget build(BuildContext context) {
    final Color valueColor;
    final Color iconBackground;
    final IconData icon;
    final List<Color> backgroundColors;

    switch (type) {
      case _TicketType.unpaid:
        valueColor = const Color(0xFF1977D3);
        iconBackground = const Color(0xFFEAF2FF);
        icon = Icons.receipt_long_rounded;
        backgroundColors = const <Color>[
          Color(0xFFFBFEFE),
          Color(0xFFEDF8F4),
        ];
        break;
      case _TicketType.pending:
        valueColor = const Color(0xFFE99B08);
        iconBackground = const Color(0xFFFFF2D4);
        icon = Icons.hourglass_bottom_rounded;
        backgroundColors = const <Color>[
          Color(0xFFFFFDF9),
          Color(0xFFFFF4DF),
        ];
        break;
      case _TicketType.paid:
        valueColor = const Color(0xFF078F5A);
        iconBackground = const Color(0xFFE6F7EF);
        icon = Icons.verified_rounded;
        backgroundColors = const <Color>[
          Color(0xFFFBFEFE),
          Color(0xFFEDF8F4),
        ];
        break;
    }

    final BorderRadius radius = switch (side) {
      _TicketSide.left => const BorderRadius.horizontal(
          left: Radius.circular(18),
        ),
      _TicketSide.middle => BorderRadius.zero,
      _TicketSide.right => const BorderRadius.horizontal(
          right: Radius.circular(18),
        ),
    };

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cellWidth = constraints.maxWidth;
        final double cellHeight = constraints.maxHeight;
        final double iconSize = _clampDouble(cellWidth * 0.22, 20.0, 24.0);
        final double valueSize = _clampDouble(cellWidth * 0.24, 21.0, 29.0);
        final double labelSize = _clampDouble(cellWidth * 0.098, 8.5, 11.0);

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: backgroundColors,
                  ),
                  border: Border(
                    top: const BorderSide(color: Color(0x9EA9BEB4), width: 1),
                    bottom: const BorderSide(
                      color: Color(0x9EA9BEB4),
                      width: 1,
                    ),
                    left: side == _TicketSide.left
                        ? const BorderSide(
                            color: Color(0x9EA9BEB4),
                            width: 1,
                          )
                        : BorderSide.none,
                    right: side == _TicketSide.right
                        ? const BorderSide(
                            color: Color(0x9EA9BEB4),
                            width: 1,
                          )
                        : BorderSide.none,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: RadialGradient(
                      center: switch (side) {
                        _TicketSide.left => const Alignment(-0.60, -1.0),
                        _TicketSide.middle => const Alignment(0.0, -1.0),
                        _TicketSide.right => const Alignment(0.60, -1.0),
                      },
                      radius: 0.95,
                      colors: const <Color>[
                        Color(0xF2FFFFFF),
                        Color(0x00FFFFFF),
                      ],
                      stops: const <double>[0.0, 0.58],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  cellWidth * 0.13,
                  cellHeight * 0.08,
                  cellWidth * 0.08,
                  cellHeight * 0.07,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        icon,
                        color: valueColor,
                        size: iconSize * 0.60,
                      ),
                    ),
                    SizedBox(height: cellHeight * 0.035),
                    Text(
                      '$value',
                      maxLines: 1,
                      style: TextStyle(
                        color: valueColor,
                        fontSize: valueSize,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: cellHeight * 0.025),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          color: const Color(0xFF343C38),
                          fontSize: labelSize,
                          fontWeight: FontWeight.w600,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showSeparator)
              Positioned(
                right: -0.75,
                top: cellHeight * 0.12,
                bottom: cellHeight * 0.12,
                width: 1.5,
                child: const _DashedVerticalDivider(),
              ),
          ],
        );
      },
    );
  }
}

class _DashedVerticalDivider extends StatelessWidget {
  const _DashedVerticalDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double dashHeight = 4;
        const double gap = 3;
        final int count = (constraints.maxHeight / (dashHeight + gap)).floor();

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List<Widget>.generate(
            count < 1 ? 1 : count,
            (int index) => Container(
              width: 1.5,
              height: dashHeight,
              color: const Color(0xB8738F7F),
            ),
          ),
        );
      },
    );
  }
}

class _TicketCut extends StatelessWidget {
  final double size;

  const _TicketCut({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF07894D),
      ),
    );
  }
}

ImageErrorWidgetBuilder _assetErrorBuilder(String message) {
  return (
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Container(
      color: const Color(0xFFFDECEC),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFB42318),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  };
}

double _minDouble(double a, double b) => a < b ? a : b;

double _clampDouble(double value, double min, double max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}
