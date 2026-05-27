import 'package:flutter/material.dart';

class ErrorRefreshWidget extends StatelessWidget {
  final String? message;
  final double padding;
  final Function()? refreshAction;
  const ErrorRefreshWidget(
      {Key? key, required this.message, this.refreshAction, this.padding = 60})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(left: padding, right: padding),
            child: Text(
              message ?? '',
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
              onPressed: (() {
                if (refreshAction != null) refreshAction!();
              }),
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.black,
              ))
        ],
      ),
    );
  }
}
