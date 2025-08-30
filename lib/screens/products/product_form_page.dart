import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart';

class ProductFormPage extends StatefulWidget {
  final Product? product;
  const ProductFormPage({this.product, super.key});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _inStockCtrl = TextEditingController();

  List<Map<String, dynamic>> _sizes =
      []; // Each: {size, price, imageUrls, pickedImages}
  final _picker = ImagePicker();

  List<XFile>? _pickedImages;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameCtrl.text = widget.product!.name;
      _priceCtrl.text = widget.product!.price.toString();
      _descCtrl.text = widget.product!.description;
      _inStockCtrl.text = widget.product!.inStock.toString();
      // Load sizes if present
      if (widget.product!.sizes != null) {
        _sizes = widget.product!.sizes!.map((size) {
          // Ensure pickedImages is always initialized as an empty list
          return {...size, 'pickedImages': []};
        }).toList();
      }
    }
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    setState(() {
      _pickedImages = images;
    });
  }

  Future<List<String>> _uploadImages(List<XFile> images) async {
    final storage = FirebaseStorage.instance;
    List<String> downloadUrls = [];

    for (final image in images) {
      final ref = storage.ref().child(
        'product_images/${DateTime.now().millisecondsSinceEpoch}_${image.name}',
      );

      UploadTask uploadTask;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        uploadTask = ref.putData(bytes);
      } else {
        final file = File(image.path);
        uploadTask = ref.putFile(file);
      }

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      print('Uploaded image path: ${ref.fullPath}');
      print('Download URL: $url');
      downloadUrls.add(url); // Save the URL as returned by getDownloadURL()
    }

    return downloadUrls;
  }

  Future<void> _pickSizeImages(int sizeIndex) async {
    final images = await _picker.pickMultiImage();
    setState(() {
      _sizes[sizeIndex]['pickedImages'] = images;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      List<String> imageUrls = widget.product?.imageUrls ?? [];

      if (_pickedImages != null && _pickedImages!.isNotEmpty) {
        final uploadedUrls = await _uploadImages(_pickedImages!);
        imageUrls = uploadedUrls;
      }

      // Upload images for each size
      for (var size in _sizes) {
        if (size['pickedImages'] != null &&
            (size['pickedImages'] as List).isNotEmpty) {
          final uploadedUrls = await _uploadImages(
            List<XFile>.from(size['pickedImages']),
          );
          size['imageUrls'] = uploadedUrls;
        }
        size.remove('pickedImages');
      }

      final name = _nameCtrl.text.trim();
      final price = double.parse(_priceCtrl.text.trim());
      final description = _descCtrl.text.trim();
      final inStock = int.tryParse(_inStockCtrl.text.trim()) ?? 0;

      final docRef = widget.product == null
          ? FirebaseFirestore.instance.collection('products').doc()
          : FirebaseFirestore.instance
                .collection('products')
                .doc(widget.product!.id);

      await docRef.set({
        'name': name,
        'price': price,
        'imageUrls': imageUrls,
        'description': description,
        'inStock': inStock,
        'sizes': _sizes,
        'createdAt': widget.product == null
            ? FieldValue.serverTimestamp()
            : null,
      }, SetOptions(merge: true));

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving product: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use picked images if available, otherwise use product image URLs directly
    final imagesToShow = _pickedImages != null
        ? _pickedImages!
        : (widget.product?.imageUrls != null ? widget.product!.imageUrls! : []);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) =>
                    v != null && v.isNotEmpty ? null : 'Enter a name',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) => v != null && double.tryParse(v) != null
                    ? null
                    : 'Enter a valid price',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _inStockCtrl,
                decoration: const InputDecoration(labelText: 'In Stock Amount'),
                keyboardType: TextInputType.number,
                validator: (v) => v != null && int.tryParse(v) != null
                    ? null
                    : 'Enter a valid stock amount',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Text('Images:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imagesToShow.length + 1,
                  itemBuilder: (context, index) {
                    if (index == imagesToShow.length) {
                      return GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    }
                    final img = imagesToShow[index];
                    // If img is XFile (picked image)
                    if (img is XFile) {
                      if (img.path.startsWith('http')) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Image.network(
                            img.path, // <-- Add the missing URL argument
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        );
                      } else if (kIsWeb) {
                        // On web, display image from bytes
                        return FutureBuilder<Uint8List>(
                          future: img.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Image.memory(
                                  snapshot.data!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              );
                            } else {
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                          },
                        );
                      } else {
                        // Mobile: display from file path
                        final file = File(img.path);
                        return FutureBuilder<bool>(
                          future: file.exists(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              if (snapshot.data == true) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Image.file(
                                    file,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              } else {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.broken_image),
                                  ),
                                );
                              }
                            } else {
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                          },
                        );
                      }
                    }
                    // If img is String (URL from Firestore)
                    else if (img is String) {
                      final url = img;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Image.network(
                          url,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    // Fallback
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.broken_image)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text('Sizes:', style: Theme.of(context).textTheme.titleMedium),
              ..._sizes.asMap().entries.map((entry) {
                final i = entry.key;
                final size = entry.value;
                final sizeCtrl = TextEditingController(
                  text: size['size'] ?? '',
                );
                final priceCtrl = TextEditingController(
                  text: size['price']?.toString() ?? '',
                );
                final colorCtrl = TextEditingController(
                  text: size['color'] ?? '',
                );
                // Safely convert pickedImages to List<XFile>
                final pickedImagesRaw = size['pickedImages'] ?? [];
                final pickedImages = pickedImagesRaw is List<XFile>
                    ? pickedImagesRaw
                    : pickedImagesRaw is List
                    ? pickedImagesRaw
                          .where((img) => img is XFile)
                          .cast<XFile>()
                          .toList()
                    : <XFile>[];
                final imageUrls = size['imageUrls'] is List
                    ? (size['imageUrls'] as List)
                          .map((e) => e.toString())
                          .toList()
                    : <String>[];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: sizeCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Size',
                                ),
                                onChanged: (v) => size['size'] = v,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: priceCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) =>
                                    size['price'] = double.tryParse(v) ?? 0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: colorCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Color',
                                ),
                                onChanged: (v) => size['color'] = v,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() => _sizes.removeAt(i));
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // Show picked images (local)
                              ...pickedImages.map(
                                (img) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: kIsWeb
                                      ? FutureBuilder<Uint8List>(
                                          future: img.readAsBytes(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                    ConnectionState.done &&
                                                snapshot.hasData) {
                                              return Image.memory(
                                                snapshot.data!,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              );
                                            } else {
                                              return Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            }
                                          },
                                        )
                                      : Image.file(
                                          File(img.path),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              // Show uploaded images (URLs)
                              ...imageUrls.map(
                                (imgUrl) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Image.network(
                                    imgUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // Add button
                              GestureDetector(
                                onTap: () => _pickSizeImages(i),
                                child: Container(
                                  width: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.add_a_photo,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Size'),
                onPressed: () {
                  setState(() {
                    _sizes.add({
                      'size': '',
                      'price': 0.0,
                      'color': '', // Add color field
                      'imageUrls': [],
                      'pickedImages': [],
                    });
                  });
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.product == null ? 'Add Product' : 'Save Changes',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
