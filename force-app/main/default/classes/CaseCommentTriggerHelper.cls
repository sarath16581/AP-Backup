/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 21/02/2016
  * @description  : Helper Class for CaseCommentTrigger
  */
/*******************************  History ************************************************
21/02/2016  nandan.narasappa@auspost.com.au  Created
21/02/2016  nandan.narasappa@auspost.com.au  Added completeFirstCustomerResponse method
30/05/2016  nandan.narasappa@auspost.com.au  Added "LastModifiedById" to SOQL in checkNPS method to fix INC0742626
03/10/2017  maumita.bandyopadhyay@auspost.com.au  Added Status in checkNPS
20/11/2017	maumita.bandyopadhyay@auspost.com.au  Commented out status checking to fix INC1035423
21/06/2018  disha.kariya@auspost.com.au  Removed NPS check method.
12/12/2018  ramtej.juloori@auspost.com.au  Added method to send email notification on child case comment insert/update.
*******************************  History ************************************************/
public with sharing class CaseCommentTriggerHelper{

    // Constants
    private static Set<Id> ssswProfileIds = new Set<Id>();                   // profile Ids of all SSSW profiles
    private static Set<Id> validRecTypes = new Set<Id>();                   // type of cases for which code executes

    // Set the recordTypeMap variable to store the map of id and record type name
    static{
        try{
            // get all valid record types for the SSSW functionality
            validRecTypes =  Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);

            Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());                        // Get Query Row Limit
            String ssswProf = SSSWConstants.PERCENT + SSSWConstants.SSSW_APP + SSSWConstants.PERCENT ;
            for(Profile prof : [SELECT Id FROM Profile WHERE Name LIKE : ssswProf LIMIT : rowLimit]){
                ssswProfileIds.add(prof.Id);
            }
        }
        catch(Exception exp){
            System.debug('** StackTrack ==>'+ exp.getStackTraceString());
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    CaseCommentTriggerHelper.class.getName(), SSSWConstants.STATIC_BLOCK,
                    SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }

    /**
      * @description       This method checks if its public comments & completes First customer response milestone
      * @param             newCaseCommentMap - Map<Id,CaseComment>
      * @return            Void
      * @throws            Method might throw exception which is handled by Try-Catch block
      */
    public void completeFirstCustomerResponse(Map<Id,CaseComment> newCaseCommentMap){
        try{
            Set<Id> caseIds = new Set<Id>();    // set of case ids for public case comment
            List<Case> caseList = new List<Case>();

            if(ssswProfileIds.contains(UserInfo.getProfileId())){   // check if case comment is by SSSW user
                for(CaseComment comment : newCaseCommentMap.values()){
                    if(comment.isPublished){    // check if its public comment & add to set
                        caseIds.add(comment.ParentId);
                    }
                }
                if(!caseIds.isEmpty()){
                    Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());                        // Get Query Row Limit
                    for(Case caseRec : [SELECT Id, RecordTypeId FROM Case
                    WHERE Id IN: caseIds AND RecordTypeId IN: validRecTypes LIMIT : rowLimit]){
                        caseList.add(caseRec);
                    }
                    if(!caseList.isEmpty()){    // check if caseList got values & invoke completeCaseMilestones method from Utility
                        Utility.completeCaseMilestones(caseList,new Set<String>{SSSWConstants.FIRST_CUSTOMER_RESPONSE},true);
                    }
                }
            }
        }
        catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    CaseCommentTriggerHelper.class.getName(), SSSWConstants.METH_COMPLETE_FCR,
                    SSSWConstants.CASECOMMENT_TRIGGER, LoggingLevel.ERROR);
        }
    }

    /*********************************************************************************
    * Created History: 12-12-2018  Rahul Kapoor
    * Description:
    *      Method to send email notification to child case owner and/or child case team members 
            on child case comment insert.
    **********************************************************************************/
    public void sendCaseCommentsNotification(Map<Id,CaseComment> newCaseCommentMap) {
        try{
            //List of case ids collected from casecomment to query on case
            List<Id> childCaseIds = new List<Id>();
            //list of target (child case record type name) and source (parent case record type name)
            //collected from child and parent case to query on metadata
            List<string> targetRecordTypeIds = new List<string>();
            List<string> sourceRecordTypeId = new List<string>();
            //collection of emails to be sent out
            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
            //map containing a list of case team members against each child case
            Map<Id,List<CaseTeamMember>> caseTeamMemberMap = new Map<Id,List<CaseTeamMember>>();
            //Query email template to be used
            EmailTemplate et = [Select id, Subject, Body, HtmlValue from EmailTemplate where Name = 'Case comment notification'];
            //collect child case ids from case comment object who has parent 
            //in order to query case fields           
            for(CaseComment casComm :newCaseCommentMap.values()){
                    childCaseIds.add(casComm.ParentId);
            }
            //collect source and parent recordtype names to query service delivery setting metadata
            Map<Id, Case> caseDataMap = new Map<Id, Case>([SELECT Id, OwnerId, RecordTypeId, Parent.RecordTypeId, 
                Recordtype.Name, Parent.Recordtype.Name, CaseNumber, Subject, Description, Updated_Case_Comments__c, 
				Parent.Updated_Case_Comments__c FROM Case WHERE Id IN :childCaseIds AND ParentId != null]);
            //Query case team members for the case ids available and group members against the case
            for(CaseTeamMember csTeam :[SELECT Id, MemberId, ParentId FROM CaseTeamMember WHERE ParentId IN :caseDataMap.keySet()]){
                List<CaseTeamMember> tempMemberList = new List<CaseTeamMember>();
                if(caseTeamMemberMap.containsKey(csTeam.ParentId)){
                    tempMemberList = caseTeamMemberMap.get(csTeam.ParentId);
                }
                tempMemberList.add(csTeam);
                caseTeamMemberMap.put(csTeam.ParentId, tempMemberList);
            }
            //collect parent and child record types to query on metadata
            for(Case cs :caseDataMap.values()){
                targetRecordTypeIds.add(cs.RecordtypeId);
                sourceRecordTypeId.add(cs.Parent.RecordtypeId);
            }
            //iterate service delivery metadata settings of matching source and target record types to check if the notifications are allowed for 
            //child case owner or case team member and send notification         
            for(Service_Delivery_Setting__mdt serviceDeliverySetting :[SELECT Id, Source_RecordType_Id__c, 
                Target_RecordType_Id__c, Notify_Child_Case_Owner__c, Notify_Child_Case_Team_Members__c
                FROM Service_Delivery_Setting__mdt WHERE Source_RecordType_Id__c IN 
                :sourceRecordTypeId AND Target_RecordType_Id__c IN :targetRecordTypeIds]){
                    //Proceed further if only either of the notifications is allowed
                    if(serviceDeliverySetting.Notify_Child_Case_Owner__c || serviceDeliverySetting.Notify_Child_Case_Team_Members__c){
                        //iterate case comments and check if the notification are allowed by
                        //comparing target and source record types
                        for(CaseComment csCom :newCaseCommentMap.values()){
                            //get the child case from map by passing parent id of case comment
                            Case childCase = caseDataMap.get(csCom.ParentId);
                            //check if the metadata combination exists for the parent and child record types
                            if(childCase.RecordtypeId == serviceDeliverySetting.Target_RecordType_Id__c && 
                                childCase.Parent.RecordtypeId == serviceDeliverySetting.Source_RecordType_Id__c){
                                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                    List<string> toAddressList = new List<string>();
                                    //check if notifications are on for child case owner
                                    if(serviceDeliverySetting.Notify_Child_Case_Owner__c){                                       
                                        //set child case owner as receipent if he is not the creator of the comment
                                        if(csCom.CreatedById != childCase.ownerId && string.valueOf(childCase.ownerId.getSObjectType()) == 'User'){
                                            toAddressList.add(childCase.ownerId);
                                        }                                        
                                    }
                                    //check if notifications are on for child case team members
                                    if(serviceDeliverySetting.Notify_Child_Case_Team_Members__c){
                                        //iterate through related case team members for the case and to receipent
                                        //list only if he hasn't created the comment
                                        if(caseTeamMemberMap.containsKey(childCase.Id)){
                                            for(CaseTeamMember csTeam :caseTeamMemberMap.get(childCase.Id)){
                                                if(csCom.CreatedById != csTeam.MemberId && string.valueOf(csTeam.MemberId.getSObjectType()).equalsIgnoreCase('User')){
                                                    toAddressList.add(csTeam.MemberId);
                                                }
                                            }
                                        }                                       
                                    }
                                    //get the email after setting subject, body from the email template
                                    mail = formEmailStructure(toAddressList, et.Subject, childCase, csCom, JSON.serialize(et.Body));                                 
                                    //add email to list only if receipents exist
                                    if(toAddressList != null && toAddressList.size() > 0){
                                        mailList.add(mail);
                                    }
                            }
                        }
                    }
            }
            //check the maillist size and send if any email exists
            system.debug('mailList '+mailList+' size '+mailList.size());
            if(mailList != null && mailList.size() > 0){
                Messaging.SendEmailResult [] result = Messaging.sendEmail(mailList);
                system.debug(' email result '+result);
            }            
        }
        catch(Exception exp){
            //Error Logged to Exception object for analysis.
            system.debug('exp message '+exp.getMessage()+' at '+exp.getStackTraceString());
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    CaseCommentTriggerHelper.class.getName(), SSSWConstants.METH_COMPLETE_FCR,
                    SSSWConstants.CASECOMMENT_TRIGGER, LoggingLevel.ERROR);
        }

    }

    /*********************************************************************************
    * Created History: 18-01-2019  Ramtej
    * Description:
    *      Method to set subject body and other details of an email
    **********************************************************************************/
    public Messaging.SingleEmailMessage formEmailStructure(List<string> toAddressList, string emailSubject, 
            Case childCase, CaseComment csCom, string emailBody){
        Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
        singleEmail.setToAddresses(toAddressList);
        singleEmail.setTreatTargetObjectAsRecipient(true);                                   
        singleEmail.setSenderDisplayName('Salesforce Support');
        singleEmail.setUseSignature(false);
        singleEmail.setBccSender(false);
        singleEmail.setSaveAsActivity(false);
        String recordLink = URL.getSalesforceBaseUrl().toExternalForm()+'/'+childCase.Id;
        //Set the subject in the email after replacing the merger fields with the data       
        emailSubject = emailSubject.replace('{!Case.CaseNumber}', childCase.CaseNumber);
        emailSubject = emailSubject.replace('{!Case.Subject}', (childCase.Subject!='' && String.isNotBlank(childCase.Subject) ? childCase.Subject : ''));
        singleEmail.setSubject(emailSubject);
        //Set the body in the email after replaceing the merge fields with the data
        emailBody = emailBody.replace('{!Case.CaseNumber}',childCase.CaseNumber);
        emailBody = emailBody.replace('{!CaseComment.Body}',(csCom.commentBody!='' && String.isNotBlank(csCom.commentBody) ? csCom.commentBody : ''));
        emailBody = emailBody.replace('{!Case.Description}',(childCase.Description!='' && String.isNotBlank(childCase.Description) ? childCase.Description : ''));
        emailBody = emailBody.replace('{!Case.Updated_Case_Comments__c}',(childCase.Updated_Case_Comments__c!='' && String.isNotBlank(childCase.Updated_Case_Comments__c) ? childCase.Updated_Case_Comments__c : ''));
        emailBody = emailBody.replace('{!Case.Subject}', (childCase.Subject!='' && String.isNotBlank(childCase.Subject) ? childCase.Subject : ''));
        emailBody = emailBody.replace('{!Case.Link}', recordLink);
        //replace \n with html break statement to add new line in email body
        emailBody = emailBody.replace('\\n','<br />');
        //tidy up to form clean html string for the email body
        emailBody = emailBody.replace('\\r','');
        emailBody = emailBody.replace('"','');
        //add html and body tags to create multi line email body
        emailBody = '<html><body>'+emailBody+'</body></html>';
        singleEmail.setHtmlBody(emailBody);
        //return the formed email body
        return singleEmail;
    }
}