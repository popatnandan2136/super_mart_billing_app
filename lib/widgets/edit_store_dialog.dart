import 'package:flutter/material.dart';
import '../providers/cart_provider.dart';

class EditStoreDialog extends StatefulWidget {
  final CartProvider cart;
  final bool isFirstTime;

  const EditStoreDialog({
    super.key,
    required this.cart,
    this.isFirstTime = false,
  });

  static Future<void> show(BuildContext context, CartProvider cart, {bool isFirstTime = false}) {
    return showDialog(
      context: context,
      barrierDismissible: !isFirstTime,
      builder: (_) => EditStoreDialog(cart: cart, isFirstTime: isFirstTime),
    );
  }

  @override
  State<EditStoreDialog> createState() => _EditStoreDialogState();
}

class _EditStoreDialogState extends State<EditStoreDialog> {
  late TextEditingController _nameController;
  late String _selectedState;
  late String _selectedCity;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.cart.storeName);
    _selectedState = CartProvider.stateCityMap.containsKey(widget.cart.storeState)
        ? widget.cart.storeState
        : CartProvider.stateCityMap.keys.first;

    final citiesForState = CartProvider.stateCityMap[_selectedState] ?? ['Rajkot'];
    _selectedCity = citiesForState.contains(widget.cart.storeCity) ? widget.cart.storeCity : citiesForState.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableStates = CartProvider.stateCityMap.keys.toList();
    final availableCities = CartProvider.stateCityMap[_selectedState] ?? ['Rajkot'];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F9D58).withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_rounded, color: Color(0xFF0F9D58), size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.isFirstTime ? "Welcome! Setup Store" : "Edit Store Details",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isFirstTime)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  "Please enter your Store Name and location for generating professional receipts.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

            // Shop Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Shop / Store Name",
                hintText: "e.g. SUPER MART",
                prefixIcon: const Icon(Icons.store_rounded, color: Color(0xFF0F9D58)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // State Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedState,
              decoration: InputDecoration(
                labelText: "Select State",
                prefixIcon: const Icon(Icons.map_rounded, color: Color(0xFF0F9D58)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: availableStates.map((state) {
                return DropdownMenuItem(
                  value: state,
                  child: Text(state),
                );
              }).toList(),
              onChanged: (newState) {
                if (newState != null) {
                  setState(() {
                    _selectedState = newState;
                    final cities = CartProvider.stateCityMap[newState] ?? ['Rajkot'];
                    _selectedCity = cities.first;
                  });
                }
              },
            ),
            const SizedBox(height: 14),

            // City Dropdown
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedState),
              initialValue: _selectedCity,
              decoration: InputDecoration(
                labelText: "Select City",
                prefixIcon: const Icon(Icons.location_city_rounded, color: Color(0xFF0F9D58)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: availableCities.map((city) {
                return DropdownMenuItem(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (newCity) {
                if (newCity != null) {
                  setState(() {
                    _selectedCity = newCity;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        if (!widget.isFirstTime)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ElevatedButton.icon(
          onPressed: () async {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter a shop name")),
              );
              return;
            }

            await widget.cart.updateStoreSettings(name, _selectedCity, _selectedState);
            if (!context.mounted) return;
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Store details updated to '$name, $_selectedCity'!"),
                backgroundColor: const Color(0xFF0F9D58),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.check_circle_rounded),
          label: Text(widget.isFirstTime ? "Get Started" : "Save Details"),
        ),
      ],
    );
  }
}
