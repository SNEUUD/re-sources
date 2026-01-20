import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  static const String _CANNY_API_KEY = '3c386e6d-2fbc-0ba6-9634-56ead11c83cf';
  static const String _CANNY_BOARD_ID = '68b6a69033ff39ad5e4d9574';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 700;

            return isSmall
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _logoSection(),
                      const SizedBox(height: 25),

                      // Ligne unique pour la 1ère colonne (liens)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _footerLinks()
                              .map((text) => Padding(
                                    padding: const EdgeInsets.only(right: 20),
                                    child: _linkWidget(context, text),
                                  ))
                              .toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Ligne unique pour la 2ème colonne (réseaux sociaux)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _footerSocials()
                              .map((text) => Padding(
                                    padding: const EdgeInsets.only(right: 20),
                                    child: _socialWidget(context, text),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(flex: 1, child: _logoSection()),
                      const SizedBox(width: 30),
                      Flexible(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _footerLinks()
                              .map((text) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _linkWidget(context, text),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 30),
                      Flexible(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _footerSocials()
                              .map((text) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _socialWidget(context, text),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _logoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset('assets/icons/logo.png', height: 50),
        const SizedBox(height: 15),
        const Text(
          'Vous avez le pouvoir de changer.',
          style: TextStyle(color: Color(0xFF000091)),
        ),
        const Text(
          'Faites un pas de plus vers une vie sereine et épanouie.',
          style: TextStyle(color: Color(0xFF000091)),
        ),
        const SizedBox(height: 15),
        const Text(
          '© 2025 (re)sources relationnelles',
          style: TextStyle(color: Color(0xFF000091)),
        ),
      ],
    );
  }

  Widget _linkWidget(BuildContext context, String text) {
    // Tous les liens affichés comme boutons sans ouvrir le dialog de feedback
    return TextButton(
      onPressed: () {},
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF000091)),
      ),
    );
  }

  // Nouveau : widget pour chaque réseau social.
  Widget _socialWidget(BuildContext context, String name) {
    if (name == 'Envoyer un feedback') {
      return TextButton(
        onPressed: () => _showFeedbackDialog(context),
        child: Text(
          name,
          style: const TextStyle(color: Color(0xFF000091)),
        ),
      );
    }

    // Comportement par défaut pour les autres réseaux
    return TextButton(
      onPressed: () {},
      child: Text(name, style: const TextStyle(color: Color(0xFF000091))),
    );
  }

  Future<void> _showFeedbackDialog(BuildContext context) async {
    final messageController = TextEditingController();
    String feedbackType = 'Bug';
    String feedbackLocation = 'Accueil';
    bool isSending = false;

    final feedbackTypes = ['Bug', 'Suggestion', 'Amélioration', 'Autre'];
    final feedbackLocations = [
      'Accueil',
      'Ressources',
      'Catégories',
      'Profil',
      'Connexion',
      'Inscription',
      'Création ressource',
      'Administration',
      'Autre'
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Envoyer un feedback'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: feedbackType,
                      decoration: const InputDecoration(
                        labelText: 'Type de feedback',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      items: feedbackTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => feedbackType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: feedbackLocation,
                      decoration: const InputDecoration(
                        labelText: 'Où ?',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      items: feedbackLocations
                          .map((loc) => DropdownMenuItem(
                                value: loc,
                                child: Text(loc),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => feedbackLocation = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                        hintText: 'Décrivez le bug ou votre suggestion...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final message = messageController.text.trim();
                          if (message.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Message vide')),
                            );
                            return;
                          }
                          setState(() => isSending = true);
                          try {
                            await _sendFeedbackCanny(
                              type: feedbackType,
                              location: feedbackLocation,
                              message: message,
                            );
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Feedback envoyé !')),
                            );
                          } catch (e) {
                            setState(() => isSending = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur lors de l\'envoi: $e')),
                            );
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Envoyer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> _findOrCreateAnonymousAuthor() async {
    final url = Uri.parse('https://canny.io/api/v1/users/find_or_create');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'apiKey': _CANNY_API_KEY,
        'name': 'Anonymous User',
        'userID': 'anonymous-user',
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['id'] != null) return decoded['id'].toString();
        if (decoded['data'] != null && decoded['data'] is Map && decoded['data']['id'] != null) {
          return decoded['data']['id'].toString();
        }
        if (decoded['user'] != null && decoded['user'] is Map && decoded['user']['id'] != null) {
          return decoded['user']['id'].toString();
        }
      }
      throw Exception('Réponse inattendue lors de la création de l\'utilisateur anonyme: ${response.body}');
    }
    throw Exception('Erreur création utilisateur anonyme: ${response.statusCode} ${response.body}');
  }

  Future<void> _sendFeedbackCanny({
    required String type,
    required String location,
    required String message,
  }) async {
    final authorId = await _findOrCreateAnonymousAuthor();

    final url = Uri.parse('https://canny.io/api/v1/posts/create');
    final Map<String, dynamic> payload = {
      'apiKey': _CANNY_API_KEY,
      'authorID': authorId,
      'boardID': _CANNY_BOARD_ID,
      'title': '[$type][$location] $message',
      'details': message
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }
    throw Exception('Canny API error: ${response.statusCode}. Réponse: ${response.body}');
  }

  List<String> _footerLinks() {
    // Libellés plus concis et professionnels
    return [
      'Nous contacter',
      'Confidentialité',
      'Mentions',
      'Préférences Cookies',
    ];
  }

  List<String> _footerSocials() {
    return [
      'Envoyer un feedback',
      'Soutenez-nous',
      'Voir nos vidéos',
      'Rejoignez-nous',
    ];
  }
}
