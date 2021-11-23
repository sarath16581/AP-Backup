global class CalcRevByOrgSchedule implements Schedulable {
/*------------------------------------------------------------  
Author:        Mathanan Yogaratnam
Company:       Salesforce.com
Description:   This class is used for scheduling the Revenue by Organisation calculation process.
		
Test Class:
History
<Date>      <Authors Name>     <Brief Description of Change>
27-03-2014	Mathanan Yogaranam	Initial Release
------------------------------------------------------------*/

// 
    
    global void execute(SchedulableContext scMain) {

        CalcRevByOrgBatch calcProcess = new CalcRevByOrgBatch();

		//Get the scope size from custom settings
		BatchJobSettings__c settings = BatchJobSettings__c.getInstance();
		Integer scopeSize = (Integer)settings.OrgRevCalcScopeSize__c;

        ID idBatch = Database.executeBatch(calcProcess, scopeSize);

    }
}