/**************************************************
Type:       Controller Extension for Lead Convert page
Purpose:    To handle custom Lead Conversion logic due to AusPost decision to not use Contacts             
History:
--------------------------------------------------
              Richard Enojas(Salesforce.com)    Created
05.12.2011    Richard Enojas(Salesforce.com)    Updated to associate Activities across from Lead to BA/PA and Opportunity(if exists)
18.06.2012    Richard Enojas(Salesforce.com)    Phase 2 changes - Added validation for Status, Opportunity Initial Estimate, PostalCode.
31.07.2012    Richard Enojas(Salesforce.com)    Updated test scenarios based on changes in Phase 2. Moved to separate class.
15.08.2012    Richard Enojas(Salesforce.com)    Set Opportunity Type to New/Existing Customer upon creation. 
06.02.3013    Richard Clarke (Post)             Extend to copy attachments across as was done previously with tasks
07.01.2014    Louis Wang (Bluewolf)				Removed concept of Partner / Individual, such that standard Account-Contact is reestablished
												Added new scenario such that BA is always mandatory. Conversion will stop if BA is not available.  
11.04.2019    Ronnie Yang(Soda)                 Prioritise using duplicate rules to find matching contacts/orgs when applicable
30.09.2021    Seth Heang                        Uplift SF API Version to 52
**************************************************/
public class LeadConvertExCon {
    private ApexPages.StandardController stdCon;
    private Id LeadId;
    private Lead lead;
        
    public LeadConvertExCon(ApexPages.StandardController controller) {
        stdCon = controller;
        lead = (Lead) stdCon.getRecord();
        LeadId = stdCon.getRecord().Id;
    }
    
    public Lead leadrec {
        get {
            if(leadrec == null){leadrec = [SELECT FirstName, LastName, Company, ConvertedAccountId, ConvertedContactId, Owner.Type,
                                           ConvertedOpportunityId, Name, ABN__c, DPID__c, Email, Website, Title,
                                           Opportunity_Initial_Estimate__c, Status, PostalCode, Product__c, RecordtypeId, Phone, MobilePhone
                                           FROM Lead WHERE Id = :LeadId];}
            return leadrec;
        }set;
    } 
    
    private List<Contact> contactList {
        get{       
            if(contactList == null){
                Contact c = new Contact(FirstName = leadrec.FirstName, LastName = leadrec.LastName, Email = leadrec.Email, Phone = leadrec.Phone, 
                                        MobilePhone = leadrec.MobilePhone);
                Set<Id> contactIds = new Set<id>();
                List<DuplicateRule> activeRules = [SELECT Id FROM DuplicateRule Where SobjectType = 'Contact' AND (SobjectSubtype = '' OR SobjectSubType = 'None') AND IsActive = true];
                System.debug('##Active Contact Duplicate Rules Found: ' + activeRules);
                
                //If there're duplicate rules available for contacts then include results found via duplciate rules
                if(!activeRules.isEmpty()){
                    for (Datacloud.FindDuplicatesResult findDupeResult : Datacloud.FindDuplicates.findDuplicates(new List<Contact>{c})){
                        for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                            for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                                for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                                    System.debug('Duplicate Record: ' + matchRecord.getRecord());
                                    contactIds.add(matchRecord.getRecord().Id);
                                }
                            }
                        }
                    }
                }
                //We retain the orignal matching logic which is by the first name and last name (including all results found via duplicate rules)
                contactList = [SELECT Id, FirstName, LastName, Email, MobilePhone, Name, IsPersonAccount, Account.Name, AccountId,
                               // Updated by Adrian Recio
                               // Description: 5 columns added as part of leadconvert improvement minor works
                               // 9/10/2017
                               Salutation, Title, Status__c, Record_Maintainer__c, Phone
                               FROM Contact 
                               WHERE  IsPersonAccount = false
                               AND (Id IN: contactIds OR (FirstName = :leadrec.FirstName AND LastName = :leadrec.LastName))];
            }
            System.debug('contactList is ' + contactList);
            return contactList;
        }set;
    }
    
    public Boolean contactFound {
        get{
            if (contactFound == null){
                if (contactList.isEmpty()) {
                    contactFound = false;
                }
            }       
            return contactFound;
        }set;
    }
    
    public List<cContact> matchingContacts{
        get{
            if (matchingContacts == null) {
                matchingContacts = new List<cContact>();
                for(Contact cont : contactList){
                    cContact record = new cContact(cont);
                    matchingContacts.add(record);
                }
            }
            return matchingContacts;
        }set;
    }
    
    private List<Account> BAcctList {
        get{
            if(BAcctList == null){
                Account a = new Account(Name = leadrec.Company, ABN__c = leadrec.ABN__c);
                Set<Id> accountIds = new Set<Id>();
                List<DuplicateRule> activeRules = [SELECT Id FROM DuplicateRule Where SobjectType = 'Account' AND (SobjectSubtype = '' OR SobjectSubType = 'None') AND IsActive = true];
                System.debug('##Active Account Duplicate Rules Found: ' + activeRules);
				
                //If there're duplicate rules available for accounts then include results found via duplciate rules
                if(!activeRules.isEmpty()){
                    for (Datacloud.FindDuplicatesResult findDupeResult : Datacloud.FindDuplicates.findDuplicates(new List<Account>{a})){
                        for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                            for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                                for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                                    System.debug('Duplicate Record: ' + matchRecord.getRecord());
                                    accountIds.add(matchRecord.getRecord().Id);
                                }
                            }
                        }
                    }
                }
                //We retain the orignal matching logic which is by ABN or company name (including all results found via duplicate rules)
                BAcctList = [SELECT Id, IsPersonAccount, Name, Email__c, Website, Phone, ABN__c, ACN__c,Organisation_Trading_Name__c, 
                             // Updated by Adrian Recio
                             // Description: 4 columns added as part of leadconvert improvement minor works
                             // 9/10/2017
                             Role_Type_Roll_Up__c, Customer_Number__c,Owner.Name, Sales_Segment__c
                             FROM Account 
                             WHERE IsPersonAccount = false
                             AND (Id IN: accountIds OR Name = :leadrec.Company OR ABN__c = :leadrec.ABN__c)
                             LIMIT 10];
            }
            System.debug('Account List is ' + contactList);
            return BAcctList;
        }set;
    }
    
    public Boolean BAfound {
        get{
            if (BAcctList.isEmpty()){BAfound = false;}       
            return BAfound;
        }set;
    }
    
    public List<cAccount> matchingBAccts{
        get{
            if (matchingBAccts == null) {
                matchingBAccts = new List<cAccount>();
                for(Account acct : BAcctList){
                    cAccount record = new cAccount(acct);
                    matchingBAccts.add(record);
                }
            }
            return matchingBAccts;
        }set;
    }
    
    public ID contactId { get; set; }
    public ID BAcctId { get; set; }
    
    public Boolean withCompany{
        get{
            if (leadrec.Company == null) withCompany = false;
                else withCompany = true;
            return withCompany;
        }set;
    }
    
    public Boolean sendEmail{
        get{
            if(sendEmail == null){
                if (LeadSettings__c.getInstance().SendEmail__c) sendEmail = true;
            }           
            return sendEmail;   
        }set;
    }
    
    public Boolean createInd {
        get{
            if(createInd == null){
                if(contactList.size()!=0) createInd = false;
                else createInd = true;
            }
            return createInd;
        }set;    
    }
    
    public Boolean createOrg{
        get{
            if(createOrg == null){
                if(BAcctList.size()!=0) createOrg = false;
                else createOrg = true;
            }           
            return createOrg;   
        }set;
    }
    
    public Boolean donotcreateOpp{
        get{
            if(donotcreateOpp == null){donotcreateOpp = false;}           
            return donotcreateOpp;   
        }set;
    }
    
    public String OppName{ 
        get{
            if(OppName == null){
                if(leadrec.Company == null) OppName = leadrec.Name + ' - ';
                else OppName = leadrec.Company + ' - ';}
            return OppName;
        }set; 
    }
  
    public PageReference convertLead(){
            
        system.debug('here we go!!!');
        //system.debug(leadrec.Owner.Type);
        
        Id finalAccId = null;
        Id finalConId = null;
        Id newOppId = null;
        String finalURL = null;
        Boolean IsValid = true;
        Id contact_AccountId = null;
                
        //retrieve all tasks and events
        List<Task> leadTasks = [SELECT WhatId, AccountId FROM Task WHERE WhoId=:LeadId];
        List<Event> leadEvents = [SELECT WhatId, AccountId FROM Event WHERE WhoId=:LeadId];
        List<Attachment> leadAttachments = [SELECT Id, Body, BodyLength, ContentType, Description, Name, IsPrivate FROM Attachment WHERE ParentId=:LeadId and IsDeleted=false];
		List<Note> leadNotes = [Select Title, ParentId, OwnerId, Body From Note WHERE ParentId=:LeadId and IsDeleted=false];

        //validate Lead
        if (!withCompany){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 
                                'This lead is missing the Organisation. Please enter a valid Organisation.');
            ApexPages.addMessage(myMsg);
            IsValid = false;
        }
        if (leadrec.PostalCode==null || leadrec.PostalCode==''){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 
                                'This lead is missing the post code. Please enter a valid Post Code.');
            ApexPages.addMessage(myMsg);
            IsValid = false;
        }
        if (leadrec.Status=='Disqualified'){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 
                                'This lead is disqualified and is not a valid lead. Please check the status of the lead before converting.');
            ApexPages.addMessage(myMsg);                    
            IsValid = false;
        }
        if (leadrec.Opportunity_Initial_Estimate__c==null && !donotcreateopp){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 
                                'Please enter Opportunity Initial Estimate before converting lead.');
            ApexPages.addMessage(myMsg);
            IsValid = false; 
        }
        
        // Added by Adrian Recio
        // Contains Conveyancer Onboarding recordtype of Lead Object
        Id conOnboarding = null;
        try{
        	conOnboarding = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Conveyancer Onboarding').getRecordTypeId();
        }catch(Exception e){
            system.debug('Recordtype Exception:' + e);
        }
        
        // Product validation added by Adrian Recio 
        // This will make sure product is required before converting
        // Part of Lead Minor works
        if(leadrec.Product__c == null && leadrec.RecordTypeId != conOnboarding && 
           (donotcreateOpp==false || donotcreateOpp==null)){ // Updated to include do not create opportunity condition in the validation
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 
                                'Please select a product before lead convert.');
            ApexPages.addMessage(myMsg);
            IsValid = false;
        }
        if (!IsValid) return null;
        
        if (!createInd){
            for (cContact ci : matchingContacts){
                if (ci.selected){
                    system.debug('found!'); 
                    contactId = ci.ccont.Id;
                    contact_AccountId = ci.ccont.AccountId;
                    break;
                }
            }
            system.debug('*****USE EXISTING INDIVIDUAL*****');
            system.debug(contactId);
            if (contactId == null){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please choose an existing record.');
                ApexPages.addMessage(myMsg);
                return null;
            }
        }
        
        if (!createOrg){
            for (cAccount co : matchingBAccts){
                if (co.selected){ 
                    BAcctId = co.cacct.Id;
                    break;
                }
            }
            system.debug('*****USE EXISTING ORGANISATION*****');
            if (BAcctId == null){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please choose an existing record.');
                ApexPages.addMessage(myMsg);
                return null;
            }
        }

		if(!createOrg && !createInd && contactId != null && BAcctId != null)
		{
			system.debug('xxx BAcctId / contactId / contact_AccountId = ' + BAcctId + ' / ' + contactId + ' / ' + contact_AccountId);
			// check if selected Contact already link to the selected Organisation
			if(contact_AccountId != BAcctId)
			{
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'The selected Contact does not belong to the selected Organisation. Please review the Contact record and try again.');
                ApexPages.addMessage(myMsg);
                system.debug('xxx myMsg = ' + myMsg);
                return null;				
			}
		}
		else if(createOrg && !createInd && contactId != null)
		{
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'The selected Contact cannot be linked to a new Organisation through Lead Conversion. ');
                ApexPages.addMessage(myMsg);
				system.debug('xxx myMsg2 = ' + myMsg);
                return null;			
		}
        system.debug('xxx createInd / createOrg / withCompany = ' + createInd + ' / ' + createOrg + ' / ' + withCompany);
        
        //scenario 1: new Contact and new BA        
        if (createInd && createOrg && withCompany){

                //create BA and Contact
                finalAccId = convertLead(LeadId, contactId, BAcctId, donotcreateOpp, OppName, sendEmail, 'create', 'create');
                if (finalAccId!=null){
                    Lead convertedLead = [SELECT ConvertedContactId, ConvertedOpportunityId FROM Lead WHERE Id=:LeadId limit 1];
                    finalConId = convertedLead.ConvertedContactId;
                    newOppId = convertedLead.ConvertedOpportunityId;
                    system.debug('****newOppId***' + newOppId);
                                                                                
                    if (newOppId!=null){
                        Opportunity newOpp = [SELECT Id, KeyContact__c FROM Opportunity WHERE Id=:newOppId];
                        newOpp.KeyContact__c = finalConId;
                        newOpp.Type = 'New Customer';
                        update newOpp;
                    }
                }
            
        }

/*        
        //scenario 2: existing Contact and new BA
		//				will never reach this scenario, as validation should already fired.
		//				the code is left here in case this behavior need to retain as per business decision.
        else if (!createInd && createOrg && withCompany){
            
                //create BA and update Contact
                finalAccId = convertLead(LeadId, contactId, BAcctId, donotcreateOpp, OppName, sendEmail, 'create', 'merge');
                if (finalAccId!=null){
                    Lead convertedLead = [SELECT ConvertedContactId, ConvertedOpportunityId FROM Lead WHERE Id=:LeadId limit 1];
                    finalConId = convertedLead.ConvertedContactId;
                    newOppId = convertedLead.ConvertedOpportunityId;
                    system.debug('****newOppId***' + newOppId);
                                                                                
                    if (newOppId!=null){
                        Opportunity newOpp = [SELECT Id, KeyContact__c FROM Opportunity WHERE Id=:newOppId];
                        newOpp.KeyContact__c = finalConId;
                        newOpp.Type = 'New Customer';
                        update newOpp;
                    }
                }
        }
  */      
        //scenario 3: new Contact and existing BA
        else if (createInd && !createOrg && withCompany){

                //update BA and create Contact
                finalAccId = convertLead(LeadId, contactId, BAcctId, donotcreateOpp, OppName, sendEmail, 'merge', 'create');
                if (finalAccId!=null){
                    // Updated by Adrian Recio, added product update
                    Lead convertedLead = [SELECT ConvertedContactId, ConvertedOpportunityId, Product__c FROM Lead WHERE Id=:LeadId limit 1];
                    finalConId = convertedLead.ConvertedContactId;
                    newOppId = convertedLead.ConvertedOpportunityId;
                    system.debug('****newOppId***' + newOppId);
                                                                                
                    if (newOppId!=null){
                        Opportunity newOpp = [SELECT Id, KeyContact__c, Product__c FROM Opportunity WHERE Id=:newOppId];
                        newOpp.Product__c = convertedLead.Product__c;
                        newOpp.KeyContact__c = finalConId;
                        newOpp.Type = 'Existing Customer';
                        update newOpp;
                    }
                }
        }
        
        //scenario 4: existing Contact and existing BA
        else if (!createInd && !createOrg && withCompany){

                //update BA and update Contact
                finalAccId = convertLead(LeadId, contactId, BAcctId, donotcreateOpp, OppName, sendEmail, 'merge', 'merge');
                if (finalAccId!=null){
                    // Updated by Adrian Recio, added product update
                    Lead convertedLead = [SELECT ConvertedContactId, ConvertedOpportunityId, Product__c FROM Lead WHERE Id=:LeadId limit 1];
                    finalConId = convertedLead.ConvertedContactId;
                    newOppId = convertedLead.ConvertedOpportunityId;
                    system.debug('****newOppId***' + newOppId);
                                                                                
                    if (newOppId!=null){
                        Opportunity newOpp = [SELECT Id, KeyContact__c, Product__c FROM Opportunity WHERE Id=:newOppId];
                        newOpp.Product__c = convertedLead.Product__c;
                        newOpp.KeyContact__c = finalConId;
                        newOpp.Type = 'Existing Customer';
                        update newOpp;
                    }
                }
        }
        
        //scenario 5: new Contact only
        //scenario 6: existing Contact only
        // LW 07.01.2014 - Removed the code for scenario 5 and 6, as due to the new business rule, Organisation is now always mandatory.
        
        if (finalAccId!=null){
            
            List<Task> TasksToUpdate = new List<Task>();
            List<Event> EventsToUpdate = new List<Event>();
            List<Attachment> AttachmentsToInsert = new List<Attachment>();
            List<Note> NotesToInsert = new List<Note>();
                        
            for (Task myTask : leadTasks){
                myTask.WhatId = finalAccId;
                if (newOppId!=null) myTask.WhatId = newOppId;
                if (finalConId!=null) myTask.WhoId = finalConId;
                TasksToUpdate.add(myTask);  
            }
            
            for (Event myEvent : leadEvents){
                myEvent.WhatId = finalAccId;
                if (newOppId!=null) myEvent.WhatId = newOppId;
                if (finalConId!=null) myEvent.WhoId = finalConId;
                EventsToUpdate.add(myEvent);
            }
            
            for (Attachment myAttachment : leadAttachments ){ // Attachments are cloned to the organisation or opportunity if latter exists
                Attachment attach = new Attachment();
                attach.Body = myAttachment.Body;
                attach.Name = myAttachment.Name;
                attach.IsPrivate = myAttachment.IsPrivate;
                attach.Description = myAttachment.Description;
                attach.ParentId = finalAccId;
                if (newOppId!=null) attach.ParentId = newOppId;
                AttachmentsToInsert.add(attach);  
            }
            
            for (Note myNote : leadNotes ){ // Attachments are cloned to the organisation or opportunity if latter exists
                Note note = new Note();
                note.Title = myNote.Title;
                note.ParentId = finalAccId;
				note.OwnerId = myNote.OwnerId;
				note.Body = myNote.Body;
                if (newOppId!=null) note.ParentId = newOppId;
                NotesToInsert.add(note);  
            }            

            //update tasks and events and attachments
            update TasksToUpdate;
            update EventsToUpdate;
            insert AttachmentsToInsert;
            insert NotesToInsert;
            
            //redirect to new BA/PA record
            finalURL = '/' + finalAccId; 
            PageReference AcctPage = new PageReference(finalURL);
            AcctPage.setRedirect(true);
            return AcctPage;
        } else return null;
    
    }
    
    //wrapper
    public class cAccount {
        public Account cacct {get; set;}
        public Boolean selected {get; set;}
        public cAccount(Account acct) {
            cacct = acct;
            selected = false;
        }
    }

    public class cContact {
        public Contact ccont {get; set;}
        public Boolean selected {get; set;}
        public cContact(Contact cont) {
            ccont = cont;
            selected = false;
        }
    }

	// LW 07.01.2014 - removed public Lead cloneLead(id leadId)
	//					as no longer required to use (no more Person Account for Lead Conversion!)
    
    public Id convertLead (Id LeadId, Id contactId, Id BAcctId, Boolean donotcreateOpp, String OppName, Boolean sendEmail, String accountAction, String contactAction){
        
        //initiate lead conversion
        Database.Leadconvert lc = new Database.Leadconvert();
        lc.setLeadId(LeadId);
        lc.setSendNotificationEmail(sendEmail);
        lc.setDoNotCreateOpportunity(donotcreateOpp);
    
        //set account
        if (accountAction == 'merge'){
            if (BAcctId!=null) lc.setAccountId(BAcctId);  
			system.debug('xxx BAcctId = ' + BAcctId);
        }
        //else if both null, don't incl setAccountId
        
        //set contact
        if(contactAction == 'merge'){
        	if(contactId!=null) lc.setContactId(contactId);
        	system.debug('xxx contactId = ' + contactId);
        }
		system.debug('xxx lc.getAccountId() = ' + lc.getAccountId());
		system.debug('xxx lc.getContactId() = ' + lc.getContactId());
    
        //opportunity   
        if (!donotcreateOpp && OppName!=null) lc.setOpportunityName(OppName);
		system.debug('xxx donotcreatOpp = ' + donotcreateOpp);
		system.debug('xxx OppName = ' + OppName);
    
        LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        Database.Leadconvertresult lcr;
        
        //MW0003155 ronnie.yang@auspost.com.au Bypassing duplicate rules so convertlead can still save on warning
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        
        try{
            lcr = Database.convertLead(lc, dml);
        }catch (Exception e){
            ApexPages.addMessages(e);
            system.debug('xxx e = ' + e);
            return null;
        }
        if(!lcr.isSuccess()){
            for(Database.Error err : lcr.getErrors()){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, err.getMessage()));
            }
        }
        
        system.debug('xxx lcr.getAccountId() = ' + lcr.getAccountId());
        system.debug('xxx lcr.getContactId() = ' + lcr.getContactId());
        
        return lcr.getAccountId();   
    }
    
    // LW 07.01.2014 - due to structural change above, the original "commented out" Test Class below is no longer valid / relevant.
    //					They are deleted to avoid future confusion. 
}