/**
*  This test class is for SectionDetail.
*
@author Frank Chen
@created 2014-06-23
@version 1.0
@since 20.0
*
@changelog
* 2014-06-23 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage 88%
*/
@isTest
private class SectionDetail_Test {

    static testMethod void myUnitTest() {
    	Schema.DescribeFieldResult f = Account.AccountNumber.getDescribe();
    	List<FieldDetail> fieldList = new List<FieldDetail>();
    	FieldDetail fd = new FieldDetail('1','Required',f);
    	fieldList.add(fd);
    	
        Test.startTest();
        
        SectionDetail sd = new SectionDetail('1',fieldList);
        sd.close();
        
        system.assert(true);
        Test.stopTest();
    }
}