//StarTrack Class used by StarTrackRelatedCasesSidePanel VF component
//Created by: David Catindoy - Dec. 5, 2016
public with sharing class StarTrackRelatedCasesSidePanelController {
    //Declare containers
    public List<Case> billingAccountRelatedCases {get; set;}
    public Case caseRecord {get; set;}
    public List<String> relCasesFields {get; set;}
    
    public StarTrackRelatedCasesSidePanelController(ApexPages.StandardController controller){
        
        if(!Test.isRunningTest()){
            controller.addFields(new List<String>{'Id', 'Related_Billing_Account__c'}); //Add fields to the standard controller.
        }
        caseRecord = (Case) controller.getRecord(); //Get record from the standard controller.
        //Initialiaze containers.
        billingAccountRelatedCases = new List<Case>();
        relCasesFields = new List<String>();
        
        if(String.isNotBlank(caseRecord.Related_Billing_Account__c)){ //Check if current case has billing account.
            String relCasesQuery = 'SELECT Id, Owner.Name, ArticleTest__r.Name'; //Initialize string query variable.
            
            // Get related cases column fields
            for(Schema.FieldSetMember fsm : SObjectType.Case.FieldSets.getMap().get('StarTrack_Billing_Account_Related_Cases').getFields()){
                relCasesFields.add(fsm.getFieldPath());
            }
            
            if(!relCasesFields.isEmpty()){
                relCasesQuery += ', ' + String.join(relCasesFields, ','); //Add fields on the string query variable.
            }
            //Finalize query.
            relCasesQuery+= ' FROM Case WHERE Id != \'' + caseRecord.Id + '\' AND Related_Billing_Account__c = \'' + caseRecord.Related_Billing_Account__c + '\' AND RecordType.Name = \'' + StarTrack_Constants.CASE_CREDIT_RT + '\' ORDER BY CreatedDate DESC';
            
            billingAccountRelatedCases = Database.query(relCasesQuery); //Execute query and assign results to our list variable.
        }
    }
}