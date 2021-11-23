/*-------------------------    
Overview: Controller for TDF Dispatch Board

History:
21.06.18    A.Judd        Added support for unassign driver in saveSearchResult.  Added unassigndriver option to list in searchServiceAppointments.
21.06.18    A.Judd        Added condition to exclude Expired duties in fetchDutyTemplates
01.08.20    A.Judd        Updated saveTemplates to align with new data model
01.08.20    A.Judd        Update saveAndGenerateWork to call common function
19.08.20    A.Judd        Added condition to only get driver SRs for Driver select list when populating serviceResourceMap
19.10.20    A.Judd        TDF Enhance Fix: Change to setting of default expiry date and generate work end date for create adhoc job
5.11.21     A.Zhou        Fix the issues that when search for drivers with jobs, the driver are randomly selected.  
--------------------------
*/
public with sharing class TDF_DispatchBoardController {

    public Datetime startDateTime{get;set;}
    public Datetime endDateTime{get;set;}
    public ServiceAppointment objServiceAppointment{get;set;}
    public Boolean renderList{get;set;}
    public List<serviceAppointmentWrapper> serviceAppointmentWrapperList{get;set;}
    public List<SelectOption> workOrderRecordTypeList{get;set;}
    public List<String> selectedWorkOrderRecordTypesList{get;set;}
    public List<SelectOption> dutyTemplateSelectList{get;set;}
    public List<String> selectedDutyTemplateList{get;set;}
    public List<SelectOption> serviceResourceSelectList{get;set;}
    public List<String> selectedServiceResourceList{get;set;}
    public AssignedResource objAssignedResource{get;set;}
    public Map<Id, WorkOrder> workOrderMap;
    public Boolean renderFilterCriteria{get;set;}
    public List<GroupServiceAppointmentWrapper> driverGroupServiceWrapperList{get;set;}
    public List<SelectOption> searchResultListViewSelectList{get;set;}
    public String selectedView{get;set;}
    public List<GroupServiceAppointmentWrapper> dutyGroupServiceWrapperList{get;set;}
    public List<SelectOption> driverToAssignSelectList{get;set;}
    public String selectedDriverForAssignment{get;set;}
    public String selectedSR{get;set;}
    public String selectedVeh{get;set;}
    public Boolean renderColumnsInAllView{get;set;}
    public String serviceTerritoryIdForCustomLookup{get;set;}
    public List<Schema.Location> locationList{get;set;}
    public string searchString{get;set;}
    public Map<Id, Set<Id>> assignedResourceSAMap;
    public List<ServiceResource> serviceRsourceListForLookup{get;set;}

    public Job_Template__c objJobTemplate{get;set;}
    public List<Task_Template__c> taskTemplateList{get;set;}
    public Integer selectedTaskTemplateIndex{get;set;}
    public Boolean saveAndGenerateReset;

    //Constuctor
    public TDF_DispatchBoardController(){

        //Initialization
        startDateTime = System.now().addHours(-8);
        endDateTime = System.now().addHours(16);
        objServiceAppointment = new ServiceAppointment();
        renderList = false; 
        workOrderRecordTypeList = new List<SelectOption>();
        selectedWorkOrderRecordTypesList = new List<String>();
        dutyTemplateSelectList = new List<SelectOption>();
        selectedDutyTemplateList = new List<String>();
        serviceResourceSelectList = new List<SelectOption>();
        selectedServiceResourceList = new List<String>();       
        objAssignedResource = new AssignedResource();
        renderFilterCriteria = false;
        serviceAppointmentWrapperList = new List<serviceAppointmentWrapper>();
        driverGroupServiceWrapperList = new List<GroupServiceAppointmentWrapper>();
        dutyGroupServiceWrapperList = new List<GroupServiceAppointmentWrapper>();
        driverToAssignSelectList = new List<SelectOption>();        
        selectedDriverForAssignment = '';
        selectedSR = '';
        selectedVeh = '';
        renderColumnsInAllView = false;
        assignedResourceSAMap = new Map<Id, Set<Id>>();
        serviceRsourceListForLookup = new List<ServiceResource>();

        searchResultListViewSelectList = new List<SelectOption>();
        searchResultListViewSelectList.add(new SelectOption('', '--- None ---'));
        searchResultListViewSelectList.add(new SelectOption('completeList', 'All'));
        searchResultListViewSelectList.add(new SelectOption('groupByDriverList', 'Group By Driver'));
        searchResultListViewSelectList.add(new SelectOption('groupByDutyList', 'Group By Duty'));
        selectedView = '';

        objJobTemplate = new Job_Template__c();
        taskTemplateList = new List<Task_Template__c>();
        taskTemplateList.add(new Task_Template__c());
        selectedTaskTemplateIndex = 0;
        saveAndGenerateReset = false;

        //get Service Territory Id from Custom Lookup page
        if(ApexPages.currentPage().getParameters().get('serviceTerritory') != null){
            serviceTerritoryIdForCustomLookup = ApexPages.currentPage().getParameters().get('serviceTerritory');
        }
        
        locationList = new List<Schema.Location>();

        //get Search String from Custom Lookup page
        searchString = System.currentPageReference().getParameters().get('lksrch');

        /*get default Service Territory for current user fom Collboration group in which he is member Start */
        String currentUserId = UserInfo.getUserId();
        List<CollaborationGroupMember> collaborationGroupMemberList = new List<CollaborationGroupMember>();

        //get collaboration group members for current user
        collaborationGroupMemberList = [SELECT CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId =: currentUserId];

        if(collaborationGroupMemberList.size()>0){

            Set<String> collaborationGroupIdSet = new Set<String>();

            //loop trough the Collaboration groups members for Collaboration group Ids
            for(CollaborationGroupMember objCGM : collaborationGroupMemberList){
                collaborationGroupIdSet.add(objCGM.CollaborationGroupId);
            }

            if(collaborationGroupIdSet.size() > 0){

                Set<String> collaborationGroupNameSet = new Set<String>();

                //get Collaboration groups from Id and add the name in a set
                for(CollaborationGroup objCollaborationGroup : [SELECT Name FROM CollaborationGroup WHERE Id In : collaborationGroupIdSet]){
                    collaborationGroupNameSet.add(objCollaborationGroup.Name);
                }

                if(collaborationGroupNameSet.size() > 0){

                    //get Service Territories from Collaboration Names
                    List<ServiceTerritory> serviceTerritoryList = [SELECT Id FROM ServiceTerritory WHERE TerritoryDispatcher__c IN : collaborationGroupNameSet];
                    
                    //get first Service Territory and assign it to Dispatch page Service Territory
                    if(serviceTerritoryList.size()>0){                        
                        objServiceAppointment.ServiceTerritoryId = serviceTerritoryList[0].Id;   
                        fetchDutyTemplates();
                    }
                }
            }
        }
        /*get default Service Territory for current user */
    }

    //performs the keyword search
    public PageReference search() {
        runSearch();
        return null;
    }

    public void runSearch() {       
        locationList = performSearch(searchString);
    } 

    //Run the search and return the Vehicle found
    public List<Schema.Location> performSearch(string searchString) {

        RecordType vehilceRecordType = [SELECT Id FROM RecordType WHERE sObjectType = 'Location' AND DeveloperName = 'Vehicle' LIMIT 1];        
        String queryString = 'SELECT Id, Name, Make__c, Model__c, Status__c, ParkingBay__c, Service_Territory__c FROM Location WHERE (Status__c = '+ '\''+ 'Available' + '\'' + ' OR Status__c = ' + '\'' + '\'' + ' OR Status__c = ' + '\'' + 'In Use' + '\'' + ' OR Status__c = ' + '\'' + 'Fault' + '\'' + ' OR Status__c = ' + '\'' + 'Scheduled Maintainance' + '\'' +') AND ';
        
        if(vehilceRecordType != null){
            queryString += ' RecordTypeId = '+ '\'' + vehilceRecordType.Id + '\'';
        }

        if(searchString != '' && searchString != null){
            queryString += 'AND Name LIKE \'%' + searchString +'%\'';
        }
        
        /*YL TDF 4/9/17 - Commented out as Service Territory constrain not a valid business requirememnt.
        if(searchString != '' && searchString != null && serviceTerritoryIdForCustomLookup != null && serviceTerritoryIdForCustomLookup != ''){
            queryString += ' AND ';
        }

        if(serviceTerritoryIdForCustomLookup != null && serviceTerritoryIdForCustomLookup != ''){
            queryString += 'Service_Territory__c ='+ '\'' + serviceTerritoryIdForCustomLookup + '\'';
        }*/
        
        queryString += ' LIMIT 50';
        System.debug(queryString);
        return database.query(queryString);
    }

    //performs the keyword search
    public PageReference searchServiceResource() {
        runSearchForSR();
        return null;
    }

    public void runSearchForSR() {       
        serviceRsourceListForLookup = performServiceResourceSearch(searchString);
    } 

    //Run the search and return the Service Resources 
    public List<ServiceResource> performServiceResourceSearch(string searchString) {
        
        String queryString;
        List<ServiceResource> srList = new List<ServiceResource>();
        Set<String> srIdSet = new Set<String>();

        //if Search string is having something then Search Service Resources for that String
        if(searchString != '' && searchString != null){
            queryString =  'SELECT Id, Name FROM ServiceResource WHERE Name LIKE \'%' + searchString +'%\'';
            searchString = '';
            return database.query(queryString);
        }

        //Search for all the Service Resources belongs to the passed Service Territory
        else{
            if(serviceTerritoryIdForCustomLookup != null){
                List<ServiceTerritory> serviceTerritoryList = new List<ServiceTerritory>();
                serviceTerritoryList = [SELECT Id, (SELECT Id, ServiceResourceId FROM ServiceResources) FROM ServiceTerritory WHERE Id =: serviceTerritoryIdForCustomLookup LIMIT 1];
                if(serviceTerritoryList.size()>0 && serviceTerritoryList[0].ServiceResources.size()>0){
                    for(ServiceTerritoryMember objSTM : serviceTerritoryList[0].ServiceResources){
                        srIdSet.add(objSTM.ServiceResourceId);
                    }
                }

                if(srIdSet.size() > 0){
                    srList = [SELECT Id, Name FROM ServiceResource WHERE Id IN : srIdSet];
                }
            }
        }
        searchString = '';
        return srList;       
    }

    //Used by the custom lookup visualforce page to send the link to the right dom element
    public string getFormTag() {
        return System.currentPageReference().getParameters().get('frm');
    }

    //Used by the custom lookup visualforce page to send the link to the right dom element for the text box
    public string getTextBox() {
        return System.currentPageReference().getParameters().get('txt');
    }       

    //Method to get duty templates, Service Resource and WorkOrder record types
    public void fetchDutyTemplates(){
        
        renderFilterCriteria = true;
        Set<String> serviceResourceIdSet = new Set<String>();
        dutyTemplateSelectList = new List<SelectOption>();
        workOrderRecordTypeList = new List<SelectOption>();
        serviceResourceSelectList = new List<SelectOption>();
        List<ServiceTerritoryMember> serviceTerritoryMemberList = new List<ServiceTerritoryMember>();
        Map<String, String> serviceResourceMap = new Map<String, String>();     
        
        //Populate Duty Template select list
        dutyTemplateSelectList.add(new SelectOption('', 'UnAssigned'));
        //AJ 21.06.18 Added condition to exclude Expired duties
        for(Route_Template__c objDutyTemplate : [SELECT Id, Name FROM Route_Template__c WHERE Service_Territory__c =: objServiceAppointment.ServiceTerritoryId AND Status__c != 'Expired' ORDER BY Name ASC]){
            dutyTemplateSelectList.add(new SelectOption(objDutyTemplate.Id, objDutyTemplate.Name));
        }           

        //Populate Work Order recordType select list    
        for(RecordType objRecordType : [SELECT Id, Name FROM RecordType WHERE sObjectType='WorkOrder']){
            workOrderRecordTypeList.add(new SelectOption(objRecordType.Id, objRecordType.Name));
        }

        //AJ 19.8.2020 Added condition to only get Active Driver SRs
        for(ServiceTerritoryMember objServiceTerritoryMember : [SELECT Id, ServiceResourceId, ServiceResource.Name 
                                                                FROM ServiceTerritoryMember 
                                                                WHERE ServiceTerritoryId =: objServiceAppointment.ServiceTerritoryId 
                                                                AND ServiceResource.ResourceType = 'T' 
                                                                AND ServiceResource.IsActive = true 
                                                                ORDER BY ServiceResource.Name ASC]){
            serviceResourceMap.put(objServiceTerritoryMember.ServiceResourceId, objServiceTerritoryMember.ServiceResource.Name);
        }           

        //Populate Service Resource select list  
        serviceResourceSelectList.add(new SelectOption('', 'UnAssigned'));   
        for(String serviceResourceId : serviceResourceMap.keySet()){
            serviceResourceSelectList.add(new SelectOption(serviceResourceId, serviceResourceMap.get(serviceResourceId)));
        }
        resetPage();
    }

    //Method for Searching only PDC-PrimeMover and PDC-Rigid work order record type Service Appoitments and dafult the list view to All
    public void assignvehicle(){
        Map<String, RecordType> workOrderRecordTypeMap = new Map<String, RecordType>();

        //get all record types of Work Order
        for(RecordType objRecordType : [SELECT Id, DeveloperName FROM RecordType WHERE sObjectType = 'WorkOrder']){
            workOrderRecordTypeMap.put(objRecordType.DeveloperName, objRecordType);
        }

        Set<String> rtStringSet = new Set<String>();
        
        //add the selected Record Type in the Set to check for Record Type
        rtStringSet.addAll(selectedWorkOrderRecordTypesList);

        //clear the list of selected WorkOrder record types before adding elements with Some conition
        selectedWorkOrderRecordTypesList.clear();

        //If PDC_Trailer is selected then add that to the selected list of WorkOrder RecordTypes
        if(rtStringSet.contains(workOrderRecordTypeMap.get('PDC_Trailer').Id)){            
            selectedWorkOrderRecordTypesList.add(workOrderRecordTypeMap.get('PDC_Trailer').Id);
        }

        //Also add PDC_Rigid and PDC_Primemover into Selected WO record type list
        for(RecordType objRecordType : workOrderRecordTypeMap.values()){
            if(objRecordType.DeveloperName == 'PDC_PrimeMover' || objRecordType.DeveloperName == 'PDC_Rigid'){
                selectedWorkOrderRecordTypesList.add(objRecordType.Id);
            }
        }

        //Call the Search method
        searchServiceAppointments();

        //Select the default view for Assign Vehicle that is All
        selectedView = 'completeList';        
        renderColumnsInAllView = true;
    }

    //Method to search Service Appointments based on Filter Criteria
    public PageReference searchServiceAppointments(){
        
        //renderList = true;
        renderColumnsInAllView = false;
        workOrderMap = new Map<Id, WorkOrder>();        

        serviceAppointmentWrapperList = new List<serviceAppointmentWrapper>();
        driverGroupServiceWrapperList = new List<GroupServiceAppointmentWrapper>();
        dutyGroupServiceWrapperList = new List<GroupServiceAppointmentWrapper>();
        driverToAssignSelectList = new List<SelectOption>();
        driverToAssignSelectList.add(new SelectOption('','--- None ---'));
          
        Set<String> workOrderIdSet = new Set<String>();
        List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();
        Set<String> selectedDutyTemplateSet = new Set<String>();
        Set<String> selectedWorkOrderRTSet = new Set<String>();
        Set<String> selectedServiceResourceIdSet = new Set<String>();
        Set<String> serviceResourceIdSet = new Set<String>();
        Map<String, ServiceResource> srMap  = new Map<String, ServiceResource>();

        /* Add all list elements into set for checking the contains Begin*/
        selectedDutyTemplateSet.addAll(selectedDutyTemplateList);
        selectedWorkOrderRTSet.addAll(selectedWorkOrderRecordTypesList);
        selectedServiceResourceIdSet.addAll(selectedServiceResourceList);
        driverToAssignSelectList.addAll(serviceResourceSelectList);
        /* Add all list elements into set for checking the contains End */

        //Remove the Selected driver for Assignment
        if(driverToAssignSelectList.size()>1){
            driverToAssignSelectList.remove(1);
        }
        
        //AJ 21.06.18 Add unassign driver option
        driverToAssignSelectList.add(new SelectOption('unassigndriver','--- UnAssign ---')); 

        //get Service Appointments for start and end date mentioned on Dispatch Board page
        serviceAppointmentList = [SELECT Id, AppointmentNumber, ServiceTerritoryId, Duty_Board__c, Duty_Board__r.Name, SchedStartTime, SchedEndTime, Duration, DurationType, FSL__Related_Service__c, ParentRecordId, ParentRecord.Name, ParentRecord.RecordTypeId, Service_Resource__c, (SELECT Id, ServiceResourceId, ServiceResource.Name, ServiceResource.Vehicle__c, ServiceResource.Vehicle__r.Status__c, ServiceResource.Vehicle__r.ParkingBay__c FROM ServiceResources order by CreatedDate ) FROM ServiceAppointment WHERE SchedStartTime >=: startDateTime AND SchedEndTime <=: endDateTime AND ServiceTerritoryId =: objServiceAppointment.ServiceTerritoryId ORDER BY SchedStartTime ASC]; 
        System.debug('serviceAppointmentList->'+serviceAppointmentList.size());

        //get only Service Appointments whose Parent Type is WorkOrder
        for(ServiceAppointment objSA : serviceAppointmentList){
            if(objSA.ParentRecordId.getSObjectType().getDescribe().getName() == 'WorkOrder'){
                workOrderIdSet.add(objSA.ParentRecordId);
            }

            Set<Id> arIdSet = new Set<Id>();

            //loop through the child Assigned Resources of Service Appointments
            if(objSA.ServiceResources.size()>0){
                for(AssignedResource objAR : objSA.ServiceResources){
                    arIdSet.add(objAR.ServiceResourceId);
                }
                //Populate Map that will be having Id of Service Appointment as Key and Set of Id of Assigned Resource's Service Resource as Value
                assignedResourceSAMap.put(objSA.Id, arIdSet);
            }
        }

        //loop throught the Service Appointments and get the first Assigned Resource's Service Resource Id and add in the Set of Ids
        for(ServiceAppointment objSA : serviceAppointmentList){
            if(objSA.ServiceResources.size()>0){
                serviceResourceIdSet.add(objSA.ServiceResources[0].ServiceResourceId);
            }
        }

        //create Service Resource Map
        for(ServiceResource objSerRes : [SELECT Id, Name, Vehicle__c FROM ServiceResource WHERE Id IN : serviceResourceIdSet]){
            srMap.put(objSerRes.Id, objSerRes);
        }

        //create WorkOrder Map
        for(WorkOrder objWorkOrder : [SELECT Id, Vehicle__c, Vehicle__r.Name, Vehicle__r.Status__c, Vehicle__r.ParkingBay__c, Location.Registration_Number__c, Subject, LocationId, Location.Name, Status FROM WorkOrder WHERE Id IN : workOrderIdSet]){
            workOrderMap.put(objWorkOrder.Id, objWorkOrder);            
        }

        //loop through the Service Appointments for further checking other filter criterias and Add the filtered records in Wrapper List
        for(ServiceAppointment objSA : serviceAppointmentList){

            //Check for ParentId is of type WorkOrder
            if(objSA.ParentRecordId != null && String.valueOf(objSA.ParentRecordId).startsWith('0WO')){

                //Check for Duty Tempalte
                if(selectedDutyTemplateSet.size() == 0 || selectedDutyTemplateSet.contains(objSA.Duty_Board__c)){

                    //Check for Record Type
                    if(selectedWorkOrderRTSet.size() == 0 || selectedWorkOrderRTSet.contains(objSA.ParentRecord.RecordTypeId)){

                        //Check for driver
                        if(selectedServiceResourceIdSet.size() == 0 || (objSA.ServiceResources.size()>0 && selectedServiceResourceIdSet.contains(objSA.ServiceResources[0].ServiceResourceId))){

                            if(objSA.ServiceResources.size()>0){

                                if(workOrderMap.get(objSA.ParentRecordId) != null){

                                    serviceAppointmentWrapperList.add(new serviceAppointmentWrapper(objSA, objSA.ServiceResources[0], srMap.get(objSA.ServiceResources[0].ServiceResourceId), workOrderMap.get(objSA.ParentRecordId)));
                                
                                }else{

                                    serviceAppointmentWrapperList.add(new serviceAppointmentWrapper(objSA, objSA.ServiceResources[0], srMap.get(objSA.ServiceResources[0].ServiceResourceId)));

                                }                               
                            
                            }else if(objSA.ServiceResources.size() == 0){

                                if(workOrderMap.get(objSA.ParentRecordId) != null){
                                
                                    serviceAppointmentWrapperList.add(new serviceAppointmentWrapper(objSA, workOrderMap.get(objSA.ParentRecordId)));
                                
                                }else{

                                    serviceAppointmentWrapperList.add(new serviceAppointmentWrapper(objSA));

                                }                       
                            }
                        }else{

                            if(objSA.ServiceResources.size() == 0 && selectedServiceResourceIdSet.contains('')){

                                if(workOrderMap.get(objSA.ParentRecordId) != null){
                                
                                    serviceAppointmentWrapperList.add(new serviceAppointmentWrapper(objSA, workOrderMap.get(objSA.ParentRecordId)));
                                
                                }else{

                                    serviceAppointmentWrapperList.add(new serviceAppointmentWrapper(objSA));

                                }                       
                            }
                        }
                    }
                }else{

                    if(objSA.Duty_Board__c == null && selectedDutyTemplateSet.contains('')){

                        //Check for Record Type
                        if(selectedWorkOrderRTSet.size() == 0 || selectedWorkOrderRTSet.contains(objSA.ParentRecord.RecordTypeId)){

                            //Check for driver
                            if(selectedServiceResourceIdSet.size() == 0 || (objSA.ServiceResources.size()>0 && selectedServiceResourceIdSet.contains(objSA.ServiceResources[0].ServiceResourceId))){

                                if(objSA.ServiceResources.size()>0){

                                    if(workOrderMap.get(objSA.ParentRecordId) != null){

                                        serviceAppointmentWrapperList.add(new serviceAppointmentWrapper(objSA, objSA.ServiceResources[0], srMap.get(objSA.ServiceResources[0].ServiceResourceId), workOrderMap.get(objSA.ParentRecordId)));
                                    
                                    }else{

                                        serviceAppointmentWrapperList.add(new serviceAppointmentWrapper(objSA, objSA.ServiceResources[0], srMap.get(objSA.ServiceResources[0].ServiceResourceId)));

                                    }                               
                                
                                }else if(objSA.ServiceResources.size() == 0){

                                    if(workOrderMap.get(objSA.ParentRecordId) != null){
                                    
                                        serviceAppointmentWrapperList.add(new serviceAppointmentWrapper(objSA, workOrderMap.get(objSA.ParentRecordId)));
                                    
                                    }else{

                                        serviceAppointmentWrapperList.add(new serviceAppointmentWrapper(objSA));

                                    }                       
                                }
                            }else{

                                if(objSA.ServiceResources.size() == 0 && selectedServiceResourceIdSet.contains('')){

                                    if(workOrderMap.get(objSA.ParentRecordId) != null){
                                    
                                        serviceAppointmentWrapperList.add(new serviceAppointmentWrapper(objSA, workOrderMap.get(objSA.ParentRecordId)));
                                    
                                    }else{

                                        serviceAppointmentWrapperList.add(new serviceAppointmentWrapper(objSA));

                                    }                       
                                }
                            }
                        }                      
                    }
                }
            }
        }

        System.debug('serviceAppointmentWrapperList ->'+serviceAppointmentWrapperList.size());
        
        TDF_NotificationScheduler__c objNotificationSch;

        //get the custom setting value for getting the specified limit of Service Appointments that can be shown on Dispatch page
        if(TDF_NotificationScheduler__c.getAll().get('DispatchBoardSACountCheck') != null){
            objNotificationSch = TDF_NotificationScheduler__c.getAll().get('DispatchBoardSACountCheck');
        }
        System.debug('objNotificationSch ->'+objNotificationSch);

        //compare the filtered records and limit specified in Custom Setting
        //If condition is satisfied then throw the error(Error is also specified in Custom Setting)    
        if(objNotificationSch != null && serviceAppointmentWrapperList.size() > objNotificationSch.Service_Appointment_Query_Limit__c){
            System.debug('objNotificationSch.Service_Appointment_Query_Limit__c ->'+objNotificationSch.Service_Appointment_Query_Limit__c);
            String serviceAppointmentLimitErrMsg = objNotificationSch.Error_Message__c.replace('<?>', String.valueOf(Integer.valueOf(objNotificationSch.Service_Appointment_Query_Limit__c)));
            serviceAppointmentLimitErrMsg = serviceAppointmentLimitErrMsg.replace('<SA>', String.valueOf(Integer.valueOf(serviceAppointmentWrapperList.size())));
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, serviceAppointmentLimitErrMsg));
            renderList = false;
            serviceAppointmentWrapperList = new List<ServiceAppointmentWrapper>();
            workOrderMap = new Map<Id, WorkOrder>();
            assignedResourceSAMap = new Map<Id, Set<Id>>();
            System.debug('serviceAppointmentWrapperList ->'+serviceAppointmentWrapperList.size());
            return null;
        }

        //else dont through the error and render the list of filtered records
        else{
            renderList = true;
        }

        /*To make Service Appointment wrapper list Grouped by Driver Begin*/
        Map<String, AssignedResource> serviceResourceMap = new Map<String, AssignedResource>();
        List<serviceAppointmentWrapper> serviceAppointmentUnAssignedList = new List<serviceAppointmentWrapper>();

        Set<Id> serviceResourceIdSetTemp = new Set<Id>();
        List<ServiceResource> serviceResourceList = new List<ServiceResource>();

        for(serviceAppointmentWrapper objSAWrap : serviceAppointmentWrapperList){
            if(objSAWrap.objAssignedResource.ServiceResourceId != null){
                serviceResourceMap.put(objSAWrap.objAssignedResource.ServiceResourceId, objSAWrap.objAssignedResource);

                if(!serviceResourceIdSetTemp.contains(objSAWrap.objAssignedResource.ServiceResourceId)){
                    serviceResourceList.add(objSAWrap.objAssignedResource.ServiceResource);
                    serviceResourceIdSetTemp.add(objSAWrap.objAssignedResource.ServiceResourceId);
                }

            }else{
                serviceAppointmentUnAssignedList.add(objSAWrap);                
            }
        }

        serviceResourceList.sort();

        System.debug('serviceAppointmentUnAssignedList->'+serviceAppointmentUnAssignedList+' Size->'+serviceAppointmentUnAssignedList.size());
        List<serviceAppointmentWrapper> saWrapList;

        if(serviceAppointmentUnAssignedList.size()>0 && (selectedServiceResourceIdSet.contains('') || selectedServiceResourceIdSet.size()==0)){
            driverGroupServiceWrapperList.add(new GroupServiceAppointmentWrapper('Unassigned Drivers', serviceAppointmentUnAssignedList));
        }

        for(ServiceResource objSR : serviceResourceList){
            saWrapList = new List<serviceAppointmentWrapper>();
            for(serviceAppointmentWrapper objSAWrap : serviceAppointmentWrapperList){
                if(objSAWrap.objAssignedResource.ServiceResourceId == objSR.Id){
                    saWrapList.add(objSAWrap);
                }
            }
            driverGroupServiceWrapperList.add(new GroupServiceAppointmentWrapper(objSR, saWrapList));            
        }

        System.debug('driverGroupServiceWrapperList ->'+driverGroupServiceWrapperList.size());
        /*To make Service Appointment wrapper list Grouped by Driver End*/


        /*To make Service Appointment wrapper list Grouped by Duty Begin*/      
        Set<String> dutyBoardIdSet = new Set<String>(); 
        Map<String, Route_Template__c> dutyBoardMap = new Map<String, Route_Template__c>(); 
        serviceAppointmentUnAssignedList = new List<serviceAppointmentWrapper>();
        for(serviceAppointmentWrapper objSAWrap : serviceAppointmentWrapperList){
            if(objSAWrap.objSA.Duty_Board__c != null){
                dutyBoardIdSet.add(objSAWrap.objSA.Duty_Board__c);
            }else{
                serviceAppointmentUnAssignedList.add(objSAWrap);
            }
        }
        System.debug('serviceAppointmentUnAssignedList->'+serviceAppointmentUnAssignedList+' Size->'+serviceAppointmentUnAssignedList.size());
        for(Route_Template__c objDutyBoard : [SELECT Id, Name FROM Route_Template__c WHERE Id IN : dutyBoardIdSet ORDER BY Name ASC]){
            dutyBoardMap.put(objDutyBoard.Id, objDutyBoard);
        }

        if(serviceAppointmentUnAssignedList.size()>0){
            dutyGroupServiceWrapperList.add(new GroupServiceAppointmentWrapper('Unassigned Duties', serviceAppointmentUnAssignedList));
        }
        
        for(String dutyBoardId : dutyBoardMap.keySet()){
            saWrapList = new List<serviceAppointmentWrapper>();
            for(serviceAppointmentWrapper objSAWrap : serviceAppointmentWrapperList){
                if(objSAWrap.objSA.Duty_Board__c == dutyBoardId){
                    saWrapList.add(objSAWrap);
                }
            }
            dutyGroupServiceWrapperList.add(new GroupServiceAppointmentWrapper(dutyBoardMap.get(dutyBoardId), saWrapList));
        }

        System.debug('dutyGroupServiceWrapperList ->'+dutyGroupServiceWrapperList.size());          
        /*To make Service Appointment wrapper list Grouped by Duty End*/

        //selectedView = '';

        return null;
    }

    //method to reset the page without resetting the filtered criterias that are already selected
    public void resetPage(){
        renderColumnsInAllView = false;
        renderList = false;     
        renderFilterCriteria = true;
        selectedWorkOrderRecordTypesList = new List<String>();
        selectedDutyTemplateList = new List<String>();
        selectedServiceResourceList = new List<String>();       
        objAssignedResource = new AssignedResource();
        selectedView = '';          
    }

    //Method for saving changed records and Assign selected driver on selected records  
    public PageReference saveSearchResult(){

        List<ServiceAppointment> serviceAppointmentToUpdateList = new List<ServiceAppointment>();
        List<AssignedResource> assignResourceToUpdateList = new List<AssignedResource>();
        List<WorkOrder> workOrderToUpdateList = new List<WorkOrder>();
        List<ServiceResource> serviceResourceToUpdateList = new List<ServiceResource>();
        Set<Id> serviceResourceIdSetForDuplicateCheck = new Set<Id>();
        List<AssignedResource> assignResourceToInsertList = new List<AssignedResource>(); 
        //AJudd 21.06.18 New list for deleting assRes for unassign driver
        List<AssignedResource> assignResourceToDeleteList = new List<AssignedResource>(); 
              
        Boolean recordSelected  = false;

        if(ServiceAppointmentWrapperList.size()>0){

            //loop through the list of Service Appointments Wrapper list records
            for(serviceAppointmentWrapper objServiceAppointmentWrap : ServiceAppointmentWrapperList){

                //check for Select checkbox
                if(objServiceAppointmentWrap.isSelected){

                    //AJ 05.09.18 Check Status not Completed - i.e. dont reassign Completed jobs
                    if(objServiceAppointmentWrap.objWorkOrder.Status != 'Completed'){
                     
                        //this boolean is used to check atleast one record should be selected before Saving
                        recordSelected = true;
    
                        System.debug('objServiceAppointmentWrap 1->'+objServiceAppointmentWrap);
    
                        //Add the Duration and Start Time and Assign it to End Time of Service Appointment based on Duration type(Specified in hours and minute)
                        if(objServiceAppointmentWrap.objSA.DurationType != null && objServiceAppointmentWrap.objSA.Duration != null && objServiceAppointmentWrap.objSA.SchedStartTime != null){                    
                            if(objServiceAppointmentWrap.objSA.DurationType == 'Minutes'){
                                objServiceAppointmentWrap.objSA.SchedEndTime = objServiceAppointmentWrap.objSA.SchedStartTime.addMinutes(Integer.valueOf(objServiceAppointmentWrap.objSA.Duration));
                            }else if(objServiceAppointmentWrap.objSA.DurationType == 'Hours'){
                                objServiceAppointmentWrap.objSA.SchedEndTime = objServiceAppointmentWrap.objSA.SchedStartTime.addHours(Integer.valueOf(objServiceAppointmentWrap.objSA.Duration));
                            }                    
                        }
                        serviceAppointmentToUpdateList.add(objServiceAppointmentWrap.objSA);
                        
                        //AJ 21.06.18 If option selected is unassign driver then delete assignment                 
                        if(selectedDriverForAssignment == 'unassigndriver'){
                            if(objServiceAppointmentWrap.objAssignedResource.Id != null){
                                //Add Assigned Resource to delete list
                                assignResourceToDeleteList.add(objServiceAppointmentWrap.objAssignedResource);
                            }
                        }
                        //Not unassigndriver
                        else{
                        
                            //if Driver is selected for Assignment then update the Assigned Resource's ServiceResourceId to the selected driver id
                            if(selectedDriverForAssignment != null){
                                objServiceAppointmentWrap.objAssignedResource.ServiceResourceId = selectedDriverForAssignment;
                            }
        
                            //Check for Assigned Resource Id 
                            //if its null then insert the Assigned Resource for Service Appointment
                            if(objServiceAppointmentWrap.objAssignedResource.Id == null){
        
                                if(objServiceAppointmentWrap.objSA.Id != null){
        
                                    if(objServiceAppointmentWrap.objSA.Service_Resource__c != null){
        
                                        objServiceAppointmentWrap.objAssignedResource.ServiceAppointmentId = objServiceAppointmentWrap.objSA.Id;
        
                                        objServiceAppointmentWrap.objAssignedResource.ServiceResourceId = objServiceAppointmentWrap.objSA.Service_Resource__c;
        
                                        assignResourceToInsertList.add(objServiceAppointmentWrap.objAssignedResource);                               
                                    }
        
                                    else if(selectedDriverForAssignment != null){
        
                                        objServiceAppointmentWrap.objAssignedResource.ServiceAppointmentId = objServiceAppointmentWrap.objSA.Id;
        
                                        objServiceAppointmentWrap.objAssignedResource.ServiceResourceId = selectedDriverForAssignment;
                                        
                                        assignResourceToInsertList.add(objServiceAppointmentWrap.objAssignedResource);                                
                                    }
                                }
                            }
        
                            //update the Existing Assigned Resource with other Service Resource Id
                            else{
        
                                if(objServiceAppointmentWrap.objSA.Service_Resource__c != null && selectedDriverForAssignment == null){
        
                                    objServiceAppointmentWrap.objAssignedResource.ServiceResourceId = objServiceAppointmentWrap.objSA.Service_Resource__c;
        
                                    assignResourceToUpdateList.add(objServiceAppointmentWrap.objAssignedResource);                               
                                }
        
                                else if(!assignedResourceSAMap.get(objServiceAppointmentWrap.objSA.Id).contains(selectedDriverForAssignment)){
                                    assignResourceToUpdateList.add(objServiceAppointmentWrap.objAssignedResource);                        
                                }
                            }
                        } //End else not unassign driver                   
    
                        //update the Duty Board on WorkOrder same as Service Appointment
                        if(objServiceAppointmentWrap.objSA.Duty_Board__c != null){
                            objServiceAppointmentWrap.objWorkOrder.Duty_Board__c = objServiceAppointmentWrap.objSA.Duty_Board__c;
                        }
                        workOrderToUpdateList.add(objServiceAppointmentWrap.objWorkOrder);
                        
                        //Check for Duplicates for Service Resource to update list                
                        if(objServiceAppointmentWrap.objAssignedResource.ServiceResource.Id != null && !serviceResourceIdSetForDuplicateCheck.contains(objServiceAppointmentWrap.objAssignedResource.ServiceResource.Id)){                    
                            System.debug('In if condition'+objServiceAppointmentWrap.objAssignedResource.ServiceResource);
                            serviceResourceToUpdateList.add(objServiceAppointmentWrap.objAssignedResource.ServiceResource);
                            serviceResourceIdSetForDuplicateCheck.add(objServiceAppointmentWrap.objAssignedResource.ServiceResource.Id);
                        }
                    }
                }
            }                   
        }

        //If no receord is selected then through the error message on page for atleast selectin one record before saving
        if(!recordSelected){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select a record (not in Completed Status) before saving'));
            return null;
        }

        //Decalre savepoint 
        Savepoint sp;

        try{           
            //Set save point 
            sp = Database.setSavepoint();

            //perform DML operations
            
            //AJ 21.06.18 Delete assigned resource for unassigned drivers
            if(assignResourceToDeleteList.size() > 0){
                delete assignResourceToDeleteList;
            }
            System.debug('assignResourceToDeleteList->'+assignResourceToDeleteList+' Size->'+assignResourceToDeleteList.size());
            
            if(serviceAppointmentToUpdateList.size() > 0){
                for(ServiceAppointment objSA : serviceAppointmentToUpdateList){
                    objSA.Service_Resource__c = null;
                }                
                update serviceAppointmentToUpdateList;              
            }
            System.debug('serviceAppointmentToUpdateList ->'+serviceAppointmentToUpdateList+' Size ->'+serviceAppointmentToUpdateList.size());
 
            if(serviceResourceToUpdateList.size() > 0){
                update serviceResourceToUpdateList;
            }       
            System.debug('serviceResourceToUpdateList ->'+serviceResourceToUpdateList+' Size ->'+serviceResourceToUpdateList.size()); 

            if(assignResourceToUpdateList.size() > 0){
                update assignResourceToUpdateList;
            }
            System.debug('assignResourceToUpdateList ->'+assignResourceToUpdateList+' Size ->'+assignResourceToUpdateList.size());

            if(workOrderToUpdateList.size() > 0){
                update workOrderToUpdateList;
            }
            System.debug('workOrderToUpdateList ->'+workOrderToUpdateList+' Size ->'+workOrderToUpdateList.size());

            System.debug('assignResourceToInsertList 1->'+assignResourceToInsertList+' Size 1->'+assignResourceToInsertList.size());
            if(assignResourceToInsertList.size() > 0){
                insert assignResourceToInsertList;
            }
            System.debug('assignResourceToInsertList 2->'+assignResourceToInsertList+' Size 2->'+assignResourceToInsertList.size());
            
        }catch(Exception e){
            System.debug('Error Message ->'+e.getMessage());
            System.debug('Error Line Number ->'+e.getLineNumber());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getMessage()));
            Database.rollback( sp );
            return null;            
        }
        
        //After successful DML operations reset the selected driver and run the Search again for showing the updated data on page        
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Data Updated Successfully.!!'));
        selectedDriverForAssignment = null;
        searchServiceAppointments();
        PageReference pg = new PageReference('/apex/TDF_DispatchBoard');            
        return pg;
    }

    //Method for refreshing Territories
    // Added 06/02/18
    public PageReference refreshTerritories(){
        try{

            System.debug('*** Start refreshTerritories - objServiceAppointment.ServiceTerritoryId : ' + objServiceAppointment.ServiceTerritoryId);

            TDF_RefreshTerritories.RefreshByServiceTerritoryId(objServiceAppointment.ServiceTerritoryId);

        }catch(Exception e){
                System.debug('Error Message ->'+e.getMessage());
                System.debug('Error Line Number ->'+e.getLineNumber());
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getMessage()));
                return null;
            }

             //After successful DML operations reset the selected driver and run the Search again for showing the updated data on page
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Territories Successfully Refreshed.!!'));
             //selectedDriverForAssignment = null;
             //searchServiceAppointments();
             PageReference pg = new PageReference('/apex/TDF_DispatchBoard');
             return pg;
         }



         //method to add a row for Task Template
         public pagereference addTaskTemplate(){
             taskTemplateList.add(new Task_Template__c());
             return null;
         }

         //method to remove the element from Task Template list by using Index
         public Pagereference deleteTaskTemplate(){
             //if index passed is not null
             if(selectedTaskTemplateIndex != null){
                 //remove the element from list by Index
                 taskTemplateList.remove(selectedTaskTemplateIndex);
             }
             return null;
         }

         //Method to save the Job Tempalte and Task Template
         //TDF Enhance: 01.08.20 Changes to task template insert to align with to new connected data model
         public PageReference saveTemplates(){

            Boolean taskToInsert = false;

            //Decalre savepoint
             Savepoint sp;

             if(objJobTemplate.Start_Time__c != null && objJobTemplate.Earliest_Start_Time__c != null && objJobTemplate.Start_Time__c < objJobTemplate.Earliest_Start_Time__c){
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Start Time must be greater or equal to Earliest Start Time'));
                 return null;
             }
             if(objJobTemplate.Start_Time__c != null && (Integer.valueOf(objJobTemplate.Start_Time__c)>2400 || Integer.valueOf(objJobTemplate.Start_Time__c)<0)){
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Start Time must be between 0000 and 2400'));
                 return null;
             }
             if(objJobTemplate.Earliest_Start_Time__c != null && (Integer.valueOf(objJobTemplate.Earliest_Start_Time__c)>2400 || Integer.valueOf(objJobTemplate.Earliest_Start_Time__c)<0)){
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Earliest Start Time must be between 0000 and 2400'));
                 return null;
             }
             if(objJobTemplate.Latest_Start_Time__c != null && (Integer.valueOf(objJobTemplate.Latest_Start_Time__c)>2400 || Integer.valueOf(objJobTemplate.Latest_Start_Time__c)<0)){
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Latest Start Time must be between 0000 and 2400'));
                 return null;
             }
             try{
                 //Set save point
                 sp = Database.setSavepoint();

                 //insert Job Template first to link it with the Task Template
                 if(objJobTemplate.Id == null){
                     insert objJobTemplate;
                 }
                
                 //loop throght the Task Templates and associate with Job Template
                 for(Task_Template__c objTaskTemplate :  taskTemplateList){

                    //If a task is specified
                    if(objTaskTemplate.Task__c != null){

                        taskToInsert = true;

                        //Set the lookup to the Duty Template
                        objTaskTemplate.DTID__c = objJobTemplate.Route_Template__c;
                        //If a collect task
                        if(objTaskTemplate.Task__c == 'Collect Product'){
                            //Set the collect from lookup
                            objTaskTemplate.Collect_From_Job_Template__c = objJobTemplate.Id;
                        }
                        //If a deliver task
                        else if(objTaskTemplate.Task__c == 'Deliver Product'){
                            //Set the deliver to lookup
                            objTaskTemplate.Deliver_To_Job_Template__c = objJobTemplate.Id;
                        }
                        //Set the legacy lookup - though not required
                        objTaskTemplate.Job_Template__c = objJobTemplate.Id;
                    }
                 }

                 //If there are tasks to insert
                 if(taskToInsert){
                     //Insert
                     insert taskTemplateList;
                 }

                 if(!saveAndGenerateReset){
                     ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Job Template and Task Templates created successfully!'));
                 }

             }catch(Exception e){
                 System.debug('Error Message ->'+e.getMessage());
                 System.debug('Error Line Number ->'+e.getLineNumber());
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getMessage()));
                 Database.rollback(sp);
                 return null;
             }
             System.debug('objJobTemplate Id->'+objJobTemplate.Id);
             resetTemplates();
             return null;
         }

         //method to save templates and generate work for those templates
         //TDF Enhance: 01.08.20 Changed to call common generate work function
         public Pagereference saveAndGenerateWork(){

            //make boolean false to not reset the templates
            saveAndGenerateReset = true;
            saveTemplates();

            //Declare the SavePoint
            Savepoint sp;

            try{

                //Create database save point so if any exception occurs will rollback to this save point
                sp = Database.setSavepoint();

                Date startDateGen = System.today();
                //TDF Enhance Fix 19.10.20 Change generate work end date from to today to today + 6 days
                Date endDateGen = System.today().addDays(6);
                String resultString;
     
                //TDF Enhance: 01.08.20 Call method to generate jobs
                if(objJobTemplate.Id != null){
                    TDF_GenerateWork generateWork = new TDF_GenerateWork();
                    resultString = generateWork.createJobs(startDateGen, endDateGen, objJobTemplate.Route_Template__c, objJobTemplate.Id); 
                }

                saveAndGenerateReset = false;
                resetTemplates();

                //Display success message
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM, resultString)); 

                return null;
            }
            catch(Exception e){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getMessage()));            
                System.debug('Exception Occured : '+e.getMessage());
                System.debug('Exception Occured : '+e.getStackTraceString());
                // Rollback to save point
                Database.rollback( sp );
                return null;
            }
    }

    //method to reset the templates
    public void resetTemplates(){
        if(!saveAndGenerateReset){        
            objJobTemplate = new Job_Template__c();
            taskTemplateList = new List<Task_Template__c>();
            //add a blank Task Template
            addTaskTemplate();
        }        
    }

    //Wrapper class to show search result
    public class serviceAppointmentWrapper{

        public Boolean isSelected{get;set;}
        public ServiceAppointment objSA{get;set;}
        public AssignedResource objAssignedResource{get;set;}       
        public WorkOrder objWorkOrder{get;set;} 
        public ServiceResource objServiceResource{get;set;}
        
        //Different constructors for different list of Argument passed
        public serviceAppointmentWrapper(ServiceAppointment objServiceAppoint, AssignedResource objAR, ServiceResource objSR, WorkOrder objWO){
            objServiceResource = new ServiceResource();
            isSelected = false;
            objSA = objServiceAppoint;
            objAssignedResource = objAR;
            objWorkOrder = objWO;
            objServiceResource = objSR;
            if(objAR.ServiceResourceId != null){
                objSA.Service_Resource__c = objAR.ServiceResourceId;
            }                
        }

        public serviceAppointmentWrapper(ServiceAppointment objServiceAppoint, AssignedResource objAR, ServiceResource objSR){
            objServiceResource = new ServiceResource();
            isSelected = false;
            objSA = objServiceAppoint;
            objAssignedResource = objAR;
            objWorkOrder = new WorkOrder();         
            objServiceResource = objSR;
            if(objAR.ServiceResourceId != null){
                objSA.Service_Resource__c = objAR.ServiceResourceId;
            }                       
        }       

        public serviceAppointmentWrapper(ServiceAppointment objServiceAppoint, WorkOrder objWO){
            isSelected = false;
            objSA = objServiceAppoint;
            objAssignedResource = new AssignedResource();
            objWorkOrder = objWO;
            objServiceResource = new ServiceResource();         
        }               

        public serviceAppointmentWrapper(ServiceAppointment objServiceAppoint){
            isSelected = false;
            objSA = objServiceAppoint;
            objAssignedResource = new AssignedResource();
            objWorkOrder = new WorkOrder(); 
            objServiceResource = new ServiceResource();     
        }
    }

    //Wrapper class for showing records in groups
    public class GroupServiceAppointmentWrapper{
        
        public String dutyTemplatesName{get;set;}
        public Route_Template__c objDutyBoard{get;set;}     
        public List<serviceAppointmentWrapper> serviceAppointmentWrapperList{get;set;}
        public ServiceResource objServiceResource{get;set;}
        public String unassignedName{get;set;}

        //Different constructors for different list of Argument passed
        public GroupServiceAppointmentWrapper(ServiceResource objSR, List<serviceAppointmentWrapper> saWrapList){
            objServiceResource = objSR;
            dutyTemplatesName = '';
            objDutyBoard = new Route_Template__c();
            serviceAppointmentWrapperList = saWrapList;
            unassignedName = '';         

            Set<String> dutyTemplateNames = new Set<String>();
            for(serviceAppointmentWrapper objSAWrap : saWrapList){
                if(objSAWrap.objSA.Duty_Board__c != null){
                    dutyTemplateNames.add(objSAWrap.objSA.Duty_Board__r.Name);
                }
            }           
            for(String dutyTempName : dutyTemplateNames){
                dutyTemplatesName += ' | ' + dutyTempName;
            }
        }

        public GroupServiceAppointmentWrapper(Route_Template__c objDB, List<serviceAppointmentWrapper> saWrapList){
            objServiceResource = new ServiceResource();
            dutyTemplatesName = '';
            objDutyBoard = objDB;
            serviceAppointmentWrapperList = saWrapList;
            unassignedName = '';
        }

        public GroupServiceAppointmentWrapper(String uName, List<serviceAppointmentWrapper> saWrapList){
            unassignedName = uName;
            serviceAppointmentWrapperList = saWrapList;
            objServiceResource = new ServiceResource();
            dutyTemplatesName = '';
            objDutyBoard = new Route_Template__c();            
        }       
    }  
}