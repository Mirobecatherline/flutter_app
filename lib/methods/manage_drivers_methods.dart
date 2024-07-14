import 'package:user_app/models/online_nearby_drivers.dart';

class ManageDriversMethods {
  static List<OnlineNearbyDrivers> nearbyOnlineDriversList = [];

  static void removeDriverFromList(String driverID) {
    int index = nearbyOnlineDriversList.indexWhere((driver) => driver.uidDriver == driverID);

    if (nearbyOnlineDriversList.isNotEmpty)
    {
      nearbyOnlineDriversList.removeAt(index);
    }
  }

  //to update online near by drivers location
  static void updateOnlineNearbyDriversLocation(OnlineNearbyDrivers nearbyOnlineDriversInformation)
  {
    int index = nearbyOnlineDriversList.indexWhere((driver) => driver.uidDriver == nearbyOnlineDriversInformation.uidDriver);

    nearbyOnlineDriversList[index].latDriver = nearbyOnlineDriversInformation.latDriver;
    nearbyOnlineDriversList[index].longDriver = nearbyOnlineDriversInformation.longDriver;
  }
}
