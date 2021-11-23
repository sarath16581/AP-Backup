public with sharing class TDF_DeleteWorkOrderFromDBT_ControllerX{
    public Date startDate{get;set;}
    public Date endDate{get;set;}
    public String jobBoardTemplateId{get;set;}
    public boolean hasWorkOrder{get;set;}
    public boolean isValidatedStartDate{get;set;}
    public List<WorkOrder> workOrderList{get;set;}
    public List<WorkOrderLineItem> workOrderLIList{get;set;}
    public List<ServiceAppointment> serviceAppointmentList{get;set;}
    public List<AssignedResource> assignedResourceList{get;set;}
    public RecordType workOrderRecordType;
    public Integer woCount{get;set;}
    public Integer woLICount{get;set;}
    public Integer saCount{get;set;}
    public Boolean displayPopUp{get;set;}
    public Boolean displaySuccessMessage{get;set;}
    
    // Constructor
    public TDF_DeleteWorkOrderFromDBT_ControllerX(ApexPages.standardController sc){
        jobBoardTemplateId = Apexpages.currentPage().getParameters().get('id');
        workOrderList = new List<WorkOrder>();
        workOrderLIList = new List<WorkOrderLineItem>();
        serviceAppointmentList = new List<ServiceAppointment>();
        assignedResourceList = new List<AssignedResource>();
        isValidatedStartDate = false;
        startDate = System.today();
        endDate = System.today();
        displayPopUp = false;
        displaySuccessMessage = false;
        woCount = 0;
        woLICount = 0;
        saCount = 0;

        //get Duty Assignements of current Duty Template
        for(Route_Assignment__c objRouteAssignment : [SELECT Id, Name, Start_Date__c, End_Date__c, Service_Resource__c FROM Route_Assignment__c WHERE Duty_Board__c =: jobBoardTemplateId]){
            if(objRouteAssignment.End_Date__c > endDate){
                endDate = objRouteAssignment.End_Date__c;
            }
        }
        
        //get all the WorkOrder related to current Duty Template
        workOrderList = [SELECT Id FROM WorkOrder WHERE Duty_Board__c =: jobBoardTemplateId];

        //make Boolean variable true/false according to size of WorkOrder list
        if(workOrderList.size()>0){
            hasWorkOrder = true;
        }else{
            hasWorkOrder = false;
        }        
    }

    //method to show count if reocrds that are going to be deleted and get confirmation from User before deleting
    public PageReference confirmDeletion(){ 

        // Validate if start date is small than the current date
        if(validateStartDate()){
            ApexPages.Message errMsg= new ApexPages.Message(ApexPages.severity.ERROR, 'Start date cannot be earlier than the current date');  
            ApexPages.addMessage(errMsg);
            return null;            
        }

        displayPopUp = true;
        workOrderList = new List<WorkOrder>();
        workOrderLIList = new List<WorkOrderLineItem>();
        serviceAppointmentList = new List<ServiceAppointment>();

        if(startDate != null && endDate != null){

            Datetime endDateTime = Datetime.newInstance(endDate.year(), endDate.month(), endDate.day(), 23, 59, 59);

            // Populate work order list to delete             
            for(WorkOrder objWorkOrder : [SELECT Id, StartDate, EndDate, Duty_Day__c, (SELECT Id FROM WorkOrderLineItems),(SELECT Id FROM ServiceAppointments) FROM WorkOrder WHERE /*StartDate >=: startDate AND EndDate <=: endDate AND*/ Duty_Board__c =: jobBoardTemplateId AND Status != 'Completed' AND Duty_Day__c != null]){

                if(objWorkOrder.Duty_Day__c >= startDate && objWorkOrder.Duty_Day__c <= endDateTime){
                    workOrderList.add(objWorkOrder);
                    workOrderLIList.addAll(objWorkOrder.WorkOrderLineItems);
                    serviceAppointmentList.addAll(objWorkOrder.ServiceAppointments);
                }                
            }

            //populate count of records that are going to delete after confirmation from User
            woCount = workOrderList.size();
            woLICount = workOrderLIList.size();
            saCount = serviceAppointmentList.size();
        }
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
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,workOrderList.size()+' Work Orders are deleted successfully. '));
            return null;

        }catch(Exception e){

            System.debug('Exception Occured : '+e.getMessage());
            System.debug('Exception Occured : '+e.getStackTraceString());
            
            //Rollback to save point
            Database.rollback( sp );
            return null;
        }
    }

    public PageReference cancel(){
        PageReference pg = new PageReference('/'+jobBoardTemplateId);
        return pg;
    }

    //To check if entered start date is valid or not
    public boolean validateStartDate(){
        if(startDate < System.today()){
            return true;
        }
        return false;
    }   
}