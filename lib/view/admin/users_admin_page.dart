import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

class UsersAdminPage extends StatefulWidget {
  const UsersAdminPage({super.key});

  @override
  State<UsersAdminPage> createState() => _UsersAdminPageState();
}

class _UsersAdminPageState extends State<UsersAdminPage> {
  late Future<List<dynamic>> futureUsers;
  late Future<List<dynamic>> futureMaskedResources;
  int? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _loadSession();
    futureUsers = fetchUsers();
    futureMaskedResources = fetchMaskedResources();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final roleId = prefs.getInt('roleUtilisateur');
    setState(() {
      _currentUserRole = roleId;
    });
  }

  Future<List<dynamic>> fetchUsers() async {
    final response = await http.get(
      Uri.parse('http://chris-crp.freeboxos.fr/api/utilisateurs'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des utilisateurs');
    }
  }

  Future<void> suspendUser(String userId) async {
    final response = await http.patch(
      Uri.parse(
        'http://chris-crp.freeboxos.fr/api/utilisateurs/$userId/suspendre',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'statusUtilisateur': 'désactivé'}),
    );
    if (response.statusCode == 200) {
      setState(() {
        futureUsers = fetchUsers();
      });
      _showSuccessSnackBar('Compte suspendu avec succès');
    } else {
      _showErrorSnackBar('Erreur lors de la suspension');
    }
  }

  Future<void> deleteUser(String userId) async {
    final response = await http.delete(
      Uri.parse('http://chris-crp.freeboxos.fr/api/utilisateurs/$userId'),
    );
    if (response.statusCode == 200) {
      setState(() {
        futureUsers = fetchUsers();
      });
      _showSuccessSnackBar('Compte supprimé avec succès');
    } else {
      _showErrorSnackBar('Erreur lors de la suppression');
    }
  }

  Future<void> updateUserStatus(String userId, String status) async {
    final response = await http.patch(
      Uri.parse(
        'http://chris-crp.freeboxos.fr/api/utilisateurs/$userId/suspendre',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'statusUtilisateur': status}),
    );
    if (response.statusCode == 200) {
      setState(() {
        futureUsers = fetchUsers();
      });
      _showSuccessSnackBar(
        status == 'désactivé' ? 'Compte suspendu' : 'Compte réactivé',
      );
    } else {
      _showErrorSnackBar('Erreur lors du changement de statut');
    }
  }

  Future<void> promoteToAdmin(String userId) async {
    final response = await http.patch(
      Uri.parse('http://chris-crp.freeboxos.fr/api/utilisateurs/$userId/role'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'role': 2}),
    );
    if (response.statusCode == 200) {
      setState(() {
        futureUsers = fetchUsers();
      });
      _showSuccessSnackBar('Utilisateur promu admin');
    } else {
      _showErrorSnackBar('Erreur lors de la promotion');
    }
  }

  Future<void> demoteToUser(String userId) async {
    final response = await http.patch(
      Uri.parse('http://chris-crp.freeboxos.fr/api/utilisateurs/$userId/role'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'role': 1}),
    );
    if (response.statusCode == 200) {
      setState(() {
        futureUsers = fetchUsers();
      });
      _showSuccessSnackBar('Utilisateur rétrogradé avec succès');
    } else {
      _showErrorSnackBar('Erreur lors de la rétrogradation');
    }
  }

  Future<List<dynamic>> fetchMaskedResources() async {
    final response = await http.get(
      Uri.parse('http://chris-crp.freeboxos.fr/api/resources_admin'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des ressources');
    }
  }

  Future<void> validateResource(String resourceId) async {
    final response = await http.patch(
      Uri.parse(
        'http://chris-crp.freeboxos.fr/api/resources_admin/$resourceId/valider',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'statusRessource': 'affiche'}),
    );
    if (response.statusCode == 200) {
      setState(() {
        futureMaskedResources = fetchMaskedResources();
      });
      _showSuccessSnackBar('Ressource validée avec succès');
    } else {
      _showErrorSnackBar('Erreur lors de la validation');
    }
  }

  Future<void> deleteResource(String resourceId) async {
    final response = await http.delete(
      Uri.parse(
        'http://chris-crp.freeboxos.fr/api/resources_admin/$resourceId',
      ),
    );
    if (response.statusCode == 200) {
      setState(() {
        futureMaskedResources = fetchMaskedResources();
      });
      _showSuccessSnackBar('Ressource supprimée avec succès');
    } else {
      _showErrorSnackBar('Erreur lors de la suppression');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? action}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF000091), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000091).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            title == "Utilisateurs" ? Icons.people : Icons.library_books,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          if (action != null) ...[const Spacer(), action],
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final bool isActive = user['status'] != 'désactivé';
    final bool isAdmin = user['role'] == 2;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isActive
                      ? [const Color(0xFF000091), const Color(0xFF1E3A8A)]
                      : [Colors.grey.shade400, Colors.grey.shade500],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.person, color: Colors.white, size: 24),
        ),
        title: Text(
          user['pseudo'] ?? 'Sans pseudo',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user['email'] ?? '',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isActive ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? 'Actif' : 'Suspendu',
                style: TextStyle(
                  color:
                      isActive ? Colors.green.shade700 : Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isActive ? Colors.orange.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  isActive ? Icons.pause_circle : Icons.play_circle,
                  color:
                      isActive ? Colors.orange.shade600 : Colors.green.shade600,
                  size: 28,
                ),
                tooltip: isActive ? 'Suspendre' : 'Réactiver',
                onPressed:
                    () => updateUserStatus(
                      user['id'].toString(),
                      isActive ? 'désactivé' : 'activé',
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.delete_forever,
                  color: Colors.red.shade600,
                  size: 28,
                ),
                tooltip: 'Supprimer',
                onPressed:
                    () => _showDeleteConfirmation(
                      context,
                      'Supprimer l\'utilisateur',
                      'Êtes-vous sûr de vouloir supprimer cet utilisateur ?',
                      () => deleteUser(user['id'].toString()),
                    ),
              ),
            ),
            const SizedBox(width: 8),
            if (_currentUserRole == 3 && user['role'] != 2 && user['role'] != 3)
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                  tooltip: 'Promouvoir admin',
                  onPressed:
                      () => _showDeleteConfirmation(
                        context,
                        'Promouvoir administrateur',
                        'Êtes-vous sûr de vouloir promouvoir cet utilisateur en administrateur ?',
                        () => promoteToAdmin(user['id'].toString()),
                      ),
                ),
              ),
            if (_currentUserRole == 3 && isAdmin)
              Container(
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_downward,
                    color: Colors.purple.shade700,
                    size: 28,
                  ),
                  tooltip: 'Rétrograder',
                  onPressed:
                      () => _showDeleteConfirmation(
                        context,
                        'Rétrograder l\'utilisateur',
                        'Êtes-vous sûr de vouloir rétrograder cet utilisateur ?',
                        () => demoteToUser(user['id'].toString()),
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> res) {
    Widget imageWidget;
    if (res['image'] != null && res['image'].isNotEmpty) {
      try {
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            base64Decode(res['image']),
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        imageWidget = _buildPlaceholderImage(Icons.broken_image);
      }
    } else {
      imageWidget = _buildPlaceholderImage(Icons.image_not_supported);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: imageWidget,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    res['title'] ?? 'Sans titre',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF000091),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (res['categorie'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.purple],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        res['categorie'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    res['message'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        res['date'] != null
                            ? res['date'].toString().split('T').first
                            : '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.green, Color(0xFF4CAF50)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Valider',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed:
                              () => validateResource(
                                res['idRessource'].toString(),
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.red, Color(0xFFE57373)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Supprimer',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed:
                              () => _showDeleteConfirmation(
                                context,
                                'Supprimer la ressource',
                                'Êtes-vous sûr de vouloir supprimer cette ressource ?',
                                () => deleteResource(
                                  res['idRessource'].toString(),
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(IconData icon) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 40, color: Colors.grey.shade400),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Confirmer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF000091)),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Text(
                'Administration',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF000091),
                ),
              ),
            ],
          ),

          // 🔹 Contenu principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colonne Utilisateurs
                  Expanded(
                    child: Column(
                      children: [
                        _buildSectionHeader("Utilisateurs"),
                        const SizedBox(height: 20),
                        Expanded(
                          child: FutureBuilder<List<dynamic>>(
                            future: futureUsers,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              } else if (snapshot.hasError) {
                                return Center(
                                  child: Text('Erreur: ${snapshot.error}'),
                                );
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text('Aucun utilisateur trouvé.'),
                                );
                              } else {
                                final users = snapshot.data!;
                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  itemCount: users.length,
                                  itemBuilder: (context, index) {
                                    return _buildUserCard(users[index]);
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 32),

                  // Colonne Ressources
                  Expanded(
                    child: Column(
                      children: [
                        _buildSectionHeader(
                          "Ressources à valider",
                          action: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.white,
                            ),
                            label: const Text('Créer une ressource'),
                            onPressed: () {
                              // Naviguer vers la création
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: FutureBuilder<List<dynamic>>(
                            future: futureMaskedResources,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              } else if (snapshot.hasError) {
                                return Center(
                                  child: Text('Erreur: ${snapshot.error}'),
                                );
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text('Aucune ressource à valider.'),
                                );
                              } else {
                                final resources = snapshot.data!;
                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  itemCount: resources.length,
                                  itemBuilder: (context, index) {
                                    return _buildResourceCard(resources[index]);
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
