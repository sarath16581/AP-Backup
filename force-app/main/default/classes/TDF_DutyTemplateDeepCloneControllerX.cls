/**************************************************
Description: Controller for clone of Duty Template and child record. Called from Deep Clone action on Duty Template
History:
--------------------------------------------------
07-07-2020  ajudd@salesforce.com                TDF Enhance 20: Added reference to Collect and Deliver Tasks and removed reference to original M-D JT to TT relationship
												Removed duty assignment logic

**************************************************/
public with sharing class TDF_DutyTemplateDeepCloneControllerX {

    public String dutyTemplateId;
    public Route_Template__c objDutyTemplate{get;set;}
    public Route_Template__c objClonedDutyTemplate{get;set;}
    public List<Job_Template__c> jobTemplateToCloneList;
    public String dutyTemplateName{get;set;}

    //constructor
    public TDF_DutyTemplateDeepCloneControllerX(ApexPages.StandardController controller){
        
        //Initialization
        dutyTemplateId = ApexPages.currentPage().getParameters().get('id');
        objDutyTemplate = new Route_Template__c();
        objClonedDutyTemplate = new Route_Template__c();
        jobTemplateToCloneList = new List<Job_Template__c>();
        dutyTemplateName = '';

        if(dutyTemplateId != null){

            //To prepare dynamic query using field set
            List<String> dutyTemplateFields = new List<String>();
            Schema.FieldSet dutyTemplateFieldSet = Schema.SObjectType.Route_Template__c.fieldSets.getMap().get('TDF_Clone_Fields');
            for(Schema.FieldSetMember objFieldSetMember : dutyTemplateFieldSet.getFields()){
                dutyTemplateFields.add(objFieldSetMember.getFieldPath());
            }

            String queryString = 'SELECT ' + String.join( dutyTemplateFields, ',' ) + ' FROM Route_Template__c';
            queryString += ' WHERE Id = \''+dutyTemplateId+'\'' + ' LIMIT 1';
            System.debug('Query ->'+queryString);

            //execute the query and get Duty Template
            objDutyTemplate = Database.query(queryString);
            if(objDutyTemplate != null){
                dutyTemplateName = objDutyTemplate.Name;
            }

            //clone the Duty Template
            objClonedDutyTemplate = objDutyTemplate.clone(false, true, false, false);          
        }
    }

    //Action method called when clicked on Deep Clone button
    public PageReference deepCloneDutyTemplate(){

        //Local variables declaration
        Map<Id, Job_Template__c> jobTemplateMap = new Map<Id, Job_Template__c>();
        List<Task_Template__c> cloneTaskTemplateList = new List<Task_Template__c>();
        //AJ 07.07.20: Remove clone of Duty Assignment as best not to clone this
        //List<Route_Assignment__c> clonedutyAssignmentList = new List<Route_Assignment__c>();
        //AJ 07.07.20: New task template clone map
        Map<Id, Task_Template__c> cloneTaskTemplateMap = new Map<Id, Task_Template__c>();

        //Set savepoint
        Savepoint sp = Database.setSavepoint();

        try{

            //trim the duty template name string for removing spaces
            dutyTemplateName = dutyTemplateName.trim();

            //if user dont's change the name and put null for the name then clone the template with the same name by appending '- Copy' against the name
            if(dutyTemplateName == null || dutyTemplateName == '' || objDutyTemplate.Name == dutyTemplateName){
                objClonedDutyTemplate.Name = objDutyTemplate.Name+' - Copy';    
            }else{
                objClonedDutyTemplate.Name = dutyTemplateName;
            }

            //insert the cloned Duty Template
            insert objClonedDutyTemplate;       

            //To prepare dynamic query using Job Template's field set
            List<String> jobTemplateFields = new List<String>();
            Schema.FieldSet jobTemplateFieldSet = Schema.SObjectType.Job_Template__c.fieldSets.getMap().get('TDF_Clone_Fields');
            for(Schema.FieldSetMember objFieldSetMember : jobTemplateFieldSet.getFields()){
                jobTemplateFields.add(objFieldSetMember.getFieldPath());
            }

            //To prepare dynamic query using Task Template's field set
            List<String> taskTemplateFields = new List<String>();
            Schema.FieldSet taskTemplateFieldSet = Schema.SObjectType.Task_Template__c.fieldSets.getMap().get('TDF_Clone_Fields');
            for(Schema.FieldSetMember objFieldSetMember : taskTemplateFieldSet.getFields()){
                taskTemplateFields.add(objFieldSetMember.getFieldPath());
            }

            //Query the Job Temlate and related Task Templates from Dynamic Query
            //AJ 07.07.20: change query string to get tasks based on new data model (i.e. based on collect and deliver lookup fields)
            String queryString = ' SELECT ' + String.join( jobTemplateFields, ',' );
           // queryString += ',(SELECT '+String.join(taskTemplateFields,',')+' FROM Task_Templates__r)';  //AJ TODO: REMOVE?
            queryString += ',(SELECT '+String.join(taskTemplateFields,',')+' FROM Collect_Task_Templates__r)';
            queryString += ',(SELECT '+String.join(taskTemplateFields,',')+' FROM Deliver_Task_Templates__r)';
            queryString += ' FROM Job_Template__c';
            queryString += ' WHERE Route_Template__c = \''+dutyTemplateId+'\'';

            //loop throght the job templates and create clone Job Templates and Task Templates
            for(Job_Template__c objJobTemplate : Database.query(queryString)){
                Job_Template__c objCloneJobTemplate = new Job_Template__c();
                objCloneJobTemplate = objJobTemplate.clone(false, true);
                objCloneJobTemplate.Route_Template__c = objClonedDutyTemplate.Id;
                jobTemplateMap.put(objJobTemplate.Id, objCloneJobTemplate);
                
                //AJ 07.07.20: Remove this as task templates now only have collect from or deliver to job templates
                /*
                for(Task_Template__c objTaskTemplate : objJobTemplate.Task_Templates__r){
                    cloneTaskTemplateList.add(objTaskTemplate.clone());
                }*/
                
                //AJ 07.07.20: Clone templates based on collect from
                for(Task_Template__c objTaskTemplate : objJobTemplate.Collect_Task_Templates__r){
                    //Add clone of task template to map.  Note use of map as some task templates will have both a collect from and a deliver to
                    cloneTaskTemplateMap.put(objTaskTemplate.Id,objTaskTemplate.clone());
                }
                //AJ 07.07.20: Clone templates based on deliver to
                for(Task_Template__c objTaskTemplate : objJobTemplate.Deliver_Task_Templates__r){
                    //Add clone of task template to map. 
                    cloneTaskTemplateMap.put(objTaskTemplate.Id,objTaskTemplate.clone());
                }
                
            }

            //insert the Job Templates
            insert jobTemplateMap.values();

            //loop throght the Task Templates and give the newly created Job Template Id
            //AJ 07.07.20: Change to loop thru map values
            //for(Task_Template__c objTaskTemp : cloneTaskTemplateList){
            for(Task_Template__c objTaskTemp : cloneTaskTemplateMap.values()){
                
                //AJ 07.07.20: Set legacy look up field to null
                //objTaskTemp.Job_Template__c = jobTemplateMap.get(objTaskTemp.Job_Template__c).Id;
                objTaskTemp.Job_Template__c = null;
                
                //AJ 07.07.20: Set duty template Id
                objTaskTemp.DTID__c = objClonedDutyTemplate.Id;
                
                //Set Collect from and Deliver tos from map if they were set in the clone from record
                if(objTaskTemp.Collect_From_Job_Template__c != null){
                	objTaskTemp.Collect_From_Job_Template__c = jobTemplateMap.get(objTaskTemp.Collect_From_Job_Template__c).Id;
                }
                if(objTaskTemp.Deliver_To_Job_Template__c != null){
                	objTaskTemp.Deliver_To_Job_Template__c = jobTemplateMap.get(objTaskTemp.Deliver_To_Job_Template__c).Id;
                }
            }

            //insert Cloned Task Templates
            //AJ 07.07.20: Insert based on new map
            //insert cloneTaskTemplateList;
            insert cloneTaskTemplateMap.values();

            
            //AJ 07.07.20: Remove clone of Duty Assignment records
            /*
            List<String> dutyAssignmentFields = new List<String>();

            
            //To prepare dynamic query using Duty Assignement's field set
            Schema.FieldSet dutyAssignmentFieldSet = Schema.SObjectType.Route_Assignment__c.fieldSets.getMap().get('TDF_Clone_Fields');
            for(Schema.FieldSetMember objFieldSetMember : dutyAssignmentFieldSet.getFields()){
                dutyAssignmentFields.add(objFieldSetMember.getFieldPath());
            }
            
            //A.Judd 01.11.2018 Changed query to exclude clone of duty assignments in the past or with inactive SRs
            Date dToday = Date.today();
            String queryForDutyAssignment = 'SELECT ' + String.join( dutyAssignmentFields, ',' ) + ' FROM Route_Assignment__c';
            queryForDutyAssignment += ' WHERE  Duty_Board__c = \''+dutyTemplateId+'\'';
            queryForDutyAssignment += ' AND Service_Resource__r.IsActive = true AND End_Date__c >= :dToday';         

            //loop through the Duty Assignment and make a clone of it 
            for(Route_Assignment__c objRouteAssignment : Database.query(queryForDutyAssignment)){
                Route_Assignment__c objCloneRouteAssignment = new Route_Assignment__c();
                objCloneRouteAssignment = objRouteAssignment.clone();
                objCloneRouteAssignment.Duty_Board__c = objClonedDutyTemplate.Id;
                clonedutyAssignmentList.add(objCloneRouteAssignment); 
            }

            //insert the cloned Duty Assignment
            insert clonedutyAssignmentList;
			*/
            //redirect to cloned Duty Template after successful insertion of all the cloned records
            PageReference pg = new PageReference('/'+objClonedDutyTemplate.Id);
            return pg;

        }catch(Exception e){
            System.debug('Exception Occur due to ->'+e.getMessage()+' Location ->'+e.getLineNumber());
            Database.rollback(sp);          
        }
        return null;
    }
}