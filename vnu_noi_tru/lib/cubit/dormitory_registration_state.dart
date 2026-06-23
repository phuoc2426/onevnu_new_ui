part of 'dormitory_registration_cubit.dart';

@immutable
abstract class DormitoryRegistrationState {}

class DormitoryRegistrationInitial extends DormitoryRegistrationState {}

class DormitoryRegistrationShowHub extends DormitoryRegistrationState {}

class DormitoryRegistrationLoading extends DormitoryRegistrationState {}

class DormitoryRegistrationDismissHub extends DormitoryRegistrationState {}

class DormitoryRegistrationOpenPeriodChecking
    extends DormitoryRegistrationState {}

class DormitoryRegistrationOpenPeriodChecked
    extends DormitoryRegistrationState {
  final bool hasOpenPeriod;

  DormitoryRegistrationOpenPeriodChecked(this.hasOpenPeriod);
}

class DormitoryRegistrationError extends DormitoryRegistrationState {
  final String message;
  DormitoryRegistrationError(this.message);
}

class DormitoryRegistrationPeriodsLoaded extends DormitoryRegistrationState {
  final List<RegistrationPeriodModel> periods;
  DormitoryRegistrationPeriodsLoaded(this.periods);
}

class DormitoryRegistrationDormitoriesLoaded extends DormitoryRegistrationState {
  final List<DormitoryModel> dormitories;
  DormitoryRegistrationDormitoriesLoaded(this.dormitories);
}

class DormitoryRegistrationRoomTypesLoaded extends DormitoryRegistrationState {
  final List<RoomTypeModel> roomTypes;
  DormitoryRegistrationRoomTypesLoaded(this.roomTypes);
}

class DormitoryRegistrationPriorityObjectsLoaded extends DormitoryRegistrationState {
  final List<PriorityObjectModel> priorityObjects;
  DormitoryRegistrationPriorityObjectsLoaded(this.priorityObjects);
}

class DormitoryRegistrationMyRegistrationsLoaded
    extends DormitoryRegistrationState {
  final dynamic data;

  DormitoryRegistrationMyRegistrationsLoaded(this.data);
}

class DormitoryRegistrationHistoryLoaded extends DormitoryRegistrationState {
  final List<RegistrationHistoryModel> history;
  DormitoryRegistrationHistoryLoaded(this.history);
}

class DormitoryRegistrationDetailLoaded extends DormitoryRegistrationState {
  final MyRegistrationModel registration;
  DormitoryRegistrationDetailLoaded(this.registration);
}

class DormitoryRegistrationUploadSuccess extends DormitoryRegistrationState {
  final UploadedAttachmentModel attachment;
  DormitoryRegistrationUploadSuccess(this.attachment);
}

class DormitoryRegistrationUploadError extends DormitoryRegistrationState {
  final String message;
  DormitoryRegistrationUploadError(this.message);
}

class DormitoryRegistrationSavedSuccess extends DormitoryRegistrationState {
  final String message;
  DormitoryRegistrationSavedSuccess(this.message);
}

class DormitoryRegistrationFileSelected extends DormitoryRegistrationState {
  final String slot;
  final File file;
  DormitoryRegistrationFileSelected(this.slot, this.file);
}

class DormitoryRegistrationFileChanged extends DormitoryRegistrationState {
  final String type;

  DormitoryRegistrationFileChanged(this.type);
}

class DormitoryRegistrationUploadProgress extends DormitoryRegistrationState {
  final double progress; // 0.0 to 1.0
  final String message;
  DormitoryRegistrationUploadProgress(this.progress, this.message);
}
