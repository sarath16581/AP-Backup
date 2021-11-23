/**
 * cognition utility class
 * ------------------History ------------------------------
 * Created by hasantha on 15/08/2018.
 **/
public with sharing class Cognition_Util {

    @testVisible
    private static User user {
        get {
            return [SELECT Id, ContactId, UserType, Profile.Name FROM User WHERE id =: UserInfo.getUserId() LIMIT 1];
        }
        set;
    }

    private static CustomerCognitionSettings__c cognitionSetting {
        get {
            if(CognitionSetting != null) {
                return CognitionSetting;
            } else {
                return CustomerCognitionSettings__c.getOrgDefaults();
            }
        }
        set;
    }
    /**
     * Checking whether the user is external user or a salesforce (internal) user.
     * @return boolean
     */
    public static boolean isInternalUser(){
        return 'Standard'.equalsIgnoreCase(user.UserType);
    }

    public static sObject getSystemCustomSettingListByName(String listName, String recordName){
        try{
            SObjectType objToken = Schema.getGlobalDescribe().get(listName);
            DescribeSObjectResult objDef = objToken.getDescribe();

            // read all the fields on the custom setting
            Map<String, SObjectField> fields = objDef.fields.getMap();
            //prepare for SOQL
            string fieldsAPIname = '';
            for(string f : objDef.fields.getMap().keySet()){
                fieldsAPIname += f +',';
            }
            if(fieldsAPIname.endsWith(',')){
                fieldsAPIname= fieldsAPIname.substring(0,fieldsAPIname.length()-1);
            }

            // query the custom setting
            for(sObject so: database.query('SELECT '+fieldsAPIname+' FROM '+listName+' WHERE Name=\''+recordName+'\'')) {
                //return the custom setting if found
                return so;
            }
        } catch(exception e){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'Cognition_Util', LightningUtilityController.class.getName(), 'getSystemCustomSettingListByName',
                    null, LoggingLevel.ERROR
            );
        }

        // return null if not found
        return null ;
    }

    public static Integer getRefreshInterval(){
        Integer ONE_MINUTE = 60000;
        if(cognitionSetting.AutoRefresh__c) {
            if(null == cognitionSetting.RefreshInterval__c) {
                return 5 * ONE_MINUTE;
            } else {
                return Integer.valueOf(cognitionSetting.RefreshInterval__c) * ONE_MINUTE;
            }
        }
        return 5 * ONE_MINUTE;
    }


    /**
     * convertTimeStamp - Formats EPOCH timestamp to Date and Time in Melbourne
     **/
    public static String convertTimeStamp(String timeStamp) {
        if(timeStamp != null && timeStamp != ''){
            String myTime = timeStamp.substringBetween('(', '+');
            System.debug('myTime>>>>>'+myTime);
            DateTime dt = DateTime.newInstance(Long.valueOf(myTime));
            return dt.format('dd/MM/yyyy HH:mm:ss', 'Australia/Victoria');
        }else{
            return null;
        }
    }
    
    public static String[] pickupCategory = new String[]{'30','31','32'};

}