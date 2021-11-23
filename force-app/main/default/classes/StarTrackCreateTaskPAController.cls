/**
 ** Description: Controller for StarTrackCreateTaskPA Page
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: AUG.20.2015
 ** History:--------------------------------------------
 **         AUG.23.2015 PAUL FAYLE - Modified
 **         AUG.28.2015 Patrick James Franco - Added validation to verify that Task is created
 **         OCT.15.2015 Patrick James Franco - Added validation to new Task Subject, Depot Filter, and State
 **                                          - Added Reference to Depot Filter for bulk tasks
 **         OCT.26.2015 Patrick James Franco - Added field mapping for Task sub type
 **         NOV.16.2015 Patrick James Franco - Added Depot Area defaulting to Driver Contact for Pickup Booking Enquiry
 **                                          - Renamed Parent_Network_Facility__c references to Parent_Network__c
 **         NOV.25.2015 Patrick James Franco - Removed StandardController in order to use with Quick Action PA
 **         DEC.09.2015 Patrick James Franco - Added new contructor with caseId parameter
 **                                          - Refactored the constructor logic into initialize method
 **         JAN.05.2016 David Catindoy       - Refactor create task method to include more logic to address some issues.
 **         JUl.29.2019 SaiSwetha Pingali    - Display message for case type ETA to choose a valida Depot - REQ1864272
 **/
public class StarTrackCreateTaskPAController {

    public Task newTask {get; set;}
    public Boolean fromVF {get;set;}
    public Case existingCase {get; set;}
    public Id starTrackTaskRecTypeId {get; set;}
    public Id selectedUserId {get; set;}
    public Boolean validation {get; set;}
    public network__c networkRec {get; set;}
    public String taskingmethod {get; set;}
    public case clonedCase {get; set;}
    public boolean disabledSubmitBtn {get; set;}
    public boolean prefMethodIsPhone {get; set;}
    public Boolean createTaskAllowed {get; set;}
    public Boolean disabledButton {get; set;}
    public Id pbenquiryRecType {get; set;}
    public String depotAreaId {get; set;}

    public StarTrackCreateTaskPAController(){
        existingCase = [SELECT Id, Origin, Status, Network__r.Parent_Network__c, Network__r.Email__c, ArticleTest__c, Network__c, Priority, Enquiry_Type__c, Network__r.Preferred_Method_of_Tasking__c, ArticleTest__r.ReceiverName__c, ArticleTest__r.ActualWeight__c,
                        ArticleTest__r.Number_of_Items__c, ArticleTest__r.Unit_Type__c, Network__r.RecordType.DeveloperName, ArticleTest__r.ReceiverPostcode__c, ArticleTest__r.Receiver_Suburb__c, RecordType.Name, StarTrack_Receiver_Name__c, Unit_Type__c,
                        Number_of_Items__c, Address4Postcode__c, Address4Suburb__c FROM Case WHERE ID =: ApexPages.CurrentPage().getParameters().get('Id')];
        pbenquiryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
        fromVF = true;
        initialize();
    }

    public StarTrackCreateTaskPAController(Id caseId){
        existingCase = [SELECT Id, OwnerId, Origin, Status, Network__r.Parent_Network__c, SuppliedEmail, Network__r.Email__c, ArticleTest__c, ArticleTest__r.Name, Network__c, Priority, Enquiry_Type__c, Network__r.Preferred_Method_of_Tasking__c, ArticleTest__r.ReceiverName__c,
                        ArticleTest__r.ActualWeight__c, ArticleTest__r.Number_of_Items__c, ArticleTest__r.Unit_Type__c, Network__r.RecordType.DeveloperName, ArticleTest__r.ReceiverPostcode__c, ArticleTest__r.Receiver_Suburb__c, RecordType.Name, StarTrack_Receiver_Name__c,
                        Unit_Type__c, Number_of_Items__c, Address4Postcode__c, Address4Suburb__c FROM Case WHERE ID = :caseId];
        pbenquiryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
        fromVF = false;
        initialize();
    }

    public void initialize(){
        depotAreaId = '';
        
        createTaskAllowed = true;
        //get record type id
        starTrackTaskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('StarTrack Task').getRecordTypeId();
        //Current user id, used in remote PA page.
        selectedUserId = UserInfo.getUserId();
        //Initialize task for and execute logic based on case attributes.
        initializeNewTask();
        //Validation variable to check of validaition is sucessful before save.
        validation = false;
        disabledSubmitBtn = FALSE;
        //On initialze and change of network field.
        changeNetworkfield();
    }

    public void initializeNewTask(){
        newTask = new Task();
        newTask.WhatId = existingCase.Id;
        newTask.RecordTypeId = starTrackTaskRecTypeId;
        newTask.Subject = null;
        if(existingCase.RecordType.Name == 'Credit Dispute Claim') {
            newTask.Type = StarTrack_Constants.TASK_TYPE_REMINDER;
        } else {
            newTask.Type = StarTrack_Constants.TASK_TYPE_OPERATION;
        }
        checkTaskType();
        //Added as part of REQ1864272
        checkCaseType(); 
    }
    //Added as part of REQ1864272
    //** method header -check if the Enquiry type on case is ETA then display a message to choose approrpiate Depot
     public void checkCaseType(){
         if(existingCase.Enquiry_Type__c =='ETA'){
             if(fromVF){
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, StarTrack_Error_Messages__c.getValues('CaseTypeETA_Depot').Value__c));
             }   
         }
     }
    public void checkTaskType(){
        if(newTask.Type == StarTrack_Constants.TASK_TYPE_REMINDER){
            newTask.ActivityDate = System.today();
            newTask.ReminderDateTime = System.now() + 0.0833;
            newTask.OwnerId = UserInfo.getUserId();
            newTask.IsReminderSet = true;
            newTask.network__c = null;
            newTask.Depot_Role__c = null;
            newTask.Run_Dock__c = null;
            newTask.CaseObject__c =  existingCase.Id;
            newTask.Status = StarTrack_Constants.TASK_STATUS_NOTSTARTED;
            newTask.Priority = StarTrack_Constants.TASK_PRIORITY_NORMAL;
            newTask.Is_Bulk_Task__c = FALSE;
            newTask.Depot_Filter__c = null;
            newTask.State__c = null;
            newTask.Interaction_Type__c = existingCase.Origin;
            newTask.Sub_Type__c = null;
            createTaskAllowed = true;
            disabledButton = false;
        } else if(newTask.Type == StarTrack_Constants.TASK_TYPE_OPERATION){
            if((existingCase.Network__c == null || existingCase.ArticleTest__c == null) && !existingCase.RecordTypeId.equals(pbenquiryRecType)){
                if(fromVF){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Error_Messages__c.getValues('Network/Consignment is NULL') != null ?
                    StarTrack_Error_Messages__c.getValues('Network/Consignment is NULL').Value__c : 'This action cannot be performed until a consignment and receiving depot is associated to the case.'));
                }
                createTaskAllowed = false;
            } else if(String.isNotBlank(existingCase.Network__c) && existingCase.Network__r.Preferred_Method_of_Tasking__c == 'Email' && existingCase.RecordType.Name.equals('Transit Warranty Claim')){
                if(fromVF){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Error_Messages__c.getValues('Preferred Method Tasking Not Allowed') != null ?
                    StarTrack_Error_Messages__c.getValues('Preferred Method Tasking Not Allowed').Value__c : 'Preferred method of tasking is not allowed for transit warranty claim case record.'));
                }
                newTask.network__c = existingCase.Network__c;
                disabledButton = true;
            } else if(existingCase.RecordTypeId.equals(pbenquiryRecType) && String.isBlank(existingCase.Network__c)){
                if(fromVF){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Error_Messages__c.getValues('PBE Require Network') != null ?
                    StarTrack_Error_Messages__c.getValues('PBE Require Network').Value__c : 'This action cannot be performed until a receiving depot is associated to the case.'));
                }
                createTaskAllowed = false;
            } else if(String.isBlank(existingCase.Enquiry_Type__c)){
                if(fromVF){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Case Type is required when creating an operation task.'));
                }
                createTaskAllowed = false;
            } else{
                newTask.CaseObject__c =  existingCase.Id;
                if(String.isBlank(existingCase.ArticleTest__r.ReceiverPostcode__c) && String.isBlank(existingCase.ArticleTest__r.Receiver_Suburb__c) && !existingCase.RecordTypeId.equals(pbenquiryRecType)){
                 existingCase.ArticleTest__r.ReceiverName__c = existingCase.StarTrack_Receiver_Name__c;
                 existingCase.ArticleTest__r.Unit_Type__c = existingCase.Unit_Type__c;
                 existingCase.ArticleTest__r.Number_of_Items__c = existingCase.Number_of_Items__c;
                 existingCase.ArticleTest__r.ReceiverPostcode__c = existingCase.Address4Postcode__c;
                 existingCase.ArticleTest__r.Receiver_Suburb__c = existingCase.Address4Suburb__c;
                 existingCase.ArticleTest__r.ActualWeight__c = null;
                }
    
                if(newTask.Is_Bulk_Task__c){
                    newTask.network__c = null;
                    newTask.Depot_Role__c = null;
                    newTask.Run_Dock__c = null;
                    networkRec = null;
                    newTask.Sub_Type__c = StarTrack_Constants.TASK_SUBTYPE_MASSTASKING;
                }else{
                    
                    newTask.Sub_Type__c = StarTrack_Constants.TASK_SUBTYPE_SINGLETASKING;
                    newTask.Network__c = existingCase.Network__c;
                }
    
                newTask.Priority = existingCase.Priority;
                newTask.Status = StarTrack_Constants.TASK_STATUS_WAITING;
                newTask.OwnerId = UserInfo.getUserId();
                
                createTaskAllowed = true;
            }
        } else{
            newTask.State__c = null;
            newTask.Is_Bulk_Task__c = FALSE;
            newTask.Depot_Filter__c = null;
            newTask.Status = StarTrack_Constants.TASK_STATUS_NOTSTARTED;
            newTask.ActivityDate = null;
            newTask.ReminderDateTime = null;
            newTask.IsReminderSet = false;
            newTask.network__c = null;
            newTask.Depot_Role__c = null;
            newTask.Run_Dock__c = null;
            newTask.Bulk__c = null;
            newTask.OwnerId = UserInfo.getUserId();
            createTaskAllowed = true;
        }
    }
    public PageReference createTask(){
        if(changeDepotArea()){
            try{
                validation = true;
    
                // Subject validation
                PostcodeMapping__c pcm = queryPostCodeMapping(existingCase.ArticleTest__r.ReceiverPostcode__c, existingCase.ArticleTest__r.Receiver_Suburb__c);
                newTask.Run_Dock__c =  pcm != null ? pcm.Run_Dock__c : null;
                newTask.Bulk__c = pcm != null ? pcm.Bulk__c : null;
                if(String.isBlank(newTask.Subject)){
                    newTask.Subject.addError(StarTrack_Constants.VALIDATION_REQUIRE_FIELD_VALUE);
                    validation = false;
                } else if(newTask.Is_Bulk_Task__c){
                    // Depot Filter validation
                    if(String.isBlank(newTask.Depot_Filter__c)){
                        newTask.Depot_Filter__c.addError(StarTrack_Constants.VALIDATION_REQUIRE_FIELD_VALUE);
                        validation = false;
                    }
                    // State validation
                    else if(newTask.Depot_Filter__c == StarTrack_Constants.TASK_DEPOT_FILTER_ALL_STATE && String.isBlank(newTask.State__c)){
                        newTask.State__c.addError(StarTrack_Constants.VALIDATION_REQUIRE_FIELD_VALUE);
                        validation = false;
                    }
                    else{
                        list<task> lst_task = new list<task>();
                        list<workflow_Email__c> lst_workflowEmail  = new list<workflow_Email__c>();
                        for(Network__c n : (List<Network__c>)queryNetwork(newTask.Depot_Filter__c,newTask.state__c)){
                            for(Depot_Area__c d : n.Depot_Roles__r){
                                if(n.System__c){
                                    Task t = new Task();
                                    t.CaseObject__c =  existingCase.Id;
                                    t.OwnerId = UserInfo.getUserId();
                                    t.network__c = n.id;
                                    t.State__c = newTask.state__c;
                                    t.Depot_Role__c = d.id;
                                    t.Depot_Filter__c = newTask.Depot_Filter__c;
                                    t.Priority = existingCase.Priority;
                                    t.Type = StarTrack_Constants.TASK_TYPE_OPERATION;
                                    t.Status = StarTrack_Constants.TASK_STATUS_WAITING;
                                    t.Sub_Type__c = newTask.Sub_Type__c;
                                    t.Description = newTask.Description;
                                    t.recordtypeid = starTrackTaskRecTypeId;
                                    t.WhatId = existingCase.Id;
                                    t.Subject = newTask.Subject;
                                    t.is_bulk_task__c = TRUE;
                                    t.Bulk__c = newTask.Bulk__c;
                                    t.Run_Dock__c = newTask.Run_Dock__c;
                                    lst_task.add(t);
                                }
                                else if(n.ST_Email__c){
                                    workflow_Email__c wfe = new workflow_Email__c();
                                    wfe.Case__c = existingCase.id;
                                    wfe.Status__c = StarTrack_Constants.WFE_STATUS_OPEN;
                                    wfe.Task_Description__c = newTask.Description;
                                    wfe.To_Address__c = n.Email__c;
                                    wfe.Workflow_Email_Alert__c = StarTrack_Constants.OPS_NEWTASK_VIA_EMAIL;
                                    wfe.Task_Subject__c = newTask.Subject;
                                    wfe.Email_Type__c = StarTrack_Constants.TASK_SUBTYPE_MASSTASKING;
                                    wfe.Email_Sub_Type__c = newTask.Depot_Filter__c;
                                    wfe.Network_Name__c = n.name;
                                    lst_workflowEmail.add(wfe);
                                }
                            }
                        }
    
                        if(lst_task.size() > 0){
                            insert lst_task;
                            updateCaseStatus();
                        }
    
                        if(lst_workflowEmail.size() > 0){
                            insert lst_workflowEmail;
                            if(lst_task.size() == 0){
                                updateCaseStatus();
                            }
                        }
                    }
                } else if(newTask.Type == StarTrack_Constants.TASK_TYPE_REMINDER){
                    INSERT newTask;
                } else if(taskingmethod ==  StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PARENT){
                    INSERT newTask;
                    updateCaseStatus();
                } else if(taskingmethod == StarTrack_Constants.NETWORK_PREFMETHOFTASKING_SYSTEM){
                    INSERT newTask;
                    updateCaseStatus();
                } else if(taskingmethod == StarTrack_Constants.NETWORK_PREFMETHOFTASKING_EMAIL){
                    changeNetworkfield();
                    workflow_Email__c wfe = new workflow_Email__c();
                    wfe.Case__c = existingCase.id;
                    wfe.Status__c = StarTrack_Constants.WFE_STATUS_OPEN;
                    wfe.Task_Description__c = newTask.Description;
                    wfe.Task_Subject__c = newTask.Subject;
                    wfe.Email_Type__c = StarTrack_Constants.TASK_SUBTYPE_SINGLETASKING;
                    wfe.Email_Sub_Type__c = newTask.Depot_Filter__c;
                    wfe.Workflow_Email_Alert__c = StarTrack_Constants.OPS_NEWTASK_VIA_EMAIL;
                    wfe.To_Address__c = networkRec.Email__c;
                    wfe.Network_Name__c = networkRec.Name;
                    
                    insert wfe;
                    updateCaseStatus();
                }
            }
            catch(DmlException e){
                System.debug(e.getMessage());
            }
        }
        
        return null;
    }
    
    public void updateCaseStatus(){
        if(existingCase.Status != StarTrack_Constants.CASE_STATUS_WAITINGOPERATIONS && existingCase.Status != 'Closed' && !StarTrack_Constants.CASE_STAT_AWAITINGAPPROVAL.equals(existingCase.Status)){
            existingCase.Status = StarTrack_Constants.CASE_STATUS_WAITINGOPERATIONS;
            update existingCase;
        }
    }
    
    public Boolean changeDepotArea(){
        if(StarTrack_Constants.TASK_TYPE_OPERATION.equals(newTask.Type)){
            if(String.isBlank(depotAreaId)){
                if(fromVF && !newTask.Is_Bulk_Task__c && (StarTrack_Constants.NETWORK_PREFMETHOFTASKING_SYSTEM.equals(networkRec.Preferred_Method_of_Tasking__c) || StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PARENT.equals(networkRec.Preferred_Method_of_Tasking__c))){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Constants.DEPOTAREA_REQUIRED));
                    return false;
                }
                newTask.Depot_Role__c = null;
            } else{
                newTask.Depot_Role__c = depotAreaId;
            }
        }
        return true;
    }

    public void changeNetworkValue(){
        changeNetworkfield();
    }

    public PageReference changeTaskField(){
        checkTaskType();
        changeNetworkfield();
        return null;
    }

    public PageReference changeNetworkfield(){
        prefMethodIsPhone = false;
        networkRec = null;
        newTask.Depot_Role__c = null;
        try{
            if(String.isNotBlank(newTask.network__c)){
                networkRec =[SELECT Id, Name, Parent_Network__c, Parent_Network__r.Name, Parent_Network__r.Email__c, Preferred_Method_of_Tasking__c, Parent_Network__r.Preferred_Method_of_Tasking__c,
                                    Parent_Network__r.Depot_contact_number__c, Parent_Network__r.Fax_Number__c, Phone_Number__c, Depot_contact_number__c, Fax_Number__c, Email__c
                                    FROM Network__c
                                    WHERE Id =: newTask.network__c];
                            
                clonedCase = existingCase.clone(true, true, false, false);
                clonedCase.Network__c = networkRec.Id;
                clonedCase.Network__r.Preferred_Method_of_Tasking__c = networkRec.Preferred_Method_of_Tasking__c;
                clonedCase.Network__r.Parent_Network__c = networkRec.Parent_Network__c;
    
                if(networkRec.Preferred_Method_of_Tasking__c == StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PARENT){
                    if(fromVF && StarTrack_Error_Messages__c.getValues('StarTrack Parent Depot') != null){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, StarTrack_Error_Messages__c.getValues('StarTrack Parent Depot').Value__c));
                    }
                    newTask.Network__c = networkRec.Parent_Network__c;
                    networkRec.Preferred_Method_of_Tasking__c = networkRec.Parent_Network__r.Preferred_Method_of_Tasking__c;
                    networkRec.Depot_contact_number__c = networkRec.Parent_Network__r.Depot_contact_number__c;
                    networkRec.Fax_Number__c = networkRec.Parent_Network__r.Fax_Number__c;
                    clonedCase.network__c = networkRec.Parent_Network__c;
                    taskingmethod = networkRec.Parent_Network__r.Preferred_Method_of_Tasking__c;
                }
                else{
                    taskingmethod = networkRec.Preferred_Method_of_Tasking__c;
                }
    
                if((networkRec.Preferred_Method_of_Tasking__c == StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PHONE || networkRec.Preferred_Method_of_Tasking__c == StarTrack_Constants.NETWORK_PREFMETHOFTASKING_FAX) ||
                   (networkRec.Preferred_Method_of_Tasking__c == StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PARENT &&
                   (networkRec.Parent_Network__r.Preferred_Method_of_Tasking__c == StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PHONE ||
                    networkRec.Parent_Network__r.Preferred_Method_of_Tasking__c == StarTrack_Constants.NETWORK_PREFMETHOFTASKING_FAX))){
                    prefMethodIsPhone = TRUE;
                }
                
                newTask.Depot_Role__c = (StarTrackTaskingRuleUtility.taskingRule(new list<case>{clonedCase}).ContainsKey(clonedCase.id)?StarTrackTaskingRuleUtility.taskingRule(new list<case>{clonedCase}).get(clonedCase.id).id:null);
                depotAreaId = newTask.Depot_Role__c;
    
            }
        } catch(Exception e){
            System.debug(e.getMessage());
        }
        
        return null;
    }

    private PostcodeMapping__c queryPostCodeMapping(String postcode, String suburb){
        try{
            Return [SELECT Run_Dock__c, Bulk__c
                    FROM PostcodeMapping__c
                    WHERE Network__c =: newTask.Network__c
                    AND Postcode__r.Name =: postcode
                    AND Postcode__r.Suburb__c =: suburb
                    LIMIT 1];
        }
        catch(queryException e){
            System.debug('No Records were returned');
            return null;
        }
    }

    private List<Network__c> queryNetwork(String depotType, string state){
        string query = 'SELECT id,Name,System__c,ST_Email__c,Email__c,(SELECT id FROM Depot_Roles__r WHERE Area__c =\'' + StarTrack_Constants.DEPOTAREA_AREA_BRANCHMANAGEMENT + '\' LIMIT 1) FROM Network__c ';
        if(depotType == 'Metros Only'){
            query += ' WHERE RecordType.DeveloperName =\''+ StarTrack_Constants.RECORDTYPE_DEPOT_METRO + '\'';
        }
        else if(depotType == 'Regions Only'){
            query += ' WHERE RecordType.DeveloperName =\'' + StarTrack_Constants.RECORDTYPE_DEPOT_REGIONAL + '\'';
        }
        else if(depotType ==  'All by State'){
            query += ' WHERE state__c =\''+ state + '\'';
        }
        return Database.query(query);
    }
    
    public List<SelectOption> getDepotAreaRecords() {
        Boolean depotAreaIdValid = false;
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));
        List<Depot_Area__c> depotAreaList = [SELECT Id, Name FROM Depot_Area__c WHERE Depot__c =: newTask.Network__c ORDER BY Name ASC];
        for(Depot_Area__c depotAreaRec : depotAreaList){
            options.add(new SelectOption(depotAreaRec.Id, depotAreaRec.Name));
            if(String.isNotBlank(depotAreaId) && depotAreaId.equals(depotAreaRec.Id)){
                depotAreaIdValid = true;
            }
        }
        
        if(!depotAreaIdValid){
            depotAreaId = '';
        }
        return options;
    }
    
    public void refreshRecord(){
        existingCase = [SELECT Id, Origin, Status, Network__r.Parent_Network__c, Network__r.Email__c, ArticleTest__c, Network__c, Priority, Enquiry_Type__c, Network__r.Preferred_Method_of_Tasking__c, ArticleTest__r.ReceiverName__c, ArticleTest__r.ActualWeight__c,
                        ArticleTest__r.Number_of_Items__c, ArticleTest__r.Unit_Type__c, Network__r.RecordType.DeveloperName, ArticleTest__r.ReceiverPostcode__c, ArticleTest__r.Receiver_Suburb__c, RecordType.Name, StarTrack_Receiver_Name__c, Unit_Type__c,
                        Number_of_Items__c, Address4Postcode__c, Address4Suburb__c FROM Case WHERE Id =: existingCase.Id];
        fromVF = true;
        initialize();
    }
}