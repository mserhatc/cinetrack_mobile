import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_theme.dart';

class AvatarPickerDialog extends StatefulWidget {
  final String? initialAvatar;

  const AvatarPickerDialog({super.key, this.initialAvatar});

  static Future<String?> show(BuildContext context, {String? initialAvatar}) {
    return showShadDialog<String>(
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
    return ShadDialog(
      title: const Text('Profil Fotoğrafı Seç'),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ShadButton(
          onPressed: () {
            Navigator.pop(context, _selectedAvatar.trim());
          },
          backgroundColor: AppTheme.primaryColor,
          child: const Text('Seç', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
      child: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Canlı Önizleme (ShadAvatar)
              if (_selectedAvatar.isNotEmpty)
                ShadAvatar(
                  _selectedAvatar,
                  size: const Size.square(80),
                  placeholder: const Icon(Icons.person, size: 40),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF0F1F5),
                  ),
                  child: const Icon(Icons.person, size: 40, color: Colors.grey),
                ),
              const SizedBox(height: 16),
              const Text(
                'Hazır Avatarlardan Seçin:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              // Preset Avatar Grid
              Wrap(
                spacing: 10,
                runSpacing: 10,
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
                          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ShadAvatar(
                        url,
                        size: const Size.square(42),
                        placeholder: const Icon(Icons.person, size: 20),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 8),
              // Özel URL Alanı (ShadInput)
              ShadInput(
                controller: _urlController,
                placeholder: const Text('https://ornek.com/foto.jpg'),
                leading: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.link_rounded, size: 18),
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
    );
  }
}
