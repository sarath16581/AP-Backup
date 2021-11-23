/* @author Nathan Franklin
 * @date 2020-08-09
 * @group Tests
 * @tag Selector
 * @tag ApexPageMessage
 * @domain Core
 * @description Test Class covering ApexPageMessagesSelector
 * @changelog
 * 2020-08-14 - arjun.singh@austpost.com.au - Created
 */
@IsTest
public with sharing class ApexPageMessagesSelector_Test {    
    @IsTest
    public static void getPageMessagesTest() {
        Test.startTest();
        ApexPageMessagesSelector selector = ApexPageMessagesSelector.newInstance();
        selector.getSObjectType();
        selector.getSObjectFieldList();
        List<Apexpages.Message> msg = selector.getPageMessages();
        Test.stopTest();
        System.assert(msg != null);
    }
}