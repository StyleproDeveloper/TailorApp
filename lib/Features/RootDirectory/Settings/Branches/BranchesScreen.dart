import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Fonts.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Widgets/CommonHeader.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/Branches/AddBranchModal.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/Shop/ShopDetailsScreen.dart';
import '../../../../Core/Services/Urls.dart';
import '../../../../Core/Widgets/CustomSnakBar.dart';
import '../../../../GlobalVariables.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  List<Map<String, dynamic>> _branches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBranchData();
  }

  Future<void> fetchBranchData() async {
  int? id = GlobalVariables.shopIdGet;
  if (id == null) {
    Future.microtask(() => CustomSnackbar.showSnackbar(
          context,
          "Shop ID is missing",
          duration: Duration(seconds: 2),
        ));
    return;
  }

  try {
    final String requestUrl = "${Urls.shopName}/$id";
    final response = await ApiService().get(requestUrl, context);

    print('Branch API Response: $response');

    if (response.data != null) {
      final data = response.data;
      
      // Handle both direct data and nested data structure
      final shopData = data is Map ? (data['data'] ?? data) : data;

      setState(() {
        _branches = [
          {
            'branch_id': shopData['branch_id']?.toString() ?? shopData['branchId']?.toString() ?? 'N/A',
            'shopName': shopData['shopName']?.toString() ?? shopData['yourName']?.toString() ?? 'Unnamed Shop',
            'mobile': shopData['mobile']?.toString() ?? '',
          }
        ];
        _isLoading = false;
      });
    } else {
      setState(() {
        _branches = [];
        _isLoading = false;
      });
    }
  } catch (e) {
    setState(() => _isLoading = false);
    CustomSnackbar.showSnackbar(context, e.toString(),
        duration: Duration(seconds: 2));
  }
}

  void _showAddBranchModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Addbranchmodal(
        onClose: () {
          Navigator.of(context).pop();
          fetchBranchData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Commonheader(
        title: 'Shops & Branches',
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () {
                _showAddBranchModal(context);
              },
              icon: const Icon(Icons.add, color: ColorPalatte.primary),
              label: const Text('Add Branch',
                  style: TextStyle(color: ColorPalatte.primary)),
            ),
          ),
        ],
      ),
      backgroundColor: ColorPalatte.white,
      body: Column(
        children: [
          // Shop Details Section
          Container(
            margin: EdgeInsets.all(12.0),
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: ColorPalatte.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: ColorPalatte.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Shop Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: Fonts.Bold,
                        color: ColorPalatte.primary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: ColorPalatte.primary),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShopDetailsScreen(
                              shopData: _branches.isNotEmpty ? _branches[0] : null,
                            ),
                          ),
                        ).then((_) => fetchBranchData());
                      },
                    ),
                  ],
                ),
                if (_branches.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    _branches[0]['shopName'] ?? 'Shop Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: Fonts.Medium,
                      color: ColorPalatte.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Branch ID: ${_branches[0]['branch_id'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: Fonts.Regular,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Phone: ${_branches[0]['mobile'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: Fonts.Regular,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search branches...",
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          SizedBox(height: 8),

          // Branches Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Branches',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: Fonts.Bold,
                    color: ColorPalatte.black,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddBranchModal(context),
                  icon: Icon(Icons.add, color: ColorPalatte.primary, size: 20),
                  label: Text(
                    'Add Branch',
                    style: TextStyle(
                      color: ColorPalatte.primary,
                      fontFamily: Fonts.Medium,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _branches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No branches available",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontFamily: Fonts.Regular,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        itemCount: _branches.length,
                        separatorBuilder: (context, index) =>
                            Divider(color: Colors.grey.shade300, thickness: 1),
                        itemBuilder: (context, index) {
                          final branch = _branches[index];
                          final shopName = branch['shopName']?.toString() ?? '';
                          final initial = shopName.isNotEmpty ? shopName[0].toUpperCase() : '?';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              child: Text(
                                initial,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: ColorPalatte.primary),
                              ),
                            ),
                            title: Text(
                              branch['shopName']?.toString() ?? 'Unnamed Branch',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: Fonts.Medium,
                              ),
                            ),
                            subtitle: Text(
                              'Branch ID: ${branch['branch_id']?.toString() ?? 'N/A'} | Phone: ${branch['mobile']?.toString() ?? 'N/A'}',
                              style: TextStyle(
                                fontFamily: Fonts.Regular,
                                color: Colors.grey[600],
                              ),
                            ),
                            onTap: () {
                              // Navigate to shop details when tapping on the main shop
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShopDetailsScreen(
                                    shopData: branch,
                                  ),
                                ),
                              ).then((_) => fetchBranchData());
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}