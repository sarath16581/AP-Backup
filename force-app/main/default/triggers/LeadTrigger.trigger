/**************************************************
Type:       Trigger for Lead Object
Purpose:    Create "deleted" record/s in the Deleted Record object when record/s (Lead) is/are deleted (soft or hard)
            Remove "undeleted" record/s from the Deleted Record object when record/s (Lead) is/are undeleted
History:
--------------------------------------------------
16.05.2011  M. Isidro (Cloud Sherpas)       - Created
07.06.2012  M. Isidro (Cloud Sherpas)       - Added updateLeadHubCatchment
07.06.2012  Joseph Barrameda (CloudSherpas) - Added code for updating Owner_Employee_Number__c before insert and before update
03.07.2012  Joseph Barrameda (CloudSherpas) - Added updateCampaignName
31.07.2012  Richard Enojas (Salesforce.com) - Added checking to skip records where Hidden_Lead_Convert_Clone__c field is true
15.01.2020 Victor Cheng (Salesforce.com) - Added ABN format validation when saving Status as Verified
12.03.2020 Victor Cheng (Salesforce.com) - ABN format validation rules updated to include Status = Qualified, and exclude Primary Product = MyPost Business
13-03-2020  Jansi(avula.jansirani@crmit.com)  - Added isBefore &isInsert if Block
11-08-2020  arjun.singh@auspost.com.au      - Modified the code related to ABN validation
26-08-2020  arjun.singh@auspost.com.au      - Added leadScoring feature to update Lead Score Field on Lead Insert/Update
15-10-2020  suman.gunaganti@auspost.com.au  - Added validation for lead details
27-10-2020  Mav3rik                         - Added LPOLeadWccController.updateWCC
05-11-2020  suman.gunaganti@auspost.com.au  - Added HVS Sales cadence code
12-01-2022  naveen.rajanna@auspost.com.au   - REQ2656153 Added check for whether Batch/Future invoked call before making future call
27-03-2023  Pratyush Chalasani              - (SF-621) Added LeadTriggerHandler and respective domain classes
**************************************************/

trigger LeadTrigger on Lead (after delete, after undelete, before insert, before update, after insert, after update) {
    if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
		(new LeadTriggerHandler()).dispatch();
		
        Set<Id> leadIds=new Set<Id>();
            if (trigger.isAfter && trigger.isDelete){
                system.debug('***' + trigger.old);
                DeletedRecordUtil.createDeletedRecord(trigger.old, 'Lead'); 
            }
        
            if (trigger.isAfter && trigger.isUnDelete){
                system.debug('***' + trigger.new);
                DeletedRecordUtil.undeleteDeletedRecord(trigger.new);
            }   
        
            if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
            //LeadUtil.updateLeadHubCatchment(trigger.new);
                List<Lead> LeadsList = new List<Lead>();
                for (Lead leadrec : trigger.new){
                    leadIds.add(leadrec.Id);
                    if (leadrec.Hidden_Lead_Convert_Clone__c == false){
                        LeadsList.add(leadrec);
                    }

                    // 2020-01-15 MW0003954 validate ABN format on progressing to Verified
                    // 2020-03-12 as part of STP R1, Lead Status has a new Qualified value, and this check is to be excluded for MyPost Business products
                    String leadPrimaryProduct = leadrec.Product__c == null ? '' : leadrec.Product__c;
                    if(leadPrimaryProduct.toLowerCase() != 'mypost business'
                            && (leadrec.Status == 'Verified' || leadrec.Status == 'Qualified')
                            && leadrec.ABN__c != null)
                    {
                        String abn = leadrec.ABN__c.deleteWhitespace();
                        if(Utility.isValidAbnFormat(abn) != true)
                        {
                            // throw an error, the VF Page will surface this to the user
                            leadrec.addError('ABN is invalid');
                        }
                    }

                }
                if(!LeadsList.isEmpty()) {
                    SegmentationUtil.updateHubCatchment(LeadsList);
                    LeadUtil.updateLeadOwnerEmployeeNumber(LeadsList);
                    // Update the Lead.LPO_WCC__c field
                    LPOLeadWccController.updateWCC(LeadsList);
                }

            }

        /* refactor to above if clause
            if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
                List<Lead> LeadsList = new List<Lead>();
                for (Lead leadrec : trigger.new){
                    if (leadrec.Hidden_Lead_Convert_Clone__c == false){
                        LeadsList.add(leadrec);
                    }
                }
                if(!LeadsList.isEmpty())
                    LeadUtil.updateLeadOwnerEmployeeNumber(LeadsList);
            }

         */
              //--[Jansi:13-03-2020]Added below if block
            if (trigger.isBefore && trigger.isInsert){
               LeadUtil.updateLeadRecordType(trigger.new);
            }
            if (trigger.isAfter && trigger.isInsert) {
                List<Lead> LeadsList = new List<Lead>();
                for (Lead leadrec : trigger.new){
                    leadIds.add(leadrec.Id);
                    if (leadrec.Hidden_Lead_Convert_Clone__c == false){
                        LeadsList.add(leadrec);
                    }
                }
                if(!LeadsList.isEmpty())
                    LeadUtil.updateCampaignName(LeadsList);
            }
            //Suman G: 15-10-2020
            //FirstName , LastName, Phone/Mobile, Address , Email , Customer Type validation at 
            //the time of BG Standard and StartTrack Lead Status change to Qualified or Converted
            if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
                BG_LeadUtility.validateLeadFields(trigger.new);

                //Suman G: 16-12-2020
                //Populate Lead SLA fields
                BG_LeadUtility.populateLeadSLAFields(trigger.new, trigger.oldMap);
            }
            //Suman G: 05-11-2020
            //Sales Cadence logic for in progress and qualified leads 
            if (trigger.isAfter && trigger.isUpdate){
                BG_LeadUtility.verifyLeadsforSalesCadence(trigger.new, trigger.oldMap);
            }
            if (LeadScoring.leadScoringClassAlreadyCalled()==False && !leadIds.isEmpty() && !System.IsFuture() && !System.IsBatch()){ //REQ2656153
                Integer limit1 = Limits.getLimitFutureCalls() - Limits.getFutureCalls();
                if (limit1>0){//don't call the method if the limit is reached
                    LeadScoring.evaluateLeads(leadIds);    
                }    
            } 
    }
}