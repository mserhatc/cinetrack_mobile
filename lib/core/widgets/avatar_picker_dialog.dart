import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
    _selectedAvatar = (widget.initialAvatar != null && widget.initialAvatar!.isNotEmpty)
        ? widget.initialAvatar!
        : _presetAvatars.first;
    _urlController = TextEditingController(text: widget.initialAvatar ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Profil Fotoğrafı Seç',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.softGreyBg,
                ),
                child: ClipOval(
                  child: Image.network(
                    _selectedAvatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.person, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Hazır Sinema Karakterleri:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _presetAvatars.map((avatarUrl) {
                final isSelected = _selectedAvatar == avatarUrl;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatar = avatarUrl;
                      _urlController.text = avatarUrl;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        avatarUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.person, size: 24),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text(
              'Veya Özel Görsel Bağlantısı (URL):',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: 'https://ornek.com/foto.jpg',
                prefixIcon: Icon(Icons.link, size: 18),
              ),
              onChanged: (val) {
                if (val.trim().startsWith('http')) {
                  setState(() {
                    _selectedAvatar = val.trim();
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(color: AppTheme.mutedText)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedAvatar.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text(
            'Seç',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
