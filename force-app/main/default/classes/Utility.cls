/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 01/09/2015
  * @description  : UTIL Class for SSSW Application
  *
  *
  * Supporting Test Classes:
  * Utility_Test
  * CacheManager_Test
  * CaseMilestoneUtility_Test
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    10/03/2015  nandan.narasappa@auspost.com.au  updated completeCaseMilestones method to include completeVioltedMilestone parameter
    2017-09-28  nathan.franklin@auspost.com.au  adding caching for some methods
    2018-12-17  nathan.franklin@auspost.com.au  added generic get record types method with caching
    2019-01-22  nathan.franklin@auspost.com.au  refactored record type methods to all call getRecordTypesAsSObject
    2019-02-19  ramtej.juloori@auspost.com.au  added method to search record types by Name or DevName 
    2020-01-08  vcheng@salesforce.com added method to validate if a string fulfils the ABN format
    2020-02-06  vcheng@salesforce.com bug fix in completeCaseMilestones, the logic for completing violated milestones should
    not be in the WHERE clause, if completeViolatedMilestone is false, we ignore violated milestones
    2020-02-13  lija.jawahar@auspost.com.au Cache CaseTeamroles
    2020-08-02 - Nathan Franklin - deprecated getRecordTypesAsSObject in favour of RecordTypesSelector
*******************************  History ************************************************/
public without sharing class Utility{

    public static Map<String,Id> businessHourMap = new Map<String,Id>();    // variable to store timezone & its business hour
    public static Set<String> closedCaseStatuses;
    public static Id defaultBusinessHour;                                   // Id of default business hour

    /**
      * @description       This method returns the standard Entitlement
      * @param             NA
      * @return            Id
      * @throws            Method might throw exception which is handled by invoked method
      */
    public static Id getStandardEntitlement(){
        List<Entitlement> ssswEntitlements = [SELECT Id FROM Entitlement WHERE Account.Name =: SSSWConstants.ENTITLEMENT_ACC LIMIT 1 ];
        if(ssswEntitlements.size() == 1)
        {
            return ssswEntitlements[0].Id;
        }
        return null;
    }

    /**
    * @description       This method returns the Case Team role from Platform cache
    * @param             caseTeamRole - case team role
    * @return            Id
    * @throws            NA
    */
    public static Id getCaseTeamRole(String caseTeamRole){

        Id roleId = null;

        //check org cache whether caseTeamRole is already fetched
        Map<String,Id> caseTeamRoleMap = (Map<String,Id>)CacheManager.get('CASE_TEAM_ROLE');

        //if cache is not a hit or cache does not have a value for the queried caseTeamRole, continue to query the database
        if(caseTeamRoleMap == null || !(caseTeamRoleMap.containsKey(caseTeamRole))) {
            System.debug('Utility.getCaseTeamRole : caseTeamRoleMap not in Platform Cache ');

            Map<String, Id> roleMap = new Map<String, Id>();
            // fetch all case team roles and store in a map
            for (CaseTeamRole role : [SELECT Id,Name FROM CaseTeamRole]) {
                roleMap.put(role.Name, role.Id);
            }

            // assign role id from map
            roleId = !String.isBlank(caseTeamRole) ? roleMap.get(caseTeamRole) : null;
            System.debug('Utility.getCaseTeamRole : roleId :: '+roleId);

            // Cache the new Queried CaseTeamRoles
            CacheManager.put('CASE_TEAM_ROLE',roleMap);

        } else {

            System.debug('Utility.getCaseTeamRole : caseTeamRoleMap from cache :: '+caseTeamRoleMap);

            // assign role id from map
            roleId = caseTeamRoleMap.get(caseTeamRole);
            System.debug('Utility.getCaseTeamRole : roleId :: '+roleId);
        }

        return roleId;
    }

    /**
    * @description returns Id by Dev Name
    * @author rajesh.punjabi@mav3rik.com | 7/31/2019
    * @param String objName
    * @param String recordTypeName
    * @return Id
    */
    public static Id getRecordTypesAsIdByDevName(String objName, String recordTypeName) {
        /*Id output;

        if(String.isNotBlank(objName) && String.isNotBlank(recordTypeName)) {

            // check cache
            output = (Id) CacheManager.get('UTILITY_RECORD_TYPE_IDS', recordTypeName);
            if(output != null) {
                return output;
            }
            // fetch recordtype details from Schema method based on the object api name

            output = Schema.getGlobalDescribe().get(objName).getDescribe().getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
            CacheManager.put('UTILITY_RECORD_TYPE_IDS', recordTypeName, output);
        }
        return output;*/

        Map<Id, RecordType> output = getRecordTypesAsSObjectByDevName(objName, new Set<String>{recordTypeName});
        return (output.isEmpty() ? null : output.values()[0].Id);
    }

    /**
     * Reurns a list of record types for a particular object and then caches the result
     * @deprecated use RecordTypesSelector instead
     */
    public static Map<Id, RecordType> getRecordTypesAsSObject(String objName) {
        return RecordTypesSelector.newInstance().selectBySObject(objName);
    }

    /**
      * @description       This method returns the recordtypes for sobject
      * @param             objName - sobject name
      * @return            Map<String,Id>
      * @throws            NA
      */
    public static Map<String,Id> getsObjectRecordTypes(String objName){
        Map<String, Id> recTypeMap = new Map<String,Id>();
        if(String.isNotBlank(objName)){
            // grab a list of all the record types on a particular object
            // this is cached so it shouldn't be too slow.
            List<RecordType> recordTypes = getRecordTypesAsSObject(objName).values();

            for(RecordType rType : recordTypes){
                recTypeMap.put(rType.Name, rType.Id);  // map of record type name and Id
            }
        }
        return recTypeMap;
    }

    /**
      * @description       This method returns the recordtypes for sobject
      * @param             objName - sobject name
      * @return            Map<Id,String>
      * @throws            NA
      */
    public static Map<Id,String> getsObjectRecordTypeNames(String objName){
        Map<Id,String> recTypeMap = new Map<Id,String>();
        if(String.isNotBlank(objName)){
            // grab a list of all the record types on a particular object
            // this is cached so it shouldn't be too slow.
            List<RecordType> recordTypes = getRecordTypesAsSObject(objName).values();

            for(RecordType rType : recordTypes) {
                recTypeMap.put(rType.Id, rType.Name);  // map of record type name and Id
            }
        }
        return recTypeMap;
    }

    /**
      * Retruns a map of record type id's based on the list of Name/DeveloperNames passed in
      */
    public static Map<Id, RecordType> getRecordTypesAsSObjectByDevName(String objName, Set<String> recordTypeDevNames) {
        Map<Id, RecordType> output = new Map<Id, RecordType>();

        // grab a list of all the record types on a particular object
        // this is cached so it shouldn't be too slow.
        List<RecordType> recordTypes = getRecordTypesAsSObject(objName).values();

        for(RecordType rt : recordTypes) {
            // this will prioritise a developer name over just a name
            if(recordTypeDevNames.contains(rt.DeveloperName)) {
                output.put(rt.Id, rt);
            }
        }

        return output;
    }

    /**
      * @description       This method returns the recordtype ids based search string for an object
      * @param             objName - sobject name, searchString - string to check in recordtype name
      * @return            Id
      * @throws            NA
      */
    public static Set<Id> getRecordTypeIds(String objName,String searchString){
        //search record types by Nameusing searchRecordTypes method
        Set<Id> recTypeIds = searchRecordTypes(objName, searchString, 'Name');

        return recTypeIds;
    }

    /**
      * @description       This method returns the recordtype ids based search string for an object
                            searching in Name or developerName
      * @param             objName - sobject name, searchString - string to check in recordtype name
                            searchBy - search string in name or developer name
      * @return            Id
      * @throws            NA
      */
    public static Set<Id> searchRecordTypes(String objName,String searchString, String searchBy){
        Set<Id> recTypeIds = new Set<Id>();
        // verify if object api name & search string for recordtype is provided
        if(String.isNotBlank(objName) && String.isNotBlank(searchString)){

            // grab a list of all the record types on a particular object
            // this is cached so it shouldn't be too slow.
            List<RecordType> recordTypes = getRecordTypesAsSObject(objName).values();
            system.debug('recordTypes '+recordTypes+' searchBy '+searchBy);
            // Iterate over the record types of sObject using schema methods
            for(RecordType rType : recordTypes){
                // check if record type name or dev name contains searchString
                if(searchBy == 'Name'){
                    if(rType.Name.containsIgnoreCase(searchString)) {
                        recTypeIds.add(rType.Id);
                    }
                }
                else if(searchBy == 'DeveloperName'){
                    if(rType.DeveloperName.containsIgnoreCase(searchString)) {
                        recTypeIds.add(rType.Id);
                    }
                }
            }
        }
        system.debug('recTypeIds '+recTypeIds);
        return recTypeIds;
    }

    /**
      * @description       This method checks if record type is valid for functionality
      * @param             recTypeIds - Set<Id>, recTypeId - Id
      * @return            Boolean
      * @throws            NA
      */
    public static Boolean isValidRecordType(Set<Id> recTypeIds,Id recTypeId){
        Boolean isValid = false;
        if(recTypeIds != null && recTypeIds.contains(recTypeId)){   // verify if set contains the recordtype Id
            isValid = true; // set flag to true
        }
        return isValid;
    }

    /**
      * @description       This method returns current user's business hour Id
      * @param             NA
      * @return            Id
      * @throws            NA
      */
    public static Id getCurrentUserBussinessHour(){
        return getBussinessHourMap().get(String.valueOf(UserInfo.getTimeZone()));
    }

    /**
      * @description       This method returns  default business hour Id
      * @param             NA
      * @return            Id
      * @throws            NA
      */
    public static Id getDefaultBussinessHour(){
        if(defaultBusinessHour == null){
            defaultBusinessHour = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
        }
        return defaultBusinessHour;
    }

    /**
      * @description       This method returns business hour map for SSSW application
      * @param             NA
      * @return            Map<String,Id>
      * @throws            NA
      */
    public static Map<String,Id> getBussinessHourMap(){
        if(businessHourMap.isEmpty()){
            String ssswLike = SSSWConstants.SSSW_APP + SSSWConstants.PERCENT;
            Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());    // get dynamic query row limit
            for(BusinessHours busHour : [SELECT Id,TimeZoneSidKey FROM BusinessHours WHERE Name LIKE : ssswLike
            AND IsActive = true ORDER BY TimeZoneSidKey,CreatedDate ASC
            LIMIT : rowLimit]){
                if(!businessHourMap.containsKey(busHour.TimeZoneSidKey)){
                    businessHourMap.put(busHour.TimeZoneSidKey,busHour.Id);
                }
            }
        }
        return businessHourMap;
    }

    /**
      * @description       This method returns closed status values for case
      * @param             NA
      * @return            Set<String>
      * @throws            NA
      */
    public static Set<String> getCaseClosedStatus(){

        // check session cache
        Set<String> cachedStatuses = (Set<String>)CacheManager.get('CASE_CLOSED_STATUSES');
        if(cachedStatuses != null) {
            return cachedStatuses;
        }

        if(closedCaseStatuses == null || closedCaseStatuses.isEmpty()) {
            closedCaseStatuses = new Set<String>();
            for (CaseStatus status : [SELECT MasterLabel FROM CaseStatus WHERE IsClosed = true]) {
                closedCaseStatuses.add(status.MasterLabel);
            }

            CacheManager.put('CASE_CLOSED_STATUSES', closedCaseStatuses);
        }
        return closedCaseStatuses;
    }

    /**
      * @description       This method returns user details for a set of user ids
      * @param             usrIds - Set<Id>
      * @return            Map<Id,User>
      * @throws            NA
      */
    public static Map<Id,User> getUsers(Set<Id> usrIds){
        Map<Id,User> usrMap = new Map<Id,User>();
        try{
            Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());    // get dynamic query row limit
            usrMap = new Map<Id,User>([SELECT Name,TimeZoneSidKey,Email FROM User WHERE Id IN: usrIds LIMIT : rowLimit]);
        }
        catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    Utility.class.getName(), SSSWConstants.METH_GETUSERS,
                    SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
        return usrMap;
    }

    /**
      * @description       This method returns Group details for the group ids and the group type
      * @param             grpIds - Set<Id>, grpType - Group Type
      * @return            Map<Id,Group>
      * @throws            NA
      */
    public static Map<Id,Group> getGroupDetails(Set<Id> grpIds,String grpType){
        Map<Id,Group> grpMap = new Map<Id,Group>();
        try{
            Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());    // get dynamic query row limit
            grpMap = new Map<Id,Group>([SELECT Name,DeveloperName FROM Group
            WHERE Id IN: grpIds AND Type =: grpType LIMIT : rowLimit]);
        }
        catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    Utility.class.getName(), SSSWConstants.METH_GETGROUP_DETAILS,
                    SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
        return grpMap;
    }

    /**
      * @description       This method returns group detail of a type
      * @param             grpType - Group Type
      * @return            Map<Id,Group>
      * @throws            NA
      */
    public static Map<Id,Group> getGroups(String grpType){
        Map<Id,Group> grpMap;
        try{
            // check session cache
            grpMap = (Map<Id,Group>)CacheManager.get('UTILITY_GROUPS', grpType);
            if(grpMap != null) {
                return grpMap;
            }

            Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());    // get dynamic query row limit
            grpMap = new Map<Id,Group>([SELECT Name,DeveloperName FROM Group WHERE Type =: grpType LIMIT : rowLimit]);

            CacheManager.put('UTILITY_GROUPS', grpType, grpMap);
        }
        catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    Utility.class.getName(), SSSWConstants.METH_GETGROUPS,
                    SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
        return grpMap;
    }

    /**
      * @description       This method returns group Id based on group type and developer name
      * @param             grpDevName - String, grpType - String
      * @return            Id
      * @throws            Method might throw exception which is handled by try-catch block
      */
    public static Id getGroupId(String grpDevName,String grpType){
        Id groupId;
        try{
            groupId = [SELECT Id,Name,DeveloperName
            FROM Group WHERE DeveloperName =: grpDevName AND Type =: grpType LIMIT 1].Id;
        }
        catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    Utility.class.getName(), SSSWConstants.METH_GETGROUPID,
                    SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
        return groupId;
    }

    /**
      * @description       This method completes milestone for the cases of the milestoneType provided
      * @param             caseNumber - String, milestoneTypes - Set<String>, Boolean completeVioltedMilestone
      * @return            String
      * @throws            NA
      */
    public static void completeCaseMilestones(List<Case> caseList,Set<String> milestoneTypes,Boolean includeViolatedMilestones){
        Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());    // get dynamic query row limit
        List<CaseMilestone> charterMilestones = new List<CaseMilestone>();
        for(CaseMilestone mileStone : [SELECT CompletionDate,MilestoneType.Name, IsViolated
        FROM CaseMilestone WHERE CaseId IN: caseList AND
        MilestoneType.Name IN: milestoneTypes
        // 2020-02 removed this line, as this is incorrect logic
        //AND (IsCompleted = false OR IsViolated =: completeViolatedMilestone)

        // 2020-02 replaced with the following - only update a milestone if it's not completed
        AND IsCompleted = false
        LIMIT : rowLimit]){
            // 2020-02 Change to rectify logic of completeViolatedMilestone parameter
            // IF completeViolatedMilestone == false, then ignore violated milestones
            // else, complete ALL (incomplete) milestones
            if(includeViolatedMilestones == true
                    || (includeViolatedMilestones == false && mileStone.IsViolated == false))
            {
                mileStone.CompletionDate = System.now();
                // complete mileStone
                charterMilestones.add(mileStone);
            }
        }

        System.debug('Utility::milestones to mark as complete:' + charterMilestones);
        if(!charterMilestones.isEmpty()){
            Database.update(charterMilestones,false);
        }
    }
    /**
      * @description       This method parse string and retreive a substring based on start and end parameters
      * @param             strEntire - String, strStart - String, strEnd  - String
      * @return            String
      * @throws            NA
      */
    public static string parsetext(String strEntire, String strStart, String strEnd) {

        String strSubset = strEntire.substringafter(strStart);

        String strCapture = strSubset<>null?strSubset.substringbefore(strEnd):null ;

        return strCapture.trim();

    }

    /* @author: rajesh.punjabi@mav3rik.com
     * @description: This method is specific to Live Chat and Feeditem.
     * @description: Live Chat body content contains html tag which are not supported by Feeditem.
*/
    public static String convertTextoRichText(String sLiveChatBodyContent){
        Map<String, String> supportedMarkup = new Map<String, String> {
                '<p align="center">' => '<p>',
                '<br>' => '<p>&nbsp;</p>'
        };

        for(String skey:supportedMarkup.keySet()){
            sLiveChatBodyContent = sLiveChatBodyContent.replace(skey, supportedMarkup.get(skey));
        }

        return sLiveChatBodyContent;
    }

/* @author: rajesh.punjabi@mav3rik.com
     * @description: This methos returns list of Ids by profile name.
     * @param: String seprated by comma. ProfileName1, ProfileName2
*/
    /*  public static Set<Id> getProfileIds(String ProfileNames){
          List<Profile> output;

          if(String.isNotBlank(ProfileNames)) {

              // check cache
              output = (List<Profile>) CacheManager.get('UTILITY_RECORD_TYPES', ProfileNames.left(25));
              if(output != null) {
                  System.debug('zzzz from cache' + output);
                  return (new Map<Id,Profile>(output)).keySet();
              }
              // fetch recordtype details from Schema method based on the object api name

              output = [SELECT Id FROM Profile WHERE NAME IN: ProfileNames.Split(',')];
              CacheManager.put('UTILITY_RECORD_TYPES', ProfileNames.left(25), output);
          }
          System.debug('zzzz not from cache' + output);
          return (new Map<Id,Profile>(output)).keySet();
      }*/


    /**
     * Check if an ABN string fits the official format rules
     * Sample usage:
        String abn = '51824753556';
        isValidAbnFormat(abn.deleteWhitespace());
     * @param abnString the abn string, the value passed in should use String.deleteWhitespace() to remove whitespace
     *
     * @return true if the abnString passed in satisfies the format
     */
    public static Boolean isValidAbnFormat(String abnString)
    {
        // if not a number, return false
        if(!abnString.isNumeric())
            return false;

        if(abnString.length() != 11)
            return false;

        // using local variables since these are only used in this calculation
        List<Integer> ABN_DIGIT_WEIGHTING = new List<Integer>{10,1,3,5,7,9,11,13,15,17,19};
        Integer ABN_DIVIDE = 89;

        Integer sumTotal = 0;
        for(Integer i = 0; i < abnString.length(); ++i)
        {
            String sDigit = abnString.substring(i, i + 1);
            Integer iDigit = Integer.valueOf(sDigit);
            if(i == 0)
            {
                // step 1 subtract 1 from left most
                iDigit -= 1;
            }

            // step 2 multiply by weighting table
            iDigit *= ABN_DIGIT_WEIGHTING[i];

            // step 3 add to the total
            sumTotal += iDigit;
        }

        // step 4 modulus division to get the remainder
        Integer remainder = Math.mod(sumTotal, ABN_DIVIDE);

        System.Debug('Utility::isValidAbnFormat: total = ' + sumTotal);
        System.Debug('Utility::isValidAbnFormat: remainder = ' + remainder);

        if(0 == remainder) {
            // valid ABN format if remainder = 0
            return true;
        }

        // everything else is invalid
        return false;
    }

    public static Map<String, Id> getBGSEntitlementIds()
    {
        List<Entitlement> bgsEntitlements = [SELECT Id, Name
        FROM Entitlement WHERE Account.Name =: BGSConstants.BGS_ENTITLEMENT_STANDARD
        LIMIT 10];

        Map<String, Id> bgsEntitlementIds = new Map<String, Id>();
        for(Entitlement ent:bgsEntitlements)
        {
            bgsEntitlementIds.put(ent.Name, ent.Id);
        }
        System.debug('BGS Entitlements:' + bgsEntitlementIds);
        return bgsEntitlementIds;
    }
}