import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:resources/main.dart';
import 'dart:convert';

import 'package:resources/view/auth/login_view.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _birthDateController = TextEditingController();

  String? _gender;

  final _formKey = GlobalKey<FormState>();

  // Couleurs inspirées du DSFR (Système de Design de l'État français)
  static const Color _primaryBlue = Color(0xFF000091);
  static const Color _lightBlue = Color(0xFFE3E3FD);
  static const Color _darkGray = Color(0xFF161616);
  static const Color _mediumGray = Color(0xFF666666);
  static const Color _lightGray = Color(0xFFF6F6F6);
  static const Color _borderGray = Color(0xFFDDD);
  static const Color _errorRed = Color(0xFFCE0500);
  static const Color _successGreen = Color(0xFF18753C);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _darkGray,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      final url = Uri.parse('http://chris-crp.freeboxos.fr/api/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nomUtilisateur': _lastNameController.text.trim(),
          'prénomUtilisateur': _firstNameController.text.trim(),
          'dateNaissanceUtilisateur': _birthDateController.text.trim(),
          'sexeUtilisateur': _gender,
          'pseudoUtilisateur': _usernameController.text.trim(),
          'emailUtilisateur': _emailController.text.trim(),
          'motDePasseUtilisateur': _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text("Inscription réussie !"),
              ],
            ),
            backgroundColor: _successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("Erreur: ${jsonDecode(response.body)['error']}"),
                ),
              ],
            ),
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    String? Function(String?)? validator,
    String? hint,
    IconData? prefixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _darkGray,
                fontFamily:
                    'Marianne', // Police officielle du gouvernement français
              ),
              children: [
                TextSpan(text: label.replaceAll('*', '')),
                if (label.contains('*'))
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: _errorRed),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              validator: validator,
              style: const TextStyle(fontSize: 16, color: _darkGray),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: _mediumGray.withOpacity(0.7),
                  fontSize: 16,
                ),
                prefixIcon:
                    prefixIcon != null
                        ? Icon(prefixIcon, color: _mediumGray, size: 20)
                        : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _borderGray, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _borderGray, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _primaryBlue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _errorRed, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _errorRed, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _darkGray,
              ),
              children: [
                TextSpan(text: 'Date de naissance'),
                TextSpan(text: ' *', style: TextStyle(color: _errorRed)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _birthDateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une date de naissance';
                }
                if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) {
                  return 'Veuillez entrer une date au format JJ/MM/AAAA';
                }
                return null;
              },
              style: const TextStyle(fontSize: 16, color: _darkGray),
              decoration: InputDecoration(
                hintText: 'JJ/MM/AAAA',
                hintStyle: TextStyle(
                  color: _mediumGray.withOpacity(0.7),
                  fontSize: 16,
                ),
                prefixIcon: const Icon(
                  Icons.calendar_today,
                  color: _mediumGray,
                  size: 20,
                ),
                suffixIcon: const Icon(
                  Icons.arrow_drop_down,
                  color: _mediumGray,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _borderGray, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _borderGray, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _primaryBlue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _errorRed, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _darkGray,
              ),
              children: [
                TextSpan(text: 'Sexe'),
                TextSpan(text: ' *', style: TextStyle(color: _errorRed)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderGray),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _gender = 'M'),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'M',
                            groupValue: _gender,
                            onChanged: (String? value) {
                              setState(() {
                                _gender = value;
                              });
                            },
                            activeColor: _primaryBlue,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Masculin',
                            style: TextStyle(fontSize: 16, color: _darkGray),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _gender = 'F'),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'F',
                            groupValue: _gender,
                            onChanged: (String? value) {
                              setState(() {
                                _gender = value;
                              });
                            },
                            activeColor: _primaryBlue,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Féminin',
                            style: TextStyle(fontSize: 16, color: _darkGray),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      appBar: AppBar(
        title: const Text(
          "Inscription",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _primaryBlue,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryBlue),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête avec dégradé
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add,
                      size: 32,
                      color: _primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Créer votre compte",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: _primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Remplissez le formulaire ci-dessous pour créer votre compte",
                    style: TextStyle(
                      fontSize: 16,
                      color: _primaryBlue,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Formulaire
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Indication des champs obligatoires
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: _lightBlue,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _primaryBlue.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: _primaryBlue,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Les champs marqués d'un astérisque (*) sont obligatoires",
                              style: TextStyle(
                                fontSize: 14,
                                color: _primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildTextField(
                      "Adresse e-mail*",
                      _emailController,
                      hint: "exemple@domaine.fr",
                      prefixIcon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une adresse e-mail';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Veuillez entrer une adresse e-mail valide';
                        }
                        return null;
                      },
                    ),

                    _buildTextField(
                      "Prénom*",
                      _firstNameController,
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre prénom';
                        }
                        if (value.length > 45) {
                          return 'Le prénom ne doit pas dépasser 45 caractères';
                        }
                        return null;
                      },
                    ),

                    _buildTextField(
                      "Nom*",
                      _lastNameController,
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre nom';
                        }
                        if (value.length > 255) {
                          return 'Le nom ne doit pas dépasser 255 caractères';
                        }
                        return null;
                      },
                    ),

                    _buildTextField(
                      "Pseudo*",
                      _usernameController,
                      prefixIcon: Icons.alternate_email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un pseudo';
                        }
                        if (value.length > 45) {
                          return 'Le pseudo ne doit pas dépasser 45 caractères';
                        }
                        return null;
                      },
                    ),

                    _buildDateField(),

                    _buildGenderSelection(),

                    _buildTextField(
                      "Mot de passe*",
                      _passwordController,
                      obscure: true,
                      prefixIcon: Icons.lock_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un mot de passe';
                        }
                        if (value.length > 255) {
                          return 'Le mot de passe ne doit pas dépasser 255 caractères';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Bouton d'inscription
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "S'inscrire",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
