import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final bool isCloudMode;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.isCloudMode,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  String _activeLocalFeature = 'Standard';
  String _activeCloudModel = 'Gemini 3.8 Live';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteur de capacités selon le mode (Local vs Cloud)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.isCloudMode
                  ? [
                      const Text('☁️ Cloud Live API : ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      _buildChip('Gemini 3.8 Live', Icons.bolt),
                      _buildChip('Gemini 3.8 Thinking', Icons.psychology),
                      _buildChip('Gemini 3 Flash Live', Icons.flash_on),
                      _buildChip('Gemini 2.5 Audio Dialog', Icons.record_voice_over),
                      _buildChip('Gemini 3.5 Live Translate', Icons.translate),
                      _buildChip('Gemini 3.5 Transcribe Live', Icons.closed_caption),
                    ]
                  : [
                      const Text('⚡ Gemma 4 Local : ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      _buildLocalChip('Standard', Icons.chat),
                      _buildLocalChip('Vision & OCR (Bounding Boxes)', Icons.document_scanner),
                      _buildLocalChip('Audio Natif (Voix)', Icons.mic),
                      _buildLocalChip('Traitement Vidéo (1 fps)', Icons.videocam),
                      _buildLocalChip('Thinking Mode (128K Ctx)', Icons.psychology),
                    ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: widget.isCloudMode
                        .toString() // Just to suppress warning
                        ? 'Envoyer à [${widget.isCloudMode ? _activeCloudModel : _activeLocalFeature}]...'
                        : 'Message...',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => widget.onSubmitted(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: widget.onSubmitted,
                icon: const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocalChip(String label, IconData icon) {
    final isSelected = _activeLocalFeature == label;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white)),
        selected: isSelected,
        selectedColor: Colors.white,
        backgroundColor: Colors.grey.shade900,
        avatar: Icon(icon, size: 14, color: isSelected ? Colors.black : Colors.white70),
        onSelected: (selected) {
          setState(() => _activeLocalFeature = label);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mode Local activé : $label')),
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    final isSelected = _activeCloudModel == label;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white)),
        selected: isSelected,
        selectedColor: Colors.white,
        backgroundColor: Colors.grey.shade900,
        avatar: Icon(icon, size: 14, color: isSelected ? Colors.black : Colors.white70),
        onSelected: (selected) {
          setState(() => _activeCloudModel = label);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Modèle Cloud actif : $label (Quota illimité)')),
          );
        },
      ),
    );
  }
}
