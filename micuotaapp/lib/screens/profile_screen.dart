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
  int debtsCount = 0; // Contador de deudas
  int debtorsCount = 0; // Contador de deudores


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
  int pendingRequestsCount = 0;
  List<Map<String, dynamic>> pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
    _loadDebtsCount();
    _loadDebtorsCount();
  }
  void _loadPendingRequests() {
    FirebaseFirestore.instance
        .collection('friend_requests')
        .where('toUserId', isEqualTo: widget.userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        pendingRequestsCount = snapshot.docs.length;
        pendingRequests = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    });
  }
  void _loadDebtsCount() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('debts') // Subcolección de deudas
        .snapshots()
        .listen((snapshot) {
      setState(() {
        debtsCount = snapshot.docs.length; // Actualiza el contador de deudas
      });
    });
  }

  void _loadDebtorsCount() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('debtors') // Subcolección de deudores
        .snapshots()
        .listen((snapshot) {
      setState(() {
        debtorsCount = snapshot.docs.length; // Actualiza el contador de deudores
      });
    });
  }

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
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      final result = await FirebaseFirestore.instance
          .collection('users')
          .where('nombre', isGreaterThanOrEqualTo: query)
          .where('nombre', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      setState(() {
        _searchResults = result.docs
            .where((doc) => doc.id != currentUserId) // Exclude the current user
            .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['userId'] = doc.id;
          return data;
        }).toList();
      });
      _showSearchResultsDialog();
    } catch (e) {
      print("Error en búsqueda: $e");
    }
  }

  void _showSearchResultsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Color(0xFF1B1919),
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
                  color: Colors.white, // Cambiado a blanco
                ),
              ),
              const SizedBox(height: 16.0),
              _searchResults.isEmpty
                  ? const Text('No se encontraron usuarios.', style: TextStyle (color: Colors.white),)
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    title: Text(user['nombre'] ?? 'Sin nombre', style: const TextStyle(color: Colors.white),),
                    subtitle: Text(user['email'] ?? 'Sin correo', style: const TextStyle(color: Colors.white)),
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
                child: const Text('Cerrar', style: TextStyle(color: Colors.white)), // Cambiado a blanco
              ),
            ],
          ),
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
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _sendFriendRequest(String toUserId) async {
    final fromUserId = FirebaseAuth.instance.currentUser?.uid;

    // Validar si ya son amigos
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(fromUserId).get();
    final userFriends = List<String>.from(userDoc.data()?['friendsList'] ?? []);

    if (userFriends.contains(toUserId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya tienes a este usuario como amigo')),
      );
      return;
    }

    // Validar si ya existe una solicitud pendiente
    final existingRequest = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .get();
    final blockedUsers = await FirebaseFirestore.instance
        .collection('blocked_users')
        .where('blockerId', isEqualTo: fromUserId)
        .where('blockedId', isEqualTo: toUserId)
        .get();

    if (blockedUsers.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes enviar solicitudes a este usuario')),
      );
      return;
    }
    final pendingRequests = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: fromUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (pendingRequests.docs.length >= 10) { // Límite de 10 solicitudes
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has alcanzado el límite de solicitudes pendientes')),
      );
      return;
    }
    final blockedByUser = await FirebaseFirestore.instance
        .collection('blocked_users')
        .where('blockerId', isEqualTo: toUserId)
        .where('blockedId', isEqualTo: fromUserId)
        .get();

    if (blockedByUser.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes enviar solicitudes a este usuario')),
      );
      return;
    }

    if (existingRequest.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya existe una solicitud pendiente')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('friend_requests').add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Solicitud enviada')),
    );
  }

  Future<void> _acceptFriendRequest(String requestId, String fromUserId) async {
    // Actualizar el estado de la solicitud
    await FirebaseFirestore.instance
        .collection('friend_requests')
        .doc(requestId)
        .update({'status': 'accepted'});
    await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
      'contacts': FieldValue.increment(1),
      'friendsList': FieldValue.arrayUnion([fromUserId])
    });

    await FirebaseFirestore.instance.collection('users').doc(fromUserId).update({
      'contacts': FieldValue.increment(1),
      'friendsList': FieldValue.arrayUnion([widget.userId])
    });
  }
  Future<void> _rejectFriendRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('friend_requests')
        .doc(requestId)
        .update({'status': 'rejected'});
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
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              textAlignVertical: TextAlignVertical.center, // Agregado
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
              onSubmitted: (value) => _searchUsers(value),
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

  void _showContactsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF424242), // Color gris oscuro
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: const Color(0xFF424242),
                  child: const TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFF1CC0C6),
                    tabs: [
                      Tab(text: 'Solicitudes'),
                      Tab(text: 'Contactos'),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFF424242),
                    child: TabBarView(
                      children: [
                        _buildRequestsTab(),  // Ahora usamos el widget que construimos
                        _buildContactsTab(),  // Necesitamos crear este widget
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Añade este método para mostrar los contactos
  Widget _buildContactsTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Error al cargar los contactos',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final List<dynamic> friendsList = userData?['friendsList'] ?? [];

        if (friendsList.isEmpty) {
          return const Center(
            child: Text(
              'No tienes contactos aún',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView.builder(
          itemCount: friendsList.length,
          itemBuilder: (context, index) {
            final friendId = friendsList[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(friendId)
                  .get(),
              builder: (context, friendSnapshot) {
                if (!friendSnapshot.hasData) {
                  return const ListTile(
                    title: Text(
                      'Cargando...',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final friendData = friendSnapshot.data!.data() as Map<String, dynamic>;
                final friendName = friendData['nombre'] ?? 'Usuario';
                final friendImage = friendData['profileImage'] ?? 'lib/assets/images/avatar1.png';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(friendImage),
                  ),
                  title: Text(
                    friendName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    friendData['nickName'] ?? '@usuario',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('toUserId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Error al cargar las solicitudes',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return const Center(
            child: Text(
              'No hay solicitudes pendientes',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final requestData = request.data() as Map<String, dynamic>;
            final requestId = request.id;
            final fromUserId = requestData['fromUserId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(fromUserId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(
                    title: Text(
                      'Cargando...',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final userName = userData['nombre'] ?? 'Usuario';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(
                      userData['profileImage'] ?? 'lib/assets/images/avatar1.png',
                    ),
                  ),
                  title: Text(
                    userName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    userData['nickName'] ?? '@usuario',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          _acceptFriendRequest(requestId, fromUserId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Solicitud aceptada')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          _rejectFriendRequest(requestId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Solicitud rechazada')),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1919),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1919),
        automaticallyImplyLeading: false,
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 10),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            textAlignVertical: TextAlignVertical.center, // Centrar el texto verticalmente
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
            onSubmitted: (value) => _searchUsers(value),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.people, color: Colors.white),
                onPressed: _showContactsBottomSheet,
              ),
              if (pendingRequestsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '$pendingRequestsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
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
                return const Center(child: Text('Error al cargar los datos.', style: TextStyle(color: Colors.white)));
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('No se encontraron datos del usuario.', style: TextStyle(color: Colors.white)));
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
                        padding: const EdgeInsets.only(top: 100), // Ajusta este valor
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1CC0C6),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
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
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatColumn('CONTACTOS',
                                        userData['contacts']?.toString() ?? '0'), // Contactos
                                    _buildStatColumn('DEUDAS', debtsCount.toString()), // Deudas
                                    _buildStatColumn('DEUDORES', debtorsCount.toString()), // Deudores
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 50, // Ajusta este valor para cambiar la posición vertical de la imagen
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
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}