import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'screens/product_list_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SuperMartBillingApp());
}


class SuperMartBillingApp extends StatelessWidget {
  const SuperMartBillingApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Super Mart Billing App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const ProductListScreen(),
      ),
    );
  }
}