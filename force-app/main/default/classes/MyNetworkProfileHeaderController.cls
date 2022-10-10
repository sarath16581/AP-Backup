/*------------------------------------------------------------
Author:        Dion Gunn (dion.gunn@auspost.com.au)
Description:   Controller for the MyNetwork custon profile header component.
Test Class:    MyNetworkProfileHeaderControllerTest.cls
History
31-02-2017 - Dion Gunn - Created
*********************************** HISTORY ***************************************************
* 06.06.18     kalpita.talwadekar@auspost.com.au            updated code for coding standard follow - TDO-202
* 10.09.2018   saiswetha.pingali@auspost.com.au             Retail Users to be redirected to their login page once they logout of mynetwork portal as per REQ1527795
* 08.09.2022   naveen.rajanna@auspost.com.au                REQ2963906 - upgraded to 55 and moved profile, logout url separate methods to fetch in constructor call itself
------------------------------------------------------------*/

public without sharing class MyNetworkProfileHeaderController {
  
  //class variables
  public static String baseURL = '';
  //variable to show the user photo icon on UI component
  @AuraEnabled public String photo {get;set;}
  //variable to show the user name on UI component
  @AuraEnabled public String name {get;set;}
  @AuraEnabled public String id {get;set;} //Logged-in UserId
  @AuraEnabled public String pathPrefix {get;set;} //Community baseURL path prefix if any ex: myNetwork
  @AuraEnabled public String retailLogoutURL {get;set;} //Community secure logout URL for Retail users
  
  public static String getRetailLogoutURL() {
    String logoutURL = '';
    MyNetworkCommunitySettings__mdt myNetworkSettings = [
			SELECT
				Dev_Oracle_IAM_Logout_URL__c,
				PTEST_Oracle_IAM_Logout_URL__c,
				Stest_Oracle_IAM_Logout_URL__c,
				Prod_Oracle_IAM_Logout_URL__c,
				Production_Retail_Logout_URL__c
			FROM MyNetworkCommunitySettings__mdt
			LIMIT 1
		];
    
    if(!Util.runningInASandbox && !Test.isRunningTest()) {
      // REQ1527795 - Retail Users to be redirected to their login page once they logout of mynetwork portal 
      logoutURL = myNetworkSettings.Prod_Oracle_IAM_Logout_URL__c + '?end_url=' + myNetworkSettings.Production_Retail_Logout_URL__c;
    } else if(baseURL.containsIgnoreCase('ptest')) { 
      logoutURL = myNetworkSettings.PTEST_Oracle_IAM_Logout_URL__c;
    } else if(baseURL.containsIgnoreCase('stest')) {
      logoutURL = myNetworkSettings.Stest_Oracle_IAM_Logout_URL__c;
    } else {
      logoutURL = myNetworkSettings.Dev_Oracle_IAM_Logout_URL__c;
    }      
    return logoutURL;
  }

  /** 
    * @name: uName 
    * @desciption: For retreving the user name and profile photo as icon for header component
    * @param: NA
    * @return: MyNetworkProfileHeaderController
    *
    */
  @AuraEnabled
  public static MyNetworkProfileHeaderController uName() {
      MyNetworkProfileHeaderController obj = new MyNetworkProfileHeaderController();
      //setting base url from portal and not running in test mode
      if(!Test.isRunningTest()) {
        baseURL = URL.getSalesforceBaseUrl().toExternalForm();
      }
      //query user to get the photo url and user name for display on header component
      User u = [Select Id, SmallPhotoUrl, FullPhotoUrl, FirstName, MyNetwork_Retail_User__c From User where id=:Userinfo.getUserid()];
      //set value in class properties
      obj.Photo = u.SmallPhotoUrl;
      obj.Name = u.FirstName;
      obj.id = u.Id;
      obj.pathPrefix = baseURL.contains('auspostbusiness') ? '/'+ LABEL.MYNETWORK_LABEL : '';
      obj.retailLogoutURL = u.MyNetwork_Retail_User__c ? getRetailLogoutURL() : '';
      return obj;
  }

}