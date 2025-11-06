import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Initialization errors will be reported in the UI.
  }
  runApp(const LibraryApp());
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library Book Manager',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const LibraryHomePage(),
    );
  }
}

class LibraryHomePage extends StatefulWidget {
  const LibraryHomePage({super.key});

  @override
  State<LibraryHomePage> createState() => _LibraryHomePageState();
}

class _LibraryHomePageState extends State<LibraryHomePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _copiesController = TextEditingController();

  bool _initError = false;
  bool _isSearching = false;
  String? _notFoundMessage;
  List<Map<String, dynamic>> _results = [];
  String? _selectedDocId;

  @override
  void initState() {
    super.initState();
    Firebase.apps.isEmpty ? _initError = true : _initError = false;
  }

  Future<void> _searchBook() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _isSearching = true;
      _notFoundMessage = null;
      _results = [];
    });

    try {
      final col = FirebaseFirestore.instance.collection('books');

      // Exact title match.
      final snapshot = await col.where('title', isEqualTo: title).get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _notFoundMessage = 'Book not found';
        });
      } else {
        final list = snapshot.docs.map((d) {
          final data = d.data();
          final copies = (data['copies'] is int)
              ? data['copies'] as int
              : (data['copies'] is double)
              ? (data['copies'] as double).toInt()
              : int.tryParse('${data['copies']}') ?? 0;
          return {
            'id': d.id,
            'title': data['title'] ?? '',
            'author': data['author'] ?? '',
            'copies': copies,
          };
        }).toList();

        setState(() {
          _results = list;
          // Reset selection when new search happens
          _selectedDocId = null;
          _copiesController.clear();
        });
      }
    } catch (e) {
      setState(() {
        _notFoundMessage = 'Error searching books: $e';
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _updateCopies() async {
    final copyText = _copiesController.text.trim();
    final parsed = int.tryParse(copyText);
    if (parsed == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid integer for copies.'),
        ),
      );
      return;
    }

    try {
      final col = FirebaseFirestore.instance.collection('books');
      await col.doc(_selectedDocId).update({'copies': parsed});

      if (!mounted) return;
      setState(() {
        for (var r in _results) {
          if (r['id'] == _selectedDocId) r['copies'] = parsed;
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copies updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update copies: $e')));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _copiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Library Book Search')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 12),
                Text(
                  'Firebase is not initialized.\nPlease add your google-services.json (Android) or configure Firebase for your platform and restart the app.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Library Book Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Enter book title',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _searchBook(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _copiesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Updated number of copies',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _searchBook,
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    _titleController.clear();
                    _copiesController.clear();
                    setState(() {
                      _results = [];
                      _notFoundMessage = null;
                      _selectedDocId = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (_isSearching) const CircularProgressIndicator(),

            if (!_isSearching && _notFoundMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  _notFoundMessage!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),

            if (!_isSearching && _results.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    final docId = item['id'] as String?;
                    final copies = item['copies'] as int? ?? 0;
                    final isUnavailable = copies == 0;
                    final isSelected =
                        (_selectedDocId != null && _selectedDocId == docId);

                    return ListTile(
                      title: Text('${item['title']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Author: ${item['author']}'),
                          const SizedBox(height: 4),
                          Text('Copies Available: $copies'),
                          if (isUnavailable) const SizedBox(height: 6),
                          if (isUnavailable)
                            const Text(
                              'Not Available – All Copies Issued',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      tileColor: isSelected
                          ? Colors.indigo.withOpacity(0.08)
                          : null,
                      onTap: docId == null
                          ? null
                          : () {
                              setState(() {
                                _selectedDocId = docId;
                                _copiesController.text = copies.toString();
                              });
                            },
                      trailing: isSelected ? const Icon(Icons.edit) : null,
                    );
                  },
                ),
              ),
            if (_selectedDocId != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _updateCopies,
                      icon: const Icon(Icons.update),
                      label: const Text('Update'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
