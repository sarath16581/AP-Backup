/**
 * This is the header file to send user stats to each cognition server REST request,
 * These data will be recorded at cognition server for analytics purposes in the future
 *  History:
 *	 12-09-2018: Created - H Liyanage :  CFC-9: #62 : Cognition Analytics Tracking - Add customer number into API calls
 *  --------------------------------------------------
 **/

public virtual with sharing class Cognition_APICommons {
    public Cognition_APICommons(){
        this.sfProfileName = [SELECT Name FROM profile where id = :UserInfo.getProfileId() LIMIT 1].Name;
        this.sfUserName = UserInfo.getUserName();
    }
    @AuraEnabled public String sfProfileName ;
    @AuraEnabled public String sfUserName ;
}