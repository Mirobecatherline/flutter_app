class AddressModel
{
  String? humanReadableAddress;
  double? systemGeneratedPickUp_latitudePosition;
  double? systemGeneratedPickUp_longitudePosition;
  String? place_id;

  ///user typed details

  AddressModel({

    this.humanReadableAddress ,
    this.systemGeneratedPickUp_latitudePosition ,
    this.systemGeneratedPickUp_longitudePosition,
    this.place_id});
}