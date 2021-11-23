/**************************************************************************************
Description:    Test class to cover CustomerOnboardingViewContactStatusCtrl  functionality
History:
---------------------------------------------------------------------------------------
4/02/2018  Ramtej Juloori Created
***************************************************************************************/
@IsTest
public class CustomerOnboardingContactStatusCtrlTest {
    /*********************************************************************************
   *  Scenario:
   *      Setup method to create test data.
   **********************************************************************************/
    @testSetup
    static void setup() {
		
        // Custom Setting to get T and C name for Secure Post
        SecurePost__c securePostSettings = new SecurePost__c(CaseType__c = 'Customer Onboarding',
                Email_to_Case_address__c = 'test@auspost.com.au',
                ProductName__c = 'Secure Accept & Collect',
                TandCName__c = 'Secure Accept & Collect TandC');
        insert securePostSettings;
        
        //Fetch the record type.
        Id sourceRecordTypeId =
                Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.RECORDTYPE_NAME_CUSTOMER_ONBOARDING).getRecordTypeId();

        Id targetRecordTypeId =
                Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.RECORDTYPE_NAME_CUSTOMER_DATA_REQUEST).getRecordTypeId();

        Product2 tandc = new Product2(Name = 'TandC');
        insert tandc;

        Account bizAccount = TestDataProvider.createAndSaveBusinessAccount('Business Bob the builder',
                                                    Constants.RECORDTYPE_NAME_ACCOUNT_BUSINESS_ACCOUNT);

        Contact bizContact = TestDataProvider.createAndSaveContact('Bob Test', bizAccount.Id, Constants.RECORDTYPE_NAME_CONTACT_CONTACT );

        //MPBIZ Assets
        Asset mpbiz = TestDataProvider.createAndSaveAssets('MPBIZ', bizAccount.Id, Constants.RECORDTYPE_NAME_ASSET_GENERAL );
        Asset mpbtandc = TestDataProvider.createAssets('MYPSTTandC', bizAccount.Id, Constants.RECORDTYPE_NAME_ASSET_TANDC );
        mpbtandc.contactId = bizContact.Id;
        mpbtandc.ParentId = mpbiz.Id;
        mpbtandc.Product2Id = tandc.Id;
        insert mpbtandc;

        //SecurePost Assets
        Asset securePost = TestDataProvider.createAndSaveAssets(securePostSettings.ProductName__c, bizAccount.Id, Constants.RECORDTYPE_NAME_ASSET_GENERAL );
        Asset sptandc = TestDataProvider.createAssets(securePostSettings.TandCName__c, bizAccount.Id, Constants.RECORDTYPE_NAME_ASSET_TANDC );
        sptandc.contactId = bizContact.Id;
        sptandc.ParentId = sptandc.Id;
        sptandc.Product2Id = tandc.Id;
        insert sptandc;
        
        Asset sptandc1 = TestDataProvider.createAssets(securePostSettings.TandCName__c, bizAccount.Id, Constants.RECORDTYPE_NAME_ASSET_TANDC );
        sptandc1.contactId = bizContact.Id;
        sptandc1.ParentId = sptandc1.Id;
        sptandc1.Product2Id = tandc.Id;
        insert sptandc1;

        //Create Parent Cases 1 with child case and other without child case.
        List<Case> parentCaseList = new List<Case>();
        Case parentCase1 = new Case(Subject = 'Subject for inserting Customer Onboarding Case',
                Description = 'Description for inserting Customer Onboarding Case', RecordTypeId= sourceRecordTypeId,
                ReferenceID__c = '1234597');
        Case parentCase2 = new Case(Subject = 'Subject for inserting Customer Onboarding Case',
                Description = 'Description for inserting Customer Onboarding Case', RecordTypeId= sourceRecordTypeId,
                ReferenceID__c = '1234597');
        parentCaseList.add(parentCase1);
        parentCaseList.add(parentCase2);
        insert parentCaseList;
        //Create Child Case of type Customer Data Request and link to Legal Entity to be available in view
        Case childCase = new Case(Subject = 'Subject for inserting Customer Onboarding Case',
                Description = 'Description for inserting Customer Onboarding Case', RecordTypeId= targetRecordTypeId,
                ReferenceID__c = '1234597', AccountId = bizAccount.Id, ParentId = parentCaseList[0].Id);

        insert childCase;
        
    }

    /*********************************************************************************
    *  Scenario:
    *      Test Case Status from Child Case
    **********************************************************************************/
    static testMethod void testCaseStatus() {
        //Retrieve the parent case Id.
        List<Case> cases = [SELECT Id, RecordTypeId, RecordType.Name, parent.ownerid, ownerId,
                ContactId, Description, Subject, CaseNumber, AccountId FROM Case WHERE Parent.Id = null];
        List<Asset> assets = [SELECT Id, Name, RecordTypeId, RecordType.Name,
                ContactId, AccountId, Product2.Name FROM Asset LIMIT 1];
        ApexPages.StandardSetController controller = new ApexPages.StandardSetController(cases);
        controller.setSelected(cases);
        CustomerOnboardingViewContactStatusCtrl extension = new CustomerOnboardingViewContactStatusCtrl(controller);
        extension.selectedCases();
        List<String> caseIds = new List<String>();
        for(Case cs : cases)
        {
            caseIds.add(cs.Id);
        }
        List<CustomerOnboardingViewContactStatusCtrl.parentCaseMappingWithContactDetails> expectedWrapper = CustomerOnboardingViewContactStatusCtrl.getContacts(caseIds);    
        List<String> expected = CustomerOnboardingViewContactStatusCtrl.getCaseIds();
        System.assertEquals(expected.size(), 2);
        System.assertEquals(expectedWrapper.size(), 1);
        System.assertEquals(expectedWrapper[0].ContactDetailsWrapper.size(), 1);
    }
}