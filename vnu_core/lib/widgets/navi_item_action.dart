import 'package:flutter/material.dart';
import 'package:vnu_core/themes/app_theme.dart';

class NaviItemAction extends StatelessWidget {
  final Widget icon;
  final int? count;
  final Function()? action;
  const NaviItemAction({Key? key, required this.icon, this.count, this.action})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    int countInt = (count ?? 0);
    return SizedBox(
        width: 44,
        child: Stack(
          children: [
            Center(
              child: icon,
            ),
            Visibility(
              visible: (count ?? 0) > 0,
              child: Positioned(
                  right: countInt > 9 ? 0 : 3,
                  top: countInt > 9 ? 6 : 4,
                  child: Container(
                      width: countInt > 9 ? 28 : 20,
                      height: countInt > 9 ? 18 : 20,
                      decoration: const BoxDecoration(
                          color: Colors.red,
                          // border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.all(Radius.circular(14))),
                      child: Center(
                        child: Text(
                          countInt < 100 ? countInt.toString() : '99+',
                          textAlign: TextAlign.center,
                          style: AppTheme.body2.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.normal,
                              color: Colors.white),
                        ),
                      ))),
            )
          ],
        ));
  }
}
