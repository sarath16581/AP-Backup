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
 * 
 * @changelog
 * 2021-08-06 - Seth Heang - Fix test data to bypass lead validation rule on mandatory phone information
 */
@isTest
private with sharing class updateLeadTriggerTest {

    static testMethod void myUnitTest() {
        Campaign c1 = new Campaign( Name='Xtest campaignX', IsActive = true, type='Partners');
        insert c1;
        
        Test.startTest();
        
        Lead L1 = new Lead(
            LeadSource = 'Xtest campaignX',
            LastName='Lead Record',
            FirstName='First Name',
            Email='x@y.com',
            Street='Street',
            City='City',
            State='State',
            Country='Country',
            PostalCode='1000',
            Parcels_per_week__c='1-9',
			MobilePhone='0340123456'             
        );        
        insert L1;
        // expect that a campaign member record is inserted
        System.assertEquals(1, [Select id from CampaignMember where CampaignId =:c1.id].size());
        
        Lead l2 = new Lead(
            LeadSource = 'test campaign2',
            LastName='Lead Record',
            FirstName='First Name',
            Email='x@x.com',
            Street='Street',
            City='City',
            State='State',
            Country='Country',
            PostalCode='1000',
            Parcels_per_week__c='1-9',
			MobilePhone='0340123457'              
        );        
        insert l2;
        // no match on campaign name, so shouldnt have inserted member, ie 1 instead of 2
        System.assertEquals(1,[Select id from CampaignMember where CampaignId =:c1.id].size());
        
        Test.stopTest();
    }
}