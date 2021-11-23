/**************************************************
Type:       Utility Class for Account Object
Purpose:    Create a default Party Role with Type='Customer', plus other utility methods
Used By:    AccountTrigger
History:
--------------------------------------------------
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
**************************************************/
public class AccountUtil {
   
   public static final set<string> LICENCE_APPROVAL_STATUSES = new set<string>{'Draft', 'Pending', 'Approved', 'Rejected'};
   public static final set<string> LICENCE_ACTIVE_STATUSES = new set<string>{'Active', 'Suspended Without Fees', 'Suspended With Fees'};
   public static final set<string> LICENCE_INACTIVE_STATUSES = new set<string>{'Ceased', 'Not Activated'};
   public static final string ERROR_NOMINATED_CONTACT_REQUIRED = 'The Parent Organisation must have a "Nominated Partner Contact & Incent User" before creating a Licence.';
   public static final string ERROR_LICENCE_EXISTS = 'Found another Licence for this Facility in <status> status. Please use it.';
   public static final string ERROR_ACTIVE_LICENCE_EXISTS = 'Another Licence is already active for this start date';   
   public static final string ERROR_NETWORK_MANAGER = 'Failed to determine the approval authority for this Facility. Please contact business support team.';
   public static final string APPROVAL_STATUS_PENDING = 'Pending';
   public static final string LICENCE_STATUS_CEASED = 'Ceased';
   public static final string LICENCE_STATUS_ACTIVE = 'Active';
   public static final string LICENCE_STATUS_NOT_ACTIVATED = 'Not Activated';
   public static final string EMAIL_MISSING = 'Please specify Email address for the Primary Contact of the Legal Entity';
   public static final string SPECIFY_CONTACT = 'Please specify the Contact related to Legal Entity as Primary';
   public static final string PRIMARY_CONTANCT = 'Please specify a Primary Contact for the Legal Entity';
   public static final string UNIQUE_EMAIL_ADDRESS = '"Nominated Partner Contact & Incent User" email address must be unique across all Legal entities with Licences in any status excluding "Ceased" or "Not Activated". The "Nominated Partner Contact & Incent User" for Organisation [ORG NAME] has the same email address as this contact.';
   public static final string NOMINATED_CONTACT = 'Legal Entity [ORG NAME] must have a "Nominated Partner Contact & Incent User" set before creating a new Licence.';
   public static final string TERMINATION_REASON = 'New Assignment';
   public static boolean RUN_TRIGGER_BEFORE_INSERT = true;
   public static boolean RUN_TRIGGER_BEFORE_UPDATE = true;
   public static boolean RUN_TRIGGER_AFTER_UPDATE = true;

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
                if(a.AccountSource__c != SSSWConstants.MPB_ACCOUNT_SOURCE){
                    accountList.add(a);
                }
            } 
        }else{
            accountList.addAll(accounts);
        }

        return accountList;
    }
    


   public static void generateReversePhoneFields(List<Account> accounts){
        List<Account> shortListed = new List<Account>();
        for(Account a: accounts){
            if(a.IsPersonAccount){
                shortListed.add(a);
            }
        }
        for(Account a: shortListed){
            a.ReversePhoneFields__pc = Util.reversePhoneString(a.Phone) + ' ';
            a.ReversePhoneFields__pc += Util.reversePhoneString(a.PersonHomePhone) + ' ';
            a.ReversePhoneFields__pc += Util.reversePhoneString(a.PersonMobilePhone) + ' ';
            a.ReversePhoneFields__pc += Util.reversePhoneString(a.PersonOtherPhone) + ' ';
        }
    }
    
    public static void generateReversePhoneFields(Map<id, Account> newMap, Map<id, Account> oldMap){
        List<Account> shortListed = new List<Account>();
        for(Account a: newMap.values()){
            if(a.Phone != oldMap.get(a.id).Phone || 
               a.PersonHomePhone != oldMap.get(a.id).PersonHomePhone ||
               a.PersonMobilePhone != oldMap.get(a.id).PersonMobilePhone ||
               a.PersonOtherPhone != oldMap.get(a.id).PersonOtherPhone){
                
                shortListed.add(a);
            }
        }
        generateReversePhoneFields(shortListed);
    }
        
    
    public static void createCustomerRole (List<Id> OrgIds){
        
        List<Account> OrgList = [SELECT Id FROM Account WHERE Id in : OrgIds];
        List<Organisation_Role__c> OrgRoleList = new List<Organisation_Role__c>();
        
        for(Account Org : OrgList){
            Organisation_Role__c OrgRole = new Organisation_Role__c(Organisation__c = Org.Id, Role_Type__c = 'Prospect');
            OrgRoleList.add(OrgRole);
        }
        
        if(!OrgRoleList.isEmpty())
            insert OrgRoleList;
        
        //try {
        //  if(!OrgRoleList.isEmpty())
        //      insert OrgRoleList;
        //} catch (System.DmlException e) {
        //  for (Integer i = 0; i < e.getNumDml(); i++) {
            // Process exception here 
        //  System.debug(e.getDmlMessage(i)); 
        //  }
        //}
            
            
    }

    // public static void createPartnership(Map<Id,Account> partnerMap, List<Id> partnerIds)
    // LW - removed 2/01/2014    
    
    public static void PopulateAccountRootID(List<Account> acctList, Boolean bIsInsert) { 
        List <String> rootIdList = new List<String>();
        List <String> parentIdList = new List <String>();
        Map <Id, Id> acctMap = new Map <Id, Id>() ; 
        List <Account> acctUpdate = new List <Account>();
        Map <Id,Id> acctRootIdMap = new Map <Id, Id> ();    
        
        try {    
            for (Account tmpAcct : acctList){                
             
                acctMap.put (tmpAcct.Id , tmpAcct.ParentId);            
                parentIdList.add(tmpAcct.ParentID); 
                
            }            
              
            if (!parentIdList.isEmpty()) {
                for (Account a: [Select Id,Root_Id__c from Account where Id in : parentIdList]){                
                    acctRootIdMap.put (a.Id, a.Root_id__c);    //Add the Account.Id and Root_Id  to the map
                    rootIdList.add (a.Root_Id__c);                  
                }
            }                       
            
            system.debug('***acctRootIdMap: ' + acctRootIdMap);
            
            if (!rootIdList.isEmpty()) { 
                if (bIsInsert) {
                    for (Account acc: [Select Id,ParentId,Root_Id__c from Account where Id in : acctMap.keySet()]){
                        System.debug('***Getting ParentId:' + acctRootIdMap.get(acc.ParentId)); 
                        if (acc.ParentId == null) {             //Assign                        
                            acc.Root_Id__c = acc.Id; 
                            System.debug('***Assigning own Id as Root ID because ParentID is null.');
                        }
                        else { 
                            acc.Root_Id__c = acctRootIdMap.get(acc.ParentId);
                        } 
                        acctUpdate.add(acc) ;
                    }  
                    update acctUpdate;
                } else {
                    for (Account acct: acctList){
                        System.debug('***Getting ParentId:' + acctRootIdMap.get(acct.ParentId)); 
                        if (acct.ParentId == null) {                //Assign                        
                            acct.Root_Id__c = acct.Id; 
                            System.debug('***Assigning own Id as Root ID because ParentID is null.');
                        }
                        else { 
                            acct.Root_Id__c = acctRootIdMap.get(acct.ParentId);
                        } 
                    }  
                }               
            }
         } catch(Exception e){ System.debug('AccountTriggerManager Class error:' + e.getMessage());}
    }

    // public static void updateIndividualScore(List<Account> IndList){}
    // LW - removed 2/01/2014
    
    public static void assignSalesDirector (List<Account> acctList){        
        List <String> salesSegmentList = new List <String>();
        Map <String,String> salesSegmentMap = new Map <String,String>();
        
        for (Account acctTmp : acctList ){
            /*** START OF UPDATE DYU MPB 12-AUG-2016 -  Check if there is a parent id ***/ 
            if(acctTmp.Sales_Segment__c != null)
                salesSegmentList.add(acctTmp.Sales_Segment__c);  
            /*** END OF UPDATE DYU MPB 12-AUG-2016 ***/
        }

        /*** START OF UPDATE DYU MPB 12-AUG-2016 -  Check if there is salesSegmentList is not empty ***/ 
        if(!salesSegmentList.isEmpty()){
            for (Sales_Segment_Reference__c ssr : [SELECT Sales_Segment__c, Sales_Director__c FROM Sales_Segment_Reference__c WHERE (Sales_Segment__c in : salesSegmentList) AND (Sales_Director__c!='')]){            
                salesSegmentMap.put( ssr.Sales_Segment__c , ssr.Sales_Director__c);
            }
        }
        /*** END OF UPDATE DYU MPB 12-AUG-2016 ***/
        
        /*** START OF UPDATE DYU MPB 12-AUG-2016 - Check if salesSegmentMap is not empty ***/
        if(!salesSegmentMap.isEmpty() || salesSegmentMap != null){
            for (Account acct : acctList) {                                 
                acct.Sales_Director__c = salesSegmentMap.get(acct.Sales_Segment__c);             
            }
        }
        /*** END OF UPDATE DYU MPB 12-AUG-2016 ***/

        System.debug('******Account List: ' + acctList ); 
        System.debug ('******Sales Segment Map: ' + salesSegmentMap);       
        
    }    
    
    public static void updateAccountOwnerEmail(List <Account> newLst, List<Account> oldLst,  List <Id> acctPrevOwnerId){
        Map <Id, String> mapEmail = new Map<Id, String>(); 
        if (newLst !=null){
            List <User> userList = [Select Id, Name, Email FROM User where Id in: acctPrevOwnerId];
            
            for (Account acctList : oldLst){
                for (User usr : userList){
                    if (acctList.OwnerId == usr.Id){
                        mapEmail.put(acctList.Id, usr.Email); 
                        break;
                    }
                }
            } 
            
            for (Account acctList : newLst ){
                System.debug('### Prior Email:' + mapEmail.get(acctList.id));
                acctList.Hidden_Prior_Account_Manager_Email__c  = mapEmail.get(acctList.id);

            }           
        }       
    }
    
    // Sept 2013: Added for Retail Ops to generate unique Conveyancer Number for conveyancers
    public static void generateConveyancerNumber(List <Account> accConveyancers) {
        // Retrieve the next id from Custom Setting - LOCK for update
        Conveyancer_Number__c [] cn = [SELECT Id, Next_Id__c FROM Conveyancer_Number__c LIMIT 1 FOR UPDATE];
        Double latestNumber = cn[0].Next_Id__c;
        
        if(latestNumber != null) {
            for(Account accCon: accConveyancers) {
                accCon.Conveyancer_Number__c = latestNumber;
                latestNumber = latestNumber + 1;
            }
            // Update the next id in the Custom Setting
            cn[0].Next_Id__c = latestNumber;
            update cn;      
        }
    }
    
    //Ignores out of sync updates from SAP CRM based off Integration_Service_Mod_Date__c
    public static void ignoreOutOfSyncUpdates(Map<Id, Account> newMap, Map<Id, Account> oldMap) {
        for (Account newAcc : newMap.values()) {
            if (newAcc.IsPersonAccount) {
                Account oldAcc = oldMap.get(newAcc.Id);
                if (newAcc.Integration_Service_Mod_Date__c != null &&
                        oldAcc.Integration_Service_Mod_Date__c != null &&
                        newAcc.Integration_Service_Mod_Date__c < oldAcc.Integration_Service_Mod_Date__c) {
                    newAcc.addError('The new Integration_Service_Mod_Date__c is older than the existing value');
                }
            }   
        }       
    }

    
    // ************** Partner Info Methods *****************
    
    // Populate Network Manager on Licence, on submission for approval
    public static void updateNetworkManager(list<Account> accounts, map<id, Account> oldAccounts){

        set<id> facilityIds = new set<id>();
        Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(new Set<String>{'Licence','Licence CMA','Licence CPA'},'Account'));
        Set<Id> licenceRTIds = new Set<Id>(licenceRTs.keySet());
        //id licenseRT = RecordTypes.getRecordTypeByName('Licence', 'Account').id;
        system.debug('+++licenceRTIds+++'+licenceRTIds);
        for(Account account : accounts){
            //if(account.RecordTypeId == licenseRT &&
            if(licenceRTIds.contains(account.RecordTypeId) &&
                (trigger.isInsert || 
                    (account.Approval_Status__c == APPROVAL_STATUS_PENDING && 
                    account.Approval_Status__c != oldAccounts.get(account.id).Approval_Status__c) )){
                facilityIds.add(account.Facility__c);
            }
        }
        facilityIds.remove(null);

        // fetching the facility's netowrk's parent network's Network Manager
        if(facilityIds.size() > 0){
            map<id, Account> facilities = new map<id, Account>([
                                                                    SELECT id, Network_Facility__r.Id ,Network_Facility__r.Parent_Network__r.Network_Manager__c
                                                                    FROM Account
                                                                    WHERE id in: facilityIds
                                                                ]);

            for(Account account : accounts){
                //if(account.RecordTypeId == licenseRT && 
                if(licenceRTIds.contains(account.RecordTypeId) &&
                    account.Facility__c != null &&
                    (trigger.isInsert || 
                        (account.Approval_Status__c == APPROVAL_STATUS_PENDING && 
                        account.Approval_Status__c != oldAccounts.get(account.id).Approval_Status__c) )){
                            Account facility = facilities.get(account.Facility__c);
                            if(facility.Network_Facility__r.Parent_Network__r.Network_Manager__c == null){
                                account.addError(ERROR_NETWORK_MANAGER);
                            }
                            else{
                                account.Network_Manager__c = facility.Network_Facility__r.Parent_Network__r.Network_Manager__c;
                            }
                }
            }
        }

    }
    
    // Check Legal Entity has assocaited Primary Contact
    // Primary Contact should have email address
    // Commeted out 26-04-2016 - Using 'Nominated Partner Contact & Incent User' field as primary contact instead of contact role
    /*
    public static void checkPrimaryContact(List<Account> accounts, map<id, Account> oldAccounts ){
        Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(new Set<String>{'Licence','Licence CMA','Licence CPA','Licence PP'},'Account'));
        Set<Id> licenceRTIds = new Set<Id>(licenceRTs.keySet());
        set<id> legalAccountIds = new set<id>();
        //id licenseRT = RecordTypes.getRecordTypeByName('Licence', 'Account').id;
        for(Account account : accounts){
            if(licenceRTIds.contains(account.RecordTypeId) && trigger.isInsert && account.ParentId<>null ){
                legalAccountIds.add(account.ParentId);
            }
        }  
        
        if(legalAccountIds.size()>0){
            
            map<id, Account> legalEntityList = new map<id, Account>([
                                                                    SELECT id, 
                                                                                (Select isPrimary, contact.email, 
                                                                                contact.accountId
                                                                                from AccountContactRoles
                                                                                where isPrimary = true
                                                                                limit 1)
                                                                    FROM Account
                                                                    WHERE id in: legalAccountIds
                                                                ]); 
            for(Account account : accounts){
                //if(account.RecordTypeId == licenseRT && trigger.isInsert && account.ParentId<>null ){
                if(licenceRTIds.contains(account.RecordTypeId) && trigger.isInsert && account.ParentId<>null ){
                    Account legalEnityAccountObj =  legalEntityList.get(account.parentId);
                    
                    if(legalEnityAccountObj<>null && legalEnityAccountObj.AccountContactRoles.size()>0){
                        if(legalEnityAccountObj.accountcontactroles[0].Contact.accountId<>null &&
                            legalEnityAccountObj.accountcontactroles[0].Contact.accountId<>account.ParentId){
                                account.addError(SPECIFY_CONTACT);
                        }else if(legalEnityAccountObj.accountcontactroles[0].Contact.email==null){
                            account.addError(EMAIL_MISSING);
                        }
                    }else{
                        account.addError(PRIMARY_CONTANCT);
                    }
                }
            }                                                    
        }
    }
    */

 
    // Perform actions on Licence Activation
    // Cease outgoing Licence
    // Mark Organization on Facility as the incoming Licence
    public static void activateLicence(map<id, Account> accounts, map<id, Account> oldAccounts){

        // Incoming Licence gets updated to Approved from a Time Based Workflow.
        // We capture the same Field Update change, and make the Outgoing Licence Ceased
        // and update the Facility's Parent Licence to the Incoming Licence
        Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(new Set<String>{'Licence','Licence CMA','Licence CPA'},'Account'));
        Set<Id> licenceRTIds = new Set<Id>(licenceRTs.keySet());
        //id licenseRT = RecordTypes.getRecordTypeByName('Licence', 'Account').id;
        
        set<id> activatedLicenceIds = new set<id>();
        for(Account acc : accounts.values()){
            if(licenceRTIds.contains(acc.RecordTypeId) && acc.Licence_Status__c == LICENCE_STATUS_ACTIVE &&
                acc.Licence_Status__c != oldAccounts.get(acc.id).Licence_Status__c){

                    activatedLicenceIds.add(acc.id);

            }
        }

        if(activatedLicenceIds.size() > 0){
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
                        accountsToUpdate.get(acc.Facility__r.ParentId).Licence_Status__c = LICENCE_STATUS_CEASED;                   
                        //AJ 30.5.16 Set Outgoing Licence Assignment Effective To Date and Termination Reason
                        accountsToUpdate.get(acc.Facility__r.ParentId).Assignment_Effective_To_Date__c = acc.Assignment_Effective_From_Date__c.addDays(-1);
                        accountsToUpdate.get(acc.Facility__r.ParentId).Termination_Reason__c = TERMINATION_REASON;
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
                update accountsToUpdate.values();
                
                //AJ 30.5.16 Call flow to update outgoing Partner Addenum dates and Renewal Status.
                Map<String, Object> params = new Map<String, Object>();
                params.put('OutgoingLicenceId', sOutgoingLicenceId );
                params.put('StartDate', dtAssignEffFromDate );
                Flow.Interview.Partner_Info_Update_Partner_Addendum_Dates_Outgoing UpdPAfl = new Flow.Interview.Partner_Info_Update_Partner_Addendum_Dates_Outgoing(params);
                UpdPAfl.start();

                String returnValue = (String) UpdPAfl.Error;
                if(returnValue != null){
                     system.debug('The following error occured updating the PAs against outgoing Licence ' + sOutgoingLicenceId + ' Error: ' + returnValue );
                }
                
            }
            catch(DMLException ex){
                System.debug('EX==>'+ex.getMessage());
                for(Id accId : activatedLicenceIds){
                    accounts.get(accId).addError('Unsuccessfull Activation');
                }
            }
        }

    }

    // Verifies Duplicate License Account does not exist
    public static void verifyDuplicateLicence(List<Account> accounts, map<id, Account> oldAccounts ){
        Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(new Set<String>{'Licence','Licence CMA','Licence CPA'},'Account'));
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
                                  AND Licence_Status__c != : LICENCE_STATUS_CEASED
                                  AND Licence_Status__c != : LICENCE_STATUS_NOT_ACTIVATED
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
                                account.addError(ERROR_LICENCE_EXISTS.replace('<status>',acc.Licence_Status__c));
                                errorFound = true;
                                break;
                            }
                            else if(acc.Assignment_Effective_To_Date__c != null && 
                                    LICENCE_ACTIVE_STATUSES.contains(acc.Licence_Status__c) &&
                                    acc.Assignment_Effective_To_Date__c >= account.Assignment_Effective_From_Date__c){
                                         account.addError(ERROR_ACTIVE_LICENCE_EXISTS);
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
                                    account.addError(ERROR_LICENCE_EXISTS.replace('<status>',accToCompare.Licence_Status__c));
                                    break;
                                }
                                else if(accToCompare.Assignment_Effective_To_Date__c != null && 
                                        LICENCE_ACTIVE_STATUSES.contains(accToCompare.Licence_Status__c) &&
                                        accToCompare.Assignment_Effective_To_Date__c >= account.Assignment_Effective_From_Date__c){
                                             account.addError(ERROR_ACTIVE_LICENCE_EXISTS);
                                             break;
                                }
                            }
                            
                        }
                    }
                    
                    i++;
                }
            }
        }
        
    }

    //Prevent setting 'Nominated Partner Contact & Incent User' with email address the same as another 'Nominated Partner Contact & Incent User' with multi facilities (scenario 1)
    public static void checkNominatedContactEmail(List<Account> newList, Map<Id,Account> oldMap){
        
        for(Account a: newList){
            Map<String, Object> params = new Map<String, Object>();
            Account oldAcc = oldMap.get(a.Id);
            if(a.Nominated_Partner_Contact_Incent_User__c != oldAcc.Nominated_Partner_Contact_Incent_User__c && a.Nominated_Partner_Contact_Incent_User__c != null){
                params.put('ContactId', a.Nominated_Partner_Contact_Incent_User__c);
                params.put('LegalEntityId', a.Id);                
                Flow.Interview.Partner_Info_Nominated_Contact_Check fl = new Flow.Interview.Partner_Info_Nominated_Contact_Check(params);
                fl.start(); 

                String returnValue = (String) fl.LegalEntityFoundName;
                if(returnValue != null){
                     a.addError(UNIQUE_EMAIL_ADDRESS.replace('[ORG NAME]', returnValue));
                }
            }
        }
    }
    
    //When updating a Legal Entity or Facility on Licence, trigger the Nominated Partner Contact email check (scenario 2-Upd)
    public static void checkLEUpdate(List<Account> newList, Map<Id,Account> oldMap){
        Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(new Set<String>{'Licence','Licence CMA','Licence CPA','Licence PP'},'Account'));
        for(Account a: newList){
            Map<String, Object> params = new Map<String, Object>();
            Account oldAcc = oldMap.get(a.Id);
            if((a.ParentId != oldAcc.ParentId || a.Facility__c != oldAcc.Facility__c) && licenceRTs.keySet().contains(a.RecordTypeId)){
                params.put('LegalEntityId', a.ParentId); 
                params.put('FacilityId', a.Facility__c);  
                Flow.Interview.Partner_Info_Nominated_Contact_Check fl = new Flow.Interview.Partner_Info_Nominated_Contact_Check(params);
                fl.start(); 
                Boolean leNPCIUSet = (Boolean) fl.LegalEntityNPCIUSet;
                if(leNPCIUSet){
                    String returnValue = (String) fl.LegalEntityFoundName;
                        if(returnValue != null){
                            a.addError(UNIQUE_EMAIL_ADDRESS.replace('[ORG NAME]', returnValue));
                        }  
                }else{
                    a.addError(ERROR_NOMINATED_CONTACT_REQUIRED);
                }
            }
        }
    }
     
    // Prevent insert of Licence if Legal Entity does not have a Primary Contact('Nominated Partner Contact & Incent User')
    // Also prevent insert of Licence if its Legal Entity has a Nominated Partner Contact email used by another LE with different facilities (scenario 2-Ins)
    public static void checkLicenceInsert(List<Account> newList){
        Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(new Set<String>{'Licence','Licence CMA','Licence CPA','Licence PP'},'Account'));
        for(Account a: newList){
            if(licenceRTs.keySet().contains(a.RecordTypeId)){
                Map<String, Object> params = new Map<String, Object>();
                params.put('LegalEntityId', a.ParentId); 
                params.put('FacilityId', a.Facility__c); 
                Flow.Interview.Partner_Info_Nominated_Contact_Check fl = new Flow.Interview.Partner_Info_Nominated_Contact_Check(params);
                fl.start(); 
                Boolean leNPCIUSet = (Boolean) fl.LegalEntityNPCIUSet;
                if(leNPCIUSet){
                    String returnValue = (String) fl.LegalEntityFoundName;
                        if(returnValue != null){
                            a.addError(UNIQUE_EMAIL_ADDRESS.replace('[ORG NAME]', returnValue));
                        }  
                }else{
                    a.addError(ERROR_NOMINATED_CONTACT_REQUIRED);
                }
            }
        }
    }
    
}