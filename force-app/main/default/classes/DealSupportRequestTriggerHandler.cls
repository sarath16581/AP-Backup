/*****************************************************************************************
@description: Provide Email Routing and Email notification upon Submission of Deal Support Request of "Credit Management Request" record type
@author: Seth Heang
History:
-----------------------------------------------------------------------------------------
10/12/2020   	seth.heang@auspost.com.au			                created
17/02/2021   	seth.heang@auspost.com.au			                Uplift the routing logic for work type related to a formula field(Credit_Queue_Routing__c) on DSR and SSSW Routing table
15/03/2021   	seth.heang@auspost.com.au			                Fix the search logic on SSSWRouting Credit Person Code, from 'Contain' to 'Exact Match'
*****************************************************************************************/
public without sharing class DealSupportRequestTriggerHandler {
    
    /**
     * @description    handler method on 'After Update' trigger to check below criteria:
     *                  1. Record type = 'Credit Management Request'
     *                  2. Stage & Status = 'Submitted'
     *                 Then, call creditDSR_QueueRouting to route the DSR to appropriate queue
     * @param          List<Deal_Support_Request__c> Trigger.New, Map<Id,Deal_Support_Request__c> oldDSRMap
     * @return         void
     */
    public static void afterUpdateHandler(List<Deal_Support_Request__c> newDSRList, Map<Id,Deal_Support_Request__c> oldDSRMap){
        
        try{
            // retrieve the record type id of 'Credit Management Request' on DSR object
            Id recTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Deal_Support_Request__c', new Set<String>{'Credit_Management_Request'}).values()[0].Id;
            List<Deal_Support_Request__c> creditDSRlist = new List<Deal_Support_Request__c>();
            // Loop Trigger.New and check for Stage and Status = 'Submitted' and add to a list
            for(Deal_Support_Request__c dsr: newDSRList){
                if(dsr.RecordTypeId == recTypeId && dsr.Stage__c == 'Submitted' && dsr.Status__c == 'Submitted'
                && oldDSRMap.get(dsr.id).Stage__c != dsr.Status__c && oldDSRMap.get(dsr.id).Status__c != dsr.Stage__c){
                    creditDSRlist.add(dsr);
                }
            }
            // Perform Queue Routing on the credit DSR list
            if(creditDSRlist.size() > 0){
                creditDSR_QueueRouting(creditDSRlist);
            }
        }catch (Exception ex){
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Deal Support Request', 'DealSupportRequestTriggerHandler' , 'afterUpdateHandler', 'DealSupportRequestTrigger', LoggingLevel.ERROR);
        }
    }
    
    /**
     * @description    Route the DSR on Submission, to appropriate queue based on the associated 'Credit Person Code' within mapping logic stored in SSSWRouting object
     * @param          List<Deal_Support_Request__c> 
     * @return         void
     * @throws         Method might throw exception which is handled by Try-Catch block
     */
    public static void creditDSR_QueueRouting(List<Deal_Support_Request__c> creditDSRList){
        try{
            // retrieve the record type id of 'Credit DSR Routing' on SSSWRouting mapping object
            Id recTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('SSSWRouting__c', new Set<String>{'Credit_DSR_Routing'}).values()[0].Id;
            
            // Query the SSSWRouting mapping object and relevent field details under 'Credit DSR Routing' record type
            List<SSSWRouting__c> mappingObj = SSSWRoutingSelector.newInstance().selectByRecordTypeId(new Set<id>{recTypeId}).values();  
        
            //set up maps for dsrId-to-QueueName, and dsrId-to-Email
            Map<Id, String> dsrQueueMapping = new Map<Id, String>();
            Map<Id, String> dsrEmailMapping = new Map<Id, String>();
            Map<SSSWRouting__c, Deal_Support_Request__c> ssswTodsrMapping = new Map<SSSWRouting__c, Deal_Support_Request__c>();

            // Loop SSSWRouting object to compare the ledger code and obtain the Queue Name and Email, then save into respective maps
            for(SSSWRouting__c sssw : mappingObj){
                for(Deal_Support_Request__c dsr : creditDSRList){
                    // match the credit DSR routing logic
                    if(sssw.Credit_DSR_Routing__c == dsr.Credit_Queue_Routing__c){
                        // add SSSW->DSR mapping
                        ssswTodsrMapping.put(sssw, dsr);
                    }
                }
            }

            for(SSSWRouting__c ssswRec : ssswTodsrMapping.keyset()){
                Deal_Support_Request__c dsr = ssswTodsrMapping.get(ssswRec);

                // Split the credit person code entry(ie. 1A, 1B) into a List of individual code, parsed by comma
                List<String> creditCodeEntryList = new List<String>();
                if(String.ISBLANK(ssswRec.Credit_Person_Code__c) == FALSE){
                    creditCodeEntryList = ssswRec.Credit_Person_Code__c.split(',');
                }
                

                // Blank Credit Person Code, there is no email mapping
                if(ssswRec.Credit_DSR_Routing__c == 'Credit Person Code' &&
                    (String.isBlank(dsr.Credit_Person_Code__c) || dsr.Credit_Person_Code__c == null)){
                    dsrQueueMapping.put(dsr.id, ssswRec.DSR_Queue_Name__c);
                    continue;
                }
                // Routing logic based on Work Type where Credit_DSR_Routing__c is not 'Credit Person Code'
                else if(ssswRec.Credit_DSR_Routing__c != 'Credit Person Code'){
                    dsrQueueMapping.put(dsr.id, ssswRec.DSR_Queue_Name__c);
                    dsrEmailMapping.put(dsr.id, ssswRec.Credit_Representative_Email__c);
                    continue;
                }

                for(String eachCode : creditCodeEntryList){
                    // Compare the DSR's credit person code against the SSSWRouting's entry's sets of credit person code
                    if(ssswRec.Credit_DSR_Routing__c == 'Credit Person Code' && eachCode.trim().equalsIgnoreCase(dsr.Credit_Person_Code__c) 
                    && ( !String.isBlank(dsr.Credit_Person_Code__c) || dsr.Credit_Person_Code__c != null) ){
                        dsrQueueMapping.put(dsr.id, ssswRec.DSR_Queue_Name__c);
                        dsrEmailMapping.put(dsr.id, ssswRec.Credit_Representative_Email__c);
                    }
                }
            }

            // Set of invalid credit person code
            Set<Id> invalidLedgerDSRIdSet = new Set<Id>();
            for(Deal_Support_Request__c dsr : creditDSRList){
                // check if ID doesn't exist, means no match is found from SSSW Routing mapping table
                if(dsrQueueMapping.get(dsr.id) == null){
                    invalidLedgerDSRIdSet.add(dsr.id);
                }
            }
            // set up a map for QueueName-to-QueueId
            Map<String, Id> queueNameToIdMapping = new Map<String, Id>();
        	// set up a direct dsrId-to-QueueId map
            Map<id, id> dsrQueueIdMapping = new Map<id,id>();
            
            // DSR Credit Person Code has at least one match with existing code in the SSSW Routing table
            if(!dsrQueueMapping.isEmpty()){
                // Loop Queue based on QueueName and retrieve the QueueId and save to the map: QueueName-to-QueueId
                for(Group queue : GroupsSelector.newInstance().selectByGroupTypeAndName(new Set<String>{'queue'},new Set<String>(dsrQueueMapping.values())).values()){
                	queueNameToIdMapping.put(queue.name, queue.id);
            	}
                
                // Loop DSR and QueueName and save the mapping data into dsrId-to-QueueId map
                for(id dsrId : dsrQueueMapping.keyset()){
                    String dsrQueueName = dsrQueueMapping.get(dsrId);
                    for(String queueName : queueNameToIdMapping.keyset()){
                        if(dsrQueueName == queueName){
                            id queueId = queueNameToIdMapping.get(queueName);
                            dsrQueueIdMapping.put(dsrId, queueId);
                        }
                    }
                }
            }
            // set up a DSR list to be updated, fields including the OwnerId and Assigned_Team__c
            List<Deal_Support_Request__c> updateDSRlist = new List<Deal_Support_Request__c>();
            Set<Id> allDSRIdset = new Set<Id>();
            // Combined all DSR with matched and unmatched credit person code into a full set
            allDSRIdset.addall(dsrQueueIdMapping.keyset());
            allDSRIdset.addAll(invalidLedgerDSRIdSet);
            // Retrieve Queue for 'Unassigned Credit Management Requests', which is used for invalid credit person code
            Group qUnassignedDSR = GroupsSelector.newInstance().selectByGroupTypeAndDeveloperName(new Set<String>{'queue'},new Set<String>{'Unassigned_Credit_Management_Requests'}).values()[0];                                                                                                                              
            /**
             * Loop DSR and updating: 
             *  1. the DSR-to-Email map for Credit DSR that does not go to Queue
             *  2. fields: OwnerId, Assigned_Team__c for Credit DSR that is routed to appropriate queues
             *  */ 
            for(Deal_Support_Request__c dsr : DealSupportRequestsSelector.newInstance().selectById(allDSRIdset).values()){
                // flag invalid person code to true, when there is no match returned from SSSW Routing mapping table
                // And Update OwnerId to ‘Unassigned Credit Support Request’ queue and 'Assigned Team' picklist
                if(invalidLedgerDSRIdSet.contains(dsr.id)){
                    dsr.Invalid_Credit_Person_Code__c = true;
                    dsr.OwnerId = qUnassignedDSR.id;
                    dsr.Assigned_Team__c = qUnassignedDSR.name;
                }
                
                // Update OwnerId and 'Assigned Team' based on queue mapping from SSSW Routing table
                if(dsrQueueIdMapping.containskey(dsr.id)){
                    // Update OwnerId with QueueId from the SSSWRouting object
                    dsr.OwnerId = dsrQueueIdMapping.get(dsr.id);
                    // Update the Assign Team with Queue Name values, used for reporting
                    dsr.Assigned_Team__c = dsrQueueMapping.get(dsr.id);
                }
                // save updated details into the DSR list
                updateDSRlist.add(dsr);
                
            }
            // Perform Update on the updated DSR list, and send email notification based on the DSR-to-Email mapping
            if(updateDSRlist.size() > 0){
                ApplicationDatabase.getInstance().dmlUpdate(updateDSRlist);
                creditDSR_SendEmailNotification(updateDSRlist, dsrEmailMapping);
            }
        }catch(Exception ex){
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Deal Support Request', 'DealSupportRequestTriggerHandler' , 'creditDSR_QueueRouting', 'DealSupportRequestTrigger', LoggingLevel.ERROR);
        }
        
    }
    
    
    /**
     * @description    Send Email Notification, to appropriate 'Credit Representative Email' based on the associated 'Credit Person Code' within mapping logic stored in SSSWRouting object
     * @param          List<Deal_Support_Request__c>, Map<Id, String>
     * @return         void
     * @throws         Method might throw exception which is handled by Try-Catch block
     */
    public static void creditDSR_SendEmailNotification(List<Deal_Support_Request__c> updatedDSRList, Map<Id, String> dsrEmailMapping){
        try{
            for(Deal_Support_Request__c dsr: updatedDSRList){
                for(Id dsrId: dsrEmailMapping.keyset()){
                    String email = dsrEmailMapping.get(dsrId);
                    
                    // terminate the method if no email returned in the mapping (i.e. invalid ledger code case)
                    if(String.isBlank(email)){
                        return;
                    }
                    
                    // retrieve 'noreply@auspost.com.au' orgWideEmailAddress, so that Send From Address is 'noreply@auspost.com.au'
                    OrgWideEmailAddress owa = OrgWideEmailAddressSelector.newInstance().selectByAddress(BGSConstants.AUSPOST_NOREPLY_EMAIL).values()[0];
                    /**
                     * Limitation: 
                     *      > When using the existing shared 'text' Email template for other DSR, Salesforce require a Contact/Lead as param into setTargetObjectId()
                     *      > Input a User into setTargetObjectId, Salesforce does not take in WhatId which mean mergefield functionality is not working
                     * Workaround: 
                     *      > Create a 'Visualforce' Email Template, and input current User into setTargetObjectId()
                     *      > Suppress the email sent to the specified user using setTreatTargetObjectAsRecipient(false) 
                     *  */ 

                    //Query the template Id from the Visualforce Email Template for Credit DSR
                    EmailTemplate creditDSR_VFTemplate = EmailTemplatesSelector.newInstance().selectByDeveloperName('Credit_DSR_Submission_to_queue').values()[0];
                    List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    // populate 'To Address' with respective email that is mapped against the DSR Id from the dsrID-to-Email mapping
                    mail.toAddresses = new String[] { email }; //email
                    mail.setTemplateID(creditDSR_VFTemplate.Id);
                    // Not need for use case but a required field by Salesforce, set to current user
                    mail.setTargetObjectId(UserInfo.getUserId());
                    // suppress the email sending to the specified User, so it only sends to 'To Address'
                    mail.setTreatTargetObjectAsRecipient(false);
                    // set DSR Id to populate the merge field on the email template
                    mail.setWhatId(dsr.id);
                    mail.setSaveAsActivity(true);
                    mail.setOrgWideEmailAddressId(owa.id);
                    allmsg.add(mail);
                    // send email
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(allmsg,false);
                    if (results[0].success) {
                        System.debug('The email was sent successfully.');
                    } else {
                        System.debug('The email failed to send: ' + results[0].errors[0].message);
                    }
                }
            }
        }catch(Exception ex){
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Deal Support Request', 'DealSupportRequestTriggerHandler' , 'creditDSR_SendEmailNotification', 'DealSupportRequestTrigger', LoggingLevel.ERROR);
        }
    }
}