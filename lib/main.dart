import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class User {
  final int id;
  final String name;
  final String email;
  final String? firstName; 
  final String? lastName;  
  final String? avatar;    
  DateTime? updatedAt;
  DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.firstName,
    this.lastName,
    this.avatar,
    this.updatedAt,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['first_name'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      avatar: json['avatar'],
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}

class UserController extends GetxController {
  var userList = <User>[].obs;
  var nameController = TextEditingController();
  var emailController = TextEditingController();
  var selectedUser = User(id: 0, name: '', email: '');

  @override
  void onInit() {
    fetchUsers();
    super.onInit();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('https://reqres.in/api/users'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        userList.assignAll(data.map<User>((json) => User.fromJson(json)));
      }
    } catch (error) {
      print('Failed to fetch data: $error');
    }
  }

  Future<void> addUser(String name, String email, String firstName, String lastName) async {
    try {
      if (name.isEmpty) {
        print('Name and email are required.');
        return;
      }

      final response = await http.post(
        Uri.parse('https://reqres.in/api/users'),
        body: {
          'name': name,
          'email': email,
          'first_name': firstName, 
          'last_name': lastName,   
        },
      );

      if (response.statusCode == 201) {
        final userData = json.decode(response.body);
        final newUserId = int.parse(userData['id']);

        if (userList.any((user) => user.id == newUserId)) {
          print('User with ID $newUserId already exists in the list.');
        } else {
          final newUser = User(
            id: newUserId,
            name: userData['name'],
            email: userData['email'],
            firstName: firstName,
            lastName: lastName,
            createdAt: DateTime.now(),
          );
          userList.add(newUser);
          nameController.clear();
          emailController.clear();
          Get.back();
        }
      } else {
        print('Failed to add user. Unexpected response status: ${response.statusCode}');
      }
    } catch (error) {
      print('Failed to add user: $error');
    }
  }

  Future<void> updateUser(int id, String name, String email, String firstName, String lastName) async {
    try {
      final response = await http.put(
        Uri.parse('https://reqres.in/api/users/$id'),
        body: {
          'name': name,
          'email': email,
          'first_name': firstName, 
          'last_name': lastName,   
        },
      );

      if (response.statusCode == 200) {
        final updatedUserIndex = userList.indexWhere((user) => user.id == id);
        if (updatedUserIndex != -1) {
          final originalUser = userList[updatedUserIndex];

          userList[updatedUserIndex] = User(
            id: id,
            name: name,
            email: email,
            firstName: firstName,
            lastName: lastName,
            avatar: originalUser.avatar,
          );

          userList[updatedUserIndex].updatedAt = DateTime.now();
          Get.back();
        } else {
          print('Failed to update user. User not found in the list.');
        }
      } else if (response.statusCode == 404) {
        print('User not found (404): Please check the user ID.');
      } else {
        print('Failed to update user. Unexpected response status: ${response.statusCode}');
      }
    } catch (error) {
      print('Failed to update user: $error');
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('https://reqres.in/api/users/$id'),
      );

      if (response.statusCode == 204) {
        userList.removeWhere((user) => user.id == id);
      } else if (response.statusCode == 404) {
        print('User not found (404): Please check the user ID.');
      } else {
        print('Failed to delete user. Unexpected response status: ${response.statusCode}');
      }
    } catch (error) {
      print('Failed to delete user: $error');
    }
  }
}

class SplashPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Get.offAllNamed('/home');
    });

    return Scaffold(
      body: Container(
        color: Colors.white, 
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.network(
                'https://media.cdnandroid.com/item_images/1293086/imagen-pari-pasar-rakyat-indonesia-0ori.jpg',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome!',
                style: TextStyle(fontSize: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final UserController userController = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: SplashPage(),
      getPages: [
        GetPage(name: '/home', page: () => HomeScreen()),
        GetPage(name: '/create', page: () => CreateUserScreen()),
        GetPage(name: '/userDetail', page: () => UserDetailScreen()),
        GetPage(name: '/notFound', page: () => NotFoundScreen()),
        GetPage(name: '/userDetail', page: () => UserDetailScreen()),
      ],
    );
  }
}

class HomeScreen extends StatelessWidget {
  final UserController userController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User List'),
      ),
      body: Obx(
        () {
          if (userController.userList.isEmpty) {
            return const Center(child: Text('No users available'));
          }
          return ListView.builder(
            itemCount: userController.userList.length,
            itemBuilder: (context, index) {
              final user = userController.userList[index];
              return ListTile(
                leading: user.avatar != null
                    ? Image.network(
                        user.avatar!,
                        width: 40,
                        height: 40,
                      )
                    : const SizedBox.shrink(),
                title: Row(
                  children: [
                    Text(user.name),
                  ],
                ),
                subtitle: Text(user.email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Get.to(CreateUserScreen(), arguments: user);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        userController.deleteUser(user.id);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  userController.selectedUser = user;
                  Get.toNamed('/userDetail');
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed('/create');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CreateUserScreen extends StatelessWidget {
  final UserController userController = Get.find();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController(); 
  final TextEditingController lastNameController = TextEditingController();  

  @override
  Widget build(BuildContext context) {
    final User? user = Get.arguments;
    final isEditing = user != null;

    if (isEditing) {
      nameController.text = user.name;
      emailController.text = user.email;
      firstNameController.text = user.firstName ?? '';
      lastNameController.text = user.lastName ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Update user' : 'Add user'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            if (isEditing)
              Column(
                children: [
                  TextField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                  TextField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                ],
              ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text;
                final email = emailController.text;
                final firstName = firstNameController.text; 
                final lastName = lastNameController.text;   
                if (name.isNotEmpty && email.isNotEmpty) {
                  if (isEditing) {
                    userController.updateUser(user.id, name, email, firstName, lastName); 
                  } else {
                    userController.addUser(name, email, firstName, lastName); 
                  }
                  Get.back();
                }
              },
              child: Text(isEditing ? 'Perbarui Pengguna' : 'Tambah Pengguna'),
            ),
          ],
        ),
      ),
    );
  }
}
class UserDetailScreen extends StatelessWidget {
  final UserController userController = Get.find();

  @override
  Widget build(BuildContext context) {
    final User user = userController.selectedUser;
    final bool isExistingUser = user.createdAt != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Detail'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('ID: ${user.id}'),
            if (isExistingUser) Text('Name: ${user.name}'),
            Text('Email: ${user.email}'),
            if (!isExistingUser) Text('First Name: ${user.firstName ?? "N/A"}'),
            if (!isExistingUser) Text('Last Name: ${user.lastName ?? "N/A"}'),
            if (user.avatar != null) Text('Avatar: ${user.avatar}'),
            if (user.updatedAt != null) Text('Updated At: ${user.updatedAt!.toLocal()}'),
            if (user.createdAt != null) Text('Created At: ${user.createdAt!.toLocal()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Get.back();
              },
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Not Found'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('User not found. Please check the user ID.'),
          ],
        ),
      ),
    );
  }
}