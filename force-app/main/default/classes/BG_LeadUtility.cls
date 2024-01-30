/**************************************************
Type:       Utility Class for Lead Object
Purpose:    The assignment of Lead Owners            
History:
Test Class:BG_LeadUtilityTest
--------------------------------------------------
28-01-2020      Jansi               Created
23-07-2020      Victor Cheng        Added Send notification email code
17-01-2020      Suman Gunaganti     Methods to support HVS functionality 
05-03-2020      Suman Gunaganti     Lead SLA fields logic update
01-10-2021	Seth Heang	    Uplift SF API version to 52
08-04-2022      Naveen Rajanna REQ2804764 - Remove debug and Add null check to prevent nullpointerexception
**************************************************/

public with sharing class BG_LeadUtility {
    public final static String LEAD_ASSIGNED_EMAIL_TEMPLATE = 'Lead Assigned Notification to Manager';

    
    @InvocableMethod(label='Map Lead Owners' description='Assign the Lead owners based on mapping criteria')
    public static void  assignLeadOwner(List<ID> ids) {
        //System.Debug('assignLeadOwner --- START');
        if(ids != null && ids.size() > 0){
            List<Lead> leadsList = [SELECT Id, Product__c, Opportunity_Initial_Estimate__c, PostalCode
            FROM Lead
            WHERE Id in :ids];
            //System.Debug('leadsList='+leadsList);
            if(leadsList !=null && leadsList.size() > 0) {
                assignSalesRep(leadsList);
            }
        }
        //System.Debug('assignLeadOwner --- END');
    }
    
    public static void assignSalesRep (List <Lead> leadList ){  
        //System.Debug('assignSalesRep --- START');

        // list of leads to updated in single DML
        List <Lead> leadUpdateList = new List <Lead>();

        // list of postcodes to search for
        List <String> postCodeList = new List<String>();
        Boolean isFound = false ;

        // collate the post codes
        for (Lead tmpLead: leadList){
            postCodeList.add(tmpLead.PostalCode);
        }

        // begin processing
        if (!leadList.isEmpty()){
            //System.Debug ('############# Started getting territory matrix ###############');

            // SOQL for territory assignment matrix records
            List <Territory_Assignment_Matrix__c> territoryList = [
                    SELECT Post_Code__c, Sales_Team__c, Sales_Team_Member__c,
                            High_Threshold_amount__c, Low_Threshold_Amount__c, Product__c,
                            Sales_Team_Member__r.Email
                    FROM Territory_Assignment_Matrix__c
                    WHERE Post_Code__c in : postCodeList];
            //System.Debug('territoryList='+territoryList);
            String defaultSalesRep = ConfigSetting__c.getInstance().OpportunityDriverDefaultUserId__c;
            //System.Debug('defaultSalesRep='+defaultSalesRep);

            // 2020/07/23 vcheng - adding notification email
            Id emailTemplateId = getLeadAssignEmailTemplateId();
            // the list of emails to send
            List<Messaging.Email> managerNotificationEmails = new List<Messaging.Email>();

            // loop through the leads
            for (Lead tmpLead: leadList)
            {
                // try to find a matching territory and sales rep based on postcode, estimate, product
                for (Territory_Assignment_Matrix__c tmpTerritory : territoryList){
                    if(tmpTerritory.Post_Code__c ==tmpLead.PostalCode){
                        
                        //Assumption here is that Low and High reference values will be set up correctly, eg
                        //Low - 0, High - 40000.99
                        //Low - 40001, High - 80000.99
                        //Low - 80001, High - null
                        //Increased coverage of threshold amount. Added >= and <= condition.
                        if (tmpLead.Opportunity_Initial_Estimate__c >= tmpTerritory.Low_Threshold_Amount__c &&
                            (tmpLead.Opportunity_Initial_Estimate__c <= tmpTerritory.High_Threshold_amount__c ||
                             tmpTerritory.High_Threshold_amount__c == null) && tmpLead.Product__c == tmpTerritory.Product__c)
                        {
                            //System.Debug('*****LOW: ' + tmpTerritory.Low_Threshold_Amount__c);
                            //System.Debug('*****HIGH: ' + tmpTerritory.High_Threshold_amount__c);

                            // if territory is found, assign the territory's sales rep as owner
                            tmpLead.OwnerId= tmpTerritory.Sales_Team_Member__c ;
                            leadUpdateList.add(tmpLead);
                            isFound=true;

                            // 2020/07/23 VC adding the actual sales reps to a list to add the emails later
                            if(emailTemplateId != null)
                            {
                                // create the email message
                                Messaging.SingleEmailMessage notificationEmail = makeEmailMessage(tmpLead, emailTemplateId, tmpTerritory.Sales_Team_Member__r.Email);
                                managerNotificationEmails.add(notificationEmail);
                            }
                            break;
                         }
                    }
                }

                // if no territory is matched, assign to default
                if (isFound<>true){
                    tmpLead.OwnerId= defaultSalesRep;
                    leadUpdateList.add (tmpLead);
                }
                isFound=false;
            }
            //System.Debug('####### leadUpdateList= #######' + leadUpdateList);

            // DML to update the processed leads
            if (!leadUpdateList.isEmpty()) {
                update leadUpdateList;
            }

            // 2020/07/23 VC Send the emails
            if(emailTemplateId != null)
            {
                //System.Debug('BG_LeadUtility:: Notification Emails ' + managerNotificationEmails);
                Messaging.sendEmail(managerNotificationEmails);
            }
            else
            {
                //System.Debug('BG_LeadUtility:: Email Template ' + LEAD_ASSIGNED_EMAIL_TEMPLATE + ' not found');
            }

        }

        //System.Debug('assignSalesRep --- END');
    }


    /**
     * @return The Id of the Email Template for sending these notification emails
     */
    public static Id getLeadAssignEmailTemplateId()
    {
        // email template
        List<EmailTemplate> leadTemplates = [SELECT Id, Subject, HtmlValue, Body
        FROM EmailTemplate
        WHERE Name =: LEAD_ASSIGNED_EMAIL_TEMPLATE
        LIMIT 1];

        // Early out if no template found
        if(leadTemplates.size() != 1) {
            // If the template is not found, return null, let the calling method handle it
            return null;
        }
        Id leadTemplateId = leadTemplates[0].Id;
        return leadTemplateId;
    }


    /**
     * @param updatedLead the Lead to send the email for
     * @param emailTemplateId the email template
     * @param salesRepEmail the email of the recipient
     *
     * @return
     */
    public static Messaging.SingleEmailMessage makeEmailMessage(Lead updatedLead, Id emailTemplateId, String salesRepEmail)
    {
        Messaging.SingleEmailMessage notificationEmail = new Messaging.SingleEmailMessage();
        // create the email
        notificationEmail.setToAddresses(new List<String>{salesRepEmail});
        notificationEmail.setSenderDisplayName('Australia Post');
        notificationEmail.setReplyTo('noreply@auspost.com.au');
        notificationEmail.setTemplateId(emailTemplateId);
        notificationEmail.setTargetObjectId(updatedLead.Id);
        notificationEmail.setTreatTargetObjectAsRecipient(false);
        //notificationEmail.setWhatId(updatedLead.Id);
        notificationEmail.saveAsActivity = false;
        return notificationEmail;
    }

     /**
      * @description       Method to run validation on lead fields
      * @param             List <lead> leadList
      * @return            Void
      */ 
      public static void validateLeadFields(List <lead> leadList){
        Map<Id, RecordType> leadRecordTypeMap = RecordTypesSelector.newInstance().selectBySObject('Lead');
        for (Lead leadrec : leadList){
            List<String> fieldsWithoutValues = new List<String>();
            if(('Verified'.equalsIgnoreCase(leadrec.Status) || 'Qualified'.equalsIgnoreCase(leadrec.Status) || 'mypost business'.equalsIgnoreCase(leadrec.Status))
            && (leadRecordTypeMap.get(leadrec.RecordTypeId)?.DeveloperName == 'BG_Standard' || leadRecordTypeMap.get(leadrec.RecordTypeId)?.DeveloperName == 'StarTrack_Lead'))
            {
                if (String.isBlank(leadrec.FirstName)) {
                    fieldsWithoutValues.add('First Name');
                }
                if(String.isBlank(leadrec.LastName)){
                    fieldsWithoutValues.add('Last Name');
                }
                if (String.isBlank(leadrec.Email)) {
                    fieldsWithoutValues.add('Email');
                }
                if(String.isBlank(leadrec.Street) 
                    || String.isBlank(leadrec.City) 
                    || String.isBlank(leadrec.State)
                    || String.isBlank(leadrec.PostalCode)){
                    fieldsWithoutValues.add('Address with Postal Code');
                }
                if (String.isBlank(leadrec.Customer_Type__c)) {
                    fieldsWithoutValues.add('Customer Type');
                }
                if (String.isBlank(leadrec.Phone) && String.isBlank(leadrec.MobilePhone)) {
                    fieldsWithoutValues.add('either \'Phone or Mobile\'');
                }
            }
            if (!fieldsWithoutValues.isEmpty()) {
                String errorMessage = '';
                Integer length = fieldsWithoutValues.size();
                String last = fieldsWithoutValues.remove(length-1);
                errorMessage = length >= 2? String.join(fieldsWithoutValues, ', ') + ' and ' + last:last;
                errorMessage = 'Please provide ' + errorMessage + ' prior to qualifying the Lead or converting the Lead into an Opportunity';
                leadrec.addError(errorMessage);
            }

        }
    }
    /**
      * @description       Method to verify in progress and qualified leads for sales cadence
      * @param             List <lead> newLeadList, Map <Id, lead> oldLeadList
      * @return            Void
      */ 
      public static void verifyLeadsforSalesCadence(List <lead> newLeadList, Map<id,lead> oldLeadMap){
        Map<Id, RecordType> leadRecordTypeMap = RecordTypesSelector.newInstance().selectBySObject('Lead');
        List<Lead> leadsForcadence = new List<Lead>();
        List<Lead> disqualifiedLeads = new List<Lead>();
        List<Id> leadOwnersList = new List<Id>();
        for (Lead leadrec : newLeadList) {
            Lead oldLead = oldLeadMap?.get(leadrec.Id);
            //Collect In Progress and Qualified leads
            if (leadrec.RecordTypeId != null && leadRecordTypeMap.get(leadrec.RecordTypeId).DeveloperName == 'BG_Standard' &&
                leadrec.OwnerId.getSobjectType() == Schema.User.SObjectType &&
                leadrec.OwnerId <> leadrec.CreatedById &&
                (leadrec.OwnerId <> oldLead?.ownerId || leadrec.Status <> oldLead?.Status) &&
                ('Qualified'.equalsIgnoreCase(leadrec.Status) || 'In Progress'.equalsIgnoreCase(leadrec.Status))) {
                    leadsForcadence.add(leadrec);
                    leadOwnersList.add(leadrec.OwnerId);
            }
            else if (leadrec.RecordTypeId != null && leadRecordTypeMap.get(leadrec.RecordTypeId).DeveloperName == 'BG_Standard' &&
                    leadrec.Status <> oldLead?.Status &&
                    'Disqualified'.equalsIgnoreCase(leadrec.Status)) {
                    disqualifiedLeads.add(leadrec);
            }
        }
        if (!leadsForcadence.isEmpty()) {
            triggerSalesCadence(leadsForcadence, leadOwnersList);
        }
        if (!disqualifiedLeads.isEmpty()) {
            removeLeadsFromCadence(disqualifiedLeads);
        }
      }

    /**
      * @description       Method to initiate sales cadence for in progress and qualified leads
      * @param             List <lead> leadsForcadence, List <Id> leadOwnersList
      * @return            Void
      */ 
    public static void triggerSalesCadence(List<Lead> leadsForcadence, List<Id>leadOwnersList){
        
        List<SalesCadenceEvent__e> cadenceEvents = new List<SalesCadenceEvent__e>();
        Map<Id,GroupMember> groupMbrMap = getGroupMembers(new Set<String>{'Sales_Managers'});
        Map<Id,ActionCadenceTracker> cadenceTrackers = getCadenceTrackers(leadsForcadence);
        Map<Id,PermissionSetLicenseAssign> licenseAssigneeMap = getLicenseAssignees('HighVelocitySalesPsl');
        LeadSettings__c leadSetting = LeadSettings__c.getOrgDefaults();
        Map<Id,User> userMap = new Map<Id,User>([SELECT Id, UserRoleId FROM User WHERE Id in :leadOwnersList]);

        for (Lead tmpLead : leadsForcadence) {
            if ((!groupMbrMap.containsKey(tmpLead.OwnerId) && !groupMbrMap.containsKey(userMap.get(tmpLead.OwnerId).UserRoleId)) &&
                (Test.isRunningTest() || licenseAssigneeMap.containsKey(tmpLead.OwnerId)) &&
                String.isNotEmpty(leadSetting.LeadCadence__c)) {
                    SalesCadenceEvent__e event = new SalesCadenceEvent__e();
                    if (!cadenceTrackers.containsKey(tmpLead.Id)) {
                        event.ActionType__c = 'AddToCadence';
                        event.CadenceNameOrId__c  = leadSetting.LeadCadence__c;
                        event.TargetId__c = tmpLead.Id;
                        event.UserId__c = tmpLead.OwnerId;
                    } else if(cadenceTrackers.get(tmpLead.Id).ownerId <> tmpLead.OwnerId){
                        event.ActionType__c = 'ChangeTargetAssignee';
                        event.UserId__c = tmpLead.OwnerId;
                        event.TargetId__c = tmpLead.Id;
                    }
                    cadenceEvents.add(event);
            }
        }
        if(!cadenceEvents.isEmpty())
            List<Database.SaveResult> results = EventBus.publish(cadenceEvents);
    }
    /**
    * @description       Method to remove lead from sales cadence for Disqualified leads
    * @param             List <lead> leadsForcadence
    * @return            Void 
    */ 
    public static void removeLeadsFromCadence(List<Lead> disqualifiedLeads){
        List<SalesCadenceEvent__e> cadenceEvents = new List<SalesCadenceEvent__e>();
        Map<Id,ActionCadenceTracker> cadenceTrackers = getCadenceTrackers(disqualifiedLeads);

        for(Lead tmpLead : disqualifiedLeads) {
            if(cadenceTrackers.containsKey(tmpLead.Id)){
                SalesCadenceEvent__e event = new SalesCadenceEvent__e();
                    event.ActionType__c = 'RemoveTarget';
                    event.TargetId__c = tmpLead.Id;
                    event.CompletionReason__c = 'ManuallyRemoved';
                    cadenceEvents.add(event);
            }
        }
        if(!cadenceEvents.isEmpty())
            List<Database.SaveResult> results = EventBus.publish(cadenceEvents);
    }
    /**
      * @description       This method populates Lead SLA field values
      * @param             List <lead> newLeadList, Map <Id, lead> oldLeadList
      * @return            void
      * @throws            NA
      */ 
    public static void populateLeadSLAFields(List<Lead> leadRecords, Map<Id,Lead> oldLeadMap){
        Map<Id, RecordType> leadRecordTypeMap = RecordTypesSelector.newInstance().selectBySObject('Lead');
        List<Id> leadOwnerIdChangeList = new List<Id>();
        Set<String> reopenedleadStatuses = new Set<String>{'Disqualified', 'Duplicate lead', 'Information only', 'MyPost Business'};
        Map<Id,GroupMember> groupMbrMap = new Map<Id,GroupMember>();
        Set<Id> ownersList = new Set<Id>();
        Map<Id,User> userMap;
        Map<Id,Group> queueMap;

        // Verifies whether lead owner is changed
        for(Lead l : leadRecords){
            Lead oldLead = oldLeadMap?.get(l.Id);
            //Verify lead Owner is populated 
            if(leadRecordTypeMap.get(l.RecordTypeId)?.DeveloperName == 'BG_Standard' &&
               l.OwnerId <> oldLead?.OwnerId){

                leadOwnerIdChangeList.add(l.Id);
                ownersList.add(l.OwnerId);
            }
        }
        if(!leadOwnerIdChangeList.isempty()){
            groupMbrMap = getGroupMembers(new Set<String>{'Sales_Managers', 
                                                           'Account_Managers', 
                                                           'Lead_Vero_Group'});
            userMap = new Map<Id,User>([SELECT Id, UserRoleId FROM User WHERE Id in :ownersList]);
            queueMap = new Map<Id, Group>([SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' And DeveloperName IN('MyPost_Bus_Leads', 'TSA_Leads_Queue')]);
        }
        // Populate SLA values 
        for(Lead tempLead : leadRecords){
            Lead oldLead = oldLeadMap?.get(tempLead.Id);
            // check if lead owner is changed and memeber of a public group
            if(leadOwnerIdChangeList.contains(tempLead.Id) ){
                if(groupMbrMap.containsKey(tempLead.OwnerId)||
                    groupMbrMap.containsKey(userMap.get(tempLead.OwnerId)?.UserRoleId)){
                    //Get either user or role based on group or queue membership
                    String userOrRoleId = groupMbrMap.containsKey(tempLead.OwnerId)? tempLead.OwnerId : userMap.get(tempLead.OwnerId).UserRoleId;
                    
                    switch on groupMbrMap.get(userOrRoleId).Group.DeveloperName {
                        when 'Sales_Managers' {
                            tempLead.Assigned_to_Sales_Manager__c = System.Now();
                        }
                        when 'Account_Managers' {
                            tempLead.Assigned_to_Account_Manager__c = System.Now();
                        }
                        when 'Lead_Vero_Group' {
                            tempLead.Assigned_to_lead_vero__c = System.now();
                        }
                    }
                }
                else if(queueMap.containsKey(tempLead.OwnerId))
                    tempLead.Assigned_to_Sales_Manager__c = System.Now();
            }
            //check if lead converted or disqualified, adding null check on oldLead.Status for consistency
            if((tempLead.IsConverted && !oldLead?.IsConverted) || 
                ('Disqualified'.equalsIgnoreCase(tempLead.Status) && tempLead.Status <> oldLead?.Status)){
                    tempLead.Lead_Converted_or_Disqualified_Time__c  = System.now();
            }
            // check if lead reopened 
            if(tempLead.Status <> oldLead?.Status && 
                reopenedleadStatuses.contains(oldLead?.Status) &&
                !reopenedleadStatuses.contains(tempLead.Status)){
                    tempLead.Lead_Re_Opened__c  = True;
            }

        }
        
    }
    /**
      * @description       This method returns group members based on group names
      * @param             Set<String> - grpNames
      * @return            Map<Id,GroupMember>
      * @throws            NA
      */        
    public static Map<Id,GroupMember> getGroupMembers(Set<String> grpNames){
        Map<Id,GroupMember> grpMbrMap = new Map<Id,GroupMember>();
        Set<Id> roleGroups = new Set<Id>();
        Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());

        for(GroupMember mbr : [SELECT Id,UserOrGroupId,GroupId, Group.DeveloperName FROM GroupMember WHERE Group.DeveloperName IN: grpNames ORDER BY GroupId 
                                LIMIT : rowLimit]){
            grpMbrMap.put(mbr.UserOrGroupId,mbr);
        }
        for(Group grp:[SELECT Id,RelatedId FROM Group where Id IN:grpMbrMap.keySet() AND type = 'Role']){
            GroupMember tmpGmp = grpMbrMap.remove(grp.Id);
            grpMbrMap.put(grp.RelatedId, tmpGmp);
        }
        return grpMbrMap;
    }

    /**
      * @description       This method returns license assignees based on License name
      * @param             Set<String> - licenseName
      * @return            Map<Id,PermissionSetLicenseAssign>
      * @throws            NA
      */        
    public static Map<Id,PermissionSetLicenseAssign> getLicenseAssignees(String licenseName){
        Map<Id,PermissionSetLicenseAssign> licenseAssigneeMap = new Map<Id,PermissionSetLicenseAssign>();
        Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());
        for(PermissionSetLicenseAssign licenseAssignee : [SELECT Id,AssigneeId FROM PermissionSetLicenseAssign WHERE PermissionSetLicense.DeveloperName = :licenseName
                                LIMIT : rowLimit]){
            licenseAssigneeMap.put(licenseAssignee.AssigneeId,licenseAssignee);
        }
        return licenseAssigneeMap;
    }

    /**
      * @description       This method returns running and paused cadence tracker instances based on leads
      * @param             List<Lead> - listOfLeads
      * @return            Map<Id,ActionCadenceTracker>
      * @throws            NA
      */ 
    public static Map<Id, ActionCadenceTracker> getCadenceTrackers(List<Lead> listOfLeads){
        Map<Id, ActionCadenceTracker> cadenceTrackers = new Map<Id, ActionCadenceTracker>();
        for (ActionCadenceTracker tracker : [SELECT Id,TargetId, CompletionReason, OwnerId FROM ActionCadenceTracker 
                                            WHERE TargetId IN :listOfLeads AND
                                            State IN ('Running','Paused')]) {
            cadenceTrackers.put(tracker.TargetId, tracker);
        }
        return cadenceTrackers;
    }
}