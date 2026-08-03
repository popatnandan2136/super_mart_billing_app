import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product_model.dart';
import '../widgets/edit_store_dialog.dart';
import 'cart_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cart = Provider.of<CartProvider>(context, listen: false);
      await cart.loadStoreSettings();
      if (cart.isFirstInstall && mounted) {
        await cart.markFirstInstallDone();
        if (mounted) {
          EditStoreDialog.show(context, cart, isFirstTime: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductFormDialog(BuildContext context, CartProvider cart, {Product? existingProduct}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingProduct?.name ?? '');
    final priceController = TextEditingController(
      text: existingProduct != null ? existingProduct.price.toStringAsFixed(0) : '',
    );
    String selectedUnit = existingProduct?.unit ?? 'pack';
    IconData selectedIcon = existingProduct?.icon ?? Icons.shopping_bag_rounded;
    Color selectedColor = existingProduct?.color ?? const Color(0xFF0F9D58);

    final isEditing = existingProduct != null;

    final availableIcons = [
      Icons.shopping_bag_rounded,
      Icons.local_cafe_rounded,
      Icons.sanitizer_rounded,
      Icons.fastfood_rounded,
      Icons.breakfast_dining_rounded,
      Icons.cookie_rounded,
      Icons.set_meal_rounded,
      Icons.opacity_rounded,
      Icons.local_grocery_store_rounded,
    ];

    final availableColors = [
      const Color(0xFF0F9D58), // Emerald Green
      const Color(0xFF1E88E5), // Blue
      const Color(0xFFFB8C00), // Orange
      const Color(0xFF8E24AA), // Purple
      const Color(0xFF00ACC1), // Teal
      const Color(0xFFD81B60), // Pink
      const Color(0xFF7CB342), // Light Green
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isEditing ? Icons.edit_note_rounded : Icons.add_shopping_cart_rounded,
                                color: const Color(0xFF0F9D58),
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isEditing ? "Edit Product" : "Add New Product",
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Name Input with Validation Error
                      TextFormField(
                        controller: nameController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Please enter product name";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: "Product Name *",
                          hintText: "e.g. Coffee, Sunflower Oil",
                          prefixIcon: const Icon(Icons.label_rounded, color: Color(0xFF0F9D58)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Price & Unit Row with Validation Error
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return "Please enter price";
                                }
                                final p = double.tryParse(val.trim());
                                if (p == null || p <= 0) {
                                  return "Enter valid price";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: "Price (₹) *",
                                hintText: "e.g. 150",
                                prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF0F9D58)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedUnit,
                              decoration: InputDecoration(
                                labelText: "Unit",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'pack', child: Text("pack")),
                                DropdownMenuItem(value: 'kg', child: Text("kg")),
                                DropdownMenuItem(value: 'litre', child: Text("litre")),
                                DropdownMenuItem(value: 'item', child: Text("item")),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() {
                                    selectedUnit = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Icon Picker
                      const Text(
                        "Select Product Icon",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableIcons.map((icon) {
                          final isSelected = selectedIcon == icon;
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedIcon = icon;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? selectedColor.withAlpha(40) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? selectedColor : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Icon(icon, color: isSelected ? selectedColor : Colors.grey.shade600, size: 24),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Color Picker
                      const Text(
                        "Select Color Tag",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children: availableColors.map((color) {
                          final isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedColor = color;
                              });
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected ? Border.all(color: Colors.black, width: 2.5) : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Save/Update Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            final name = nameController.text.trim();
                            final price = double.parse(priceController.text.trim());

                            if (isEditing) {
                              final updatedProduct = Product(
                                id: existingProduct.id,
                                name: name,
                                price: price,
                                unit: selectedUnit,
                                icon: selectedIcon,
                                color: selectedColor,
                                isCustom: existingProduct.isCustom,
                              );
                              await cart.updateProduct(updatedProduct);
                            } else {
                              final newProduct = Product(
                                id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                                name: name,
                                price: price,
                                unit: selectedUnit,
                                icon: selectedIcon,
                                color: selectedColor,
                                isCustom: true,
                              );
                              await cart.addProduct(newProduct);
                            }

                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEditing ? "'$name' updated successfully!" : "'$name' saved to local database!"),
                                backgroundColor: const Color(0xFF0F9D58),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          icon: Icon(isEditing ? Icons.update_rounded : Icons.save_rounded),
                          label: Text(isEditing ? "Update Product" : "Save Product to Local DB"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    // Filter products based on search
    final filteredProducts = cart.availableProducts.where((p) {
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              cart.storeName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              cart.storeAddress,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt_rounded, size: 24),
            tooltip: "Edit Store Details",
            onPressed: () => EditStoreDialog.show(context, cart),
          ),
          IconButton(
            icon: const Icon(Icons.add_box_rounded, size: 26),
            tooltip: "Add Custom Product",
            onPressed: () => _showProductFormDialog(context, cart),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_rounded, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              if (cart.totalItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${cart.totalItemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: cart.isLoading
          ? const Center(child: CircularProgressIndicator())
          : NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (notification.direction == ScrollDirection.reverse) {
                  if (_isFabVisible) {
                    setState(() {
                      _isFabVisible = false;
                    });
                  }
                } else if (notification.direction == ScrollDirection.forward) {
                  if (!_isFabVisible) {
                    setState(() {
                      _isFabVisible = true;
                    });
                  }
                }
                return true;
              },
              child: Column(
                children: [
                  // Banner & Search Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withAlpha(20),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.storefront_rounded, color: Color(0xFF0F9D58), size: 28),
                                SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Fresh Products & Daily Essentials",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      "Select items to create a quick bill",
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Search TextField
                        TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Search products (e.g. Milk, Rice)...",
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0F9D58)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF0F9D58), width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Product List Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Product Catalogue",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${filteredProducts.length} Items",
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Product ListView
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  "No products found",
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              final qtyInCart = cart.getQuantity(product.id);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Product Icon
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: product.color.withAlpha(30),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          product.icon,
                                          color: product.color,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Name & Price
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    product.name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                ),
                                                if (product.isCustom)
                                                  Container(
                                                    margin: const EdgeInsets.only(left: 4),
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.shade50,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: Colors.blue.shade200),
                                                    ),
                                                    child: Text(
                                                      "Custom",
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.blue.shade800,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                Text(
                                                  product.formattedPrice,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF0F9D58),
                                                  ),
                                                ),
                                                // Edit Button
                                                InkWell(
                                                  onTap: () {
                                                    _showProductFormDialog(context, cart, existingProduct: product);
                                                  },
                                                  child: const Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.edit_rounded, size: 13, color: Colors.blue),
                                                        SizedBox(width: 2),
                                                        Text(
                                                          "Edit",
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.blue,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                if (product.isCustom)
                                                  // Delete Button for custom items
                                                  InkWell(
                                                    onTap: () {
                                                      _confirmDeleteProduct(context, cart, product);
                                                    },
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                      child: Text(
                                                        "Delete",
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.redAccent,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Quantity Controls (+ / -)
                                      if (qtyInCart == 0)
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            cart.addToCart(product);
                                          },
                                          icon: const Icon(Icons.add_rounded, size: 18),
                                          label: const Text("ADD"),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        )
                                      else
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  cart.updateQuantity(product.id, -1);
                                                },
                                                icon: const Icon(Icons.remove_rounded, color: Colors.redAccent, size: 18),
                                                padding: const EdgeInsets.all(4),
                                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text(
                                                  '$qtyInCart',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  cart.updateQuantity(product.id, 1);
                                                },
                                                icon: const Icon(Icons.add_rounded, color: Color(0xFF0F9D58), size: 18),
                                                padding: const EdgeInsets.all(4),
                                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isFabVisible ? 1.0 : 0.0,
          child: FloatingActionButton.extended(
            onPressed: () => _showProductFormDialog(context, cart),
            icon: const Icon(Icons.add_rounded),
            label: const Text("Add Product"),
          ),
        ),
      ),
      bottomNavigationBar: cart.totalItemCount == 0
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${cart.totalItemCount} Items added",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            "Subtotal: ₹${cart.subtotal.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F9D58),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart_checkout_rounded),
                      label: const Text("View Cart"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, CartProvider cart, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete '${product.name}'?"),
        content: const Text("This product will be permanently removed from the local database."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await cart.removeProduct(product.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("'${product.name}' deleted from database.")),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
