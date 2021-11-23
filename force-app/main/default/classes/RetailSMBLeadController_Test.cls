/**************************************************
Type:       Test Class
Purpose:    Test for RetailSMBLeadController
History:
--------------------------------------------------
26.05.2016:  snigdha.sahu@auspost.com.au    Created
27.06.2018:  heguang.miao@coroma.com.au     [TDO-101] Rewrote tests based on scenarios

**************************************************/
@isTest
class RetailSMBLeadController_Test {

    /*********************************************************************************
   *  Scenario:
   *      Setup method to create test data.
   **********************************************************************************/
    @testSetup
    static void createTestData(){
        //Fetch a profile.
        Profile testProfile = [SELECT Id,Name
                               FROM Profile
                               WHERE Name = 'Standard User'];
        //Create a user.
        User newTestUser = TestUtility.createUser('TestU1',testProfile.id,null);
        insert newTestUser;
    }

    /**
     * SCENARIO: Submit a new lead
     */
    @isTest
    static void submitLead_newLead() {
        //Fetch a user.
        User testUser = [SELECT Id
                         FROM User
                         WHERE isActive = TRUE
                         AND alias = 'TestU1'
                         LIMIT 1];

        String leadEmail = 'retailsbmlead@test.com';

        System.runAs(testUser) {
            Test.startTest();
            RetailSMBLeadController retailSMBLeadCont = new RetailSMBLeadController();

            retailSMBLeadCont.FirstName = 'Lead first name';
            retailSMBLeadCont.LastName = 'Lead last name';
            retailSMBLeadCont.Phone = '123456789';
            retailSMBLeadCont.Email = leadEmail;
            retailSMBLeadCont.CreatorWCC = '1234567890';
            retailSMBLeadCont.Description = 'Lead description';
            retailSMBLeadCont.Company = 'Hydra';

            retailSMBLeadCont.submitLead();

            Test.stopTest();

            Lead lead = [SELECT Id, Name, CreatedDate, Company
                         FROM Lead
                         WHERE Email = :leadEmail
                         AND CreatedDate=TODAY
                         LIMIT 1];

            System.assertEquals('Hydra', lead.Company,
                    'RetailSMBLeadController_submitLead_newLead : a new lead should be created');

            //Check ApexPage messages
            Boolean messageFound = false;
            ApexPages.Message[] pageMessages = ApexPages.getMessages();
            for (ApexPages.Message message : pageMessages) {
                if (message.getSummary().equals('Lead created successfully.Thank you!')
                        && message.getSeverity() == ApexPages.Severity.CONFIRM) {
                    messageFound = true;
                    break;
                }
            }

            System.assertEquals(true,messageFound,
                    'RetailSMBLeadController_submitLead_newLead : created message should me generated');
        }
    }

    /**
     * SCENARIO: Update an existing lead
     */
    @isTest
    static void submitLead_replaceLead() {
        User testUser = [SELECT Id
                         FROM User
                         WHERE isActive = TRUE
                         AND alias = 'TestU1'
                         LIMIT 1];

        String leadEmail = 'retailsbmlead@test.com';

        //Create a lead first
        Lead testDataNewLead = new Lead(
                FirstName = 'dummyFirstName',
                LastName = 'dummyLastName',
                Phone = '0102030405',
                Email = leadEmail,
                Creator_Centre_Code__c = '123456',
                Description = 'Test Lead Creation',
                Company = 'SHIELD'
                //CreatedDate = System.Today()
        );

        System.runAs(testUser) {

            insert testDataNewLead;

            Id leadId = testDataNewLead.Id;

            Test.startTest();
            //ApexPages.StandardController stdCont = new ApexPages.StandardController(newLead);
            RetailSMBLeadController retailSMBLeadCont = new RetailSMBLeadController();

            retailSMBLeadCont.FirstName = 'Lead first name';
            retailSMBLeadCont.LastName = 'Lead last name';
            retailSMBLeadCont.Phone = '123456789';
            //Keep the email same
            retailSMBLeadCont.Email = leadEmail;
            retailSMBLeadCont.CreatorWCC = '1234567890';
            retailSMBLeadCont.Description = 'Lead description';
            retailSMBLeadCont.Company = 'Hydra';

            retailSMBLeadCont.submitLead();
            Test.stopTest();

            Lead lead = [SELECT Id, Name, CreatedDate, Company
                         FROM Lead
                         WHERE Email = :leadEmail
                         AND CreatedDate=TODAY
                         LIMIT 1];

            System.assertEquals(leadId, lead.Id,
                    'RetailSMBLeadController_submitLead_replaceLead : Lead id should be kept');
            System.assertEquals('Hydra', lead.Company,
                    'RetailSMBLeadController_submitLead_replaceLead : Leads info should be updated');

            //Check ApexPage messages
            Boolean messageFound = false;
            ApexPages.Message[] pageMessages = ApexPages.getMessages();
            for (ApexPages.Message message : pageMessages) {
                if (message.getSummary().equals('Lead updated successfully.Thank you!')
                        && message.getSeverity() == ApexPages.Severity.CONFIRM) {
                    messageFound = true;
                    break;
                }
            }

            System.assertEquals(true,messageFound,
                    'RetailSMBLeadController_submitLead_replaceLead : updated message should be generated');
        }
    }

    /**
     * SCENARIO: Submit an invalid lead
     */
    @isTest
    static void submitLead_error() {

        Test.startTest();

        Lead newLead = new Lead();
        //ApexPages.StandardController stdCont = new ApexPages.StandardController(newLead);
        RetailSMBLeadController retailSMBLeadCont = new RetailSMBLeadController();

        //Make these fields null, this can cause errors
        retailSMBLeadCont.FirstName = null;
        retailSMBLeadCont.LastName = null;
        retailSMBLeadCont.Phone = null;
        retailSMBLeadCont.Email = null;
        retailSMBLeadCont.CreatorWCC = null ;
        retailSMBLeadCont.Description = null ;
        retailSMBLeadCont.Company = null ;

        retailSMBLeadCont.submitLead();

        Test.stopTest();

        Boolean messageFound = false;
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for (ApexPages.Message message : pageMessages) {
            if (message.getSeverity() == ApexPages.Severity.ERROR) {
                messageFound = true;
                break;
            }
        }

        System.assertEquals(true,messageFound,
                'RetailSMBLeadController_submitLead_error : error message should be generated');

    }
}