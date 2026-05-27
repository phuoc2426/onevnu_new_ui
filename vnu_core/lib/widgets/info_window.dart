import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vnu_core/common/log.dart';
import 'package:vnu_core/models/model.dart';
import 'package:vnu_core/screens/vcore_maps_direction_screen.dart';
import 'package:vnu_core/themes/app_theme.dart';

class InfoWindowWidget extends StatelessWidget {
  final DiaDiemBanDoSo diaDiemBanDoSo;
  const InfoWindowWidget({super.key, required this.diaDiemBanDoSo});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: Color(0xFF3E3D3D).withOpacity(.2),
                      spreadRadius: 2,
                      blurRadius: 5),
                ],
              ),
              width: double.infinity,
              height: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        diaDiemBanDoSo.tieuDe ?? '',
                        style: AppTheme.body2.copyWith(
                          color: Colors.black,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        logInfo('directions');
                        Get.to(() => VcoreMapsDirectionScreen(
                            diaDiemBanDoSo: diaDiemBanDoSo));
                      },
                      child: const Icon(
                        Icons.directions,
                        color: AppTheme.colorMain,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          // Triangle.isosceles(
          //   edge: Edge.BOTTOM,
          //   child: Container(
          //     color: Colors.blue,
          //     width: 20.0,
          //     height: 10.0,
          //   ),
          // ),
        ],
      ),
    );
  }
}
