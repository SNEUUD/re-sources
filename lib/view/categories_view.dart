import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart';
import 'category_ressources_page.dart';

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

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late Future<List<Category>> futureCategories;
  final TextEditingController _searchController = TextEditingController();
  List<Category> allCategories = [];
  List<Category> filteredCategories = [];
  bool showAllCategories = false;

  @override
  void initState() {
    super.initState();
    futureCategories = fetchCategories();
    futureCategories.then((categories) {
      setState(() {
        allCategories = categories;
        filteredCategories = categories;
      });
    });

    _searchController.addListener(() {
      filterCategories(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void filterCategories(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredCategories = allCategories;
      });
    } else {
      setState(() {
        filteredCategories =
            allCategories
                .where(
                  (category) => category.nomCategorie.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
                )
                .toList();
      });
    }
  }

  Future<List<Category>> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('http://chris-crp.freeboxos.fr/api/categories'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception(
          'Échec de chargement des catégories: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Color getCategoryColor(int index) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.amber,
      Colors.blue,
    ];
    return colors[index % colors.length];
  }

  Color getCategoryBgColor(int index) {
    final colors = [
      Colors.blue.shade50,
      Colors.red.shade50,
      Colors.blue.shade50,
      Colors.green.shade50,
      Colors.amber.shade50,
      Colors.blue.shade50,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomePage()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF0000CC),
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Retour',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF0000CC),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Catégories',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0000CC),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Parcourez l\'ensemble des catégories disponibles pour explorer les thématiques proposées. Chaque catégorie regroupe des ressources spécifiques pour vous aider à mieux comprendre un sujet ou approfondir vos connaissances. Utilisez la barre de recherche pour filtrer rapidement selon vos centres d'intérêt.",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Rechercher : ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Rechercher une catégorie',
                          border: InputBorder.none,
                          suffixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<Category>>(
                  future: futureCategories,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Erreur: ${snapshot.error}'));
                    } else if (!snapshot.hasData ||
                        filteredCategories.isEmpty) {
                      return const Center(
                        child: Text('Aucune catégorie trouvée'),
                      );
                    } else {
                      List<Category> categoriesToDisplay =
                          showAllCategories
                              ? filteredCategories
                              : filteredCategories.take(6).toList();

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 2.5,
                        ),
                        itemCount: categoriesToDisplay.length,
                        itemBuilder: (context, index) {
                          final category = categoriesToDisplay[index];
                          return _buildCategoryCard(
                            category.nomCategorie,
                            category.description,
                            getCategoryBgColor(index),
                            getCategoryColor(index),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
              if (filteredCategories.length > 6)
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showAllCategories = !showAllCategories;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0000CC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      showAllCategories ? 'Voir moins' : 'En voir plus',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    String description,
    Color bgColor,
    Color buttonColor,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryResourcesPage(nomCategorie: title),
          ),
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        color: bgColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IntrinsicHeight(
            // Permet d'ajuster la hauteur au contenu
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0000CC),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  CategoryResourcesPage(nomCategorie: title),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0000CC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: const Size(100, 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Voir les ressources liées',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
