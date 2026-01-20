import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ResourcesUserView extends StatefulWidget {
  const ResourcesUserView({super.key});

  @override
  State<ResourcesUserView> createState() => _ResourcesUserViewState();
}

class _ResourcesUserViewState extends State<ResourcesUserView>
    with TickerProviderStateMixin {
  List<dynamic> ressources = [];
  bool isLoading = true;
  late AnimationController _animationController;
  late AnimationController _fabController;
  String _searchQuery = '';
  String _selectedFilter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    fetchUserRessources();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> fetchUserRessources() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('idUtilisateur');

    if (userId == null) {
      setState(() => isLoading = false);
      _showSnackBar('Utilisateur non connecté', Colors.red);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://chris-crp.freeboxos.fr/api/ressources/user/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          ressources = data['ressources'];
          isLoading = false;
        });
        _animationController.forward();
        _fabController.forward();
      } else {
        throw Exception('Erreur serveur : ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Erreur : $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> deleteRessource(int idRessource, String titre) async {
    final confirm = await _showDeleteDialog(titre);

    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse(
            'http://chris-crp.freeboxos.fr/api/ressources/$idRessource',
          ),
        );

        if (response.statusCode == 200) {
          _showSnackBar('Ressource supprimée avec succès', Colors.green);
          fetchUserRessources();
        } else {
          throw Exception('Erreur : ${response.statusCode}');
        }
      } catch (e) {
        _showSnackBar('Erreur : $e', Colors.red);
      }
    }
  }

  Future<bool?> _showDeleteDialog(String titre) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                const Text("Confirmation"),
              ],
            ),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer la ressource "$titre" ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }

  Future<void> updateRessource(Map<String, dynamic> r) async {
    final titreCtrl = TextEditingController(text: r['titre']);
    final descCtrl = TextEditingController(text: r['description']);
    List<String> categories = [];
    String selectedCat = "";
    String? updatedImageBase64 = r['imageRessource'];
    bool loading = true;
    final ImagePicker picker = ImagePicker();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        fetchCategories() async {
          final response = await http.get(
            Uri.parse('http://chris-crp.freeboxos.fr/api/categories'),
          );
          if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            categories =
                data.map<String>((c) => c['nomCatégorie'] as String).toList();
            selectedCat =
                categories.contains(r['nomCategorie'])
                    ? r['nomCategorie']
                    : categories.first;
          } else {
            categories = ['Éducation'];
            selectedCat = 'Éducation';
          }
          loading = false;
          (ctx as Element).markNeedsBuild();
        }

        fetchCategories();

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                  maxHeight: 600,
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Modifier la ressource",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Flexible(
                      child:
                          loading
                              ? const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              )
                              : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start, // ajoute cette ligne

                                  children: [
                                    _buildModernTextField(
                                      controller: titreCtrl,
                                      label: 'Titre',
                                      icon: Icons.title,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildModernTextField(
                                      controller: descCtrl,
                                      label: 'Description',
                                      icon: Icons.description,
                                      maxLines: 4,
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.category,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Catégorie: $selectedCat',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildImagePicker(
                                      onImageSelected: (imageBase64) {
                                        setState(() {
                                          updatedImageBase64 = imageBase64;
                                        });
                                      },
                                      currentImage: updatedImageBase64,
                                      picker: picker,
                                    ),
                                  ],
                                ),
                              ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Annuler"),
                        ),
                        const SizedBox(width: 12),
                        if (!loading)
                          ElevatedButton(
                            onPressed: () async {
                              await _submitUpdate(
                                r,
                                titreCtrl.text,
                                descCtrl.text,
                                selectedCat,
                                updatedImageBase64,
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667eea),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Modifier"),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildImagePicker({
    required Function(String) onImageSelected,
    required String? currentImage,
    required ImagePicker picker,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              final picked = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (picked != null) {
                final bytes = await picked.readAsBytes();
                onImageSelected(base64Encode(bytes));
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF667eea).withOpacity(0.1),
                    const Color(0xFF764ba2).withOpacity(0.1),
                  ],
                ),
              ),
              child:
                  currentImage != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(currentImage),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder();
                          },
                        ),
                      )
                      : _buildImagePlaceholder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.add_photo_alternate,
            size: 40,
            color: Color(0xFF667eea),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Appuyez pour changer l'image",
          style: TextStyle(
            color: Color(0xFF667eea),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _submitUpdate(
    Map<String, dynamic> r,
    String titre,
    String description,
    String categorie,
    String? image,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(
          'http://chris-crp.freeboxos.fr/api/ressources/${r['idRessource']}',
        ),

        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'titre': titre,
          'message': description,
          'categorie': categorie,
          'image': image,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Ressource modifiée avec succès', Colors.green);
        fetchUserRessources();
      } else {
        _showSnackBar('Erreur : ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Erreur : $e', Colors.red);
    }
  }

  List<dynamic> get filteredRessources {
    var filtered =
        ressources.where((r) {
          final matchesSearch =
              r['titre']?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false;
          final matchesFilter =
              _selectedFilter == 'Toutes' ||
              (_selectedFilter == 'Affichées' &&
                  r['statusRessource'] == 'affiche') ||
              (_selectedFilter == 'En Attente' &&
                  r['statusRessource'] != 'affiche');
          return matchesSearch && matchesFilter;
        }).toList();

    return filtered;
  }

  Widget _buildSearchAndFilter() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Rechercher une ressource...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF667eea)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Filtrer: ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        ['Toutes', 'Affichées', 'En Attente'].map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() => _selectedFilter = filter);
                              },
                              backgroundColor: Colors.grey[100],
                              selectedColor: const Color(
                                0xFF667eea,
                              ).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF667eea),
                              labelStyle: TextStyle(
                                color:
                                    isSelected
                                        ? const Color(0xFF667eea)
                                        : Colors.grey[700],
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildRessourceCard(Map<String, dynamic> r, int index) {
    final status = r['statusRessource'] ?? 'masque';
    final isAffiche = status == 'affiche';

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (index * 0.1).clamp(0.0, 1.0),
              ((index * 0.1) + 0.3).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (index * 0.1).clamp(0.0, 1.0),
              ((index * 0.1) + 0.5).clamp(0.0, 1.0),
              curve: Curves.easeOut,
            ),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey[50]!],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => updateRessource(r),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r['titre'] ?? 'Sans titre',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2d3748),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors:
                                        isAffiche
                                            ? [
                                              Colors.green[400]!,
                                              Colors.green[600]!,
                                            ]
                                            : [
                                              Colors.orange[400]!,
                                              Colors.orange[600]!,
                                            ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isAffiche ? 'Affiché' : 'En Attente',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            r['description'] ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF4a5568),
                              height: 1.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          if (r['imageRessource'] != null)
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[200],
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Image.memory(
                                base64Decode(r['imageRessource']),
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        const Center(
                                          child: Text("Erreur de chargement"),
                                        ),
                              ),
                            ),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF667eea,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.category,
                                      size: 16,
                                      color: Color(0xFF667eea),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      r['nomCategorie'] ?? 'Non spécifiée',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF667eea),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              _buildActionButton(
                                icon: Icons.edit_outlined,
                                color: const Color(0xFF667eea),
                                onPressed: () => updateRessource(r),
                                tooltip: 'Modifier',
                              ),
                              const SizedBox(width: 8),
                              _buildActionButton(
                                icon: Icons.delete_outline,
                                color: Colors.red[400]!,
                                onPressed:
                                    () => deleteRessource(
                                      r['idRessource'],
                                      r['titre'],
                                    ),
                                tooltip: 'Supprimer',
                              ),
                            ],
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
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20),
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredRessources;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text(
          'Mes Ressources',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body:
          isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF667eea),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chargement des ressources...',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  _buildSearchAndFilter(),
                  Expanded(
                    child:
                        filtered.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.folder_open,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    ressources.isEmpty
                                        ? "Aucune ressource trouvée"
                                        : "Aucun résultat pour votre recherche",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ressources.isEmpty
                                        ? "Commencez par créer votre première ressource"
                                        : "Essayez avec d'autres mots-clés",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : RefreshIndicator(
                              onRefresh: fetchUserRessources,
                              color: const Color(0xFF667eea),
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 100),
                                itemCount: filtered.length,
                                itemBuilder:
                                    (context, index) => buildRessourceCard(
                                      filtered[index],
                                      index,
                                    ),
                              ),
                            ),
                  ),
                ],
              ),
      floatingActionButton: ScaleTransition(
        scale: _fabController,
        child: FloatingActionButton.extended(
          onPressed: fetchUserRessources,
          backgroundColor: const Color(0xFF667eea),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.refresh),
          label: const Text('Actualiser'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
