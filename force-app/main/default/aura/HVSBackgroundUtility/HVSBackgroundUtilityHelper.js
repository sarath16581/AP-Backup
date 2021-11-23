({
  //Method to load utility
  openUtility: function (cmp) {
    let utilityAPI = cmp.find("utilitybar");
    utilityAPI
      .getAllUtilityInfo()
      .then(function (response) {
        //find qualification utility item
        let myUtilityInfo = response.filter((ul)=>{
            return ul.utilityLabel == 'Qualifications' /**&& ul.isLoaded == false**/;
        });
        if (myUtilityInfo.length > 0) {
            utilityAPI.openUtility({
                utilityId: myUtilityInfo[0].id
            });
        }
      })
      .catch(function (error) {
        console.log(error);
      });
  },
  //Method to close utility
  minimizeUtility: function (cmp) {
    let utilityAPI = cmp.find("utilitybar");
    utilityAPI
      .getAllUtilityInfo()
      .then(function (response) {
        //find loaded qualification utility item
        let myUtilityInfo = response.filter((ul)=>{
            return ul.utilityLabel == 'Qualifications' && ul.isLoaded == true;
        });
        if (myUtilityInfo.length > 0) {
            utilityAPI.minimizeUtility({
                utilityId: myUtilityInfo[0].id
            });
        }
      })
      .catch(function (error) {
        console.log(error);
      });
  }
});