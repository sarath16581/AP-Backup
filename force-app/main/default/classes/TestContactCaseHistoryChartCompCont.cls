/**************************************************
Type:       Test class for the ContactCaseHistoryChartComponentCont class
Purpose:    Tests if the chart data is created correctly
       
History:
--------------------------------------------------
23.01.2014  Mohamed.Atheek@bluewolf.com  Created          
28.07.2015  Eric.shen@auspost.com.au     Edit case record type                                     
**************************************************/

@isTest
private class TestContactCaseHistoryChartCompCont 
{

    static testMethod void testChartData() 
    {
        TestDataProvider.preventTrigger = true;
        Account acc = TestDataProvider.createAndSaveBusinessAccount('BusAcc', Constants.RECORDTYPE_NAME_ACCOUNT_BUSINESS_ACCOUNT);
        Contact cont = TestDataProvider.createAndSaveContact('test', acc.Id, Constants.RECORDTYPE_NAME_CONTACT_UNVERIFIED);
        Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();     //Eric Shen 28/07/15 Add record type for SSSW
        
        //Creating 2 open cases
        Case c1 = TestDataProvider.createCase('subject1', 'description', Constants.RECORDTYPE_NAME_CASE_SSSW_GENERAL);
         c1.recordtypeID = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId(); //Eric Shen 21/07/15 Add record type for SSSW
       c1.ContactId = cont.Id;
       c1.ResolutionCode__c = 'FCR';
        Case c2 = TestDataProvider.createCase('subject2', 'description', Constants.RECORDTYPE_NAME_CASE_SSSW_GENERAL);
         c2.recordtypeID = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId(); //Eric Shen 21/07/15 Add record type for SSSW
        c2.ContactId = cont.Id;
        c2.ResolutionCode__c = 'FCR';
        //Creating 3 closed cases
        Case c3 = TestDataProvider.createCase('subject3', 'description', Constants.RECORDTYPE_NAME_CASE_SSSW_GENERAL);
         c3.recordtypeID = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId(); //Eric Shen 21/07/15 Add record type for SSSW
        c3.ContactId = cont.Id;
        c3.Status = 'Closed';
        c3.ResolutionCode__c = 'FCR';
        Case c4 = TestDataProvider.createCase('subject4', 'description', Constants.RECORDTYPE_NAME_CASE_SSSW_GENERAL);
         c4.recordtypeID = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId(); //Eric Shen 21/07/15 Add record type for SSSW
        c4.ContactId = cont.Id;
        c4.Status = 'Closed';
        c4.ResolutionCode__c = 'FCR';
        Case c5 = TestDataProvider.createCase('subject5', 'description', Constants.RECORDTYPE_NAME_CASE_SSSW_GENERAL);
         c5.recordtypeID = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId(); //Eric Shen 21/07/15 Add record type for SSSW
        c5.ContactId = cont.Id;
        c5.Status = 'Closed';
        c5.ResolutionCode__c = 'FCR';
        insert new List<Case> {c1, c2, c3, c4, c5};
                
        Test.startTest();
        
        ContactCaseHistoryChartComponentCont contr = new ContactCaseHistoryChartComponentCont();
        contr.contId = cont.Id;
        
        System.assert(contr.openCaseChartData.indexOf(ChartMonths.getMonthName(System.today().month())) >= 0);//chart data should include the current month
        System.assert(contr.openCaseChartData.indexOf('2') >= 0);//chart data should include the 2 open cases we created
        
        System.assert(contr.closedCaseChartData.indexOf(ChartMonths.getMonthName(System.today().month())) >= 0);//chart data should include the current month
        System.assert(contr.closedCaseChartData.indexOf('3') >= 0);//chart data should include the 3 open cases we created
        
        Test.stopTest();
        TestDataProvider.preventTrigger = false;
    }
}