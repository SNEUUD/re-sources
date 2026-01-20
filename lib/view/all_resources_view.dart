import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class AllResourcesView extends StatefulWidget {
  const AllResourcesView({super.key});

  @override
  State<AllResourcesView> createState() => _AllResourcesViewState();
}

class _AllResourcesViewState extends State<AllResourcesView> {
  late Future<List<dynamic>> futureResources;
  String sortBy = 'dateDesc';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Map<int, bool> likedStatus = {};
  Map<int, int> likeCounts = {};
  Map<int, TextEditingController> commentControllers = {};
  Map<int, bool> showAllComments = {};

  // Couleurs du Design System de l'État
  static const Color bleuFrance = Color(0xFF000091);
  static const Color rougeMarianne = Color(0xFFE1000F);
  static const Color grisFrance = Color(0xFF666666);
  static const Color grisClair = Color(0xFFF6F6F6);
  static const Color bleuCumulus = Color(0xFFE5E5F4);

  @override
  void initState() {
    super.initState();
    futureResources = fetchAllResources();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var controller in commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchCommentaires(int ressourceId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://chris-crp.freeboxos.fr/api/ressources/$ressourceId/commentaires',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          "Erreur chargement commentaires (${response.statusCode})",
        );
      }
    } catch (e) {
      throw Exception("Erreur réseau: $e");
    }
  }

  Future<void> sendCommentaire(int ressourceId, String message) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('idUtilisateur');

    if (userId == null) {
      throw Exception("Utilisateur non connecté");
    }

    if (message.trim().isEmpty) {
      throw Exception("Le commentaire ne peut pas être vide");
    }

    try {
      final response = await http.post(
        Uri.parse(
          'http://chris-crp.freeboxos.fr/api/ressources/$ressourceId/commentaire',
        ),

        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'message': message.trim()}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          "Erreur lors de l'ajout du commentaire (${response.statusCode})",
        );
      }
    } catch (e) {
      throw Exception("Erreur réseau: $e");
    }
  }

  Future<void> fetchLikesForResource(int ressourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('idUtilisateur');
    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          'http://chris-crp.freeboxos.fr/api/ressources/$ressourceId/likes/$userId',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            likedStatus[ressourceId] = data['liked'] ?? false;
            likeCounts[ressourceId] = data['likeCount'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des likes: $e");
    }
  }

  Future<void> toggleLike(int ressourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('idUtilisateur');
    if (userId == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://chris-crp.freeboxos.fr/api/interactions'),

        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'ressourceId': ressourceId}),
      );

      if (response.statusCode == 200) {
        await fetchLikesForResource(ressourceId);
      }
    } catch (e) {
      debugPrint("Erreur lors du toggle like: $e");
    }
  }

  Future<List<dynamic>> fetchAllResources() async {
    try {
      final response = await http.get(
        Uri.parse('http://chris-crp.freeboxos.fr/api/ressourcesAll'),
      );

      if (response.statusCode == 200) {
        List<dynamic> ressources = jsonDecode(response.body);
        return _sortResources(ressources);
      } else {
        throw Exception('Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des ressources: $e');
    }
  }

  List<dynamic> _sortResources(List<dynamic> ressources) {
    switch (sortBy) {
      case 'dateDesc':
        ressources.sort(
          (a, b) =>
              (b['dateRessource'] ?? '').compareTo(a['dateRessource'] ?? ''),
        );
        break;
      case 'dateAsc':
        ressources.sort(
          (a, b) =>
              (a['dateRessource'] ?? '').compareTo(b['dateRessource'] ?? ''),
        );
        break;
      case 'titre':
        ressources.sort(
          (a, b) => (a['titreRessource'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo((b['titreRessource'] ?? '').toString().toLowerCase()),
        );
        break;
      case 'categorie':
        ressources.sort(
          (a, b) => (a['nomCatégorie'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo((b['nomCatégorie'] ?? '').toString().toLowerCase()),
        );
        break;
    }
    return ressources;
  }

  void onSortChanged(String? value) {
    if (value != null) {
      setState(() {
        sortBy = value;
        futureResources = fetchAllResources();
      });
    }
  }

  List<dynamic> filterResources(List<dynamic> ressources) {
    if (searchQuery.isEmpty) return ressources;
    return ressources.where((ressource) {
      final titre =
          (ressource['titreRessource'] ?? '').toString().toLowerCase();
      final description =
          (ressource['messageRessource'] ?? '').toString().toLowerCase();
      final categorie =
          (ressource['nomCatégorie'] ?? '').toString().toLowerCase();
      return titre.contains(searchQuery) ||
          description.contains(searchQuery) ||
          categorie.contains(searchQuery);
    }).toList();
  }

  String formatDateTime(String datetime) {
    try {
      final date = DateTime.parse(datetime);
      return DateFormat('dd/MM/yyyy à HH:mm').format(date);
    } catch (e) {
      return datetime;
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24), // Réduit pour mobile
        margin: const EdgeInsets.all(16), // Réduit pour mobile
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: rougeMarianne.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8, // Réduit pour mobile
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: rougeMarianne,
              size: 40, // Taille réduite
            ),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18, // Taille réduite
                fontWeight: FontWeight.w600,
                color: rougeMarianne,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                color: grisFrance,
                fontSize: 13, // Taille réduite
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  futureResources = fetchAllResources();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: bleuFrance,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ), // Réduit
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24), // Réduit pour mobile
        margin: const EdgeInsets.all(16), // Réduit pour mobile
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8, // Réduit pour mobile
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: grisFrance,
              size: 40, // Taille réduite
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18, // Taille réduite
                fontWeight: FontWeight.w500,
                color: grisFrance,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: grisFrance,
                  fontSize: 13, // Taille réduite
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // BARRE DE CONTRÔLE ADAPTÉE MOBILE
  Widget _buildControlsBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ), // Réduit
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section tri
          Row(
            children: [
              const Icon(Icons.sort, color: grisFrance, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Trier par :",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: grisFrance,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButton<String>(
                    value: sortBy,
                    underline: const SizedBox(),
                    isExpanded: true,
                    style: const TextStyle(color: grisFrance, fontSize: 14),
                    items: const [
                      DropdownMenuItem(
                        value: 'dateDesc',
                        child: Text('Date (plus récentes)'),
                      ),
                      DropdownMenuItem(
                        value: 'dateAsc',
                        child: Text('Date (plus anciennes)'),
                      ),
                      DropdownMenuItem(value: 'titre', child: Text('Titre')),
                      DropdownMenuItem(
                        value: 'categorie',
                        child: Text('Catégorie'),
                      ),
                    ],
                    onChanged: onSortChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barre de recherche
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDDDDDD)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: "Rechercher une ressource...",
                hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 14),
                prefixIcon: Icon(Icons.search, color: grisFrance, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CARTE DE RESSOURCE ADAPTÉE MOBILE
  Widget _buildResourceCard(
    dynamic ressource,
    List<Map<String, dynamic>> comments,
  ) {
    final ressourceId = ressource['idRessource'];
    final auteur = ressource['pseudoUtilisateur'] ?? 'Auteur inconnu';

    Widget? imageWidget;
    if (ressource['imageRessource'] != null &&
        ressource['imageRessource'].isNotEmpty) {
      try {
        imageWidget = ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: SizedBox(
            width: double.infinity,
            height: 160, // Hauteur fixe pour mobile
            child: Image.memory(
              base64Decode(ressource['imageRessource']),
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (_) {
        imageWidget = null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16), // Marge réduite
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8, // Réduit pour mobile
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageWidget != null) imageWidget,
          Padding(
            padding: const EdgeInsets.all(12), // Padding réduit
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec catégorie et métadonnées
                Row(
                  children: [
                    if (ressource['nomCatégorie'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bleuCumulus,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ressource['nomCatégorie'],
                          style: const TextStyle(
                            color: bleuFrance,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      "par $auteur",
                      style: const TextStyle(color: grisFrance, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      formatDateTime(ressource['dateRessource'] ?? ''),
                      style: const TextStyle(color: grisFrance, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Titre
                Text(
                  ressource['titreRessource'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: bleuFrance,
                  ),
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  ressource['messageRessource'] ?? '',
                  style: const TextStyle(color: grisFrance, fontSize: 14),
                ),
                const SizedBox(height: 12),
                // Boutons d'interaction
                Row(
                  children: [
                    // Bouton Like
                    InkWell(
                      onTap: () => toggleLike(ressourceId),
                      child: Row(
                        children: [
                          Icon(
                            likedStatus[ressourceId] == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                likedStatus[ressourceId] == true
                                    ? rougeMarianne
                                    : grisFrance,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${likeCounts[ressourceId] ?? 0}',
                            style: const TextStyle(
                              color: grisFrance,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Bouton Commentaire
                    InkWell(
                      onTap: () {
                        setState(() {
                          showAllComments[ressourceId] =
                              !(showAllComments[ressourceId] ?? false);
                        });
                      },
                      child: const Row(
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            color: grisFrance,
                            size: 20,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Commenter',
                            style: TextStyle(color: grisFrance, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Section commentaires (simplifiée pour l'exemple)
                if (showAllComments[ressourceId] == true) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller:
                        commentControllers[ressourceId] ??=
                            TextEditingController(),
                    decoration: InputDecoration(
                      hintText: "Écrire un commentaire...",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          final message = commentControllers[ressourceId]!.text;
                          if (message.isNotEmpty) {
                            await sendCommentaire(ressourceId, message);
                            commentControllers[ressourceId]!.clear();
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                ],
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
      backgroundColor: grisClair,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          },
        ),
        title: const Text("Toutes les ressources"),
        backgroundColor: bleuFrance,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildControlsBar(),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: futureResources,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(
                      title: "Aucune ressource trouvée",
                      subtitle:
                          "Essayez de modifier votre recherche ou vos filtres.",
                      icon: Icons.info_outline,
                    );
                  } else {
                    final filtered = filterResources(snapshot.data!);
                    if (filtered.isEmpty) {
                      return _buildEmptyState(
                        title: "Aucun résultat",
                        subtitle:
                            "Aucune ressource ne correspond à votre recherche.",
                        icon: Icons.search_off,
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(12), // Padding réduit
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final ressource = filtered[index];
                        return FutureBuilder<List<Map<String, dynamic>>>(
                          future: fetchCommentaires(ressource['idRessource']),
                          builder: (context, commentSnapshot) {
                            final comments = commentSnapshot.data ?? [];
                            return _buildResourceCard(ressource, comments);
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
