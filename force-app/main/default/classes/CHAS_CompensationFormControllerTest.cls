/**
 * @author Phap Mai
 * @date October 2021
 * @description: unit test for CHAS_CompensationFormController
 * @changelog
 * October 2021 - Phap Mai - Init
 */
@isTest
private with sharing class CHAS_CompensationFormControllerTest
{
    @TestSetup
    private static void setUpCampFire()
    {
        // setting
        Consumer_Help_and_Support__c hs = new Consumer_Help_and_Support__c();
        hs.Encoded_Crypto_Key__c = 'testcryptokey/testcryptokey/testcryptokey/+=';
        hs.Compensation_Max_Attemps__c = 5;
        insert hs;
        
        // account
        Account a = TestDataProvider.createAccount('Account', 1)[0];
        insert a;

        // contact
        Contact c = TestDataProvider.createContact('Contact', a.Id, null);
        insert c;

        // case
        Case iCase = TestDataProvider.createCase('subject', 'description', null);
        iCase.ContactId = c.Id;
        insert iCase;

        // EFT record type
        RecordType rc = [SELECT Id FROM RecordType WHERE DeveloperName = 'EFT' AND SobjectType = 'Compensation__c'];

        // compensation
        Compensation__c compensation = new Compensation__c();
        compensation.Contact__c = c.Id;
        compensation.RecordTypeId = rc.Id;
        compensation.Case__c = iCase.Id;
        compensation.Compensation_Amount__c = 50;
        compensation.Cover_Type__c = 'T&C Cover	';
        compensation.Bank_Detail_Provided_By_Customer__c = true;
        insert compensation;

        // set the status to Approved Awaiting Customer
        compensation = [SELECT Status__c, Bank_Detail_Provided_By_Customer__c, Compensation_Form_Token__c FROM Compensation__c WHERE Id = :compensation.Id];
        compensation.Compensation_Form_Token__c = null;
        update compensation;
    }

    /**
     * scenario: populate encoded token to compensation record
     * expected: a new token is updated to record
     */
    @isTest
    private static void updateToken_HappyPath_Encode()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];

        System.assert(String.isEmpty(compensation.Compensation_Form_Token__c), 'updateToken_HappyPath_Encode failed: initial token is not empty');

        Test.startTest();
        CHAS_CompensationFormController.updateToken(compensation.Id, true, false, false);
        Test.stopTest();

        compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];

        System.assert(String.isNotEmpty(compensation.Compensation_Form_Token__c), 'updateToken_HappyPath_Encode failed: generated token is empty');
    }

    /**
     * scenario: populate token to compensation record
     * expected: a new token is updated to record
     */
    @isTest
    private static void updateToken_HappyPath_No_Encode()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];

        System.assert(String.isEmpty(compensation.Compensation_Form_Token__c), 'updateToken_HappyPath_No_Encode failed: initial token is not empty');

        Test.startTest();
        CHAS_CompensationFormController.updateToken(compensation.Id, false, false, false);
        Test.stopTest();

        compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];

        System.assert(String.isNotEmpty(compensation.Compensation_Form_Token__c), 'updateToken_HappyPath_No_Encode failed: generated token is empty');
    }

    /**
     * scenario: update token to an invalid record Id
     * expected: controller throw an exception
     */
    @isTest
    private static void updateToken_Invalid_RecordId()
    {
        Test.startTest();
        try {
            CHAS_CompensationFormController.updateToken(null, true, false, false);
        } catch (Exception e)
        {
            System.assert(String.isNotEmpty(e.getMessage()), 'updateToken_Invalid_RecordId failed: no exception message');
        }
        Test.stopTest();
    }

    /**
     * scenario: update token to compensation record and send compensation email
     * expected: compensation email sent out
     */
    @isTest
    private static void sendCompensationEmail_HappyPath()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];
        Test.startTest();
        CHAS_CompensationFormController.updateToken(compensation.Id, true, true, true);
        System.assertEquals(1, System.Limits.getEmailInvocations(), 'sendCompensationEmail_HappyPath failed: no email sent');
        Test.stopTest();
    }

    /**
     * scenario: update token to compensation record and send compensation email for invalid record Id
     * expected: controller throw an exception
     */
    @isTest
    private static void sendCompensationEmail_Invalid_RecordId()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];

        Test.startTest();
        try
        {
            CHAS_CompensationFormController.updateToken(null, true, true, true);
        } catch (Exception e)
        {
            System.assert(String.isNotEmpty(e.getMessage()), 'sendCompensationEmail_Invalid_RecordId failed: no exception message');
        }
        Test.stopTest();
    }

    /**
     * scenario: update token to compensation record and send compensation email. The compensation's case is not linked to a contact
     * expected: controller throw an exception
     */
    @isTest
    private static void sendCompensationEmail_Case_No_Contact()
    {
        Case c = [SELECT ContactId FROM Case];
        c.ContactId = null;
        update c;

        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];

        Test.startTest();
        try
        {
            CHAS_CompensationFormController.updateToken(compensation.Id, true, true, true);
        } catch (Exception e)
        {
            System.assert(String.isNotEmpty(e.getMessage()), 'sendCompensationEmail_Case_No_Contact failed: no exception message');
        }
        Test.stopTest();
    }

    /**
     * scenario: update token to compensation record and send compensation email. The compensation's contact do not have email
     * expected: controller throw an exception
     */
    @isTest
    private static void sendCompensationEmail_Contact_No_Email()
    {
        Contact c = [SELECT Email FROM Contact];
        c.Email = null;
        update c;

        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];

        Test.startTest();
        try
        {
            CHAS_CompensationFormController.updateToken(compensation.Id, true, true, true);
        } catch (Exception e)
        {
            System.assert(String.isNotEmpty(e.getMessage()), 'sendCompensationEmail_Contact_No_Email failed: no exception message');
        }
        Test.stopTest();
    }

    /**
     * scenario: get compensation record with a valid token
     * expected: the record with correct token is returned
     */
    @isTest
    private static void getCompensationByToken_HappyPath()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];
        CHAS_CompensationFormController.updateToken(compensation.Id, true, false, false);
        compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];

        // decode token to mimic the behaviour of web browser when pass token down to back end
        String decodedToken = EncodingUtil.urlDecode(compensation.Compensation_Form_Token__c, 'UTF-8');

        Test.startTest();
        CHAS_CompensationFormController.CompensationPackage result = CHAS_CompensationFormController.getCompensationByToken(decodedToken);
        Test.stopTest();

        System.assertEquals(compensation.Id, result.compensation.Id, 'getCompensationByToken_HappyPath failed. Expected Id: ' + compensation.Id + '. Actual Id: ' + result.compensation.Id);
    }

    /**
     * scenario: get compensation record with an invalid token
     * expected: controller throw an exception
     */
    @isTest
    private static void getCompensationByToken_Invalid_Token()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];
        CHAS_CompensationFormController.updateToken(compensation.Id, true, false, false);

        Test.startTest();
        try
        {
            CHAS_CompensationFormController.getCompensationByToken('token');
        }
        catch (Exception e)
        {
            System.assert(String.isNotEmpty(e.getMessage()), 'getCompensationByToken_Invalid_Token failed: no exception message');
        }
        Test.stopTest();
    }

    /**
     * scenario: get compensation record with a valid token but record have invalid record type
     * expected: controller throw an exception
     */
    @isTest
    private static void getCompensationByToken_Invalid_RecordType()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];
        CHAS_CompensationFormController.updateToken(compensation.Id, true, false, false);
        compensation = [SELECT Id, Compensation_Form_Token__c FROM Compensation__c];
        String decodedToken = EncodingUtil.urlDecode(compensation.Compensation_Form_Token__c, 'UTF-8');

        RecordType rc = [SELECT Id FROM RecordType WHERE DeveloperName = 'Retail_Compensation' AND SobjectType = 'Compensation__c'];
        compensation.RecordTypeId = rc.Id;
        update compensation;

        Test.startTest();
        try
        {
            CHAS_CompensationFormController.getCompensationByToken(decodedToken);
        }
        catch (Exception e)
        {
            System.assert(String.isNotEmpty(e.getMessage()), 'getCompensationByToken_Invalid_RecordType failed: no exception message');
        }
        Test.stopTest();
    }

    /**
     * scenario: get compensation record with a valid token but record is out of attempts
     * expected: controller throw an exception
     */
    @isTest
    private static void getCompensationByToken_Invalid_OutOfAttemps()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c, Compensation_Form_Attemps__c FROM Compensation__c];
        CHAS_CompensationFormController.updateToken(compensation.Id, true, false, false);
        compensation = [SELECT Id, Compensation_Form_Token__c, Compensation_Form_Attemps__c, Status__c FROM Compensation__c];
        String decodedToken = EncodingUtil.urlDecode(compensation.Compensation_Form_Token__c, 'UTF-8');
        compensation.COmpensation_Form_Attemps__c = 6;
        update compensation;

        Test.startTest();
        try
        {
            CHAS_CompensationFormController.getCompensationByToken(decodedToken);
        }
        catch (Exception e)
        {
            System.assert(String.isNotEmpty(e.getMessage()), 'getCompensationByToken_Invalid_OutOfAttemps failed: no exception message');
        }
        Test.stopTest();
    }

    /**
     * scenario: get compensation record with a valid token but record is not in open status
     * expected: controller throw an exception
     */
    @isTest
    private static void getCompensationByToken_Invalid_NotOpen()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Token__c, Compensation_Form_Attemps__c, Status__c FROM Compensation__c];
        CHAS_CompensationFormController.updateToken(compensation.Id, true, false, false);
        compensation = [SELECT Id, Compensation_Form_Token__c, Compensation_Form_Attemps__c, Status__c FROM Compensation__c];
        String decodedToken = EncodingUtil.urlDecode(compensation.Compensation_Form_Token__c, 'UTF-8');
        compensation.Status__c = 'Pending';
        update compensation;

        Test.startTest();
        try
        {
            CHAS_CompensationFormController.getCompensationByToken(decodedToken);
        }
        catch (Exception e)
        {
            System.assert(String.isNotEmpty(e.getMessage()), 'getCompensationByToken_Invalid_NotOpen failed: no exception message');
        }
        Test.stopTest();
    }

    /**
     * scenario: increase attempts counter in compensation record
     * expected: counter increase by 1
     */
    @isTest
    private static void increaseAttempsCounter_HappyPath()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Attemps__c FROM Compensation__c];
        
        System.assertEquals(0, compensation.Compensation_Form_Attemps__c, 'increaseAttempsCounter_HappyPath failed: initial attemp is not zero');

        Test.startTest();
        CHAS_CompensationFormController.increaseAttempsCounter(compensation.Id);
        Test.stopTest();

        compensation = [SELECT Id, Compensation_Form_Attemps__c FROM Compensation__c];

        System.assertEquals(1, compensation.Compensation_Form_Attemps__c, 'increaseAttempsCounter_HappyPath failed: attemp is not updated');
    }

    /**
     * scenario: increase attempts counter in compensation record. The updated attempts hit maximum. A case comment will be created on this.
     * expected: a case comment created.
     */
    @isTest
    private static void increaseAttempsCounter_CreateCaseComment()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Attemps__c FROM Compensation__c];
        compensation.Compensation_Form_Attemps__c = 5;
        update compensation;
        
        System.assertEquals(5, compensation.Compensation_Form_Attemps__c, 'increaseAttempsCounter_CreateCaseComment failed: initial attemps not equal max attemps');

        Test.startTest();
        CHAS_CompensationFormController.increaseAttempsCounter(compensation.Id);
        Test.stopTest();

        compensation = [SELECT Id, Compensation_Form_Attemps__c FROM Compensation__c];

        List<CaseComment> comments = [SELECT Id FROM CaseComment];
        System.assert(comments.size() > 0, 'increaseAttempsCounter_CreateCaseComment failed: no case comment created');
    }

    /**
     * scenario: get metadata for thank you page
     * expected: a list of metadata is returned
     */
    @isTest
    private static void getNextStepsMetadata_HappyPath()
    {
        Test.startTest();
        List<CHAS_ThankYouPageNextSteps__mdt> mtds = CHAS_CompensationFormController.getNextStepsMetadata('nextStepsCompensation');
        test.stopTest();
        System.assert(mtds.size() > 0, 'getNextStepsMetadata_HappyPath failed: no next step metadata retrieved');
    }

    /**
     * scenario: update bank details to compensation record
     * expected: bank details successfully updated
     */
    @isTest
    private static void updateBankDetails_HappyPath()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Attemps__c, Account_Name__c, Account_Number__c, BSB__c FROM Compensation__c];

        System.assert(compensation.Account_Name__c == null, 'updateBankDetails_HappyPath failed: initial account name is not blank');
        System.assert(compensation.Account_Number__c == null, 'updateBankDetails_HappyPath failed: initial account number is not blank');
        System.assert(compensation.BSB__c == null, 'updateBankDetails_HappyPath failed: initial BSB is not blank');

        User siteGuestUser = [SELECT Id FROM User WHERE CommunityNickname = 'Consumer_Help_and_Support'];

        Test.startTest();
        System.runAs(siteGuestUser)
        {
            CHAS_CompensationFormController.updateBankDetails(compensation.Id, 'Account Name', '123456', '456789');
        }
        Test.stopTest();

        compensation = [SELECT Id, Compensation_Form_Attemps__c, Account_Name__c, Account_Number__c, BSB__c FROM Compensation__c];

        System.assertEquals('Account Name', compensation.Account_Name__c, 'updateBankDetails_HappyPath failed: account name is not updated');
        System.assertEquals('123456', compensation.BSB__c, 'updateBankDetails_HappyPath failed: account number is not updated');
        System.assertEquals('456789', compensation.Account_Number__c, 'updateBankDetails_HappyPath failed: BSB is not updated');
    }

    /**
     * scenario: update bank details to compensation record
     * expected: bank details successfully updated
     */
    @isTest
    private static void updateBankDetails_ErrorHandle()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Attemps__c, Account_Name__c, Account_Number__c, BSB__c FROM Compensation__c];

        System.assert(compensation.Account_Name__c == null, 'updateBankDetails_ErrorHandle failed: initial account name is not blank');
        System.assert(compensation.Account_Number__c == null, 'updateBankDetails_ErrorHandle failed: initial account number is not blank');
        System.assert(compensation.BSB__c == null, 'updateBankDetails_ErrorHandle failed: initial BSB is not blank');

        Test.startTest();
        try {
            CHAS_CompensationFormController.updateBankDetails(compensation.Id, 'Account Name', '123456789010', '456789');
        }
        catch (Exception e)
        {
            System.assert(String.isNotEmpty(e.getMessage()), 'updateBankDetails_ErrorHandle failed: no exception message');
        }
        Test.stopTest();
    }

    /**
     * scenario: create a case comment after compensation email has been sent
     * expected: a case comment is created
     */
    @isTest
    private static void createCaseCommentAboutEmailSent()
    {
        Compensation__c compensation = [SELECT Id, Compensation_Form_Attemps__c, Account_Name__c, Account_Number__c, BSB__c, Name, Case__c FROM Compensation__c];
        
        Test.startTest();
        CHAS_CompensationFormController.createCaseCommentAboutEmailSent(new List<Compensation__c> {compensation});
        List<CaseComment> comments = [SELECT CommentBody, ParentId FROM CaseComment WHERE ParentId = :compensation.Case__c];
        System.assert(comments.size() > 0, 'createCaseCommentAboutEmailSent failed: no comment created');
        System.assert(comments[0].CommentBody.contains('Compensation email has been sent to customer'), 'createCaseCommentAboutEmailSent failed: comment content is not correct');
        Test.stopTest();
    }
}