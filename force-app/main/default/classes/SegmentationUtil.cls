/**************************************************
Type:       Utility Class for Sales Segment
Purpose:    Retrieve Sales Segment information
Used By:    AccountTrigger and LeadTrigger
History:
--------------------------------------------------
20.06.2012  M. Isidro (Cloud Sherpas)       Created
20.06.2012  M. Isidro (Cloud Sherpas)       Added method to derive the Hub Catchment for an Account or Lead from a reference data object 
25.06.2012  M. Isidro (Cloud Sherpas)       Added updateGenericSalesSegment method to derive the Sales Segment for an Account or 
                                            Segmentation_Change_Request__c from a reference data object
11.07.2012  M. Isidro (Cloud Sherpas)       Added logic to update Approval Status to Processed/Failed depending on the Database Update
02.08.2012  Richard Enojas (Salesforce.com) Removed references to Proposed Tier/Sector/Subsector based on CR 23. Modified logic to retrieve L2 Approver.
13.08.2012  Richard Enojas (Salesforce.com) Updated logic to only populate L2 Approver when current owner manager is different from proposed owner manager
24.08.2012  Richard Enojas (Salesforce.com) Added to updateSegmentationChangeRequest to process Sales Team Change Request   
15.05.2014  Eric Shen (Australia Post)      Added a filter condition to only includes post codes from AUS customers because of post code format identical with Australia which cuases the issue for hub assignment                                     
03.02.2016  Paul Stamer (Australia Post)    Update Query for Local Area Market not to pickup Inactive Hub Catchment Reference
03.02.2015  Vera Octavia (Australia Post)   Update Test Method
04.08.2016  ejandusay                       Moved testMethod to a separate class
26.08.2016    Kalpita Talwadekar            Updated the method to using coding standards and cleanup.
13.02.2017    Eric Shen                     update updateSalesSegment for new trigger framework
14.02.2017    Eric Shen                     Add alertOnlyOneSubmitterPerAccount method
                                            add segmentationRequireRejectionComment mthod
**************************************************/
public with sharing class SegmentationUtil {
        
     /**
      * @description       This method is invoked from account trigger and lead trigger to update the hub catchment based on post codes.
      * @param             List<SObject> soList 
      * @return            Void
      * @throws            NA
      */   

    private static final String STATUS_SUBMITTED = 'Submitted';
    private static final String STATUS_APPROVED = 'Approved';


    public static void updateHubCatchment(List<SObject> soList){
        // Update hub catchment for an Account or Lead
        try{
            List<String> postcodeList = new List<String>();
            
            for (SObject so : soList) {
                //this if clause is to collect postcodes for accounts only residing in Australia due to the 
                //issue that NZ has the same post code format as Aus
                if (so.getSObjectType() == Lead.SObjectType) {
                   if ( Label.AU_STRING.equals(String.valueOf(so.get(Label.COUNTRY_STRING))) ) {  
                        postcodeList.add(String.valueOf(so.get(Label.POSTALCODE_STRING)));  }        
                } else if (so.getSObjectType() == Account.SObjectType) {
                 if (Label.AU_STRING.equals(String.valueOf(so.get(Label.SHIPPINGCOUNTRY_STRING)))) {  
                      postcodeList.add(String.valueOf(so.get(Label.SHIPPINGPOSTALCODE_STRING)));   
                    }       
                }
            }
            
            if (!postcodeList.isEmpty()) {
                List<Hub_Catchment_Reference__c> hcrList = [SELECT Post_Code__c, Hub_Catchment__c FROM Hub_Catchment_Reference__c 
                                                            WHERE Post_Code__c  in: postcodeList AND Active__c = true];
                Map<String, String> codeHubMap = new Map<String, String>();
                for (Hub_Catchment_Reference__c hcr : hcrList){
                    codeHubMap.put(hcr.Post_Code__c, hcr.Hub_Catchment__c);
                }       
                
                for (SObject so : soList) {
                    if (so.getSObjectType() == Lead.SObjectType) {
                        so.put(Label.HUB_CATCHMENT_FIELD_STRING, codeHubMap.get(String.ValueOf(so.get(Label.POSTALCODE_STRING))));               
                    } else if (so.getSObjectType() == Account.SObjectType) {
                        so.put(Label.HUB_CATCHMENT_FIELD_STRING, codeHubMap.get(String.ValueOf(so.get(Label.SHIPPINGPOSTALCODE_STRING))));               
                    }
                }
            }
        } catch(exception exp){
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                            SegmentationUtil.class.getName(), 'updateHubCatchment', 
                                            'account or lead trigger', LoggingLevel.ERROR);
        }  
    }

    
    public static void updateSalesSegment(List<SObject> sObjList) {
        // Update sales segment from Account or Segmentation Change Request
        List<String> postcodeList = new List<String>();
        List<String> sectorList = new List<String>();
        List<String> subsectorList = new List<String>();
        List<String> acctIds = new List<String>();
        List<Account> acctList = new List<Account>();
        
        List<User> userList = new List <User>();                                            //***   Users List
        List<String> userIdList = new List <String>();
        List<String> ownerIdList = new List <String>();
        List<Sales_Segment_Reference__c> sSegmentList = new List<Sales_Segment_Reference__c>();
        List<String> idPropSSList = new List<String>();
        Map<String,String> usrIdMgrMap = new Map <String,String>();                         //***   Map user's Manager ID                    
        Map<String,String> idAcctSSMap = new Map <String,String>();                         //***   Map Account Sales Segment
        Map<String,String> idSalesDirMap = new Map<String,String>();                        //***   Map user's Sales Director 
        
        
        Map<Id, String> idPostcodeMap = new Map<Id, String>();        
        
        for (SObject so : sObjList){
            system.debug('***so.getSObjectType(): ' + so.getSObjectType());
            system.debug('***Segmentation_Change_Request__c.SObjectType: ' + Segmentation_Change_Request__c.SObjectType);
            if (so.getSObjectType() == Segmentation_Change_Request__c.SObjectType) {
                acctIds.add(String.valueOf(so.get('Organisation__c')));
                userIdList.add (String.valueOf(so.get('Proposed_Account_Manager__c')));
                idPropSSList.add(String.valueOf(so.get('Proposed_Sales_Team__c')));
                system.debug ('##### Proposed SS: ' + so.get('Proposed_Sales_Team__c'));  
            }
        }
        
        if (!acctIds.isEmpty()) {
            acctList = [Select Id, ShippingPostalCode, OwnerId, Sales_Segment__c From Account Where Id in :acctIds];
            system.debug('***acctList: ' + acctList);
        }
        
        for (Account acct : acctList){ 
            ownerIdList.add (acct.OwnerId);           
            idAcctSSMap.put( acct.id, acct.Sales_Segment__c);
            idPostcodeMap.put( acct.Id, acct.ShippingPostalCode );
        }
        system.debug('***idPostcodeMap: ' + idPostcodeMap);
        
        // ************** Users List **************  
        userList = [Select Id,ManagerId,Sales_Director__c from User where Id in: userIdList or Id in: ownerIdList ];
        
        system.debug('***userList: ' + userList);
                          
        for (User uList: userList){
            usrIdMgrMap.put(uList.Id,uList.ManagerId );         
        }
        
        sSegmentList=[Select Sales_Segment__c ,Sales_Director__c from Sales_Segment_Reference__c where Sales_Segment__c in: idPropSSList];
        
        for (Sales_Segment_Reference__c sdList : sSegmentList){
            idSalesDirMap.put(sdList.Sales_Segment__c, sdList.Sales_Director__c );
        }
        // ****************************************
        
        for (SObject so : sObjList){
            if (so.getSObjectType() == Account.SObjectType) {
                
                /*****Commenting out based on CR 23*****
                if (so.get('Type') == 'Small Business') {
                    postcodeList.add(String.valueOf(so.get('ShippingPostalCode')));  
                } else if ( (so.get('Type') == 'Enterprise') || (so.get('Type') == 'Large Account') ){
                    if (so.get('Industry') != '' && so.get('Industry') != null){
                        sectorList.add(String.valueOf(so.get('Industry'))); 
                    }
                    
                    if (so.get('Industry_Sub_Sector__c') != '' && so.get('Industry_Sub_Sector__c') != null){
                        subsectorList.add(String.valueOf(so.get('Industry_Sub_Sector__c'))); 
                    }
                }
                *****/
            } else if (so.getSObjectType() == Segmentation_Change_Request__c.SObjectType) {
                
                //Retrieve Segmentation Change Request record types
            //Mona    RecordType AMCrectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Segmentation_Change_Request__c' AND Name = 'Account Manager Change' limit 1];
            //Mona    RecordType STCrectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Segmentation_Change_Request__c' AND Name = 'Sales Team Change' limit 1];
                
           //Mona     if (so.get('RecordTypeId') == AMCrectype.Id){
                    //If Record Type = Account Manager Change, Level Approver = Manager of Proposed Account Manager
                    /*************** New Change Request 7/27/2012 ******/
                    system.debug ('###### User ID: ' + usrIdMgrMap.get(String.valueOf(so.get('Proposed_Account_Manager__c'))));
                    system.debug ('###### Org Owner ID: ' + so.get('Hidden_Current_Org_Owner_Id__c'));
            //Mona        if (usrIdMgrMap.get(String.valueOf(so.get('Proposed_Account_Manager__c'))) <> usrIdMgrMap.get(String.valueOf(so.get('Hidden_Current_Org_Owner_Id__c')))){
                        so.put('Level2_Approver__c', usrIdMgrMap.get(String.valueOf(so.get('Proposed_Account_Manager__c')))) ; 
            //Mona        } 
                    System.debug('###### Level 2 Approver: ' + usrIdMgrMap.get(String.valueOf(so.get('Proposed_Account_Manager__c'))));
               /**************************************************/   
           //Mona     }
        //Mona        else if (so.get('RecordTypeId') == STCrectype.Id){
                //06.08.2012 - Additional changes to Segmentation Change Request logic   
                //If Record Type = Sales Team Change, Level 2 Approver = Sales Team Owner of the Proposed Sales Team from the Sales Segment Reference object
                    
                    system.debug('*****New CR 23 logic*****');
                    
                    so.put('Level2_Approver__c', idSalesDirMap.get(String.valueOf(so.get('Proposed_Sales_Team__c'))));
                    system.debug('###### Level 2 Approver: ' + idSalesDirMap.get(String.valueOf(so.get('Proposed_Sales_Team__c'))));
             //Mona   }
            }

        } 
    }    
        
        
    public static void updateSegmentationChangeRequest(List<SObject> sObjList){
        // Update segmentation change request
        List<String> acctIds = new List<String>();       
        List<Account> acctList = new List<Account>();       
        Map<String, SObject> idSCRMap = new Map<String, SObject>();
        Map<String, String> scrIdacctIdMap = new Map<String, String>();
        List<SObject> scrUpdateList = new List<SObject>();
        
        if (!sObjList.isEmpty()) {
            for (SObject so : sObjList){
                if (so.getSObjectType() == Segmentation_Change_Request__c.SObjectType) {
                    acctIds.add(String.valueOf(so.get('Organisation__c'))); 
                    idSCRMap.put( String.valueOf(so.get('Organisation__c')), so );
                    scrIdacctIdMap.put( String.valueOf(so.get('Id')), String.valueOf(so.get('Organisation__c')) );
                }
            }   
            
            system.debug('***acctIds: ' + acctIds);
            system.debug('***idSCRMap: ' + idSCRMap);
            
            acctList = [Select Id, Type, Industry, Industry_Sub_Sector__c, Sales_Segment__c, OwnerId From Account Where Id in :acctIds];
            system.debug('***acctList BEFORE: ' + acctList);       
            
            for (Account acct : acctList) {
                Segmentation_Change_Request__c scr = new Segmentation_Change_Request__c();
                scr = (Segmentation_Change_Request__c) idSCRMap.get(acct.Id);   
                system.debug('***scr: ' + scr);
                
                system.debug('***OK');
    
                system.debug('***scr.Proposed_Account_Manager__c: ' + scr.Proposed_Account_Manager__c);
                system.debug('***scr.Proposed_Sales_Team__c: ' + scr.Proposed_Sales_Team__c);
                
                if (scr.Proposed_Sales_Team__c != null && scr.Proposed_Account_Manager__c != null){
                    system.debug('***CHANGE SALES TEAM AND ACCOUNT MANAGER***');
                    acct.OwnerId = scr.Proposed_Account_Manager__c;
                    acct.Sales_Segment__c = scr.Proposed_Sales_Team__c;
                }
                else if (scr.Proposed_Account_Manager__c != null) {
                    system.debug('***CHANGE ACCOUNT MANAGER ONLY***');
                    system.debug('***scr.Proposed_Account_Manager__c: ' + scr.Proposed_Account_Manager__c);
                    acct.OwnerId = scr.Proposed_Account_Manager__c;
                }
                                
            }
            
            
            
            //update acctList;
            Set<Id> successId = new Set<Id>();
            Set<Id> failId = new Set<Id>();
            List<Account> successList = new List<Account>();
            List<Segmentation_Change_Request__c> failList = new List<Segmentation_Change_Request__c>();
            Database.SaveResult[] SR = Database.update(acctList, false);
            
            system.debug('***SR: ' + SR);
            
            for(integer i=0; i<SR.size(); i++) {  
                if(SR[i].isSuccess() == true) {
                    successId.add(SR[i].getId());
                } else {
                    failId.add(SR[i].getId());              
                }
            } 
            system.debug('***acctList AFTER: ' + acctList); 
            
            // Set approval status to Processed for all successful updates
            if (!successId.isEmpty()) {
                for (Id theID : successId) {
                    idSCRMap.get(theId).put('Approval_Status__c', 'Processed');
                }
            }
            
            system.debug('***acctList: ' + acctList);   
            system.debug('***successId: ' + successId); 
            for(Account acct : acctList) {
                Boolean isOk = false;
                for (Id theId : successId) {
                    if (theId == acct.id) {
                        isOk = true;
                        break;
                    }
                }
                if (!isOk) {
                    failId.add(acct.id);    
                }
            }
            
            system.debug('***failId: ' + failId);   

            
            Date dateToday = Date.today();  
            failList = [Select Id, Approval_Status__c From Segmentation_Change_Request__c Where Effective_Date_of_Change__c =: dateToday and Organisation__c in :failId];        
            
            // Set approval status to Failed for all failed updates
            if (!failList.isEmpty()) {
                for (Segmentation_Change_Request__c scr : failList) {
                    scr.Approval_Status__c = 'Failed';
                }
                Database.SaveResult[] SRfail = Database.update(failList, false);
                //update failList;
            }        
            
            for (SObject so : idSCRMap.values()) {
                scrUpdateList.add(so);          
            }   
            
            system.debug('***scrUpdateList: ' + scrUpdateList);
            
            if (!scrUpdateList.isEmpty()) {
                Database.SaveResult[] SRupdate = Database.update(scrUpdateList, false);
                //update scrUpdateList;
            }           
                        
        }
    }        

//14-Feb-17 Eric Shen 
/* This will check if an already existing SCCR is either in Submitted or Approved stage for the current user for the same account. 
* If so, creation of the new record should not be permitted.
*/
 public static void alertOnlyOneSubmitterPerAccount(List<Segmentation_Change_Request__c> lstSCCR){

    Map<String,String> accsMap = new Map<String,String>();

    for (Segmentation_Change_Request__c sc:[SELECT Organisation__c, Name
                FROM Segmentation_Change_Request__c 
                WHERE (Approval_Status__c =: STATUS_SUBMITTED OR Approval_Status__c =: STATUS_APPROVED)]) {
               // AND CreatedById =: UserInfo.getUserId()]) {

                    accsMap.put(sc.Organisation__c,sc.Name);
    }


    for(Segmentation_Change_Request__c sccr: lstSCCR)
    {
        String errormsg1 = 'There is currently a SCCR (';
        String errormsg2 =  ') in the submitted/approved stage. If it is incorrect please review the history on the SCCR record against the customer and contact the last approver or creator to recall.';
        if(!accsMap.isEmpty()) {

            if (accsMap.containsKey(sccr.Organisation__c))
            {
                sccr.addError(errormsg1 + accsMap.get(sccr.Organisation__c) + errormsg2 );
            }
        }
    }

 }

/*//14-Feb-17 Eric Shen 
 * This will make the rejection comments mandatory. 
 * if on reject no comments are added, an error will be thrown.
 */
 public static void segmentationRequireRejectionComment (List<Segmentation_Change_Request__c> lstSCCR) {

// Create a map that stores all the objects that require editing 
    Map<Id, Segmentation_Change_Request__c > approvalStatements = 
    new Map<Id, Segmentation_Change_Request__c>{};

  for(Segmentation_Change_Request__c sccr: lstSCCR)
  {
    // Put all objects for update that require a comment check in a map,
    // so we only have to use 1 SOQL query to do all checks
    
    if (sccr.Approval_Comment_Check__c == 'Requested')
    { 
      approvalStatements.put(sccr.Id, sccr);
      // Reset the field value to null, 
      // so that the check is not repeated,
      // next time the object is updated
      sccr.Approval_Comment_Check__c = null; 
    }
  }  
   
  if (!approvalStatements.isEmpty())  
  {
    // Get the most recent process instance for the approval.
    // If there are some approvals to be reviewed for approval, then
    // get the most recent process instance for each object.
    List<Id> processInstanceIds = new List<Id>{};
    
    for (Segmentation_Change_Request__c sccrs : [SELECT (SELECT ID
                                              FROM ProcessInstances
                                              ORDER BY CreatedDate DESC
                                              LIMIT 1)
                                      FROM Segmentation_Change_Request__c
                                      WHERE ID IN :approvalStatements.keySet()])
    {
        processInstanceIds.add(sccrs.ProcessInstances[0].Id);
    }
      
    // Now that we have the most recent process instances, we can check
    // the most recent process steps for comments.  
    for (ProcessInstance pi : [SELECT TargetObjectId,
                                   (SELECT Id, StepStatus, Comments 
                                    FROM Steps
                                    ORDER BY CreatedDate DESC
                                    LIMIT 1 )
                               FROM ProcessInstance
                               WHERE Id IN :processInstanceIds
                               ORDER BY CreatedDate DESC])
    {
      // If no comment exists, then prevent the object from saving.                 
      if ((pi.Steps[0].Comments == null || 
           pi.Steps[0].Comments.trim().length() == 0))
      {
        approvalStatements.get(pi.TargetObjectId).addError(
         'Please provide a ' + 
         'rejection comment');
      }
    }                                       
  }
 }
}