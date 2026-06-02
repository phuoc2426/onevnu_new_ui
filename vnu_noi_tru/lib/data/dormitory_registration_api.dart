import 'dart:io';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/model.dart';

part 'dormitory_registration_api.g.dart';

@RestApi()
abstract class DormitoryRegistrationApi {
  factory DormitoryRegistrationApi(Dio dio, {String baseUrl}) =
      _DormitoryRegistrationApi;

  @GET('registration-periods')
  Future<RegistrationPeriodResponse> getRegistrationPeriods();

  @GET('list')
  Future<DormitoryListResponse> getDormitories();

  @GET('room-types')
  Future<RoomTypeListResponse> getRoomTypes();

  @GET('priority-objects')
  Future<PriorityObjectListResponse> getPriorityObjects();

  @GET('registrations/me')
  Future<MyRegistrationResponse> getMyRegistrations();

  @GET('registrations/{id}')
  Future<SingleRegistrationResponse> getRegistrationDetail(
    @Path('id') int id,
  );

  @POST('attachments/upload')
  @MultiPart()
  Future<UploadedAttachmentListResponse> uploadAttachment(
    @Part(name: 'student_id') int studentId,
    @Part(name: 'type') String type,
    @Part(name: 'files[]') List<File> files,
  );

  @POST('registrations')
  Future<SingleRegistrationResponse> registerDormitory(
    @Body() RegistrationPayloadModel payload,
  );

  @POST('registrations/{id}/submit')
  Future<dynamic> submitDraft(
    @Path('id') int id,
  );

  @GET('registrations/{id}/histories')
  Future<RegistrationHistoryResponse> getRegistrationHistories(
    @Path('id') int id,
  );
}
