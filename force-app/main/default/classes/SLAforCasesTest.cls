@IsTest (IsParallel=true)
public class SLAforCasesTest {

    @TestSetup
    static void setup(){
        
         //.. Get Custom Metadata for Callback Settings.
		Callback_Request_Settings__mdt callbackMdt = [SELECT CaseStatus__c,Case_Queue_Name__c, Initial_SLA_in_Hours__c, Case_Type__c, Enquiry_Sub_Type__c, Product_Category__c
                                                      FROM Callback_Request_Settings__mdt 
                                                      WHERE QualifiedApiName = 'Callback_Request_Settings'];
		
        String sProduct = callbackMdt.Product_Category__c.Split(',')[0];
        /*** Create Case record records. */
        Case cs = new Case();
        cs.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW General Enquiry').getRecordTypeId();
        cs.BusinessHoursId=[SELECT Id FROM BusinessHours WHERE Name='SSSWSydney'].Id;
        cs.Type = callbackMdt.Case_Type__c;
        cs.CaseOriginator__c = 'Sender';
        cs.Origin = SSSWConstants.CASE_ORIGIN;
        cs.ProductCategory__c = sProduct;
        cs.ProductSubCategory__c = callbackMdt.Enquiry_Sub_Type__c;
        cs.Priority = SSSWConstants.CASE_PRIORITY;
        cs.Subject='Testing 5 Days SLA';
        cs.Status= callbackMdt.CaseStatus__c;
        cs.OwnerId = [SELECT Id, QueueId FROM QueueSobject WHERE Queue.Name='SSSW Network Queue'].QueueId;
        cs.ResolutionCode__c = 'Assistance provided';
		cs.EnquirySubType__c = SSSWConstants.CASE_ENQUIRY_SUBTYPE;
        insert cs;
    }

    @IsTest
    public static void SLAforCasesBatchTest(){
		Test.startTest();
        SLAforCases slac = new SLAforCases();
		Database.executeBatch(slac);
        Test.stopTest();
    }
}