class PredictionModel
{
  String? place_Id;
  String? main_text;
  String? secondary_text;

  PredictionModel({this.place_Id, this.main_text ,this.secondary_text});

  PredictionModel.fromJson(Map<String, dynamic>json)
  {
    place_Id = json["id"];
    main_text = json["address"]["label"];
    secondary_text = json["address"]["label"];
  }

}