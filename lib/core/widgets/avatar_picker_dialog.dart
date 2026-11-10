import 'package:flutter/material.dart';

class AvatarPickerDialog extends StatefulWidget {
  final String? initialAvatar;

  const AvatarPickerDialog({super.key, this.initialAvatar});

  static Future<String?> show(BuildContext context, {String? initialAvatar}) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AvatarPickerDialog(initialAvatar: initialAvatar),
    );
  }

  @override
  State<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog> {
  late TextEditingController _urlController;
  late String _selectedAvatar;

  final List<String> _presetAvatars = [
    'https://api.dicebear.com/7.x/bottts/png?seed=Cine1',
    'https://api.dicebear.com/7.x/bottts/png?seed=FilmFan',
    'https://api.dicebear.com/7.x/bottts/png?seed=Director',
    'https://api.dicebear.com/7.x/bottts/png?seed=MovieStar',
    'https://api.dicebear.com/7.x/bottts/png?seed=Popcorn',
    'https://api.dicebear.com/7.x/bottts/png?seed=Hollywood',
    'https://api.dicebear.com/7.x/bottts/png?seed=Oscar',
    'https://api.dicebear.com/7.x/bottts/png?seed=Cinema',
  ];

  @override
  void initState() {
    super.initState();
    _selectedAvatar = widget.initialAvatar ?? _presetAvatars.first;
    _urlController = TextEditingController(text: widget.initialAvatar ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Profil Fotoğrafı Seç', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Canlı Önizleme
              CircleAvatar(
                radius: 44,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                backgroundImage: _selectedAvatar.isNotEmpty ? NetworkImage(_selectedAvatar) : null,
                child: _selectedAvatar.isEmpty
                    ? const Icon(Icons.person, size: 44, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Hazır Avatarlardan Seçin:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              // Preset Avatar Grid
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _presetAvatars.map((url) {
                  final isSelected = _selectedAvatar == url;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatar = url;
                        _urlController.text = url;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(url),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 8),
              // Özel URL Alanı
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Veya Görsel URL\'si Yapıştırın',
                  hintText: 'https://ornek.com/foto.jpg',
                  prefixIcon: Icon(Icons.link_rounded),
                  isDense: true,
                ),
                onChanged: (val) {
                  setState(() {
                    _selectedAvatar = val.trim();
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _selectedAvatar.trim());
          },
          child: const Text('Seç'),
        ),
      ],
    );
  }
}

