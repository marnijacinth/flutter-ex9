import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProductUpdateApp());
}

class ProductUpdateApp extends StatelessWidget {
  const ProductUpdateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Update Product Details',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const ProductUpdatePage(),
    );
  }
}

class ProductUpdatePage extends StatefulWidget {
  const ProductUpdatePage({super.key});

  @override
  State<ProductUpdatePage> createState() => _ProductUpdatePageState();
}

class _ProductUpdatePageState extends State<ProductUpdatePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _status = "";
  String? _docId; // to hold Firestore doc id
  bool _isLoading = false;
  Map<String, dynamic>? _productData;

  /// 🔍 Search product by name
  Future<void> _searchProduct() async {
    final name = _searchController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _status = "Please enter a product name.";
        _productData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = "";
      _productData = null;
      _docId = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products_details')
          .where('name', isEqualTo: name)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _status = "Product not found";
        });
      } else {
        final doc = snapshot.docs.first;
        final data = doc.data();
        setState(() {
          _docId = doc.id;
          _productData = data;
          _quantityController.text = data['quantity'].toString();
          _priceController.text = data['price'].toString();
        });
      }
    } catch (e) {
      setState(() {
        _status = "Error: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✏️ Update product details
  Future<void> _updateProduct() async {
    if (_docId == null) {
      setState(() => _status = "Search a product first.");
      return;
    }

    final newQuantity = double.tryParse(_quantityController.text.trim());
    final newPrice = double.tryParse(_priceController.text.trim());

    if (newQuantity == null || newPrice == null) {
      setState(() => _status = "Enter valid numeric values.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ref = FirebaseFirestore.instance
          .collection('products_details')
          .doc(_docId);

      await ref.update({'quantity': newQuantity, 'price': newPrice});

      // fetch updated data to display
      final updated = await ref.get();
      setState(() {
        _productData = updated.data();
        _status = "✅ Product updated successfully!";
      });
    } catch (e) {
      setState(() => _status = "Error updating product: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Product Details'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Enter product name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _searchProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Search"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Update"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_status.isNotEmpty)
              Text(
                _status,
                style: TextStyle(
                  color: _status.startsWith("✅") ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              )
            else if (_productData != null)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Name: ${_productData!['name']}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Quantity",
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Price"),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
