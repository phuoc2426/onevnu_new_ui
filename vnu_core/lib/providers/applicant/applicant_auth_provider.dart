import 'package:vnu_core/modules/admission/controllers/applicant_auth_controller.dart';

/// Backward-compatible type kept only so old imports do not reference the
/// removed legacy Applicant API service implementation.
///
/// The active Applicant login flow is ApplicantAuthController -> ApiRepository
/// -> ApplicantSessionRepository.
@Deprecated('Use ApplicantAuthController directly.')
class ApplicantAuthProvider extends ApplicantAuthController {
  ApplicantAuthProvider();
}
