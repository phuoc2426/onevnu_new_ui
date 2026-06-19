import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VcorePahtControllerV2 extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  void changePage(int page) {
    currentPage.value = page;
    pageController.jumpToPage(page);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
