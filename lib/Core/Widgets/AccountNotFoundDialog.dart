import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';
import 'package:tailorapp/Core/Widgets/CommonStyles.dart';

class AccountNotFoundDialog extends StatelessWidget {
  final String mobileNumber;
  final VoidCallback onTryAgain;
  final VoidCallback onNewShopRegister;

  const AccountNotFoundDialog({
    super.key,
    required this.mobileNumber,
    required this.onTryAgain,
    required this.onNewShopRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.brown),
            const SizedBox(height: 10),
            Text(
              Textstring().accountNotFound,
              style: Commonstyles.headerTextblack,
            ),
            const SizedBox(height: 10),
            Text(
              "This phone number +$mobileNumber is not registered. Please contact your shop admin to add your account, or register a new shop if you're a shop owner.",
              textAlign: TextAlign.center,
              style: Commonstyles.accountNotFoundSbbText,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onTryAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(Textstring().tryAgain,
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onNewShopRegister,
              icon: const Icon(Icons.store_mall_directory, color: Colors.brown),
              label: const Text("New Shop Registration",
                  style: TextStyle(color: Colors.brown)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.brown),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
