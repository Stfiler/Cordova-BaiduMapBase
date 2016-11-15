var BaiduMap = {

  initAK: function(appkey,success,failure){
    cordova.exec(success,failure,'CDVBaiduMap','initBaiDu',[appkey]);
  },
  enterMapView: function(enterInfo,success, failure){
    cordova.exec(success,failure,'CDVBaiduMap','enterMapView',[enterInfo]);
  },
  chooseLocation: function(enterInfo,success, failure){
    cordova.exec(success,failure,'CDVBaiduMap','chooseLocation',[enterInfo]);
  },
getRealDistanceFromTwoPlace: function(enterInfo,success, failure){
    cordova.exec(success,failure,'CDVBaiduMap','getRealDistanceFromTwoPlace',[enterInfo]);
},
getLocationCoordinate2DInfo: function(enterInfo,success, failure){
    cordova.exec(success,failure,'CDVBaiduMap','getLocationCoordinate2DInfo',[enterInfo]);
},
getLocationInfo: function(enterInfo,success, failure){
    cordova.exec(success,failure,'CDVBaiduMap','getLocationInfo',[enterInfo]);
},
}

module.exports = BaiduMap;
