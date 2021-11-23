/*------------------------------------------------------------
Author:         David E. Catindoy
Company:        Cloud Sherpas
Description:    Class Extension for Sorry We Missed You page.
Parameters:     N/A
Returns:        N/A
History:
                August 27, 2015 - David E. Catindoy - Created
                September 7, 2015 - David E. Catindoy - Finalize
                November 25, 2015 - Patrick James Franco - Removed StandardController in order to use with Quick Action PA
                September 8, 2016 - David Catindoy - Modify to add addtional controller for US1390.
				October 29, 2018 - Nanda Kothamasu - Modified code to capture  the ATL delivery instructions REQ1591904
				October 28, 2020 - Suman Gunaganti - Removed reference to Activity-Case address DPID field post the discussion and agreement with
                                                     Webb, Joel (VIC) <Joel.Webb@startrack.com.au> & Santos, Erick Erick.Santos@startrack.com.au;
    ------------------------------------------------------------*/
public with sharing class StarTrackCardLeft_ControllerX {

    //Public variables
    public List<BusinessHours> businessHour {get; set;}
    public Case caseRecord {get; set;}
    public Billing_Account__c billingAccount {get; set;}
    public AddressExtension deliveryAddress {get; set;}
    public String dpid {get; set;}
    public Boolean hasEnquiryTypeError {get; set;}
    public Boolean hasATLError {get; set;}
    public Boolean hasATLWarning {get; set;}
    public Boolean hasSaveError {get; set;}
    public Boolean hasDeliveryDateMessage {get; set;}
    public Boolean isWithin {get; set;}
    public Boolean isOverride {get; set;}
    public Boolean validation {get; set;}
    public Boolean cardLeftAllowed {get; set;}
    public Boolean fromVF {get; set;}
    public Boolean saveButtonClick {get; set;}

    /*------------------------------------------------------------
    Author:         David E. Catindoy
    Company:        Cloud Sherpas
    Description:    Class Controller (variable iniatialization occurs)
    Inputs:         None
    Returns:        None
    History:
    August 27, 2015 - David E. Catindoy - Created
    ------------------------------------------------------------*/
    public StarTrackCardLeft_ControllerX(){ //Constrictor for VF page
        fromVF = true;
        initialize(ApexPages.CurrentPage().getParameters().get(StarTrack_Constants.ID_FIELD));
    }
    
    public StarTrackCardLeft_ControllerX(String caseId){ //Constructor for other apex classes referencing this controller including PB (Process Builder)
        fromVF = false;
        initialize(caseId);
    }
    
    public void initialize(String caseId){  //Method to initialize every variables used in this controller.
        //Query case record using the case id passed as a parameter.
        caseRecord = [SELECT Id, Delivery_Address_Line_1__c, Delivery_Address_Line_2__c, Delivery_Address_Suburb__c, Delivery_Address_State__c, Delivery_Address_Post_Code__c, Delivery_Address_DPID__c, Call_Purpose__c, ArticleTest__r.Receiver_Suburb__c,
                             Enquiry_Type__c, Business_Name__c, Phone__c, Delivery_Collection_Date__c, ATL__c, StarTrack_Receiver_Name__c, ATL_Allowed_Billing_Accounts__c, ATL_Instructions__c, Authorization_Origin__c, Network__r.Parent_Network__c,
                             Other_ATL_Instructions__c, Article_Receiver_Name__c, ArticleTest__r.STServiceType__c, Network__r.Preferred_Method_of_Tasking__c, ArticleTest__r.Network__r.City__c, ArticleTest__r.Network__r.Country__c, ArticleTest__r.Network__r.State__c,
                             ArticleTest__r.ReceiverName__c, Override_Customer_Restriction__c, Override_Customer_Restriction_Reason__c, Override_Allow_ATL__c, DeliveryInstructions__c, Description, Network__c, ArticleTest__c, BusinessHoursId,
                             Network__r.Parent_Network__r.Preferred_Method_of_Tasking__c, ArticleTest__r.ReceiverPostcode__c, Priority, Calc_Case_Consignment__c, Network__r.Parent_Network__r.Name, Network__r.Name, Network__r.Parent_Network__r.Email__c,
                             Network__r.Email__c, ArticleTest__r.Unit_Type__c, ArticleTest__r.ActualWeight__c, ArticleTest__r.Number_of_Items__c, Additional_Information__c, ArticleTest__r.Billing_Account__c, ArticleTest__r.Network__c, Related_Billing_Account__c
                             FROM Case WHERE ID =: caseId];
                             
        caseRecord.Additional_Information__c = String.isNotBlank(caseRecord.Additional_Information__c) ? caseRecord.Additional_Information__c + '\n\n' : '';
        if(String.isBlank(caseRecord.Network__c) || String.isBlank(caseRecord.ArticleTest__c)){
            if(fromVF){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_NULLCONSIGNORDEPOT) != null ?
                StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_NULLCONSIGNORDEPOT).Value__c : StarTrack_Constants.ERRORDEFMSG_NULLCONSIGNORDEPOT));
            }else{
                caseRecord.Additional_Information__c += StarTrack_Constants.ERRORDEFMSG_NULLCONSIGNORDEPOT + ' \n';
                Database.update(caseRecord);
            }
            cardLeftAllowed = false;
            
        } else if(String.isBlank(caseRecord.Related_Billing_Account__c) && String.isBlank(caseRecord.ArticleTest__r.Billing_Account__c)){
            if(fromVF){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Constants.ERRORMSG_BILLINGACCOUNTNULL));
            }else{
                caseRecord.Additional_Information__c += StarTrack_Constants.ERRORMSG_BILLINGACCOUNTNULL + ' \n';
                Database.update(caseRecord);
            }
            cardLeftAllowed = false;
        } else{
            deliveryAddress = new AddressExtension(caseRecord.Delivery_Address_Line_1__c, caseRecord.Delivery_Address_Line_2__c, caseRecord.Delivery_Address_Suburb__c, caseRecord.Delivery_Address_State__c, caseRecord.Delivery_Address_Post_Code__c, caseRecord.Delivery_Address_DPID__c, 'AU');
            dpid = '';
            defaultFlag();
            isWithin = false;
            validation = false;
            isOverride = false;
            saveButtonClick = false;
            cardLeftAllowed = true;
            caseRecord.Call_Purpose__c = StarTrack_Constants.CASEPURPOSE_CARDLEFT;
            caseRecord.Override_Allow_ATL__c = false;
            caseRecord.Override_Customer_Restriction__c = false;
            caseRecord.Override_Customer_Restriction_Reason__c = '';
            caseRecord.StarTrack_Receiver_Name__c = String.isBlank(caseRecord.StarTrack_Receiver_Name__c) ? caseRecord.ArticleTest__r.ReceiverName__c:caseRecord.StarTrack_Receiver_Name__c;
            businessHour = [SELECT Id, Name FROM BusinessHours WHERE Id = :caseRecord.BusinessHoursId];
            billingAccount = [SELECT Id, Calc_Depot_Collection__c, Calc_Redirection__c, Calc_Redelivery__c, Calc_Authority_to_leave__c FROM Billing_Account__c WHERE Id = :(String.isNotBlank(caseRecord.Related_Billing_Account__c) ? caseRecord.Related_Billing_Account__c : caseRecord.ArticleTest__r.Billing_Account__c)];
            
            if(String.isNotBlank(caseRecord.Enquiry_Type__c)){
                //Determine if controller is currently being called by the VF page.
                if(fromVF){
                    validateDeliveryDate();
                } else{
                    validateDeliveryDate();
                    if(!(hasEnquiryTypeError || hasATLError || hasDeliveryDateMessage)){
                        updateCase();
                    } else{
                        Database.update(caseRecord);
                    }
                }
            }
        }
    }

    /*------------------------------------------------------------
    Author:         Patrick James Franco
    Company:        Cloud Sherpas
    Description:    Method that will invoke a Case update
    Inputs:         None
    Returns:        None
    History:
    August 12, 2015 - Patrick James Franco - Created
    August 27, 2015 - David E. Catindoy - Modified
    ------------------------------------------------------------*/
    public void updateCase(){
        Boolean hasError = validateOverride();
        saveButtonClick = true;
        validateDeliveryDate();
        
        if(!hasError && !hasDeliveryDateMessage){
            defaultFlag();
            if(StarTrack_Constants.CASEENTYPE_CHECKADDRESS.equals(caseRecord.Enquiry_Type__c) || StarTrack_Constants.CASE_ENQUIRY_REDIRECTION.equals(caseRecord.Enquiry_Type__c)){
                if(String.isBlank(caseRecord.Business_Name__c) || String.isBlank(caseRecord.Phone__c) || String.isBlank(String.valueOf(caseRecord.Delivery_Collection_Date__c))){
                    caseRecord.Additional_Information__c += StarTrack_Constants.ERRORMSG_MANDATORY1 + ' \n';
                    if(fromVF){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_MANDATORY1) != null ?
                        StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_MANDATORY1).Value__c : StarTrack_Constants.ERRORMSG_MANDATORY1));
                    }
                    hasSaveError = true;
                } else if(String.isNotBlank(deliveryAddress.line1) && String.isNotBlank(deliveryAddress.city) && String.isNotBlank(deliveryAddress.state) && String.isNotBlank(deliveryAddress.postcode)){
                    caseRecord.Delivery_Address_Line_1__c = deliveryAddress.line1;
                    caseRecord.Delivery_Address_Line_2__c = deliveryAddress.line2;
                    caseRecord.Delivery_Address_Suburb__c = deliveryAddress.city;
                    caseRecord.Delivery_Address_State__c = deliveryAddress.state;
                    caseRecord.Delivery_Address_Post_Code__c = deliveryAddress.postcode;
                    caseRecord.Delivery_Address_DPID__c = dpid;
                    try{
                        createChildRecord();
                        validation = true;
                    } catch(DMLException e){
                        caseRecord.Additional_Information__c += e.getDmlMessage(0) + ' \n';
                        if(fromVF){
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
                        }
                        hasSaveError = true;
                    }
                } else {
                    caseRecord.Additional_Information__c += StarTrack_Constants.ERRORMSG_ADDRESSMISSING + ' \n';
                    if(fromVF){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_ADDRESSMISSING) != null ?
                        StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_ADDRESSMISSING).Value__c : StarTrack_Constants.ERRORMSG_ADDRESSMISSING));
                    }
                    hasSaveError = true;
                }
            } else{
                 if(String.isBlank(caseRecord.Phone__c) || String.isBlank(String.valueOf(caseRecord.Delivery_Collection_Date__c))){
                    caseRecord.Additional_Information__c += StarTrack_Constants.ERRORMSG_MANDATORY2 + ' \n';
                    if(fromVF){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_MANDATORY2) != null ? 
                        StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_MANDATORY2).Value__c : StarTrack_Constants.ERRORMSG_MANDATORY2));
                    }
                    hasSaveError = true;
                 } else{
                    try{
                            createChildRecord();
                            validation = true;
                    } catch(DMLException e){
                        caseRecord.Additional_Information__c += e.getDmlMessage(0) + ' \n';
                        if(fromVF){
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
                        }
                        hasSaveError = true;
                    }
                 }

            }

            Id deliveryEnquiry = Schema.SObjectType.Case.getRecordTypeInfosByName().get(StarTrack_Constants.CASE_DELIVERY_RT).getRecordTypeId();            
            if (!hasSaveError && deliveryEnquiry.equals(caseRecord.RecordTypeId) 
                && StarTrack_Constants.TASK_INTERACTION.equals(caseRecord.Authorization_Origin__c) && caseRecord.ATL__c) {
                notifyCaseChange(caseRecord.Id);                
            }

        } else{
            hasSaveError = true;
        }

    }
    
    //Method to create case child record/s and update case record status if child creation is allowed.
    //September 18, 2017 -  Disha Kariya - Modified to add Minor work - MW0001979.
    public void createChildRecord(){
        StarTrack_Settings__c stSettingsCCR = StarTrack_Settings__c.getOrgDefaults();
        if(StarTrack_Constants.NETWORK_PREFMETHOFTASKING_SYSTEM.equals(caseRecord.Network__r.Preferred_Method_of_Tasking__c) || 
          (StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PARENT.equals(caseRecord.Network__r.Preferred_Method_of_Tasking__c) &&
          (StarTrack_Constants.NETWORK_PREFMETHOFTASKING_SYSTEM.equals(caseRecord.Network__r.Parent_Network__r.Preferred_Method_of_Tasking__c) || StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PARENT.equals(caseRecord.Network__r.Parent_Network__r.Preferred_Method_of_Tasking__c)))){
            caseRecord.Status = StarTrack_Constants.CASE_STATUS_WAITINGOPERATIONS;
            // SWMY Redelivery TEMP Queue Change
            if(StarTrack_Constants.CASE_ENQUIRY_REDELIVERY.equals(caseRecord.Enquiry_Type__c)) caseRecord.OwnerId = stSettingsCCR.SWMYTempQueue__c;
            Database.update(caseRecord);
            createTask();
        } else if(StarTrack_Constants.NETWORK_PREFMETHOFTASKING_EMAIL.equals(caseRecord.Network__r.Preferred_Method_of_Tasking__c) || 
                 (StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PARENT.equals(caseRecord.Network__r.Preferred_Method_of_Tasking__c) &&
                 StarTrack_Constants.NETWORK_PREFMETHOFTASKING_EMAIL.equals(caseRecord.Network__r.Parent_Network__r.Preferred_Method_of_Tasking__c))){
            caseRecord.Status = StarTrack_Constants.CASE_STATUS_WAITINGOPERATIONS;
            Database.update(caseRecord);
            createWFE();
        } else{
            Database.update(caseRecord);
        }
    }
    
    /*------------------------------------------------------------
    Author:         David Catindoy
    Company:        Accenture
    Description:    Method that will create an operation task after case update
    Inputs:         None
    Returns:        None
    History:
    July 7, 2016 - David E. Catindoy - Created
    ------------------------------------------------------------*/
    private void createTask(){
        Task newTask = new Task();
        newTask.WhatId = caseRecord.Id;
        newTask.CaseObject__c = caseRecord.Id;
        newTask.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(StarTrack_Constants.TASK_RECTYPE_OPERATION).getRecordTypeId();
        newTask.Type = StarTrack_Constants.TASK_TYPE_OPERATION;
        newTask.Subject = caseRecord.Call_Purpose__c + ' ' + caseRecord.Enquiry_Type__c;
        newTask.Case_Business_Name__c = caseRecord.Business_Name__c;
        newTask.Case_Phone__c = caseRecord.Phone__c;
        newTask.Case_Delivery_Collection_Date__c = caseRecord.Delivery_Collection_Date__c;
        newTask.Case_Delivery_Instructions__c = caseRecord.DeliveryInstructions__c;
       
        /*
         * Request:  Provide Authority To Leave(ATL) with instuctions in Task record when user provided those details on the Track card form.
         * Soluiton: (REQ1591904) If ATL flag is enabled, in the Task record 'Manage Delivery Details' are available with  
          			 ATL instructions (if available) &  Authority To Leave information.  
        */
         if(caseRecord.ATL__c == true){
             if(caseRecord.ATL_Instructions__c == '' || caseRecord.ATL_Instructions__c == null ){
                 newTask.Case_ATL_Instructions__c = ' - /  Authority To Leave';
             }else{
                 newTask.Case_ATL_Instructions__c = caseRecord.ATL_Instructions__c +' /  Authority To Leave';
             }
            
        }else{
            newTask.Case_ATL_Instructions__c = '';
        } 
        
        newTask.Case_Other_ATL_Instructions__c = caseRecord.Other_ATL_Instructions__c;
        newTask.Case_Authorization_Origin__c = caseRecord.Authorization_Origin__c;
        newTask.Case_Override_Customer_Restriction__c = caseRecord.Override_Customer_Restriction_Reason__c;
        newTask.Network__c = StarTrackTaskingRuleUtility.networkId(caseRecord);
        newTask.Status = StarTrack_Constants.TASK_STATUS_WAITING;
        PostcodeMapping__c pcm = queryPostCodeMapping(caseRecord.ArticleTest__r.ReceiverPostcode__c, caseRecord.ArticleTest__r.Receiver_Suburb__c, newTask.Network__c);
        newTask.Run_Dock__c =  pcm != null ? pcm.Run_Dock__c : null;
        newTask.Bulk__c = pcm != null ? pcm.Bulk__c : null;
        newTask.Depot_Role__c = (StarTrackTaskingRuleUtility.taskingRule(new List<Case>{caseRecord}).containsKey(caseRecord.Id) ? StarTrackTaskingRuleUtility.taskingRule(new List<Case>{caseRecord}).get(caseRecord.Id).Id : null);
        newTask.Priority = caseRecord.Priority;
        newTask.Calculate_Run_Dock_and_Depot_Area__c = true;
        
        if(StarTrack_Constants.CASEENTYPE_CHECKADDRESS.equals(caseRecord.Enquiry_Type__c) || StarTrack_Constants.CASE_ENQUIRY_REDIRECTION.equals(caseRecord.Enquiry_Type__c)){
            newTask.Case_Address_Line__c = caseRecord.Delivery_Address_Line_1__c + ' ' + caseRecord.Delivery_Address_Line_2__c;
            newTask.Case_Address_Suburb__c = caseRecord.Delivery_Address_Suburb__c;
            newTask.Case_Address_State__c = caseRecord.Delivery_Address_State__c;
            newTask.Case_Address_Postcode__c = caseRecord.Delivery_Address_Post_Code__c;
            //newTask.Case_Address_DPID__c = caseRecord.Delivery_Address_DPID__c;
        }
        
        Database.insert(newTask);
    }
    
    /*------------------------------------------------------------
    Author:         David Catindoy
    Company:        Accenture
    Description:    Method that will create a workflow email record after case update
    Inputs:         None
    Returns:        None
    History:
    July 7, 2016 - David E. Catindoy - Created
    ------------------------------------------------------------*/
    private void createWFE(){
        workflow_Email__c wfe = new workflow_Email__c();
        wfe.Case__c = caseRecord.id;
        wfe.Status__c = StarTrack_Constants.WFE_STATUS_OPEN;
        wfe.Email_Type__c = StarTrack_Constants.TASK_SUBTYPE_SINGLETASKING;
        wfe.Task_Subject__c = caseRecord.Call_Purpose__c + ' ' + caseRecord.Enquiry_Type__c;
        wfe.Workflow_Email_Alert__c = StarTrack_Constants.OPS_NEWTASK_VIA_EMAIL;
        
        if(StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PARENT.equals(caseRecord.Network__r.Preferred_Method_of_Tasking__c) && String.isNotBlank(caseRecord.Network__r.Parent_Network__c)){
            wfe.Network_Name__c = caseRecord.Network__r.Parent_Network__r.Name;
            wfe.To_Address__c = caseRecord.Network__r.Parent_Network__r.Email__c;
        } else{
            wfe.Network_Name__c = caseRecord.Network__r.Name;
            wfe.To_Address__c = caseRecord.Network__r.Email__c;
        }
        
        Database.insert(wfe);
    }


    @future(callout=true)
    public static void notifyCaseChange(Id caseRecordId) {
    
        StarTrack_Settings__c stSettings = StarTrack_Settings__c.getOrgDefaults();
    
        Case caseRecord = [SELECT Id, Consignment_Unique_External_ID__c, CaseNumber, Connote_number__c FROM Case WHERE ID =: caseRecordId];
        StarTrack_Settings__c stCNSettings = StarTrack_Settings__c.getOrgDefaults();

        Map<String,String> httpHeaders = new Map<String,String>();
        httpHeaders.put('Authorization','Basic ' + stCNSettings.StarTrack_ConSearch_BA_Password__c);

        wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2 caseNotifyStubSync = new wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2();
        caseNotifyStubSync.endpoint_x = stCNSettings.StarTrack_ConSearch_BA_Endpoint__c;        
        caseNotifyStubSync.inputHttpHeaders_x = httpHeaders;

        wwwAuspostComAuSchemaCustomercarema.Header header = new wwwAuspostComAuSchemaCustomercarema.Header();
        wwwAuspostComAuSchemaCustomercarema.CaseNotification request = new wwwAuspostComAuSchemaCustomercarema.CaseNotification();

        DateTime nowDT = DateTime.now();
        header.TimeStamp = nowDT;
        header.TransactionId = UserInfo.getUserName() + '_' + (nowDT).format('YYYYMMddHHmmss');
        header.SourceId = 'Salesforce';

        request.Header = header;
        request.UniqueExternalId = caseRecord.Consignment_Unique_External_ID__c;
        request.CaseType = 'Delivery Enquiry Phone ATL';
        request.CaseNumber = caseRecord.CaseNumber;
        request.CaseId = caseRecord.Id;
        request.Consignment = caseRecord.Connote_number__c;
        request.UserAccount = UserInfo.getUserEmail();
        
        String reqTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();

        try {
            caseNotifyStubSync.CaseNotification(request);
            // REQUEST/RESPONSE LOG
            if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                StarTrackIntegrationLogging.logRequestResponse('StarTrackCardLeft_ControllerX', 'notifyCaseChange', '', 'INT-REQ - notifyCaseChange', reqTimeStamp, request);
            }            
        } catch (Exception e) {
            if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                StarTrackIntegrationLogging.logRequestResponse('StarTrackCardLeft_ControllerX', 'notifyCaseChange', '', 'INT-REQ - notifyCaseChange - ERROR', reqTimeStamp, request);
            }
            GlobalUtility.logMessage('ERROR', 'StarTrackCardLeft_ControllerX', 'notifyCaseChange', '', 'Exception', e.getMessage(), String.valueOf(request), e, 0);
        }
    }


    /*------------------------------------------------------------
    Author:         David E. Catindoy
    Company:        Cloud Sherpas
    Description:    This method returns the enquiry type values available for selection.
    Inputs:         None
    Returns:        List of enquiry type picklist values
    History:
    August 27, 2015 - David E. Catindoy - Created
    ------------------------------------------------------------*/
    public List<SelectOption> getEnquiryTypeValues() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', StarTrack_Constants.GLOBAL_NONE));
        options.add(new SelectOption(StarTrack_Constants.CASEENTYPE_CHECKADDRESS, StarTrack_Constants.CASEENTYPE_CHECKADDRESS));
        options.add(new SelectOption(StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION, StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION));
        options.add(new SelectOption(StarTrack_Constants.CASE_ENQUIRY_REDIRECTION, StarTrack_Constants.CASE_ENQUIRY_REDIRECTION));
        options.add(new SelectOption(StarTrack_Constants.CASE_ENQUIRY_REDELIVERY, StarTrack_Constants.CASE_ENQUIRY_REDELIVERY));
        return options;
    }

    /*------------------------------------------------------------
    Author:         David E. Catindoy
    Company:        Cloud Sherpas
    Description:    This method validates the enquiry type selected
    Inputs:         None
    Returns:        None
    History:
    August 27, 2015 - David E. Catindoy - Created
    ------------------------------------------------------------*/
    public PageReference validateEnquiryType(){
        if(!caseRecord.Override_Customer_Restriction__c){
            defaultFlag();
            if(StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION.equals(caseRecord.Enquiry_Type__c)){
                caseRecord.ATL__c = false;
                if(StarTrack_Constants.GLOBAL_NO.equals(billingAccount.Calc_Depot_Collection__c)){
                    addPageMessage(StarTrack_Constants.ENQ_NO);
                } else if(StarTrack_Constants.AUTHREQUIRED.equalsIgnoreCase(billingAccount.Calc_Depot_Collection__c)){
                    addPageMessage(StarTrack_Constants.ENQ_YES);
                }
            } else if (StarTrack_Constants.CASE_ENQUIRY_REDIRECTION.equals(caseRecord.Enquiry_Type__c)){
                if(StarTrack_Constants.GLOBAL_NO.equals(billingAccount.Calc_Redirection__c)){
                    addPageMessage(StarTrack_Constants.ENQ_NO);
                } else if(StarTrack_Constants.AUTHREQUIRED.equalsIgnoreCase(billingAccount.Calc_Redirection__c)){
                    addPageMessage(StarTrack_Constants.ENQ_YES);
                    validateATL();
                } else if(caseRecord.ArticleTest__r.STServiceType__c != null && caseRecord.ArticleTest__r.STServiceType__c.containsIgnoreCase(StarTrack_Constants.SERVICETYPE_AIRLOCK)){
                    addPageMessage(StarTrack_Constants.CARDLEFT_SERVICE);
                } else if(caseRecord.ATL__c){
                    validateATL();
                }
            } else if (StarTrack_Constants.CASE_ENQUIRY_REDELIVERY.equals(caseRecord.Enquiry_Type__c)){
                if(StarTrack_Constants.GLOBAL_NO.equals(billingAccount.Calc_Redelivery__c)){
                    addPageMessage(StarTrack_Constants.ENQ_NO);
                } else if(StarTrack_Constants.AUTHREQUIRED.equalsIgnoreCase(billingAccount.Calc_Redelivery__c)){
                    addPageMessage(StarTrack_Constants.ENQ_YES);
                    validateATL();
                } else if(caseRecord.ATL__c){
                    validateATL();
                }
            } else if (StarTrack_Constants.CASEENTYPE_CHECKADDRESS.equals(caseRecord.Enquiry_Type__c)){
                if(caseRecord.ATL__c){
                    validateATL();
                }
            }
        } else {
            isOverride = true;
            hasEnquiryTypeError = false;
            if(String.isBlank(caseRecord.Enquiry_Type__c)){
                caseRecord.Override_Customer_Restriction__c = false;
                caseRecord.Override_Customer_Restriction_Reason__c = '';
                isOverride = false;
            } else if(caseRecord.ATL__c){
                defaultFlag();
                if(!(StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION.equals(caseRecord.Enquiry_Type__c))){
                    validateATL();
                }
            }
        }

        return null;
    }

    public void changeEnquiryType(){
        caseRecord.Override_Customer_Restriction__c = false;
        caseRecord.Override_Customer_Restriction_Reason__c = '';
        isOverride = false;
        validateDeliveryDate();
        
    }

    /*------------------------------------------------------------
    Author:         David E. Catindoy
    Company:        Cloud Sherpas
    Description:    This method validates the ATL override
    Inputs:         None
    Returns:        None
    History:
    August 27, 2015 - David E. Catindoy - Created
    ------------------------------------------------------------*/
    public PageReference validateATL(){
        if(caseRecord.ATL__c && StarTrack_Constants.GLOBAL_NO.equals(billingAccount.Calc_Authority_to_leave__c)){
            if(!caseRecord.Override_Allow_ATL__c){
                //Error
                addPageMessage(StarTrack_Constants.ATL_NO);
            }

        } else if(caseRecord.ATL__c && StarTrack_Constants.AUTHREQUIRED.equalsIgnoreCase(billingAccount.Calc_Authority_to_leave__c)){
            if(!caseRecord.Override_Allow_ATL__c){
                //Warning
                addPageMessage(StarTrack_Constants.ATL_YES);
            }

        } else {
            defaultFlag();
        }
        return null;
    }

    /*------------------------------------------------------------
    Author:         David E. Catindoy
    Company:        Cloud Sherpas
    Description:    This method validates the delivery/collection date selected.
    Inputs:         None
    Returns:        None
    History:
    August 27, 2015 - David E. Catindoy - Created
    ------------------------------------------------------------*/
    public PageReference validateDeliveryDate(){
        hasDeliveryDateMessage = false;
        if(!saveButtonClick){
            validateEnquiryType();
        }
        if(String.isNotBlank(String.valueOf(caseRecord.Delivery_Collection_Date__c))){
           if(caseRecord.Delivery_Collection_Date__c <= Date.today()){
                if(!(caseRecord.Delivery_Collection_Date__c == Date.today() && StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION.equals(caseRecord.Enquiry_Type__c))){
                    hasDeliveryDateMessage = true;
                    caseRecord.Additional_Information__c += StarTrack_Constants.ERRORMSG_DATENOTALLOWED + ' \n';
                    if(fromVF){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_DATENOTALLOWED) != null ? 
                        StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_DATENOTALLOWED).Value__c : StarTrack_Constants.ERRORMSG_DATENOTALLOWED));
                    }
                } else if(caseRecord.Delivery_Collection_Date__c == Date.today() && StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION.equals(caseRecord.Enquiry_Type__c)){
                    validateDate(caseRecord.Delivery_Collection_Date__c);
                }
           } else{
                validateDate(caseRecord.Delivery_Collection_Date__c);
                if(!hasDeliveryDateMessage){
                     if(StarTrack_Constants.CASE_ENQUIRY_REDIRECTION.equals(caseRecord.Enquiry_Type__c)){
                        addPageMessage(StarTrack_Constants.DELIVERY);
                    } else if(StarTrack_Constants.CASE_ENQUIRY_REDELIVERY.equals(caseRecord.Enquiry_Type__c)){
                        addPageMessage(StarTrack_Constants.DELIVERY);
                    }
                }
            }
        }
        
        saveButtonClick = false;

        return null;
    }
    
    public PageReference validateDate(Date deliveryDate){
        Time myTime = Time.newInstance(5, 0, 0, 0);
        DateTime dt = DateTime.newInstanceGMT(deliveryDate, myTime);
        for(BusinessHours bh : businessHour){
            isWithin = BusinessHours.isWithin(bh.Id, dt);
            if(!isWithin){
                hasDeliveryDateMessage = true;
                caseRecord.Additional_Information__c += StarTrack_Constants.ERRORMSG_DATENOTVALID + ' \n';
                if(fromVF){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_DATENOTVALID) != null ? 
                    StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_DATENOTVALID).Value__c : StarTrack_Constants.ERRORMSG_DATENOTVALID));
                }
                break;
            }
        }
        return null;
    }

    /*------------------------------------------------------------
    Author:         David E. Catindoy
    Company:        Cloud Sherpas
    Description:    This method validates the override fields.
    Inputs:         None
    Returns:        None
    History:
    August 31, 2015 - David E. Catindoy - Created
    ------------------------------------------------------------*/
    public Boolean validateOverride(){
        if(caseRecord.Override_Customer_Restriction__c && String.isBlank(caseRecord.Override_Customer_Restriction_Reason__c)){
            caseRecord.Additional_Information__c += StarTrack_Constants.ERRORMSG_OVERRIDEREASON + ' \n';
            if(fromVF){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_OVERRIDEREASON) != null ?
                StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_OVERRIDEREASON).Value__c : StarTrack_Constants.ERRORMSG_OVERRIDEREASON)); 
            }
            return true;
        }
        return false;
    }

    /*------------------------------------------------------------
    Author:         David E. Catindoy
    Company:        Cloud Sherpas
    Description:    These methods set the boolean flag used for page rerending.
    Inputs:         None
    Returns:        None
    History:
    August 31, 2015 - David E. Catindoy - Created
    ------------------------------------------------------------*/
    public void defaultFlag(){
        hasEnquiryTypeError = false;
        hasATLError = false;
        hasATLWarning = false;
        hasSaveError = false;
        hasDeliveryDateMessage = false;
    }

    public void setEnquiryTypeErrorFlag(){
        hasEnquiryTypeError = true;
        hasATLError = false;
        hasATLWarning = false;
        isOverride = true;
    }

    public void setATLErrorFlag(){
        hasATLError = true;
        hasATLWarning = false;
        hasEnquiryTypeError = false;
        hasSaveError = false;
    }

    /*------------------------------------------------------------
    Author:         David E. Catindoy
    Company:        Cloud Sherpas
    Description:    This method is responsible for adding page messages.
    Inputs:         A string variable that will serve as an indicator.
    Returns:        None
    History:
    August 27, 2015 - David E. Catindoy - Created
    ------------------------------------------------------------*/
    public void addPageMessage(String source){
        
        if(StarTrack_Constants.ENQ_NO.equals(source)){
            setEnquiryTypeErrorFlag();
            caseRecord.Additional_Information__c += StarTrack_Constants.ERRORMSG_ENQUIRYTYPENOTALLOWED + caseRecord.Enquiry_Type__c + ' \n';
            if(fromVF){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_ENQUIRYTYPENOTALLOWED) != null ?
                StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_ENQUIRYTYPENOTALLOWED).Value__c + ' ' + caseRecord.Enquiry_Type__c + '.' :
                StarTrack_Constants.ERRORMSG_ENQUIRYTYPENOTALLOWED + caseRecord.Enquiry_Type__c));
            }
        } else if(StarTrack_Constants.ENQ_YES.equals(source) && StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_ENQUIRYTYPEAUTH) != null && fromVF){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_ENQUIRYTYPEAUTH).Value__c));
        } else if(StarTrack_Constants.CARDLEFT_SERVICE.equals(source)){
            setEnquiryTypeErrorFlag();
            caseRecord.Additional_Information__c += StarTrack_Constants.ERRORMSG_ERVICETYPENOTALLOWED + caseRecord.Enquiry_Type__c + ' \n';
            if(fromVF){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_SERVICETYPENOTALLOWED) != null ?
                StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_SERVICETYPENOTALLOWED).Value__c + ' ' + caseRecord.Enquiry_Type__c + '.' :
                StarTrack_Constants.ERRORMSG_ERVICETYPENOTALLOWED + caseRecord.Enquiry_Type__c));
            }
        } else if(StarTrack_Constants.ATL_SERVICE.equals(source)){
            setEnquiryTypeErrorFlag();
            caseRecord.Additional_Information__c += StarTrack_Constants.ERRORMSG_ATLSERVICENOTALLOWED + ' \n';
            if(fromVF){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_ATLSERVICENOTALLOWED) != null ?
                StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_ATLSERVICENOTALLOWED).Value__c :
                StarTrack_Constants.ERRORMSG_ATLSERVICENOTALLOWED));
            }
        }else if(StarTrack_Constants.ATL_YES.equals(source) && StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_ATLAUTH) != null){
            hasATLWarning= true;
            hasATLError = false;
            hasEnquiryTypeError = false;
            if(fromVF){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_ATLAUTH).Value__c));
            }
        } else if(StarTrack_Constants.ATL_NO.equals(source)){
            setATLErrorFlag();
            caseRecord.Additional_Information__c += StarTrack_Constants.ERRORMSG_ATLNOTALLOWED + ' \n';
            if(fromVF){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_ATLNOTALLOWED) != null ?
                StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_ATLNOTALLOWED).Value__c :
                StarTrack_Constants.ERRORMSG_ATLNOTALLOWED));
            }
        } else if(!hasEnquiryTypeError && StarTrack_Constants.DELIVERY.equals(source) && StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_DELIVERYDATE1) != null && StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_DELIVERYDATE2) != null && fromVF){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_DELIVERYDATE1).Value__c + ' ' + caseRecord.Enquiry_Type__c + ' ' + StarTrack_Error_Messages__c.getValues(StarTrack_Constants.ERROR_DELIVERYDATE2).Value__c));
        }
    }
    
    private PostcodeMapping__c queryPostCodeMapping(String postcode, String suburb, Id depotId){
        try{
            return [SELECT Run_Dock__c, Bulk__c FROM PostcodeMapping__c WHERE Network__c =: depotId
                    AND Postcode__r.Name =: postcode AND Postcode__r.Suburb__c =: suburb LIMIT 1];
        } catch(queryException e){
            System.debug(StarTrack_Constants.NORECORD_FOUND);
            return null;
        }
    }
}