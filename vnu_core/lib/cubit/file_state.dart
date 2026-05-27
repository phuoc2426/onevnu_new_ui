part of 'file_cubit.dart';

abstract class FileState {}

class FileInitial extends FileState {}

class FileLoadingState extends FileState {}

class FileLoadedErrorState extends FileState {
  final String message;
  FileLoadedErrorState(this.message);
}

class FileLoadedSuccessState extends FileState {
  final String localPath;
  FileLoadedSuccessState(this.localPath);
}
