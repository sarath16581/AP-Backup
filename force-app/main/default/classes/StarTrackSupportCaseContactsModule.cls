/**
 * Domain Modules should NEVER be called directly. Domain modules should only ever be called from a domain class
 *
 * This has been a port of parts of the StarTrack Case Automation process builder. It deals with the following nodes:
 * 1. Create Initial Caller - Updates Initial Caller Details on the case and Creates authorised contact
 * 2. StarTrack New Email-to-Case - Creates Authorised contact and  Updates Initial Caller Details on the case
 * 3. Assign consignment - Updates Authorised contact if they are present, Otherwise creates the authorised contact.
 * 
 * @author Snehil Jaiswal
 * @date 2021-06-22
 * @channel Domain
 * @domain StarTrack
 * @changelog
 * 2023-06-14 - Nathan Franklin - uplift to domainless architecture
 */

public inherited sharing class StarTrackSupportCaseContactsModule extends ApplicationModule {

	/**
	 * @deprecated
	 */
    public static StarTrackSupportCaseContactsModule newInstance() {
        return (StarTrackSupportCaseContactsModule) Application.Utilities.newInstance(
            StarTrackSupportCaseContactsModule.class
        );
    }
    // Setup which triggers this module should respond to
    public StarTrackSupportCaseContactsModule() {
        getTriggerEvents().enableBeforeInsert().enableAfterInsert().enableBeforeUpdate();
    }

	public override List<SObject> filter(List<SObject> records) {
		return CaseAutomationTriggerHandler.filterStarTrackCases(records);
	}
    
    // Record type id for autherised contact record to be created
    public static Id relatedContactRecordTypeId {
        get {
            if (relatedContactRecordTypeId == null) {
                relatedContactRecordTypeId = StarTrack_Settings__c.getInstance().StarTrack_Related_Contact_RecType_Id__c;
            }
            return relatedContactRecordTypeId;
        }
        private set;
    }
    /**
	 * Called when a new Case is being inserted.
	 */
    public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
        try {
            updateInitialCallerDetail(records, uow);
        } catch (Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackSupportCaseContactsModule.class.getName(), 'onBeforeInsert', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }
    
    /**
	 * Update the initial caller details on insert of case.
	 * @param records list of cases which have been inserted.
	 */
    private void updateInitialCallerDetail(List<SObject> records, ApplicationUnitOfWork uow) {
        // Loop through our records to figure out what actions need to be taken
        for (Case c : (List<Case>) records) {
            if (String.isEmpty(c.Recent_Caller_First_Name__c) && String.isEmpty(c.Recent_Caller_Last_Name__c)) {
                if (!String.isEmpty(c.SuppliedEmail) && (StarTrack_Constants.CASE_ORIGIN_EMAIL.equalsIgnoreCase(c.Origin) || StarTrack_Constants.CASE_ORIGIN_BSC.equalsIgnoreCase(c.Origin))) {
                    // StarTrack Case Automation: StarTrack New Email-to-Case (Decision node)
                    // Update the initial contact details
                    c.Initial_Call_Purpose__c = c.Call_Purpose__c;
                    c.Initial_Caller_Email__c = c.Recent_Caller_Email__c = c.SuppliedEmail;
                    c.Initical_CallPreferred_method_of_contact__c = c.Recent_Caller_Pref_Method_of_Contact__c = StarTrack_Constants.CASE_ORIGIN_EMAIL; /* <-- :o ... no words */
                    c.Recent_Caller_Type__c = StarTrack_Constants.CASE_CONTYPE_SENDER;
                }
            } else {
                // StarTrack Case Automation: Create Initial Caller (Decision node)
                c.Initial_Call_Purpose__c = (String.isBlank(c.Call_Purpose__c)
                                             ? c.Initial_Call_Purpose__c
                                             : c.Call_Purpose__c);
                c.Initial_Caller_Email__c = (String.isBlank(c.Recent_Caller_Email__c)
                                             ? c.Initial_Caller_Email__c
                                             : c.Recent_Caller_Email__c);
                c.Initial_Caller_First_Name__c = (String.isBlank(c.Recent_Caller_First_Name__c)
                                                  ? c.Initial_Caller_First_Name__c
                                                  : c.Recent_Caller_First_Name__c);
                c.Initial_Caller_Last_Name__c = (String.isBlank(c.Recent_Caller_Last_Name__c)
                                                 ? c.Initial_Caller_Last_Name__c
                                                 : c.Recent_Caller_Last_Name__c);
                c.Initial_Caller_Phone_Number__c = (String.isBlank(c.Recent_Caller_Phone_Number__c)
                                                    ? c.Initial_Caller_Phone_Number__c
                                                    : c.Recent_Caller_Phone_Number__c);
                c.Initial_Caller_Type__c = (String.isBlank(c.Recent_Caller_Type__c)
                                            ? c.Initial_Caller_Type__c
                                            : c.Recent_Caller_Type__c);
                c.Initial_Contact_Mobile_Number__c = (String.isBlank(c.Recent_Contact_Mobile_Number__c)
                                                      ? c.Initial_Contact_Mobile_Number__c
                                                      : c.Recent_Contact_Mobile_Number__c);
                
                if (!String.isEmpty(c.Recent_Caller_Pref_Method_of_Contact__c)) {
                    c.Initical_CallPreferred_method_of_contact__c = c.Recent_Caller_Pref_Method_of_Contact__c;
                } else if (!String.isEmpty(c.Recent_Caller_Email__c)) {
                    c.Initical_CallPreferred_method_of_contact__c = c.Recent_Caller_Pref_Method_of_Contact__c = StarTrack_Constants.CASE_ORIGIN_EMAIL;
                } else if (!String.isEmpty(c.Recent_Contact_Mobile_Number__c)) {
                    c.Initical_CallPreferred_method_of_contact__c = c.Recent_Caller_Pref_Method_of_Contact__c = StarTrack_Constants.MOBILE_PREFCONTACT_METHOD;
                } else if (!String.isEmpty(c.Recent_Caller_Phone_Number__c)) {
                    c.Initical_CallPreferred_method_of_contact__c = c.Recent_Caller_Pref_Method_of_Contact__c = StarTrack_Constants.CASE_ORIGIN_PHONE;
                } else {
                    c.Initical_CallPreferred_method_of_contact__c = c.Recent_Caller_Pref_Method_of_Contact__c = '';
                }
            }
        }
    }
    
    /**
	 * Called when a new Case is being inserted, calls createInitialCaller which will create related authorised contact
	 */
    public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
        try {
            createInitialCaller(records, uow);
        } catch (Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackSupportCaseContactsModule.class.getName(), 'onAfterInsert', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }
    
    /**
	 * Create AuthorisedContacts__c on insert of case,
	 * @param records list of cases which has been inserted.
	 */
    private void createInitialCaller(List<SObject> records, ApplicationUnitOfWork uow) {
        try {
            List<AuthorisedContacts__c> authContactsList = new List<AuthorisedContacts__c>();
            for (Case c : (List<Case>) records) {
                if (String.isEmpty(c.Recent_Caller_First_Name__c) && String.isEmpty(c.Recent_Caller_Last_Name__c)) {
                    if (!String.isEmpty(c.SuppliedEmail) && (StarTrack_Constants.CASE_ORIGIN_EMAIL.equalsIgnoreCase(c.Origin) || StarTrack_Constants.CASE_ORIGIN_BSC.equalsIgnoreCase(c.Origin))) {
                        // StarTrack Case Automation: StarTrack New Email-to-Case (Decision node)
                        // This processes if the recent name fields are empty only
                        
                        // Create a new Authorised contact as per star track case automation
                        authContactsList.add(
                            new AuthorisedContacts__c(
                                Case__c = c.Id,
                                Contact_Email__c = c.SuppliedEmail,
                                Initial_Contact__c = true,
                                Notification_Required__c = true,
                                Pref_Method_of_Contact__c = 'Email',
                                RecordTypeId = relatedContactRecordTypeId
                            )
                        );
                    }
                } else {
                    // StarTrack Case Automation: Create Initial Caller (Decision node)
                    // Create a new Authorised contact as per star track case automation
                    authContactsList.add(
                        new AuthorisedContacts__c(
                            Case__c = c.Id,
                            Contact_Email__c = c.Recent_Caller_Email__c,
                            Contact_Mobile_Number__c = c.Recent_Contact_Mobile_Number__c,
                            Contact_Phone_Number__c = c.Recent_Caller_Phone_Number__c,
                            Contact_Type__c = c.Recent_Caller_Type__c,
                            First_Name__c = c.Recent_Caller_First_Name__c,
                            Last_Name__c = c.Recent_Caller_Last_Name__c,
                            Initial_Contact__c = true,
                            Notification_Required__c = (!String.isEmpty(c.Recent_Caller_Email__c) ||
                                                        !String.isEmpty(c.Recent_Contact_Mobile_Number__c) ||
                                                        !String.isEmpty(c.Recent_Caller_Phone_Number__c)
                                                        ? true
                                                        : false),
                            RecordTypeId = relatedContactRecordTypeId,
                            Pref_Method_of_Contact__c = c.Initical_CallPreferred_method_of_contact__c
                        )
                    );
                }
            }
            if (!authContactsList.isEmpty()) {
                uow.registerNew(authContactsList, false, 'StarTrackSupportCaseContactsModule');
            }
        } catch (Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackSupportCaseContactsModule.class.getName(), 'onBeforeInsert', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }
    /**
	 * update the cases and assign the consignment
	 */
    public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        try {
            // Get a list records that were changed for easy access
            // Changed records will be based on monitored fields for this module
            Map<Id, Case> assignConsignmentCases = new Map<Id, Case>();
            
            // Loop through our records to figure out what actions need to be taken
            for (Case c : (List<Case>) records) {
                Case oldCase = (Case) existingRecords.get(c.Id);
                // StarTrack Case Automation: Assign consignment (Decision node)
                // The article has changed and either the Recent_Caller_First_Name__c or Recent_Caller_Last_Name__c has changed
                if (c.ArticleTest__c != oldCase.ArticleTest__c && (c.Recent_Caller_First_Name__c != null || c.Recent_Caller_Last_Name__c != null) &&
                    (c.Recent_Caller_First_Name__c != oldCase.Recent_Caller_First_Name__c || c.Recent_Caller_Last_Name__c != oldCase.Recent_Caller_Last_Name__c)) {
                        
                        assignConsignmentCases.put(c.Id, c);
                    }
            }
            
            if (!assignConsignmentCases.isEmpty()) {
                // The article has changed and either the Recent_Caller_First_Name__c or Recent_Caller_Last_Name__c has changed
                ensureContactDetailIntegrity(assignConsignmentCases, uow);
            }
        } catch (Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackSupportCaseContactsModule.class.getName(), 'onBeforeUpdate', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }
    
    /**
	 * This will handle the contact detail update when an article has changed/attached on the case 
	 * and either of the Recent_Caller_First_Name__c or Recent_Caller_Last_Name__c has changed when the record is updated
	 */
    private void ensureContactDetailIntegrity(Map<Id, Case> cases, ApplicationUnitOfWork uow) {
        // Get a list of any 'initial' contacts linked to the cases in subject
        Set<Id> caseIds = cases.keySet();
        Map<Id, Case> casesContacts = CasesSelector.newInstance()
            .selectById(caseIds, new Set<Object>{ CasesSelector.Options.WITH_CHILDINITIALCONTACT });
        List<AuthorisedContacts__c> authContactListToUpsert = new List<AuthorisedContacts__c>();
        for (Case c : cases.values()) {
            // Recent caller's Firstname or LastName changed, clear the details related to recent caller.
            // logic from StarTrackCreateRelatedContact.createRelatedContact method to set below fields as blank.
            c.Recent_Caller_Email__c = '';
            c.Recent_Caller_Phone_Number__c = '';
            c.Recent_Contact_Mobile_Number__c = '';
            c.Recent_Caller_Pref_Method_of_Contact__c = '';
            c.Notification_Required__c = false;
            
            List<AuthorisedContacts__c> authContactList = casesContacts.get(c.Id).Authorised_Contacts__r;
            // Validate if there is an existing initial related contact on the case.
            if (!authContactList?.isEmpty() && String.isBlank(c.Initial_Caller_Email__c) && String.isBlank(c.Initial_Caller_Phone_Number__c) && String.isBlank(c.Initial_Contact_Mobile_Number__c)) {
                // Update the 'initial' contact details on the case.
                updateCaseInitialContactDetails(c);
                
                // Update the existing related contact
                AuthorisedContacts__c relCont = getNewRelatedContact(c, true);
                relCont.Id = authContactList[0].Id; 
                authContactListToUpsert.add(relCont);
                
            } else if (authContactList?.isEmpty()) {
                // Check if there's no initial contact under the case.
                
                // Update the 'initial' contact details on the case.
                updateCaseInitialContactDetails(c);
                
                // Since no initial contact exists then we create one
                authContactListToUpsert.add(getNewRelatedContact(c, true)); //Call method to create new related contact.
            } else {
                authContactListToUpsert.add(getNewRelatedContact(c, true)); //Call method to create new related contact.
            }
        }
        if (!authContactListToUpsert.isEmpty()) {
            uow.registerUpsert(authContactListToUpsert);
        }
    }
    
    // StarTrack method to create new related contact under the case.
    private AuthorisedContacts__c getNewRelatedContact(Case caseRec, Boolean initialContact) {
        return new AuthorisedContacts__c(
            Case__c = caseRec.Id,
            Contact_Email__c = caseRec.Recent_Caller_Email__c,
            Contact_Mobile_Number__c = caseRec.Recent_Contact_Mobile_Number__c,
            Contact_Phone_Number__c = caseRec.Recent_Caller_Phone_Number__c,
            First_Name__c = caseRec.Recent_Caller_First_Name__c,
            Last_Name__c = caseRec.Recent_Caller_Last_Name__c,
            Contact_Type__c = caseRec.Recent_Caller_Type__c,
            Notification_Required__c = caseRec.Notification_Required__c,
            Pref_Method_of_Contact__c = caseRec.Recent_Caller_Pref_Method_of_Contact__c,
            Initial_Contact__c = initialContact
        );
    }
    
    // StarTrack method to update initial contact details on the case.
    private void updateCaseInitialContactDetails(Case caseRec) {
        caseRec.Initial_Caller_First_Name__c = caseRec.Recent_Caller_First_Name__c;
        caseRec.Initial_Caller_Last_Name__c = caseRec.Recent_Caller_Last_Name__c;
        caseRec.Initial_Call_Purpose__c = caseRec.Call_Purpose__c;
        caseRec.Initial_Caller_Email__c = caseRec.Recent_Caller_Email__c;
        caseRec.Initial_Caller_Phone_Number__c = caseRec.Recent_Caller_Phone_Number__c;
        caseRec.Initial_Contact_Mobile_Number__c = caseRec.Recent_Contact_Mobile_Number__c;
        caseRec.Initial_Caller_Type__c = caseRec.Recent_Caller_Type__c;
        caseRec.Initical_CallPreferred_method_of_contact__c = caseRec.Recent_Caller_Pref_Method_of_Contact__c;
    }
}