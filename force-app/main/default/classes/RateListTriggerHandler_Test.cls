/******************************************************************************************
    
    Author:         Lyndon Lavapie
    Date Created:   03/10/2016
    Description:    Handler for RateListTriggerHandler
    
    Change Log:
    Date:          Author:                  Description:
    03/10/2016     Lyndon Lavapie           Created
    01/06/2016     Andrew Judd (Salesforce.com)        Added setting of ByPassValidation, to allow Rate List to be activated without approval
    
*******************************************************************************************/
@isTest
private class RateListTriggerHandler_Test {
    private static final Id LPO_RECORD_TYPE = Schema.SObjectType.Rate_List__c.getRecordTypeInfosByName().get('LPO').getRecordTypeId();
    private static testMethod void testRateListDelete() {
        Rate_List__c rateList = new Rate_List__c   (
                                                    Name = 'Test Rate List',
                                                    Approval_Status__c = 'Approved',
                                                    status__c = 'Draft',
                                                    Licence_Type__c = 'LPO',
                                                    ByPassValidation__c = true
                                                   ); 
        insert rateList;
        rateList.status__c = 'Active';
        update rateList;
        
    Test.startTest();
        Boolean isDeleted = true;
        try{
            delete rateList;
        } catch (DmlException de) {
            isDeleted = false;
        }
        
        List<Rate_List__c> rateLists = New List<Rate_List__c>([Select Id From Rate_List__c]);
        system.debug(rateLists + '++ Rate List Record ++');
        System.assertNotEquals(0, rateLists.size());
        System.assertEquals(false, isDeleted);
    Test.stopTest();
    }
}