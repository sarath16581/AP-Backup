/**
  * @author        Urmi Chatterjee
  * @date          30/10/2013
  * @description   UTIL Class for creation of common Data used in Test Classes.
  * 
  * This software and all content is the property of ACCENTURE or its licensors, 
  * and is for the internal and confidential use of employees and authorized agents 
  * of ACCENTURE solely for the benefit of ACCENTURE and its affiliates.  
  * The software and contents are protected by copyright, trade secret and patent laws, 
  * and other local and international laws and treaties.  
  * Unauthorized use may subject the user to civil and criminal penalties.  
  * The software contains confidential information of ACCENTURE and its affiliates.  
  * You may not access, use, copy, install, modify, transfer, or distribute this software 
  * (electronically or otherwise), or create any copy, adaptation, transcription, or 
  * derivative thereof, except as expressly authorized by ACCENTURE.  
  * You may not divulge, disclose or communicate to any other third party, any of the 
  * confidential information contained in the software, including the software itself.  
  * ACCENTURE maintains full and exclusive right, title and ownership interest in and 
  * to the software and all copyright, patent, trade secret, trademark and other intellectual 
  * property rights therein.
  *
  31.01.2022  Naveen Rajanna REQ2723602 - Minor Fix to failing test class
  */
  
public with sharing class UTIL_TestMethods{
    
    /**
      * @description       Method for defining User object record to be created for use in Test Class. 
      * @param             aliasId the Alias Id of the User record is to be created
      * @param             profileName the profile for which the User record is to be created
      * @return            User
      * @throws            NA
      */
    public static User runningUser(String aliasId, String profileName){
        Id profId = [SELECT Id FROM Profile WHERE Name=: profileName].Id;
        User userData = new User(FirstName=aliasId, LastName=aliasId, Alias=aliasId, IsActive=True, Email=aliasId+'@test.com',
                                 ProfileId=profId, Username=aliasId+'@test.com', EmailEncodingKey='UTF-8', CommunityNickname=aliasId,
                                 LanguageLocaleKey='en_US', LocaleSidKey='en_US', TimeZoneSidKey='GMT');
        return userData;
    }
    
    /**
      * @description       Method for setting the Custom Setting Value to display fixed records on a Visualforce page
                           for use in Test Class.
      * @param             custName the Custom Setting name
      * @param             num the number of records value
      * @return            void
      * @throws            NA
      */
    public static void createCustomSetting(String custName, Integer num){
        PaginationRecords__c noOfRecs = new PaginationRecords__c(Name=custName, NumberofRecords__c=num);
        insert noOfRecs;
    }
}