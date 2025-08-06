import 'package:shared_preferences/shared_preferences.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';

class GlobalVariables {
  static int? shopIdGet;
  static int? branchId;
  static int? userId;

  static Future<void> loadShopId() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    shopIdGet = pref.getInt(Textstring().shopId);
    branchId = pref.getInt(Textstring().branchId);
    userId = pref.getInt(Textstring().userId);
  }
}