import 'package:flutter/material.dart';
import 'package:vnu_core/repository/app_repository.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class VcoreSyncView extends StatefulWidget {
  const VcoreSyncView({super.key});

  @override
  State<VcoreSyncView> createState() => _VcoreSyncViewState();
}

class _VcoreSyncViewState extends State<VcoreSyncView> {
  bool _isSyncing = false;
  String _status = 'Chưa đồng bộ';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncVneidShareInfo();
    });
  }

  Future<void> _syncVneidShareInfo() async {
    if (_isSyncing) {
      return;
    }

    setState(() {
      _isSyncing = true;
      _status = 'Đang đồng bộ thông tin...';
    });

    try {
      final response = await ApiRepository().shareVneidInfo();
      final description = response.description ?? 'Đồng bộ hoàn tất.';

      setState(() {
        _status = response.responseCode == 200
            ? description
            : 'Đồng bộ chưa thành công: $description';
      });
    } catch (e) {
      setState(() {
        _status = 'Không thể đồng bộ thông tin: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VcoreModuleScaffold(
      title: 'Đồng bộ',
      showBackButton: true,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 72,
            ),
            const SizedBox(height: 16),
            const Text(
              'Đồng bộ thông tin qua VNeID',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _status,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSyncing ? null : _syncVneidShareInfo,
              child: Text(_isSyncing ? 'Đang đồng bộ...' : 'Đồng bộ lại'),
            ),
          ],
        ),
      ),
    );
  }
}
