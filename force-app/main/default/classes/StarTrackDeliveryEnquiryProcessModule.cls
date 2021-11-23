/**
* @description
* Domain Module to handle the Startrack Delivery Enquiry Process | PBRP 2021
* Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
*
* This has been a port of parts of the Startrack Delivery Enquiry Process. It deals with the following nodes:
* 1.Create No Data Activity - Creates a Task after a case is inserted/updated
* 2.Update No Data Flag - updates to FALSE before a case is inserted/updated
* 3.Update Consignment Shortage Flag - updates to FALSE before a case is inserted/updated
* 4.StarTrack Shortage Request Approval - submits for approval before a case is inserted/updated
*
* NOTE: The is wrapped in a domain class that filters all cases based on StarTrack cases only!
*      The cases passed through this module should only ever be StarTrack Cases!!
*
* @author Madhusudhan
* @date 2021-06-30
* @group Domain
* @domain StarTrack
* @changelog
*/
public inherited sharing class StarTrackDeliveryEnquiryProcessModule extends ApplicationDomain.Module {
    
    public static StarTrackDeliveryEnquiryProcessModule newInstance() {
        return (StarTrackDeliveryEnquiryProcessModule)Application.Utilities.newInstance(StarTrackDeliveryEnquiryProcessModule.class);
    }
    
    // Lists to hold the records to be processed for approval and Task creation in after triggers
    public static List<Case> casesToCreateActivity = new List<Case>();
    public static List<Case> casesToSubmitForApproval = new List<Case>();

    // Setup which triggers this module should respond to
    public StarTrackDeliveryEnquiryProcessModule() {
        getTriggerEvents().enableBeforeInsert().enableAfterInsert().enableBeforeUpdate().enableAfterUpdate();
    }
    
    /**
    * Grab Delivery Enquiry RecordTypeId
    */
    public static Id deliveryEnquiryRecordTypeId {
        get {
            if(deliveryEnquiryRecordTypeId == null) {
                deliveryEnquiryRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{'StarTrack_PUD_Enquiry'}).values()[0].Id;
            }
            return deliveryEnquiryRecordTypeId;
        }
        private set;
    }

    /**
    * Grab StarTrack Activity RecordTypeId
    */
    public static Id starTrackActivityRecordTypeId {
        get {
            if(starTrackActivityRecordTypeId == null) {
                starTrackActivityRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Task', new Set<String>{'StarTrack_Activity'}).values()[0].Id;
            }
            return starTrackActivityRecordTypeId;
        }
        private set;
    }
    
    /**
    * Grab current user id
    */
    public static String currenrUserId {
        get {
            if(currenrUserId == null) {
                currenrUserId = UserInfo.getUserId();
            }
            return currenrUserId;
        }
        private set;
    }
     
    /**
    * Called when a new Case is being inserted.
    * Checks for the No_Data_Change__c/Consignment_Shortage__c flags to determine whether 
    * an Activity/Task has to be created or the case has to be submitted for approval(because of Incorrect Delivery)
    */
    public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
        try {
            System.debug('StarTrackDeliveryEnquiryProcessModule:onBeforeInsert');
            if (!records.isEmpty()) {
                // Updates the No_Data_Change__c/Consignment_Shortage__c to false for StarTrack Delivery Enquiry cases
                updateNodataOrConsignmentFlag((List<Case>) records);
            }
            
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackDeliveryEnquiryProcessModule.class.getName(), 'onBeforeInsert', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }
    
    /**
    * Called when a new Case is being updated.
    * Checks for the No_Data_Change__c/Consignment_Shortage__c flags to determine whether 
    * an Activity/Task has to be created or the case has to be submitted for approval(because of Incorrect Delivery)
    */
    public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        try {
            System.debug('StarTrackDeliveryEnquiryProcessModule:onBeforeUpdate');
            // Checking for casesToCreateActivity and casesToCreateActivity to be empty
            // to avoid the method call from Insert Operation resulting in calling update triggers
            if (!records.isEmpty() && casesToCreateActivity.isEmpty() && casesToCreateActivity.isEmpty()) {
                // Updates the No_Data_Change__c/Consignment_Shortage__c to false for StarTrack Delivery Enquiry cases
                updateNodataOrConsignmentFlag((List<Case>)records);   
            }
            
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackDeliveryEnquiryProcessModule.class.getName(), 'onBeforeUpdate', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }

    /**
    * Called after a case is inserted.
    * Performs below operations
    * 1. Creates Activity/Task under the case
    * 2. Submits a record for approval in case of Incorrect Delivery/Items shortage 
    */
    public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
        try {
            System.debug('StarTrackDeliveryEnquiryProcessModule:onAfterInsert');
            // Creates Activity/Task under the case
            if(!casesToCreateActivity.isEmpty()) {
                createNoDataActivity(uow);
            }
            // Submits a record for approval in case of Incorrect Delivery/Items shortage 
            if(!casesToSubmitForApproval.isEmpty()) {
                submitForApproval();     
            }   
            
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackDeliveryEnquiryProcessModule.class.getName(), 'onAfterInsert', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }
   
    /**
    * Called after a Case is updated. 
    * Performs below operations
    * 1. Creates Activity/Task under the case
    * 2. Submits a record for approval in case of Incorrect Delivery/Items shortage 
    */
    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        try {
            System.debug('StarTrackDeliveryEnquiryProcessModule:onAfterUpdate');
            // Creates Activity/Task under the case
            if(!casesToCreateActivity.isEmpty()) {
                createNoDataActivity(uow);
            }
            // Submits a record for approval in case of Incorrect Delivery/Items shortage 
            if(!casesToSubmitForApproval.isEmpty()) {
                submitForApproval();     
            }
            
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackDeliveryEnquiryProcessModule.class.getName(), 'onAfterUpdate', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }
    
    /**
    * Called from beforeInsert() and beforeUpdate(), updates No_Data_Change__c and Consignment_Shortage__c to FALSE
    * NOTE: This method should not be called in the scenario where, Insert Operation resulting in calling update triggers
    */
    public void updateNodataOrConsignmentFlag(List<Case> records) {
        
        Set<String> excludedApprovalStatuses = new Set<String>{ 'Shortage Request Submitted', 'Shortage Request Approved' };
        Set<String> includedEnquiryTypes = new Set<String>{ 'Short - No Scan', 'Short - Scanned', 'Incorrect Delivery' };
        
        for (Case record : records) {
            
            if (record.RecordTypeId == deliveryEnquiryRecordTypeId) {
                // From the decison node (No Data Consignment )
                // Creates Activity(Task) under the case with subject as "No Data supplemented by caller" 
                if (record.No_Data_Change__c && record.Number_of_No_Data_Consignment_Updates__c > 0) {
                    // Set No data Change to FALSE so that only activity is created.
                    record.No_Data_Change__c = FALSE;
                    // No data change is true and Number of No data consignment updates is more than 0 
                    // add the case to the list of cases for which Activity/Task has to be created
                    casesToCreateActivity.add(record);   
                // From the decison node (Shortage Request Submitted)
                } else if (record.Consignment_Shortage__c && !excludedApprovalStatuses.contains(record.Approval_Status__c) && includedEnquiryTypes.contains(record.Enquiry_Type__c)) {         
                    // Set Consignment Shortage to FALSE so that the case is submitted for approval only once.
                    record.Consignment_Shortage__c = FALSE;
                    // Some issue with the Delivery/Items shortage so case needs to be approved
                    // add the case to the list of cases which have to be submitted for approval
                    casesToSubmitForApproval.add(record);
                } 
            }
        }
    }
    
    /**
    * Called from afterInsert() and afterUpdate(), Submits the cases for approval 
    * From the decision node (Shortage Request Submitted)
    * Submits a record for approval in case of Incorrect Delivery/Items shortage
    * NOTE: This method should not be called in the scenario where, Insert Operation resulting in calling update triggers
    */
    public void submitForApproval() {
        
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        List<Case> casesToProcess = casesToSubmitForApproval.clone();
        // Clearing the list as the approval process makes field updates which were triggering before and after update triggers.
        casesToSubmitForApproval.clear();
        for(Case caseRecord : casesToProcess)
        {
            Approval.ProcessSubmitRequest request =  new Approval.ProcessSubmitRequest();
            request.setComments('Submitting request for approval:'+caseRecord.id);
            request.setObjectId(caseRecord.id);        
            // Submit on behalf of a specific submitter
            request.setSubmitterId(currenrUserId); 
            // Submit the record to specific process and skip the criteria evaluation
            request.setProcessDefinitionNameOrId('StarTrack_Shortage_Request');
            // Submit the approval request for the account
            requests.add(request);
        }
        Approval.ProcessResult[] result = Approval.process(requests);
        // Verify the result
        System.debug('ResultOfSubmitForApproval==>'+result[0].getInstanceStatus());
    }

    /**
    * This is called from afterInsert() and afterUpdate() 
    * From the decision node (No Data Consignment)
    * Creates Activity/Task under the case
    * NOTE: This method should not be called in the scenario where, Insert Operation resulting in calling update triggers 
    */
    public void createNoDataActivity(ApplicationUnitOfWork uow) {
        List<Task> tasksToBeCreated = new List<Task>();
        for(Case caseRecord : casesToCreateActivity){
            // Define a task record which needs to be created
            Task noDataActivity = new Task();
            noDataActivity.Status = 'Completed';
            noDataActivity.CaseObject__c = caseRecord.Id;
            noDataActivity.RecordTypeId = starTrackActivityRecordTypeId;
            noDataActivity.WhatId = caseRecord.Id;
            noDataActivity.OwnerId = caseRecord.OwnerId;
            noDataActivity.Subject = 'No Data supplemented by caller';
            noDataActivity.Description = 'No Data supplemented by caller';
            noDataActivity.Priority = 'Normal';
            tasksToBeCreated.add(noDataActivity);
        }
        uow.registerNew(tasksToBeCreated, false, 'StarTrackDeliveryEnquiryProcessModule');
        // Reset list after operation
        casesToCreateActivity.clear();
    }
        
    /**
    * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
    */
    public class Constructor implements ApplicationDomain.IConstructableModule {
        public ApplicationDomain.Module construct() {
            return (ApplicationDomain.Module)StarTrackDeliveryEnquiryProcessModule.newInstance();
        }
    }  
}