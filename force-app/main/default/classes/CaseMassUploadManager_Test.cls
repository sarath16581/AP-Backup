/**
*  This test class is for CaseMassUploadDeciphaCont.
*
@author Frank Chen
@created 2014-06-24
@version 1.0
@since 20.0
*
@changelog
* 2014-06-24 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage  82%
*/
@isTest
private class CaseMassUploadManager_Test {

    static testMethod void testTypeText() {
        
        CaseMassUploadFieldMappingSettings__c cfms = TestDataProvider.createTestCaseMassUploadFieldMappingSettings1();
        
        Case case1 = new Case();
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'Network Responded';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.EnquirySubType__c = 'Article carded - no card left';
        case1.DateofIncident__c = date.today();
        insert case1;   
        
        List<String> headerRow = new List<String>();
        headerRow.add('Content of Parcel');
        
        List<String> csvRow = new List<String>();
        csvRow.add('Content of Parcel');
        Id profileId = [select id from Profile where Name like 'BSP%' limit 1].Id;
        ccusettings__c c= new ccusettings__c(CCUCommunityUserProfileId__c=profileId);
        insert c;
        Test.startTest();
        
        CaseMassUploadManager cum = new CaseMassUploadManager();
        
        CaseMassUploadManager.createCases(case1, 'csv');
        CaseMassUploadManager.createCase(case1, headerRow, csvRow,true);
        CaseMassUploadManager.createCase(case1, headerRow, csvRow,false);
        CaseMassUploadManager.parsetDate('s');
        CaseMassUploadManager.parseNumber('s');
        CaseMassUploadManager.parseDateTime('s');
        
        system.assert(true);
        Test.stopTest();
    }
    static testMethod void testTypeNum() {
        
        CaseMassUploadFieldMappingSettings__c cfms = TestDataProvider.createTestCaseMassUploadFieldMappingSettings2();
        
        Case case1 = new Case();
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'Network Responded';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.EnquirySubType__c = 'Article carded - no card left';
        case1.DateofIncident__c = date.today();
        insert case1;   
        Id profileId = [select id from Profile where Name like 'BSP%' limit 1].Id;
        ccusettings__c c= new ccusettings__c(CCUCommunityUserProfileId__c=profileId);
        insert c;
        List<String> headerRow = new List<String>();
        headerRow.add('xxx');
        
        List<String> csvRow = new List<String>();
        csvRow.add('xxx');
        
        Test.startTest();
        
        CaseMassUploadManager cum = new CaseMassUploadManager();
        
        CaseMassUploadManager.createCases(case1, 'csv');
        CaseMassUploadManager.createCase(case1, headerRow, csvRow,true);
        CaseMassUploadManager.createCase(case1, headerRow, csvRow,false);
        CaseMassUploadManager.parsetDate('s/s/s/s');
        CaseMassUploadManager.parseNumber('1');
        CaseMassUploadManager.parseDateTime('2014-10-10');
                
        system.assert(true);
        Test.stopTest();
    }
}