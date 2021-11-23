/*------------------------------------------------------------
Author:        Dion Gunn (dion.gunn@auspost.com.au)
Description:   Controller for the MyNetwork custon profile header component.
Test Class:    MyNetworkProfileHeaderControllerTest.cls
History
31-02-2017 - Dion Gunn - Created
*********************************** HISTORY ***************************************************
* 06.06.18     kalpita.talwadekar@auspost.com.au            updated code for coding standard follow - TDO-202
* 10.09.2018   saiswetha.pingali@auspost.com.au             Retail Users to be redirected to their login page once they logout of mynetwork portal as per REQ1527795
*
------------------------------------------------------------*/

public without sharing class MyNetworkProfileHeaderController {
    
    //class variables
    public static String baseURL = '';
    //variable to show the user photo icon on UI component
    @AuraEnabled public  String photo {get;set;}
    //variable to show the user name on UI component
    @AuraEnabled public  string name {get;set;}

    /** 
      * @name: myLogoutUrl 
      * @desciption: If the user is not part of the MyNetwork Retail group, they should get the standard Salesforce Logout. Otherwise they should
                     be logged out of Oracle IAM. Used in the MyNetworkProfileHeader lightning component in the MyNetwork community.
      * @param: NA
      * @return: NA
      *
      */
    @AuraEnabled
    public static String myLogoutUrl() {
        String oracleLogoutURL = '';
        String logoutHost = '';
        // REQ1527795 - Retail Users to be redirected to their login page once they logout of mynetwork portal 
        String RetailHost = ''; 
        
        //setting base url from portal and not running in test mode
        if(!Test.isRunningTest()) {
          baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        }
        
        //retreive custom metadata type for myNetwork community settings
        MyNetworkCommunitySettings__mdt myNetworkSettings = [select Dev_Oracle_IAM_Logout_URL__c, PTEST_Oracle_IAM_Logout_URL__c,
                Stest_Oracle_IAM_Logout_URL__c, Prod_Oracle_IAM_Logout_URL__c, Development_Base_URL__c, PTEST_Base_URL__c,
                STEST_Base_URL__c, Production_Base_URL__c,Production_Retail_Logout_URL__c from MyNetworkCommunitySettings__mdt limit 1];
        Organization currentOrg = [select IsSandbox from Organization limit 1];

        // Work out which URL we should be using based on org type. 
        //This was implemented like this due to the difficulty determining the host from a community when "My Domain" is enabled.
        if(baseURL.containsIgnoreCase('ptest')) { 
            oracleLogoutURL = myNetworkSettings.PTEST_Oracle_IAM_Logout_URL__c;
            logoutHost = myNetworkSettings.PTEST_Base_URL__c;
        } else if(baseURL.containsIgnoreCase('stest')) {
            oracleLogoutURL = myNetworkSettings.Stest_Oracle_IAM_Logout_URL__c;
            logoutHost = myNetworkSettings.STEST_Base_URL__c;
        } else if(!currentOrg.IsSandbox && !Test.isRunningTest()) {
            oracleLogoutURL = myNetworkSettings.Prod_Oracle_IAM_Logout_URL__c;
            logoutHost = myNetworkSettings.Production_Base_URL__c;
            // REQ1527795 - Retail Users to be redirected to their login page once they logout of mynetwork portal 
            RetailHost = myNetworkSettings.Production_Retail_Logout_URL__c;
        } else {
            oracleLogoutURL = myNetworkSettings.Dev_Oracle_IAM_Logout_URL__c;
            logoutHost = myNetworkSettings.Development_Base_URL__c;
        }
        
        //query the current logged in user to know if he is retail user or not
        User currentUser = [select Id, MyNetwork_Retail_User__c from User where Id =: UserInfo.getUserId()];

        //If the user is part of the MyNetwork retail group, they should have their OAM session killed. Otherwise, just return to standard logout.
        if(currentUser.MyNetwork_Retail_User__c) {
            String logoutURL = oracleLogoutURL + '?end_url=' + RetailHost ;
            return logoutURL;
        } else {
            String logoutURL = logoutHost + '/secur/logout.jsp';
            return logoutURL;
        }
    }

    /** 
      * @name: myProfileUrl 
      * @desciption: Menu item directing the user to their profile. Used as part of the custom menu built for MyNetwork.
      * @param: NA
      * @return: NA
      *
      */
    @AuraEnabled
    public static String myProfileUrl() {
        String profileURL = './profile/' + UserInfo.getUserId();
        return profileURL;
    }
    
    
    /** 
      * @name: myProfileUrl 
      * @desciption: For retreving the user name and profile photo as icon for header component
      * @param: NA
      * @return: MyNetworkProfileHeaderController
      *
      */
    @AuraEnabled
    public static MyNetworkProfileHeaderController uName() {
        MyNetworkProfileHeaderController obj = new MyNetworkProfileHeaderController();
        //query user to get the photo url and user name for display on header component
        User u = [Select u.SmallPhotoUrl, u.FullPhotoUrl, u.FirstName From User u where u.id=:Userinfo.getUserid()];

        //set value in class properties
        obj.Photo = u.SmallPhotoUrl;
        obj.Name = u.FirstName;
        return obj;
    }

}