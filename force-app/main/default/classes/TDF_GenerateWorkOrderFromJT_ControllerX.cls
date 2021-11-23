/**************************************************
Description: Controller for Page behind the Generating a Work Order button from a Job Template
History:
--------------------------------------------------
Unknown     Unknown                             Created
24-07-2020  ajudd@salesforce.com				Refactored, moving body of code to generic TDF_GenerateWork class
25-08-2020  ajudd@salesforce.com                Removed commented out code replaced by common TDF_GenerateWork class 
**************************************************/
public with sharing class TDF_GenerateWorkOrderFromJT_ControllerX {

    public Date startDate{get;set;}
    public Date endDate{get;set;}
    
    public Id jobTemplateId;
    public Job_Template__c objJobTemplate;
    public boolean renderForm{get;set;}
    
    public Date eDate;
    public Id jobBoardTemplateId;

    // Constructor
    public TDF_GenerateWorkOrderFromJT_ControllerX(ApexPages.StandardController controller){

        //Initialization
        startDate = System.today();
        endDate = System.today(); //AJ 25.06.18 Changed from day + 1 to today
        eDate = System.today();
        //hasTaskTemplate = false;
        renderForm = true;
        jobTemplateId =  Apexpages.currentPage().getParameters().get('id');
        
        //AJ 24.07.20 Added to get Job Template details
        if(jobTemplateId != null){
            objJobTemplate = [SELECT Id, Route_Template__c, Route_Template__r.Name, Route_Template__r.Status__c, Route_Template__r.Service_Territory__c, 
                              Route_Template__r.Default_Vehicle__c, Route_Template__r.Effective_Date__c, Route_Template__r.Expiry_Date__c 
                              FROM Job_Template__c WHERE Id =: jobTemplateId];
        }
        
        //If Duty Template not active, display message
        if(objJobTemplate.Route_Template__r.Status__c != 'Active'){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Duty Template must be Active before generating Work'));            
        }
        else{
            jobBoardTemplateId = objJobTemplate.Route_Template__c;
        }

    }

    //Create Work Order and Work Order Line Item from Job template and Task template
    public PageReference createWorkOrders(){
		
        String resultString; 
        
        //AJ 24.07.20 Keep initial validation
        //show error message if Start Date or End Date missing
        if(startDate == null || endDate == null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please enter the dates'));
            return null;                
        }
        
        //show error message if Start Date is greater then End Date
        if(startDate > endDate){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Start Date should not be greater then End Date'));
            return null;                
        }

        //Calculate the days difference in Start and End date selected by User 
        Integer daysDifference = startDate.daysBetween(endDate);
        
        //validate the dates for 60 days difference
        if(daysDifference>60){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Date range should be 60 days'));
            return null;
        }        
        
        //TDF Enhance 24-07-2020: Call new common class to generate jobs, specifying the job template
        TDF_GenerateWork generateWork = new TDF_GenerateWork();
        resultString = generateWork.createJobs(startDate, endDate, jobBoardTemplateId, jobTemplateId); 
        
        resetListsAndDate();

        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM, resultString)); 
        return null;
    }

    //To go back on Job template
    public PageReference goBack(){
        PageReference pg = new PageReference('/'+jobTemplateId);
        return pg;
    } 

    public void resetListsAndDate(){
        startDate = System.today();
        endDate = eDate;   
    }                  
}