import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/buttons_widget.dart';
import '../common/utils.dart';
import '../themes/app_theme.dart';
import 'container_dissmis.dart';

class InputTextPopupWidget extends StatefulWidget {
  final String? title;
  final String? buttonTitleSubmit;
  final Function(String content)? submitAction;
  const InputTextPopupWidget(
      {Key? key, this.title, this.buttonTitleSubmit, this.submitAction})
      : super(key: key);

  @override
  State<InputTextPopupWidget> createState() => _InputTextPopupWidgetState();
}

class _InputTextPopupWidgetState extends State<InputTextPopupWidget> {
  final TextEditingController _textEditingController = TextEditingController();
  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ContainerAutoDissmis(
        child: Center(
          child: Container(
            color: Colors.white,
            margin: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 45,
                  color: AppTheme.backgroundBlueColor,
                  padding: const EdgeInsets.only(left: 15, right: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title ?? '',
                          style: AppTheme.body1.copyWith(color: Colors.white),
                        ),
                      ),
                      svgAction('assets/images/ic_close.svg',
                          color: Colors.white, width: 20, action: () {
                        Get.back();
                      })
                    ],
                  ),
                ),

                //Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: _textEditingController,
                    style: AppTheme.body2,
                    autofocus: true,
                    maxLines: 5,
                    decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(8),
                        border: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Color(0xFFC4C4C4)),
                            borderRadius: BorderRadius.circular(10))),
                  ),
                ),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BlueButton(
                      title: widget.buttonTitleSubmit ?? 'Gửi',
                      action: () {
                        Get.back();
                        if (widget.submitAction != null) {
                          widget.submitAction!(_textEditingController.text);
                        }
                      },
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    WhiteButton(
                      title: 'Đóng',
                      action: () {
                        Get.back();
                      },
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
