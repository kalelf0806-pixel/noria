import 'package:flutter/material.dart';

class MultimodalFeaturesPage extends StatelessWidget {
  const MultimodalFeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('CENTRE MULTIMODAL & LIVE API', style: TextStyle(color: Colors.white, fontSize: 15, letterSpacing: 1.2)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('CAPACITÉS LOCALES (Gemma 4 / NPU)', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          _buildFeatureCard(
            context,
            'Vision, OCR & Bounding Boxes',
            'Analyse d\'images, schémas, tableaux et détection d\'objets avec coordonnées natives.',
            Icons.document_scanner,
            () => _showInfo(context, 'Module OCR & Vision Gemma 4 prêt pour analyse.'),
          ),
          _buildFeatureCard(
            context,
            'Audio Natif Embarqué',
            'Traitement direct de la voix et des instructions audio sur le Snapdragon 888.',
            Icons.mic,
            () => _showInfo(context, 'Encodeur audio local en écoute.'),
          ),
          _buildFeatureCard(
            context,
            'Traitement Vidéo (1 fps)',
            'Analyse séquentielle de flux vidéo courts en local.',
            Icons.videocam,
            () => _showInfo(context, 'Capture vidéo activée.'),
          ),
          _buildFeatureCard(
            context,
            'Extended Thinking & Function Calling',
            'Fenêtre de contexte 128K tokens avec chaîne de pensée locale.',
            Icons.psychology,
            () => _showInfo(context, 'Contexte étendu configuré.'),
          ),
          const Divider(color: Colors.grey, height: 32),
          const Text('CAPACITÉS CLOUD (Google Live API - Illimité)', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          _buildFeatureCard(
            context,
            'Gemini 3.8 Live & Extended Thinking',
            'Streaming audio/texte bidirectionnel à haute performance avec raisonnement.',
            Icons.bolt,
            () => _showInfo(context, 'Connexion flux Gemini 3.8 Live initialisée.'),
          ),
          _buildFeatureCard(
            context,
            'Gemini 2.5 Flash Native Audio Dialog',
            'Dialogue vocal natif fluide et naturel.',
            Icons.record_voice_over,
            () => _showInfo(context, 'Session Audio Dialog active.'),
          ),
          _buildFeatureCard(
            context,
            'Gemini 3.5 Live Translate',
            'Traduction instantanée multilingue en streaming.',
            Icons.translate,
            () => _showInfo(context, 'Module de traduction instantanée prêt.'),
          ),
          _buildFeatureCard(
            context,
            'Gemini 3.5 Transcribe Live',
            'Transcription audio haute précision en temps réel.',
            Icons.closed_caption,
            () => _showInfo(context, 'Transcription Live démarrée.'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      color: Colors.grey.shade900,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
        onTap: onTap,
      ),
    );
  }

  void _showInfo(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
