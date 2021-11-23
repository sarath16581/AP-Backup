/**************************************************
Description: Controller for Page behind the Generating a Work Order button from a Duty Template
History:
--------------------------------------------------
Unknown     Unknown                             Created
12-09-2019  gunith.devasurendra@auspost.com.au  Removed the unused dutyBoardServiceAppointmentMap which caused view state size limit exceeded error (INC1455105)
24-07-2020  ajudd@salesforce.com				Refactored, moving body of code to generic TDF_GenerateWork class
25-08-2020  ajudd@salesforce.com                Removed commented out code replaced by common TDF_GenerateWork class 
**************************************************/
public with sharing class TDF_GenerateWorkOrderFromDBT_ControllerX{
    public Date startDate{get;set;}
    public Date endDate{get;set;}
    
    public String jobBoardTemplateId{get;set;}
    public boolean hasJobTemplate{get;set;}

    public Route_Template__c objDutyTemplate{get;set;}
    public Date eDate;

    // Constructor
    public TDF_GenerateWorkOrderFromDBT_ControllerX(ApexPages.standardController sc){

        //Initialization
        
        startDate = System.today();
        endDate = System.today();
        eDate = System.today(); 
  
        //Get the selected Duty Template record
        jobBoardTemplateId = Apexpages.currentPage().getParameters().get('id');
        if(jobBoardTemplateId != null){
            objDutyTemplate = [SELECT Id, Name, Status__c, Service_Territory__c, Default_Vehicle__c, Effective_Date__c, Expiry_Date__c 
                                FROM Route_Template__c 
                                WHERE Id =: jobBoardTemplateId];
        }

        if(objDutyTemplate.Status__c != 'Active'){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Duty Template must be Active before generating Work'));            
        }
        
        hasJobTemplate = true;

    }
    
    //Create Work Order and Work Order Line Item from Job template and Task template
    public PageReference createWOandWOLineItem(){ 
       
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

        //AJ 26.06.18 Adjust start and end dates to align with Duty Template Effective and Expiry Dates           
        //If Effective Date not null, then if start date is before effective date, then change it to effective date
        if(objDutyTemplate.Effective_Date__c != null){
            if(startDate < objDutyTemplate.Effective_Date__c){
                startDate = objDutyTemplate.Effective_Date__c;
                //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'The Start Date is prior to the Duty Template Effective Date'));
                //return null;
            }
        }

        //If Expiry Date not null, then if end date is on or after expiry date, then change it to day before expiry date
        if(objDutyTemplate.Expiry_Date__c != null){
            if(endDate >= objDutyTemplate.Expiry_Date__c){
                endDate = objDutyTemplate.Expiry_Date__c.addDays(-1);
                //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'The End Date is greater than or equal to the Duty Template Expiry Date'));
                //return null;
            }
        }         
        
        //Calculate the days difference in Start and End date selected by User            
        Integer daysDifference = startDate.daysBetween(endDate);
        
        //validate the dates for 60 days difference
        if(daysDifference>60){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Date range should be 60 days'));
            return null;
        }
        
        //TDF Enhance 24-07-2020: Call new common class to generate jobs
        TDF_GenerateWork generateWork = new TDF_GenerateWork();
        resultString = generateWork.createJobs(startDate, endDate, jobBoardTemplateId, null); 
        
        resetListsAndDate();

        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM, resultString)); 
        return null;
    }
      
    //To go back on duty board
    public PageReference goBack(){
        PageReference pg = new PageReference('/'+jobBoardTemplateId);
        return pg;
    }

    public void resetListsAndDate(){
        startDate = System.today();
        endDate = eDate;   
    }     
}