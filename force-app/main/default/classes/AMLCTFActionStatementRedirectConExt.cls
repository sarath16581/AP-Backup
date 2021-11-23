public class AMLCTFActionStatementRedirectConExt {
/*------------------------------------------------------------
Author:        Kenny Liew
Company:       Salesforce
Description:   Saves Action Statement record programmatically, as oppose to needing user to save in UI
Inputs:        New action of Action Statement is overriden with VF - AMLCTFActionStatementNewButtonOverride
			   which calls this controller extension
Test Class:    AMLCTFActionStatementRedirectConExt_Test
History
<Date>      	<Authors Name>     	<Brief Description of Change>
15.Sep.2016    	Kenny Liew	     	Initial Version
------------------------------------------------------------*/
    
    private ApexPages.StandardController standardController;
    private String recId;
    
    public AMLCTFActionStatementRedirectConExt (ApexPages.StandardController controller){ 
        this.standardController = controller;
    }

    public String getActionStatementRecordId() {
    	return recId;
    }

    public Pagereference pageredir()
    {
        
      	AMLCTF_Audit_Action_Statement__c record = (AMLCTF_Audit_Action_Statement__c) standardController.getRecord();
        insert record;
        recId = record.Id;
        return new PageReference('/' + record.Id);
    }
    
}