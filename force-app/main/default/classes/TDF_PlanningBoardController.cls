/* Controller class for the TDF Planning Board screen
 * 
 * 
 * 24.07.2020 ajudd@salesforce.com 	Refactored to call common Generate Work function
 * 25-08-2020  ajudd@salesforce.com Removed commented out code replaced by common TDF_GenerateWork class 
 */ 
public with sharing class TDF_PlanningBoardController {
    
    public Date startDate{get;set;}
    public Date endDate{get;set;}
    public ServiceAppointment objServiceAppointment{get;set;}
    public List<DutyTemplateWrapper> dutyTemplateWrapperList{get;set;}  
    public Date generateWorkStartDate{get;set;}
    public Date generateWorkEndDate{get;set;}
    public Date deleteWorkStartDate{get;set;}
    public Date deleteWorkEndDate{get;set;}    
    public Map<String, Route_Template__c> dutyTemplateMap;
    public Map<String, List<Job_Template__c>> jobTemplateMap;

    public Set<String> jobTemplateIdSet;
    public List<WorkOrder> workOrderList;
    public List<WorkOrderLineItem> workOrderLIList;
    public List<ServiceAppointment> serviceAppointmentList;
    public List<AssignedResource> assignedResourceList;
    public Integer woCount{get;set;}
    public Integer woLICount{get;set;}
    public Integer saCount{get;set;}
    public Boolean displayPopUp{get;set;}
    public Boolean displaySuccessMessage{get;set;}
    public Route_Template__c objDT{get;set;}
    
    //AJ 01.07.18 Added for name search
    public String nameSearchCriteria {get;set;}

    public TDF_PlanningBoardController(){

        //Initialization
        objServiceAppointment = new ServiceAppointment();
        dutyTemplateWrapperList = new List<DutyTemplateWrapper>();
        dutyTemplateMap = new Map<String, Route_Template__c>();
        jobTemplateMap = new Map<String, List<Job_Template__c>>();
        jobTemplateIdSet = new Set<String>();
        displayPopUp = false;
        displaySuccessMessage = false; 
        objDT = new Route_Template__c(); 
               
        //AJ 01.07.18 Default dates to today
        generateWorkStartDate = System.today();
        generateWorkEndDate = System.today();
        deleteWorkStartDate = System.today();
        deleteWorkEndDate = System.today();     
  
    }

    // 16/02/18:  Refresh Territories
    public PageReference refreshTerritories(){

        try{

            if (objServiceAppointment.ServiceTerritoryId == null)
                throw new applicationException('Please Select a Service Territory');
            else
            {
                // Get the selected territory Id:
                System.debug('*** Start TDF_PlanningBoardController.refreshTerritories - objServiceAppointment.ServiceTerritoryId : ' + objServiceAppointment.ServiceTerritoryId);
                TDF_RefreshTerritories.RefreshByServiceTerritoryId(objServiceAppointment.ServiceTerritoryId);
            }
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
        PageReference pg = new PageReference('/apex/TDF_PlanningBoard');
        return pg;
    }

    //Method to get duty templates
    public void fetchDutyTemplates(){          
        
        dutyTemplateWrapperList = new List<DutyTemplateWrapper>();
        dutyTemplateMap = new Map<String, Route_Template__c>();
        //jobTemplateMap = new Map<String, List<Job_Template__c>>();        
        jobTemplateIdSet = new Set<String>();
        String[] splitStr1;
        String[] splitStr2;
        if(startDate != null){
            splitStr1 = String.valueOf(startDate).split('\\s+');
        }
        if(endDate != null){
            splitStr2 = String.valueOf(endDate).split('\\s+');
        }
        String sDate;
        String eDate;
        System.debug('splitStr1 ->'+splitStr1);
        System.debug('splitStr2 ->'+splitStr2);
        if(splitStr1 != null && splitStr1.size()>0){
            sDate = splitStr1[0];
        }
        if(splitStr2 != null && splitStr2.size()>0){ 
            eDate = splitStr2[0];
        }

        //To prepare dynamic query for Duty Template and its related Job Templates
        DescribeSObjectResult describeResult = Route_Template__c.getSObjectType().getDescribe();
        DescribeSObjectResult describeJobTempResult = Job_Template__c.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
        List<String> jobTemplateFields = new List<String>(describeJobTempResult.fields.getMap().keySet());

        //AJ 01.07.18 to resolve view state error, change query to just get DT.  Add get JT to GenerateWork and DeleteWork
        //String query = ' SELECT ' + String.join( fieldNames, ',' ) +', (SELECT '+String.join(jobTemplateFields,',')+', Location__r.TimeZone, Location__r.Name, Route_Template__r.VehicleType__c FROM Job_Templates__r)'+ ' FROM ' + describeResult.getName();          
        String query = ' SELECT Id, Name, Active_Route_Days__c, Effective_Date__c, Expiry_Date__c, Service_Territory__c, Status__c FROM ' + describeResult.getName();      
        if(objServiceAppointment.ServiceTerritoryId != null){
            query += ' WHERE Service_Territory__c = '+ '\'' +objServiceAppointment.ServiceTerritoryId + '\'';/*' AND Effective_Date__c >= '+ sDate + ' AND Expiry_Date__c <= '+ eDate + */
        }
        if(objDT.Status__c != null){
            if(objServiceAppointment.ServiceTerritoryId != null){
                query += ' AND Status__c = '+ '\'' +objDT.Status__c + '\'';
            }else{
                query += ' WHERE Status__c = '+ '\'' +objDT.Status__c + '\'';
            }
        }
        //AJ 01.07.18 Added Name search criteria
        if(!String.isBlank(nameSearchCriteria)){
            if(objDT.Status__c == null && objServiceAppointment.ServiceTerritoryId == null){         
                query += ' WHERE Name LIKE \'%'+ nameSearchCriteria +'%\'';
            }else{
                query += ' AND Name LIKE \'%'+ nameSearchCriteria +'%\'';
            }
        }
        
        query += ' ORDER BY Name ASC';
        System.debug('Query ->'+query);
        Set<String> dutyTempIdSet = new Set<String>();

        //Populate Duty Template select list
        for(Route_Template__c objDutyTemplate : Database.Query(query)){ 
            //If records found, add to the set
            if(!dutyTempIdSet.contains(objDutyTemplate.Id)){                    
                addDutyTemplate(objDutyTemplate);
                dutyTempIdSet.add(objDutyTemplate.Id);
            }
        }

        System.debug('dutyTemplateWrapperList ->'+dutyTemplateWrapperList+' Size->'+dutyTemplateWrapperList.size());

        TDF_NotificationScheduler__c objNotificationSch;

        //get the custom setting value for getting the specified limit of Service Appointments that can be shown on Dispatch page
        if(TDF_NotificationScheduler__c.getAll().get('PlanningBoardDutyTemplateCountCheck') != null){
            objNotificationSch = TDF_NotificationScheduler__c.getAll().get('PlanningBoardDutyTemplateCountCheck');
        }
        System.debug('objNotificationSch ->'+objNotificationSch);

        //compare the filtered records and limit specified in Custom Setting
        //If condition is satisfied then throw the error(Error is also specified in Custom Setting)    
        if(objNotificationSch != null && objNotificationSch.Service_Appointment_Query_Limit__c != null && dutyTemplateWrapperList.size() > objNotificationSch.Service_Appointment_Query_Limit__c){
            System.debug('objNotificationSch.Service_Appointment_Query_Limit__c ->'+objNotificationSch.Service_Appointment_Query_Limit__c);
            String dutyTemplateLimitErrMsg = objNotificationSch.Error_Message__c.replace('<?>', String.valueOf(Integer.valueOf(objNotificationSch.Service_Appointment_Query_Limit__c)));
            dutyTemplateLimitErrMsg = dutyTemplateLimitErrMsg.replace('<DT>', String.valueOf(Integer.valueOf(dutyTemplateWrapperList.size())));
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, dutyTemplateLimitErrMsg));
            dutyTemplateWrapperList = new List<DutyTemplateWrapper>();
        }         
    }

    public void addDutyTemplate(Route_Template__c objDT){
        dutyTemplateWrapperList.add(new DutyTemplateWrapper(objDT));
        dutyTemplateMap.put(objDT.Id, objDT);
        //AJ 01.07.18 Moved to within Generate Work
        //jobTemplateMap.put(objDT.Id, objDT.Job_Templates__r);       
    }

    //AJ 24.07.20 Refactored as logic moved to common class TDF_GenerateWork
    public PageReference generateWork(){

        //AJ 01.07.18 added
        Set<String> dutyTemplateIdSelectedSet = new Set<String>();
        dutyTemplateIdSelectedSet = new Set<String>();
        
        Boolean isRecordSelected = false;

        //AJ 24.07.20 Keep initial validation
        //show error message if Start Date or End Date missing
        if(generateWorkStartDate == null || generateWorkEndDate == null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please enter the dates'));
            return null;                
        }

        //show error message if Start Date is greater then End Date
        if(generateWorkStartDate > generateWorkEndDate){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Start Date should not be greater then End Date'));
            return null;                
        }

        //Calculate the days difference in Start and End date selected by User            
        Integer daysDifference = generateWorkStartDate.daysBetween(generateWorkEndDate);

        //validate the dates for 60 days difference
        if(daysDifference>60){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Date range must not be more than 60 days'));
            return null;
        }

        //AJ 01.07.18 Change to get Ids of selected Duty Templates
        for(DutyTemplateWrapper objDutyTemplateWrapper : dutyTemplateWrapperList){
            if(objDutyTemplateWrapper.isSelected){
                dutyTemplateIdSelectedSet.add(objDutyTemplateWrapper.objDutyTemplate.Id);
            }
        }

        //If too many templates selected
        if(dutyTemplateIdSelectedSet.size() > 50){
            //Display message
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Too many templates selected to generate (' + dutyTemplateIdSelectedSet.size() +'). Please select no more than 50.'));
        }
        
        //Else call generate work for each duty
        else{

            //For each selected duty template, call generate work
            for(Id dtId : dutyTemplateIdSelectedSet){

                System.debug('Call Generate Work for Duty Id = ' + dtId);
                //AJ 24.07.20 Call common Generate Work function for each duty via queueable interface
                Id jobID = System.enqueueJob(new TDF_GenerateWorkQueueable(generateWorkStartDate, generateWorkEndDate, dtId, null));

            }
            //Display message
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Request submitted successfully for duty templates (' + dutyTemplateIdSelectedSet.size() + '). Please allow a few minutes (depending on volume) for processing to complete.')); 
        }

        //AJ 01.07.18 Reset dates
        generateWorkStartDate = System.today();  
        generateWorkEndDate = System.today();
        return null;

    }    
    
    //Method to delete work from selected duties
    public PageReference confirmDeleteWork(){

        displayPopUp = true;
        Set<String> selectedDutyTemplateIdSet = new Set<String>();
        workOrderList = new List<WorkOrder>();
        workOrderLIList = new List<WorkOrderLineItem>();
        serviceAppointmentList = new List<ServiceAppointment>();
        assignedResourceList = new List<AssignedResource>();
        woCount = 0;
        woLICount = 0;
        saCount = 0;

        //show error message if Start Date or End Date missing
        if(deleteWorkStartDate == null || deleteWorkEndDate == null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please enter the dates'));
            return null;                
        }

        // Validate if start date is small than the current date
        if(deleteWorkStartDate < System.today()){
            ApexPages.Message errMsg= new ApexPages.Message(ApexPages.severity.ERROR, 'Start date cannot be earlier than the todays date');  
            ApexPages.addMessage(errMsg);
            return null;            
        } 

        for(DutyTemplateWrapper objDutyTemplateWrapper : dutyTemplateWrapperList){
            if(objDutyTemplateWrapper.isSelected){
                selectedDutyTemplateIdSet.add(objDutyTemplateWrapper.objDutyTemplate.Id);
            }
        }

        if(selectedDutyTemplateIdSet.size()==0){
            ApexPages.Message errMsg= new ApexPages.Message(ApexPages.severity.WARNING, 'Please select atleast one Duty Template for Deleting Works');  
            ApexPages.addMessage(errMsg);
            return null;             
        }

        if(deleteWorkStartDate != null && deleteWorkEndDate != null){

            Datetime endDateTime = Datetime.newInstance(deleteWorkEndDate.year(), deleteWorkEndDate.month(), deleteWorkEndDate.day(), 23, 59, 59);

            // Populate work order list to delete             
            for(WorkOrder objWorkOrder : [SELECT Id, StartDate, EndDate, Duty_Day__c, (SELECT Id FROM WorkOrderLineItems),(SELECT Id FROM ServiceAppointments) FROM WorkOrder WHERE Duty_Board__c IN : selectedDutyTemplateIdSet AND Status != 'Completed' AND Duty_Day__c != null]){

                if(objWorkOrder.Duty_Day__c >= deleteWorkStartDate && objWorkOrder.Duty_Day__c <= endDateTime){
                    workOrderList.add(objWorkOrder);
                    workOrderLIList.addAll(objWorkOrder.WorkOrderLineItems);
                    serviceAppointmentList.addAll(objWorkOrder.ServiceAppointments);
                }                
            }

            //populate count of records that are going to delete after confirmation from User
            woCount = workOrderList.size();
            woLICount = workOrderLIList.size();
            saCount = serviceAppointmentList.size();
            System.debug('woCount ->'+woCount);
            System.debug('woLICount ->'+woLICount);
            System.debug('saCount ->'+saCount); 
            deleteWorkOrders();           
        }
        
        //AJ 01.07.18 Default dates to today
        deleteWorkStartDate = System.today();
        deleteWorkEndDate = System.today(); 
        
        return null;
    }

     //Delete work order of duty board template 
    public PageReference deleteWorkOrders(){

        Savepoint sp;

        try{

            //Create database save point so if any exception occurs will rollback to this save point
            sp = Database.setSavepoint();

            //If work order exists then delete 
            if(workOrderList.size() > 0 ){
                delete workOrderList;                   
            }

            //hide popup and show success message
            displayPopUp = false;
            displaySuccessMessage = true; 
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,woCount+' Work Orders, '+woLICount+' WorkOrder Line Items, '+saCount+' Service Appointments deleted successfully.'));
            return null;

        }catch(Exception e){

            System.debug('Exception Occured : '+e.getMessage());
            System.debug('Exception Occured : '+e.getStackTraceString());
            
            //Rollback to save point
            Database.rollback( sp );
            return null;
        }
    }

    //method to reset the page without resetting the filtered criterias that are already selected
    public void resetPage(){   
        startDate = null;
        endDate = null;
        objServiceAppointment = new ServiceAppointment();
        dutyTemplateWrapperList = new List<DutyTemplateWrapper>();
        objDT = new Route_Template__c();
    }

    public class DutyTemplateWrapper{
        public Boolean isSelected{get;set;}
        public Route_Template__c objDutyTemplate{get;set;}

        public DutyTemplateWrapper(Route_Template__c objDT){
            objDutyTemplate = objDT;
        }
    }

    public class applicationException extends Exception {}
}