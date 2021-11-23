/**
 ** Description: Controller for StarTrackAddContactSidePanel page
 ** Author: David Catindoy(Accenture)
 ** Date Created: September 1, 2016
 ** History:--------------------------------------------
 **         September 1, 2016 David Catindoy - Created
 **			February 1, 2018 Angelo Rivera - CCTR Project - Added method to prepopulate New Contact Fields 
 **/
public class StarTrackAddContactSidePanel_ControllerX {
    
    //Declare variables/containers
    public Map<Id, Contact> contactList {get; set;}
    public Map<Id, AuthorisedContacts__c> relatedContacts {get; set;}
    public Set<Id> associatedContactIds {get; set;}
    public String selectedConId {get; set;} 
    public Case caseRec {get; set;}
    public Id caseId {get; set;}
    public Id initialContactId {get; set;}
    public Id startrackRT {get; set;}
    public Boolean isEdit {get; set;}
    public Boolean legalEntityContact {get; set;}
    public Boolean noContactSelected {get; set;}
    //public Boolean notificationRequired {get; set;}
    public Boolean saveSuccess {get; set;}
    public Boolean initialContactAvailable {get; set;}
    
    public StarTrackAddContactSidePanel_ControllerX(ApexPages.StandardController con) {
        //get controller case record id
        caseId = con.getId();
        saveSuccess = StarTrack_Constants.ST_FALSE;
        //Call method to initialize variables/containers
        initialize();
    }
    
    //START - CCTR - APRivera - 31012018 - Added variable for the prepopulation of fields
    public String phoneNumber{get;set;}
    public String callerType{get;set;}
    public Id relatedContactId{get;set;}
    public Boolean withRelatedContact{get;set;}

    //Method that populates the new contact Fields
	public void populateField(){
        if(String.isNotBlank(caseId) && !StarTrack_Constants.CASE_STAT_CLOSED.equals(caseRec.Status)){
            isEdit = StarTrack_Constants.ST_TRUE;
            if(!withRelatedContact){
                selectedConId = StarTrack_Constants.ADD_CONTACT;
                autoPopulateFields();
                caseRec.Recent_Caller_Phone_Number__c = phoneNumber;
                caseRec.Recent_Caller_Pref_Method_of_Contact__c = StarTrack_Constants.CASE_ORIGIN_PHONE;
                caseRec.Recent_Caller_Type__c = callerType;
            }else{
                selectedConId = relatedContactId;
                autoPopulateFields();
                caseRec.Recent_Caller_Pref_Method_of_Contact__c = StarTrack_Constants.CASE_ORIGIN_PHONE;
            }
        } else if(StarTrack_Constants.CASE_STAT_CLOSED.equals(caseRec.Status)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Constants.ERRORMSG_CASECLOSED));
        }
    }
    //END - CCTR - APRivera - 31012018
    
    public void initialize(){
        //Initialize variables/containers
        associatedContactIds =  new Set<Id>();
        startrackRT = Schema.SObjectType.AuthorisedContacts__c.getRecordTypeInfosByName().get(StarTrack_Constants.STRELCONT_RT).getRecordTypeId();
        selectedConId = '';
        isEdit = StarTrack_Constants.ST_FALSE;
        legalEntityContact = StarTrack_Constants.ST_FALSE;
        noContactSelected = StarTrack_Constants.ST_TRUE;
        //notificationRequired = StarTrack_Constants.ST_FALSE;
        initialContactAvailable = StarTrack_Constants.ST_FALSE;
        
        //Check if caseId is not blank
        if(String.isNotBlank(caseId)){
            //Query case record passed as a standard controller.
            caseRec = [SELECT Id, CaseNumber, Related_Billing_Account__c, Recent_Caller_Type__c, Direction__c, Recent_Caller_Pref_Method_of_Contact__c, Recent_Caller_First_Name__c, Recent_Caller_Last_Name__c, Initial_Contact_Mobile_Number__c,
                       Recent_Caller_Phone_Number__c, Recent_Contact_Mobile_Number__c, Recent_Caller_Email__c, Callers_Data_Change__c, Add_Caller_Quick_Action__c, No_Data_Capture_DateTime__c, Origin, SuppliedEmail, Initial_Caller_First_Name__c,
                       Initial_Caller_Last_Name__c, Initial_Caller_Email__c, Initial_Caller_Phone_Number__c, Initial_Caller_Type__c, Initical_CallPreferred_method_of_contact__c, Number_of_Callers__c, Initial_Call_Purpose__c, Notification_Required__c,
                       Call_Purpose__c, AccountId, Status FROM Case WHERE Id = :caseId];
                                                
            relatedContacts = new Map<Id, AuthorisedContacts__c>([SELECT Id, RecordType.Name, Case__c, Calc_Contact_Email__c, Calc_Contact_Mobile_Number__c, Calc_Contact_Phone_Number__c, Contact_Type__c, Calc_First_Name__c, Calc_Last_Name__c,
                                                               Notification_Required__c, Pref_Method_of_Contact__c, Related_Contact__c, Initial_Contact__c, Notified_on_Status__c FROM AuthorisedContacts__c
                                                               WHERE Case__c != null AND Case__c = :caseRec.Id ORDER BY Initial_Contact__c DESC, Calc_First_Name__c ASC]);
            if(!relatedContacts.isEmpty()){
                for(AuthorisedContacts__c relCont : relatedContacts.values()){
                    if(String.isNotBlank(relCont.Related_Contact__c)){
                        associatedContactIds.add(relCont.Related_Contact__c);
                    }
                    if(relCont.Initial_Contact__c){
                        initialContactAvailable = StarTrack_Constants.ST_TRUE;
                        initialContactId = relCont.Id;
                    }
                }
            }                                                   
            contactList = new Map<Id, Contact>([SELECT Id, Name, FirstName, LastName, MobilePhone, Email, Status__c, AccountId, Contact_Type__c, Phone, Pref_Method_of_Contact__c
                                                FROM Contact WHERE AccountId != null AND AccountId = :caseRec.AccountId AND Status__c = :StarTrack_Constants.CON_STAT_ACTIVE AND Contact_Type__c = :StarTrack_Constants.CONTACT_TYPE AND Id NOT IN :associatedContactIds
                                                ORDER BY Name ASC]);
            
            //Assign predefined values
            caseRec.Callers_Data_Change__c = (StarTrack_Constants.CASE_ORIGIN_EMAIL.equals(caseRec.Origin) && String.isBlank(caseRec.Recent_Caller_First_Name__c)) ? StarTrack_Constants.ST_FALSE : StarTrack_Constants.ST_TRUE;
        }
    }
    
    //Method to return list of options to be selected in the contact list.
    public List<SelectOption> getContacts() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', StarTrack_Constants.GLOBAL_NONE));
        options.add(new SelectOption(StarTrack_Constants.ADD_CONTACT, StarTrack_Constants.ADD_NEW_CONTACT));
        
        if(!relatedContacts.isEmpty()){
            for(AuthorisedContacts__c relCont : relatedContacts.values()){
                options.add(new SelectOption(relCont.Id, (String.isNotBlank(relCont.Calc_First_Name__c) ? (relCont.Calc_First_Name__c + ' ') :  '') + (String.isNotBlank(relCont.Calc_Last_Name__c) ? (relCont.Calc_Last_Name__c + ' - ') : '') +
                (String.isNotBlank(relCont.Contact_Type__c) ? relCont.Contact_Type__c : '') + (relCont.Initial_Contact__c ? ' (Initial)' : '')));
            }
        }
        
        if(!contactList.isEmpty()){
            for(Contact contRec : contactList.values()){
                options.add(new SelectOption(contRec.Id, contRec.Name));
            }
        }
        
        return options;
    }
    
    //Change edit flag value.
    public void changeEditFlag(){
        if(String.isNotBlank(caseId) && !StarTrack_Constants.CASE_STAT_CLOSED.equals(caseRec.Status)){
            if(!isEdit){
                initialize();
            }
            caseRec.Direction__c = StarTrack_Constants.CASE_DIRECTION_IN;
            if(relatedContacts.size() < 2 && initialContactAvailable && !isEdit){
                selectedConId = initialContactId;
                autoPopulateFields();
            }
            isEdit = StarTrack_Constants.ST_TRUE;
        } else if(StarTrack_Constants.CASE_STAT_CLOSED.equals(caseRec.Status)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Constants.ERRORMSG_CASECLOSED));
        }
    }
    
    //Initialize again to retrun the record to its previous state.
    public void cancelEdit(){
        initialize();
    }
    
    //Save all the new details specified.
    public void saveContactDetails(){
        
        caseRec.Recent_Contact_Mobile_Number__c = String.isNotBlank(caseRec.Recent_Contact_Mobile_Number__c) ? caseRec.Recent_Contact_Mobile_Number__c.replaceAll(' ', '') : caseRec.Recent_Contact_Mobile_Number__c;
        caseRec.Recent_Caller_Phone_Number__c = String.isNotBlank(caseRec.Recent_Caller_Phone_Number__c) ? caseRec.Recent_Caller_Phone_Number__c.replaceAll(' ', '') : caseRec.Recent_Caller_Phone_Number__c;
        //Throw an error if preferred method of contact is 'Email' and caller email is blank.
        if(caseRec.Notification_Required__c && String.isBlank(caseRec.Recent_Caller_Pref_Method_of_Contact__c)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_PREFMETHODISBLANK) != null ?
                StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_PREFMETHODISBLANK).Value__c : StarTrack_Constants.ERRORMSG_PREFMETHODISBLANK));
        } else if(StarTrack_Constants.CASE_ORIGIN_EMAIL.equals(caseRec.Recent_Caller_Pref_Method_of_Contact__c) && String.isBlank(caseRec.Recent_Caller_Email__c)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_EMAILISBLANK) != null ?
                StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_EMAILISBLANK).Value__c : StarTrack_Constants.ERRORMSG_EMAILISBLANK));
        } else if(StarTrack_Constants.CASE_ORIGIN_PHONE.equals(caseRec.Recent_Caller_Pref_Method_of_Contact__c) && String.isBlank(caseRec.Recent_Caller_Phone_Number__c)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_PHONEISBLANK) != null ?
                StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_PHONEISBLANK).Value__c : StarTrack_Constants.ERRORMSG_PHONEISBLANK));
        } else if(StarTrack_Constants.MOBILE_PREFCONTACT_METHOD.equals(caseRec.Recent_Caller_Pref_Method_of_Contact__c) && String.isBlank(caseRec.Recent_Contact_Mobile_Number__c)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_MOBILEISBLANK) != null ?
                StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_MOBILEISBLANK).Value__c : StarTrack_Constants.ERRORMSG_MOBILEISBLANK));
        } else if(String.isNotBlank(caseRec.Recent_Contact_Mobile_Number__c) && (caseRec.Recent_Contact_Mobile_Number__c.length() != 10 || !caseRec.Recent_Contact_Mobile_Number__c.isNumeric())){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Constants.ERRORMSG_MOBILEINVALID));
        } else if(String.isNotBlank(caseRec.Recent_Caller_Phone_Number__c) && (caseRec.Recent_Caller_Phone_Number__c.length() != 10 || !caseRec.Recent_Caller_Phone_Number__c.isNumeric()) && (caseRec.Recent_Caller_Phone_Number__c.length() != 6 || !caseRec.Recent_Caller_Phone_Number__c.isNumeric())){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Constants.ERRORMSG_PHONEINVALID));
        } else if(String.isNotBlank(caseRec.Recent_Caller_Phone_Number__c) && (caseRec.Recent_Caller_Phone_Number__c.length() == 6) && (caseRec.Recent_Caller_Phone_Number__c.substring(0,2)!='13')){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Constants.ERRORMSG_PHONEINVALID13));
        } else if(String.isBlank(caseRec.Recent_Caller_Type__c) ){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Constants.ERRORMSG_CONTACTTYPE));
        } else {
            
            caseRec.Recent_Caller_Pref_Method_of_Contact__c = String.isNotBlank(caseRec.Recent_Caller_Pref_Method_of_Contact__c) ? caseRec.Recent_Caller_Pref_Method_of_Contact__c :
                                        (String.isNotBlank(caseRec.Recent_Caller_Email__c) ? StarTrack_Constants.CASE_ORIGIN_EMAIL : (String.isNotBlank(caseRec.Recent_Contact_Mobile_Number__c) ? StarTrack_Constants.MOBILE_PREFCONTACT_METHOD : (String.isNotBlank(caseRec.Recent_Caller_Phone_Number__c) ? StarTrack_Constants.CASE_ORIGIN_PHONE : '')));
            
            if(caseRec.Callers_Data_Change__c){
                caseRec.Number_of_Callers__c += 1;
            }
            
            if(StarTrack_Constants.ADD_CONTACT.equals(selectedConId) && (String.isNotBlank(caseRec.Recent_Caller_Email__c) || String.isNotBlank(caseRec.Recent_Caller_Phone_Number__c) || String.isNotBlank(caseRec.Recent_Contact_Mobile_Number__c))){
                if(initialContactAvailable && (String.isBlank(caseRec.Initial_Caller_Email__c) && String.isBlank(caseRec.Initial_Caller_Phone_Number__c) && String.isBlank(caseRec.Initial_Contact_Mobile_Number__c))){
                    AuthorisedContacts__c selectedRelCont = relatedContacts.get(initialContactId);
                    caseRec.Notification_Required__c = StarTrack_Constants.ST_TRUE;
                    updateInitialRelatedContactDetails(selectedRelCont, null);
                    updateCaseInitialContactDetails();
                } else{
                    Database.insert(new AuthorisedContacts__c(RecordTypeId = startrackRT, Case__c = caseRec.Id, Contact_Email__c = caseRec.Recent_Caller_Email__c, Contact_Mobile_Number__c = caseRec.Recent_Contact_Mobile_Number__c, Contact_Phone_Number__c = caseRec.Recent_Caller_Phone_Number__c,
                                        Initial_Contact__c = initialContactAvailable ? StarTrack_Constants.ST_FALSE : StarTrack_Constants.ST_TRUE, Contact_Type__c = caseRec.Recent_Caller_Type__c, First_Name__c = caseRec.Recent_Caller_First_Name__c, Last_Name__c = caseRec.Recent_Caller_Last_Name__c,
                                        Notification_Required__c = initialContactAvailable ? caseRec.Notification_Required__c : StarTrack_Constants.ST_TRUE, Pref_Method_of_Contact__c = caseRec.Recent_Caller_Pref_Method_of_Contact__c));
            
                    if(!initialContactAvailable){
                        updateCaseInitialContactDetails();
                    }  
                }
            } else if(!StarTrack_Constants.ADD_CONTACT.equals(selectedConId)){
                if(relatedContacts.containsKey(selectedConId)){
                    AuthorisedContacts__c selectedRelCont = relatedContacts.get(selectedConId);
                    
                    if(initialContactAvailable && selectedConId.equals(initialContactId)){
                        updateCaseInitialContactDetails();
                        caseRec.Notification_Required__c = (String.isBlank(selectedRelCont.Calc_Contact_Email__c) && String.isBlank(selectedRelCont.Calc_Contact_Phone_Number__c) && String.isBlank(selectedRelCont.Calc_Contact_Mobile_Number__c)) &&
                                               (String.isNotBlank(caseRec.Recent_Caller_Email__c) || String.isNotBlank(caseRec.Recent_Caller_Phone_Number__c) || String.isNotBlank(caseRec.Recent_Contact_Mobile_Number__c)) ? StarTrack_Constants.ST_TRUE : caseRec.Notification_Required__c;
                    }
                    updateInitialRelatedContactDetails(selectedRelCont, null);
                } else if(contactList.containsKey(selectedConId) && (String.isNotBlank(caseRec.Recent_Caller_Email__c) || String.isNotBlank(caseRec.Recent_Caller_Phone_Number__c) || String.isNotBlank(caseRec.Recent_Contact_Mobile_Number__c))){
                    if(initialContactAvailable && (String.isBlank(caseRec.Initial_Caller_Email__c) && String.isBlank(caseRec.Initial_Caller_Phone_Number__c) && String.isBlank(caseRec.Initial_Contact_Mobile_Number__c))){
                        AuthorisedContacts__c selectedRelCont = relatedContacts.get(initialContactId);
                        caseRec.Notification_Required__c = StarTrack_Constants.ST_TRUE;
                        updateInitialRelatedContactDetails(selectedRelCont, selectedConId);
                        updateCaseInitialContactDetails();
                    } else{
                        Database.insert(new AuthorisedContacts__c(RecordTypeId = startrackRT, Case__c = caseRec.Id, Related_Contact__c = selectedConId, Contact_Type__c = caseRec.Recent_Caller_Type__c, Notification_Required__c = initialContactAvailable ? caseRec.Notification_Required__c : StarTrack_Constants.ST_TRUE,
                                            Initial_Contact__c = initialContactAvailable ? StarTrack_Constants.ST_FALSE : StarTrack_Constants.ST_TRUE, Pref_Method_of_Contact__c = caseRec.Recent_Caller_Pref_Method_of_Contact__c));
                        
                        caseRec.Recent_Caller_Pref_Method_of_Contact__c = String.isNotBlank(caseRec.Recent_Caller_Pref_Method_of_Contact__c) ? caseRec.Recent_Caller_Pref_Method_of_Contact__c :
                                        (String.isNotBlank(caseRec.Recent_Caller_Email__c) ? StarTrack_Constants.CASE_ORIGIN_EMAIL : (String.isNotBlank(caseRec.Recent_Contact_Mobile_Number__c) ? StarTrack_Constants.MOBILE_PREFCONTACT_METHOD : (String.isNotBlank(caseRec.Recent_Caller_Phone_Number__c) ? StarTrack_Constants.CASE_ORIGIN_PHONE : '')));                    
                        if(!initialContactAvailable){
                            updateCaseInitialContactDetails();
                        }
                    }
                }
            }
            
            //Clone current case record.
            Case tempCase = caseRec.clone(StarTrack_Constants.ST_TRUE, StarTrack_Constants.ST_TRUE, StarTrack_Constants.ST_TRUE, StarTrack_Constants.ST_TRUE);
            if(caseRec.Callers_Data_Change__c){
                caseRec.Callers_Data_Change__c = StarTrack_Constants.ST_FALSE;
            }
            //Update case record to save all the changes made in the visualforce page.
            caseRec.Status = [SELECT Id, Status FROM Case WHERE Id =:caseRec.Id].Status;
            Database.update(caseRec);
            saveSuccess = StarTrack_Constants.ST_TRUE;
            //Call method to initialize all the variables again.
            initialize();
            
            //Check if create call log should be trigger.
            if(tempCase.Callers_Data_Change__c){
                StarTrackCreateCallLogActivity.createLogACallRecord(new List<Id>{caseRec.Id});
            } else{
                //Call method to update exisiting call log details.
                if(StarTrack_Settings__c.getOrgDefaults().Create_Call_Log_using_Future__c){
                    //Execute the process in asynchronous manner.
                    StarTrackUtil.updateCallLogAsync(new List<Id>{caseRec.Id});
                } else{
                    //Execute the process in synchronous manner.
                    StarTrackUtil.updateCallLogSync(new List<Id>{caseRec.Id});
                }
            }
        }
    }
    
    //Method to auto populate recent contact details on the page when a contact record was selected in the contact list.
    public void autoPopulateFields(){
        //If selected contact is receiver contact, then perform this auto assignment.
        if(String.isBlank(selectedConId)){
            setBooleanFlag(StarTrack_Constants.ST_TRUE, StarTrack_Constants.ST_FALSE, StarTrack_Constants.ST_FALSE);
        } else if(StarTrack_Constants.ADD_CONTACT.equals(selectedConId)){
            caseRec.Recent_Caller_First_Name__c = '';
            caseRec.Recent_Caller_Last_Name__c = '';
            caseRec.Recent_Contact_Mobile_Number__c = '';
            caseRec.Recent_Caller_Phone_Number__c = '';
            caseRec.Recent_Caller_Email__c = '';
            caseRec.Recent_Caller_Type__c = StarTrack_Constants.CASE_CONTYPE_SENDER;
            caseRec.Recent_Caller_Pref_Method_of_Contact__c = StarTrack_Constants.CASE_ORIGIN_EMAIL;
            setBooleanFlag(StarTrack_Constants.ST_FALSE, StarTrack_Constants.ST_FALSE, StarTrack_Constants.ST_FALSE);
            
        } else if(relatedContacts.containsKey(selectedConId)){ //Check if selected contact is in the contact map variable, if yes then pull it up and use it for auto assignment.
            AuthorisedContacts__c selectedContact = relatedContacts.get(selectedConId);
            
            caseRec.Recent_Caller_First_Name__c = selectedContact.Calc_First_Name__c;
            caseRec.Recent_Caller_Last_Name__c = selectedContact.Calc_Last_Name__c;
            caseRec.Recent_Caller_Phone_Number__c = selectedContact.Calc_Contact_Phone_Number__c;
            caseRec.Recent_Contact_Mobile_Number__c = selectedContact.Calc_Contact_Mobile_Number__c;
            caseRec.Recent_Caller_Email__c = selectedContact.Calc_Contact_Email__c;
            caseRec.Recent_Caller_Type__c = selectedContact.Contact_Type__c;
            caseRec.Recent_Caller_Pref_Method_of_Contact__c = selectedContact.Pref_Method_of_Contact__c;
            setBooleanFlag(StarTrack_Constants.ST_FALSE, String.isNotBlank(selectedContact.Related_Contact__c) ?  StarTrack_Constants.ST_TRUE : StarTrack_Constants.ST_FALSE, selectedContact.Notification_Required__c);
            
        } else if(contactList.containsKey(selectedConId)){ //Check if selected contact is in the contact map variable, if yes then pull it up and use it for auto assignment.
            Contact selectedContact = contactList.get(selectedConId);
            
            caseRec.Recent_Caller_First_Name__c = selectedContact.FirstName;
            caseRec.Recent_Caller_Last_Name__c = selectedContact.LastName;
            caseRec.Recent_Caller_Phone_Number__c = selectedContact.Phone;
            caseRec.Recent_Contact_Mobile_Number__c = selectedContact.MobilePhone;
            caseRec.Recent_Caller_Email__c = selectedContact.Email;
            caseRec.Recent_Caller_Type__c = StarTrack_Constants.CASE_CONTYPE_SENDER;
            caseRec.Recent_Caller_Pref_Method_of_Contact__c = String.isNotBlank(selectedContact.Pref_Method_of_Contact__c) ? selectedContact.Pref_Method_of_Contact__c : StarTrack_Constants.CASE_ORIGIN_EMAIL;
            setBooleanFlag(StarTrack_Constants.ST_FALSE, StarTrack_Constants.ST_TRUE, StarTrack_Constants.ST_FALSE);
        }
    }
    
    public void setBooleanFlag(Boolean noContact, Boolean legalEnt, Boolean notif){
        noContactSelected = noContact;
        legalEntityContact = legalEnt;
        caseRec.Notification_Required__c = notif;
    }
    
    public void updateCaseInitialContactDetails(){
        caseRec.Initial_Caller_First_Name__c = caseRec.Recent_Caller_First_Name__c;
        caseRec.Initial_Caller_Last_Name__c = caseRec.Recent_Caller_Last_Name__c;
        caseRec.Initial_Call_Purpose__c = caseRec.Call_Purpose__c;
        caseRec.Initial_Caller_Email__c = caseRec.Recent_Caller_Email__c;
        caseRec.Initial_Caller_Phone_Number__c = caseRec.Recent_Caller_Phone_Number__c;
        caseRec.Initial_Contact_Mobile_Number__c = caseRec.Recent_Contact_Mobile_Number__c;
        caseRec.Initial_Caller_Type__c = caseRec.Recent_Caller_Type__c;
        caseRec.Initical_CallPreferred_method_of_contact__c = caseRec.Recent_Caller_Pref_Method_of_Contact__c;
    }
    
    public void updateInitialRelatedContactDetails(AuthorisedContacts__c selectedRelCont, Id contactId){
        if(String.isBlank(selectedRelCont.Related_Contact__c)){
            selectedRelCont.Contact_Email__c = caseRec.Recent_Caller_Email__c;
            selectedRelCont.Contact_Mobile_Number__c = caseRec.Recent_Contact_Mobile_Number__c;
            selectedRelCont.Contact_Phone_Number__c = caseRec.Recent_Caller_Phone_Number__c;
            selectedRelCont.First_Name__c = caseRec.Recent_Caller_First_Name__c;
            selectedRelCont.Last_Name__c = caseRec.Recent_Caller_Last_Name__c;
        }
        selectedRelCont.Related_Contact__c = String.isNotBlank(contactId) ? contactId : selectedRelCont.Related_Contact__c;
        selectedRelCont.Contact_Type__c = caseRec.Recent_Caller_Type__c;
        selectedRelCont.Notification_Required__c = caseRec.Notification_Required__c;
        selectedRelCont.Notified_on_Status__c = (caseRec.Callers_Data_Change__c && StarTrack_Constants.CASE_STAT_PENCUSNOTIF.equals(caseRec.Status) && StarTrack_Constants.OUTBOUND_CALLLOG.equals(caseRec.Direction__c) && (StarTrack_Constants.MOBILE_PREFCONTACT_METHOD.equals(caseRec.Recent_Caller_Pref_Method_of_Contact__c) || StarTrack_Constants.CASE_ORIGIN_PHONE.equals(caseRec.Recent_Caller_Pref_Method_of_Contact__c))) ?
                                                caseRec.Status : selectedRelCont.Notified_on_Status__c;
        selectedRelCont.Pref_Method_of_Contact__c = String.isNotBlank(caseRec.Recent_Caller_Pref_Method_of_Contact__c) ? caseRec.Recent_Caller_Pref_Method_of_Contact__c : (String.isNotBlank(caseRec.Recent_Caller_Email__c) ? StarTrack_Constants.CASE_ORIGIN_EMAIL :
                                                    (String.isNotBlank(caseRec.Recent_Caller_Phone_Number__c) ? StarTrack_Constants.CASE_ORIGIN_PHONE : (String.isNotBlank(caseRec.Recent_Contact_Mobile_Number__c) ? StarTrack_Constants.MOBILE_PREFCONTACT_METHOD : '')));
        Database.update(selectedRelCont);
    }
}