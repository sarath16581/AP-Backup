/*------------------------------------------------------------------------------
Author:         Kenny Liew
Company:        Salesforce.com
Description:    A utility class used by the Contact trigger, used for converting
                Leads into Accounts and Contacts specifically for the MyPost
                Business customer segment whereby Accounts and Contacts are
                created prior via SOAP API.
Inputs:         n/a
Test Class:     MyPostBusinessLeadConvert_Test

History
<Date>      <Authors Name>      <Brief Description of Change>
02-JUN-2016 Kenny Liew          Initial creation.
03-AUG-2016 Davey Yu            MPB - Update converLead and convertLeadPersonAccount method
21-OCT-2016 Davey Yu            MPB - Update convertLead and ConvertLeadPersonAccount methods to fix exception 
                                when updating a lead wherein it was added twice in a list.
16-JUN-2018 Disha Kariya        Added check to duplicate only those leads which are created with MPB Campaign member Id
------------------------------------------------------------------------------*/

public class MyPostBusinessLeadConvert {
    
    /*--------------------------------------------------------------------------
    Author:         Kenny Liew
    Company:        Salesforce.com
    Description:    Async method called to perform the following when the
                    ContactTrigger is fired:
                    
                    1)  Target specifically Contacts with
                        MPB_Campaign_Member_Id__c populated.  These are Contacts
                        created via TIBCO for MyPost customer "registration",
                        originating from MyPost Business Small Business
                        Newsletter Sign-ups (MPB_Campaign_Member_Id__c = 
                        Salesforce Id of Campaign Member record).

                    2)  If the Email address against the Lead is the same as
                        the Email address against the Contact, perform all
                        subsequent steps, else skip and process next record.
                        
                    3)  If customer details like First Name, Last Name and
                        Company Name on the Lead record does not match that
                        of the associated Account + Contact, update the Lead
                        record to match.  Values against Account + Contact is
                        taken to be latest and most accurate as it is used
                        for registration.
                        
                    4)  For each Contact record, create an instance of the
                        Database.LeadConvert class to handle its conversion.
                        Set the right values and ddd instance to a collection
                        for bulk conversion in a single call.
                        
                    5)  Check for duplicate leads by Email.  Set status of
                        these to "Duplicate lead" (OOTB value).
                        
                    6)  Call bulk conversion, and log any errors.
                    
                    7)  Set MPB_Campaign_Member_Id__c to prevent re-processing.
                            
    Inputs:         A Set containing all Contact records that were created
    Returns:        n/a
            
    History
    <Date>      <Authors Name>      <Brief Description of Change>
    02-JUN-2016 Kenny Liew          Initial creation.
    03-AUG-2016 Davey Yu            MPB - Update Lead OwnerId to a user when lead is owned by a queue
    --------------------------------------------------------------------------*/
    @future
    public static void convertLead(Set<Id> contactIds) {
        try {
    
            /*** Initialise relevant variables with relevant values used throughout method ***/
            LeadStatus leadConvertedStatus = [SELECT Id,MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
            List<Contact> targetedContacts = [SELECT Id, AccountId, FirstName, LastName, Email, MPB_Campaign_Member_Id__c FROM Contact WHERE Id in :contactIds AND MPB_Campaign_Member_Id__c != null AND MPB_Campaign_Member_Id__c != '' LIMIT 200];
            List<Lead> listofLeadsProcessed = new Lead[0];
            List<Lead> listofLeadsToUpdate = new Lead[0];
            Set<Id> listofProcessedLeadIds = new Set<Id>();
            Set<String> listofLeadEmails = new Set<String>();
            Map<Id, CampaignMember> mapofCampaignMembers = new Map<Id, CampaignMember>();
            List<CampaignMember> listofCampaignMemberToUpdate = new List<CampaignMember>();
            Database.LeadConvert[] listofLeadConvertInstances = new Database.LeadConvert[0];

            /*** START OF UPDATE MPB 02-AUG-2016 DYU - Retrieved Owner Id set from MPB Settings ***/
            MPB_Settings__c mpbSettings = MPB_Settings__c.getOrgDefaults();
            /*** END OF UPDATE MPB 02-AUG-2016 ***/ 


            
            for (Contact contactRec : targetedContacts) {
                
                /*** Get reference to Campaign Member + Lead Id record to be converted. ***/
                CampaignMember currentCampaignMemberRec = [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE Id = :contactRec.MPB_Campaign_Member_Id__c LIMIT 1];
                Lead currentLeadRec = [SELECT Company,Email,FirstName,Id,LastName, owner.type, ownerId FROM Lead WHERE Id = :currentCampaignMemberRec.LeadId LIMIT 1];
                
                /*** Check if email addresses match between Contact and Lead. ***/
                if (currentLeadRec.Email == contactRec.Email) {

                    listofLeadsProcessed.add(currentLeadRec);
                    
                    // START OF UPDATE DY 21.10.2016 MPB - Prevent adding the same lead on list for update
                    Boolean updateLead = false; //10.21.2016 Add new boolean to determine if lead need to be updated

                    /*** Update Lead record with details from Account + Contact (coming via TIBCO) in case details were updated at the public-facing Auspost MPB registration page itself. ***/
                    Account currentAccountRec = [SELECT Id, Name FROM Account WHERE Id = :contactRec.AccountId LIMIT 1];
                    if (currentAccountRec.Name != currentLeadRec.Company || contactRec.FirstName != currentLeadRec.FirstName || contactRec.LastName != currentLeadRec.LastName) {
                        currentLeadRec.Company = currentAccountRec.Name;
                        currentLeadRec.FirstName = contactRec.FirstName;
                        currentLeadRec.LastName = contactRec.LastName;
                        //listofLeadsToUpdate.add(currentLeadRec);  // 21.10.2016 remove to avoid duplicate ids
                        updateLead = true; // 21.10.2016 set variable to true
                    }

                    /*** START OF UPDATE MPB 02-AUG-2016 DYU - Assign lead owner from a queue to a user ***/
                    if(currentLeadRec.Owner.Type == 'Queue'){
                        currentLeadRec.OwnerId = mpbSettings.MPB_Lead_Owner__c;
                        //listofLeadsToUpdate.add(currentLeadRec);  // 21.10.2016 remove to avoid duplicate ids
                        updateLead = true; // 21.10.2016 set variable to true
                    }
                    
                    if(updateLead){ //21.10.2106 validate if leads need to be updated
                        listofLeadsToUpdate.add(currentLeadRec); 
                        updateLead = false; // 21.10.2016 refresh boolean
                    }
                    
                    /*** START OF UPDATE MPB 02-AUG-2016 ***/

                    /*** Create instance of LeadConvert class for each Contact  / Lead to be converted. Attached to list / array. ***/
                    Database.LeadConvert leadConvertInstance = new Database.LeadConvert();
                    leadConvertInstance.setDoNotCreateOpportunity(true);
                    leadConvertInstance.setLeadId(currentCampaignMemberRec.LeadId);
                    leadConvertInstance.setAccountId(contactRec.AccountId);
                    leadConvertInstance.setContactId(contactRec.Id);
                    leadConvertInstance.setConvertedStatus(leadConvertedStatus.MasterLabel);
                    listofLeadConvertInstances.add(leadConvertInstance);

                    /*** Set lists up for duplicate Lead treatment outside of loop. ***/
                    listofProcessedLeadIds.add(currentLeadRec.Id);
                    listofLeadEmails.add(contactRec.Email);

                    /*** Set Map up for Campaign Member Status update outside of loop. ***/
                    mapofCampaignMembers.put(currentLeadRec.Id, currentCampaignMemberRec);

                } else {
                    // check what are the requirements in terms of handling this business scenario...
                    continue;
                }

                /*** Reset MPB_Campaign_Member_Id__c to null to prevent any future conversion. ***/
                contactRec.MPB_Campaign_Member_Id__c = null;

            }

            /*** Update Lead record with details from Account + Contact (coming via TIBCO) in case details were updated at the public-facing Auspost MPB registration page itself. ***/
            if(listofLeadsToUpdate.size() >0)   //21.10.2016 validate if list is not empty
                update listofLeadsToUpdate;     //  this updates all Leads with differing First Names and Last Names to match created Account + Contact
            //END OF UPDATE DY 21.10.2016 MPB - Prevent adding the same lead on list for update

            /*** Actual execution of LeadConvert, all at once. ***/
            Database.LeadConvertResult[] listofLeadConvertResults = Database.convertLead(listofLeadConvertInstances, false);

            /*** For successful Lead Convesion, update Campaign Member record. ***/
            for(integer i=0; i < listofLeadConvertResults.size(); ++i) {
                Database.LeadConvertResult currentResultRec = listofLeadConvertResults[i];
                if (currentResultRec.isSuccess()) {
                    CampaignMember campaignMemberRecToUpdate = mapofCampaignMembers.get(currentResultRec.getLeadId());
                    campaignMemberRecToUpdate.Status = 'Responded';
                    listofCampaignMemberToUpdate.add(campaignMemberRecToUpdate);
                }
            }
            update listofCampaignMemberToUpdate;

            /*** Call common error handling framework for post lead conversion processing. ***/
            UTIL_LoggingService.LogConvertLeadResult(listofLeadConvertResults, listofLeadsProcessed, SSSWConstants.SSSW_APP, 
                MyPostBusinessLeadConvert.class.getName(), SSSWConstants.METH_CONVERT_LEAD, 
                SSSWConstants.CONTACT_TRIGGER, LoggingLevel.ERROR);     

            update targetedContacts;

            /*** Now find all duplicate Leads with the same email address and mark them as duplicates. ***/
            // Added check to duplicate only those leads which are created with MPB Campaign member Id
            List<Lead> duplicateLeadRecs = [SELECT Id,Email,Status,MPB_Campaign_Member_Id__c FROM Lead WHERE Email in :listofLeadEmails AND Id NOT IN :listofProcessedLeadIds AND MPB_Campaign_Member_Id__c!='' AND MPB_Campaign_Member_Id__c!=null]; 
            System.debug('duplicateLeadRecs--->'+duplicateLeadRecs);
            for (Lead currentLeadRec : duplicateLeadRecs) {
                currentLeadRec.Status = 'Duplicate lead';
            }
            update duplicateLeadRecs;

        } catch(Exception e) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                    MyPostBusinessLeadConvert.class.getName(), SSSWConstants.METH_CONVERT_LEAD, 
                                                    SSSWConstants.CONTACT_TRIGGER, LoggingLevel.ERROR);         
        }

    }


    /*--------------------------------------------------------------------------
    Author:         Kenny Liew
    Company:        Salesforce.com
    Description:    Async method called to perform the following when the
                    ContactTrigger is fired:
                    
                    1)  Target specifically Person Accounts with
                        MPB_Campaign_Member_Id__c populated.  These are 
                        created via TIBCO for MyPost customer "registration",
                        originating from MyPost Business Small Business
                        Newsletter Sign-ups (MPB_Campaign_Member_Id__c = 
                        Salesforce Id of Campaign Member record).

                    2)  If the Email address against the Lead is the same as
                        the Email address against the Person Account, perform all
                        subsequent steps, else skip and process next record.
                        
                    3)  If customer details like First Name and Last Name
                        on the Lead record does not match that
                        of the associated Person Account, update the Lead
                        record to match.  Values against Person Account is
                        taken to be latest and most accurate as it is used
                        for registration.
                        
                    4)  For each Person Account record, create an instance of the
                        Database.LeadConvert class to handle its conversion.
                        Set the right values and ddd instance to a collection
                        for bulk conversion in a single call.
                        
                    5)  Check for duplicate leads by Email.  Set status of
                        these to "Duplicate lead" (OOTB value).
                        
                    6)  Call bulk conversion, and log any errors.
                    
                    7)  Set MPB_Campaign_Member_Id__c to prevent re-processing.
                            
    Inputs:         A Set containing all Person Account Ids that were created
    Returns:        n/a
            
    History
    <Date>      <Authors Name>      <Brief Description of Change>
    02-JUN-2016 Kenny Liew          Initial creation.
    03-AUG-2016 Davey Yu            MPB - Update Lead OwnerId to a user when lead is owned by a queue
    --------------------------------------------------------------------------*/
    @future
    public static void convertLeadPersonAccount(Set<Id> accountIds) {

        try {

            LeadStatus leadConvertedStatus = [SELECT Id,MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
            List<Lead> listofLeadsProcessed = new Lead[0];
            List<Lead> listofLeadsToUpdate = new Lead[0];
            Set<Id> listofProcessedLeadIds = new Set<Id>();
            Set<String> listofLeadEmails = new Set<String>();
            Map<Id, CampaignMember> mapofCampaignMembers = new Map<Id, CampaignMember>();
            List<CampaignMember> listofCampaignMemberToUpdate = new List<CampaignMember>();
            Database.LeadConvert[] listofLeadConvertInstances = new Database.LeadConvert[0];
            List<Account> listofTargetedAccounts = [SELECT FirstName, LastName, PersonContactId, PersonEmail, MPB_Campaign_Member_Id__pc FROM Account WHERE Id in :accountIds LIMIT 200];

            /*** START OF UPDATE MPB 02-AUG-2016 DYU - Retrieved Owner Id set from MPB Settings ***/
            MPB_Settings__c mpbSettings = MPB_Settings__c.getOrgDefaults();
            /*** END OF UPDATE MPB 02-AUG-2016 ***/         
            
            for (Account accountRec : listofTargetedAccounts) {

                /*** Get reference to Campaign Member + Lead Id record to be converted. ***/
                CampaignMember currentCampaignMemberRec = [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE Id = :accountRec.MPB_Campaign_Member_Id__pc LIMIT 1];
                Lead currentLeadRec = [SELECT Company,Email,FirstName,Id,LastName, owner.type, ownerId FROM Lead WHERE Id = :currentCampaignMemberRec.LeadId LIMIT 1];

                /*** Check if email addresses match between Person Account and Lead. ***/
                if (currentLeadRec.Email == accountRec.PersonEmail) {
                  
                    // START OF UPDATE DY 21.10.2016 MPB - Prevent adding the same lead on list for update
                    Boolean updateLead = false; //10.21.2016 Add new boolean to determine if lead need to be updated
                    
                    /*** Check differing names between Lead and Person Account, setup for single DML update outside of loop. ***/
                    if (accountRec.FirstName != currentLeadRec.FirstName || accountRec.LastName != currentLeadRec.LastName) {
                        currentLeadRec.FirstName = accountRec.FirstName;
                        currentLeadRec.LastName = accountRec.LastName;
                        //listofLeadsToUpdate.add(currentLeadRec); // 21.10.2016 remove to avoid duplicate ids
                        updateLead = true; // 21.10.2016 set variable to true
                    }
                    
                    /*** START OF UPDATE MPB 02-AUG-2016 DYU - Assign lead owner from a queue to a user ***/
                    if(currentLeadRec.Owner.Type == 'Queue'){
                        currentLeadRec.OwnerId = mpbSettings.MPB_Lead_Owner__c;
                        //listofLeadsToUpdate.add(currentLeadRec); // 21.10.2016 remove to avoid duplicate ids
                        updateLead = true; // 21.10.2016 set variable to true
                    } 
                  
                    if(updateLead){ //21.10.2106 validate if leads need to be udpated
                        listofLeadsToUpdate.add(currentLeadRec); 
                        updateLead = false; // 21.10.2016 refresh boolean
                    }
                    /*** START OF UPDATE MPB 02-AUG-2016 ***/

                    listofLeadsProcessed.add(currentLeadRec);

                    /*** Create instance of LeadConvert class for each Contact  / Lead to be converted. Attached to list / array. ***/
                    Database.LeadConvert leadConvertInstance = new Database.LeadConvert();
                    leadConvertInstance.setDoNotCreateOpportunity(true);
                    leadConvertInstance.setLeadId(currentLeadRec.Id);
                    leadConvertInstance.setAccountId(accountRec.Id);
                    leadConvertInstance.setContactId(accountRec.PersonContactId);
                    leadConvertInstance.setConvertedStatus(leadConvertedStatus.MasterLabel);
                    listofLeadConvertInstances.add(leadConvertInstance);

                    /*** Set Map up for Campaign Member Status update outside of loop. ***/
                    mapofCampaignMembers.put(currentLeadRec.Id, currentCampaignMemberRec);

                    /*** Set lists up for duplicate Lead treatment outside of loop. ***/
                    listofProcessedLeadIds.add(currentLeadRec.Id);
                    listofLeadEmails.add(accountRec.PersonEmail);
                    
                } else {
                    // check what are the requirements in terms of handling this business scenario...
                    continue;
                }

                /*** Reset MPB_Campaign_Member_Id__c to null to prevent any future conversion. ***/
                accountRec.MPB_Campaign_Member_Id__pc = null;

            }

            /*** Update Lead record with details from Person Account (coming via TIBCO) in case details were updated at the public-facing Auspost MPB registration page itself. ***/
            if(listofLeadsToUpdate.size() >0) //21.10.2016 validate if list is not empty
                update listofLeadsToUpdate;     //  this updates all Leads with differing First Names and Last Names to match created Person Account
            // END OF UPDATE DY 21.10.2016 MPB - Prevent adding the same lead on list for update
            
            
            /*** Actual execution of LeadConvert, all at once. ***/
            Database.LeadConvertResult[] listofLeadConvertResults = Database.convertLead(listofLeadConvertInstances, false);

            /*** For successful Lead Convesion, update Campaign Member record. ***/
            for(integer i=0; i < listofLeadConvertResults.size(); ++i) {
                Database.LeadConvertResult currentResultRec = listofLeadConvertResults[i];
                if (currentResultRec.isSuccess()) {
                    CampaignMember campaignMemberRecToUpdate = mapofCampaignMembers.get(currentResultRec.getLeadId());
                    campaignMemberRecToUpdate.Status = 'Responded';
                    listofCampaignMemberToUpdate.add(campaignMemberRecToUpdate);
                }
            }
            update listofCampaignMemberToUpdate;

            /*** Call common error handling framework for post lead conversion processing. ***/
            UTIL_LoggingService.LogConvertLeadResult(listofLeadConvertResults, listofLeadsProcessed, SSSWConstants.SSSW_APP, 
                MyPostBusinessLeadConvert.class.getName(), SSSWConstants.METH_CONVERT_LEAD_PC, 
                SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);     

            update listofTargetedAccounts;  //  this sets all MPB_Campaign_Member_Id__pc to NULL after Lead Conversion

            /*** Now find all duplicate Leads with the same email address and mark them as duplicates. ***/
            // Added check to duplicate only those leads which are created with MPB Campaign member Id
            List<Lead> duplicateLeadRecs = [SELECT Id,Email,Status,MPB_Campaign_Member_Id__c FROM Lead WHERE Email in :listofLeadEmails AND Id NOT IN :listofProcessedLeadIds AND MPB_Campaign_Member_Id__c!='' AND MPB_Campaign_Member_Id__c!=null]; 
            System.debug('duplicateLeadRecs--->'+duplicateLeadRecs);
            for (Lead currentLeadRec : duplicateLeadRecs) {
                currentLeadRec.Status = 'Duplicate lead';
            }
            update duplicateLeadRecs;

        } catch (Exception e) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                    MyPostBusinessLeadConvert.class.getName(), SSSWConstants.METH_CONVERT_LEAD_PC, 
                                                    SSSWConstants.ACCOUNT_TRIGGER, LoggingLevel.ERROR);         
        }
    }
}