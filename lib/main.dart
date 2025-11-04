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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _copiesController = TextEditingController();

  bool _initError = false;

  @override
  void initState() {
    super.initState();
    // Basic check: if Firebase isn't initialized, attempts to use Firestore will fail at runtime.
    // We keep a lightweight flag to show the user helpful instructions.
    Firebase.apps.isEmpty ? _initError = true : _initError = false;
  }

  Future<void> _addBook() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final copies = int.tryParse(_copiesController.text.trim()) ?? 0;

    final col = FirebaseFirestore.instance.collection('books');
    await col.add({
      'title': title,
      'author': author,
      'copies': copies,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _titleController.clear();
    _authorController.clear();
    _copiesController.clear();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Book added')));
    }
  }

  Future<void> _deleteBook(String docId) async {
    await FirebaseFirestore.instance.collection('books').doc(docId).delete();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _copiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Library Book Manager')),
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

    final booksCollection = FirebaseFirestore.instance.collection('books');

    return Scaffold(
      appBar: AppBar(title: const Text('Library Book Manager')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Book Title'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Enter book title';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(labelText: 'Author'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Enter author name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _copiesController,
                    decoration: const InputDecoration(
                      labelText: 'Number of copies',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Enter number of copies';
                      final n = int.tryParse(v);
                      if (n == null || n < 0)
                        return 'Enter a valid non-negative integer';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _addBook,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Book'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          _titleController.clear();
                          _authorController.clear();
                          _copiesController.clear();
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Live list of books
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: booksCollection.orderBy('title').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty)
                    return const Center(child: Text('No books yet'));

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final d = docs[index];
                            final data = d.data();
                            final title = data['title'] ?? '';
                            final author = data['author'] ?? '';
                            final copies = (data['copies'] is int)
                                ? data['copies'] as int
                                : (data['copies'] is double)
                                ? (data['copies'] as double).toInt()
                                : int.tryParse('${data['copies']}') ?? 0;

                            final isUnavailable = copies == 0;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text('$title'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Author: $author'),
                                    const SizedBox(height: 4),
                                    Text('Copies Available: $copies'),
                                    if (isUnavailable)
                                      const SizedBox(height: 6),
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
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete book'),
                                        content: const Text(
                                          'Delete this book from Firestore?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true) await _deleteBook(d.id);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Total count
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Total Books in Library: ${docs.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
