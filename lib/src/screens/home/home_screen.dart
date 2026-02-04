import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handleImageSelection(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    // For now we just pick the image to demonstrate functionality, implementation will come later.
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        // TODO: Navigate to analysis screen with image path
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected: ${image.name}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispersion Analyzer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Text(
              'Start Analysis',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ).animate().fadeIn().slideX(begin: -0.2),
            const SizedBox(height: 8),
            Text(
              'Choose a method to import your target',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[400],
                  ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 40),
            
            Expanded(
              child: _ActionCard(
                icon: Icons.upload_file_rounded,
                title: 'Upload Image',
                subtitle: 'Select from gallery',
                color: Colors.blueAccent,
                delay: 400.ms,
                onTap: () => _handleImageSelection(context, ImageSource.gallery),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _ActionCard(
                icon: Icons.camera_alt_rounded,
                title: 'Take Photo',
                subtitle: 'Capture new target',
                color: Colors.tealAccent.shade700,
                delay: 600.ms,
                onTap: () => _handleImageSelection(context, ImageSource.camera),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Duration delay;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardTheme.color!,
                Theme.of(context).cardTheme.color!.withValues(alpha: 0.8),
              ],
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                ),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(delay: delay, duration: 500.ms, curve: Curves.easeOutBack).fadeIn(delay: delay);
  }
}
