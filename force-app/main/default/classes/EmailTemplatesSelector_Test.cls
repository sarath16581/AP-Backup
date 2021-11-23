/**
* @author Seth Heang
* @date 2020-11-06
* @group Tests
* @tag Selector
* @tag EmailTemplate SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-12-18 - Seth Heang - Created
*/
@IsTest
private with sharing class EmailTemplatesSelector_Test {
    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    private static void testEnsureQueryBuilderProducesCorrectString() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        EmailTemplatesSelector selector = EmailTemplatesSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom EmailTemplate\\b').matcher(soql).find(), 'Resulting query does not select from opportunity product classification');

        Test.stopTest();

    }

    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();
		System.runAs(new User(Id=UserInfo.getUserId())) {
           EmailTemplate emailTemplate = ApplicationTestDataFactory.getVFEmailTemplate(1, 'Credit DSR Template' , 'Credit_DSR_Submission_to_queue', 'New Credit Management Request submitted :', 'htmlValue', 'body', 
            '<messaging:emailTemplate subject="New Credit Management Request submitted : {!relatedTo.Name}" recipientType="User" relatedToType="Deal_Support_Request__c">' +
         	'<messaging:htmlEmailBody > <p>Hello,</p> <p>A new support request has been submitted : {!relatedTo.Name} </p> <p>Request can be reviewed by following the below link:<br/>'+
            '<apex:outputlink value="{!LEFT($Api.Partner_Server_URL_140,FIND(\'.com\',$Api.Partner_Server_URL_140)+4)+relatedTo.Id}">{!relatedTo.Name}</apex:outputlink> '+
            '<br/>or by entering support request number in global search within Salesforce.</p><p>Regards <br/>Salesforce</p></messaging:htmlEmailBody></messaging:emailTemplate>',false)[0];
        	
    		insert emailTemplate;
            // =====================================
            // Stubbing
            // =====================================
            // None!
    
            // =====================================
            // Testing
            // =====================================
            Test.startTest();
            EmailTemplatesSelector selector = EmailTemplatesSelector.newInstance(1);
            Map<Id, EmailTemplate> results = selector.selectByDeveloperName('Credit_DSR_Submission_to_queue');
            System.assertEquals(1, results.size(), 'Expected result size of 1');
    
            Test.stopTest();
        }
    }

}