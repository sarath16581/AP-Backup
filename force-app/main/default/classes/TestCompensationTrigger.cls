// created by shengpeng.xiao@bluewolf.com at 2014.7.1
// test class for after update trigger on Compensation
// @changelog
// modified by phap.mai@auspost.com.au at 20 Nov 2021 -- Added approvedCompensation
// modified by phap.mai@auspost.com.au at 20 Nov 2021 -- Added notApprovedCompensation
// modified by phap.mai@auspost.com.au at 20 Nov 2021 -- Modified myUnitTest: old method failed because u2 user do not have sufficient access to update compensation. Need to set u2 as higher role than u1.
@isTest
private class TestCompensationTrigger {

    @TestSetup
    private static void prepareData()
    {
        User agentUser = agentUser();
        insert agentUser;
        // setting
        Consumer_Help_and_Support__c hs = new Consumer_Help_and_Support__c();
        hs.Encoded_Crypto_Key__c = 'testcryptokey/testcryptokey/testcryptokey/+=';
        hs.Compensation_Max_Attemps__c = 5;
        System.runAs(agentUser)
        {
            insert hs;
        }
        
        // account
        Account iAccount = TestDataProvider.createAccount('Account', 1)[0];
        System.runAs(agentUser)
        {
            insert iAccount;
        }
        
        // contact
        Contact iContact = TestDataProvider.createContact('Contact', iAccount.Id, null);
        iContact.MobilePhone = '123456789';
        System.runAs(agentUser)
        {
            insert iContact;
        }

        // case
        Case iCase = new Case(ContactId = iContact.Id, Subject = 'subject', Description = 'description', Type = 'General Enquiry');
        System.runAs(agentUser)
        {
            insert iCase;
        }
    }

    /**
     * scenario: compensation is approved
     * expected: compensation token populate, email send to customer & case comment on email sent out
     */
    @isTest
    private static void approvedCompensation()
    {
       Compensation__c compensation = createCompensation(false);
       compensation.Bank_Detail_Provided_By_Customer__c = true;

       User agentUser = [SELECT Id FROM User WHERE UserName = 'agentuser@testorg.com'];
    
       Test.startTest();
       System.runAs(agentUser)
       {
           insert compensation;
       }
       compensation = [SELECT Compensation_Form_Token__c, Case__c FROM Compensation__c WHERE Id = :compensation.Id];
       List<CaseComment> comments = [SELECT CommentBody FROM CaseComment WHERE ParentId = :compensation.Case__c];
       System.assert(String.isNotEmpty(compensation.Compensation_Form_Token__c), 'approvedCompensation failed: token is empty');
       System.assertEquals(1, System.Limits.getEmailInvocations(), 'approvedCompensation failed: no email sent');
       System.assert(comments.size() > 0, 'approvedCompensation failed: no comment created');
       Test.stopTest();
    }

    /**
     * scenario: compensation is not approved
     * expected: compensation token empty, do not send compesantion email & no case comment on this
     */
    @isTest
    private static void notApprovedCompensation()
    {
       Compensation__c compensation = createCompensation(false);
       compensation.Bank_Detail_Provided_By_Customer__c = true;
       compensation.Compensation_Amount__c = 150;
       compensation.Cover_Type__c = 'ACL';

       User agentUser = [SELECT Id FROM User WHERE UserName = 'agentuser@testorg.com'];
    
       Test.startTest();
       System.runAs(agentUser)
       {
           insert compensation;
       }
       compensation = [SELECT Compensation_Form_Token__c, Case__c FROM Compensation__c WHERE Id = :compensation.Id];
       List<CaseComment> comments = [SELECT CommentBody FROM CaseComment WHERE ParentId = :compensation.Case__c];
       System.assert(String.isEmpty(compensation.Compensation_Form_Token__c), 'notApprovedCompensation failed: token is not empty');
       System.assertEquals(0, System.Limits.getEmailInvocations(), 'notApprovedCompensation failed: email sent');
       System.assert(comments.size() == 0, 'notApprovedCompensation failed: comment created');
       Test.stopTest();
    }

    /**
     * create an agent user for testing
     */
    private static User agentUser()
    {
        Profile agentProfile = [SELECT Id FROM Profile WHERE Name = 'SSSW - Service Agent'];
        UserRole agentRole = [SELECT Id FROM UserRole WHERE Name = 'SSSW North Service Agent'];
        
        User agentManager = agentManagerUser(agentProfile, agentRole);
        insert agentManager;

        User agent = new User(
            Alias = 'Agent',
            Email='agentuser@testorg.com',
            EmailEncodingKey='UTF-8',
            LastName='BlueWolf1',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = agentProfile.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='agentuser@testorg.com',
            ManagerId = agentManager.Id,
            CallCentreManager__c = agentManager.Id,
            UserRoleId = agentRole.Id
        );

        return agent;
    }

    /**
     * create an agent user for testing
     */
    private static User agentManagerUser(Profile agentProfile, UserRole agentRole)
    {
        User agentManager = new User(
            Alias = 'Manager',
            Email='agentmanageruser@testorg.com',
            EmailEncodingKey='UTF-8',
            LastName='BlueWolf1',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = agentProfile.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='agentmanageruser@testorg.com',
            UserRoleId = agentRole.Id
        );

        return agentManager;
    }

    /**
     * create compensation for testing
     */
    private static Compensation__c createCompensation(Boolean doCommit)
    {
        // EFT record type
        RecordType rc = [SELECT Id FROM RecordType WHERE DeveloperName = 'EFT' AND SobjectType = 'Compensation__c'];

        Contact iContact = [SELECT Id FROM Contact];
        Case iCase = [SELECT Id FROM Case];

        // compensation
        Compensation__c compensation = new Compensation__c();
        compensation.Contact__c = iContact.Id;
        compensation.RecordTypeId = rc.Id;
        compensation.Case__c = iCase.Id;
        compensation.Compensation_Amount__c = 50;
        compensation.Cover_Type__c = 'T&C Cover	';
        compensation.Bank_Detail_Provided_By_Customer__c = true;

        if (doCommit) insert compensation;

        return compensation;
    }

    static testMethod void myUnitTest()
    {
        UserRole agentRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'SSSW_North_Service_Agent'];
        UserRole agentManagerRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'SSSW_North_Team_Lead'];
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        User u1;    // agent user
        User u2;    // agent manager user
        
        // create user using runAs to bypass mixed DML restriction
        System.runAs(thisUser)
        {
            Profile suProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User']; 
            u1 = new User(  Alias = 'Wolf', 
                            Email='bluewolfday@testorg.com', 
                            EmailEncodingKey='UTF-8', 
                            LastName='BlueWolf1', 
                            LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', 
                            ProfileId = suProfile.Id, 
                            TimeZoneSidKey='America/Los_Angeles', 
                            UserName='bluewolfday@testorg.com', 
                            UserRoleId = agentRole.Id);
            insert u1;
            
            u2 = new User(  Alias = 'Blue', 
                            Email='bluewolfnight@testorg.com', 
                            EmailEncodingKey='UTF-8', 
                            LastName='BlueWolf1', 
                            LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', 
                            ProfileId = suProfile.Id, 
                            TimeZoneSidKey='America/Los_Angeles', 
                            UserName='bluewolfnight@testorg.com', 
                            UserRoleId = agentManagerRole.Id);
            insert u2;
        }
        
        Case c = new Case(EnquirySubType__c ='Problem', Status = 'New', Subject = 'My Subject', type = 'General Enquiry', ReopenDate__c = System.today());
        
        System.runAs(u1)
        {
            insert c; 
        }
             
        Compensation__c comp = new Compensation__c();
        comp.Case__c = c.Id;
        comp.Compensation_Amount__c = 10;
        comp.Status__c = 'Pending';
        comp.Cover_Type__c = 'ACL';
        insert comp;
            
        comp = [SELECT Status__c, LastModifiedById FROM Compensation__c WHERE Id =: comp.Id];
        
        System.runAs(u2)
        {
            comp.Status__c = 'Rejected';      
            update comp;
        }  
        
        c = [SELECT OwnerId, LastModifiedDate FROM Case WHERE Id =: c.Id];
        comp = [SELECT Status__c, LastModifiedById FROM Compensation__c WHERE Id =: comp.Id]; 
        
        system.assert(u2.Id == comp.LastModifiedById);   
        
        comp.Status__c = 'Pending';
        update comp;
    }   
}