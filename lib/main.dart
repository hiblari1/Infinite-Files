import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InfiniteFilesApp());
}

class InfiniteFilesApp extends StatelessWidget {
  const InfiniteFilesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF9A8CFF),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Infinite Files',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF060711),
      ),
      home: const FileManagerScreen(),
    );
  }
}

class FileNode {
  FileNode({
    required this.entity,
    required this.name,
    required this.modified,
    required this.size,
  });

  final FileSystemEntity entity;
  final String name;
  final DateTime modified;
  final int? size;

  bool get isDirectory => entity is Directory;

  String get extension => isDirectory ? '' : p.extension(name).replaceFirst('.', '').toUpperCase();
}

enum SortMode { name, modified, size }

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _folderController = TextEditingController();

  final List<Directory> _favorites = [];
  List<FileNode> _entries = [];
  Directory? _currentDirectory;

  bool _loading = false;
  SortMode _sortMode = SortMode.modified;
  bool _ascending = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _folderController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final home = _resolveHomeDirectory();
    final docs = Directory(p.join(home.path, 'Documents'));
    final downloads = Directory(p.join(home.path, 'Downloads'));
    final desktop = Directory(p.join(home.path, 'Desktop'));

    _favorites.addAll(
      [home, docs, downloads, desktop].where((directory) => directory.existsSync()),
    );

    await _openDirectory(_favorites.isNotEmpty ? _favorites.first : home);
  }

  Directory _resolveHomeDirectory() {
    if (Platform.isWindows) {
      final profile = Platform.environment['USERPROFILE'];
      if (profile != null && profile.isNotEmpty) {
        return Directory(profile);
      }
    }

    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return Directory(home);
    }

    return Directory.current;
  }

  Future<void> _openDirectory(Directory directory) async {
    setState(() => _loading = true);
    try {
      final entities = directory.listSync(followLinks: false);
      final nodes = <FileNode>[];

      for (final entity in entities) {
        final stat = entity.statSync();
        final size = entity is File ? stat.size : null;

        nodes.add(
          FileNode(
            entity: entity,
            name: p.basename(entity.path),
            modified: stat.modified,
            size: size,
          ),
        );
      }

      setState(() {
        _currentDirectory = directory;
        _entries = nodes;
      });
    } catch (_) {
      _showSnack('Unable to open ${directory.path}');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createFolder() async {
    if (_currentDirectory == null) {
      return;
    }

    _folderController.clear();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create folder'),
          content: TextField(
            controller: _folderController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Folder name',
              hintText: 'new-folder',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (created != true) {
      return;
    }

    final name = _folderController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final folder = Directory(p.join(_currentDirectory!.path, name));
    if (folder.existsSync()) {
      _showSnack('Folder already exists.');
      return;
    }

    try {
      await folder.create(recursive: true);
      await _openDirectory(_currentDirectory!);
      _showSnack('Folder created: $name');
    } catch (_) {
      _showSnack('Failed to create folder.');
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  List<FileNode> get _visibleEntries {
    var list = [..._entries];
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((entry) => entry.name.toLowerCase().contains(q)).toList();
    }

    list.sort((a, b) {
      int comparison;
      switch (_sortMode) {
        case SortMode.name:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case SortMode.modified:
          comparison = a.modified.compareTo(b.modified);
          break;
        case SortMode.size:
          comparison = (a.size ?? -1).compareTo(b.size ?? -1);
          break;
      }

      if (a.isDirectory && !b.isDirectory) {
        return -1;
      }
      if (!a.isDirectory && b.isDirectory) {
        return 1;
      }

      return _ascending ? comparison : -comparison;
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = _currentDirectory?.path ?? 'Loading...';
    final formatter = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0D1F), Color(0xFF060711), Color(0xFF13103A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 290,
                  child: _Sidebar(
                    favorites: _favorites,
                    current: _currentDirectory,
                    onSelect: _openDirectory,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: const Color(0x221A1D35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                width: 320,
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search_rounded),
                                    hintText: 'Search in current folder',
                                  ),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: _createFolder,
                                icon: const Icon(Icons.create_new_folder_outlined),
                                label: const Text('New folder'),
                              ),
                              _SortDropdown(
                                mode: _sortMode,
                                ascending: _ascending,
                                onModeChanged: (mode) => setState(() => _sortMode = mode),
                                onDirectionChanged: () => setState(() => _ascending = !_ascending),
                              ),
                              ActionChip(
                                label: const Text('Refresh'),
                                avatar: const Icon(Icons.refresh_rounded, size: 18),
                                onPressed: () {
                                  if (_currentDirectory != null) {
                                    _openDirectory(_currentDirectory!);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentPath,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _loading
                                ? const Center(child: CircularProgressIndicator())
                                : _visibleEntries.isEmpty
                                    ? const Center(child: Text('No files found.'))
                                    : GridView.builder(
                                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 280,
                                          mainAxisSpacing: 10,
                                          crossAxisSpacing: 10,
                                          childAspectRatio: 1.8,
                                        ),
                                        itemCount: _visibleEntries.length,
                                        itemBuilder: (context, index) {
                                          final entry = _visibleEntries[index];
                                          return InkWell(
                                            borderRadius: BorderRadius.circular(18),
                                            onTap: () {
                                              if (entry.isDirectory) {
                                                _openDirectory(entry.entity as Directory);
                                              }
                                            },
                                            child: Ink(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(18),
                                                gradient: LinearGradient(
                                                  colors: entry.isDirectory
                                                      ? [const Color(0x409A8CFF), const Color(0x207FD7FF)]
                                                      : [const Color(0x307FD7FF), const Color(0x2085F6B6)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                border: Border.all(color: const Color(0x33FFFFFF)),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(12),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          entry.isDirectory ? Icons.folder_rounded : Icons.description_outlined,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            entry.name,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      entry.isDirectory
                                                          ? 'Directory'
                                                          : '${entry.extension.isEmpty ? 'File' : entry.extension} · ${_humanSize(entry.size ?? 0)}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(color: Colors.white70),
                                                    ),
                                                    Text(
                                                      'Modified ${formatter.format(entry.modified)}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(color: Colors.white54),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.mode,
    required this.ascending,
    required this.onModeChanged,
    required this.onDirectionChanged,
  });

  final SortMode mode;
  final bool ascending;
  final ValueChanged<SortMode> onModeChanged;
  final VoidCallback onDirectionChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton<SortMode>(
          value: mode,
          onChanged: (value) {
            if (value != null) {
              onModeChanged(value);
            }
          },
          items: const [
            DropdownMenuItem(value: SortMode.modified, child: Text('Sort: Modified')),
            DropdownMenuItem(value: SortMode.name, child: Text('Sort: Name')),
            DropdownMenuItem(value: SortMode.size, child: Text('Sort: Size')),
          ],
        ),
        IconButton(
          onPressed: onDirectionChanged,
          icon: Icon(ascending ? Icons.north_rounded : Icons.south_rounded),
          tooltip: ascending ? 'Ascending' : 'Descending',
        ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.favorites,
    required this.current,
    required this.onSelect,
  });

  final List<Directory> favorites;
  final Directory? current;
  final ValueChanged<Directory> onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0x221A1D35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0x559A8CFF), Color(0x337FD7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('∞ Infinite Files', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('M3 expressive desktop manager'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Favorites', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final dir = favorites[index];
                  final active = current?.path == dir.path;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      tileColor: active ? const Color(0x409A8CFF) : const Color(0x14000000),
                      leading: const Icon(Icons.folder_copy_rounded),
                      title: Text(p.basename(dir.path).isEmpty ? dir.path : p.basename(dir.path)),
                      subtitle: Text(dir.path, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => onSelect(dir),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _humanSize(int size) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  double current = size.toDouble();
  int unit = 0;

  while (current >= 1024 && unit < units.length - 1) {
    current /= 1024;
    unit++;
  }

  final formatted = unit == 0 ? current.toStringAsFixed(0) : current.toStringAsFixed(1);
  return '$formatted ${units[unit]}';
}
