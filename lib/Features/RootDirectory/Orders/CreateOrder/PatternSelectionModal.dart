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

    // Extract unique categories - group all patterns by category
    Set<String> categorySet = {};
    for (var item in patternsListArr) {
      // Handle name as array or string
      dynamic rawName = item['name'];
      String name = '';
      if (rawName is List) {
        name = rawName.isNotEmpty ? rawName[0].toString().trim() : '';
      } else if (rawName != null) {
        name = rawName.toString().trim();
      }
      
      // Handle category - if empty, use "Other"
      dynamic rawCategory = item['category'];
      String cat = '';
      if (rawCategory is List) {
        cat = rawCategory.isNotEmpty ? rawCategory[0].toString().trim() : '';
      } else if (rawCategory != null) {
        cat = rawCategory.toString().trim();
      }
      
      // Include if name is valid (category can be empty, we'll use "Other")
      if (name.isNotEmpty && name.toLowerCase() != 'unnamed pattern') {
        categorySet.add(cat.isNotEmpty ? cat : 'Other');
      }
    }
    
    List<String> categories = categorySet.toList()..sort();
    
    print('🎨 Extracted ${categories.length} categories: $categories');
    print('🎨 Total valid patterns: ${patternsListArr.length}');

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
      Set<String> categorySet = {};
      for (var item in patternsListArr) {
        // Handle category as array or string
        dynamic rawCategory = item['category'];
        String cat = '';
        if (rawCategory is List) {
          cat = rawCategory.isNotEmpty ? rawCategory[0].toString().trim() : '';
        } else if (rawCategory != null) {
          cat = rawCategory.toString().trim();
        }
        
        // If category is empty, use "Other"
        if (cat.isEmpty) {
          cat = 'Other';
        }
        
        if (cat.isNotEmpty) {
          categorySet.add(cat);
        }
      }
      categories = categorySet.toList()..sort();
      print('🎨 Categories extracted: $categories');
    } catch (e) {
      print("Error extracting categories: $e");
      categories = ['Other']; // Fallback
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
                                  final itemCategory = item['category']?.toString()?.trim() ?? "";
                                  final itemName = item['name'];
                                  
                                  // Normalize category (empty becomes "Other")
                                  final normalizedCategory = itemCategory.isNotEmpty ? itemCategory : 'Other';
                                  
                                  // Must match the current category being displayed
                                  if (normalizedCategory != category) {
                                    return SizedBox.shrink();
                                  }
                                  
                                  // Extract name - handle both string and list
                                  String displayName = '';
                                  if (itemName is List) {
                                    displayName = (itemName as List)
                                        .map((n) => n?.toString()?.trim() ?? '')
                                        .where((n) => n.isNotEmpty)
                                        .join(', ');
                                  } else {
                                    displayName = itemName?.toString()?.trim() ?? '';
                                  }
                                  
                                  // Skip if name is empty or invalid
                                  if (displayName.isEmpty || 
                                      displayName.toLowerCase() == 'unnamed pattern' ||
                                      displayName.toLowerCase() == '[unnamed pattern]') {
                                    return SizedBox.shrink();
                                  }
                                  
                                  // Get selection type - check if it's 'single' (case-insensitive)
                                  final selectionType = item['selection']?.toString()?.toLowerCase() ?? 'multiple';
                                  bool isSingleSelection = selectionType == 'single';
                                  
                                  final patternId = item['_id']?.toString() ?? item['dressPatternId']?.toString();
                                  if (patternId == null) {
                                    print(
                                        '⚠️ Warning: Missing _id for pattern: category=$category, name=$displayName');
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