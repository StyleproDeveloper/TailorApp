import 'package:flutter/cupertino.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';

class Requiredalert {
  static void showRequiredFieldsAlert(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          Textstring().incompleteForm,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(Textstring().requiredFields),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: ColorPalatte.primary,
            ),
            child: CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                Textstring().ok,
                style: TextStyle(color: ColorPalatte.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
