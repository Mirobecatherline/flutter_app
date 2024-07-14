import 'package:flutter/cupertino.dart';
import 'package:user_app/models/address_model.dart';

class AppInfo extends ChangeNotifier
{
  AddressModel? pickUpAddress;
  AddressModel? dropOffAddress;

  void updatePickUpAddress(AddressModel pickUpModel)
  {
    pickUpAddress = pickUpModel;
    notifyListeners();
  }



  void updateDropOffAddress(AddressModel dropOffModel)
  {
    dropOffAddress = dropOffModel;
    notifyListeners();
  }


}