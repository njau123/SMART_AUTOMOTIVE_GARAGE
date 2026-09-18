import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.blueGradient),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: const Icon(Icons.car_repair, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 40),
                  const Text('Welcome Back!', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Text('Sign in to continue', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 30),
                  AuthTextField(controller: _emailCtrl, label: 'Email Address', prefixIcon: Icons.email, keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Enter email' : null),
                  const SizedBox(height: 16),
                  AuthTextField(controller: _passCtrl, label: 'Password', prefixIcon: Icons.lock, obscureText: true, validator: (v) => v!.isEmpty ? 'Enter password' : null),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pushNamed(context, '/forgot-password'), child: const Text('Forgot Password?'))),
                  const SizedBox(height: 20),
                  AuthButton(
                    text: 'Sign In',
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final authCtrl = context.read<AuthController>();
                        final success = await authCtrl.login(_emailCtrl.text, _passCtrl.text);
                        if (success && context.mounted) {
                          Navigator.pushReplacementNamed(context, '/home');
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authCtrl.error ?? 'Login failed'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    isLoading: context.watch<AuthController>().isLoading,
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.grey.shade300)),
                  ),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text("Don't have an account? "),
                    GestureDetector(onTap: () => Navigator.pushNamed(context, '/signup'), child: const Text('Sign Up', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold))),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
