import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Smart Garage', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications)),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text('Driver'),
              accountEmail: Text('driver@example.com'),
              currentAccountPicture: CircleAvatar(backgroundImage: NetworkImage('https://via.placeholder.com/150')),
              decoration: BoxDecoration(gradient: LinearGradient(colors: AppColors.blueGradient)),
            ),
            ListTile(leading: const Icon(Icons.home), title: const Text('Home'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.build), title: const Text('Services'), onTap: () {}),
            ListTile(leading: const Icon(Icons.shopping_cart), title: const Text('Spare Parts'), onTap: () {}),
            ListTile(leading: const Icon(Icons.people), title: const Text('Mechanics'), onTap: () {}),
            ListTile(leading: const Icon(Icons.wallet), title: const Text('Wallet'), onTap: () {}),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await context.read<AuthController>().logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.blueGradient),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Good morning, Driver!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Toyota Crown - T 238 DJF', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CarouselSlider(
              items: [1,2,3].map((i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: Center(child: Text('Ad $i')),
              )).toList(),
              options: CarouselOptions(height: 120, autoPlay: true),
            ),
            const SizedBox(height: 20),
            const Text('Our Services', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _serviceCard(Icons.build, 'Services', AppColors.primaryBlue),
                _serviceCard(Icons.shopping_cart, 'Spare Parts', AppColors.accentOrange),
                _serviceCard(Icons.biotech, 'AI Diagnosis', AppColors.accentGreen),
                _serviceCard(Icons.people, 'Find Mechanic', AppColors.primaryDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard(IconData icon, String title, Color color) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6)]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 30)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
