import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'dart:ui';

class PatternSelectionmodal extends StatefulWidget {
  final Map<String, dynamic>? patternsList;
  final List<Map<String, dynamic>> selectedPatterns;

  const PatternSelectionmodal({
    super.key,
    this.patternsList,
    this.selectedPatterns = const [],
  });

  @override
  State<PatternSelectionmodal> createState() => _PatternSelectionmodalState();
}

class _PatternSelectionmodalState extends State<PatternSelectionmodal> {
  List patternsListArr = [];
  Map<String, List<String>> categoryNamesMap = {};
  Map<String, String?> radioSelection = {};
  Map<String, Set<String>> checkboxSelection = {};

  @override
  void initState() {
    super.initState();
    patternsListArr = widget.patternsList?['patterns'] ?? [];
    print('Patterns List: $patternsListArr');
    print('Selected Patterns: ${widget.selectedPatterns}');

    // Extract unique categories
    List<String> categories = patternsListArr
        .map((item) => item['category']?.toString() ?? "")
        .toSet()
        .where((category) => category.isNotEmpty)
        .toList();

    // Initialize selection state
    for (var category in categories) {
      radioSelection[category] = null;
      checkboxSelection[category] = {};

      // Pre-select patterns based on selectedPatterns
      final selectedPattern = widget.selectedPatterns.firstWhere(
        (pattern) => pattern['category'] == category,
        orElse: () => <String, dynamic>{},
      );

      if (selectedPattern.isNotEmpty) {
        // Handle both String and List cases for selectedPattern['name']
        final selectedNames = selectedPattern['name'] is List
            ? (selectedPattern['name'] as List).cast<String>()
            : selectedPattern['name'] != null
                ? [selectedPattern['name'].toString()]
                : [];

        for (var name in selectedNames) {
          // Find the corresponding pattern in patternsListArr
          final matchingPattern = patternsListArr.firstWhere(
            (item) {
              if (item['category'] != category) return false;
              final itemName = item['name'];
              if (itemName is List) {
                return itemName.contains(name);
              } else {
                return itemName == name;
              }
            },
            orElse: () => <String, dynamic>{},
          );

          if (matchingPattern.isNotEmpty) {
            final patternId = matchingPattern['_id']?.toString();
            final selectionType = matchingPattern['selection']?.toString() ?? 'multiple';
            if (patternId != null) {
              print(
                  'Pre-selecting pattern: category=$category, name=$name, id=$patternId, selection=$selectionType');
              if (selectionType == 'single') {
                radioSelection[category] = patternId;
              } else {
                checkboxSelection[category]!.add(patternId);
              }
            } else {
              print('Warning: Missing _id for pattern: category=$category, name=$name');
            }
          } else {
            print('Warning: No matching pattern found for: category=$category, name=$name');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> categories = [];

    try {
      categories = patternsListArr
          .map((item) => item['category']?.toString() ?? "")
          .toSet()
          .where((category) => category.isNotEmpty)
          .toList();
    } catch (e) {
      print("Error extracting categories: $e");
    }

    return Scaffold(
      backgroundColor: ColorPalatte.white.withOpacity(0.8),
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: ColorPalatte.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Category',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children: categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                ...patternsListArr.map((item) {
                                  if (item['category'] != category ||
                                      item['category']?.toString() == "") {
                                    return SizedBox.shrink();
                                  }
                                  bool isSingleSelection =
                                      item['selection']?.toString() == 'single';
                                  final name = item['name'];
                                  final displayName = name is List
                                      ? (name as List).join(', ')
                                      : name?.toString() ?? '';
                                  final patternId = item['_id']?.toString();
                                  if (patternId == null) {
                                    print(
                                        'Warning: Missing _id for pattern: category=$category, name=$displayName');
                                    return SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: Row(
                                      children: [
                                        isSingleSelection
                                            ? Radio<String>(
                                                value: patternId,
                                                groupValue:
                                                    radioSelection[category],
                                                onChanged: (value) {
                                                  setState(() {
                                                    radioSelection[category] =
                                                        value;
                                                  });
                                                },
                                              )
                                            : Checkbox(
                                                value: checkboxSelection[
                                                        category]!
                                                    .contains(patternId),
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    if (value != null) {
                                                      if (value) {
                                                        checkboxSelection[
                                                                category]!
                                                            .add(patternId);
                                                      } else {
                                                        checkboxSelection[
                                                                category]!
                                                            .remove(patternId);
                                                      }
                                                    }
                                                  });
                                                },
                                              ),
                                        Expanded(
                                          child: Text(
                                            displayName,
                                            style: TextStyle(fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).where((widget) => widget != SizedBox.shrink())
                                    .toList(),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          List<Map<String, dynamic>> selectedPatterns = [];

                          // Handle single selection categories
                          radioSelection.forEach((category, selectedId) {
                            if (selectedId != null) {
                              final selectedItem = patternsListArr.firstWhere(
                                (item) => item['_id'] == selectedId,
                                orElse: () => <String, dynamic>{},
                              );
                              if (selectedItem.isNotEmpty &&
                                  selectedItem['name'] != null) {
                                print(
                                    'Selected single pattern: category=$category, id=$selectedId, name=${selectedItem['name']}');
                                selectedPatterns.add({
                                  'category': category,
                                  'name': selectedItem['name'] is List
                                      ? selectedItem['name']
                                      : [selectedItem['name']],
                                });
                              } else {
                                print(
                                    'Warning: Invalid or missing pattern for category=$category, id=$selectedId');
                              }
                            }
                          });

                          // Handle multiple selection categories
                          checkboxSelection.forEach((category, selectedIds) {
                            if (selectedIds.isNotEmpty) {
                              final selectedNames = selectedIds
                                  .map((id) {
                                    final item = patternsListArr.firstWhere(
                                      (element) => element['_id'] == id,
                                      orElse: () => <String, dynamic>{},
                                    );
                                    return item['name'];
                                  })
                                  .whereType<dynamic>()
                                  .map((name) => name is List
                                      ? name
                                      : name != null
                                          ? [name.toString()]
                                          : [])
                                  .expand((x) => x)
                                  .toList()
                                  .cast<String>();

                              if (selectedNames.isNotEmpty) {
                                print(
                                    'Selected multiple patterns: category=$category, names=$selectedNames');
                                selectedPatterns.add({
                                  'category': category,
                                  'name': selectedNames,
                                });
                              } else {
                                print(
                                    'Warning: No valid names for category=$category, ids=$selectedIds');
                              }
                            }
                          });

                          print('Returning selected patterns: $selectedPatterns');
                          Navigator.of(context).pop(selectedPatterns);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPalatte.primary,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: Text('Save Selection'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}