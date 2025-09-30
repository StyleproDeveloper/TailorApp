import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Widgets/CustomLoader.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/Dress/AddDressModal.dart';
import '../../../../Core/Constants/ColorPalatte.dart';
import '../../../../Core/Widgets/CommonHeader.dart';
import '../../../../Core/Widgets/CustomSnakBar.dart';
import '../../../../Core/Widgets/DressIcons.dart';
import '../../../../GlobalVariables.dart';

class DressScreen extends StatefulWidget {
  const DressScreen({super.key});

  @override
  State<DressScreen> createState() => _DressScreenState();
}

class _DressScreenState extends State<DressScreen> {
  List<Map<String, dynamic>> dresses = [];
  final ScrollController _scrollController = ScrollController();
  int pageNumber = 1;
  final int pageSize = 10;
  bool hasMoreData = true;
  bool isLoading = false;
  TextEditingController searchKeywordController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    searchKeywordController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchDressData();
    });
  }

  void _scrollListener() {
    if (!isLoading &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50) {
      fetchDressData();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        pageNumber = 1;
        hasMoreData = true;
        // Don't clear dresses immediately to prevent blank screen
      });
      fetchDressData();
    });
  }

  Future<void> fetchDressData() async {
    if (isLoading || !hasMoreData) return;
    int? id = GlobalVariables.shopIdGet;
    if (id == null) {
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            "Shop ID is missing",
            duration: Duration(seconds: 2),
          ));
      return;
    }
    setState(() {
      isLoading = true;
    });
    if (pageNumber == 1) {
      Future.delayed(Duration.zero, () => showLoader(context));
    }
    try {
      final requestUrl =
          "${Urls.addDress}/$id?pageNumber=$pageNumber&pageSize=$pageSize&searchKeyword=${searchKeywordController.text}";
      final response = await ApiService().get(requestUrl, context);

      if (pageNumber == 1) {
        Future.delayed(Duration.zero, () => hideLoader(context));
      }

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        List<dynamic> newDresses = response.data['data'];
        setState(() {
          // Clear dresses only on first page (search or initial load)
          if (pageNumber == 1) {
            dresses.clear();
          }
          dresses.addAll(List<Map<String, dynamic>>.from(newDresses));
          if (newDresses.length < pageSize) {
            hasMoreData = false;
          } else {
            pageNumber++;
          }
        });
      } else {
        // Only show message if it's the first page and no data
        if (pageNumber == 1) {
          setState(() {
            dresses.clear();
          });
          CustomSnackbar.showSnackbar(
            context,
            "No dress data found",
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      if (pageNumber == 1) {
        Future.delayed(Duration.zero, () => hideLoader(context));
      }
      CustomSnackbar.showSnackbar(
        context,
        "Failed to fetch data: ${e.toString()}",
        duration: const Duration(seconds: 2),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchKeywordController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _resetAndFetch() {
    setState(() {
      dresses.clear();
      pageNumber = 1;
      hasMoreData = true;
    });
    fetchDressData();
  }

  void _showAddDressModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddDressModal(
        onClose: () {
          Navigator.of(context).pop();
          _resetAndFetch();
        },
      ),
    );
  }

  void _showEditDressModal(
      BuildContext context, int? dressDataId, String? dressName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddDressModal(
        dressDataId: dressDataId,
        dressName: dressName,
        onClose: () {
          Navigator.of(context).pop();
          _resetAndFetch();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: Commonheader(
          title: 'Dress',
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: TextButton.icon(
                onPressed: () {
                  _showAddDressModal(context);
                },
                icon: const Icon(Icons.add, color: ColorPalatte.primary),
                label: const Text(
                  'Add Dress',
                  style: TextStyle(color: ColorPalatte.primary),
                ),
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
                  hintText: "Search dress...",
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
              child: dresses.isEmpty
                  ? const Center(child: Text("No dresses found"))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: dresses.length + (hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == dresses.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
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
                        final dress = dresses[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: DressIconWidget(
                              dressType: dress['name'],
                              size: 50,
                              showBackground: true,
                            ),
                            title: Text(
                              dress['name'] ?? 'Unknown Dress',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              "Tap to edit dress type",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: ColorPalatte.primary,
                              ),
                            ),
                            onTap: () {
                              _showEditDressModal(
                                  context, dress['dressTypeId'], dress['name']);
                            },
                          ),
                        );
                      },
                    ),
            )
          ],
        ));
  }
}
