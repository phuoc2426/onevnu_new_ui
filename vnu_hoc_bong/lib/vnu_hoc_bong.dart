library vnu_hoc_bong;

export 'repository/hoc_bong_repository.dart';
export 'screens/hoc_bong_list_screen.dart';
export 'screens/hoc_bong_detail_screen.dart';
export 'screens/hoc_bong_register_form_screen.dart';
export 'screens/hoc_bong_my_applications_screen.dart';
export 'screens/hoc_bong_application_detail_screen.dart';
export 'models/hoc_bong_models.dart';

import 'package:flutter/material.dart';

import 'repository/hoc_bong_repository.dart';
import 'screens/hoc_bong_list_screen.dart';

class VnuHocBong {
  static Widget screen({HocBongRepository? repository}) {
    return HocBongListScreen(repository: repository);
  }
}
