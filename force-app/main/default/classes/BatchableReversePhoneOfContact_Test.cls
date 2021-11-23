/**
*  This test class is for BatchableReversePhoneOfContact.
*
@author Yuanyuan Zhang
@created 2014-07-25
@version 1.0
@since 30.0
*
@changelog
* 2014-07-25 Yuanyuan Zhang <yuanyuan.zhang@bluewolf.com>
* - Created
* - Test coverage 100%
*/
@isTest
private class BatchableReversePhoneOfContact_Test {
    static testmethod void testBatch () {
        test.startTest();
        Database.BatchableContext BC;
        BatchableReversePhoneOfContact brp = new BatchableReversePhoneOfContact();
        brp.start(BC);
        Contact con = TestDataProvider.createContact();
        con.ReversePhoneFields__c = null;
        con.Phone = '12345';
        insert con;
        brp.execute(BC, new List<Sobject>{con});
        brp.finish(BC);
        test.stopTest();
    }
}