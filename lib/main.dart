import 'package:flutter/material.dart';
import 'package:my_store_admin_pane/screens/products/products_list_page.dart';
import 'config/firebase_init.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/create_admin_page.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.init();

  runApp(const AdminPanelApp());
}

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Panel',
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/login', // Change initial route back to login
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/products': (context) => const ProductListPage(),
        '/create-admin': (context) => const CreateAdminPage(),
      },
    );
  }
}
