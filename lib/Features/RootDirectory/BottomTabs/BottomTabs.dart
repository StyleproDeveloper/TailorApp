import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Images.dart';
import 'package:tailorapp/Features/RootDirectory/BottomTabs/BottomStyle.dart';
import 'package:tailorapp/Features/RootDirectory/Orders/OrderScreen.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/SettingScreen.dart';
import 'package:tailorapp/Features/RootDirectory/customer/CustomerScreen.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    OrderScreen(),
    Customerscreen(),
    Center(child: Text('Gallery Screen', style: TextStyle(fontSize: 18))),
    Center(child: Text('Reports Screen', style: TextStyle(fontSize: 18))),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalatte.white,
      body: _pages[_currentIndex],
      // ---------bottom bar---------
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: ColorPalatte.white,
          border: Border(
            top: BorderSide(color: ColorPalatte.borderGray, width: 0.8),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: ColorPalatte.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          backgroundColor: ColorPalatte.white,
          selectedFontSize: 12,
          selectedLabelStyle: Bottomstyle.bottomText,
          unselectedFontSize: 12,
          unselectedLabelStyle: Bottomstyle.bottomText,
          items: [
            BottomNavigationBarItem(
              icon: SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(Images.orderIcon,
                    color: _currentIndex == 0
                        ? ColorPalatte.primary
                        : Colors.grey),
              ),
              label: "Order",
            ),
            BottomNavigationBarItem(
              icon: SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(
                  Images.customerIcon,
                  color:
                      _currentIndex == 1 ? ColorPalatte.primary : Colors.grey,
                ),
              ),
              label: "Customer",
            ),
            BottomNavigationBarItem(
              icon: SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(
                  Images.gallaryIcon,
                  color:
                      _currentIndex == 2 ? ColorPalatte.primary : Colors.grey,
                ),
              ),
              label: "Gallery",
            ),
            BottomNavigationBarItem(
              icon: SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(
                  Images.reportIcon,
                  color:
                      _currentIndex == 3 ? ColorPalatte.primary : Colors.grey,
                ),
              ),
              label: "Report",
            ),
            BottomNavigationBarItem(
              icon: SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(
                  Images.settingsIcon,
                  color:
                      _currentIndex == 4 ? ColorPalatte.primary : Colors.grey,
                ),
              ),
              label: "Settings",
            ),
          ],
        ),
      ),
    );
  }
}
