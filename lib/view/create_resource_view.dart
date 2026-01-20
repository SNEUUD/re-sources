import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class Category {
  final String nomCategorie;
  final String description;

  Category({required this.nomCategorie, required this.description});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      nomCategorie: json['nomCatégorie'],
      description: json['descriptionCatégorie'],
    );
  }
}

class CreateResourcePage extends StatefulWidget {
  const CreateResourcePage({super.key});

  @override
  _CreateResourcePageState createState() => _CreateResourcePageState();
}

class _CreateResourcePageState extends State<CreateResourcePage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _message = '';
  final DateTime _selectedDate = DateTime.now();
  Uint8List? _selectedImageBytes;
  String? _utilisateurId;
  String _status = 'masque'; // <-- Forcé à 'masque'
  String _category = 'Musique';
  bool isLoading = false;

  late Future<List<Category>> futureCategories;
  List<Category> categories = [];

  // Couleurs du Design System de l'État
  static const Color bleuFrance = Color(0xFF000091);
  static const Color rougeMarianne = Color(0xFFE1000F);
  static const Color grisFrance = Color(0xFF666666);
  static const Color grisClair = Color(0xFFF6F6F6);

  @override
  void initState() {
    super.initState();
    futureCategories = fetchCategories();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('idUtilisateur');
    setState(() {
      _utilisateurId = userId;
    });
  }

  Future<List<Category>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('http://chris-crp.freeboxos.fr/api/categories'),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de chargement: ${response.statusCode}');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_utilisateurId == null || _utilisateurId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non identifié')),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => isLoading = true);

    final String? imageBase64 =
        _selectedImageBytes != null ? base64Encode(_selectedImageBytes!) : null;

    final response = await http.post(
      Uri.parse('http://chris-crp.freeboxos.fr/api/resources'),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': _title,
        'message': _message,
        'date': _selectedDate.toIso8601String(),
        'image': imageBase64,
        'userId': _utilisateurId,
        'status': _status,
        'category': _category,
      }),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 201) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ressource ajoutée avec succès !')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur : ${jsonDecode(response.body)['error'] ?? 'Inconnue'}',
          ),
        ),
      );
    }
  }

  bool _categoryExists(String category, List<Category> categories) {
    return categories.any((cat) => cat.nomCategorie == category);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;
    final maxWidth = isDesktop ? 800.0 : (isTablet ? 600.0 : double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Créer une ressource',
          style: TextStyle(color: bleuFrance, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: bleuFrance,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: bleuFrance),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E5E5)),
        ),
      ),
      backgroundColor: grisClair,
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
            child: Container(
              padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Titre de la page
                    Text(
                      'Nouvelle ressource',
                      style: TextStyle(
                        fontSize: isDesktop ? 28 : 24,
                        fontWeight: FontWeight.w700,
                        color: bleuFrance,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Partagez une ressource avec la communauté',
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : 14,
                        color: grisFrance,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Champ titre
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Intitulé *',
                        labelStyle: TextStyle(color: grisFrance),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: grisFrance.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: bleuFrance,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.all(isDesktop ? 16 : 12),
                      ),
                      style: TextStyle(fontSize: isDesktop ? 16 : 14),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Veuillez entrer un titre'
                                  : null,
                      onSaved: (value) => _title = value!,
                    ),
                    const SizedBox(height: 24),

                    // Champ message
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Message *',
                        labelStyle: TextStyle(color: grisFrance),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: grisFrance.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: bleuFrance,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.all(isDesktop ? 16 : 12),
                        alignLabelWithHint: true,
                      ),
                      maxLines: isDesktop ? 6 : 5,
                      style: TextStyle(fontSize: isDesktop ? 16 : 14),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Veuillez entrer un message'
                                  : null,
                      onSaved: (value) => _message = value!,
                    ),
                    const SizedBox(height: 24),

                    // Sélection de catégorie
                    FutureBuilder<List<Category>>(
                      future: futureCategories,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            height: isDesktop ? 64 : 56,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: grisFrance.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  bleuFrance,
                                ),
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Container(
                            padding: EdgeInsets.all(isDesktop ? 16 : 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: rougeMarianne.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: rougeMarianne.withOpacity(0.05),
                            ),
                            child: Text(
                              'Erreur: ${snapshot.error}',
                              style: TextStyle(
                                color: rougeMarianne,
                                fontSize: isDesktop ? 14 : 12,
                              ),
                            ),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Container(
                            padding: EdgeInsets.all(isDesktop ? 16 : 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: grisFrance.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Aucune catégorie disponible',
                              style: TextStyle(
                                color: grisFrance,
                                fontSize: isDesktop ? 14 : 12,
                              ),
                            ),
                          );
                        } else {
                          categories = snapshot.data!;
                          if (!_categoryExists(_category, categories)) {
                            _category = categories.first.nomCategorie;
                          }
                          return DropdownButtonFormField<String>(
                            value: _category,
                            decoration: InputDecoration(
                              labelText: 'Catégorie *',
                              labelStyle: TextStyle(color: grisFrance),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: grisFrance.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: bleuFrance,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.all(
                                isDesktop ? 16 : 12,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: isDesktop ? 16 : 14,
                              color: Colors.black87,
                            ),
                            items:
                                categories
                                    .map(
                                      (cat) => DropdownMenuItem<String>(
                                        value: cat.nomCategorie,
                                        child: Text(cat.nomCategorie),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _category = newValue!;
                              });
                            },
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Section image
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 20 : 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              _selectedImageBytes != null
                                  ? bleuFrance.withOpacity(0.3)
                                  : grisFrance.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color:
                            _selectedImageBytes != null
                                ? bleuFrance.withOpacity(0.02)
                                : Colors.grey.withOpacity(0.02),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: Icon(
                                  Icons.image,
                                  size: isDesktop ? 20 : 18,
                                ),
                                label: Text(
                                  _selectedImageBytes != null
                                      ? 'Modifier l\'image'
                                      : 'Ajouter une image',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 16 : 14,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: bleuFrance,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isDesktop ? 24 : 16,
                                    vertical: isDesktop ? 12 : 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              if (_selectedImageBytes != null) ...[
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Image ajoutée',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: isDesktop ? 14 : 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (_selectedImageBytes != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              constraints: BoxConstraints(
                                maxHeight: isDesktop ? 200 : 150,
                                maxWidth: double.infinity,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: grisFrance.withOpacity(0.2),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  _selectedImageBytes!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bouton de soumission
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _submitForm,
                        icon:
                            isLoading
                                ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                )
                                : Icon(Icons.send, size: isDesktop ? 20 : 18),
                        label: Text(
                          isLoading
                              ? 'Enregistrement...'
                              : 'Enregistrer la ressource',
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLoading ? grisFrance : bleuFrance,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isDesktop ? 16 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: isLoading ? 0 : 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
