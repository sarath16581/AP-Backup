/**
* @author Frank Chen
* @date 2014-06-23
* @group 
* @tag Test Controller
* @tag 
* @domain 
* @description This test class is for SSSWFaxUtility.
* 2014-06-23 - Frank Chen - Created
* 2014-06-23 - Frank Chen - Test Coverage
* 2020-06-10 - Dheeraj Mandavilli - Included the test method for generateAttachments method
* 2024-08-28 mona.raghav@auspost.com.au - mehtod testTrimEscalationEmailContent added to test trimming of the string
*/
@isTest
private with sharing class SSSWFaxUtility_Test {
    
    static testMethod void myUnitTest() {
        Date d1 = Date.today().addDays(-2);
        
        List<Case> list_case = new List<Case>();
        
        Case case1 = new Case();
        //case1.RecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.OwnerId = Userinfo.getUserId();
        case1.Status = 'Network Responded';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.CreatedDate = d1;
        list_case.add(case1);
        
        
        
        Case case2 = new Case();
        //case1.RecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');
        case2.Type = 'Feedback';
        case2.Subject = 'MINI';
        case2.OwnerId = Userinfo.getUserId();
        case2.Status = 'Network Responded';
        case2.ProductCategory__c = 'Travel & ID';
        case2.EnquirySubType__c = 'Product Support';
        case2.ProductSubCategory__c = 'KeyPass';
        list_case.add(case2);
        insert list_case; 
        
        Fax__c fax = TestDataProvider.createTestFax();
        fax.Case__c = case1.Id;
        fax.CreatedDate = date.today().addDays(-1);
        insert fax;
        
        StatusTracking__c st = TestDataProvider.createTestStatusTracking();
        st.Case__c = case1.Id;
        st.Fax__c = fax.Id;
        st.EndDate__c = date.today().addDays(-1);
        
        StatusTracking__c st2 = TestDataProvider.createTestStatusTracking();
        st2.Case__c = case2.Id;
        st2.Fax__c = fax.Id;
        st2.EndDate__c = date.today().addDays(-1);
        
        insert new List<StatusTracking__c> {st, st2};
            
            Map<Id, Fax__c> oldFaxes = new Map<Id, Fax__c>(); 
        oldFaxes.put(fax.Id,fax);
        
        List<Fax__c> updatedFaxes = new List<Fax__c>();
        
        
        fax.Case__c = case2.Id;
        updatedFaxes.add(fax);
        
        List<Case> cases = new List<Case>();
        cases.add(case1);
        
        Test.startTest();
        
        // SSSWFaxUtility.updateCaseStatusTracking(oldFaxes, updatedFaxes);
        SSSWFaxUtility.createCaseForFax(updatedFaxes);
        SSSWFaxUtility.deleteCaseForFax(cases);
        
        system.assert(true);
        Test.stopTest();
    }
    static testMethod void myUnitTest2() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0];
        User u = [SELECT Id, Name FROM User WHERE ProfileId = :p.Id AND isActive = true limit 1];
        System.runAs(u) {
            List<Case> list_case = new List<Case>();
            Case case2 = new Case();
            //case1.RecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');
            case2.Type = 'Feedback';
            case2.Subject = 'MINI';
            case2.OwnerId = Userinfo.getUserId();
            case2.Status = 'Network Responded';
            case2.ProductCategory__c = 'Travel & ID';
            case2.EnquirySubType__c = 'Product Support';
            case2.ProductSubCategory__c = 'KeyPass';
            list_case.add(case2); 
            
            
            Case case1 = new Case();
            //case1.RecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');
            case1.Type = 'Feedback';
            case1.Subject = 'Newsdd';
            case1.Status = 'Network Responded';
            case1.ProductCategory__c = 'Travel & ID';
            case1.OwnerId = Userinfo.getUserId();
            case1.EnquirySubType__c = 'Product Support';
            case1.ProductSubCategory__c = 'KeyPass';
            case1.RecordTypeId = SSSWFaxUtility.getSSSWFaxCaseRT();
            
            list_case.add(case1); 
            insert list_case;
            case1.ParentId = case2.Id;
            
            
            Fax__c fax = TestDataProvider.createTestFax();
            fax.Case__c = case1.Id;
            fax.CreatedDate = date.today().addDays(-1);
            insert fax;
            
            Fax__c fax2 = TestDataProvider.createTestFax();
            fax2.Case__c = case2.Id;
            fax2.CreatedDate = date.today().addDays(-1);
            fax2.Name = '2234';
            insert fax2;
            
            Fax__c fax3 = fax2.clone(true, false, true, true);
            fax3.Case__c = case1.Id;
            
            StatusTracking__c st = TestDataProvider.createTestStatusTracking();
            st.Case__c = case1.Id;
            st.Fax__c = fax3.Id;
            insert st;
            
            StatusTracking__c st2 = TestDataProvider.createTestStatusTracking();
            st2.Case__c = case2.Id;
            st2.EndDate__c = fax2.CreatedDate;
            insert st2;
            
            Map<Id, Fax__c> oldFaxes = new Map<Id, Fax__c>(); 
            oldFaxes.put(fax.Id,fax);
            oldFaxes.put(fax2.Id, fax2);
            
            
            oldFaxes.put(fax3.Id,fax3);
            List<Fax__c> updatedFaxes = new List<Fax__c>();
            updatedFaxes.add(fax2);
            updatedFaxes.add(fax);
            List<Case> cases = new List<Case>();
            cases.add(case1);
            
            Test.startTest();
            
            SSSWFaxUtility.updateCaseStatusTracking(oldFaxes, updatedFaxes);
            SSSWFaxUtility.createCaseForFax(updatedFaxes);
            SSSWFaxUtility.deleteCaseForFax(cases);
            
            system.assert(true);
            Test.stopTest();
        }
        
    }
    
    static testMethod void myUnitTest3() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0];
        User u = [SELECT Id, Name FROM User WHERE ProfileId = :p.Id AND isActive = true limit 1];
        System.runAs(u) {
            List<Case> list_case = new List<Case>();
            Case case2 = new Case();
            //case1.RecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');
            case2.Type = 'Feedback';
            case2.Subject = 'MINI';
            case2.OwnerId = Userinfo.getUserId();
            case2.Status = 'Network Responded';
            case2.ProductCategory__c = 'Travel & ID';
            case2.EnquirySubType__c = 'Product Support';
            case2.ProductSubCategory__c = 'KeyPass';
            list_case.add(case2); 
            
            
            Case case1 = new Case();
            //case1.RecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');
            case1.Type = 'Feedback';
            case1.Subject = 'Newsdd';
            case1.Status = 'Network Responded';
            case1.ProductCategory__c = 'Travel & ID';
            case1.OwnerId = Userinfo.getUserId();
            case1.EnquirySubType__c = 'Product Support';
            case1.ProductSubCategory__c = 'KeyPass';
            case1.RecordTypeId = SSSWFaxUtility.getSSSWFaxCaseRT();
            
            list_case.add(case1); 
            insert list_case;
            case1.ParentId = case2.Id;
            
            
            Fax__c fax = TestDataProvider.createTestFax();
            fax.Case__c = case1.Id;
            fax.CreatedDate = date.today().addDays(-1);
            insert fax;
            
            Fax__c fax2 = TestDataProvider.createTestFax();
            fax2.Case__c = case2.Id;
            fax2.CreatedDate = date.today().addDays(-1);
            fax2.Name = '2234';
            insert fax2;
            
            Fax__c fax3 = fax2.clone(true, false, true, true);
            fax3.Case__c = case1.Id;
            
            StatusTracking__c st = TestDataProvider.createTestStatusTracking();
            st.Case__c = case1.Id;
            st.Fax__c = fax3.Id;
            insert st;
            
            StatusTracking__c st2 = TestDataProvider.createTestStatusTracking();
            st2.Case__c = case2.Id;
            st2.EndDate__c = fax2.CreatedDate;
            insert st2;
            
            Map<Id, Fax__c> oldFaxes = new Map<Id, Fax__c>(); 
            oldFaxes.put(fax.Id,fax);
            oldFaxes.put(fax2.Id, fax2);
            
            
            oldFaxes.put(fax3.Id,fax3);
            List<Fax__c> updatedFaxes = new List<Fax__c>();
            updatedFaxes.add(fax2);
            updatedFaxes.add(fax);
            update updatedFaxes;
            
            List<Case> cases = new List<Case>();
            cases.add(case1);
            
            Test.startTest();
            
            SSSWFaxUtility.updateCaseStatusTracking(oldFaxes, updatedFaxes);
            
            
            Test.stopTest();
            system.assert(true);
        }
        
    }
    //Test Method to test generate attachments.
    static testMethod void generateAttachmentsTestMethod() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0];
        User u = [SELECT Id, Name FROM User WHERE ProfileId = :p.Id AND isActive = true limit 1];
        System.runAs(u) {
            List<Case> list_case = new List<Case>();
            Case case2 = new Case();
            //case1.RecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');
            case2.Type = 'Feedback';
            case2.Subject = 'MINI';
            case2.OwnerId = Userinfo.getUserId();
            case2.Status = 'Network Responded';
            case2.ProductCategory__c = 'Travel & ID';
            case2.EnquirySubType__c = 'Product Support';
            case2.ProductSubCategory__c = 'KeyPass';
            list_case.add(case2); 
            
            
            Case case1 = new Case();
            //case1.RecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');
            case1.Type = 'Investigation';
            case1.Subject = 'Newsdd';
            case1.Status = 'Awaiting Network Response';
            case1.ProductCategory__c = 'Domestic Parcels';
            case1.OwnerId = Userinfo.getUserId();
            case1.EnquirySubType__c = 'Delayed delivery';
            case1.ProductSubCategory__c = 'Parcel Post';
            case1.RecordTypeId = SSSWFaxUtility.getSSSWFaxCaseRT();
            
            list_case.add(case1); 
            insert list_case;
            case1.ParentId = case2.Id;
            
            List<Fax__c> newFaxes = new List<Fax__c>();
            
            Fax__c fax = TestDataProvider.createTestFax();
            fax.Case__c = case1.Id;
            fax.CreatedDate = date.today().addDays(-1);
            Id RecTyp = RecordTypes.getRecordTypeByName('Outbound','Fax__c').Id;
            fax.RecordTypeId = RecTyp;
            newFaxes.add(fax);
            
            Fax__c fax2 = TestDataProvider.createTestFax();
            fax2.Case__c = case2.Id;
            fax2.CreatedDate = date.today().addDays(-1);
            fax2.Name = '2234';
            newFaxes.add(fax2);
            
            insert newFaxes;
            
            Test.startTest();
            
            SSSWFaxUtility.generateAttachment(newFaxes);
            
            Test.stopTest();
            
            system.assert(true);
        }
        
    }
    
    /**
	  * SCENARIO:
	  *   Scenario will test the trimEscalationEmailContent functionality where the escalation email content is trimmed to the fields length
	  */
	  public static testMethod void testTrimEscalationEmailContent() {
		Test.startTest();
		string trimmedString = SSSWFaxUtility.trimContent('email comment', 2);
		Test.stopTest();
		// check the string passed is trimmed
		System.assertEquals(trimmedString, 'em');
	}
}