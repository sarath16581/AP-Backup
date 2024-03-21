/**------------------------------------------------------------
Author:        Accenture IDC
Company:       Accenture
Description:   It is the utility class for trigger on Account

History
05.10.2011  Richard Enojas(Salesforce.com)      Created
29.05.2012  M. Isidro (Cloud Sherpas)           Added code that will update the Hub Catchment based on the Billing Post Code
06.06.2012  M. Isidro (Cloud Sherpas)           Added code that will update the Sales Segment based on the Physical/Shipping Address Post Code
13.06.2012  Joseph Barrameda (Cloud Sherpas)    Added code that will update the Sales Director based on the Sales Segment
13.07.2012  Joseph Barrameda (Cloud Sherpas)    Added code that will update the Hidden_Prior_Account_Manager_Email__c once the Account Manager has changed. (SP2)
25.07.2012  Richard Enojas(Salesforce.com)      Removed 'with sharing' (related to custom Lead Conversion process) 
19.09.2013  Matthew Watson (Salesforce.com)     Added method to generate unique Conveyancer Number for Retail Ops
02.01.2014  Louis Wang (Bluewolf)               Removed concept of Partner / Individual, such that standard Account-Contact is reestablished
12.05.2014  Mohaemd Atheek (Bluewolf)           Added a method to ignore out of sync updates from SAP CRM based off Integration_Service_Mod_Date__c
04.08.2015  Ritika Dhandia (Salesforce.com)     LiPOMS: Added Partner Info project methods for Licence and Facility
03.21.2016  Lyndon Lavapie (Cloud Sherpar)      Modified updateNetworkManager, checkPrimaryContact, activateLicence, verifyDuplicateLicence method to support new Licence record types
26.04.2016  Lyndon Lavapie (Cloud Sherpas)      Commented out checkPrimaryContact
03.05.2016  Lyndon Lavapie (Cloud Sherpas)      Added checkLegalEntityNPCIU,checkLEUpdate,checkNominatedContactEmail
15.05.2016  Andrew Judd(Salesforce.com)         Renamed checkLegalEntityNPCIU to checkLicenceInsert and extended, modified checkLEUpdate and checkNominatedContactEmail
30.05.2016  Andrew Judd(Salesforce.com)         Updated activateLicence.  Added update of outgoing Licence 'Agreement Effective From Date' and outgoing Licence Partner Addendums
02.06.2016  Andrew Judd(Salesforce.com)         Updated activateLicence.  Added set of 'Termination Reason'
06.06.2016  Andrew Judd(Salesforce.com)         Updated verifyDuplicateLicence to exclude Licences 'Not Activated'
03.08.2016  Davey Yu (Accenture)                MPB: Added new method MPBFilter to determine mpb accounts.  Update existing methods
                                                populateAccountRootId and assignSalesDirector
11/07/2016  Eugene Jandusay                     Created Utility class for Account trigger structure optimization
26.08.2016  Kalpita Talwadekar                  Updated class to optimize the code and follow coding standards.
03.07.2017  Dilshan Egodawela                   Added Verified Mobile field to ReversePhone Field nad modified the Order
10.07.2017  Dilshan Egodawela                   Added method to Lock Name updates based on LOA value
04.07.2019  Disha Kariya                        Added State Admin Email on Licence when created in updateNetworkManager.
10.03.2020  Swati Mogadala                       Added debug log as per Salesforce teams requestREQ2120103
04.08.2020  Swati Mogadala                      Used RecordTypesSelector.newInstance().selectByName() to get recordtypes for Account object using names
25.01.2020  SaiSwetha Pingali                   Fix for guest user access issues to avoid duplicate Holding Role references being created after the activation of CRUD "Secure Guest users Sharing settings and record access"
03.02.2021  SaiSwetha Pingali                  INC1727549 - Moved the logic to create customer role to a inner class without sharing as guest users doesn't have access to accounts.
22.02.2021  L. Serafico (Mav3rik)               Added updateAccountTeamForLPO to add/update Team to allow Accounts to be visible to LPO
17.03.2023  Naveen Rajanna						Correct formatting error
1/12/2023 Ken McGuire			OPC Replacement - update incremental and retained reveue for line items of reparented accounts - updateLIneItemRevenues
------------------------------------------------------------**/
public with sharing class AccountTriggerUtility {
    public  static final set<string> LICENCE_APPROVAL_STATUSES = LICENCE_APPROVAL_STATUSES__c.getAll().keySet();
    public  static final set<string> LICENCE_ACTIVE_STATUSES = LICENCE_ACTIVE_STATUSES__c.getAll().keySet();
    public  static final set<string> LICENCE_INACTIVE_STATUSES = LICENCE_INACTIVE_STATUSES__c.getAll().keySet();
    public  static final set<string> ACCOUNT_LICENCE_RECORDTYPES = ACCOUNT_LICENCE_RECORDTYPES__c.getAll().keySet();

    public static boolean RUN_TRIGGER_BEFORE_INSERT = true;
    public static boolean RUN_TRIGGER_AFTER_INSERT = true;
    public static boolean RUN_TRIGGER_BEFORE_UPDATE = true;
    public static boolean RUN_TRIGGER_AFTER_UPDATE = true;
    public static boolean RUN_TRIGGER_BEFORE_DELETE = true;
    public static boolean RUN_TRIGGER_AFTER_DELETE = true;
    public static boolean RUN_TRIGGER_ISUNDELETE = true;

    //class constant variables
    private  String ACCOUNT_STRING = 'Account';
    private  String PROSPECT = 'Prospect';
    private  String ORGANISATION = 'Organisation';
    private  String PARTNERINFO_PROFILE = 'PartnerInfo Read Only';
    private  String SALES_TEAM_STRING = 'Holding Sales Team';
    private  String HOLDING_USER = 'Holding User';
    private  String BLANK_SPACE = ' ';
    private String CONTID = 'ContactId';
    private String OUTGOING_LIC = 'OutgoingLicenceId';
    private String START_DATE = 'StartDate';
    private String IntegrationProfile = 'AusPost Integration';

    /**
      * @description       Exclude MPB sign-up/step-up process
      * @param             accounts List of new account records
      * @param             tInsert Trigger timing
      * @return            accountList List of account records to process
      * @throws            N/A
      */
    public static List<Account> mpbFilter(List<Account> accounts, Boolean tIsInsert){
        List<Account> accountList = new List<Account>();
        if(tIsInsert){
            for(Account a: accounts){
                system.debug('***account source: '+SSSWConstants.MPB_ACCOUNT_SOURCE.equalsIgnoreCase(a.AccountSource__c)+' '+a.AccountSource__c+' '+SSSWConstants.MPB_ACCOUNT_SOURCE);
                if(!SSSWConstants.MPB_ACCOUNT_SOURCE.equalsIgnoreCase(a.AccountSource__c) ){
                    accountList.add(a);
                }
            }
        }else{
            accountList.addAll(accounts);
        }
        system.debug('***accountList: '+accountList.size());
        return accountList;
    }

    /**
	 * @description       method to store reverse value of phone in ReversePhoneFields__pc for shortlisted records
	 * @param             List<Account> accounts
	 * @return            NA
	 * @throws            Exception Handled using exception handling framework
	 */
    public void generateReversePhoneFields(List<Account> accounts){
        List<Account> shortListed = new List<Account>();
        //iterate over all person accounts
        try{
            for(Account a: accounts){
                if(a.IsPersonAccount ){
                    shortListed.add(a);
                }
            }

            //call reversePhoneString method from utility then store in reversephonefield__pc
            for(Account a: shortListed){
                a.ReversePhoneFields__pc = Util.reversePhoneString(a.VerifiedMobile__pc) + BLANK_SPACE;
                a.ReversePhoneFields__pc += Util.reversePhoneString(a.PersonMobilePhone) + BLANK_SPACE;
                a.ReversePhoneFields__pc += Util.reversePhoneString(a.PersonHomePhone) + BLANK_SPACE;
                a.ReversePhoneFields__pc += Util.reversePhoneString(a.Phone) + BLANK_SPACE;
                a.ReversePhoneFields__pc += Util.reversePhoneString(a.PersonOtherPhone) + BLANK_SPACE;
            }

        }
        catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC,
                    SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
        }

    }

    /**
	 * @description       method to store reverse value of phone
	 * @param             Map<id, Account> newMap, Map<id, Account> oldMap
	 * @return            NA
	 * @throws            Exception Handled using exception handling framework
	 */
    public void generateReversePhoneFields(Map<id, Account> newMap, Map<id, Account> oldMap){
        List<Account> shortListed = new List<Account>();
        try{
            //iterate over records and check if the value has been changed
            for(Account a: newMap.values()){
                if(a.Phone != oldMap.get(a.id).Phone ||
                        a.PersonHomePhone != oldMap.get(a.id).PersonHomePhone ||
                        a.VerifiedMobile__pc != oldMap.get(a.id).VerifiedMobile__pc ||
                        a.PersonMobilePhone != oldMap.get(a.id).PersonMobilePhone ||
                        a.PersonOtherPhone != oldMap.get(a.id).PersonOtherPhone){

                    shortListed.add(a);
                }
            }
            //call generateReversePhoneFields method 
            if(!shortListed.isEmpty()) {
                generateReversePhoneFields(shortListed);
            }
        }catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC,
                    SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
        }
    }

/*spingali - Moved this class to an inner class without sharing 'AccessHoldingRoleandUser' to give access to guest users .      
	//method called for creating org role for filtered accounts
	public void createCustomerRole (List<Id> OrgIds){
        //List<Account> OrgList = [SELECT Id FROM Account WHERE Id in : OrgIds];
        List<Organisation_Role__c> OrgRoleList = new List<Organisation_Role__c>();
        try{
            for(Id Org : OrgIds){
                Organisation_Role__c OrgRole = new Organisation_Role__c(Organisation__c = Org, Role_Type__c = PROSPECT);
                OrgRoleList.add(OrgRole);
            }
            
            if(!OrgRoleList.isEmpty())
                database.insert(OrgRoleList);
            
        }catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                    AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC, 
                                                    SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
        }
    }
    
    */

    /**
	 * @description    method to populate account root id.
					   root id value:
					   if parent id is null, root id will be the record's id.
					   if parent id is populated, root id will be the parent id's root id
	 * @param          NA
	 * @return         NA
	 * @throws         NA
	 */
    public void PopulateAccountRootID(List<Account> acctList, Boolean bIsInsert) {
        //variable declarations
        List <String> rootIdList = new List<String>();
        Set <String> parentIdList = new Set <String>();
        Set<Id> recIdSet = new Set<Id>();
        Map <Id, Id> acctMap = new Map <Id, Id>() ;
        List <Account> acctUpdate = new List <Account>();
        Map <Id,Id> acctRootIdMap = new Map <Id, Id> ();

        try {
            for (Account tmpAcct : acctList){
                //acctMap.put (tmpAcct.Id , tmpAcct.ParentId);
                if(tmpAcct.ParentID != null){
                    parentIdList.add(tmpAcct.ParentID);
                }
                if(bIsInsert){
                    recIdSet.add(tmpAcct.Id);
                }

            }

            //build map to get root id of parent accounts
            for (Account a: [Select Id,Root_Id__c from Account where Id in : parentIdList]){
                if(a.Root_Id__c != null){
                    acctRootIdMap.put (a.Id,a.Root_id__c);
                }
            }

            if(bIsInsert){
                //on the insert scenario, query is needed to avoid record is read only error
                for(Account acc: [Select Id,ParentId,Root_Id__c from Account where Id in : recIdSet]){
                    if (acc.ParentId == null) {
                        acc.Root_Id__c = acc.Id;
                        System.debug('***Assigning own Id as Root ID because ParentID is null.');
                    }
                    else {
                        acc.Root_Id__c = acctRootIdMap.get(acc.ParentId);
                    }
                    acctUpdate.add(acc);
                }
            }else{
                //update scenario. no need to do a dml operation
                for(Account acc : acctList){
                    if (acc.ParentId == null) {
                        acc.Root_Id__c = acc.Id;
                        System.debug('***Assigning own Id as Root ID because ParentID is null.');
                    }
                    else {
                        acc.Root_Id__c = acctRootIdMap.get(acc.ParentId);
                    }
                }
            }
            //call update dml if list isnt empyu    
            if(!acctUpdate.isEmpty()){
                database.update(acctUpdate);
            }
        }catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC,
                    SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
        }
    }

    /**
	 * @description       method to populate sales director field based on Sales_Segment_Reference__c records
	 * @param             NA
	 * @return            NA
	 * @throws            NA
	 */
    public void assignSalesDirector (List<Account> acctList){
        List <String> salesSegmentList = new List <String>();
        Map <String,String> salesSegmentMap = new Map <String,String>();

        try{
            //get sales segment of the account
            for (Account acctTmp : acctList ){
                salesSegmentList.add(acctTmp.Sales_Segment__c);
            }

            //get the sales director of the sales segment from the Sales_Segment_Reference__c object
            for (Sales_Segment_Reference__c ssr : [SELECT Sales_Segment__c, Sales_Director__c FROM Sales_Segment_Reference__c
            WHERE (Sales_Segment__c in : salesSegmentList) AND (Sales_Director__c!='')]){
                salesSegmentMap.put( ssr.Sales_Segment__c , ssr.Sales_Director__c);
            }
            //assign sales director
            for (Account acct : acctList) {
                acct.Sales_Director__c = salesSegmentMap.get(acct.Sales_Segment__c);
            }

        }catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC,
                    SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
        }

    }

    //Copy names to Legal Names on Create
    public void CopyNameonCreate(List<Account> accounts){
        for(Account Acc : accounts){
            Acc.LegalFirstName__pc = Acc.FirstName;
            Acc.LegalLastName__pc = Acc.LastName;
            if(Acc.Preferred_Name__pc == null || Acc.Preferred_Name__pc == ''){
                Acc.Preferred_Name__pc = Acc.FirstName;}
        }
    }


    //disable updates for verified fields
    public void lockVerifiedData(List<Account> accounts, map<id, Account> oldAccounts){
        List<LOA_Settings__c> loas = LOA_Settings__c.getAll().values();
        Id integrationProfileID = [SELECT Id, Name FROM Profile WHERE Name=:IntegrationProfile LIMIT 1].Id;
        Map<Account,List<String>> errorMap = new Map<Account,List<String>>();
        for(Account acc : accounts){
            if(acc.IsPersonAccount){
                //set the preferred name from first name if preferred name is empty
                if(String.isEmpty(acc.Preferred_Name__pc) && !String.isEmpty(oldAccounts.get(acc.Id).Preferred_Name__pc)){
                    acc.Preferred_Name__pc = oldAccounts.get(acc.Id).Preferred_Name__pc;
                }
                if(String.isEmpty(acc.Preferred_Name__pc) && String.isEmpty(oldAccounts.get(acc.Id).Preferred_Name__pc)){
                    acc.Preferred_Name__pc = acc.FirstName;
                }
                //if not a verified account or the change is done by the Integration profile, copy name changes across to legal first name and legal last name.
                if(UserInfo.getProfileId() == integrationProfileID || acc.LevelOfAssurance__pc == null){
                    //if names changed, copy to legal
                    if(acc.FirstName != oldAccounts.get(acc.Id).FirstName){
                        acc.LegalFirstName__pc = acc.FirstName;
                    }
                    if(acc.LastName != oldAccounts.get(acc.Id).LastName){
                        acc.LegalLastName__pc = acc.LastName;
                    }
                    //if legal names are empty, copy from std name fields
                    if((acc.LegalFirstName__pc == '' || acc.LegalFirstName__pc == Null) && (oldAccounts.get(acc.Id).LegalFirstName__pc == '' || oldAccounts.get(acc.Id).LegalFirstName__pc == Null) ){
                        acc.LegalFirstName__pc = acc.FirstName == '' ? oldAccounts.get(acc.Id).FirstName : acc.FirstName ;
                    }
                    if((acc.LegalLastName__pc == '' || acc.LegalLastName__pc == Null) && (oldAccounts.get(acc.Id).LegalLastName__pc == '' || oldAccounts.get(acc.Id).LegalLastName__pc == Null) ){
                        acc.LegalLastName__pc = acc.LastName;
                    }
                }
                else{
                    for(LOA_Settings__c lockfields : loas){
                        //if account loa values is greater than the locked field loa, add lockfield name to error map.
                        if((lockfields.LOA_Value__c <= acc.LevelOfAssurance__pc) && (acc.get(lockfields.Locked_Field_API__c) != oldAccounts.get(acc.Id).get(lockfields.Locked_Field_API__c))){
                            //add error and break
                            if(!errorMap.containsKey(acc)){
                                errorMap.put(acc, New List<String>{lockfields.Name});
                            }
                            else{
                                errorMap.get(acc).add(lockfields.Name);
                            }
                        }
                        //check account loa agains name field loa values, if it's not greater(locked) copy name fields to legal name fields
                        if(lockfields.Locked_Field_API__c == 'LegalFirstName__pc' && lockfields.LOA_Value__c > acc.LevelOfAssurance__pc){
                            if(acc.FirstName != oldAccounts.get(acc.Id).FirstName){
                                acc.LegalFirstName__pc = acc.FirstName;
                            }
                            if((acc.LegalFirstName__pc == '' || acc.LegalFirstName__pc == Null) && (oldAccounts.get(acc.Id).LegalFirstName__pc == '' || oldAccounts.get(acc.Id).LegalFirstName__pc == Null) ){
                                acc.LegalFirstName__pc = acc.FirstName == '' ? oldAccounts.get(acc.Id).FirstName : acc.FirstName ;
                            }
                        }
                        if(lockfields.Locked_Field_API__c == 'LegalLastName__pc' && lockfields.LOA_Value__c > acc.LevelOfAssurance__pc){
                            if(acc.LastName != oldAccounts.get(acc.Id).LastName){
                                acc.LegalLastName__pc = acc.LastName;
                            }
                            if((acc.LegalLastName__pc == '' || acc.LegalLastName__pc == Null) && (oldAccounts.get(acc.Id).LegalLastName__pc == '' || oldAccounts.get(acc.Id).LegalLastName__pc == Null) ){
                                acc.LegalLastName__pc = acc.LastName;
                            }
                        }
                    }
                    if(!errorMap.isEmpty()){
                        for(Account a : errorMap.keySet()){
                            a.addError(Label.loaError+errorMap.get(a) , false);
                        }
                    }
                }
            }
        }
    }

    /**
	 * @description       Method to update previous owner of account
	 * @param             NA
	 * @return            NA
	 * @throws            NA
	 */
    public void updateAccountOwnerEmail(List <Account> newLst, List<Account> oldLst,  List <Id> acctPrevOwnerId){
        Map <Id, String> mapEmail = new Map<Id, String>();
        try{
            if (!newLst.isEMpty()){
                List <User> userList = [Select Id, Name, Email FROM User where Id in: acctPrevOwnerId];

                //iterate to check old owner
                for (Account acctList : oldLst){
                    for (User usr : userList){
                        if (acctList.OwnerId == usr.Id){
                            mapEmail.put(acctList.Id, usr.Email);
                            break;
                        }
                    }
                }
                //populate hidden field 
                for (Account acctList : newLst ){
                    acctList.Hidden_Prior_Account_Manager_Email__c  = mapEmail.get(acctList.id);

                }
            }

        }catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC,
                    SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
        }
    }

    /**
	 * @description       Sept 2013: Added for Retail Ops to generate unique Conveyancer Number for conveyancers
	 * @param             NA
	 * @return            NA
	 * @throws            NA
	 */
    public void generateConveyancerNumber(List <Account> accConveyancers) {
        try{
            // Retrieve the next id from Custom Setting - LOCK for update
            Conveyancer_Number__c [] cn = [SELECT Id, Next_Id__c FROM Conveyancer_Number__c LIMIT 1 FOR UPDATE];
            //Double latestNumber = cn[0].Next_Id__c;

            Double latestNumber ;
            if(!cn.isEmpty()) latestNumber = cn[0].Next_Id__c;


            if(latestNumber != null) {
                for(Account accCon: accConveyancers) {
                    accCon.Conveyancer_Number__c = latestNumber;
                    latestNumber = latestNumber + 1;
                }
                // Update the next id in the Custom Setting
                cn[0].Next_Id__c = latestNumber;
                update cn;
            }

        }catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC,
                    SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
        }
    }

    //convert to validation rule
    /**
	 * @description       Ignores out of sync updates from SAP CRM based off Integration_Service_Mod_Date__c
	 * @param             NA
	 * @return            NA
	 * @throws            NA

   public void ignoreOutOfSyncUpdates(Map<Id, Account> newMap, Map<Id, Account> oldMap) {
	   try{
		   for (Account newAcc : newMap.values()) {
			   if (newAcc.IsPersonAccount) {
				   Account oldAcc = oldMap.get(newAcc.Id);
				   if (newAcc.Integration_Service_Mod_Date__c != null &&
						   oldAcc.Integration_Service_Mod_Date__c != null &&
						   newAcc.Integration_Service_Mod_Date__c < oldAcc.Integration_Service_Mod_Date__c) {
					   newAcc.addError(Label.AccountOutOfSyncUpdateError);
				   }
			   }
		   }
	   }catch(Exception exp){
		   // Error Logged to Exception object for analysis
		   UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
												   AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC,
												   SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
	   }
   }
   */
    // ************** Partner Info Methods *****************
    /**
	 * @description       Method Populate Network Manager on Licence, on submission for approval
	 * @param             NA
	 * @return            NA
	 * @throws            NA
	 */
    public void updateNetworkManagerAndStateAdmin(list<Account> accounts, map<id, Account> oldAccounts){
        set<id> facilityIds = new set<id>();
        //  04.08.2020 Used Selector class instead of getRecordTypesByName to retrive recordtypes
        Map<Id,RecordType> licenceRTs = RecordTypesSelector.newInstance().selectByName('Account', ACCOUNT_LICENCE_RECORDTYPES);
        //Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(ACCOUNT_LICENCE_RECORDTYPES,ACCOUNT_STRING));
        Set<Id> licenceRTIds = new Set<Id>(licenceRTs.keySet());
        //Get Partner Info Settign to find State Admin based on StateAdmin from Licence.Facility.Network.ParentNetwork.State
        Partner_Info_Settings__c setting = Partner_Info_Settings__c.getInstance();
        try{

            //id licenseRT = RecordTypes.getRecordTypeByName('Licence', 'Account').id;
            system.debug('+++licenceRTIds+++'+licenceRTIds);
            for(Account account : accounts){
                System.debug('account.RecordTypeId--->'+account.RecordTypeId);
                //if(account.RecordTypeId == licenseRT &&
                if(licenceRTIds.contains(account.RecordTypeId) &&
                        (trigger.isInsert ||
                                (Label.APPROVAL_STATUS_PENDING.equalsIgnoreCase(account.Approval_Status__c)  &&
                                        !account.Approval_Status__c.equalsIgnoreCase(oldAccounts.get(account.id).Approval_Status__c)) )){
                    facilityIds.add(account.Facility__c);
                }
            }
            facilityIds.remove(null);

            // fetching the facility's netowrk's parent network's Network Manager
            if(facilityIds.size() > 0){
                map<id, Account> facilities = new map<id, Account>([
                        SELECT id, Network_Facility__r.Id ,
                                Network_Facility__r.Parent_Network__r.Network_Manager__c,
                                Network_Facility__r.Parent_Network__r.State__c
                        FROM Account
                        WHERE id in: facilityIds
                ]);
                for(Account account : accounts){
                    //if(account.RecordTypeId == licenseRT && 
                    if(licenceRTIds.contains(account.RecordTypeId) &&
                            account.Facility__c != null &&
                            (trigger.isInsert ||
                                    (Label.APPROVAL_STATUS_PENDING.equalsIgnoreCase(account.Approval_Status__c)  &&
                                            !account.Approval_Status__c.equalsIgnoreCase(oldAccounts.get(account.id).Approval_Status__c) ))){
                        Account facility = facilities.get(account.Facility__c);
                        // Throw error if parent Network Manager or State is blank
                        if(facility.Network_Facility__r.Parent_Network__r.Network_Manager__c == null || facility.Network_Facility__r.Parent_Network__r.State__c == null){
                            account.addError(Label.ERROR_NETWORK_MANAGER);
                        }
                        else{
                            //Assign Network Manager from Parent Network to Licence
                            account.Network_Manager__c = facility.Network_Facility__r.Parent_Network__r.Network_Manager__c;
                            //Assign StateAdmin on Licence based on  to Licence
                            account.Email__c = String.valueOf(setting.get('Email_List_'+facility.Network_Facility__r.Parent_Network__r.State__c+'__c'));
                        }
                    }
                    System.debug('account.name--->'+account.name);
                    System.debug('account.Email__c--->'+account.Email__c);
                    System.debug('account.Network_Manager__c--->'+account.Network_Manager__c);
                }
            }
        }catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC,
                    SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
        }
    }

    /**
	 * @description       Method Perform actions on Licence Activation
						  Cease outgoing Licence
						  Mark Organization on Facility as the incoming
	 * @param             NA
	 * @return            NA
	 * @throws            NA
	 */
    public void activateLicence(map<id, Account> accounts, map<id, Account> oldAccounts){
        system.debug('Accounts List :' +accounts);

        // Incoming Licence gets updated to Approved from a Time Based Workflow.
        // We capture the same Field Update change, and make the Outgoing Licence Ceased
        // and update the Facility's Parent Licence to the Incoming Licence
        //  04.08.2020 Used Selector class instead of getRecordTypesByName to retrive recordtypes
        Map<Id,RecordType> licenceRTs = RecordTypesSelector.newInstance().selectByName('Account', ACCOUNT_LICENCE_RECORDTYPES);
        //Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(ACCOUNT_LICENCE_RECORDTYPES,ACCOUNT_STRING));
        Set<Id> licenceRTIds = new Set<Id>(licenceRTs.keySet());
        set<id> activatedLicenceIds = new set<id>();
        //id licenseRT = RecordTypes.getRecordTypeByName('Licence', 'Account').id;
        try{
            for(Account acc : accounts.values()){
                if(licenceRTIds.contains(acc.RecordTypeId) &&  Label.LICENCE_STATUS_ACTIVE.equalsIgnoreCase(acc.Licence_Status__c) &&
                        !acc.Licence_Status__c.equalsIgnoreCase(oldAccounts.get(acc.id).Licence_Status__c)){
                    activatedLicenceIds.add(acc.id);

                }
            }

            if(!activatedLicenceIds.isEmpty()){
                map<id, Account> accountsToUpdate = new map<id, Account>();
                String sOutgoingLicenceId;
                Date dtAssignEffFromDate;

                for(Account acc : [
                        SELECT id, Facility__c, Facility__r.ParentId, Assignment_Effective_From_Date__c, Termination_Reason__c
                        FROM Account
                        WHERE id in: activatedLicenceIds
                ]){

                    if(acc.Facility__r.ParentId != null){
                        if(!accountsToUpdate.containsKey(acc.Facility__r.ParentId)){
                            accountsToUpdate.put(acc.Facility__r.ParentId, new Account(id = acc.Facility__r.ParentId));
                        }
                        // Set the Outgoing Licence to Ceased
                        if(acc.id<>acc.Facility__r.ParentId){
                            accountsToUpdate.get(acc.Facility__r.ParentId).Licence_Status__c = Label.LICENCE_STATUS_CEASED;
                            //AJ 30.5.16 Set Outgoing Licence Assignment Effective To Date and Termination Reason
                            accountsToUpdate.get(acc.Facility__r.ParentId).Assignment_Effective_To_Date__c = acc.Assignment_Effective_From_Date__c.addDays(-1);
                            accountsToUpdate.get(acc.Facility__r.ParentId).Termination_Reason__c = Label.TERMINATION_REASON;
                            //AJ 30.5.16 Store Licence Id and Assignment Effective To Date to pass to update PA flow below
                            sOutgoingLicenceId = acc.Facility__r.ParentId;
                            dtAssignEffFromDate = acc.Assignment_Effective_From_Date__c;
                        }
                    }

                    if(!accountsToUpdate.containsKey(acc.Facility__c)){
                        accountsToUpdate.put(acc.Facility__c, new Account(id = acc.Facility__c));
                    }

                    // Set the Incoming Licence as Parent of Facility
                    accountsToUpdate.get(acc.Facility__c).ParentId = acc.id;

                }

                try{
                    if(!accountsToUpdate.keySet().isEmpty()) {
                        for(Account myacc : accountsToUpdate.values()){
                            system.debug('UPDATING '+myacc.id+' '+myacc.Licence_Status__c);
                            system.debug('UPDATING '+myacc.id+' '+myacc.Parent);

                        }
                        database.update(accountsToUpdate.values());
                    }

                    //AJ 30.5.16 Call flow to update outgoing Partner Addenum dates and Renewal Status.
                    Map<String, Object> params = new Map<String, Object>();
                    params.put(OUTGOING_LIC, sOutgoingLicenceId );
                    params.put(START_DATE, dtAssignEffFromDate );
                    Flow.Interview.Partner_Info_Update_Partner_Addendum_Dates_Outgoing UpdPAfl = new Flow.Interview.Partner_Info_Update_Partner_Addendum_Dates_Outgoing(params);
                    UpdPAfl.start();
                    String returnValue = (String) UpdPAfl.Error;
                    if(!String.isblank(returnValue)){
                        system.debug('The following error occured updating the PAs against outgoing Licence ' + sOutgoingLicenceId + ' Error: ' + returnValue );
                    }
                }
                catch(DMLException ex){
                    System.debug('EX==>'+ex.getMessage());
                    for(Id accId : activatedLicenceIds){
                        accounts.get(accId).addError(Label.AccountActivateLicenceError);
                    }
                }
            }
        }
        catch(Exception exp){ UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(),
                SSSWConstants.SSSW_APP,
                AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC,
                SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);

        }
    }

    /**
	 * @description       Method  Verifies Duplicate License Account does not exist
	 * @param             NA
	 * @return            NA
	 * @throws            NA
	 */
    public void verifyDuplicateLicence(List<Account> accounts, map<id, Account> oldAccounts ){

        try{
            //  04.08.2020 Used Selector class instead of getRecordTypesByName to retrive recordtypes
            Map<Id,RecordType> licenceRTs = RecordTypesSelector.newInstance().selectByName('Account', ACCOUNT_LICENCE_RECORDTYPES);
            //Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(ACCOUNT_LICENCE_RECORDTYPES,ACCOUNT_STRING));
            Set<Id> licenceRTIds = new Set<Id>(licenceRTs.keySet());
            //id licenseRT = RecordTypes.getRecordTypeByName('Licence', 'Account').id;

            set<id> facilityIds = new set<id>();
            for(Account account : accounts){
                //if(account.RecordTypeId == licenseRT && account.Facility__c !=null){
                if(licenceRTIds.contains(account.RecordTypeId) && account.Facility__c !=null){
                    if( trigger.isInsert ||
                            account.Assignment_Effective_From_Date__c != oldAccounts.get(account.id).Assignment_Effective_From_Date__c ||
                            account.Facility__c != oldAccounts.get(account.id).Facility__c){
                        facilityIds.add(account.Facility__c);
                    }
                }
            }
            facilityIds.remove(null);

            if(facilityIds.size() > 0){
                map<id, list<Account>> facilityToAccount = new map<id, list<Account>>();
                // Query other licences
                for(Account acc : [
                        SELECT id, Assignment_Effective_To_Date__c, Assignment_Effective_From_Date__c ,
                                Facility__c, Licence_Status__c
                        FROM Account
                        WHERE RecordTypeId in: licenceRTIds
                        AND Facility__c in: facilityIds
                        AND Licence_Status__c != : Label.LICENCE_STATUS_CEASED
                        AND Licence_Status__c != : Label.LICENCE_STATUS_NOT_ACTIVATED
                        AND id not in : accounts
                ]){
                    if(!facilityToAccount.containsKey(acc.Facility__c)){
                        facilityToAccount.put(acc.Facility__c, new list<Account>());
                    }
                    facilityToAccount.get(acc.Facility__c).add(acc);
                }

                // Verify following conditions
                // For the same Facililty, Licence Record Type
                // 1. If Status in Licence Approval Statuses, error as Duplicate
                // 2. If Status in Licence Active / Suspended Statuses, error as Duplicate
                integer i =0;
                boolean errorFound = false;
                for(Account account : accounts){
                    errorFound = false;
                    if(account.Facility__c != null && licenceRTIds.contains(account.RecordTypeId) &&
                            (trigger.isInsert ||
                                    account.Assignment_Effective_From_Date__c != oldAccounts.get(account.id).Assignment_Effective_From_Date__c ||
                                    account.Facility__c != oldAccounts.get(account.id).Facility__c)){

                        if(facilityToAccount.containsKey(account.Facility__c)){

                            for(Account acc : facilityToAccount.get(account.Facility__c)){

                                if(LICENCE_APPROVAL_STATUSES.contains(acc.Licence_Status__c)){
                                    account.addError(Label.ERROR_LICENCE_EXISTS.replace('<status>',acc.Licence_Status__c));
                                    errorFound = true;
                                    break;
                                }
                                else if(acc.Assignment_Effective_To_Date__c != null &&
                                        LICENCE_ACTIVE_STATUSES.contains(acc.Licence_Status__c) &&
                                        acc.Assignment_Effective_To_Date__c >= account.Assignment_Effective_From_Date__c){
                                    account.addError(Label.ERROR_ACTIVE_LICENCE_EXISTS);
                                    errorFound = true;
                                    break;
                                }
                            }
                        }

                        if(!errorFound && trigger.isInsert){
                            for(Integer j=i+1; j<accounts.size(); j++){
                                Account accToCompare = accounts[j];

                                if(licenceRTIds.contains(accToCompare.RecordTypeId) && accToCompare.Facility__c == account.Facility__c){
                                    if(LICENCE_APPROVAL_STATUSES.contains(accToCompare.Licence_Status__c)){
                                        account.addError(Label.ERROR_LICENCE_EXISTS.replace('<status>',accToCompare.Licence_Status__c));
                                        break;
                                    }
                                    else if(accToCompare.Assignment_Effective_To_Date__c != null &&
                                            LICENCE_ACTIVE_STATUSES.contains(accToCompare.Licence_Status__c) &&
                                            accToCompare.Assignment_Effective_To_Date__c >= account.Assignment_Effective_From_Date__c){
                                        account.addError(Label.ERROR_ACTIVE_LICENCE_EXISTS);
                                        break;
                                    }
                                }

                            }
                        }

                        i++;
                    }
                }
            }

        }catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC,
                    SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
        }
    }


    /**
	 * @description       Method Prevent setting 'Nominated Partner Contact & Incent User' with email address the same as another 'Nominated Partner Contact & Incent User' with multi facilities (scenario 1)
	 * @param             NA
	 * @return            NA
	 * @throws            NA
	 */
    public void checkNominatedContactEmail(List<Account> newList, Map<Id,Account> oldMap){
        try{
            for(Account a: newList){
                Map<String, Object> params = new Map<String, Object>();
                Account oldAcc = oldMap.get(a.Id);
                if(a.Nominated_Partner_Contact_Incent_User__c != oldAcc.Nominated_Partner_Contact_Incent_User__c &&
                        a.Nominated_Partner_Contact_Incent_User__c != null){
                    params.put(CONTID, a.Nominated_Partner_Contact_Incent_User__c);
                    params.put(Label.LEGALENTITYID_ACC_PARAM, a.Id);
                    Flow.Interview.Partner_Info_Nominated_Contact_Check fl = new Flow.Interview.Partner_Info_Nominated_Contact_Check(params);
                    fl.start();

                    String returnValue = (String) fl.LegalEntityFoundName;
                    if(!String.isBlank(returnValue)){
                        a.addError(Label.UNIQUE_EMAIL_ADDRESS.replace(Label.ORG_NAME_ACC, returnValue));
                    }
                }
            }
        }
        catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC,
                    SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
        }
    }

    /**
	 * @description       When updating a Legal Entity or Facility on Licence, trigger the Nominated Partner Contact email check (scenario 2-Upd)
	 * @param             NA
	 * @return            NA
	 * @throws            NA
	 */
    public void checkLEUpdate(List<Account> newList, Map<Id,Account> oldMap){
        //  04.08.2020 Used Selector class instead of getRecordTypesByName to retrive recordtypes
        Map<Id,RecordType> licenceRTs = RecordTypesSelector.newInstance().selectByName('Account', ACCOUNT_LICENCE_RECORDTYPES);
        //Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(ACCOUNT_LICENCE_RECORDTYPES,ACCOUNT_STRING));
        try{
            for(Account a: newList){
                Map<String, Object> params = new Map<String, Object>();
                Account oldAcc = oldMap.get(a.Id);
                if((a.ParentId != oldAcc.ParentId || a.Facility__c != oldAcc.Facility__c) && licenceRTs.keySet().contains(a.RecordTypeId)){
                    params.put(Label.LEGALENTITYID_ACC_PARAM, a.ParentId);
                    params.put(Label.FACILITYID_ACC_PARAM, a.Facility__c);
                    Flow.Interview.Partner_Info_Nominated_Contact_Check fl = new Flow.Interview.Partner_Info_Nominated_Contact_Check(params);
                    fl.start();
                    Boolean leNPCIUSet = (Boolean) fl.LegalEntityNPCIUSet;
                    if(leNPCIUSet){
                        String returnValue = (String) fl.LegalEntityFoundName;
                        if(!String.isBlank(returnValue)){
                            a.addError(Label.UNIQUE_EMAIL_ADDRESS.replace(Label.ORG_NAME_ACC, returnValue));
                        }
                    }else{
                        a.addError(Label.ERROR_NOMINATED_CONTACT_REQUIRED);
                    }
                }
            }
        }
        catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC,
                    SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
        }
    }


    /**
	 * @description       Prevent insert of Licence if Legal Entity does not have a Primary Contact('Nominated Partner Contact & Incent User')
						  Also prevent insert of Licence if its Legal Entity has a Nominated Partner Contact email used by another LE with different facilities (scenario 2-Ins)
	 * @param             NA
	 * @return            NA
	 * @throws            NA
	 */
    public void checkLicenceInsert(List<Account> newList){
        //  04.08.2020 Used Selector class instead of getRecordTypesByName to retrive recordtypes
        Map<Id,RecordType> licenceRTs = RecordTypesSelector.newInstance().selectByName('Account', ACCOUNT_LICENCE_RECORDTYPES);
        //Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(ACCOUNT_LICENCE_RECORDTYPES,ACCOUNT_STRING));
        try{
            for(Account a: newList){
                if(licenceRTs.keySet().contains(a.RecordTypeId)){
                    Map<String, Object> params = new Map<String, Object>();
                    params.put(Label.LEGALENTITYID_ACC_PARAM, a.ParentId);
                    params.put(Label.FACILITYID_ACC_PARAM, a.Facility__c);
                    Flow.Interview.Partner_Info_Nominated_Contact_Check fl = new Flow.Interview.Partner_Info_Nominated_Contact_Check(params);
                    fl.start();
                    Boolean leNPCIUSet = (Boolean) fl.LegalEntityNPCIUSet;
                    if(leNPCIUSet){
                        String returnValue = (String) fl.LegalEntityFoundName;
                        if(!String.isBlank(returnValue)){
                            a.addError(Label.UNIQUE_EMAIL_ADDRESS.replace(Label.ORG_NAME_ACC, returnValue));
                        }
                    }else{
                        a.addError(Label.ERROR_NOMINATED_CONTACT_REQUIRED);
                    }
                }
            }
        }
        catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC,
                    SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
        }
    }


    /**
	 * @description       method before calling createCustomerRole. Sort accounts before creating customer role
	 * @param             NA
	 * @return            NA
	 * @throws            NA
	 */
    public void beforeCreateCustomerRole(List<Account> acctList) {
        List<Id> OrgIds = new List<Id>();

        //spingali - Created a new inner class without sharing to elevate access to guest users.
        AccessHoldingRoleandUser CustRole = new AccessHoldingRoleandUser();
        //check if it is a person account, scenario is done on insert and if Suppress_Default_Role__c is not ticked
        for (Account org : acctList){
            if (trigger.isInsert && !org.IsPersonAccount && !org.Suppress_Default_Role__c ){
                OrgIds.add(org.Id);
            }
        }

        //call createCustomerRole for filtered accounts
        if(!OrgIds.isEmpty())
            //createCustomerRole(OrgIds);
            //spingali -updated with createcustomerrole from inner class 
            CustRole.createCustomerRole(OrgIds);
    }

    /**
	 * @description       Method to be called on delete to reset the root id
	 * @param             NA
	 * @return            NA
	 * @throws            NA
	 */
    public void beforeResetRoodId(List<Account> acctList) {
        List<Account> delAcctList = new List<Account>();

        for (Account acct : acctList){
            if (!acct.IsPersonAccount)
                delAcctList.add(acct);
        }

        if (!delAcctList.isEmpty()){
            DeletedRecordUtil.createDeletedRecord(delAcctList, ACCOUNT_STRING);
            DeletedRecordUtil.resetRootId(delAcctList);
        }
    }

    /**
	 * @description       Method to call the delete util for person accounts
	 * @param             NA
	 * @return            NA
	 * @throws            NA
	 */
    public void beforeUndeleteDeletedRec(List<Account> acctList){

        List<Account> undelAcctList = new List<Account>();

        for (Account acct : acctList){
            if (!acct.IsPersonAccount)
                undelAcctList.add(acct);
        }

        if (!undelAcctList.isEmpty()){
            DeletedRecordUtil.undeleteDeletedRecord(undelAcctList);
        }
    }

    /**
	 * @description       Method to update account owner email address
	 * @param             NA
	 * @return            NA
	 * @throws            NA
	 */
    public void beforeUpdateAccOwnerEmail(List<Account> acctList,Map<Id,Account> oldMap,Map<Id,Account> newMap){

        List <Account> oldList = new List<Account>();
        List <Account> newList = new List <Account>();
        List <Id> acctPrevOwner = new List <Id>();

        for (Account acct: acctList){
            //System.debug('### NewMap :' + Trigger.newMap.get(acct.id).OwnerId + '; ### OldMap :' + Trigger.oldMap.get(acct.Id).OwnerId);
            if (newMap.get(acct.id).OwnerId != oldMap.get(acct.Id).OwnerId ){
                oldList.add (acct);
                newList.add (newMap.get(acct.id));
                acctPrevOwner.add (oldMap.get(acct.Id).OwnerId);
            }
        }
        if(!oldList.isEmpty()) {
            updateAccountOwnerEmail(newList, oldList, acctPrevOwner);
        }
    }

    /**
      * @description       Method to qualify the accounts for generating Conveyancer Number
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public void beforeGenerateConNumber(List<Account> acctList){
        List <Account> acctCon = new List<Account>();
        for (Account acctChanged: acctList) {
            if(acctChanged.Conveyancer_Is_a__c && acctChanged.Conveyancer_Number__c == null) {
                acctCon.add(acctChanged);
            }
        }
        if( !acctCon.isEmpty() )  {
            generateConveyancerNumber(acctCon);
        }
    }

    /**
	 * @description       Method to convert lead from person accounts -- made by davey for mypost
	 * @param             NA
	 * @return            NA
	 * @throws            NA
	 */
    public void beforeConvLeadPersAcc(List<Account> acctList){
        // Loop through the map, and only run this function if the CampaignMemberId field is not null on any of the records.
        Set<Id> targetedAccountIds = new Set<Id>();

        for (Account accountRec : acctList) {
            if (accountRec.IsPersonAccount && accountRec.MPB_Campaign_Member_Id__pc != null &&
                    !String.isBlank(accountRec.MPB_Campaign_Member_Id__pc)) {
                targetedAccountIds.add(accountRec.Id);
            }
        }
        if(!targetedAccountIds.isEmpty()) {
            MyPostBusinessLeadConvert.convertLeadPersonAccount(targetedAccountIds);
        }
    }

    /**
     * @description method called for updating product line item incremental and retained revenues
     * @param newList List<Account>
     * @param oldMap Map<Id,Account>
     */
    public void updateLIneItemRevenues(List<Account> newList, Map<Id,Account> oldMap) {
        Set<Id> reparentedAccountIds = new Set<Id>();
        for (Account record : newList) {
            Account oldValue = oldMap.get(record.Id);
            if (oldValue.ParentId != record.ParentId) {
                reparentedAccountIds.add(record.Id);
                if (oldValue.ParentId != null) {
                    reparentedAccountIds.add(oldValue.ParentId);
                }
                if (record.ParentId != null) {
                    reparentedAccountIds.add(record.ParentId);
                }
            }
        }
        updateLineItemRevenues(reparentedAccountIds);
    }

    public void updateLIneItemRevenues(List<Account> newList) {
        Set<Id> reparentedAccountIds = new Set<Id>();
        for (Account record : newList) {
            if (record.ParentId != null) {
                reparentedAccountIds.add(record.Id);
                reparentedAccountIds.add(record.ParentId);
            }
        }
        updateLineItemRevenues(reparentedAccountIds);
    }

    private void updateLineItemRevenues (Set<Id> reparentedAccountIds){
        if (reparentedAccountIds.isEmpty()) return;
        ProductRevenueService service = ProductRevenueService.getInstance();
        List<GroupedAccountProductRevenue__c> reCalculatedRevenues = service.reCalculateGroupRevenuesForAccounts(reparentedAccountIds);
        List<OpportunityLineItem> updatedLineItems = service.reCalculateRetainedIncremental();
        if (!updatedLineItems.isEmpty()) {
            List<Database.SaveResult> results = ApplicationDatabase.getInstance().dmlUpdate(updatedLineItems, false);
            UTIL_LoggingService.logDmlResults(results, null, updatedLineItems, 'DML update results',
                    AccountTriggerUtility.class.getName(), 'updateLineItemRevenues','AccountTrigger', LoggingLevel.ERROR);
        }
        if (!reCalculatedRevenues.isEmpty()) {
            List<Database.UpsertResult> results = ApplicationDatabase.getInstance().dmlUpsert(updatedLineItems,OpportunityLineItem.Id);
            UTIL_LoggingService.createExceptionForUpsertResults(results,null,'DML upsert results',
                    AccountTriggerUtility.class.getName(),'updateLineItemRevenues','AccountTrigger',LoggingLevel.ERROR);
        }
    }

    /**
      * @description       Method to insert holding role
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public void insertHoldingRoleRef(){
        Holding_Role_Reference__c hr = new Holding_Role_Reference__c (Name = PROSPECT);
        AccessHoldingRoleandUser HRole = new AccessHoldingRoleandUser();
        /* spingali - This soql is handled in without sharing inner class as guest users doesn't have sharing on Hold Role Reference object
        Boolean isHoldRole = false;
        //check if holding role reference exists
        for(Holding_Role_Reference__c prospectHR : [Select Id,Name FROM Holding_Role_Reference__c WHERE Name =: PROSPECT]) {
            isHoldRole = true;
        }
        //if no holding role exists, insert holding role reference record.
        if(!isHoldRole ) {
            database.insert(hr);
        } */

        //if no holding role exists, insert holding role reference record.
        if(!HRole.checkHoldingRole()) {
            database.insert(hr);
        }
    }

    // Moved this class to public without sharing inner class as Guest users doesn't have sharing access on the accounts and Hold Role References object 

    //can do in future
    /**
	 * @description       Method to associate the holding role reference to the organizations created.
	 * @param             NA
	 * @return            NA
	 * @throws            NA
	 */
    /*  public void assignHoldingRoleAndAccMan(List<Account> acctList){
		  try{
			  Holding_Role_Reference__c prospectHoldingRole = new Holding_Role_Reference__c();
			  List<Account> OrgList = new List<Account>();

			  //check if Prospect Holding role exists within the org
			  for(Holding_Role_Reference__c prospectHR : [Select Id,Name FROM Holding_Role_Reference__c WHERE Name =: PROSPECT]) {
				  prospectHoldingRole = prospectHR;
			  }
			  //get recordtype id of Organisation
			  Id orgRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(ORGANISATION).getRecordTypeId();
			  Id partnerInfoProfileId = [Select Id, Name FROM Profile WHERE Name =: PARTNERINFO_PROFILE].Id;

			  List<User> holdingUser = [Select Id,Name FROM User where Name =: HOLDING_USER LIMIT 1];

			  for(Account a :acctList){
				  if(a.RecordTypeId == orgRecordTypeId  &&  UserInfo.getProfileId() != partnerInfoProfileId){
						  orgList.add(new Account(Id=a.Id, Holding_Role_Reference__c = prospectHoldingRole.Id,
												  OwnerId = holdingUser[0].Id,Sales_Segment__c = SALES_TEAM_STRING));
				  }
			  }
			  if(!OrgList.isEmpty())
				  database.update(OrgList);
		  }
		  catch(exception exp){ UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
											  AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC,
											  SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);

		  }

	  } */

    /**
      * @description       Method to update the billing accounts with parent date changed on delete of parent account
                           and
                           Delete revenue by organisation record when an account is deleted such as customer merge
      * @param             List<Account> acctList
      * @return            NA
      * @throws            NA
      */
    public void updateBAondelete(List<Account> acctList){
        try{

            List<Billing_Account__c> ba = new List<Billing_Account__c>();

            for(Account a:  [SELECT Id, (Select Id from Billing_Accounts__r ) FROM Account WHERE Id in :acctList]) {
                for(Billing_Account__c b : a.Billing_Accounts__r) {
                    b.Date_Parent_Changed__c = Datetime.now();
                    ba.add(b);
                }
            }
            if(!ba.isEMpty()) {
                database.update(ba);
            }
            //to check revenue by organisation object and delete if any records.        
            List <Revenue_by_organisation__c> rbo = new List <Revenue_by_organisation__c>();

            for(Account a: [SELECT Id, (Select Id from Revenue_by_Organisation__r ) FROM Account WHERE Id in :acctList]) {
                for(Revenue_by_organisation__c ro : a.Revenue_by_Organisation__r) {
                    rbo.add(ro);
                }
            }
            if (!rbo.isEmpty()) {
                database.delete(rbo);
            }
        }
        catch(Exception exp) { UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                AccountTriggerUtility.class.getName(), 'updateBAondelete',
                SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
        }
    }
    /**
	* @description       Method to delete related Revenue by Billing account and Customer Revenue records when an account is deleted such as customer merge
	* @param             List<Account> acctList
	* @return            NA
	* @throws            NA
	*/
    public void deleteRReconDelete(List<Account> acctList){

        try{

            List<Budget_and_Revenue__c> custRev = new List<Budget_and_Revenue__c>();

            for(Account a:  [SELECT Id, (Select Id from Budget_and_Revenue_2__r) FROM Account WHERE Id in :acctList]) {
                for(Budget_and_Revenue__c br : a.Budget_and_Revenue_2__r) {
                    custRev.add(br);
                }
            }

            if(!custRev.isEmpty()) {
                delete(custRev);
            }

            List<Revenue_by_Billing_Account__c> revBil = new List<Revenue_by_Billing_Account__c>();

            for(Account a:  [SELECT Id, (Select Id from Revenue_by_Billing_Account__r) FROM Account WHERE Id in :acctList]) {
                for(Revenue_by_Billing_Account__c rb : a.Revenue_by_Billing_Account__r) {
                    revBil.add(rb);
                }
            }

            if(!revBil.isEmpty()) {
                database.delete(revBil);
            }
        }
        catch(Exception exp) { UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                AccountTriggerUtility.class.getName(), 'updateBRonUpdate',
                SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
        }

    }

    /** spingali - Fix for issues identified after the CRUD "Secure Guest Users' Sharing Settings and Record Access"
	   * Public inner class that elevates access privileges of the current user to query data without being limited by
	   * sharing settings.
		 Public Guest users should be able to view the existing Holding Role and assign it to the account.
	   */
    public without sharing class AccessHoldingRoleandUser
    {
        public Boolean checkHoldingRole() {
            Boolean isHoldRole = false;
            //check if holding role reference exists
            for(Holding_Role_Reference__c prospectHR : [Select Id,Name FROM Holding_Role_Reference__c WHERE Name = 'Prospect']) {
                isHoldRole = true;
            }
            return isHoldRole;
        }

        /**
		* @description       method called for creating org role for filtered accounts
		* @param             NA
		* @return            NA
		* @throws            NA
		*/
        public void createCustomerRole (List<Id> OrgIds){
            //List<Account> OrgList = [SELECT Id FROM Account WHERE Id in : OrgIds];
            List<Organisation_Role__c> OrgRoleList = new List<Organisation_Role__c>();
            try{
                for(Id Org : OrgIds){
                    Organisation_Role__c OrgRole = new Organisation_Role__c(Organisation__c = Org, Role_Type__c = 'Prospect');
                    OrgRoleList.add(OrgRole);
                }

                if(!OrgRoleList.isEmpty())
                    database.insert(OrgRoleList);

            }catch(Exception exp){
                // Error Logged to Exception object for analysis
                UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                        AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC,
                        SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
            }
        }

        public void assignHoldingRoleAndAccMan(List<Account> acctList)
        {
            try{
                Holding_Role_Reference__c prospectHoldingRole = new Holding_Role_Reference__c();
                List<Account> OrgList = new List<Account>();
                //check if Prospect Holding role exists within the org
                for(Holding_Role_Reference__c prospectHR : [Select Id,Name FROM Holding_Role_Reference__c WHERE Name ='Prospect']) {
                    prospectHoldingRole = prospectHR;
                }

                //get recordtype id of Organisation
                Id orgRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organisation').getRecordTypeId();
                Id partnerInfoProfileId = [Select Id, Name FROM Profile WHERE Name ='PartnerInfo Read Only'].Id;

                List<User> holdingUser = [Select Id,Name FROM User where Name ='Holding User' LIMIT 1];

                for(Account a :acctList){
                    if(a.RecordTypeId == orgRecordTypeId  &&  UserInfo.getProfileId() != partnerInfoProfileId){
                        orgList.add(new Account(Id=a.Id, Holding_Role_Reference__c = prospectHoldingRole.Id,
                                OwnerId = holdingUser[0].Id,Sales_Segment__c = 'Holding Sales Team'));
                    }
                }
                if(!OrgList.isEmpty())
                    database.update(OrgList);
            }
            catch(exception exp){ UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    AccountTriggerUtility.class.getName(), SSSWConstants.METH_UPDATEHLC,
                    SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);

            }
        }
    }
    /**
      * @description       Method check if need Account Team based on Post Office Assigned value 
      *                    for a queueable job
      * @param             Map<Id, sobject> trigger.oldval for account
      * @param             Map<Id, sobject> trigger.newVal for account
      * @return            NA
      * @throws            NA
      */
    public void updateAccountTeamForLPO(Map<Id, sobject> oldVal, Map<Id, sobject> newVal){
        Set<Id> networkIdsToAdd = new Set<Id>();
        Set<Id> acctIdsToRemove = new Set<Id>();
        Map<String, Set<Id>> orgIdsToAccounts = new Map<String, Set<Id>>();

        for(Account record: (List<Account>)newVal.values()) {
            Account oldRecord;
            if(oldVal != null) oldRecord = (Account) oldVal.get(record.Id);
            if(record.Post_Office_Assigned__c != null) {
                // no old value means the record is newly created.
                // That is an insert action
                if(oldRecord == null) {
                    networkIdsToAdd.add(record.Post_Office_Assigned__c);
                    if(orgIdsToAccounts.containsKey(record.Post_Office_Assigned__c)){
                        Set<Id> tempSet = orgIdsToAccounts.get(record.Post_Office_Assigned__c);
                        tempSet.add(record.Id);
                        orgIdsToAccounts.put(record.Post_Office_Assigned__c, tempSet);
                    }
                    else{
                        orgIdsToAccounts.put(record.Post_Office_Assigned__c, new Set<Id>{record.Id});
                    }
                } else if( record.Post_Office_Assigned__c != oldRecord.Post_Office_Assigned__c) {
                    networkIdsToAdd.add(record.Post_Office_Assigned__c);
                    acctIdsToRemove.add(oldRecord.Id);
                    if(orgIdsToAccounts.containsKey(record.Post_Office_Assigned__c)){
                        Set<Id> tempSet = orgIdsToAccounts.get(record.Post_Office_Assigned__c);
                        tempSet.add(record.Id);
                        orgIdsToAccounts.put(record.Post_Office_Assigned__c, tempSet);
                    }
                    else{
                        orgIdsToAccounts.put(record.Post_Office_Assigned__c, new Set<Id>{record.Id});
                    }
                }
            } else if(oldRecord != null && String.isBlank(record.Post_Office_Assigned__c)
                    && record.Post_Office_Assigned__c != oldRecord.Post_Office_Assigned__c) {
                //add to a list of account Id where team members should be deleted
                acctIdsToRemove.add(record.Id);
            }
        }
        // The Queueable function only fires when the 
        if(!acctIdsToRemove.isEmpty() || !networkIdsToAdd.isEmpty()) {
            System.enqueueJob(new AccountTeamMemberModificationQueueable(networkIdsToAdd, acctIdsToRemove, orgIdsToAccounts));
        }
    }

    public class AccountTeamMemberModificationQueueable implements Queueable {
        Set<Id> networkIdsToAdd = new Set<Id>();
        Set<Id> acctIdsToRemove = new Set<Id>();
        Map<String, Set<Id>> orgIdsToAccounts = new Map<String, Set<Id>>();

        public AccountTeamMemberModificationQueueable(Set<Id> networkIdsToAdd, Set<Id> acctIdsToRemove,
                Map<String, Set<Id>> orgIdsToAccounts) {
            this.networkIdsToAdd = networkIdsToAdd;
            this.acctIdsToRemove = acctIdsToRemove;
            this.orgIdsToAccounts = orgIdsToAccounts;
        }
        /**
		 * @description      Method adds, updates, deletes Account Team based on Post Office Assigned value
		* @param             QueueableContext context
		* @return            NA
		* @throws            NA
		*/
        public void execute(QueueableContext context) {
            Set<String> orgIdsToAdd = new Set<String>();
            if (!acctIdsToRemove.isEmpty()) {
                List<AccountTeamMember> acctTeamToRemove = AccountTeamMembersSelector.newInstance().selectByTeamRoleAndAccountIds(
                        'Post Office User', acctIdsToRemove, new Set<Object>()).values();

                if (acctTeamToRemove.size() > 0) {
                    delete acctTeamToRemove;
                }
            }
            if (networkIdsToAdd.isEmpty()) return;

            Map<Id, Network__c> netWorks = NetworksSelector.newInstance(new Set<SObjectField>{
                    Network__c.Id, Network__c.Org_ID__c
            }).selectById(networkIdsToAdd);

            //Get Org Id From Network and add to a List
            for (Network__c n : netWorks.values()) {
                orgIdsToAdd.add(n.Org_ID__c);
                if (orgIdsToAccounts.containsKey(n.Id)) {
                    Set<Id> sId = orgIdsToAccounts.get(n.Id);
                    orgIdsToAccounts.remove(n.Id);
                    orgIdsToAccounts.put(n.Org_ID__c, sId);
                }
            }

            Map<Id, String> partnerAcctsToOrgId = new Map<Id, String>();
            //Get Uppermost Account based on OrgId with the assumption that hierarchy can go up to four level
            for (Account a : [
                    SELECT Id, RecordType.DeveloperName, ParentId, WCIS_Code__c, Licence_Type__c,
                            Parent.RecordType.DeveloperName, Parent.ParentId,
                            Parent.Parent.RecordType.DeveloperName
                    FROM Account
                    WHERE WCIS_Code__c IN :orgIdsToAdd
                    AND RecordType.Name = 'Facility'
            ]) {

                if (('RP'.equalsIgnoreCase(a.Licence_Type__c) || 'BC'.equalsIgnoreCase(a.licence_Type__c))  && a.ParentId == null) {
                    // this is too accommodate the CPO scenario where a facility record will exist, however no License or Organisation record
                    // the contacts in the scenario will exist on the Facility record directly
                    partnerAcctsToOrgId.put(a.Id, a.WCIS_Code__c);
                } else if (a.Parent != null && a.Parent.Parent != null &&
                        a.Parent.RecordType != null && 'Licence'.equalsIgnoreCase(a.Parent.RecordType.DeveloperName) &&
                        a.Parent.Parent.RecordType != null && 'Business_Account'.equalsIgnoreCase(a.Parent.Parent.RecordType.DeveloperName)) {
                    // this is to handle the LPO scenario where a Facility record has a License linked to the Legal Entity holding the license
                    partnerAcctsToOrgId.put(a.Parent.ParentId, a.WCIS_Code__c);
                }
            }

            if (!partnerAcctsToOrgId.isEmpty()) {

                //Get LPO Contacts Uppermost Account
                Map<Id, Id> contactIdsToCheck = new Map<Id, Id>();
                Map<Id, Contact> contacts = ContactsSelector.newInstance().selectByAccount(partnerAcctsToOrgId.keySet());
                for (Contact c : contacts.values()) {
                    contactIdsToCheck.put(c.Id, c.AccountId);
                }

                //Add LPO Contacts to Uppermost Account
                List<AccountTeamMember> acctTeamToAdd = new List<AccountTeamMember>();
                if (!contactIdsToCheck.isEmpty()) {

                    Map<Id, User> usrMap = UsersSelector.newInstance().selectActiveuserByProfileName(contactIdsToCheck.keySet(),
                            'LPO Partner Community User', new Set<Object>());

                    for (User u : usrMap.values()) {
                        if (contactIdsToCheck.containsKey(u.ContactId) && partnerAcctsToOrgId.containsKey(contactIdsToCheck.get(u.ContactId)) &&
                                orgIdsToAccounts.containsKey(partnerAcctsToOrgId.get(contactIdsToCheck.get(u.ContactId)))) {
                            for (Id aId : orgIdsToAccounts.get(partnerAcctsToOrgId.get(contactIdsToCheck.get(u.ContactId)))) {
                                AccountTeamMember at = new AccountTeamMember();
                                at.UserId = u.Id;
                                at.TeamMemberRole = 'Post Office User';
                                at.AccountId = aId;
                                at.AccountAccessLevel = 'Edit';
                                at.OpportunityAccessLevel = 'Read';
                                at.CaseAccessLevel = 'Read';
                                acctTeamToAdd.add(at);
                            }
                        }
                    }

                    if (!acctTeamToAdd.isEmpty()) {
                        try {
                            ApplicationDatabase.getInstance().dmlInsert(acctTeamToAdd);
                        } catch (Exception e) {
                            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                                    AccountTriggerUtility.class.getName(), 'updateAccountTeamForLPO',
                                    SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);
                        }
                    }

                }
            }
        }
    }

}