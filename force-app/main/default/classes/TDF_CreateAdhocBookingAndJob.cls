/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-06-25 
* @description Controller for the Create Adhoc Booking and Job Page available from FSL Gantt actions Create Booking and Job
*               Created based on TDF_DispatchBoardController
*
* @changelog 
* 2020-06-15 - Andrew Judd - Created 
* 2020-09-29 - Andrew Judd - Added numeric check of times entered in validateFields
* 2020-10-19 - Andrew Judd - TDF Enhance Fix: Change to setting of default expiry date and generate work end date 
*/
public with sharing class TDF_CreateAdhocBookingAndJob {

    public Job_Template__c objJobTemplate{get;set;}
    public List<Task_Template__c> taskTemplateList{get;set;}
    public Integer selectedTaskTemplateIndex{get;set;}
    public Boolean saveAndGenerateReset;

    public Date effectiveDate{get;set;}
    public Date expiryDate{get;set;}

    //Constuctor
    public TDF_CreateAdhocBookingAndJob(){

        //Initialization
        objJobTemplate = new Job_Template__c();
        taskTemplateList = new List<Task_Template__c>();
        taskTemplateList.add(new Task_Template__c());
        selectedTaskTemplateIndex = 0;
        saveAndGenerateReset = false;

        effectiveDate = System.today();
        //TDF Enhance Fix 19.10.20 Change default expiry from tomorrow to 7 days from now
        expiryDate = effectiveDate.addDays(7); 

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

    //method called from button to save the Job Tempalte and Task Template
    public PageReference saveTemplates(){

        //Validate field values
        if(!validateFields()) return null;
        
        //Declare the SavePoint
        Savepoint sp;

        try{

            sp = Database.setSavepoint();
            //Call method to create templates
            createTemplates();

        }
        catch(Exception e){

            //Reset list
            resetTemplates();
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getMessage()));            
            System.debug('Exception Occured : '+e.getMessage());
            System.debug('Exception Occured : '+e.getStackTraceString());

            // Rollback to save point
            Database.rollback( sp );
            return null;

        }

        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Job Template and Task Templates created successfully!'));

        System.debug('objJobTemplate Id->'+objJobTemplate.Id);
        resetTemplates();
        return null;
        
    }

    //method to save templates and generate work for those templates
    public Pagereference saveAndGenerateWork(){

        //Validate field values
        if(!validateFields()) return null;

        //Declare the SavePoint
        Savepoint sp;

        try{
            
            sp = Database.setSavepoint();
            
            //make boolean false to not reset the templates
            saveAndGenerateReset = true;
            //saveTemplates();
            createTemplates();
            saveAndGenerateReset = false;
            
            Date startDateGen = System.today();
            //TDF Enhance Fix 19.10.20 Change generate work end date from to today to today + 6 days
            Date endDateGen = System.today().addDays(6);
            String resultString;

            //Call method to generate job
            if(objJobTemplate.Id != null){
                TDF_GenerateWork generateWork = new TDF_GenerateWork();
                resultString = generateWork.createJobs(startDateGen, endDateGen, objJobTemplate.Route_Template__c, objJobTemplate.Id); 
            }
            
            //Reset the form             
            resetTemplates();

            //Display success message
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM, resultString)); 
            return null;

        }catch(Exception e){
            
            //Reset list should be ok
            resetTemplates();
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getMessage()));            
            System.debug('Exception Occured : '+e.getMessage());
            System.debug('Exception Occured : '+e.getStackTraceString());

            // Rollback to save point
            Database.rollback( sp );
            return null;
        }
    }

    //AJ New method create templates
    //Move code from body of saveTemplate
    public void createTemplates(){
        
        Boolean taskToInsert = false;
        String dockNumber;

        //insert Job Template first to link it with the Task Template
        if(objJobTemplate.Id == null){
            
            //Set date fields from form
            objJobTemplate.Effective_Date__c = effectiveDate;
            objJobTemplate.Expiry_Date__c = expiryDate;

            insert objJobTemplate;
        }

        //loop thru the Task Templates and associate with Job Template
        for(Task_Template__c objTaskTemplate :  taskTemplateList){
            
            //If a task is specified
            If(objTaskTemplate.Task__c != null){
                
                taskToInsert = true;
                //Get task level doc number from place holder field
                dockNumber = objTaskTemplate.Collect_From_Dock_Number__c;
            	
                //Create task
                objTaskTemplate.DTID__c = objJobTemplate.Route_Template__c;
                if(objTaskTemplate.Task__c == 'Collect Product'){
                    objTaskTemplate.Collect_From_Job_Template__c = objJobTemplate.Id;
                    objTaskTemplate.Collect_From_Dock_Number__c = dockNumber;
                    objTaskTemplate.Deliver_To_Dock_Number__c = null;
                }
                else if(objTaskTemplate.Task__c == 'Deliver Product'){
                    objTaskTemplate.Deliver_To_Job_Template__c = objJobTemplate.Id;
                    objTaskTemplate.Deliver_To_Dock_Number__c = dockNumber;
                    objTaskTemplate.Collect_From_Dock_Number__c = null;
                    
                }
            }
        }

        //insert Task Templates
        if(taskToInsert){
            insert taskTemplateList;
        }   
    }

    //Method to validate fields in form before save template or save and template and generate work
    public Boolean validateFields(){

        //Validate dates and times
        if(objJobTemplate.Start_Time__c != null && objJobTemplate.Start_Time__c.isNumeric() == false ){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Start Time must be a 4 digit numeric value in 24 hour format with no colon'));
            return false;
        }
        if(objJobTemplate.Earliest_Start_Time__c != null && objJobTemplate.Earliest_Start_Time__c.isNumeric() == false ){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Earliest Start Time must be a 4 digit numeric value in 24 hour format with no colon'));
            return false;
        }
        if(objJobTemplate.Latest_Start_Time__c != null && objJobTemplate.Latest_Start_Time__c.isNumeric() == false ){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Latest Start Time must be a 4 digit numeric value in 24 hour format with no colon'));
            return false;
        }          
        if(objJobTemplate.Start_Time__c != null && objJobTemplate.Earliest_Start_Time__c != null && objJobTemplate.Start_Time__c < objJobTemplate.Earliest_Start_Time__c){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Start Time must be greater or equal to Earliest Start Time'));
            return false;
        }
        if(objJobTemplate.Start_Time__c != null && (Integer.valueOf(objJobTemplate.Start_Time__c)>2400 || Integer.valueOf(objJobTemplate.Start_Time__c)<0)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Start Time must be between 0000 and 2400'));
            return false;
        }
        if(objJobTemplate.Latest_Start_Time__c != null && (Integer.valueOf(objJobTemplate.Latest_Start_Time__c)>2400 || Integer.valueOf(objJobTemplate.Latest_Start_Time__c)<0)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Latest Start Time must be between 0000 and 2400'));
            return false;
        }
        if(effectiveDate != null && expirydate != null){
            if(expiryDate <= effectiveDate){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'The expiry date must be at least 1 day after the effective date for the booking to be valid.'));
                return false;
            }
        }

        //Validate selected template is an Adhoc. Get duty template
        Route_Template__c objDutyTemplate = [SELECT Id, Is_Adhoc__c FROM Route_Template__c WHERE Id = :objJobTemplate.Route_Template__c];
        if(objDutyTemplate.Is_Adhoc__c == false){
            //If the template is not adhoc then display error
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'The selected Duty Template is not Adhoc. Please select an Adhoc Duty Template'));
            return false;
        }

        return true;
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
}