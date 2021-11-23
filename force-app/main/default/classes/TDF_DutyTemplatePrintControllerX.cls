public class TDF_DutyTemplatePrintControllerX {
//Controller for page TDF_DutyTemplatePrint
//Created 08-10-18 Andrew Judd
    public String dutyTemplateId{get;set;} 
    public List<Job_Template__c> jobTemplateList{get;set;}

	// Constructor    
    public TDF_DutyTemplatePrintControllerX(ApexPages.standardController sc){
        
        //Get Id
        dutyTemplateId = Apexpages.currentPage().getParameters().get('id');
        
        //Get file name for save default
        String fileName = [SELECT Name FROM Route_Template__c WHERE Id = :dutyTemplateId LIMIT 1].Name;      
        Apexpages.currentPage().getHeaders().put( 'content-disposition', 'inline; filename=' + fileName + '.pdf');            
        
        //Get list of jobs
        String query = ' SELECT Day_Start_Time__c, Start_Time__c, Activity_Type__c, Duration__c, Job_Instructions__c, ' + 
            			' Location__r.Name, Location_Details__c, Dock_Number__c, Route_Template__r.Name, ' + 
            			' Location__r.Site_Instruction_Notes__c, Location__r.Site_Instructions__c ' + 
            			' FROM Job_Template__c WHERE Route_Template__c = \'' + dutyTemplateId + '\'' + 
            			' ORDER BY Day_Start_Time__c ';
        
        jobTemplateList = Database.query(query);

    }
}