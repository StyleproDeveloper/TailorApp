import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Fonts.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Widgets/CommonHeader.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/User/AddUserModal.dart';
import '../../../../Core/Widgets/CustomLoader.dart';
import '../../../../Core/Widgets/CustomSnakBar.dart';

class Userscreen extends StatefulWidget {
  const Userscreen({super.key});

  @override
  State<Userscreen> createState() => _UserscreenState();
}

class _UserscreenState extends State<Userscreen> {
  final List<Map<String, dynamic>> _users = [];
  int pageNumber = 1;
  final int pageSize = 10;
  bool hasMoreData = true;
  bool loading = false;
  bool isFirstLoad = true;
  final ScrollController _scrollController = ScrollController();
  TextEditingController searchKeywordController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchUserData();
      _scrollController.addListener(_scrollListener);
      searchKeywordController.addListener(_onSearchChanged);
    });
  }

  void _onSearchChanged() {
    if (searchKeywordController.text.isNotEmpty) {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _users.clear();
          pageNumber = 1;
          hasMoreData = true;
        });
        fetchUserData();
      });
    } else if (searchKeywordController.text.isEmpty) {
      setState(() {
        _users.clear();
        pageNumber = 1;
        hasMoreData = true;
      });
      fetchUserData();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    searchKeywordController.dispose();
    super.dispose();
  }

  void fetchUserData() async {
    if (loading || !hasMoreData) return;
    setState(() => loading = true);
    try {
      if (isFirstLoad) {
        Future.delayed(Duration.zero, () => showLoader(context));
      }
      final String requestUrl =
          "${Urls.addUsers}?pageNumber=$pageNumber&pageSize=$pageSize&searchKeyword=${searchKeywordController.text}";
      final response = await ApiService().get(requestUrl, context);
      if (isFirstLoad) {
        Future.delayed(Duration.zero, () => hideLoader(context));
      }
      final responseData = jsonDecode(response.toString());
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        List<dynamic> usersData = responseData['data'];
        setState(() {
          _users.addAll(usersData.map((user) {
            return {
              'name': user['name'] ?? 'Unknown',
              'roleId': user['roleId'] ?? 'No Role',
              'phone': user['mobile'] ?? 'No Phone',
              'userId': user['userId']?.toString() ?? 'N/A',
              'shopId': user['shopId']?.toString() ?? 'N/A',
              'email': user['email']?.toString() ?? '',
            };
          }).toList());
          if (usersData.length < pageSize) {
            hasMoreData = false;
          } else {
            pageNumber++;
          }
        });
      } else {
        throw Exception("Invalid response format");
      }
    } catch (e) {
      hideLoader(context);
      CustomSnackbar.showSnackbar(
        context,
        'Failed to load users: ${e.toString()}',
        duration: const Duration(seconds: 2),
      );
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
    if (!loading &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50) {
      fetchUserData();
    }
  }

  void _showAddUserModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddUserModal(
        sumbit: () => {
          setState(() {
            _users.clear();
            pageNumber = 1;
            hasMoreData = true;
          }),
          fetchUserData()
        },
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEditUserModal(BuildContext context, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddUserModal(
        userData: userData,
        onClose: () => Navigator.of(context).pop(),
        sumbit: () => {
          setState(() {
            _users.clear();
            pageNumber = 1;
            hasMoreData = true;
          }),
          fetchUserData()
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Commonheader(
        title: 'Users',
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () {
                _showAddUserModal(context);
              },
              icon: const Icon(Icons.add, color: ColorPalatte.primary),
              label: const Text('Add User',
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
                hintText: "Search users...",
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
            child: _users.isEmpty
                ? const Center(child: Text('No users found'))
                : ListView.separated(
                    controller: _scrollController,
                    itemCount: _users.length + (hasMoreData ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        Divider(color: Colors.grey.shade300, thickness: 1),
                    itemBuilder: (context, index) {
                      if (index == _users.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  color: ColorPalatte.primary,
                                  strokeWidth: 2,
                                )),
                          ),
                        );
                      }
                      final user = _users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          child: Text(
                            user['name']![0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: Fonts.Regular,
                              color: ColorPalatte.primary,
                            ),
                          ),
                        ),
                        title: Text(user['name']!,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'Role Id: ${user['roleId']}  |  ${user['phone']}'),
                        trailing: Text(
                          'Shop ID: ${user['shopId']}',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                        onTap: () {
                          _showEditUserModal(context, user);
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
