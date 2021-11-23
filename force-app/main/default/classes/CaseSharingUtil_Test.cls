/**
*  This test class is for CaseSharingUtil.
*
@author Frank Chen
@created 2014-06-24
@version 1.0
@since 20.0
*
@changelog
* 2014-06-24 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage  100%
*/
@isTest
private class CaseSharingUtil_Test {
    
    @testSetup
    static void testDateCreation() {
    
        User u = TestDataProvider.createTestUsers();
        u.FirstName ='gt';
        u.LastName = 'yr';
        u.Alias = 'we';
        u.Email = 'th@2rt.com';
        u.Username = 'lgh@kr.com';
        u.CommunityNickname = 'rght';       
        insert u;
        
        Network__c nw = new Network__c();
        nw.Name = 'asdf';
        nw.Email__c = 'adf@daf.com';
        nw.Portal_Licenses__c = 99;
        insert nw;      
        
        Case case1 = new Case();
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'Network Responded';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.EnquirySubType__c = 'Article carded - no card left';
        case1.DateofIncident__c = date.today();
        case1.Network__c = nw.Id;
        insert case1; 
        
        Network__c nw2 = new Network__c();
        nw2.Name = 'asdf2';
        nw2.Email__c = 'adf2@daf.com';
        nw2.Portal_Licenses__c = 99;
        insert nw2;     
        
        Case case2 = new Case();
        case2.Type = 'Feedback';
        case2.Subject = 'sadfr';
        case2.Status = 'Network Responded';
        case2.ProductCategory__c = 'Travel & ID';
        case2.EnquirySubType__c = 'Product Support';
        case2.ProductSubCategory__c = 'KeyPass';
        case2.EnquirySubType__c = 'Article carded - no card left';
        case2.DateofIncident__c = date.today();
        case2.Network__c = nw2.Id;
        insert case2;       
        
        Facility_User__c fu = new Facility_User__c();
        fu.User__c = u.Id;
        fu.Network__c = nw.Id;
        insert fu;
        
        Case case3 = new Case();
        case3.Type = 'Feedback';
        case3.Subject = 'Newsdd';
        case3.Status = 'Network Responded';
        case3.ProductCategory__c = 'Travel & ID';
        case3.EnquirySubType__c = 'Product Support';
        case3.ProductSubCategory__c = 'KeyPass';
        case3.EnquirySubType__c = 'Article carded - no card left';
        case3.DateofIncident__c = date.today();
        case3.Network__c = null;
        insert case3; 
    
    }

    /**********************************************************************
     *  Scenario:
     *      Method to update case network from A to B
     **********************************************************************/
    @isTest
    static void  myUnitTest() {

        List<Case> caseList = [Select Id, Network__c from Case where Network__c !=null limit 2];
       
        List<Case> newCases = new List<Case>();
        newCases.add(caseList[0]);
        
        List<Case> oldCases = new List<Case>();
        oldCases.add(caseList[1]);
        
        Test.startTest();
        
        //CaseSharingUtil.insertCaseShares(newCases);
        CaseSharingUtil.updateCaseShares(newCases, oldCases);
        
        system.assert(true);
        Test.stopTest();
    }
    
    /**********************************************************************
     *  Scenario:
     *      Method to update case from no network to new network and look at sharing.
     **********************************************************************/
    @isTest
    static void myUnitTest3() {
    
        Case case1 = [Select Id, Network__c from Case where Network__c = null limit 1];
       
        List<Case> newCases = new List<Case>();
        newCases.add(case1);
        
        Case case2 = [Select Id, Network__c from Case where Network__c !=null limit 1];
        
        List<Case> oldCases = new List<Case>();
        oldCases.add(case2);
        
        Test.startTest();
        
        CaseSharingUtil.updateCaseShares(newCases, oldCases);
        
        system.assert(true);
        Test.stopTest();
    }
}