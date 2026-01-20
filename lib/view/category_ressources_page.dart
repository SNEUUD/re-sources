import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CategoryResourcesPage extends StatefulWidget {
  final String nomCategorie;

  const CategoryResourcesPage({super.key, required this.nomCategorie});

  @override
  State<CategoryResourcesPage> createState() => _CategoryResourcesPageState();
}

class _CategoryResourcesPageState extends State<CategoryResourcesPage> {
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
    futureResources = fetchResources();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<List<Map<String, dynamic>>> fetchCommentaires(int ressourceId) async {
    final response = await http.get(
      Uri.parse(
        'http://chris-crp.freeboxos.fr/api/ressources/$ressourceId/commentaires',
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Erreur chargement commentaires");
    }
  }

  Future<void> sendCommentaire(int ressourceId, String message) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('idUtilisateur');
    if (userId == null || message.trim().isEmpty) return;

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
  }

  Future<void> fetchLikesForResource(int ressourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('idUtilisateur');
    if (userId == null) return;

    final response = await http.get(
      Uri.parse(
        'http://chris-crp.freeboxos.fr/api/ressources/$ressourceId/likes/$userId',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        likedStatus[ressourceId] = data['liked'];
        likeCounts[ressourceId] = data['likeCount'];
      });
    }
  }

  Future<void> toggleLike(int ressourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('idUtilisateur');
    if (userId == null) return;

    final response = await http.post(
      Uri.parse('http://chris-crp.freeboxos.fr/api/interactions'),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'ressourceId': ressourceId}),
    );

    if (response.statusCode == 200) {
      await fetchLikesForResource(ressourceId);
    }
  }

  Future<List<dynamic>> fetchResources() async {
    final response = await http.get(
      Uri.parse(
        'http://chris-crp.freeboxos.fr/api/ressources?categorie=${widget.nomCategorie}',
      ),
    );
    if (response.statusCode == 200) {
      List<dynamic> ressources = jsonDecode(response.body);

      // Tri local selon le choix
      if (sortBy == 'dateDesc') {
        ressources.sort(
          (a, b) =>
              (b['dateRessource'] ?? '').compareTo(a['dateRessource'] ?? ''),
        );
      } else if (sortBy == 'dateAsc') {
        ressources.sort(
          (a, b) =>
              (a['dateRessource'] ?? '').compareTo(b['dateRessource'] ?? ''),
        );
      } else if (sortBy == 'titre') {
        ressources.sort(
          (a, b) => (a['titreRessource'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo((b['titreRessource'] ?? '').toString().toLowerCase()),
        );
      }
      return ressources;
    } else {
      throw Exception('Erreur lors du chargement des ressources');
    }
  }

  void onSortChanged(String? value) {
    if (value != null) {
      setState(() {
        sortBy = value;
        futureResources = fetchResources();
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

      return titre.contains(searchQuery) || description.contains(searchQuery);
    }).toList();
  }

  String formatDateTime(String datetime) {
    final date = DateTime.parse(datetime);
    return DateFormat('dd/MM/yyyy à HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icons/logo.png', height: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ressources : ${widget.nomCategorie}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),

                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: bleuFrance,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E5E5)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: bleuFrance),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: grisClair,
      body: Column(
        children: [
          // Barre de contrôles
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<String>(
                        value: sortBy,
                        underline: const SizedBox(),
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
                          DropdownMenuItem(
                            value: 'titre',
                            child: Text('Titre'),
                          ),
                        ],
                        onChanged: onSortChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Rechercher une ressource...",
                      hintStyle: TextStyle(color: grisFrance.withOpacity(0.7)),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: grisFrance,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 1),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: futureResources,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(bleuFrance),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: rougeMarianne.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: rougeMarianne,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de chargement',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: rougeMarianne,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: const TextStyle(color: grisFrance),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open, color: grisFrance, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune ressource dans cette catégorie',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: grisFrance,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  final ressources = filterResources(snapshot.data!);
                  if (ressources.isEmpty) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, color: grisFrance, size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucune ressource trouvée',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: grisFrance,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Essayez de modifier vos critères de recherche',
                              style: TextStyle(color: grisFrance),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ressources.length,
                    itemBuilder: (context, index) {
                      final ressource = ressources[index];
                      final ressourceId = ressource['idRessource'];

                      final auteur =
                          ressource['pseudoUtilisateur'] ?? 'Auteur inconnu';

                      if (!likedStatus.containsKey(ressourceId)) {
                        fetchLikesForResource(ressourceId);
                      }
                      commentControllers.putIfAbsent(
                        ressourceId,
                        () => TextEditingController(),
                      );
                      showAllComments.putIfAbsent(ressourceId, () => false);

                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: fetchCommentaires(ressourceId),
                        builder: (context, commentSnapshot) {
                          Widget? imageWidget;
                          if (ressource['imageRessource'] != null &&
                              ressource['imageRessource'].isNotEmpty) {
                            try {
                              imageWidget = ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 250,
                                  maxWidth: double.infinity,
                                ),
                                child: Image.memory(
                                  base64Decode(ressource['imageRessource']),
                                  fit: BoxFit.contain,
                                ),
                              );
                            } catch (_) {
                              imageWidget = null;
                            }
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (imageWidget != null)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                    child: imageWidget,
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Badge de catégorie
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: bleuCumulus,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          widget.nomCategorie,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: bleuFrance,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Titre
                                      Text(
                                        ressource['titreRessource'] ??
                                            'Sans titre',

                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 20,
                                          color: bleuFrance,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Auteur et date
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 16,
                                            color: grisFrance,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Par $auteur",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: grisFrance,
                                            ),
                                          ),

                                          if (ressource['dateRessource'] !=
                                              null) ...[
                                            const SizedBox(width: 16),
                                            Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: grisFrance,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              formatDateTime(
                                                ressource['dateRessource'],
                                              ),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: grisFrance,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Description
                                      Text(
                                        ressource['messageRessource'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Bouton J'aime
                                      Row(
                                        children: [
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              onTap:
                                                  () => toggleLike(ressourceId),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      likedStatus[ressourceId] ==
                                                              true
                                                          ? Icons.favorite
                                                          : Icons
                                                              .favorite_border,
                                                      size: 20,
                                                      color:
                                                          likedStatus[ressourceId] ==
                                                                  true
                                                              ? rougeMarianne
                                                              : grisFrance,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      likeCounts[ressourceId]
                                                              ?.toString() ??
                                                          '0',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            likedStatus[ressourceId] ==
                                                                    true
                                                                ? rougeMarianne
                                                                : grisFrance,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const Divider(
                                        height: 32,
                                        color: Color(0xFFE5E5E5),
                                      ),

                                      // Section commentaires
                                      const Text(
                                        'Commentaires',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: bleuFrance,
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Champ de commentaire
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xFFDDDDDD),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: TextField(
                                          controller:
                                              commentControllers[ressourceId],
                                          maxLines: 2,
                                          style: const TextStyle(fontSize: 14),
                                          decoration: InputDecoration(
                                            hintText:
                                                "Écrire un commentaire...",
                                            hintStyle: TextStyle(
                                              color: grisFrance.withOpacity(
                                                0.7,
                                              ),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: const Icon(
                                                Icons.send,
                                                color: bleuFrance,
                                                size: 20,
                                              ),
                                              onPressed: () async {
                                                try {
                                                  await sendCommentaire(
                                                    ressourceId,

                                                    commentControllers[ressourceId]!
                                                        .text,
                                                  );
                                                  commentControllers[ressourceId]!
                                                      .clear();
                                                  setState(() {});
                                                } catch (e) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Erreur : $e',
                                                      ),
                                                      backgroundColor:
                                                          rougeMarianne,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                            border: InputBorder.none,

                                            contentPadding:
                                                const EdgeInsets.all(12),
                                          ),
                                        ),
                                      ),

                                      // Liste des commentaires
                                      if (commentSnapshot.hasData &&
                                          commentSnapshot.data!.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        ...commentSnapshot.data!
                                            .take(
                                              showAllComments[ressourceId]!
                                                  ? commentSnapshot.data!.length
                                                  : 3,
                                            )
                                            .map(
                                              (c) => Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: grisClair,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,

                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.person,
                                                          size: 16,
                                                          color: grisFrance,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          c['pseudo'],
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontSize: 13,
                                                                color:
                                                                    bleuFrance,
                                                              ),
                                                        ),
                                                        const Spacer(),
                                                        Text(
                                                          c['dateCommentaire'] !=
                                                                  null
                                                              ? formatDateTime(
                                                                c['dateCommentaire'],
                                                              )
                                                              : '',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: grisFrance,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      c['messageCommentaire'],
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black87,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                            .toList(),

                                        if (!showAllComments[ressourceId]! &&
                                            commentSnapshot.data!.length > 3)
                                          TextButton.icon(
                                            onPressed: () {
                                              setState(
                                                () =>
                                                    showAllComments[ressourceId] =
                                                        true,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.expand_more,
                                              size: 16,
                                            ),
                                            label: Text(
                                              "Afficher les ${commentSnapshot.data!.length - 3} commentaires restants",
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            style: TextButton.styleFrom(
                                              foregroundColor: bleuFrance,
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
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
    );
  }
}
