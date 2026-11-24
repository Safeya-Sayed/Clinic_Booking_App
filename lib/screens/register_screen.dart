import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'widgets/auth/auth_header.dart';
import 'widgets/auth/auth_text_field.dart';
import 'widgets/auth/primary_auth_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
    );
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Please sign in.'), behavior: SnackBarBehavior.floating),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), behavior: SnackBarBehavior.floating),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
const AuthHeader(
title: 'Create Account',
subtitle: 'Create a patient account to book your clinic visits.',
showIcon: false,
),
const SizedBox(height: 32),
AuthTextField(
controller: _nameController,
label: 'Full name',
hint: 'Your name',
icon: Icons.person_outline_rounded,
validator: (value) {
if (value == null || value.trim().isEmpty) return 'Name is required';
if (value.trim().length < 3) return 'Name is too short';
return null;
},
),
const SizedBox(height: 15),
AuthTextField(
controller: _emailController,
label: 'Email',
hint: 'name@example.com',
icon: Icons.email_outlined,
keyboardType: TextInputType.emailAddress,
validator: (value) {
if (value == null || value.trim().isEmpty) return 'Email is required';
if (!value.contains('@')) return 'Enter a valid email address';
return null;
},
),
const SizedBox(height: 15),
AuthTextField(
controller: _phoneController,
label: 'Phone',
hint: '01XXXXXXXXX',
icon: Icons.phone_outlined,
keyboardType: TextInputType.phone,
validator: (value) {
if (value == null || value.trim().isEmpty) return 'Phone is required';
if (value.trim().length < 11) return 'Enter a valid phone number';
return null;
},
),
const SizedBox(height: 15),
AuthTextField(
controller: _passwordController,
label: 'Password',
hint: 'Create a password',
icon: Icons.lock_outline_rounded,
obscureText: true,
validator: (value) {
if (value == null || value.isEmpty) return 'Password is required';
if (value.length < 6) return 'Use at least 6 characters';
return null;
},
),
const SizedBox(height: 24),
PrimaryAuthButton(
label: 'Create Account',
isLoading: auth.isLoading,
onPressed: () => _submit(auth),
),
const SizedBox(height: 14),
Center(
child: TextButton(
onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
child: const Text('Already have an account? Log In'),
),
),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}