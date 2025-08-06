import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Widgets/CommonHeader.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/Branches/AddBranchModal.dart';
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

      setState(() {
        _branches = [
          {
            'branch_id': data['branch_id'].toString(),
            'shopName': data['shopName'] ?? '',
            'mobile': data['mobile'] ?? '',
          }
        ];
        _isLoading = false;
      });
    } else {
      throw Exception("Invalid API response");
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
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search shops or branches...",
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

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _branches.isEmpty
                    ? Center(child: Text("No branches available"))
                    : ListView.separated(
                        itemCount: _branches.length,
                        separatorBuilder: (context, index) =>
                            Divider(color: Colors.grey.shade300, thickness: 1),
                        itemBuilder: (context, index) {
                          final branch = _branches[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              child: Text(
                                branch['shopName'][0].toUpperCase(),
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: ColorPalatte.primary),
                              ),
                            ),
                            title: Text(branch['shopName'],
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                'Branch ID: ${branch['branch_id']} | Phone: ${branch['mobile']}'),
                            onTap: () {},
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}