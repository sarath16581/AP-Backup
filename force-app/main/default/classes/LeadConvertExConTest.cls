/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 
 07.01.2014    AusPost                              Code from Production
 07.01.2014    Louis Wang (Bluewolf)                Removed concept of Partner / Individual, such that standard Account-Contact is reestablished
                                                    Added new scenario such that BA is always mandatory. Conversion will stop if BA is not available.  
                                                    Adjusted scenario to cope with Account-Contact relationship. 
                                                    Improved test coverage.
 28.03.2017    AusPost (Sushant)                    Commented line with details provided in the comments -> insert testEvent1; 
 02.06.2020    MC (Salesforce)                      Added 'Disqualified_Lead_Reason__c' for myUnitTest7
 30.09.2021    seth.heang@auspost.com.au	        Uplift SF API Version to 52 and fix test data to bypass validation rule
 */
@isTest
public class LeadConvertExConTest {

    static testMethod void myUnitTest1() {
        //This method will test Lead Conversion Scenario 1 - New Contact, New BA
        
        Lead testLead1 = new Lead(
            Company = 'oracle',
            LastName='Ellison',
            FirstName='Larry',
            Email='le@oracle.com',
            Street='Street',
            City='City',
            State='State',
            Country='Country',
            PostalCode='1234',
            Parcels_per_week__c='1-9',
            Opportunity_Initial_Estimate__c=100,
            Status='Not Verified',
            MobilePhone='0400123456',
        	Customer_Type__c='New Customer',
        	ABN__c='50110219460');             
        insert testLead1;

        Task testTask1 = new Task(
            WhoId = testLead1.Id);
        insert testTask1;
            
        Event testEvent1 = new Event(
            WhoId = testLead1.Id,
            DurationInMinutes=30,
            ActivityDateTime = System.Now());
        //insert testEvent1; 
        //SV: 27/03/2017: Inactivated above Event insert. The event criteria was failing to trigger process builder Coverage_Freq_Event. 
        //More detail: Process builder checks for an associated Account for an event and we cannot associate the Account to this event as it already has a WhoId associated (Salesforce limitation)
            
        Note testNote1 = new Note(
            ParentId = testLead1.Id,
            Title = 'test note');
        insert testNote1;
                
        Attachment testAttachment1 = new Attachment(
            ParentId = testLead1.Id,
            Name = 'test attachment',
            Body=Blob.valueOf('Test'), 
            ContentType='text/plain');
        insert testAttachment1;
        
        test.StartTest();    
            PageReference pageRef = Page.LeadConvert2;
            Test.setCurrentPage(pageRef);
            
            ApexPages.currentPage().getParameters().put('id',testLead1.id);  
            ApexPages.StandardController sc1 = new ApexPages.standardController(testLead1);  
            LeadConvertExCon leadExcon1 = new LeadConvertExCon(sc1);  

            list<LeadConvertExCon.cContact> matchingContacts1 = leadExcon1.matchingContacts;
            list<LeadConvertExCon.cAccount> matchingAccounts1 = leadExcon1.matchingBAccts;
            Boolean contactfound1 = leadExcon1.contactfound;
            Boolean BAfound1 = leadExcon1.Bafound;
            
            leadExcon1.sendEmail = false;
            leadExcon1.donotcreateOpp = true; // opportunity trigger will cause issue with opportunity owner in test mode, so opportunity creation is not covered
            leadExcon1.contactId = null;
            leadExcon1.BAcctId = null;
            leadExcon1.createInd = true;
            leadExcon1.createOrg = true;        
            leadExcon1.convertLead();
                        
            //system.AssertEquals(true, [SELECT IsConverted FROM Lead WHERE Id=:testLead1.Id limit 1].IsConverted);
        test.StopTest();
    }
    
    static testMethod void myUnitTest2() {
        //This method will test Lead Conversion Scenario 2 - Old Contact, New BA
        // this should fail due to validation   
        Contact accPerson = new Contact();
            accPerson.phone='12345678'; 
            accPerson.FirstName = 'Marc';
            accPerson.LastName = 'Benioff';
            accPerson.OtherStreet = 'Street';
            accPerson.OtherCity = 'City';
            accPerson.OtherState = 'State';
            accPerson.OtherPostalCode = '1234';
            // added to by-pass the new validation rule
            accPerson.MailingPostalCode = '3000';            
            accPerson.Phone = '87654321';                       
        insert accPerson;
        
        Lead testLead2 = new Lead(
            Company = 'sfdc',
            LastName='Benioff',
            FirstName='Marc',
            Email='mb@sfdc.com',
            Street='Street',
            City='City',
            State='State',
            Country='Country',
            PostalCode='1234',
            Parcels_per_week__c='1-9',
            Opportunity_Initial_Estimate__c=100,            
            Status='Not Verified',
            MobilePhone='0400123456',
        	Customer_Type__c='Existing Customer',
        	ABN__c='50110219460');           
        insert testLead2;
        
        test.StartTest();    
            PageReference pageRef = Page.LeadConvert2;
            Test.setCurrentPage(pageRef);
            
            ApexPages.currentPage().getParameters().put('id',testLead2.id);
            ApexPages.StandardController sc2 = new ApexPages.standardController(testLead2);  
            LeadConvertExCon leadExcon2 = new LeadConvertExCon(sc2);  
            
            leadExcon2.withCompany = true;
            leadExcon2.sendEmail = false;
            leadExcon2.donotcreateOpp = true; // opportunity trigger will cause issue with opportunity owner in test mode, so opportunity creation is not covered
            leadExcon2.contactId = accPerson.Id;
            leadExcon2.BAcctId = null;
            leadExcon2.createInd = false;
            leadExcon2.createOrg = true;
            leadExcon2.convertLead();
            //leadExcon2.convertLead(testLead2.id, null, null, leadExCon2.donotcreateOpp, 'test', leadExCon2.sendEmail, 'create');
            //leadExcon2.convertLead(testClone2.id, leadExcon2.PAcctId, null, leadExCon2.donotcreateOpp, 'test', leadExCon2.sendEmail, 'merge');
            
            system.AssertEquals(false, [SELECT IsConverted FROM Lead WHERE Id=:testLead2.Id limit 1].IsConverted);
        test.stopTest();
    }
    
    static testMethod void myUnitTest3() {
        //This method will test Lead Conversion Scenario 3 - New Contact, Old BA
        
        RecordType orgrectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        
        Account accBusiness = new Account(name='sfdc', phone='10000000', website='www.sfdc.com', recordtypeid=orgrectype.id);
        insert accBusiness;
        
        Lead testLead3 = new Lead(
            Company='sfdc',
            LastName='Benioff',
            FirstName='Marc',
            Email='mb@sfdc.com',
            Street='Street',
            City='City',
            State='State',
            Country='Country',
            PostalCode='1234',
            Parcels_per_week__c='1-9',
            Opportunity_Initial_Estimate__c=100,            
            Status='Not Verified',
            MobilePhone='0400123456',
        	Customer_Type__c='Existing Customer',
        	ABN__c='50110219460');          
        insert testLead3;

        Note note = new Note();
        note.Title = 'Note title';
        note.ParentId = testLead3.id;
        note.Body = 'Notes';
        insert note;  
        
        test.StartTest();    
            PageReference pageRef = Page.LeadConvert2;
            Test.setCurrentPage(pageRef);
            
            ApexPages.currentPage().getParameters().put('id',testLead3.id);
            ApexPages.StandardController sc3 = new ApexPages.standardController(testLead3);  
            LeadConvertExCon leadExcon3 = new LeadConvertExCon(sc3);  
            
            leadExcon3.sendEmail = false;
            leadExcon3.donotcreateOpp = true; // opportunity trigger will cause issue with opportunity owner in test mode, so opportunity creation is not covered
            leadExcon3.contactId = null;
            leadExcon3.BAcctId = accBusiness.Id;
            leadExcon3.createInd = true;
            leadExcon3.createOrg = false;        
            leadExcon3.convertLead();
            //leadExcon3.convertLead(testLead3.Id, leadExcon3.PAcctId, leadExcon3.BAcctId , leadExcon3.donotcreateOpp, 'test', leadExcon3.sendEmail, 'merge');
            
            //system.AssertEquals(true, [SELECT IsConverted FROM Lead WHERE Id=:testLead3.Id limit 1].IsConverted);
        test.stopTest();
    }
 
    static testMethod void myUnitTest4a() {
        //This method will test Lead Conversion Scenario 4a - Old Contact, Old BA, contact.AccountId = old BA
        
        RecordType orgrectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        
        Account accBusiness = new Account(name='sfdcss', phone='10000000', website='www.sfdc.com', recordtypeid=orgrectype.id);
        insert accBusiness;

        // note: contact must have the same Account as in the Lead record
        Contact accPerson = new Contact();
            accPerson.phone='12345678'; 
            accPerson.FirstName = 'Marc';
            accPerson.LastName = 'Benioffss';
            accPerson.OtherStreet = 'Street';
            accPerson.OtherCity = 'City';
            accPerson.OtherState = 'State';
            accPerson.OtherPostalCode = '1234';
            // added to by-pass the new validation rule
            accPerson.MailingPostalCode = '3000';            
            accPerson.Phone = '87654321';
            accPerson.AccountId = accBusiness.Id;                       
        insert accPerson;
                
        Lead testLead4 = new Lead(
            Company = 'sfdcss',
            LastName='Benioffss',
            FirstName='Marc',
            Email='mb@sfdc.com',
            Street='Street',
            City='City',
            State='State',
            Country='Country',
            PostalCode='1234',
            Parcels_per_week__c='1-9',
            Opportunity_Initial_Estimate__c=100,
            Status='Not Verified',
            MobilePhone='0400123456',
        	Customer_Type__c='Existing Customer',
        	ABN__c='50110219460');          
        insert testLead4;
        
        test.StartTest();    
            PageReference pageRef = Page.LeadConvert2;
            Test.setCurrentPage(pageRef);
            
            ApexPages.currentPage().getParameters().put('id',testLead4.id);
            ApexPages.StandardController sc4 = new ApexPages.standardController(testLead4);  
            LeadConvertExCon leadExcon4 = new LeadConvertExCon(sc4);  

            list<LeadConvertExCon.cContact> matchingContacts4 = leadExcon4.matchingContacts;
            list<LeadConvertExCon.cAccount> matchingAccounts4 = leadExcon4.matchingBAccts;
            Boolean contactfound4 = leadExcon4.contactfound;
            Boolean BAfound4 = leadExcon4.Bafound;
            matchingContacts4[0].selected = true;
            matchingAccounts4[0].selected = true;
            
            leadExcon4.sendEmail = false;
            leadExcon4.donotcreateOpp = true; // opportunity trigger will cause issue with opportunity owner in test mode, so opportunity creation is not covered
            leadExcon4.contactId = accPerson.Id;
            leadExcon4.BAcctId = accBusiness.Id;
            leadExcon4.createInd = false;
            leadExcon4.createOrg = false;        
            leadExcon4.convertLead();            
            
            //system.AssertEquals(true, [SELECT IsConverted FROM Lead WHERE Id=:testLead4.Id limit 1].IsConverted);
            
        test.StopTest();
    }
 
    static testMethod void myUnitTest4b() {
        //This method will test Lead Conversion Scenario 4b - Old Contact, Old BA, contact.AccountId != old BA
        // this should fail due to validation   
        
        RecordType orgrectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        
        Account accBusiness = new Account(name='sfdc', phone='10000000', website='www.sfdc.com', recordtypeid=orgrectype.id);
        insert accBusiness;

        Contact accPerson = new Contact();
            accPerson.phone='12345678'; 
            accPerson.FirstName = 'Marc';
            accPerson.LastName = 'Benioff';
            accPerson.OtherStreet = 'Street';
            accPerson.OtherCity = 'City';
            accPerson.OtherState = 'State';
            accPerson.OtherPostalCode = '1234';
            // added to by-pass the new validation rule
            accPerson.MailingPostalCode = '3000';
            accPerson.Phone = '87654321';                       
        insert accPerson;
                
        Lead testLead4 = new Lead(
            Company = 'sfdc',
            LastName='Benioff',
            FirstName='Marc',
            Email='mb@sfdc.com',
            Street='Street',
            City='City',
            State='State',
            Country='Country',
            PostalCode='1234',
            Parcels_per_week__c='1-9',
            Opportunity_Initial_Estimate__c=100,            
            Status='Not Verified',
            MobilePhone='0400123456',
        	Customer_Type__c='Existing Customer',
        	ABN__c='50110219460');         
        insert testLead4;
        
        test.StartTest();    
            PageReference pageRef = Page.LeadConvert2;
            Test.setCurrentPage(pageRef);
            
            ApexPages.currentPage().getParameters().put('id',testLead4.id);
            ApexPages.StandardController sc4 = new ApexPages.standardController(testLead4);  
            LeadConvertExCon leadExcon4 = new LeadConvertExCon(sc4);  
            
            leadExcon4.sendEmail = false;
            leadExcon4.donotcreateOpp = true; // opportunity trigger will cause issue with opportunity owner in test mode, so opportunity creation is not covered
            leadExcon4.contactId = accPerson.Id;
            leadExcon4.BAcctId = accBusiness.Id;
            leadExcon4.createInd = false;
            leadExcon4.createOrg = false;        
            leadExcon4.convertLead();
                        
            system.AssertEquals(false, [SELECT IsConverted FROM Lead WHERE Id=:testLead4.Id limit 1].IsConverted);
            
        test.StopTest();
    }
    
    
    // static testMethod void myUnitTest5() {//This method will test Lead Conversion Scenario 5 - New PA only
    // static testMethod void myUnitTest6() {//This method will test Lead Conversion Scenario 6 - Old PA only
    // LW 07.01.2014 - The above testMethods were removed, as Lead must have Organisation value (new business rule).
    
    static testMethod void myUnitTest7() {
        //This method will test Lead Conversion 'Disqualified' Scenario
        // this should fail due to validation   
        
        Lead testLead7 = new Lead(
            Company = 'sfdc',
            LastName='Benioff',
            FirstName='Marc',
            Email='mb@sfdc.com',
            Street='Street',
            City='City',
            State='State',
            Country='Country',
            PostalCode='1234',
            Parcels_per_week__c='1-9',
            Status = 'Disqualified',
            //Added additional attribute to cater for lead validation rule enhancement as part of STP project
            Disqualified_Lead_Reason__c = 'Incorrect Contact Details',
            MobilePhone='0400123456',
        	ABN__c='50110219460');          
        insert testLead7;
        
        test.StartTest();
            PageReference pageRef = Page.LeadConvert2;
            Test.setCurrentPage(pageRef);
            
            ApexPages.currentPage().getParameters().put('id',testLead7.id);
            ApexPages.StandardController sc7 = new ApexPages.standardController(testLead7);  
            LeadConvertExCon leadExcon7 = new LeadConvertExCon(sc7);  
            
            leadExcon7.sendEmail = false;
            leadExcon7.donotcreateOpp = true; // opportunity trigger will cause issue with opportunity owner in test mode, so opportunity creation is not covered
            leadExcon7.contactId = null;
            leadExcon7.BAcctId = null;
            leadExcon7.createInd = true;
            leadExcon7.createOrg = true;        
            leadExcon7.convertLead();
                        
            system.AssertEquals(false, [SELECT IsConverted FROM Lead WHERE Id=:testLead7.Id limit 1].IsConverted);
        test.StopTest();
    }
    
    static testMethod void myUnitTest8() {
        //This method will test Lead Conversion 'No Postal Code' Scenario
        // this should fail due to validation   
                
        Lead testLead8 = new Lead(
            Company = 'sfdc',        
            LastName='Benioff',
            FirstName='Marc',
            Email='mb@sfdc.com',
            Street='Street',
            City='City',
            State='State',
            Country='Country',
            Parcels_per_week__c='1-9',
            Status = 'Not Verified',
            MobilePhone='0400123456',
        	ABN__c='50110219460');           
        insert testLead8;
        
        test.StartTest();
            PageReference pageRef = Page.LeadConvert2;
            Test.setCurrentPage(pageRef);
            
            ApexPages.currentPage().getParameters().put('id',testLead8.id);
            ApexPages.StandardController sc8 = new ApexPages.standardController(testLead8);  
            LeadConvertExCon leadExcon8 = new LeadConvertExCon(sc8);  
            
            leadExcon8.sendEmail = false;
            leadExcon8.donotcreateOpp = true; // opportunity trigger will cause issue with opportunity owner in test mode, so opportunity creation is not covered
            leadExcon8.contactId = null;
            leadExcon8.BAcctId = null;
            leadExcon8.createInd = true;
            leadExcon8.createOrg = true;        
            leadExcon8.convertLead();
                        
            system.AssertEquals(false, [SELECT IsConverted FROM Lead WHERE Id=:testLead8.Id limit 1].IsConverted);
        test.StopTest();
    }

    static testMethod void myUnitTest9() {
        //This method will test Lead Conversion 'No Organisation on Lead record' Scenario
        // this should fail due to validation           
        
        Lead testLead9 = new Lead(
            LastName='Benioff',
            FirstName='Marc',
            Email='mb@sfdc.com',
            Street='Street',
            City='City',
            State='State',
            PostalCode='1234',            
            Country='Country',
            Parcels_per_week__c='1-9',
            Status = 'Not Verified',
            MobilePhone='0400123456',
        	ABN__c='50110219460');          
        insert testLead9;
        
        test.StartTest();
            PageReference pageRef = Page.LeadConvert2;
            Test.setCurrentPage(pageRef);
            
            ApexPages.currentPage().getParameters().put('id',testLead9.id);
            ApexPages.StandardController sc9 = new ApexPages.standardController(testLead9);  
            LeadConvertExCon leadExcon9 = new LeadConvertExCon(sc9);  
            
            leadExcon9.sendEmail = false;
            leadExcon9.donotcreateOpp = true; // opportunity trigger will cause issue with opportunity owner in test mode, so opportunity creation is not covered
            leadExcon9.contactId = null;
            leadExcon9.BAcctId = null;
            leadExcon9.createInd = true;
            leadExcon9.createOrg = true;        
            leadExcon9.convertLead();
                        
            system.AssertEquals(false, [SELECT IsConverted FROM Lead WHERE Id=:testLead9.Id limit 1].IsConverted);
        test.StopTest();
    }

    static testMethod void myUnitTest10() {
        //This method will test Lead Conversion 'No Opportunity Initial Estimate' Scenario
        // this should fail due to validation   
        
        Lead testLead10 = new Lead(
            Company = 'sfdc',
            LastName='Benioff',
            FirstName='Marc',
            Email='mb@sfdc.com',
            Street='Street',
            City='City',
            State='State',
            PostalCode='1234',            
            Country='Country',
            Parcels_per_week__c='1-9',            
            Status = 'Not Verified',
            MobilePhone='0400123456',
        	ABN__c='50110219460');         
        insert testLead10;
        
        test.StartTest();
            PageReference pageRef = Page.LeadConvert2;
            Test.setCurrentPage(pageRef);
            
            ApexPages.currentPage().getParameters().put('id',testLead10.id);
            ApexPages.StandardController sc10 = new ApexPages.standardController(testLead10);  
            LeadConvertExCon leadExcon10 = new LeadConvertExCon(sc10);  
            
            leadExcon10.sendEmail = false;
            leadExcon10.donotcreateOpp = false;
            leadExcon10.contactId = null;
            leadExcon10.BAcctId = null;
            leadExcon10.createInd = true;
            leadExcon10.createOrg = true;        
            leadExcon10.convertLead();
                        
            system.AssertEquals(false, [SELECT IsConverted FROM Lead WHERE Id=:testLead10.Id limit 1].IsConverted);
        test.StopTest();
    }
}