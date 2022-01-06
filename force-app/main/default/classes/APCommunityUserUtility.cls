/**************************************************
Description: Utility class for APCommunityJitLoginHandler and responsible for 
             1. New Community User provisioning
             2. Assigning 'AP ONLINE COMMUNITY MEMBERSHIP' Permission set
             3. Updating the community user profile to 'DDC_CONSUMER_COMMUNITY_USER_PROFILE_NAME'
             4. If required, then updating community user attributes
History:
--------------------------------------------------
2019-10-22  arjun.singh@auspost.com.au  Created
**************************************************/
public with sharing class APCommunityUserUtility {
    public static final String CONSUMER_RECORD_TYPE_NAME = 'Consumer';

    /**
     * Handles all AP Community User Provisioning  related exceptions
     */
    public class APCommunityUserUtilityException extends Exception { }

    /**
    * Consumer Record Type Id for Ap Community User Provisioning via custom JIT handler
    */
    public static final Id CONSUMER_RECORD_TYPE_ID{
        get {
            return Schema.SObjectType.Account.getRecordTypeInfosByName().get(CONSUMER_RECORD_TYPE_NAME).getRecordTypeId();
        }
        private set;
    }
    /**
    * @Description     Method is used for new person account record creation with recordtype as 'Consumer'
    *                  Method does not check for duplicate record before creation of new person account record 
    * @param           User u , Map<String, String> attributes 
    * @return          Account Object
    */
    public static account createAPCommunityUserAccount(User u, Map<String, String> attributes){        
        Account newAccount = new Account();       
        newAccount.recordTypeId = CONSUMER_RECORD_TYPE_ID ;
        if(attributes.containsKey('firstName')) {
            newAccount.firstName = attributes.get('firstName');
        }
        if(attributes.containsKey('lastName')) {
            newAccount.lastName = attributes.get('lastName');
        }
        if(attributes.containsKey('email')) {
            newAccount.PersonEmail = attributes.get('email');
        }
        if(attributes.containsKey('apcn')) {
            newAccount.APCN__pc = attributes.get('apcn');
        }   
        insert newAccount;        
        return newAccount ;
    }
    /**
    * @Description     Method is used for 
    *                  1.new community User Creation and update on existing community User
    *                  2. Assigning the Permission Set 'AP_Online_Community_Membership'
    *                  3. Updating the profile to 'DDC Consumer Community User'
    * @param           Boolean create, User u , Account accountRecord, Map<String, String> attributes, String  federationIdentifier
    * @return          User Object
    */
    public static user createUpdateAPCommunityUser(Boolean create, User newUser, Account accountRecord, Map<String, String> attributes, String federationIdentifier){
        Boolean userAttributeChanged = false;
        if(newUser.FederationIdentifier != federationIdentifier){
            newUser.FederationIdentifier = federationIdentifier;
            userAttributeChanged = true;
        }
        if(create && attributes.containsKey('ConsumerUserName')) {
            newUser.Username = attributes.get('ConsumerUserName');
        }
        if(attributes.containsKey('User.Email') && (newUser.Email != attributes.get('User.Email'))) {
            newUser.Email = attributes.get('User.Email');
            userAttributeChanged = true;
        }
        if(attributes.containsKey('firstName') && (newUser.FirstName != attributes.get('firstName'))) {
            newUser.FirstName = attributes.get('firstName');
            userAttributeChanged = true;
        }
        if(attributes.containsKey('User.LastName') && (newUser.LastName != attributes.get('User.LastName'))) {
            newUser.LastName = attributes.get('User.LastName');
            userAttributeChanged = true;
        }
        if(create) {
            User currentUser = getCurrentUserDetails(UserInfo.getUserId());  
            newUser.LocaleSidKey = currentUser.LocaleSidKey;
            newUser.LanguageLocaleKey = currentUser.LanguageLocaleKey;
            newUser.TimeZoneSidKey = currentUser.TimeZoneSidKey;
            newUser.EmailEncodingKey = currentUser.EmailEncodingKey;
            newUser.ProfileId = APCommunityJitLoginHandler.profilesMap.get(APCommunityJitLoginHandler.DDC_CONSUMER_COMMUNITY_USER_TEMP_PROFILE_NAME);
            newUser.IsActive = true;

            String alias = '';
            if(newUser.FirstName == null) {
                alias = newUser.LastName;
            } else {
                alias = newUser.FirstName.charAt(0) + newUser.LastName;
            }
            if(alias.length() > 5) {
                alias = alias.substring(0, 5);
            }
            newUser.Alias = alias;
            Contact communityUsrContact = [Select Id From Contact Where accountId =: accountRecord.Id];
            newUser.contactId = communityUsrContact.Id;
            insert newUser; 
            // Fire an aynchrosnous process to validate/update user profile to DDC Community user and assign AP Online Permission Set           
             assignDDCProfileAndAPOnlinePermissionAtFuture(newUser.Id, APCommunityJitLoginHandler.ddcCommunityProfileId);
        }else{
            Boolean profileUpdateRequired = validateProfileNeedsToBeUpdatedToDDCCommunity(newUser, false);            
            if(profileUpdateRequired){
                newUser.ProfileId = APCommunityJitLoginHandler.ddcCommunityProfileId ;
                userAttributeChanged = true;
            }
            if(!newUser.isActive && isUserDDDCCommunityUser(newUser)){
                newUser.isActive = true;
                userAttributeChanged = true;
            }
            if(userAttributeChanged){
                update newUser;
            }
            // Call Permission Set Assignment Method , which check the user profile before assinging the permission Set 
             AssignAPOnlineCommunityPermissionSet(newUser);
        }
        return newUser;
    }
    /**
    * @Description     future method is called at the time of new community user creation and responsible for  
    *                  permission set assignment and updating profile to 'DDC Consumer Community User'
    * @param           Id userId, id communityProfileId
    * @return          void
    */
    @future 
    public static void assignDDCProfileAndAPOnlinePermissionAtFuture(Id userId, Id commnityProfileId){
        user usrRecord = getCurrentUserDetails(userId);
        try{
            assignAPOnlineCommunityPermissionSet(usrRecord);
            Boolean updateRequired = validateProfileNeedsToBeUpdatedToDDCCommunity(usrRecord, true);
            if(updateRequired){
                usrRecord.ProfileId = commnityProfileId;
                update usrRecord ;
            }
        }Catch(Exception e){
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), APCommunityJitLoginHandler.APPLICATION_NAME,APCommunityUserUtility.class.getName(), 'assignDDCProfileAndAPOnlinePermissionAtFuture',null, LoggingLevel.ERROR);
        }
    }
    /**
    * @Description     Method is used for assinging permission set to user of profile DDC Consumer Community User/DDC Consumer Community User Temp     
    * @param           user usrRecord
    * @return          void
    */
    public static void assignAPOnlineCommunityPermissionSet(User usrRecord){
        
        if(isUserDDDCCommunityUser(usrRecord) && usrRecord.PermissionSetAssignments.isEmpty()){
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = APCommunityJitLoginHandler.AP_ONLINE_COMMUNITY_MEMBERSHIP_PERMISSIONSET_ID, AssigneeId = usrRecord.Id);
            Insert psa;
        }
    }

    /**
    * @Description     Check if the User is DDC Community User     
    * @param           user usrRecord
    * @return          Boolean
    */
    public static Boolean isUserDDDCCommunityUser(User usrRecord){
        Boolean userIsDDCCommunityUser = false ;
        if((usrRecord.Profile.Name == APCommunityJitLoginHandler.DDC_CONSUMER_COMMUNITY_USER_TEMP_PROFILE_NAME || usrRecord.Profile.Name == APCommunityJitLoginHandler.DDC_CONSUMER_COMMUNITY_USER_PROFILE_NAME) ){
            userIsDDCCommunityUser = true;
        }
        return userIsDDCCommunityUser ;
    }
    /**
    * @Description     Check if Community User profile is DDC Temp, if yes then it will return
    *                  true , indicating profile needs to be updated to DDC profile         
    * @param           user userRecord, Boolean create
    * @return          Boolean
    */
    public static Boolean validateProfileNeedsToBeUpdatedToDDCCommunity(User userRecord, Boolean create){        
        Boolean updateRequired= false;
        String userCurrentProfileName;
        if(create){
            User usrRecordVar = getCurrentUserDetails(userRecord.Id);
            userCurrentProfileName = usrRecordVar.Profile.Name; 
        }else{
            userCurrentProfileName = userRecord.Profile.Name;
        }
        if(userCurrentProfileName == APCommunityJitLoginHandler.DDC_CONSUMER_COMMUNITY_USER_TEMP_PROFILE_NAME){            
            updateRequired = true;
        }
        return updateRequired;
    }
    /**
    * @Description     Used to return the details of newly created User
    * @param           id userId
    * @return          User Object
    */
    public static user getCurrentUserDetails(Id userId){

        User currentUser = [Select Id, FirstName, ContactId, Disallow_Community_Stepup__c, ProfileId, Profile.Name, FederationIdentifier,Email, LastName, 
                                  isActive, LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey, (SELECT Id FROM PermissionSetAssignments WHERE permissionSetId =: APCommunityJitLoginHandler.AP_ONLINE_COMMUNITY_MEMBERSHIP_PERMISSIONSET_ID) From User where Id =: userId] ;

        return currentUser;                          
    }  
}