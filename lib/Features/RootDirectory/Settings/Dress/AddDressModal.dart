import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';
import 'package:tailorapp/Core/Tools/Helper.dart';
import 'package:tailorapp/Core/Widgets/CustomLoader.dart';
import 'package:tailorapp/Core/Widgets/CustomSnakBar.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/Dress/Dress_style.dart';
import 'package:tailorapp/GlobalVariables.dart';
import '../../../../Core/Constants/ColorPalatte.dart';
import '../../../../Core/Services/Services.dart';
import '../../../../Core/Services/Urls.dart';

class AddDressModal extends StatefulWidget {
  const AddDressModal(
      {super.key, required this.onClose, this.dressDataId, this.dressName});

  final VoidCallback onClose;
  final int? dressDataId;
  final String? dressName;

  @override
  _AddDressModalState createState() => _AddDressModalState();
}

class _AddDressModalState extends State<AddDressModal> with SingleTickerProviderStateMixin {
  late TextEditingController dressNameController;
  late TabController _tabController;
  
  // Master lists (all available options)
  List<Map<String, dynamic>> allMeasurementsList = [];
  List<Map<String, dynamic>> allPatternsList = [];
  
  // Dress-specific measurements and patterns (what's assigned to this dress)
  List<Map<String, dynamic>> dressMeasurements = [];
  List<Map<String, dynamic>> dressPatterns = [];
  
  // Selected items (what user has checked)
  Map<String, bool> selectedMeasurements = {};
  Map<String, bool> selectedPatterns = {};
  
  // Store IDs for updates
  Map<String, int?> measurementTypeIds = {}; // Store dressTypeMeasurementId for each measurement
  Map<String, int?> patternTypeIds = {}; // Store dressTypePatternId for each pattern

  @override
  void initState() {
    super.initState();
    dressNameController = TextEditingController(text: widget.dressName ?? '');
    _tabController = TabController(length: 2, vsync: this);
    
    // Load data
    _loadData();
  }

  Future<void> _loadData() async {
    // Load master lists first
    await getDressMeasurement();
    await getDressPattern();
    
    // Then load existing assignments for this dress
    if (widget.dressDataId != null) {
      await fetchDressPattMea(widget.dressDataId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    dressNameController.dispose();
    super.dispose();
  }

  Future<void> fetchDressPattMea(int? dressTypeId) async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) {
      print("Shop ID is missing");
      return;
    }

    final String requestUrl = "${Urls.orderDressTypeMea}/$shopId/$dressTypeId";
    try {
      final response = await ApiService().get(requestUrl, context);

      if (response.data is Map<String, dynamic>) {
        List<dynamic> fetchedMeasurements = response.data["DressTypeMeasurement"] ?? [];
        List<dynamic> fetchedPatterns = response.data["DressTypeDressPattern"] ?? [];
        
        print('📏 Fetched Measurements: ${fetchedMeasurements.length}');
        print('🎨 Fetched Patterns: ${fetchedPatterns.length}');
        print('🎨 First pattern sample: ${fetchedPatterns.isNotEmpty ? fetchedPatterns[0] : "No patterns"}');

        setState(() {
          // Clear previous data
          dressMeasurements.clear();
          dressPatterns.clear();
          selectedMeasurements.clear();
          selectedPatterns.clear();
          measurementTypeIds.clear();
          patternTypeIds.clear();
          
          // Process dress-specific measurements
          for (var fetchedMeasurement in fetchedMeasurements) {
            // For measurements, the data is directly in the fetched measurement
            // but we need to match it with the master list to get the full details
            String name = fetchedMeasurement["name"];
            var matchingMeasurement = allMeasurementsList.firstWhere(
              (m) => m["name"] == name,
              orElse: () => {},
            );
            if (matchingMeasurement.isNotEmpty) {
              // Add to dress-specific measurements list
              dressMeasurements.add({
                ...matchingMeasurement,
                "dressTypeMeasurementId": fetchedMeasurement["dressTypeMeasurementId"],
              });
              
              // Mark as selected
              String id = matchingMeasurement["_id"].toString();
              selectedMeasurements[id] = true;
              measurementTypeIds[id] = fetchedMeasurement["dressTypeMeasurementId"];
            }
          }

          // Process dress-specific patterns
          for (var fetchedPattern in fetchedPatterns) {
            // The pattern details are in PatternDetails field
            var patternDetails = fetchedPattern["PatternDetails"];
            print('🔍 Processing pattern: dressPatternId=${fetchedPattern["dressPatternId"]}, hasPatternDetails=${patternDetails != null}');
            
            if (patternDetails != null) {
              // Add to dress-specific patterns list using PatternDetails
              dressPatterns.add({
                "_id": patternDetails["_id"],
                "dressPatternId": patternDetails["dressPatternId"],
                "name": patternDetails["name"],
                "category": patternDetails["category"],
                "dressTypePatternId": fetchedPattern["_id"], // Use the relation ID
              });
              
              // Mark as selected
              String id = patternDetails["_id"].toString();
              selectedPatterns[id] = true;
              patternTypeIds[id] = fetchedPattern["_id"];
              print('✅ Added pattern: ${patternDetails["name"]}');
            } else {
              print('❌ Pattern details missing for dressPatternId: ${fetchedPattern["dressPatternId"]}');
            }
          }
          
          print('📏 Dress Measurements: ${dressMeasurements.length}');
          print('🎨 Dress Patterns: ${dressPatterns.length}');
        });
      }
    } catch (e) {
      print("❌ Failed to load dress measurements: $e");
    }
  }

  Future<void> handleSaveDress() async {
    if (dressNameController.text.isEmpty) {
      CustomSnackbar.showSnackbar(
        context,
        'Dress name is required',
        duration: const Duration(seconds: 1),
      );
      return;
    }

    int? shopId = GlobalVariables.shopIdGet;
    int? userId = GlobalVariables.userId;

    if (shopId == null) {
      CustomSnackbar.showSnackbar(
        context,
        'Shop ID is missing',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final Map<String, dynamic> payloadSaveDress = {
      "shop_id": shopId,
      "name": capitalize(dressNameController.text),
    };

    try {
      showLoader(context);
      dynamic responseSaveDress;
      if (widget.dressDataId != null) {
        String url = "${Urls.addDress}/$shopId/${widget.dressDataId}";
        responseSaveDress =
            await ApiService().put(url, context, data: payloadSaveDress);
      } else {
        responseSaveDress = await ApiService()
            .post(Urls.addDress, context, data: payloadSaveDress);
      }

      int? dressTypeId;
      String? owner = userId?.toString();
      if (responseSaveDress != null &&
          responseSaveDress.data is Map<String, dynamic>) {
        dressTypeId = responseSaveDress.data['createDressType']?['dressTypeId'];
      } else {
        throw Exception('Failed to save dress');
      }

      List<int> selectedPatternIds = [];
      List<String> selectedCategories = [];
      List<int> selectedMeasurementIds = [];
      List<String> selectedMeasurementNames = [];
      List<int?> selectedDressTypePatternId = [];
      List<int?> selectedDressTypeMeasurementId = [];

      for (var pattern in allPatternsList) {
        print('tttttttt::::: $pattern');
        String patternId = pattern["_id"].toString();
        if (selectedPatterns[patternId] == true) {
          selectedPatternIds.add(pattern["dressPatternId"]);
          // Use stored dressTypePatternId if available, otherwise null
          selectedDressTypePatternId.add(patternTypeIds[patternId]);
          if (!selectedCategories.contains(pattern["category"])) {
            selectedCategories.add(pattern["category"]);
          }
        }
      }

      for (var measure in allMeasurementsList) {
        print('llllllll::::::: $measure');
        String measureId = measure["_id"].toString();
        if (selectedMeasurements[measureId] == true) {
          selectedMeasurementIds.add(measure["measurementId"]);
          selectedMeasurementNames.add(measure["name"]);
          // Use stored dressTypeMeasurementId if available, otherwise null
          selectedDressTypeMeasurementId.add(measurementTypeIds[measureId]);
        }
      }

      final List<Map<String, dynamic>> payloadPatternList =
          selectedPatternIds.map((id) {
        int index = selectedPatternIds.indexOf(id);
        return {
          "shop_id": shopId,
          "dressTypeId": widget.dressDataId ?? dressTypeId,
          "dressTypePatternId":
              widget.dressDataId != null ? selectedDressTypePatternId[index] : null,
          "category": (index < selectedCategories.length)
              ? selectedCategories[index]
              : "string",
          "dressPatternId": id,
          "owner": owner,
        };
      }).toList();

      final List<Map<String, dynamic>> payloadMeasurementList =
          List.generate(selectedMeasurementIds.length, (index) {
        return {
          "dressTypeMeasurementId": widget.dressDataId != null
              ? selectedDressTypeMeasurementId[index]
              : null,
          "shop_id": shopId,
          "dressTypeId": widget.dressDataId ?? dressTypeId,
          "name": selectedMeasurementNames[index],
          "measurementId": selectedMeasurementIds[index],
          "owner": owner,
        };
      });

      if (payloadPatternList.isEmpty || payloadMeasurementList.isEmpty) {
        CustomSnackbar.showSnackbar(
          context,
          'At least one pattern and one measurement must be selected!',
          duration: const Duration(seconds: 2),
        );
        hideLoader(context);
        return;
      }

      print('payload measure,emnt: $payloadMeasurementList');
      print('payload pattern $payloadPatternList');

      dynamic responseMeasurement;
      dynamic responsePattern;
      if (widget.dressDataId != null) {
        print('🔄 Updating existing dress - calling PUT APIs...');
        responseMeasurement = await ApiService()
            .put(Urls.addMeasurement, context, data: payloadMeasurementList);
        print('📏 Measurement response: ${responseMeasurement?.data}');
        
        responsePattern = await ApiService()
            .put(Urls.addDressPattern, context, data: payloadPatternList);
        print('🎨 Pattern response: ${responsePattern?.data}');
      } else {
        print('🔄 Creating new dress - calling POST APIs...');
        responseMeasurement = await ApiService()
            .post(Urls.addMeasurement, context, data: payloadMeasurementList);
        print('📏 Measurement response: ${responseMeasurement?.data}');
        
        responsePattern = await ApiService()
            .post(Urls.addDressPattern, context, data: payloadPatternList);
        print('🎨 Pattern response: ${responsePattern?.data}');
      }

      hideLoader(context);

      if (responseMeasurement != null &&
          responseMeasurement.data != null &&
          responsePattern != null &&
          responsePattern.data != null) {
        CustomSnackbar.showSnackbar(
          context,
          responseMeasurement.data['message'] ?? 'Dress saved successfully',
          duration: const Duration(seconds: 1),
        );
        widget.onClose();
      } else {
        throw Exception('Failed to save measurements or patterns');
      }
    } catch (e) {
      hideLoader(context);
      print('❌ Error in saveDressPattMea: $e');
      CustomSnackbar.showSnackbar(
        context,
        'Error saving dress: ${e.toString()}',
        duration: const Duration(seconds: 3),
      );
      print('Error: ${e.toString()}');
    }
  }

  Future<void> getDressMeasurement() async {
    int? id = GlobalVariables.shopIdGet;
    final String requestUrl = "${Urls.getMeasurement}/$id";

    try {
      final response = await ApiService().get(requestUrl, context);

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        setState(() {
          allMeasurementsList = List<Map<String, dynamic>>.from(
            response.data['data'].map((m) => {
                  "_id": m["_id"],
                  "measurementId": m["measurementId"],
                  "name": m["name"],
                }),
          );
        });
        print('📏 Loaded ${allMeasurementsList.length} measurements');
      } else {
        print('⚠️ No measurements found');
      }
    } catch (e) {
      print('❌ Error loading measurements: ${e.toString()}');
    }
  }

  Future<void> getDressPattern() async {
    int? shopId = GlobalVariables.shopIdGet;
    final String requestUrl = "${Urls.getDressPattern}/$shopId";
    try {
      final response = await ApiService().get(requestUrl, context);

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        setState(() {
          allPatternsList = List<Map<String, dynamic>>.from(
            response.data['data'].map((p) => {
                  "_id": p["_id"],
                  "dressPatternId": p["dressPatternId"],
                  "name": p["name"],
                  "category": p["category"],
                }),
          );
        });
        print('🎨 Loaded ${allPatternsList.length} patterns');
      } else {
        print('⚠️ No patterns found');
      }
    } catch (e) {
      print('❌ Error loading patterns: $e');
    }
  }

  // Helper methods for checkbox handling
  void _toggleMeasurement(String measurementId) {
    setState(() {
      selectedMeasurements[measurementId] = !(selectedMeasurements[measurementId] ?? false);
    });
  }

  void _togglePattern(String patternId) {
    setState(() {
      selectedPatterns[patternId] = !(selectedPatterns[patternId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              // Compact Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: ColorPalatte.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12.0),
                    topRight: Radius.circular(12.0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.dressDataId != null
                          ? Textstring().updateDress
                          : Textstring().addDress,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColorPalatte.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black, size: 20),
                      onPressed: widget.onClose,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // Compact Dress Name Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: dressNameController,
                  decoration: InputDecoration(
                    labelText: Textstring().dressName,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: ColorPalatte.primary),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
              
              // Compact Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: ColorPalatte.primary,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  tabs: [
                    Tab(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.straighten, size: 16),
                          SizedBox(width: 4),
                          Text('Measurements (${dressMeasurements.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pattern, size: 16),
                          SizedBox(width: 4),
                          Text('Patterns (${dressPatterns.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Expanded Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMeasurementsTab(),
                    _buildPatternsTab(),
                  ],
                ),
              ),
              
              // Compact Save Button
              Container(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: handleSaveDress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPalatte.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 10.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        widget.dressDataId != null
                            ? Textstring().update
                            : Textstring().saveDress,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementsTab() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header with Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Measurements (${dressMeasurements.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorPalatte.primary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddMeasurementDialog,
                icon: Icon(Icons.add, size: 14),
                label: Text('Add', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalatte.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size(0, 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Expanded(
            child: dressMeasurements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.straighten_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No measurements assigned',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: dressMeasurements.length,
                    itemBuilder: (context, index) {
                      final measurement = dressMeasurements[index];
                      final measurementId = measurement['_id'].toString();
                      final isSelected = selectedMeasurements[measurementId] ?? false;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4.0),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? ColorPalatte.primary.withOpacity(0.1)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected 
                                ? ColorPalatte.primary
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          title: Text(
                            measurement['name'],
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? ColorPalatte.primary : Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            'ID: ${measurement['measurementId']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              _toggleMeasurement(measurementId);
                            },
                            checkColor: Colors.white,
                            activeColor: ColorPalatte.primary,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternsTab() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header with Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Patterns (${dressPatterns.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorPalatte.primary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddPatternDialog,
                icon: Icon(Icons.add, size: 14),
                label: Text('Add', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalatte.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size(0, 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Expanded(
            child: dressPatterns.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pattern_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No patterns assigned',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: dressPatterns.length,
                    itemBuilder: (context, index) {
                      final pattern = dressPatterns[index];
                      final patternId = pattern['_id'].toString();
                      final isSelected = selectedPatterns[patternId] ?? false;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4.0),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? ColorPalatte.primary.withOpacity(0.1)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected 
                                ? ColorPalatte.primary
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          title: Text(
                            pattern['name'],
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? ColorPalatte.primary : Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            'ID: ${pattern['dressPatternId']}${pattern['category'] != null && pattern['category'].toString().isNotEmpty ? ' • ${pattern['category']}' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              _togglePattern(patternId);
                            },
                            checkColor: Colors.white,
                            activeColor: ColorPalatte.primary,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddMeasurementDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Measurement', style: TextStyle(fontSize: 16)),
          content: Container(
            width: 400,
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select a measurement to add:', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: allMeasurementsList.length,
                    itemBuilder: (context, index) {
                      final measurement = allMeasurementsList[index];
                      final measurementId = measurement['_id'].toString();
                      final isAlreadyAdded = dressMeasurements.any(
                        (m) => m['_id'].toString() == measurementId
                      );
                      
                      return ListTile(
                        dense: true,
                        title: Text(measurement['name'], style: TextStyle(fontSize: 13)),
                        subtitle: Text('ID: ${measurement['measurementId']}', style: TextStyle(fontSize: 11)),
                        trailing: isAlreadyAdded 
                          ? Icon(Icons.check, color: Colors.green, size: 18)
                          : Icon(Icons.add, size: 18),
                        onTap: isAlreadyAdded ? null : () {
                          _addMeasurementToDress(measurement);
                          Navigator.of(context).pop();
                        },
                        enabled: !isAlreadyAdded,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  void _showAddPatternDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Pattern', style: TextStyle(fontSize: 16)),
          content: Container(
            width: 400,
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select a pattern to add:', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: allPatternsList.length,
                    itemBuilder: (context, index) {
                      final pattern = allPatternsList[index];
                      final patternId = pattern['_id'].toString();
                      final isAlreadyAdded = dressPatterns.any(
                        (p) => p['_id'].toString() == patternId
                      );
                      
                      return ListTile(
                        dense: true,
                        title: Text(pattern['name'], style: TextStyle(fontSize: 13)),
                        subtitle: Text('ID: ${pattern['dressPatternId']}${pattern['category'] != null && pattern['category'].toString().isNotEmpty ? ' • ${pattern['category']}' : ''}', style: TextStyle(fontSize: 11)),
                        trailing: isAlreadyAdded 
                          ? Icon(Icons.check, color: Colors.green, size: 18)
                          : Icon(Icons.add, size: 18),
                        onTap: isAlreadyAdded ? null : () {
                          _addPatternToDress(pattern);
                          Navigator.of(context).pop();
                        },
                        enabled: !isAlreadyAdded,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  void _addMeasurementToDress(Map<String, dynamic> measurement) {
    setState(() {
      dressMeasurements.add({
        ...measurement,
        "dressTypeMeasurementId": null, // Will be set when saved
      });
      
      String id = measurement["_id"].toString();
      selectedMeasurements[id] = true;
      measurementTypeIds[id] = null;
    });
  }

  void _addPatternToDress(Map<String, dynamic> pattern) {
    setState(() {
      dressPatterns.add({
        ...pattern,
        "dressTypePatternId": null, // Will be set when saved
      });
      
      String id = pattern["_id"].toString();
      selectedPatterns[id] = true;
      patternTypeIds[id] = null;
    });
  }
}
