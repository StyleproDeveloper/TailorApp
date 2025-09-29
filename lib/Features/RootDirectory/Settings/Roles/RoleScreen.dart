import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/Roles/AddRoleModal.dart';
import '../../../../Core/Constants/ColorPalatte.dart';
import '../../../../Core/Services/Services.dart';
import '../../../../Core/Services/Urls.dart';
import '../../../../Core/Widgets/CommonHeader.dart';
import '../../../../Core/Widgets/CustomLoader.dart';
import '../../../../Core/Widgets/CustomSnakBar.dart';
import '../../../../GlobalVariables.dart';

class Rolescreen extends StatefulWidget {
  const Rolescreen({super.key});

  @override
  State<Rolescreen> createState() => _RolescreenState();
}

class _RolescreenState extends State<Rolescreen> {
  List<Map<String, dynamic>> roles = [];
  List<Map<String, dynamic>> rolesAll = [];
  int pageNumber = 1;
  final int pageSize = 10;
  bool loading = false;
  bool isFirstLoad = true;
  final ScrollController _scrollController = ScrollController();
  TextEditingController searchKeywordController = TextEditingController();
  Timer? _debounce;
  bool hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _fetchRoleData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRoleData();
      _scrollController.addListener(_scrollListener);
      searchKeywordController.addListener(_onSearchChanged);
    });
  }

  void _onSearchChanged() {
    if (searchKeywordController.text.isNotEmpty) {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        setState(() {
          roles.clear();
          rolesAll.clear();
          pageNumber = 1;
          hasMoreData = true;
        });
        _fetchRoleData();
      });
    } else if (searchKeywordController.text.isEmpty) {
      setState(() {
        roles.clear();
        rolesAll.clear();
        pageNumber = 1;
        hasMoreData = true;
      });
      _fetchRoleData();
    }
  }

  void _fetchRoleData() async {
    if (loading | !hasMoreData) return;
    setState(() => loading = true);

    int? id = GlobalVariables.shopIdGet;
    if (id == null) {
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            "Shop ID is missing",
            duration: Duration(seconds: 2),
          ));
      return;
    }

    final String requestUrl =
        "${Urls.addRole}/$id?pageNumber=$pageNumber&pageSize=$pageSize&searchKeyword=${searchKeywordController.text}";

    try {
      if (isFirstLoad) {
        Future.delayed(Duration.zero, () => showLoader(context));
      }

      final response = await ApiService().get(requestUrl, context);

      if (!mounted) return;

      if (isFirstLoad) {
        Future.delayed(Duration.zero, () => hideLoader(context));
      }
      if (response.data is Map<String, dynamic>) {
        List<dynamic> roleData = response.data['data'];
        if (roleData.isNotEmpty) {
          setState(() {
            rolesAll.addAll(
                roleData.map((role) => Map<String, dynamic>.from(role)));
            roles.addAll(roleData.map((role) => {
                  'name': role['name'] ?? 'Unknown role',
                  'roleId': role['roleId'] ?? 'N/A',
                }));
            pageNumber++;
          });
        }
      } else {
        Future.microtask(() => CustomSnackbar.showSnackbar(
              context,
              'No roles found',
              duration: const Duration(seconds: 1),
            ));
      }
    } catch (e) {
      if (!mounted) return;
      Future.delayed(Duration.zero, () => hideLoader(context));
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            'Failed to load roles',
            duration: Duration(seconds: 2),
          ));
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          isFirstLoad = false;
        });
      }
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      _fetchRoleData();
    }
  }

  void _showAddRoleModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddRoleModal(
        onClose: () => Navigator.of(context).pop(),
        submit: () => {
          setState(() {
            roles.clear();
            rolesAll.clear();
            pageNumber = 1;
          }),
          _fetchRoleData()
        },
      ),
    );
  }

  void _showEditUserModal(BuildContext context, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddRoleModal(
        userData: userData,
        onClose: () {
          Navigator.of(context).pop();
        },
        submit: () => {
          setState(() {
            roles.clear();
            rolesAll.clear();
            pageNumber = 1;
          }),
          _fetchRoleData()
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: Commonheader(
          title: 'Role',
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: TextButton.icon(
                onPressed: () {
                  _showAddRoleModal(context);
                },
                icon: const Icon(Icons.add, color: ColorPalatte.primary),
                label: const Text('Add Role',
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
                controller: searchKeywordController,
                decoration: InputDecoration(
                  hintText: "Search role...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _onSearchChanged(),
              ),
            ),
            Expanded(
              child: roles.isEmpty
                  ? Center(child: Text('No roles found'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16.0),
                      itemCount: roles.length + (loading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == roles.length) {
                          return Center(
                            child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  color: ColorPalatte.primary,
                                  strokeWidth: 2,
                                )),
                          );
                        }

                        final role = roles[index];

                        return Card(
                          margin: EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: ColorPalatte.primary,
                              child: Text(
                                role['name']![0].toUpperCase(),
                                style: TextStyle(color: ColorPalatte.white),
                              ),
                            ),
                            title: Text(role['name'] ?? 'Unknown',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle:
                                Text("Role ID: ${role['roleId'] ?? 'N/A'}"),
                            onTap: () {
                              _showEditUserModal(context, rolesAll[index]);
                            },
                          ),
                        );
                      },
                    ),
            )
          ],
        ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
