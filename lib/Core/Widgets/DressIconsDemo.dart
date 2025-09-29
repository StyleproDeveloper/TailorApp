import 'package:flutter/material.dart';
import 'DressIcons.dart';

// Demo widget to showcase dress icons
class DressIconsDemo extends StatelessWidget {
  const DressIconsDemo({Key? key}) : super(key: key);

  // Sample dress types to demonstrate
  static const List<String> sampleDressTypes = [
    'Blouse',
    'Blazer', 
    'Kurta',
    'Kurti',
    'Saree',
    'Lehenga',
    'Shirt',
    'T-Shirt',
    'Dress',
    'Gown',
    'Pant',
    'Jeans',
    'Skirt',
    'Shorts',
    'Dupatta',
    'Frock',
    'Jumpsuit',
    'Dhoti',
    'Wedding',
    'Party',
    'Uniform',
    'Apron',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dress Icons Demo'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dress Icons Preview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'These are the beautiful icons that will replace the letter thumbnails in your dress list:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: sampleDressTypes.length,
                itemBuilder: (context, index) {
                  final dressType = sampleDressTypes[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DressIconWidget(
                          dressType: dressType,
                          size: 60,
                          showBackground: true,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          dressType,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}