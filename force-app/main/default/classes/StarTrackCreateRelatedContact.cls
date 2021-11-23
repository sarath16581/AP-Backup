/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture
Description:   Apex class used by StarTrack Case Automation (Process)
Test Class:    StarTrackCreateRelatedContact_Test
History
December 1, 2016 - David Catindoy - Created
------------------------------------------------------------*/
public with sharing class StarTrackCreateRelatedContact {
    
    @InvocableMethod    
    public static void createRelatedContact(List<Id> caseIdList){
        //Query cases that matches with the list of Ids passed in the parameter.
        List<Case> caseList = new List<Case>([SELECT Id, Initial_Caller_First_Name__c, Initial_Caller_Last_Name__c, Initial_Call_Purpose__c, Initial_Caller_Email__c, Initial_Caller_Phone_Number__c, Initial_Contact_Mobile_Number__c, Initial_Caller_Type__c,
                                            Initical_CallPreferred_method_of_contact__c, Recent_Caller_First_Name__c, Recent_Caller_Last_Name__c, Call_Purpose__c, Recent_Caller_Email__c, Recent_Caller_Phone_Number__c, Recent_Contact_Mobile_Number__c, 
                                            Recent_Caller_Type__c, Recent_Caller_Pref_Method_of_Contact__c, Notification_Required__c,
                                            (SELECT Id, Initial_Contact__c, Contact_Email__c, Contact_Mobile_Number__c, Contact_Phone_Number__c, First_Name__c, Last_Name__c, Contact_Type__c, Notification_Required__c, Pref_Method_of_Contact__c FROM Authorised_Contacts__r WHERE Initial_Contact__c = true) FROM Case WHERE Id IN : caseIdList]);
        
        //Initialize container.
        List<AuthorisedContacts__c> relConts = new List<AuthorisedContacts__c>();
        
        for(Case caseRec : caseList){
            //Set some fields to blank/null.
            caseRec.Recent_Caller_Email__c = '';
            caseRec.Recent_Caller_Phone_Number__c = '';
            caseRec.Recent_Contact_Mobile_Number__c = '';
            caseRec.Recent_Caller_Pref_Method_of_Contact__c = '';
            caseRec.Notification_Required__c = false;
            
            //Validate if there is an existing initial related contact on the case.
            if(!caseRec.Authorised_Contacts__r.isEmpty() && (String.isBlank(caseRec.Initial_Caller_Email__c) && String.isBlank(caseRec.Initial_Caller_Phone_Number__c) && String.isBlank(caseRec.Initial_Contact_Mobile_Number__c))){
                updateCaseInitialContactDetails(caseRec);//Call method to update initial contact details on the case.
                relConts.add(updateInitialRelCont(caseRec.Authorised_Contacts__r[0], caseRec)); //Call method to update initial related contact.
            } else if(caseRec.Authorised_Contacts__r.isEmpty()){ //Check if there's no initial contact under the case.
                AuthorisedContacts__c newRelCont = createRelCont(caseRec); //Call method to create new related contact.
                newRelCont.Initial_Contact__c = true; //Flag new related contact as initial.
                relConts.add(newRelCont);
                updateCaseInitialContactDetails(caseRec); //Call method to update initial contact details on the case.
            } else{
                relConts.add(createRelCont(caseRec)); //Call method to create new related contact.
            }
        }
        
        Database.update(caseList); //Push field update on the case records.
        
        if(!relConts.isEmpty()){ //Check if container has value/s.
            Database.upsert(relConts); //Insert/Update related contacts.
        }
    }
    
    //StarTrack method to update initial contact details on the case.
    public static void updateCaseInitialContactDetails(Case caseRec){
        caseRec.Initial_Caller_First_Name__c = caseRec.Recent_Caller_First_Name__c;
        caseRec.Initial_Caller_Last_Name__c = caseRec.Recent_Caller_Last_Name__c;
        caseRec.Initial_Call_Purpose__c = caseRec.Call_Purpose__c;
        caseRec.Initial_Caller_Email__c = caseRec.Recent_Caller_Email__c;
        caseRec.Initial_Caller_Phone_Number__c = caseRec.Recent_Caller_Phone_Number__c;
        caseRec.Initial_Contact_Mobile_Number__c = caseRec.Recent_Contact_Mobile_Number__c;
        caseRec.Initial_Caller_Type__c = caseRec.Recent_Caller_Type__c;
        caseRec.Initical_CallPreferred_method_of_contact__c = caseRec.Recent_Caller_Pref_Method_of_Contact__c;
    }
    
    //StarTrack method to create new related contact under the case.
    public static AuthorisedContacts__c createRelCont(Case caseRec){
        AuthorisedContacts__c relCont = new AuthorisedContacts__c(Case__c = caseRec.Id, Contact_Email__c = caseRec.Recent_Caller_Email__c, Contact_Mobile_Number__c = caseRec.Recent_Contact_Mobile_Number__c,
                                            Contact_Phone_Number__c = caseRec.Recent_Caller_Phone_Number__c, First_Name__c = caseRec.Recent_Caller_First_Name__c, Last_Name__c = caseRec.Recent_Caller_Last_Name__c,
                                            Contact_Type__c = caseRec.Recent_Caller_Type__c, Notification_Required__c = caseRec.Notification_Required__c, Pref_Method_of_Contact__c = caseRec.Recent_Caller_Pref_Method_of_Contact__c);
        return relCont;
    }
    
    //StarTrack method to update initial related contact details.
    public static AuthorisedContacts__c updateInitialRelCont(AuthorisedContacts__c relCont, Case caseRec){
        relCont.Contact_Email__c = caseRec.Recent_Caller_Email__c;
        relCont.Contact_Mobile_Number__c = caseRec.Recent_Contact_Mobile_Number__c;
        relCont.Contact_Phone_Number__c = caseRec.Recent_Caller_Phone_Number__c;
        relCont.First_Name__c = caseRec.Recent_Caller_First_Name__c;
        relCont.Last_Name__c = caseRec.Recent_Caller_Last_Name__c;
        relCont.Contact_Type__c = caseRec.Recent_Caller_Type__c;
        relCont.Notification_Required__c = caseRec.Notification_Required__c;
        relCont.Pref_Method_of_Contact__c = caseRec.Recent_Caller_Pref_Method_of_Contact__c;
        
        return relCont;
    }
}