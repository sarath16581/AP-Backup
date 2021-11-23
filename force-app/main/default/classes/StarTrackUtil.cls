/*------------------------------------------------------------
Author:        Patrick James Franco
Company:       Cloud Sherpas
Description:   Utility class for used by InvocableMethod calls by Process Builder
Test Class:    StarTrackUtil_Test
History
October 6, 2015 - Patrick James Franco - Created
October 15, 2015 - David Catindoy - Modified (Added additional methods)
July 18, 2016 - David Catindoy - Reason for Without Sharing: Users need access to update Tasks and other records owned by other users.
March 08, 2017 - David Catindoy - Transferred closeRelatedTasksAndWFEmails method from CaseCommonUtility class to let user close the tasks that they don't own when the parent case record was closed.
2019-02-23  nathan.franklin@auspost.com.au  Small refactoring of closeRelatedTasksAndWFEmails to minimise additional DML operations
------------------------------------------------------------*/
public without sharing class StarTrackUtil {


    /**
     * In StarTrack, in certain situations the FCR (First Call Resolution) flag should be to true.
     * Generally this occurs when cases are resolved with little contact to the contact centre
     */
    public static void processFCRFlag(List<Case> caseList, Map<Id, Case> oldCases) {
        Set<String> closedStatuses = Utility.getCaseClosedStatus();

        // get only the records that need processing (either records that have never passed through here, or where the values of tracked fields have changed since it was last processed)
        for(Case caseRec : (List<Case>)RecursionUtility.getUnprocessedRecords('ST-processFCRFlag', caseList, new Set<String>{'Status', 'FCR__c', 'RecordTypeId'})) {
            System.debug('Processing Record for processFCRFlag');
            if (caseRec.StarTrack_RecordType__c) {
                Case oldCaseRec = oldCases.get(caseRec.Id);

                // The FCR flags needs to be set in the following circumstances:
                //  1. The Status field has changed value
                //  2. FCR is not currently set
                //  3. Previous status must have been 'New'
                //  4. either Current Status is Closed OR
                //              Current status is 'Waiting on Integration' and Case is Delivery Enquiry

                // When a the current case is closed and the previous status was not Pending Customer Notification
                //      OR The current case is a Delivery Enquiry and the current status is 'Waiting on Integration'
                if (!caseRec.Status.equals(oldCaseRec.Status) && !caseRec.FCR__c && StarTrack_Constants.CASE_STATUS_NEW.equals(oldCaseRec.Status) &&
                        (closedStatuses.contains(caseRec.Status) ||
                                (StarTrack_Constants.CASE_DELIVERY_RT.equals(caseRec.RecordType.Name) && StarTrack_Constants.CASE_STAT_INTEGRATION.equals(caseRec.Status)))) {
                    caseRec.FCR__c = true;
                }
            }
        }
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Logic that creates an Operation Task after a positive LDC System Check result
    Inputs:        List<Id>
    Returns:       None
    History:
    December 9, 2015 - Patrick James Franco - Created
    ------------------------------------------------------------*/
    public static void createLDCTask(Id caseId){
        StarTrackCreateTaskPAController ctrl = new StarTrackCreateTaskPAController(caseId);
        if(ctrl.newTask != null){
            ctrl.newTask.Subject = 'LDC Approval Required - ' + ctrl.existingCase.ArticleTest__r.Name;
            ctrl.createTask();
        }
        
        Group ldcQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'StarTrack Late Delivery Claims Queue'];
        if(String.isNotBlank(ldcQueue.Id)){
            ctrl.existingCase.OwnerId = ldcQueue.Id;
            Database.update(ctrl.existingCase);
        }
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Logic that creates an Workflow Email after a negative LDC System Check result
    Inputs:        List<Id>
    Returns:       None
    History:
    December 11, 2015 - Patrick James Franco - Created
    January 14, 2016 - Patrick James Franco - Removed logic of setting Workflow Email Body
    ------------------------------------------------------------*/
    public static void createLDCEmail(Id caseId){
        Case thisCase = [SELECT Id, SuppliedEmail, ArticleTest__r.Name FROM Case WHERE Id = :caseId];

        workflow_Email__c wfe = new workflow_Email__c();
        wfe.Case__c = thisCase.Id;
        wfe.Status__c = StarTrack_Constants.WFE_STATUS_OPEN;
        wfe.To_Address__c = thisCase.SuppliedEmail;
        wfe.Task_Subject__c = 'Late Delivery Claim: ' + thisCase.ArticleTest__r.Name;
        wfe.Name = 'Late Delivery Claim: ' + thisCase.ArticleTest__r.Name;
        wfe.Email_Type__c = StarTrack_Constants.TASK_SUBTYPE_SINGLETASKING;
        wfe.Consignment_Number__c = thisCase.ArticleTest__r.Name;
        Database.insert(wfe);
    }

    /*------------------------------------------------------------
    Author:        YongLing CHUA
    Company:       Salesforce
    Description:   Logic that creates an Workflow Email after Approved LDC Approval Process
    Inputs:        List<Id>
    Returns:       None
    History:
    December 16, 2015 - YongLing CHUA - Created
    January 14, 2016 - Patrick James Franco - Removed logic of setting Workflow Email Body
    ------------------------------------------------------------*/
    public static void createLDCApprovedEmail(Id caseId){
        try{
            Case thisCase = [SELECT Id, SuppliedEmail, ArticleTest__r.Name FROM Case WHERE Id = :caseId];

            workflow_Email__c wfe = new workflow_Email__c();
            wfe.Case__c = thisCase.Id;
            wfe.Status__c = StarTrack_Constants.WFE_STATUS_OPEN;
            wfe.To_Address__c = thisCase.SuppliedEmail;
            wfe.Task_Subject__c = 'Late Delivery Claim: ' + thisCase.ArticleTest__r.Name;
            wfe.Name = 'Late Delivery Claim: ' + thisCase.ArticleTest__r.Name;
            wfe.Email_Type__c = StarTrack_Constants.TASK_SUBTYPE_SINGLETASKING;
            wfe.Consignment_Number__c = thisCase.ArticleTest__r.Name;
            Database.insert(wfe);
        }
        catch (System.CalloutException e){
            System.debug('ERROR:' + e);
        }

    }


    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Logic that provides an LDC Case a Metro Network
    Inputs:        List<Id>
    Returns:       None
    History:
    December 10, 2015 - Patrick James Franco - Created
    January 8, 2016 - Patrick James Franco - Rearranged logic to properly assign a Network
    March 30, 2016 - David Catindoy - Amended method to include a wider approach
    ------------------------------------------------------------*/
    public static void validateLDCNetwork(Id caseId){
        Case thisCase = [SELECT Network__c, Network__r.RecordType.DeveloperName, Network__r.Parent_Network__c, Network__r.Parent_Network__r.RecordType.DeveloperName, Network__r.Parent_Network__r.Parent_Network__c,
                         Network__r.Parent_Network__r.Parent_Network__r.RecordType.DeveloperName, ArticleTest__r.Network__c, ArticleTest__r.Network__r.RecordType.DeveloperName,
                         Articletest__r.Network__r.Parent_Network__c, Articletest__r.Network__r.Parent_Network__r.RecordType.DeveloperName,
                         Articletest__r.network__r.Parent_Network__r.Parent_Network__c, Articletest__r.Network__r.Parent_Network__r.Parent_Network__r.RecordType.DeveloperName
                         FROM Case WHERE Id = :caseId LIMIT 1];

        if(String.isNotBlank(thisCase.ArticleTest__r.Network__c)){
            if(checkLDCdepotRecType(thisCase.ArticleTest__r.Network__r.RecordType.DeveloperName)){
                thisCase.Network__c = thisCase.ArticleTest__r.Network__c;
            }
            else if(String.isNotBlank(thisCase.ArticleTest__r.Network__r.Parent_Network__c)){
                if(checkLDCdepotRecType(thisCase.Articletest__r.Network__r.Parent_Network__r.RecordType.DeveloperName)){
                    thisCase.Network__c = thisCase.Articletest__r.Network__r.Parent_Network__c;
                } else if(String.isNotBlank(thisCase.ArticleTest__r.Network__r.Parent_Network__r.Parent_Network__c)){
                    if(checkLDCdepotRecType(thisCase.Articletest__r.Network__r.Parent_Network__r.Parent_Network__r.RecordType.DeveloperName)){
                        thisCase.Network__c = thisCase.Articletest__r.Network__r.Parent_Network__r.Parent_Network__c;
                    } else{
                        thisCase.Network__c = thisCase.ArticleTest__r.Network__c;
                    }
                }
            }
        } else if(String.isNotBlank(thisCase.Network__c)){
            if(checkLDCdepotRecType(thisCase.Network__r.RecordType.DeveloperName)){
                thisCase.Network__c = thisCase.Network__c;
            } else if(String.isNotBlank(thisCase.Network__r.Parent_Network__c)){
                if(checkLDCdepotRecType(thisCase.Network__r.Parent_Network__r.RecordType.DeveloperName)){
                    thisCase.Network__c = thisCase.Network__r.Parent_Network__c;
                } else if(String.isNotBlank(thisCase.Network__r.Parent_Network__r.Parent_Network__c)){
                    if(checkLDCdepotRecType(thisCase.Network__r.Parent_Network__r.Parent_Network__r.RecordType.DeveloperName)){
                        thisCase.Network__c = thisCase.Network__r.Parent_Network__r.Parent_Network__c;
                    } else{
                        thisCase.Network__c = thisCase.Network__c;
                    }
                }
            }
        }

        Database.update(thisCase);
    }
    
    public static Boolean checkLDCdepotRecType(String recType){
        if(StarTrack_Constants.RECORDTYPE_DEPOT_METRO.equals(recType) ||
           StarTrack_Constants.RECORDTYPE_DEPOT_REGIONAL.equals(recType)){
           return true;
        }
        return false;
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Logic that will close related Tasks and Workflow Email for LDC Cases
    Inputs:        Id
    Returns:       None
    History:
    January 19, 2016 - Patrick James Franco - Created
    August 24, 2021  - SJudd modified to query IsClosed
    ------------------------------------------------------------*/
    public static void closeCaseTaskEmail(Id caseId){
        List<Task> taskList = [SELECT Id, Status, WhatId, Waiting_for_Operations_Date__c, Acknowledged_Date__c, CreatedDate, 
            Finished_Date__c, Operations_to_Acknowledged_Time__c, Operations_to_Finished_Time__c, Create_to_Finished_Time__c, Resolution_Code__c, IsClosed
            FROM Task WHERE WhatId = :caseId AND IsClosed = :StarTrack_Constants.ST_FALSE];

        List<workflow_Email__c> emailList = [SELECT Status__c FROM workflow_Email__c WHERE Case__c = :caseId AND Status__c != :StarTrack_Constants.WFE_STATUS_CLOSE];
        //MW0004540 SJudd modified to only finish tasks that are not already closed.
        if(!taskList.isEmpty()){
            for(Task thisTask : taskList){
                thisTask.Status = StarTrack_Constants.TASK_STATUS_FINISHED;
                thisTask.Bulk_Close__c = StarTrack_Constants.ST_TRUE;
                if(String.isBlank(thisTask.Resolution_Code__c)){
                    thisTask.Resolution_Code__c = StarTrack_Constants.TASK_RESOLUTION_CODE;
                }
                thisTask.Finished_Date__c = Datetime.now();
            }

            Database.update(taskList);
        }

        if(!emailList.isEmpty()){
            for(workflow_Email__c thisEmail : emailList){
                if(thisEmail.Status__c != StarTrack_Constants.WFE_STATUS_CLOSE){
                    thisEmail.Status__c = StarTrack_Constants.WFE_STATUS_CLOSE;
                }
            }

            Database.update(emailList);
        }

        setStatusDate(taskList);
    }

    /*------------------------------------------------------------
    Author:        David Catindoy
    Company:       Cloud Sherpas
    Description:   Logic to set date time when Task is updated to a specified Status
                   Method is callled via process builder (StarTrack Calculate Task Status Duration)
    Inputs:        Task Id List
    Returns:       None
    History:
    June 1, 2016 - David Catindoy - Modified to update some logic
    June 15, 2016 - Jen Karen Tan - Updated method, removed soql query
    September 18, 2017 - Disha Kariya - Modified to add Minor work - MW0001979
    ------------------------------------------------------------*/
    public static void setStatusDate(List<Task> taskList){
    // SWMY Redelivery TEMP Queue Change
        StarTrack_Settings__c stSettingsSSD = StarTrack_Settings__c.getOrgDefaults();
        Map<Id, Case> caseMap = new Map<Id, Case>();
        for(Task thisTask : taskList){
            caseMap.put(thisTask.WhatId, null);
        }
    // SWMY Redelivery TEMP Queue Change    
        caseMap = new Map<Id, Case>([SELECT Id, Enquiry_Type__c,BusinessHoursId, Status, RecordType.Name, (SELECT Id, Status FROM Tasks WHERE RecordType.Name =: StarTrack_Constants.TASK_RECTYPE_OPERATION AND Type =: StarTrack_Constants.TASK_TYPE_OPERATION AND
                                    Status != :StarTrack_Constants.TASK_STATUS_FINISHED AND Status != :StarTrack_Constants.TASK_STATUS_COMPLETED AND Status != :StarTrack_Constants.TASK_STATUS_REJECTED) FROM Case WHERE Id IN :caseMap.keySet()]);

        for(Task thisTask : taskList){
            if(thisTask.Status.equals(StarTrack_Constants.TASK_STATUS_WAITING)){
                thisTask.Waiting_for_Operations_Date__c = Datetime.now();
            }
            else if(thisTask.Status.equals(StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED)){
                thisTask.Acknowledged_Date__c = Datetime.now();
            }
            else if(thisTask.Status.equals(StarTrack_Constants.TASK_STATUS_FINISHED) || thisTask.Status.equals(StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED)){
                thisTask.Finished_Date__c = Datetime.now();
            }            

            if(String.isNotBlank(String.valueOf(thisTask.Waiting_for_Operations_Date__c))) {
                // Waiting for Operations to Acknowledged
                if (String.isNotBlank(String.valueOf(thisTask.Acknowledged_Date__c))){
                    thisTask.Operations_to_Acknowledged_Time__c = Integer.valueOf(BusinessHours.diff(caseMap.get(thisTask.WhatId).BusinessHoursId, thisTask.Waiting_for_Operations_Date__c, thisTask.Acknowledged_Date__c) * 0.0000166667);
                }
                // Waiting for Operations to Finished
                if (String.isNotBlank(String.valueOf(thisTask.Finished_Date__c))){
                    thisTask.Operations_to_Finished_Time__c = Integer.valueOf(BusinessHours.diff(caseMap.get(thisTask.WhatId).BusinessHoursId, thisTask.Waiting_for_Operations_Date__c, thisTask.Finished_Date__c) * 0.0000166667);
                }
            }
            // CreatedDate to Finished
            if(String.isNotBlank(String.valueOf(thisTask.Finished_Date__c))){
                thisTask.Create_to_Finished_Time__c = Integer.valueOf(BusinessHours.diff(caseMap.get(thisTask.WhatId).BusinessHoursId, thisTask.CreatedDate, thisTask.Finished_Date__c) * 0.0000166667);
            }
        }
        
        List<Case> caseToUpdate = new List<Case>();
        for(Case caseRec : caseMap.values()){
            if(StarTrack_Constants.CASE_DELIVERY_RT.equals(caseRec.RecordType.Name) && caseRec.Tasks.isEmpty() && !StarTrack_Constants.CASE_STAT_AWAITINGAPPROVAL.equals(caseRec.Status) && !StarTrack_Constants.CASE_STAT_CLOSED.equals(caseRec.Status)){
                caseRec.Status = StarTrack_Constants.CASE_STAT_AWAITINGREVIEW;
                // SWMY Redelivery TEMP Queue Change
                if(StarTrack_Constants.CASE_ENQUIRY_REDELIVERY.equals(caseRec.Enquiry_Type__c)) 
                    {
                        caseRec.OwnerId = stSettingsSSD.SWMYTempQueue__c;
                        caseRec.Case_Update__c = '';
                        }
                caseToUpdate.add(caseRec);
            }
        }
        
        if(!caseToUpdate.isEmpty()){
            Database.update(caseToUpdate);
        }

        List<Database.SaveResult> srList = Database.update(taskList, false);
        
        if(!srList.isEmpty()){
            for(Database.SaveResult sr : srList){
                // Operation was unsuccessful
                if (!sr.isSuccess()) {
                    System.debug(StarTrack_Constants.FAILED_TASK + ' - Task Record Id - ' + sr.getId());
                }
            }
        }
    }
    
    /*------------------------------------------------------------
    Author:        David Catindoy
    Company:       Cloud Sherpas
    Description:   Method to calculate the depot of the consignment
    Inputs:        List of consignment records
    Returns:       None
    History:
    October 15, 2015 - David Catindoy - Created
    August 26, 2016 - David Catindoy - Modified to accept a list of consignment records as opposed to accepting a list of consignment ids. 
    ------------------------------------------------------------*/
    public static void calculateDepot(List<Article__c> listOfConsignments){
        Map<Id, Set<Id>> depotResult = new Map<Id, Set<Id>>();
        depotResult = StarTrackUtil.queryPostCodeMapping(listOfConsignments, new List<Case>());
        for(Article__c con : listOfConsignments){
            if(depotResult.containsKey(con.Id)){
                if(!(depotResult.get(con.Id).size() > 1)){
                    con.Network__c = new List<Id>(depotResult.get(con.Id))[0];
                } else{
                    con.Network__c = null;
                }
            } else{
                con.Network__c = null;
            }
        }
    }
    
    /*------------------------------------------------------------
    Author:        David Catindoy
    Company:       Cloud Sherpas
    Description:   Method to calculate the depot of the case
    Inputs:        List of case records
    Returns:       None
    History:
    September 12, 2016 - Createdby: David Catindoy
    ------------------------------------------------------------*/
    public static void calculateCaseDepot(List<Case> listOfCases){
        Map<Id, Set<Id>> depotResult = new Map<Id, Set<Id>>();
        depotResult = StarTrackUtil.queryPostCodeMapping(new List<Article__c>(), listOfCases);
        for(Case caseRec : listOfCases){
            if(depotResult.containsKey(caseRec.Id)){
                if(!(depotResult.get(caseRec.Id).size() > 1)){
                    caseRec.Network__c = new List<Id>(depotResult.get(caseRec.Id))[0];
                } else{
                    caseRec.Network__c = null;
                }
            } else{
                caseRec.Network__c = null;
            }
        }
    }

    /*------------------------------------------------------------
    Author:        David Catindoy
    Company:       Cloud Sherpas
    Description:   Method to do the mapping between consignment against the postcode mapping table
    Inputs:        List of consignments
    Returns:       A map that contains the match depot
    History:
    October 15, 2015 - David Catindoy - Created
    October 21, 2015 - David Catindoy - Modified (Refactor to cover additional logic)
    ------------------------------------------------------------*/
    public static Map<Id, Set<Id>> queryPostCodeMapping(List<Article__c> conList, List<Case> caseList){
      Map<Id, Set<Id>> depotResult = new Map<Id, Set<Id>>();
      Map<String, Set<Id>> postCodeMap = new Map<String, Set<Id>>();
      Set<String> receiverSuburb = new Set<String>();
      Set<String> receiverPostcode = new Set<String>();
      Set<String> serviceType = new Set<String>();
      List<PostcodeMapping__c> postCode = new List<PostcodeMapping__c>();
      if(!conList.isEmpty()){
        for(Article__c con : conList){
            receiverSuburb.add(con.Receiver_Suburb__c);
            receiverPostcode.add(con.ReceiverPostcode__c);
            serviceType.add(con.Service_Type__c);
        }  
      }
      
      if(!caseList.isEmpty()){
        for(Case caseRec : caseList){
            receiverSuburb.add(caseRec.Address4Suburb__c);
            receiverPostcode.add(caseRec.Address4Postcode__c);
            serviceType.add(caseRec.ArticleTest__r.Service_Type__c);
        }
      }
      
      String[] serviceTypeFilters = new String[]{};
      for(String st : serviceType){
          serviceTypeFilters.add('%'+st+'%');
      }
      postCode = [  SELECT Id, Network__c, Suburb__c, Postcode__c,
                    Network__r.Facility__c, Postcode__r.Name
                    FROM PostcodeMapping__c
                    WHERE Suburb__c IN :receiverSuburb
                    AND Postcode__r.Name IN :receiverPostcode
                    AND Network__r.Facility__c LIKE :serviceTypeFilters];
      if(postCode.size() > 0){
          for(PostcodeMapping__c pcm : postCode){
              if(pcm.Network__r.Facility__c.contains('&')){
                  if(!postCodeMap.containsKey(pcm.Suburb__c.toUpperCase() + '' + pcm.Postcode__r.Name + StarTrack_Constants.PREMIUM)){
                      postCodeMap.put(pcm.Suburb__c.toUpperCase() + '' + pcm.Postcode__r.Name + StarTrack_Constants.PREMIUM, new Set<Id>{pcm.Network__c});
                  } else{
                      postCodeMap.get(pcm.Suburb__c.toUpperCase() + '' + pcm.Postcode__r.Name + StarTrack_Constants.PREMIUM).add(pcm.Network__c);
                  }

                  if(!postCodeMap.containsKey(pcm.Suburb__c.toUpperCase() + '' + pcm.Postcode__r.Name + StarTrack_Constants.EXPRESS)){
                      postCodeMap.put(pcm.Suburb__c.toUpperCase() + '' + pcm.Postcode__r.Name + StarTrack_Constants.EXPRESS, new Set<Id>{pcm.Network__c});
                  } else{
                      postCodeMap.get(pcm.Suburb__c.toUpperCase() + '' + pcm.Postcode__r.Name + StarTrack_Constants.EXPRESS).add(pcm.Network__c);
                  }
              } else{
                  if(!postCodeMap.containsKey(pcm.Suburb__c.toUpperCase() + '' + pcm.Postcode__r.Name + '' + pcm.Network__r.Facility__c)){
                      postCodeMap.put(pcm.Suburb__c.toUpperCase() + '' + pcm.Postcode__r.Name + '' + pcm.Network__r.Facility__c, new Set<Id>{pcm.Network__c});
                  } else{
                      postCodeMap.get(pcm.Suburb__c.toUpperCase() + '' + pcm.Postcode__r.Name + '' + pcm.Network__r.Facility__c).add(pcm.Network__c);
                  }
              }
          }
          
          if(!conList.isEmpty()){
              for(Article__c con : conList){
                if(postCodeMap.containsKey(con.Receiver_Suburb__c.toUpperCase() + '' + con.ReceiverPostcode__c + '' + con.Service_Type__c)){
                    depotResult.put(con.Id, postCodeMap.get(con.Receiver_Suburb__c.toUpperCase() + '' + con.ReceiverPostcode__c + '' + con.Service_Type__c));
                }
              }
          }
          
          if(!caseList.isEmpty()){
              for(Case caseRec : caseList){
                if(postCodeMap.containsKey(caseRec.Address4Suburb__c.toUpperCase() + '' + caseRec.Address4Postcode__c + '' + caseRec.ArticleTest__r.Service_Type__c)){
                    depotResult.put(caseRec.Id, postCodeMap.get(caseRec.Address4Suburb__c.toUpperCase() + '' + caseRec.Address4Postcode__c + '' + caseRec.ArticleTest__r.Service_Type__c));
                }
              }
          }
      }

      return depotResult;
    }


    /*------------------------------------------------------------
    Author:        David Catindoy
    Company:       Cloud Sherpas
    Description:   Method to do the mapping between consignment service code and customer type against custom metadata to assign proper consignment service type value
    Inputs:        List of consignments
    Returns:       None
    History:
    January 4, 2016 - David Catindoy - Created
    August 22, 2016 - David Catindoy - Updated to accept consignment records instead of ids.
                                       The reason for the update is to use this method in the before update trigger
                                       and completely deferred the PB.
    ------------------------------------------------------------*/
    public static void calculateConsignmentServiceType(List<Article__c> listOfConsignments){
        List<Product_Mapping__mdt> productMappings = [SELECT DeveloperName, Customer_Type__c, Delivery_Type__c, Product_Code__c, Product_Group__c, Description__c FROM Product_Mapping__mdt];
        Map<String, Product_Mapping__mdt> productMap = new Map<String, Product_Mapping__mdt>();
        for(Product_Mapping__mdt productMapping : productMappings){
            productMap.put(productMapping.Product_Code__c+''+productMapping.Customer_Type__c, productMapping);
        }
        
        for(Article__c con : listOfConsignments){
            if(productMap.containsKey(con.ServiceCode__c+con.Customer_Type__c)){
                con.Service_Type__c = productMap.get(con.ServiceCode__c+''+con.Customer_Type__c).Delivery_Type__c;
                con.Product_Group__c = productMap.get(con.ServiceCode__c+''+con.Customer_Type__c).Product_Group__c;
                con.STServiceType__c = productMap.get(con.ServiceCode__c+''+con.Customer_Type__c).Description__c;
            }
        }
    }

    /*------------------------------------------------------------
    Author:        David Catindoy
    Company:       Cloud Sherpas
    Description:   Calculate VOC Enquiry due date
    Inputs:        List of Case Ids
    Returns:       None
    History:
    January 13, 2016 - David Catindoy - Created
    ------------------------------------------------------------*/
    public static void calculateVOCEnquiryDueDate(List<Id> caseIds){
        StarTrack_Settings__c cs = StarTrack_Settings__c.getOrgDefaults();
        List<Case> caseList = [SELECT Id, CaseNumber, CreatedDate, Due_Date__c, Status, BusinessHoursId, Number_of_Open_VOC_Incidents__c, Number_of_VOC_Incidents__c FROM Case WHERE Id IN :caseIds];
        for(Case caseRec : caseList){
            if(caseRec.BusinessHoursId != null){  
                Datetime dtDueDate = BusinessHours.add(caseRec.BusinessHoursId, caseRec.CreatedDate, (3600000 * Integer.valueOf(cs.Number_of_Hours_per_Business_Days__c*cs.Number_of_Business_Days__c)));
                String strDueDate = dtDueDate.format('yyyy-MM-dd HH:mm:ss');
                Date dDueDate = Date.valueOf(strDueDate);
                caseRec.Due_Date__c = dDueDate;
            }
        }
        Database.update(caseList);
    }

    /*------------------------------------------------------------
    Author:        David Catindoy
    Company:       Cloud Sherpas
    Description:   Calculate VOC Enquiry field values
    Inputs:        List of Case Ids
    Returns:       None
    History:
    January 13, 2016 - David Catindoy - Created
    ------------------------------------------------------------*/
    public static void calculateVOCEnquiry(List<Id> caseIds){
        Map<Id, Integer> countOpenIncident = new Map<Id, Integer>();
        List<Case> caseList = [SELECT Id, CaseNumber, CreatedDate, Due_Date__c, Status, BusinessHoursId, Number_of_Open_VOC_Incidents__c, Number_of_VOC_Incidents__c, (SELECT Id, Status, CaseNumber FROM Cases WHERE RecordType.Name = :StarTrack_Constants.CASE_VOCINC_RT) FROM Case WHERE Id IN :caseIds];
        for(Case caseRec : caseList){
            Integer count = 0;
            for(Case caseChild : caseRec.Cases){
                if(!StarTrack_Constants.CASE_STAT_CLOSED.equals(caseChild.Status)){
                    count++;
                }
            }
            countOpenIncident.put(caseRec.Id, count);
        }
        for(Case caseRec : caseList){
            if(countOpenIncident.containsKey(caseRec.Id)){
                caseRec.Number_of_Open_VOC_Incidents__c = countOpenIncident.get(caseRec.Id);
            }
            caseRec.Number_of_VOC_Incidents__c = caseRec.Cases.size();
        }
        Database.update(caseList);
    }

    /*------------------------------------------------------------
    Author:        David Catindoy
    Company:       Cloud Sherpas
    Description:   Calculate VOC Incident field values.
    Inputs:        List of Case Ids
    Returns:       None
    History:
    January 13, 2016 - David Catindoy - Created
    ------------------------------------------------------------*/
    public static void calculateVOCIncident(List<Id> caseIds){
        StarTrack_Settings__c cs = StarTrack_Settings__c.getOrgDefaults();
        List<Case> caseList = [SELECT Id, CaseNumber, CreatedDate, Due_Date__c, Priority, Status, BusinessHoursId FROM Case WHERE Id IN :caseIds];
        for(Case caseRec : caseList){
            if(caseRec.BusinessHoursId != null){
                Datetime dtDueDate = System.now();
                if(StarTrack_Constants.PRIORITY_NORMAL.equals(caseRec.Priority)){
                   dtDueDate = BusinessHours.add(caseRec.BusinessHoursId, caseRec.CreatedDate, (3600000 * Integer.valueOf(cs.Number_of_Hours_per_Business_Days__c*5)));
                } else if(StarTrack_Constants.PRIORITY_HIGH.equals(caseRec.Priority)){
                    dtDueDate = BusinessHours.add(caseRec.BusinessHoursId, caseRec.CreatedDate, (3600000 * Integer.valueOf(cs.Number_of_Hours_per_Business_Days__c*3)));
                } else if(StarTrack_Constants.PRIORITY_URGENT.equals(caseRec.Priority)){
                    dtDueDate = BusinessHours.add(caseRec.BusinessHoursId, caseRec.CreatedDate, (3600000 * Integer.valueOf(cs.Number_of_Hours_per_Business_Days__c)));
                } else if(StarTrack_Constants.PRIORITY_CRITICAL.equals(caseRec.Priority)){
                    dtDueDate = BusinessHours.add(caseRec.BusinessHoursId, caseRec.CreatedDate, (3600000 * Integer.valueOf(cs.Number_of_Hours_per_Business_Days__c)));
                }               
                String strDueDate = dtDueDate.format('yyyy-MM-dd HH:mm:ss');
                Date dDueDate = Date.valueOf(strDueDate);
                caseRec.Due_Date__c = dDueDate;
            }
        }
        Database.update(caseList);
    }
    
    /*------------------------------------------------------------
    Author:        David Catindoy
    Company:       Cloud Sherpas
    Description:   Calculate Case From Address.
    Inputs:        List of Case Ids
    Returns:       None
    History:
    May 31, 2016 - David Catindoy - Created
    ------------------------------------------------------------*/
    public static void calculateFromAddress(String paramList){
        List<String> params = paramList.split('-');
        StarTrack_Settings__c customSetting = StarTrack_Settings__c.getOrgDefaults();
        EmailMessage currentEmail = [SELECT Id, CreatedDate, CcAddress, BccAddress, Subject, ToAddress, FromAddress FROM EmailMessage WHERE Id = :params[1]];
        DateTime currentEmailDateTime = currentEmail.CreatedDate - (customSetting.Duplicate_Email_Check_Interval_Minutes__c/1440);
        EmailMessage duplicateEmailRec = new EmailMessage();
        
        Case caseRec = [SELECT Id, ResolutionCode__c, Subject, Status, OwnerId, CaseNumber, RecordType.Name, StarTrack_Calc_Email_Address__c, Auto_Email_Response_sent__c, Send_Auto_Response_Email__c, Enquiry_Type__c, Call_Purpose__c FROM Case WHERE Id = :params[0]];
        
        if(StarTrack_Constants.CASE_CREDIT_RT.equals(caseRec.RecordType.Name) && ((String.isNotBlank(currentEmail.CcAddress) && currentEmail.CcAddress.containsIgnoreCase(customSetting.Credit_Dispute_From_Email__c)) ||
          (String.isNotBlank(currentEmail.BccAddress) && currentEmail.BccAddress.containsIgnoreCase(customSetting.Credit_Dispute_From_Email__c)) ||
          (String.isNotBlank(currentEmail.Subject) && currentEmail.Subject.contains(StarTrack_Constants.CREDITCLAIM_INVSUBJECT) && String.isNotBlank(currentEmail.ToAddress) && currentEmail.ToAddress.containsIgnoreCase(customSetting.Credit_Dispute_From_Email__c)))){
            caseRec.Subject = customSetting.ST_Credit_Claim_Inbound_Email_Prefix__c + caseRec.Subject;
            caseRec.ResolutionCode__c = String.isBlank(caseRec.ResolutionCode__c) ? StarTrack_Constants.CASE_RESOLUTION_DUPLICATE : caseRec.ResolutionCode__c;
            caseRec.Status = StarTrack_Constants.CASE_STAT_CLOSED;
            caseRec.Enquiry_Type__c = String.isBlank(caseRec.Enquiry_Type__c) ? StarTrack_Constants.CASE_ENQUIRY_DEF : caseRec.Enquiry_Type__c;
            caseRec.Call_Purpose__c = String.isBlank(caseRec.Call_Purpose__c) ? StarTrack_Constants.CASE_PURPOSE_DEF : caseRec.Call_Purpose__c;
            caseRec.FCR__c = false;
        } else{
            if(customSetting.Check_for_Duplicate_Email__c){
                try{
                    duplicateEmailRec = [SELECT Id, ParentId, FromAddress, Subject FROM EmailMessage
                                WHERE Id != :currentEmail.Id AND FromAddress = :currentEmail.FromAddress AND Subject = :currentEmail.Subject AND CreatedDate >= :currentEmailDateTime LIMIT 1];
                } catch(Exception e){
                    duplicateEmailRec = null;
                }
                
            }else{
                duplicateEmailRec = null;
            }
            
            
            if(duplicateEmailRec == null){
                
                Map<String, StarTrackDefaultEmailAddresses__c> defaultAddress = StarTrackDefaultEmailAddresses__c.getAll();
                if((caseRec.StarTrack_Calc_Email_Address__c.contains(customSetting.Business_Solutions_From_Email__c) || caseRec.StarTrack_Calc_Email_Address__c.contains(customSetting.Investigators_From_Email__c)) &&
                    StarTrack_Constants.CASE_DELIVERY_RT.equals(caseRec.RecordType.Name) && !caseRec.Auto_Email_Response_sent__c){
                    caseRec.Send_Auto_Response_Email__c = true;
                } else if((StarTrack_Constants.CASE_CREDIT_RT.equals(caseRec.RecordType.Name) || StarTrack_Constants.CASE_VOC_RT.equals(caseRec.RecordType.Name)) && !caseRec.Auto_Email_Response_sent__c){
                    caseRec.Send_Auto_Response_Email__c = true;
                }
                
                if(defaultAddress.containsKey(caseRec.StarTrack_Calc_Email_Address__c) && defaultAddress.get(caseRec.StarTrack_Calc_Email_Address__c).From_Email_Address__c != null &&
                   defaultAddress.get(caseRec.StarTrack_Calc_Email_Address__c).From_Email_Address__c != caseRec.StarTrack_Calc_Email_Address__c){
                    caseRec.StarTrack_Calc_Email_Address__c = defaultAddress.get(caseRec.StarTrack_Calc_Email_Address__c).From_Email_Address__c;
                }
                
            } else {
                caseRec.Subject = StarTrack_Constants.DUPLICATE_EMAIL + caseRec.Subject;
                caseRec.ResolutionCode__c = StarTrack_Constants.CASE_RESOLUTION_DUPLICATE;
                caseRec.Status = StarTrack_Constants.CASE_STAT_CLOSED;
                caseRec.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_DEF;
                caseRec.Call_Purpose__c = StarTrack_Constants.CASE_PURPOSE_DEF;
            }
        }
        
        Database.update(caseRec);
    }
    
    /*------------------------------------------------------------
    Author:        David Catindoy
    Company:       Accenture
    Description:   Logic that will close related Tasks
    Inputs:        List of Task records.
    Returns:       None
    History:
    August 24, 2016 - David Catindoy - Created
    August 24, 2021 - Steve Judd - Updated to only set status if the task is open
    ------------------------------------------------------------*/
    public static void closeCaseTask(List<Task> taskList){

        if(!taskList.isEmpty()) {
            for (Task thisTask : taskList) {
                if(thisTask.IsClosed == false) {
                    thisTask.Status = StarTrack_Constants.TASK_STATUS_FINISHED;
                }
                if (String.isBlank(thisTask.Resolution_Code__c)) {
                    thisTask.Resolution_Code__c = StarTrack_Constants.TASK_RESOLUTION_CODE;
                }
                thisTask.Bulk_Close__c = StarTrack_Constants.ST_TRUE;
                thisTask.Finished_Date__c = Datetime.now();
            }
            //Call method to calculate specific time field values.
            setStatusDate(taskList);
        }
    }
    
    /*------------------------------------------------------------
    Author:        David Catindoy
    Company:       Accenture
    Description:   Logic that will close related WF records
    Inputs:        List of WF records.
    Returns:       None
    History:
    August 24, 2016 - David Catindoy - Created
    ------------------------------------------------------------*/
    public static void closeCaseWF(List<workflow_Email__c> wfList){

        if(!wfList.isEmpty()){
            for(workflow_Email__c wfRec : wfList){
                wfRec.Status__c = StarTrack_Constants.WFE_STATUS_CLOSE;
            }
        }

        Database.update(wfList, false);
    }
    
    public static void updateCallLogSync(List<Id> caseIdList){
        updateCallLogDetail(caseIdList);
    }
    
    @future
    public static void updateCallLogAsync(List<Id> caseIdList){
        updateCallLogDetail(caseIdList);
    }
    
    /*------------------------------------------------------------
    Author:        David Catindoy
    Company:       Accenture
    Description:   Method that will update call log activity based on the changes made on the parent case.
    Inputs:        List of case Ids.
    Returns:       None
    September 1, 2016 - David Catindoy - Created
    ------------------------------------------------------------*/
    public static void updateCallLogDetail(List<Id> caseIds){
        
        Map<Id, Case> caseList = new Map<Id, Case>([SELECT Id, Direction__c, Recent_Caller_First_Name__c, Recent_Caller_Last_Name__c, Recent_Caller_Type__c, Call_Purpose__c, Recent_Caller_Email__c, Recent_Caller_Phone_Number__c, Recent_Caller_Pref_Method_of_Contact__c,
                                                    Number_of_Callers__c FROM Case WHERE Id IN :caseIds]);
        List<Task> taskList = [SELECT Id, Call_Log_Number__c, Description, Direction__c, Phone__c, Email__c, Pref_Method_of_Contact__c, Subject, WhatId FROM Task WHERE WhatId IN :caseList.keySet()];
        if(!taskList.isEmpty()){
            List<Task> validTaskList = new List<Task>();
            for(Task taskRec : taskList){
                Case parentCase = caseList.get(taskRec.WhatId);
                if(taskRec.Call_Log_Number__c == parentCase.Number_of_Callers__c && taskRec.Call_Log_Number__c > 0){
                    if(parentCase.Call_Purpose__c != null){
                        taskRec.Description = parentCase.Direction__c + StarTrack_Constants.CALLLOG_PREFIX + parentCase.Recent_Caller_First_Name__c + ' ' + parentCase.Recent_Caller_Last_Name__c + ' (' + parentCase.Recent_Caller_Type__c + ': ' + parentCase.Call_Purpose__c +')';
                    }
                    else{
                        taskRec.Description = parentCase.Direction__c + StarTrack_Constants.CALLLOG_PREFIX + parentCase.Recent_Caller_First_Name__c + ' ' + parentCase.Recent_Caller_Last_Name__c + ' (' + parentCase.Recent_Caller_Type__c + ')';
                    }
                    taskRec.Direction__c = parentCase.Direction__c;
                    taskRec.Email__c = parentCase.Recent_Caller_Email__c;
                    taskRec.Phone__c = parentCase.Recent_Caller_Phone_Number__c;
                    taskRec.Pref_Method_of_Contact__c = String.isBlank(parentCase.Recent_Caller_Pref_Method_of_Contact__c) ? StarTrack_Constants.TASK_NA : parentCase.Recent_Caller_Pref_Method_of_Contact__c;
                    taskRec.Subject = parentCase.Direction__c + StarTrack_Constants.CALLLOG_PREFIX + parentCase.Recent_Caller_First_Name__c + ' ' + parentCase.Recent_Caller_Last_Name__c + ' (' + parentCase.Recent_Caller_Type__c + ')';
                    validTaskList.add(taskRec);
                }
            }
            
            if(!validTaskList.isEmpty()){
                Database.update(validTaskList);
            }
        }
    }
    
    // ** StarTrack R4.0 and R4.1 ** //
    // ** transferred from CaseUtility - 09-23-2016 ** //
    //Close related tasks and workflow email records when StarTrack case records was closed or if close bulk tasks and workflow email records action was trigerred on the case.
    // Created by David Catindoy - August 25, 2016
    // TODO: Fix this dodgy piece of code.... Bad coding to update the same record again in its after update call
    public static void closeRelatedTasksAndWFEmails(Map<Id, Case> newCases, Map<Id, Case> oldCases) {
        
        //Initialize container
        List<Task> bulkTasks = new List<Task>();
        List<workflow_Email__c> bulkWF = new List<workflow_Email__c>();
        List<Task> closeTasks = new List<Task>();
        List<workflow_Email__c> closeWF = new List<workflow_Email__c>();
        //List<Case> caseList = new List<Case>();
        List<Case> bulkCase = new List<Case>();
        //List<Case> fcrCases = new List<Case>();

        // only process StarTrack cases, everything else should be ignored
        Map<Id, Case> processableCases = new Map<Id, Case>();
        for(Case newCase : newCases.values()) {
            if(newCase.StarTrack_RecordType__c) {
                processableCases.put(newCase.Id, newCase);
            }
        }

        if(!processableCases.isEmpty()) {
            processableCases = new Map<Id, Case>([
                    SELECT Id, RecordType.Name, Status, FCR__c, Close_Bulk_Tasks__c, BusinessHoursId, CreatedDate, ClosedDate, Case_Resolution_Time_in_Min__c, Enquiry_Type__c, (
                            SELECT Id, Resolution_Code__c, Status, Sub_Type__c, WhatId, Waiting_for_Operations_Date__c, Acknowledged_Date__c, CreatedDate, Finished_Date__c, Operations_to_Acknowledged_Time__c, Operations_to_Finished_Time__c,
                                    Create_to_Finished_Time__c, IsClosed
                            FROM Tasks
                            WHERE IsClosed = false AND IsRecurrence = false
                    ), (SELECT Id, Email_Type__c, Workflow_Email_Alert__c, Status__c FROM Workflow_Emails__r WHERE Status__c != :StarTrack_Constants.WFE_STATUS_CLOSE)
                    FROM Case
                    WHERE Id IN :processableCases.keySet()
            ]);
            System.debug('~~ processableCases : ' + processableCases);
            for (Case caseRec : processableCases.values()) {

                Case oldCaseRec = oldCases.get(caseRec.Id);
                //Check if bulk close action was triggered
                if (StarTrack_Constants.CASE_DELIVERY_RT.equals(caseRec.RecordType.Name) && !StarTrack_Constants.CASE_STAT_CLOSED.equals(caseRec.Status) && caseRec.Close_Bulk_Tasks__c && caseRec.Close_Bulk_Tasks__c != oldCaseRec.Close_Bulk_Tasks__c) {

                    bulkTasks.addAll(caseRec.Tasks);
                    bulkWF.addAll(caseRec.Workflow_Emails__r);
                    caseRec.Close_Bulk_Tasks__c = StarTrack_Constants.ST_FALSE;
                    bulkCase.add(caseRec);
                } else if (((StarTrack_Constants.CASE_STAT_CLOSED.equals(caseRec.Status) && !StarTrack_Constants.CASE_STAT_PENCUSNOTIF.equals(oldCaseRec.Status)) || //Check if case record itself was closed.
                        (StarTrack_Constants.CASE_DELIVERY_RT.equals(caseRec.RecordType.Name) && StarTrack_Constants.CASE_STAT_INTEGRATION.equals(caseRec.Status))) && !caseRec.Status.equals(oldCaseRec.Status)) {

                    closeTasks.addAll(caseRec.Tasks);
                    closeWF.addAll(caseRec.Workflow_Emails__r);

                    // This was creating an additional DML statement re-updating the same case
                    //  This is pointless given that it can be done in a beforeUpdate trigger
                    //  This is now done in StarTrackUtil.processFCRFlag
                    //                    if (StarTrack_Constants.CASE_STATUS_NEW.equals(oldCaseRec.Status) && !caseRec.FCR__c) {
                    //                        caseRec.FCR__c = StarTrack_Constants.ST_TRUE;
                    //                        fcrCases.add(caseRec);
                    //                    }

                    // This was creating an additional DML statement re-updating the same case in the same transaction which is confusing and can create unintended consequences..
                    //  This is now called from StarTrackUtil.calculateResolutionTime and executes  queueable which has now also been refactored.
                    //                if(StarTrack_Constants.CASE_STAT_CLOSED.equals(caseRec.Status) && !StarTrack_Constants.CASE_STAT_REOPENED.equals(oldCaseRec.Status) && !StarTrack_Constants.SYSTEM_SUPPORT_USER.equals(UserInfo.getName())){
                    //                    caseList.add(caseRec);
                    //                }
                }
            }

            // TODO: Fix. This is re-updating the same record.. not good practice.
            if (!bulkCase.isEmpty()) {
                update bulkCase;
            }

            if (!bulkTasks.isEmpty()) {
                List<Task> validTasks = new List<Task>();
                for (Task taskRec : bulkTasks) {
                    //Filter only those tasks created via bulk create action.
                    if (StarTrack_Constants.TASK_SUBTYPE_MASSTASKING.equals(taskRec.Sub_Type__c)) {
                        validTasks.add(taskRec);
                    }
                }

                if (!validTasks.isEmpty()) {
                    //Call method to close all task records passed in the parameter.
                    StarTrackUtil.closeCaseTask(validTasks);
                }
            }

            if (!bulkWF.isEmpty()) {
                List<workflow_Email__c> validWFList = new List<workflow_Email__c>();
                for (workflow_Email__c wfRec : bulkWF) {
                    //Filter only workflow records created via bulk create action.
                    if (StarTrack_Constants.TASK_SUBTYPE_MASSTASKING.equals(wfRec.Email_Type__c)) {
                        wfRec.Workflow_Email_Alert__c = StarTrack_Constants.OPS_CLOSETASK_VIA_EMAIL;
                        validWFList.add(wfRec);
                    }
                }

                if (!validWFList.isEmpty()) {
                    //Call method to close all workflow email records passed in the parameter.
                    StarTrackUtil.closeCaseWF(validWFList);
                }
            }

            // Read comments above
            //            if (!fcrCases.isEmpty()) {
            //                //Call method to calculate the resolution time of the case.
            //                Database.update(fcrCases);
            //            }

            if (!closeTasks.isEmpty()) {
                System.debug('List of tasks to close: ' + closeTasks);
                //Call method to close all task records passed in the parameter.
                StarTrackUtil.closeCaseTask(closeTasks);
            }

            if (!closeWF.isEmpty()) {
                //Call method to close all workflow email records passed in the parameter.
                StarTrackUtil.closeCaseWF(closeWF);
            }

            // Read comments above
            //        if(!caseList.isEmpty()){
            //            //Call method to calculate the resolution time of the case.
            //            StarTrackUtil.calculateResolutionTime(caseList);
            //        }
        }
        
    }

    /**
     * Logic to calculate the total Case resolution time with regards to Business Hours in the mapped Network
     * This is done in the afterUpdate case trigger because ClosedDate will not be accessible until the record has fully saved.
     */
    public static void calculateResolutionTime(List<Case> caseList, Map<Id, Case> oldCases) {

        Set<String> closedStatuses = Utility.getCaseClosedStatus();
        Set<Id> casesToProcess = new Set<Id>();

        // get only the records that need processing (either records that have never passed through here, or where the values of tracked fields have changed since it was last processed)
        List<Case> processableCases = (List<Case>)RecursionUtility.getUnprocessedRecords('ST-calculateResolutionTime', caseList, new Set<String>{'Status', 'RecordTypeId'});
        for(Case caseRec : processableCases) {

            Case oldCaseRec = oldCases.get(caseRec.Id);
            String currentStatus = caseRec.Status;
            String previousStatus = oldCaseRec.Status;

            // its not clear why StarTrack_Constants.SYSTEM_SUPPORT_USER.equals(UserInfo.getName()) is needed
            if (caseRec.StarTrack_RecordType__c && closedStatuses.contains(currentStatus) && currentStatus != previousStatus && !StarTrack_Constants.SYSTEM_SUPPORT_USER.equals(UserInfo.getName())) {
                casesToProcess.add(caseRec.Id);
            }
        }

        // queue an async job up to process the case resolution time to force the update into a new transaction
        if(!casesToProcess.isEmpty()) {
            System.enqueueJob(new AsyncCalculateResolutionTimeQueueable(casesToProcess));
        }
    }

    /**
     * This is called from calculateResolutionTime and will reset the Resolution time on the case.
     * This is trigger in an after update method call since the ClosedDate is not available until after the record is saved
     * Rather than doing this in the after update trigger and re-trigger a save process int he same transaction, we split it out into a separate queueable
     */
    public class AsyncCalculateResolutionTimeQueueable implements Queueable {
        private Set<Id> caseIds;

        public AsyncCalculateResolutionTimeQueueable(Set<Id> caseIds) {
            this.caseIds = caseIds;
        }

        public void execute(System.QueueableContext context) {
            List<Case> casesToUpdate = new List<Case>();
            List<Case> cases = [Select Id, Case_Resolution_Time_in_Min__c, Status, IsClosed, BusinessHoursId, ClosedDate, CreatedDate From Case Where Id In :this.caseIds];
            for(Case caseRec : cases) {
                if(caseRec.IsClosed && !String.isEmpty(String.valueOf(caseRec.ClosedDate))) {
                    Integer resolutionTime = Integer.valueOf(BusinessHours.diff(caseRec.BusinessHoursId, caseRec.CreatedDate, caseRec.ClosedDate) * 0.0000166667);
                    caseRec.Case_Resolution_Time_in_Min__c = resolutionTime;
                    casesToUpdate.add(caseRec);
                }
            }

            if(!casesToUpdate.isEmpty()) {
                update casesToUpdate;
            }
        }
    }
}