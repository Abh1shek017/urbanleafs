import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminChecker extends StatefulWidget {
  final Widget Function(BuildContext context, bool isAdmin) builder;

  const AdminChecker({super.key, required this.builder});

  @override
  State<AdminChecker> createState() => _AdminCheckerState();
}

class _AdminCheckerState extends State<AdminChecker> {
  bool? isAdmin;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isAdmin = false);
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final role = doc.data()?['role'] ?? '';
    setState(() => isAdmin = role == 'admin');
  }

  @override
  Widget build(BuildContext context) {
    if (isAdmin == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return widget.builder(context, isAdmin!);
  }
}
