import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const CustomerDetailsPage(),
      theme: ThemeData(fontFamily: 'Arial'),
    );
  }
}

class CustomerDetailsPage extends StatelessWidget {
  const CustomerDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Customer Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomerCard(),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RevenueCard(title: 'Total Revenue', amount: '\$15,250'),
                RevenueCard(title: 'Pending Amount', amount: '\$2,450'),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[300],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {},
              child: const Center(child: Text('Measurement Details')),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Order Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Chip(label: Text('Order History')),
              ],
            ),
            const SizedBox(height: 12),
            const OrderCard(
              orderId: 'ORD123',
              amount: '\$450',
              itemCount: 3,
              deliveryDate: 'Dec 15, 2023',
              status: 'Processing',
            ),
            const SizedBox(height: 8),
            const OrderCard(
              orderId: 'ORD124',
              amount: '\$320',
              itemCount: 2,
              deliveryDate: 'Dec 20, 2023',
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerCard extends StatelessWidget {
  const CustomerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('John Smith', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 8),
                Row(children: [Icon(Icons.phone, size: 16), SizedBox(width: 4), Text('(555) 123-4567')]),
                SizedBox(height: 4),
                Row(children: [Icon(Icons.location_on, size: 16), SizedBox(width: 4), Text('123 Business Street, City')]),
              ],
            ),
            const Icon(Icons.edit, size: 20)
          ],
        ),
      ),
    );
  }
}

class RevenueCard extends StatelessWidget {
  final String title;
  final String amount;
  const RevenueCard({super.key, required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final String orderId;
  final String amount;
  final int itemCount;
  final String deliveryDate;
  final String? status;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.amount,
    required this.itemCount,
    required this.deliveryDate,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order # $orderId', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(amount, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Number of Items: $itemCount'),
                if (status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(status!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  )
              ],
            ),
            const SizedBox(height: 4),
            Text('Delivery Date   $deliveryDate'),
          ],
        ),
      ),
    );
  }
}
