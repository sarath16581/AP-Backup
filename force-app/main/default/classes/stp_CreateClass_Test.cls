/**************************************************
Description:    Test Class for stp_CreateCase

History:
--------------------------------------------------
2019-10-02  LJ Created

**************************************************/
@IsTest
private class  stp_CreateClass_Test {

    @TestSetup
    static void setup() {
        //Create Accounts.
        List < Account > accounts = TestDataProvider.createAccount('AccountName', 1);
        insert accounts;

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < accounts.size(); i++) {
            Contact con = TestDataProvider.createContact('Contact', accounts[i].Id, null);
            con.FirstName = 'Contact ' + i;
            con.LastName = 'Contact ' + i;
            con.Status__c = 'Active';
            contacts.add(con);
        }
        insert contacts;

        List < Article__c > articles = TestDataProvider.createArticle('sub1', 1, null);
        articles.get(0).Name = '000CONSI001';
        insert articles;

        // create the community user
        User testCommunityUser = createUser('stp', 'partner', 'stp.partner.user@startrack.com.au', 'StarTrack Partner Community', contacts[0].Id);
        insert testCommunityUser;

        User testUser = createUser('stp', 'support', 'stp.support.user@startrack.com.au', 'StarTrack Support', null);
        insert testUser;
    }

    /**
    * Create User
    * **/
    static User createUser(String firstName, String lastName, String email, String profileName, Id contactId) {
        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = :profileName];
        String usernameSuffix = String.valueOf(Integer.valueOf((Math.random() * 90)));
        User newUser = new User();
        newUser.ProfileId = sysAdmin.Id;
        newUser.FirstName = firstName;
        newUser.LastName = lastName;
        newUser.Username = lastName.left(4) + '@' + usernameSuffix + '.bsp';
        newUser.Email = email;
        newUser.CommunityNickname = lastName.left(4) + usernameSuffix;
        newUser.Alias = firstName.left(1) + lastName.left(4) + usernameSuffix;
        newUser.TimeZoneSidKey = 'Australia/Sydney'; // Required
        newUser.LocaleSidKey = 'en_AU'; // Required
        newUser.EmailEncodingKey = 'ISO-8859-1'; // Required
        newUser.LanguageLocaleKey = 'en_US'; // Required
        newUser.IsActive = true;
        if(contactId != null) newUser.ContactId = contactId;
        return newUser;
    }

    /**
    * return the consignment  if the Name matches
    */
    @IsTest
    static void consignmentSearchSuccess() {

        User testUser = [Select Id From User Where Email = 'stp.partner.user@startrack.com.au' ];
        Article__c  existinConsignment = [
                SELECT Id,ArticleID__c,Name,Network__c,Freight_Amount__c,CID__c,Billing_Account__c
                FROM Article__c
                WHERE Name = :'000CONSI001' LIMIT 1
        ];

        Test.startTest();

        System.runAs(testUser) {
            Article__c  retrievedConsignment = stp_CreateCase.consignmentSearch('000CONSI001');
            System.assertEquals(existinConsignment.Id, retrievedConsignment.id, '');
        }

        Test.stopTest();
    }

    /**
    * Throws Exception
    */
    @IsTest
    static void consignmentSearchException() {

        User testUser = [Select Id From User Where Email = 'stp.partner.user@startrack.com.au' ];
        Article__c  existinConsignment = [
                SELECT Id,ArticleID__c,Name,Network__c,Freight_Amount__c,CID__c,Billing_Account__c
                FROM Article__c
                WHERE Name = :'000CONSI001' LIMIT 1
        ];

        Test.startTest();

        System.runAs(testUser) {
            try{
                //since this is not an existing consignment Number, it will throw an exception
                Article__c  retrievedConsignment = stp_CreateCase.consignmentSearch('000C');
            } catch (exception e){
                system.assertNotEquals(e, null);
            }
        }
        Test.stopTest();
    }

    /**
    * return the consignment  if the Name matches
    */
    @IsTest
    static void createCaseSuccess() {

        User testUser = [Select Id From User Where Email = 'stp.partner.user@startrack.com.au' ];

        // JSON from Record Edit :: {"Status":"New","Call_Purpose__c":"Depot Created","Enquiry_Type__c":"Book in","Subject":"Splist cash deposit notification","Description":"fdsfsd"}
        Map<String ,String> mapFieldValue = New Map<String ,String>();
        mapFieldValue.put('Status','New');
        mapFieldValue.put('Call_Purpose__c','Depot Created');
        mapFieldValue.put('Enquiry_Type__c','Book in');
        mapFieldValue.put('Subject','Test CAse');
        mapFieldValue.put('Description','This case is for testing purpose');

        String jsonforCase = JSON.serialize(mapFieldValue);
        System.debug(jsonforCase );

        Test.startTest();

        System.runAs(testUser) {
            String cNumber = stp_CreateCase.createNewCase(jsonforCase ,'000CONSI001');
            Case deCase = [SELECT Id, RecordTypeId, CaseNumber FROM Case WHERE CaseNumber = :cNumber];
            system.assertNotEquals(deCase, null);
        }

        Test.stopTest();
    }

}