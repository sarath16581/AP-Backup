/**************************************************************************
Description:    Test class to cover CaseMassUpload Controller functionality
History:
--------------------------------------------------
2014-06-24  di.chen@bluewolf.com  Created
2018-05-31  TDO-14 rahul.kapoor@coroma.com.au Refactored comments and indentation,
            added tests for with/without CSV blob, success/error PageMessages.
***************************************************************************/
@isTest
private class CaseMassUploadCont_Test {

    @testSetup
    static void setupTestData() {
        //create a test account to support user creation
        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        insert testAccount;

        // create an account to support user creation
        Contact newCon = new Contact(
                FirstName = 'Rahul',
                LastName = 'Kapoor',
                MobilePhone = '0400000000',
                Email = 'rahul.kapoor@coroma.com.au',
                AccountId = testAccount.Id,
                Contact_Type__c = StarTrack_Constants.CONTACT_TYPE,
                Status__c = StarTrack_Constants.CON_STAT_ACTIVE
        );
        insert newCon;
        // pull a profile for the user
        Profile profile = [
                SELECT Id
                FROM Profile
                WHERE Name = 'BSP Community User'
        ];

        // create a user for run as tests
        User user = new User(
                Email='rahul.kapoor@coroma.com.au',
                ContactId = newCon.Id,
                EmailEncodingKey='UTF-8',
                LastName='Testing',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                ProfileId = profile.Id,
                TimeZoneSidKey='America/Los_Angeles',
                UserName='rkccoau1@testorg.com',
                Alias = 'rkccoau'
        );

		insert user;
        //caseMassUploadManager cls line 59 doesn't handle the null values [Id.valueOf(bsp.CCUCommunityUserProfileId__c)]
        //TDO_TODO: corrections: update caseMassUploadManager to handle null
        CCUSettings__c setting = new CCUSettings__c(CCUCommunityUserProfileId__c = UserInfo.getProfileId());
        insert setting;
    }

    /*****************************************************************************************
    *  Scenario:
    *      Cases are mass uploaded from CaseMassUpload page using a CSV file.
    *      Legal Entity Name, Contact Name, Type, Case Owner and CSV File are the input fields.
    ******************************************************************************************/
    @isTest
    static void uploadOfMassCasesWithCSV() {

        Test.startTest();

        CaseMassUploadCont caseMassUploadCont = new CaseMassUploadCont();
        caseMassUploadCont.proxyCase.OwnerId = UserInfo.getUserId();
        String csvFile = 'type,subject,Reason\n';
        csvFile += 'Fax,s1,r1\n';

        caseMassUploadCont.csvBlob = Blob.valueOf(csvFile);
        caseMassUploadCont.upload();

        Test.stopTest();

        Integer caseCount = [Select COUNT() From Case];

        System.assertEquals(1,caseCount,
                'CaseMassUploadContTest_uploadOfMassCasesWithCSV : Cases are mass uploaded from CaseMassUpload page using a CSV file.'
        );

    }

    /*****************************************************************************************
    *  Scenario:
    *      Cases are not uploaded without CSV file.
    *      Legal Entity Name, Contact Name, Type, Case Owner and CSV File are the input fields.
    ******************************************************************************************/
    @isTest
    static void uploadOfMassCasesWithoutCSV() {

        Test.startTest();

        CaseMassUploadCont caseMassUploadCont = new CaseMassUploadCont();
        caseMassUploadCont.proxyCase.OwnerId = UserInfo.getUserId();
        caseMassUploadCont.upload();

        Test.stopTest();

        Integer caseCount = [SELECT COUNT() FROM Case];
        System.assertEquals(0,caseCount,
                'CaseMassUploadContTest_uploadOfMassCasesWithoutCSV : Cases are not uploaded without CSV file.');
    }

    /**********************************************************************
     *  Scenario:
     *      Checking the case created message when cases are mass uploaded.
     **********************************************************************/
    @isTest
    static void casesCreatedPageMessage() {

        Test.startTest();

        CaseMassUploadCont caseMassUploadCont = new CaseMassUploadCont();
        caseMassUploadCont.proxyCase.OwnerId = UserInfo.getUserId();
        String csvFile = 'type,subject,Reason\n';
        csvFile += 'Fax,s1,r1\n';

        caseMassUploadCont.csvBlob = Blob.valueOf(csvFile);
        caseMassUploadCont.upload();

        Test.stopTest();

        //Check that the expected message is in pageMessages.
        ApexPages.Message[] pageMessages = ApexPages.getMessages();

        System.assertNotEquals(0,pageMessages.size(),
                'CaseMassUploadContTest_casesCreatedPageMessage : pageMessages size is zero');

        Boolean messageFound = false;
        //Loop through the pageMessages.
        for(ApexPages.Message message : pageMessages) {
            //Check if the Case Created message is present.
            String msg = message.getSummary();
            if(msg.contains('Cases Created')) {
                messageFound = true;
            }
        }

        System.assertEquals(true,messageFound,
                'CaseMassUploadContTest_casesCreatedPageMessage : Case created message displayed when cases are mass uploaded.');
    }

    /************************************************************
     *  Scenario:
     *      Checking for the case is assigned to the correct user
     ************************************************************/
    @isTest
    static void forPortalUser() {
        User user = [SELECT id FROM User WHERE UserName='rkccoau1@testorg.com' LIMIT 1];

        System.runAs(user) {
            Test.startTest();
            CaseMassUploadCont caseMassUploadCont = new CaseMassUploadCont();
            caseMassUploadCont.proxyCase.OwnerId = UserInfo.getUserId();
            String csvFile = 'type,subject,Reason\n';
            csvFile += 'Fax,s1,r1\n';

            caseMassUploadCont.csvBlob = Blob.valueOf(csvFile);
            caseMassUploadCont.upload();
            Test.stopTest();

            Case myCase = [SELECT Id, OwnerId, Contact_Email__c FROM Case];
            System.assertEquals(user.Id,myCase.OwnerId,
                    'CaseMassUploadContTest_forPortalUser : Ownership of the case should be assigned to the passed user');
        }
    }

    /********************************************************************************************************
    *  Scenario:
    *      Testing swap method: sending 2 params as strings to the method should swap those values
    *      TDO_TODO: Swap method is not referenced in the CaseMassUploadCont controller and should be removed.
    *********************************************************************************************************/
    @isTest
    static void swapTwoStrings() {

        Test.startTest();
        CaseMassUploadCont caseMassUploadCont = new CaseMassUploadCont();
        String value1 = 'General';
        String value2 = 'Process';
        caseMassUploadCont.swap(value1,value2);
        Test.stopTest();

    }
}