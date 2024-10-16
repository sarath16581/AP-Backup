/**
 * Test class for MiniCaseComponentController
 *
 * @author
 * @date
 * @changelog
 * 2014-06-23 Frank Chen <di.chen@bluewolf.com> Test coverage
 * 2017-09-23 nathan.franklin@auspost.com.au Wrote actual scenario tests to cover class
 * 2020-10-05 disha.kariya@auspost.com.au Added safe drop attachment test
 * 2021-09-09 seth.heang@auspost.com.au Uplift SF API version to 52
 * 2021-10-10 - Nathan Franklin - Removed safe drop queueable test methods, moved to DeliveryProofService_Test
 * 2024-10-08 - George Nguyen - include Unified cases in the search result
 */
@isTest
public class MiniCaseComponentController_Test {

    /***
     * Ensures that the existing case variable is populated when a case that matches the reference id exists.
     */
    public static testMethod void testExistingCases() {
        Account acc = new Account(FirstName = 'test acc', LastName = 'test acc', Phone = '718273672', Email__c = 'test@test.com', 
                                  MailingAddress__pc = 'add', PersonEmail = 'test@test.com');
        insert acc;
        
        Article__c art = new Article__c();
        art.Name = '123';
        art.TrackingID__c = '123';
        art.ExpectedDeliveryDate__c = date.today();
        art.ArticleLodgementDate__c = date.today();
        art.SenderPostcode__c = '123';
        art.ReceiverPostcode__c = '3002';
        art.ArticleType__c = 'Regular Parcel';
        art.ReceiverName__c = '123';
        art.ReceiverEmail__c = 'dsf@163.com';
        art.ArticleLodgementDate__c = date.today();
        art.ProductCategory__c = 'eParcel';
        art.ArticleTransitAmountValue__c = 1;
        art.SubProduct__c = 'eParcel Standard';
        art.ActualWeight__c = 2;
        art.DeliveryInstructions__c = '99bb';
        insert art;
        
        Contact con = TestDataProvider.createTestContact();
        insert con;
        
        Case case1 = new Case();
        case1.RecordTypeId = [select Id from RecordType where SObjectType = 'Case' and DeveloperName = 'SSSWGeneralEnquiry' limit 1].Id;
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'New';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.ContactId = con.Id;
        case1.ReferenceID__c = '123';
        insert case1;

		Case case2 = new Case();
        case2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(SSSWConstants.UNIFIED_GENERAL_ENQUIRY_DEVELOPER_NAME).getRecordTypeId();
        case2.Type = 'Feedback';
        case2.Subject = 'Newsdd';
        case2.Status = 'New';
        case2.ProductCategory__c = 'Travel & ID';
        case2.EnquirySubType__c = 'Product Support';
        case2.ProductSubCategory__c = 'KeyPass';
        case2.ContactId = con.Id;
        case2.ReferenceID__c = '123';
        insert case2;
        
        Test.startTest();

        MiniCaseComponentController mini = new MiniCaseComponentController();

        String sapEMSearchTriggers = mini.sapEMSearchTriggers;
        String eddTriggers = mini.eddTriggers;
        AusPostSettings__c settings = mini.trackingSettings;
        mini.contactId = String.valueOf(con.Id);

        mini.proxyCase.ReferenceID__c = '123';
        mini.loadRelatedCases();
        System.assertEquals(2, mini.existingCaseOrActivities.size());

        Test.stopTest();
    }

    /***
     * Ensures a case can be created
     */
    public static testMethod void testCaseCreation() {
        Account acc = new Account(FirstName = 'test acc', LastName = 'test acc', Phone = '718273672', Email__c = 'test@test.com',
            MailingAddress__pc = 'add', PersonEmail = 'test@test.com');
        insert acc;

        Contact con = TestDataProvider.createTestContact();
        insert con;

        Article__c art = new Article__c();
        art.Name = '123';
        art.TrackingID__c = '123';
        art.ExpectedDeliveryDate__c = date.today();
        art.ArticleLodgementDate__c = date.today();
        art.SenderPostcode__c = '123';
        art.ReceiverPostcode__c = '3002';
        art.ArticleType__c = 'Regular Parcel';
        art.ReceiverName__c = '123';
        art.ReceiverEmail__c = 'dsf@163.com';
        art.ArticleLodgementDate__c = date.today();
        art.ProductCategory__c = 'eParcel';
        art.ArticleTransitAmountValue__c = 1;
        art.SubProduct__c = 'eParcel Standard';
        art.ActualWeight__c = 2;
        art.DeliveryInstructions__c = '99bb';
        insert art;

        Test.startTest();

        String caseJson = '{"Phone__c":"718273672","Subject":"test subject","Type":"Fax","ReferenceID__c":"123","DatePosted__c":"2014-07-09","ContactId":"'+ con.Id +'"}';
        String result1 = MiniCaseComponentController.createCase('',caseJson, true, '["123"]', false, '[]');
        Case c = [Select Id From Case];
        System.assertEquals(String.valueOf(c.Id), result1);

        String result2 = MiniCaseComponentController.createCase('',caseJson, false, '["123"]', false,'[]');
        c = [Select Id From Case Where Id != :c.Id];
        System.assertEquals(String.valueOf(c.Id), result2);

        Test.stopTest();
    }

    /***
     * Ensures multiple cases can be created.. although I'm sure of the application
     */
    public static testMethod void testMultipleCaseCreation() {
        Account acc = new Account(FirstName = 'test acc', LastName = 'test acc', Phone = '718273672', Email__c = 'test@test.com',
            MailingAddress__pc = 'add', PersonEmail = 'test@test.com');
        insert acc;

        Contact con = TestDataProvider.createTestContact();
        insert con;

        Article__c art = new Article__c();
        art.Name = '123';
        art.TrackingID__c = '123';
        art.ExpectedDeliveryDate__c = date.today();
        art.ArticleLodgementDate__c = date.today();
        art.SenderPostcode__c = '123';
        art.ReceiverPostcode__c = '3002';
        art.ArticleType__c = 'Regular Parcel';
        art.ReceiverName__c = '123';
        art.ReceiverEmail__c = 'dsf@163.com';
        art.ArticleLodgementDate__c = date.today();
        art.ProductCategory__c = 'eParcel';
        art.ArticleTransitAmountValue__c = 1;
        art.SubProduct__c = 'eParcel Standard';
        art.ActualWeight__c = 2;
        art.DeliveryInstructions__c = '99bb';
        insert art;

        art = new Article__c();
        art.Name = '456';
        art.TrackingID__c = '456';
        art.ExpectedDeliveryDate__c = date.today();
        art.ArticleLodgementDate__c = date.today();
        art.SenderPostcode__c = '123';
        art.ReceiverPostcode__c = '3002';
        art.ArticleType__c = 'Regular Parcel';
        art.ReceiverName__c = '123';
        art.ReceiverEmail__c = 'dsf@163.com';
        art.ArticleLodgementDate__c = date.today();
        art.ProductCategory__c = 'eParcel';
        art.ArticleTransitAmountValue__c = 1;
        art.SubProduct__c = 'eParcel Standard';
        art.ActualWeight__c = 2;
        art.DeliveryInstructions__c = '99bb';
        insert art;

        Test.startTest();

        String caseJson = '{"Phone__c":"718273672","Subject":"test subject","Type":"Fax","ReferenceID__c":"123","DatePosted__c":"2014-07-09","ContactId":"'+ con.Id +'"}';

        MiniCaseComponentController.createCase('',caseJson, false, '["123", "456"]', false, '[]');
        Integer caseCount = [Select COUNT() From Case];
        System.assertEquals(3, caseCount);

        Test.stopTest();
    }

    /***
     * Ensures a case can be created
     */
    @IsTest
    private static void testDuplicateCaseCreationIsIgnoreWhenClosedCaseExists() {
        Account acc = new Account(FirstName = 'test acc', LastName = 'test acc', Phone = '718273672', Email__c = 'test@test.com',
            MailingAddress__pc = 'add', PersonEmail = 'test@test.com');
        insert acc;

        Contact con = TestDataProvider.createTestContact();
        insert con;

        Article__c art = new Article__c();
        art.Name = '123';
        art.TrackingID__c = '123';
        art.ExpectedDeliveryDate__c = date.today();
        art.ArticleLodgementDate__c = date.today();
        art.SenderPostcode__c = '123';
        art.ReceiverPostcode__c = '3002';
        art.ArticleType__c = 'Regular Parcel';
        art.ReceiverName__c = '123';
        art.ReceiverEmail__c = 'dsf@163.com';
        art.ArticleLodgementDate__c = date.today();
        art.ProductCategory__c = 'eParcel';
        art.ArticleTransitAmountValue__c = 1;
        art.SubProduct__c = 'eParcel Standard';
        art.ActualWeight__c = 2;
        art.DeliveryInstructions__c = '99bb';
        insert art;

        Test.startTest();

        String caseJson = '{"Phone__c":"718273672","Subject":"test subject","Type":"Fax","ReferenceID__c":"123","DatePosted__c":"2014-07-09","ContactId":"'+ con.Id +'"}';
        String result1 = MiniCaseComponentController.createCase('',caseJson, true, '["123"]', false, '[]');
        Case c = [Select Id From Case];
        System.assertEquals(String.valueOf(c.Id), result1);

        String result2 = MiniCaseComponentController.createCase('',caseJson, false, '["123"]', false, '[]');
        c = [Select Id From Case Where Id != :c.Id];
        System.assertEquals(String.valueOf(c.Id), result2);

        Test.stopTest();
    }

    /***
     * Ensures multiple cases can be created.. although I'm sure of the application
     */
    public static testMethod void testMultipleCaseCreationDuplicates() {
        Account acc = new Account(FirstName = 'test acc', LastName = 'test acc', Phone = '718273672', Email__c = 'test@test.com',
            MailingAddress__pc = 'add', PersonEmail = 'test@test.com');
        insert acc;

        Contact con = TestDataProvider.createTestContact();
        insert con;

        Article__c art = new Article__c();
        art.Name = '123';
        art.TrackingID__c = '123';
        art.ExpectedDeliveryDate__c = date.today();
        art.ArticleLodgementDate__c = date.today();
        art.SenderPostcode__c = '123';
        art.ReceiverPostcode__c = '3002';
        art.ArticleType__c = 'Regular Parcel';
        art.ReceiverName__c = '123';
        art.ReceiverEmail__c = 'dsf@163.com';
        art.ArticleLodgementDate__c = date.today();
        art.ProductCategory__c = 'eParcel';
        art.ArticleTransitAmountValue__c = 1;
        art.SubProduct__c = 'eParcel Standard';
        art.ActualWeight__c = 2;
        art.DeliveryInstructions__c = '99bb';
        insert art;

        art = new Article__c();
        art.Name = '456';
        art.TrackingID__c = '456';
        art.ExpectedDeliveryDate__c = date.today();
        art.ArticleLodgementDate__c = date.today();
        art.SenderPostcode__c = '123';
        art.ReceiverPostcode__c = '3002';
        art.ArticleType__c = 'Regular Parcel';
        art.ReceiverName__c = '123';
        art.ReceiverEmail__c = 'dsf@163.com';
        art.ArticleLodgementDate__c = date.today();
        art.ProductCategory__c = 'eParcel';
        art.ArticleTransitAmountValue__c = 1;
        art.SubProduct__c = 'eParcel Standard';
        art.ActualWeight__c = 2;
        art.DeliveryInstructions__c = '99bb';
        insert art;

        Test.startTest();

        String caseJson = '{"Phone__c":"718273672","Subject":"test subject","Type":"Fax","ReferenceID__c":"123","DatePosted__c":"2014-07-09","ContactId":"'+ con.Id +'"}';

        MiniCaseComponentController.createCase('',caseJson, false, '["123", "456"]', true, '["123"]');
        Integer caseCount = [Select COUNT() From Case];
        System.assertEquals(3, caseCount);

        Test.stopTest();
    }

}