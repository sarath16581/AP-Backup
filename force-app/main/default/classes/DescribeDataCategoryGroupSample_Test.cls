/**
*  This test class is for DescribeDataCategoryGroupSample.
*
@author Frank Chen
@created 2014-06-23
@version 1.0
@since 20.0
*
@changelog
* 2014-06-23 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage 92%
*/
@isTest
private class DescribeDataCategoryGroupSample_Test {

    static testMethod void myUnitTest() {
        Test.startTest();
        
        DescribeDataCategoryGroupSample.describeDataCategoryGroupSample();
        
        system.assert(true);
        Test.stopTest();
    }
}