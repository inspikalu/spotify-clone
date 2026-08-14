import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_clone/core/errors.dart';
import 'package:spotify_clone/features/tracks/tracks_providers.dart';

class UploadTrackScreen extends ConsumerStatefulWidget {
  const UploadTrackScreen({super.key});

  @override
  ConsumerState<UploadTrackScreen> createState() => _UploadTrackScreenState();
}

class _UploadTrackScreenState extends ConsumerState<UploadTrackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();

  PlatformFile? _audioFile;
  PlatformFile? _coverFile;
  bool _uploading = false;
  double? _progress;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final file = await FilePicker.pickFile(type: FileType.audio);
    if (file == null) {
      return;
    }
    setState(() {
      _audioFile = file;
      _error = null;
    });
  }

  Future<void> _pickCover() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) {
      return;
    }
    setState(() {
      _coverFile = file;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final audioFile = _audioFile;
    if (audioFile == null) {
      setState(() => _error = 'Pick an audio file first');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _uploading = true;
      _progress = 0;
      _error = null;
    });
    try {
      await ref.read(tracksRepositoryProvider).uploadTrack(
            title: _titleController.text.trim(),
            artist: _artistController.text.trim(),
            album: _albumController.text.trim().isEmpty
                ? null
                : _albumController.text.trim(),
            audioPath: audioFile.path!,
            audioName: audioFile.name,
            coverPath: _coverFile?.path,
            onProgress: (sent, total) {
              if (total <= 0) {
                return;
              }
              setState(() => _progress = sent / total);
            },
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      setState(() {
        _uploading = false;
        _progress = null;
        _error = apiErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload track')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a title'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _artistController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Artist',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter an artist'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _albumController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Album (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              _AudioPickerButton(
                file: _audioFile,
                onPressed: _uploading ? null : _pickAudio,
              ),
              const SizedBox(height: 12),
              _CoverPickerButton(
                file: _coverFile,
                onPressed: _uploading ? null : _pickCover,
              ),
              if (_uploading && _progress != null) ...[
                const SizedBox(height: 24),
                LinearProgressIndicator(
                  value: _progress,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uploading ${(_progress! * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _uploading ? null : _submit,
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload),
                label: Text(_uploading ? 'Uploading…' : 'Upload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioPickerButton extends StatelessWidget {
  const _AudioPickerButton({required this.file, required this.onPressed});

  final PlatformFile? file;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final selected = file != null;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(selected ? Icons.audiotrack : Icons.music_note),
      label: Text(
        selected ? file!.name : 'Pick audio file',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _CoverPickerButton extends StatelessWidget {
  const _CoverPickerButton({required this.file, required this.onPressed});

  final PlatformFile? file;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final selected = file != null;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(selected ? Icons.image : Icons.add_photo_alternate_outlined),
      label: Text(
        selected ? file!.name : 'Pick cover image (optional)',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}