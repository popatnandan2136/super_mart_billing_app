import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'bill_preview_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final cart = Provider.of<CartProvider>(context, listen: false);
    _nameController = TextEditingController(text: cart.customerName == "Guest Customer" ? "" : cart.customerName);
    _phoneController = TextEditingController(text: cart.customerPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cart & Billing"),
        actions: [
          if (cart.cartItemsList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: "Clear Cart",
              onPressed: () {
                _showClearCartDialog(context, cart);
              },
            ),
        ],
      ),
      body: cart.cartItemsList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_shopping_cart_rounded, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    "Your cart is empty!",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Add products from the home screen to generate a bill",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text("Go to Product List"),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Customer Info Card ---
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.person_rounded, color: Color(0xFF0F9D58)),
                              SizedBox(width: 8),
                              Text(
                                "Customer Details (Optional)",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  onChanged: (val) {
                                    cart.setCustomerInfo(val, _phoneController.text);
                                  },
                                  decoration: InputDecoration(
                                    labelText: "Customer Name",
                                    prefixIcon: const Icon(Icons.badge_rounded, size: 20),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  onChanged: (val) {
                                    cart.setCustomerInfo(_nameController.text, val);
                                  },
                                  decoration: InputDecoration(
                                    labelText: "Phone Number",
                                    prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Items Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Cart Items",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        "${cart.totalItemCount} Items",
                        style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // --- Cart Items ListView ---
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cart.cartItemsList.length,
                    itemBuilder: (context, index) {
                      final item = cart.cartItemsList[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Icon
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: item.product.color.withAlpha(30),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      item.product.icon,
                                      color: item.product.color,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name, Unit Price
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Unit Price: ${item.product.formattedPrice}",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Total Item Price
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "₹${item.totalPrice.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F9D58),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: () {
                                          cart.removeFromCart(item.product.id);
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Text(
                                            "Remove",
                                            style: TextStyle(
                                              fontSize: 12,
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

                              const Divider(height: 16),

                              // Quantity Controls
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Quantity: ${item.quantity} ${item.product.unit}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            cart.updateQuantity(item.product.id, -1);
                                          },
                                          icon: const Icon(Icons.remove_rounded, color: Colors.redAccent, size: 18),
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            cart.updateQuantity(item.product.id, 1);
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
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // --- Calculation Summary Card ---
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.receipt_long_rounded, color: Color(0xFF0F9D58)),
                              SizedBox(width: 8),
                              Text(
                                "Bill Calculation",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Subtotal
                          _buildSummaryRow(
                            "Subtotal",
                            "₹${cart.subtotal.toStringAsFixed(2)}",
                          ),
                          const SizedBox(height: 10),

                          // GST (18%)
                          _buildSummaryRow(
                            "GST (18%)",
                            "₹${cart.gst.toStringAsFixed(2)}",
                            subtitle: "18% Goods & Services Tax",
                          ),
                          const SizedBox(height: 10),

                          // Discount
                          _buildSummaryRow(
                            "Discount (${cart.discountPercent}%)",
                            "- ₹${cart.discount.toStringAsFixed(2)}",
                            isDiscount: true,
                            subtitle: cart.subtotal > 1000
                                ? "🎉 10% Special Discount (Subtotal > ₹1000)"
                                : "💡 5% Standard Discount (Spend > ₹1000 for 10%)",
                          ),

                          const Divider(height: 24),

                          // Grand Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Grand Total",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                "₹${cart.grandTotal.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F9D58),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Proceed Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BillPreviewScreen()),
                        );
                      },
                      icon: const Icon(Icons.receipt_rounded, size: 22),
                      label: const Text("Generate & Preview Bill"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String title, String amount, {bool isDiscount = false, String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isDiscount ? FontWeight.bold : FontWeight.w500,
                color: isDiscount ? Colors.redAccent : const Color(0xFF475569),
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDiscount ? Colors.redAccent : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDiscount ? Colors.orange.shade800 : Colors.grey.shade600,
              fontWeight: isDiscount ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ],
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Cart"),
        content: const Text("Are you sure you want to remove all items from the cart?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(ctx);
            },
            child: const Text("Clear", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
