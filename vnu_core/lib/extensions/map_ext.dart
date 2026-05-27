extension MapExt on Map<dynamic, dynamic> {
  Map<String, dynamic> toStringDynamic() {
    Map<String, dynamic> mapConvert = {};
    for (var element in keys) {
      mapConvert[element.toString()] = this[element];
    }
    return mapConvert;
  }
}
