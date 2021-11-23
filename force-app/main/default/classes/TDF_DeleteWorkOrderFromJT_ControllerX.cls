public with sharing class TDF_DeleteWorkOrderFromJT_ControllerX {

    public Date startDate{get;set;}
    public Date endDate{get;set;}
    public boolean hasWorkOrder{get;set;}
    public List<WorkOrder> workOrderList;
    public List<WorkOrderLineItem> workOrderLIList;
    public List<ServiceAppointment> serviceAppointmentList;
    public List<AssignedResource> assignedResourceList;    
    public Integer woCount{get;set;}
    public Integer woLICount{get;set;}
    public Integer saCount{get;set;} 
    public String jobTemplateId;  
    public Boolean displayPopUp{get;set;}
    public Boolean displaySuccessMessage{get;set;}     

    //constructor
    public TDF_DeleteWorkOrderFromJT_ControllerX(ApexPages.StandardController controller) {

        //initialization
        startDate = System.today();
        endDate = System.today();   	
    	jobTemplateId = Apexpages.currentPage().getParameters().get('id');
    	workOrderList = new List<WorkOrder>();
        workOrderLIList = new List<WorkOrderLineItem>();
        serviceAppointmentList = new List<ServiceAppointment>();
        assignedResourceList = new List<AssignedResource>();
        displayPopUp = false;
        displaySuccessMessage = false;
        woCount = 0;
        woLICount = 0;
        saCount = 0;                 

        //get Work Orders for current Job Template
        workOrderList = [SELECT Id FROM WorkOrder WHERE Job_Template__c =: jobTemplateId];

        //get Job Template from current job template id
        Job_Template__c objJobTemplate = [SELECT Id, Route_Template__c FROM Job_Template__c WHERE Id =: jobTemplateId];

        //get Duty Assignments from current Job Template's Duty Board Id
        for(Route_Assignment__c objRouteAssignment : [SELECT Id, Name, Start_Date__c, End_Date__c, Service_Resource__c FROM Route_Assignment__c WHERE Duty_Board__c =: objJobTemplate.Route_Template__c]){
            if(objRouteAssignment.End_Date__c > endDate){
                endDate = objRouteAssignment.End_Date__c;
            }
        }                
        
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
            DateTime endDateTime = DateTime.newInstance(endDate.year(), endDate.month(), endDate.day(), 23, 59, 59); 

            //Populate work order list to delete           
            for(WorkOrder objWorkOrder : [SELECT Id, StartDate, EndDate, Duty_Day__c, (SELECT Id FROM WorkOrderLineItems),(SELECT Id FROM ServiceAppointments) FROM WorkOrder WHERE Job_Template__c =: jobTemplateId AND Status != 'Completed']){
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
        PageReference pg = new PageReference('/'+jobTemplateId);
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