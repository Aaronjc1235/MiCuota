import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _selectedImage;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  final List<String> _profileImages = [
    'lib/assets/images/avatar1.png',
    'lib/assets/images/avatar2.png',
    'lib/assets/images/avatar3.png',
    'lib/assets/images/avatar4.png',
    'lib/assets/images/avatar5.png',
    'lib/assets/images/avatar6.png',
    'lib/assets/images/avatar7.png',
    'lib/assets/images/avatar8.png',
    'lib/assets/images/avatar9.png',
    'lib/assets/images/avatar10.png',
    'lib/assets/images/avatar11.png',
    'lib/assets/images/avatar12.png',
    'lib/assets/images/avatar13.png',
    'lib/assets/images/avatar14.png',
    'lib/assets/images/avatar15.png',
    'lib/assets/images/avatar16.png',
    'lib/assets/images/avatar18.png',
    'lib/assets/images/avatar19.png',
    'lib/assets/images/avatar20.png',
    'lib/assets/images/avatar21.png',
    'lib/assets/images/avatar22.png',
    'lib/assets/images/avatar23.png',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final result = await FirebaseFirestore.instance
          .collection('users')
          .where('nombre', isGreaterThanOrEqualTo: query)
          .where('nombre', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      setState(() {
        _searchResults = result.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['userId'] = doc.id;
          return data;
        }).toList();
      });
      _showSearchResultsDialog(); // Añade esta línea
    } catch (e) {
      print("Error en búsqueda: $e");
    }
  }
  void _showSearchResultsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Resultados de la búsqueda',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              _searchResults.isEmpty
                  ? const Text('No se encontraron usuarios.')
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    title: Text(user['nombre'] ?? 'Sin nombre'),
                    subtitle: Text(user['email'] ?? 'Sin correo'),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.blue),
                      onPressed: () {
                        _sendFriendRequest(user['userId']);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendFriendRequest(String toUserId) async {
    final fromUserId = FirebaseAuth.instance.currentUser?.uid;

    await FirebaseFirestore.instance.collection('friend_requests').add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': 'pending',
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(toUserId)
        .update({
      'pendingRequests': FieldValue.arrayUnion([widget.userId]),
    });

    setState(() {
      _searchResults.removeWhere((user) => user['userId'] == toUserId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Solicitud enviada')),
    );
  }

  void _showImageSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Elige una imagen de perfil",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                    ),
                    itemCount: _profileImages.length,
                    itemBuilder: (BuildContext context, int index) {
                      final imagePath = _profileImages[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = imagePath;
                          });
                          Navigator.pop(context);
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.userId)
                              .update({'profileImage': _selectedImage});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedImage == imagePath
                                  ? Colors.blue
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
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
        );
      },
    );
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar usuarios...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: const Color(0xFF1CC0C6), width: 2),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _searchUsers(_searchController.text),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF1B1919),
        ),
        child: Column(
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar los datos.'));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('No se encontraron datos del usuario.'));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final String userName = userData['nombre'] ?? 'Nombre no disponible';
                final String userLastName = userData['apellido'] ?? 'Apellido no disponible';
                final String userNickname = userData['nickName'] ?? 'Apodo no disponible';
                final int contacts = userData['contacts'] ?? 0;
                _selectedImage = userData['profileImage'] ?? 'lib/assets/images/avatar1.png';

                return Column(
                  children: [
                    Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1CC0C6),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 60),
                                Text(
                                  '$userName $userLastName',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '@: $userNickname',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildStatColumn(
                                          'CONTACTOS', contacts.toString()),
                                      _buildStatColumn('WISHED', '271'),
                                      _buildStatColumn('LIKES', '12K'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 50,
                          left: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImageSelectionDialog,
                            child: Center(
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.white,
                                            child: const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Color(0xFF1CC0C6),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF0D7377),
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 20,
                                        color: Color(0xFF0D7377),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSearchField(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
