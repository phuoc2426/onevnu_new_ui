import 'package:flutter/material.dart';
import 'package:vnu_core/widgets/vnu_module_app_bar.dart';
import 'package:get/get.dart';
import 'package:vnu_core/models/admitted_student.dart';
import 'package:vnu_core/repository/app_repository.dart';

/// Screen displaying the list of admitted students fetched from the backend.
class AdmittedStudentPage extends StatelessWidget {
  const AdmittedStudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VnuModuleAppBar(title: 'Sinh viên trúng tuyển'),
      body: FutureBuilder<List<AdmittedStudent>>(
        future: ApiRepository().getAdmittedStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return const Center(child: Text('Không có sinh viên trúng tuyển.'));
          }
          return ListView.separated(
            itemCount: students.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = students[index];
              return ListTile(
                title: Text(s.fullName),
                subtitle: Text('CCCD: ${s.cccd}\nEmail: ${s.email ?? '-'}'),
                trailing: Text(
                  s.createdAt?.toLocal().toString().split('.').first ?? '',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

