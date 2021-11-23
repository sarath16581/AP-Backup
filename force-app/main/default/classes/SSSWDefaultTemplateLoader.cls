/***************************************************************************************************
Author:        David Catindoy
Company:       Cloud Sherpas
Description:   Email Quick Action Handler
Purpose:       This Default Email Template Handler determines the Email Template based on the Record Type name values from the Custom Settings - StarTrack Settings.
               All Case Record Types that require specific Email Template must be specified in the Custom Settings - StarTrack Settings.
History:
-----------------------------------------------------------------------------------------
unknown         David Catindoy
March 1, 2016   David Catindoy - Modified
11.06.1018      TDO-223 - kalpita.talwadekar@auspost.com.au   updated code for coding standard follow
***************************************************************************************************/
global class SSSWDefaultTemplateLoader implements QuickAction.QuickActionDefaultsHandler {

    global SSSWDefaultTemplateLoader (){
        // Empty constructor
    }

    /** 
      * @name: onInitDefaults()
      * @desciption: method to initialize the email template settings
      * @param: List<QuickAction.QuickActionDefaults> defaults
      * @return: NA
      *
      */
    public void onInitDefaults(List<QuickAction.QuickActionDefaults> defaults){  
        //call the method for setting defaults on email quick action
        QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = getSendEmailQuickAction(defaults);

        //if these email defaults are found
        if(sendEmailDefaults != null) {  

            //then query the current case details
            Case caseRec = [
                SELECT
                    Id, CaseNumber, StarTrack_RecordType__c,
                    StarTrack_Calc_Email_Address__c,
                    ArticleTest__c, StarTrack_From_Address__c,
                    RecordType.Name, RecordType.DeveloperName
                FROM
                    Case
                WHERE
                    Id =: sendEmailDefaults.getContextId()
            ];

            //setup the email message based on email message default settings
            EmailMessage emailMessage = (EmailMessage) sendEmailDefaults.getTargetSObject();

            //if it is startrack case
            if(caseRec.StarTrack_RecordType__c){
                emailMessage.FromAddress = caseRec.StarTrack_From_Address__c;
            }
            // set the template id
            sendEmailDefaults.setTemplateId(getTemplateId(caseRec));

            //for all ST recordtypes, set the template details
            if(caseRec.RecordType.DeveloperName.contains('StarTrack')){
                sendEmailDefaults.setInsertTemplateBody(true);
                sendEmailDefaults.setIgnoreTemplateSubject(true);
            }

            //call method for attachment details on template for current case
            prepareCaseAttachments(caseRec.Id, caseRec.ArticleTest__c);    
        }
    }  
    
    /** 
      * @name: getSendEmailQuickAction()
      * @desciption: method for setting defaults on email quick action
      * @param: ApexPages.StandardController controller
      * @return: QuickAction.SendEmailQuickActionDefaults
      *
      */
    public QuickAction.SendEmailQuickActionDefaults getSendEmailQuickAction(List<QuickAction.QuickActionDefaults> defaults) {   
        //loop through the quick actions defaults
        for(QuickAction.QuickActionDefaults defaultSetting : defaults) {

            //return the specific email quick action for case object
            if(defaultSetting instanceof QuickAction.SendEmailQuickActionDefaults && 
                    defaultSetting.getTargetSObject().getSObjectType() == EmailMessage.sObjectType && 
                    defaultSetting.getActionName().equals('Case.Email') && 
                    defaultSetting.getActionType().equals('Email')){
                return (QuickAction.SendEmailQuickActionDefaults) defaultSetting;
            }
        }
        return null;
    }
  
    /** 
      * @name: getTemplateId()
      * @desciption: method to return the right template details based on case type AP or ST or other
      * @param: Case theCase
      * @return: Id
      *
      */
    global Id getTemplateId(Case theCase){
        //get all ST email details from custom settings
        Map<String, StarTrack_Default_Email_Template__c> defaultEmailTemplate = StarTrack_Default_Email_Template__c.getAll();
        
        //if it is a SSSW case
        if(theCase.RecordType.DeveloperName.contains('SSSW') &&
                defaultEmailTemplate.containsKey('SSSW') &&
                defaultEmailTemplate.get('SSSW').Email_Template_Name__c != null){

            return queryEmailTemplate(defaultEmailTemplate.get('SSSW').Email_Template_Name__c);

        } else if(defaultEmailTemplate.containsKey(theCase.RecordType.Name)){

            if(defaultEmailTemplate.get(theCase.RecordType.Name).Email_Template_Name__c == null){
                return null;
            }
            return queryEmailTemplate(defaultEmailTemplate.get(theCase.RecordType.Name).Email_Template_Name__c);

        } else if(theCase.RecordType.DeveloperName.contains('StarTrack') &&
                defaultEmailTemplate.containsKey('StarTrack') &&
                defaultEmailTemplate.get('StarTrack').Email_Template_Name__c != null){ //if it is a startrack case

            return queryEmailTemplate(defaultEmailTemplate.get('StarTrack').Email_Template_Name__c);
        } else{
            return null;
        }
    }
    
    /** 
      * @name: queryEmailTemplate()
      * @desciption: query the template from templateName
      * @param: String templateName
      * @return: NA
      *
      */
    public Id queryEmailTemplate(String templateName){
        try{
            //based on templateName get the template details
            EmailTemplate theTemplate = [ SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE DeveloperName = :templateName LIMIT 1 ];
            return theTemplate.Id; 
        } catch(Exception ex){
            return null;
        }
    }
    
    /** 
      * @name: prepareCaseAttachments()
      * @desciption: method to prepare the attachment details for current case
      * @param: Id caseId, Id conId
      * @return: NA
      *
      */
    public void prepareCaseAttachments(Id caseId, Id conId){
        Set<String> podIDs = new Set<String>();

        //query all case attachments
        List<Attachment> caseAttachments = [ SELECT Id, Name, Description FROM Attachment WHERE ParentId = :caseId];

        //check if there are any attachments present
        if(!caseAttachments.isEmpty()){ 
            for(Attachment att : caseAttachments){
                podIDs.add(att.Description);
            }
        }
        
        //if a contact exists
        if(String.isNotBlank(conId)){
            //get the POD details for the article based on contact id
            Article__c caseCon = [
                  SELECT
                        Id, Name,
                        (SELECT Id, Name FROM Proof_of_Deliveries__r WHERE Id NOT IN :podIDs)
                  FROM
                      Article__c
                  WHERE
                      Id = :conId
            ];
                                        
            Set<Id> podList = new Set<Id>();
            for(Proof_of_Delivery__c pod : caseCon.Proof_of_Deliveries__r){
                podList.add(pod.Id);
            }

            //query all POD attachments
            List<Attachment> podAttachments = [
                SELECT
                    Id, Name, Description, Body,
                    BodyLength, ContentType, IsPrivate, ParentId
                FROM
                    Attachment
                WHERE
                    ParentId IN :podList
            ];
            caseAttachments.clear();

            //loop through POD attachments and add to existing case attachments if any
            for(Attachment podAttach : podAttachments){
                Attachment newAttach = podAttach.clone(false, true, false, false);
                newAttach.Name = newAttach.Name;
                newAttach.Description = podAttach.ParentId;
                newAttach.ParentId = caseId;
                caseAttachments.add(newAttach);
            }

            // insert the case attachments
            insert caseAttachments;
        }
    }
}