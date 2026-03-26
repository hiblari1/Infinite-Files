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
    const seed = Color(0xFFCB97D8);
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Infinite Files',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF130D17),
        textTheme: Typography.whiteCupertino,
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

  SortMode _sortMode = SortMode.modified;
  bool _ascending = false;
  bool _loading = false;

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
    final common = [
      home,
      Directory(p.join(home.path, 'Documents')),
      Directory(p.join(home.path, 'Downloads')),
      Directory(p.join(home.path, 'Pictures')),
      Directory(p.join(home.path, 'Videos')),
    ];

    _favorites.addAll(common.where((element) => element.existsSync()));
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
        nodes.add(
          FileNode(
            entity: entity,
            name: p.basename(entity.path),
            modified: stat.modified,
            size: entity is File ? stat.size : null,
          ),
        );
      }

      setState(() {
        _currentDirectory = directory;
        _entries = nodes;
      });
    } catch (_) {
      _toast('Cannot open ${directory.path}');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createFolder() async {
    if (_currentDirectory == null) return;

    _folderController.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create folder'),
        content: TextField(
          controller: _folderController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'new folder'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );

    if (confirmed != true) return;

    final name = _folderController.text.trim();
    if (name.isEmpty) return;

    try {
      final folder = Directory(p.join(_currentDirectory!.path, name));
      if (folder.existsSync()) {
        _toast('Folder already exists');
        return;
      }
      await folder.create(recursive: true);
      await _openDirectory(_currentDirectory!);
      _toast('Created $name');
    } catch (_) {
      _toast('Failed creating folder');
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  List<FileNode> get _visibleEntries {
    final q = _searchController.text.trim().toLowerCase();
    var list = _entries.where((e) => e.name.toLowerCase().contains(q)).toList();

    list.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;

      int cmp;
      switch (_sortMode) {
        case SortMode.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case SortMode.modified:
          cmp = a.modified.compareTo(b.modified);
          break;
        case SortMode.size:
          cmp = (a.size ?? -1).compareTo(b.size ?? -1);
          break;
      }
      return _ascending ? cmp : -cmp;
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.25,
            center: Alignment.topLeft,
            colors: [Color(0xFF2A1830), Color(0xFF130D17), Color(0xFF100B14)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _ShellSidebar(
                  favorites: _favorites,
                  current: _currentDirectory,
                  onPick: _openDirectory,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: const Color(0xB0120C15),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TopPathBar(current: _currentDirectory),
                              Expanded(
                                child: _loading
                                    ? const Center(child: CircularProgressIndicator())
                                    : Padding(
                                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 72),
                                        child: _WallpaperLikeGrid(
                                          entries: _visibleEntries,
                                          formatter: formatter,
                                          onOpenDir: (dir) => _openDirectory(dir),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: _BottomCommandBar(
                              controller: _searchController,
                              onRefresh: () {
                                if (_currentDirectory != null) {
                                  _openDirectory(_currentDirectory!);
                                }
                              },
                              onNewFolder: _createFolder,
                              selectedSort: _sortMode,
                              onSortChanged: (mode) => setState(() => _sortMode = mode),
                              onSortDirection: () => setState(() => _ascending = !_ascending),
                              onSearchChanged: () => setState(() {}),
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

class _ShellSidebar extends StatelessWidget {
  const _ShellSidebar({
    required this.favorites,
    required this.current,
    required this.onPick,
  });

  final List<Directory> favorites;
  final Directory? current;
  final ValueChanged<Directory> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xAA1C1420),
        border: Border.all(color: const Color(0x44FFFFFF)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pick a wallpaper', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final dir = favorites[index];
                final active = current?.path == dir.path;
                final label = p.basename(dir.path).isEmpty ? dir.path : p.basename(dir.path);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    tileColor: active ? const Color(0x88CA95D7) : Colors.transparent,
                    leading: Icon(active ? Icons.check_box : Icons.check_box_outline_blank, size: 15, color: Colors.white54),
                    title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    onTap: () => onPick(dir),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPathBar extends StatelessWidget {
  const _TopPathBar({required this.current});

  final Directory? current;

  @override
  Widget build(BuildContext context) {
    final path = current?.path ?? '';
    final segments = path.split(RegExp(r'[\\/]')).where((e) => e.isNotEmpty).toList();
    final crumbs = segments.length > 4 ? segments.sublist(segments.length - 4) : segments;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.folder_open, size: 14, color: Colors.white60),
            const SizedBox(width: 8),
            for (final c in crumbs)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x553A233F),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x35FFFFFF)),
                ),
                child: Text(c, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ),
          ],
        ),
      ),
    );
  }
}

class _WallpaperLikeGrid extends StatelessWidget {
  const _WallpaperLikeGrid({
    required this.entries,
    required this.formatter,
    required this.onOpenDir,
  });

  final List<FileNode> entries;
  final DateFormat formatter;
  final ValueChanged<Directory> onOpenDir;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('No files found', style: TextStyle(color: Colors.white60)));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.35,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final node = entries[index];
        final featured = index % 5 == 0;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (node.isDirectory) {
              onOpenDir(node.entity as Directory);
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: featured ? const Color(0xFFCC9BD5) : const Color(0x11FFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: Center(
                    child: Text(
                      node.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: featured ? const Color(0xFF35243B) : Colors.white60,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(formatter.format(node.modified), style: const TextStyle(fontSize: 9, color: Colors.white54)),
            ],
          ),
        );
      },
    );
  }
}

class _BottomCommandBar extends StatelessWidget {
  const _BottomCommandBar({
    required this.controller,
    required this.onRefresh,
    required this.onNewFolder,
    required this.selectedSort,
    required this.onSortChanged,
    required this.onSortDirection,
    required this.onSearchChanged,
  });

  final TextEditingController controller;
  final VoidCallback onRefresh;
  final VoidCallback onNewFolder;
  final SortMode selectedSort;
  final ValueChanged<SortMode> onSortChanged;
  final VoidCallback onSortDirection;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      constraints: const BoxConstraints(maxWidth: 430),
      decoration: BoxDecoration(
        color: const Color(0xCC251D2A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        children: [
          IconButton(onPressed: onNewFolder, icon: const Icon(Icons.create_new_folder_outlined, size: 16), tooltip: 'New Folder'),
          IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded, size: 16), tooltip: 'Refresh'),
          IconButton(onPressed: onSortDirection, icon: const Icon(Icons.swap_vert_rounded, size: 16), tooltip: 'Sort Direction'),
          DropdownButtonHideUnderline(
            child: DropdownButton<SortMode>(
              value: selectedSort,
              dropdownColor: const Color(0xFF231A28),
              onChanged: (mode) {
                if (mode != null) onSortChanged(mode);
              },
              items: const [
                DropdownMenuItem(value: SortMode.modified, child: Text('Modified', style: TextStyle(fontSize: 11))),
                DropdownMenuItem(value: SortMode.name, child: Text('Name', style: TextStyle(fontSize: 11))),
                DropdownMenuItem(value: SortMode.size, child: Text('Size', style: TextStyle(fontSize: 11))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onSearchChanged(),
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Hit / to search',
                hintStyle: TextStyle(fontSize: 12),
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
