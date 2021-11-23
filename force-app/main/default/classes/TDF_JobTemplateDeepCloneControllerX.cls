public with sharing class TDF_JobTemplateDeepCloneControllerX {

	public String jobTemplateId;
	public Job_Template__c objJobTemplate;
	public Job_Template__c objClonedJobTemplate;

	//constructor
    public TDF_JobTemplateDeepCloneControllerX(ApexPages.StandardController controller) {
    	objJobTemplate = new Job_Template__c();
    	jobTemplateId = ApexPages.currentPage().getParameters().get('id');

    	if(jobTemplateId != null){

	        //To prepare dynamic query using Job Template's field set
	        List<String> jobTemplateFields = new List<String>();
			Schema.FieldSet jobTemplateFieldSet = Schema.SObjectType.Job_Template__c.fieldSets.getMap().get('TDF_Clone_Fields');
			for(Schema.FieldSetMember objFieldSetMember : jobTemplateFieldSet.getFields()){
				jobTemplateFields.add(objFieldSetMember.getFieldPath());
			}			
			String queryString = 'SELECT ' + String.join( jobTemplateFields, ',' ) + ' FROM Job_Template__c';
			queryString += ' WHERE Id = \''+jobTemplateId+'\'' + ' LIMIT 1';
			System.debug('Query ->'+queryString);
			objJobTemplate = Database.query(queryString);
	        objClonedJobTemplate = objJobTemplate.clone(false, true, false, false);
    	}
    }

    //Action method called when clicked on Deep Clone button
	public PageReference deepCloneJobTemplate(){

		//Set savepoint
    	Savepoint sp = Database.setSavepoint();

    	List<Task_Template__c> taskTemplateToInsertList = new List<Task_Template__c>();

    	try{    

	        List<String> taskTemplateFields = new List<String>();	        

	        //To prepare dynamic query using Task Template's field set
			Schema.FieldSet taskTemplateFieldSet = Schema.SObjectType.Task_Template__c.fieldSets.getMap().get('TDF_Clone_Fields');
			for(Schema.FieldSetMember objFieldSetMember : taskTemplateFieldSet.getFields()){
				taskTemplateFields.add(objFieldSetMember.getFieldPath());
			}
	        String queryString = ' SELECT '+String.join(taskTemplateFields,',')+' FROM Task_Template__c';
	        queryString += ' WHERE Job_Template__c = \''+jobTemplateId+'\'';

	        //insert the cloned Job Template
        	insert objClonedJobTemplate;

        	//loop throght the Task Templates and give the newly created Job Template Id
        	for(Task_Template__c objTaskTemplate : Database.query(queryString)){
        		Task_Template__c objTT = objTaskTemplate.clone();
        		objTT.Job_Template__c = objClonedJobTemplate.Id;
        		taskTemplateToInsertList.add(objTT);
        	}

        	//insert Cloned Task Templates
        	if(taskTemplateToInsertList.size()>0){
        		insert taskTemplateToInsertList;
        	}

        	//redirect to cloned Job Template after successful insertion of all the cloned records
    		PageReference pg = new PageReference('/'+objClonedJobTemplate.Id);
    		return pg;

		}catch(Exception e){
    		System.debug('Exception Occur due to ->'+e.getMessage()+' Location ->'+e.getLineNumber());
    		Database.rollback(sp); 			
    		return null;
		}		
	}
}