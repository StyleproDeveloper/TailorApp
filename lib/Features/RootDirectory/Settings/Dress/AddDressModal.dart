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

class _AddDressModalState extends State<AddDressModal> {
  late TextEditingController dressNameController;
  List<Map<String, dynamic>> measurements = [];
  List<Map<String, dynamic>> patternsList = [];
  Map<String, bool> selectedMeasurements = {};
  bool _showMeasurements = true;
  Map<String, bool> selectedPatterns = {};
  bool _showPatterns = false;
  List<Map<String, dynamic>> allMeasurementsList = [];
  List<Map<String, dynamic>> allPatternsList = [];
  Map<String, int?> measurementTypeIds = {}; // Store dressTypeMeasurementId for each measurement
  Map<String, int?> patternTypeIds = {}; // Store dressTypePatternId for each pattern

  @override
  void initState() {
    super.initState();
    dressNameController = TextEditingController(text: widget.dressName ?? '');
    getDressMeasurement().then((_) {
      getDressPattern().then((_) {
        if (widget.dressDataId != null) {
          fetchDressPattMea(widget.dressDataId);
        }
      });
    });
  }

  Future<void> fetchDressPattMea(int? dressTypeId) async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) {
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            "Shop ID is missing",
            duration: Duration(seconds: 2),
          ));
      return;
    }

    final String requestUrl = "${Urls.orderDressTypeMea}/$shopId/$dressTypeId";
    try {
      final response = await ApiService().get(requestUrl, context);

      if (response.data is Map<String, dynamic>) {
        List<dynamic> fetchedMeasurements =
            response.data["DressTypeMeasurement"] ?? [];
        List<dynamic> fetchedPatterns =
            response.data["DressTypeDressPattern"] ?? [];
        print('fetchedMeasurements,,,,,,,,,,,,,, $fetchedMeasurements');
        print('fetchedPatterns,,,,,,,,,,,,,, $fetchedPatterns');

        setState(() {
          selectedMeasurements.clear();
          for (var measurement in measurements) {
            String id = measurement["_id"].toString();
            selectedMeasurements[id] = false;
          }

          selectedPatterns.clear();
          for (var pattern in patternsList) {
            String id = pattern["_id"].toString();
            selectedPatterns[id] = false;
          }

          for (var fetchedMeasurement in fetchedMeasurements) {
            String name = fetchedMeasurement["name"];
            var matchingMeasurement = measurements.firstWhere(
              (m) => m["name"] == name,
              orElse: () => {},
            );
            String id = matchingMeasurement["_id"].toString();
            selectedMeasurements[id] = true;
            // Store the dressTypeMeasurementId
            measurementTypeIds[id] = fetchedMeasurement["dressTypeMeasurementId"];
          }

          for (var fetchedPattern in fetchedPatterns) {
            String dressPatternId = fetchedPattern["dressPatternId"].toString();
            var matchingPattern = patternsList.firstWhere(
              (p) => p["dressPatternId"].toString() == dressPatternId,
              orElse: () => {},
            );
            String id = matchingPattern["_id"].toString();
            selectedPatterns[id] = true;
            // Store the dressTypePatternId
            patternTypeIds[id] = fetchedPattern["dressTypePatternId"];
          }
        });
      }
    } catch (e) {
      print("Failed to load dress measurements: $e");
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

      for (var pattern in patternsList) {
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

      for (var measure in measurements) {
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
        responseMeasurement = await ApiService()
            .put(Urls.addMeasurement, context, data: payloadMeasurementList);
        responsePattern = await ApiService()
            .put(Urls.addDressPattern, context, data: payloadPatternList);
      } else {
        responseMeasurement = await ApiService()
            .post(Urls.addMeasurement, context, data: payloadMeasurementList);
        responsePattern = await ApiService()
            .post(Urls.addDressPattern, context, data: payloadPatternList);
      }

      hideLoader(context);

      if (responseMeasurement != null &&
          responseMeasurement.data != null &&
          responsePattern != null &&
          responsePattern.data != null) {
        CustomSnackbar.showSnackbar(
          context,
          responseSaveDress.data['message'] ?? 'Dress saved successfully',
          duration: const Duration(seconds: 1),
        );
        widget.onClose();
      } else {
        throw Exception('Failed to save measurements or patterns');
      }
    } catch (e) {
      hideLoader(context);
      CustomSnackbar.showSnackbar(
        context,
        'Error: ${e.toString()}',
        duration: const Duration(seconds: 2),
      );
      print('Error: ${e.toString()}');
    }
  }

  Future<void> getDressMeasurement() async {
    int? id = GlobalVariables.shopIdGet;
    final String requestUrl = "${Urls.getMeasurement}/$id";

    try {
      Future.delayed(Duration.zero, () => showLoader(context));
      final response = await ApiService().get(requestUrl, context);
      Future.delayed(Duration.zero, () => hideLoader(context));

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        setState(() {
          measurements = List<Map<String, dynamic>>.from(
            response.data['data'].map((m) => {
                  "_id": m["_id"],
                  "measurementId": m["measurementId"],
                  "name": m["name"],
                }),
          );
          selectedMeasurements.clear();
          for (var m in measurements) {
            selectedMeasurements[m["_id"]] = false;
          }
        });
      } else {
        CustomSnackbar.showSnackbar(
          context,
          'No measurements found',
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      print('Error: ${e.toString()}');
      CustomSnackbar.showSnackbar(
        context,
        'Error: ${e.toString()}',
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> getDressPattern() async {
    int? shopId = GlobalVariables.shopIdGet;
    final String requestUrl = "${Urls.getDressPattern}/$shopId";
    try {
      Future.delayed(Duration.zero, () => showLoader(context));
      final response = await ApiService().get(requestUrl, context);
      Future.delayed(Duration.zero, () => hideLoader(context));

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        setState(() {
          patternsList = List<Map<String, dynamic>>.from(
            response.data['data'].map((p) => {
                  "_id": p["_id"],
                  "dressPatternId": p["dressPatternId"],
                  "name": p["name"],
                  "category": p["category"],
                }),
          );
          selectedPatterns.clear();
          for (var p in patternsList) {
            selectedPatterns[p["_id"]] = false;
          }
        });
      } else {
        CustomSnackbar.showSnackbar(
          context,
          'No patterns found',
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      Future.delayed(Duration.zero, () => hideLoader(context));
      CustomSnackbar.showSnackbar(
        context,
        'Error fetching patterns: $e',
        duration: const Duration(seconds: 1),
      );
    }
  }

  void toggleMeasurements() {
    setState(() {
      _showMeasurements = !_showMeasurements;
      if (_showMeasurements) {
        _showPatterns = false;
      }
    });
  }

  void togglePatterns() {
    setState(() {
      _showPatterns = !_showPatterns;
      if (_showPatterns) {
        _showMeasurements = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        widget.dressDataId != null
                            ? Textstring().updateDress
                            : Textstring().addDress,
                        style: DressStyle.headerDress),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dressNameController,
                  decoration:
                      InputDecoration(labelText: Textstring().dressName),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: toggleMeasurements,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add Measurement',
                          style: DressStyle.dressText),
                      Icon(
                        _showMeasurements
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                      ),
                    ],
                  ),
                ),
                if (_showMeasurements)
                  Column(
                    children: measurements.map((measurement) {
                      return CheckboxListTile(
                        title: Text(measurement['name']),
                        value:
                            selectedMeasurements[measurement['_id']] ?? false,
                        onChanged: (bool? value) {
                          setState(() {
                            selectedMeasurements[measurement['_id']] =
                                value ?? false;
                          });
                        },
                        checkColor: ColorPalatte.white,
                        activeColor: ColorPalatte.primary,
                      );
                    }).toList(),
                  ),
                GestureDetector(
                  onTap: togglePatterns,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add Pattern', style: DressStyle.dressText),
                      Icon(
                        _showPatterns
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                      ),
                    ],
                  ),
                ),
                if (_showPatterns)
                  Column(
                    children: patternsList.map((pattern) {
                      return CheckboxListTile(
                        title: Text("${pattern['name']}"),
                        value: selectedPatterns[pattern['_id']] ?? false,
                        onChanged: (bool? value) {
                          setState(() {
                            selectedPatterns[pattern['_id']] = value ?? false;
                          });
                        },
                        checkColor: ColorPalatte.white,
                        activeColor: ColorPalatte.primary,
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: handleSaveDress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalatte.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                    ),
                    child: Text(
                        widget.dressDataId != null
                            ? Textstring().updateDress
                            : Textstring().saveDress,
                        style: DressStyle.saveBtnDress),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
