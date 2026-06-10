import 'package:flutter/material.dart';
import 'package:valortrash/services/firebase_service.dart'; 
import 'package:valortrash/screens/home_page.dart';         
import 'package:valortrash/screens/auth/signup_screen.dart'; 

// --- Page Connexion ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  void _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) { setState(() => _errorMessage = "Champs vides"); return; }
    
    String? role = await FirebaseService().login(email, password);
    
    if (!mounted) return;
    
    if (role != null) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => HomePage(role: role, email: email))
      );
    } else {
      setState(() => _errorMessage = "Identifiants incorrects");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion"), backgroundColor: const Color(0xFF008B8B), foregroundColor: Colors.white),
      body: Padding(padding: const EdgeInsets.all(24.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 10),
        TextField(controller: _emailController, decoration: InputDecoration(hintText: "Email", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
        const SizedBox(height: 15),
        TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(hintText: "Mot de passe", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _handleLogin, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008B8B)), child: const Text("Se connecter"))),
        TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())), child: const Text("S'inscrire"))
      ])),
    );
  }
}