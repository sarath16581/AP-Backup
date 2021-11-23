/*------------------------------------------------------------
Author:        Jen Karen Tan
Description:   Test Class for StarTrackNoDataConsignmentPAController
History
September 19, 2016        Jen Karen Tan        Created
------------------------------------------------------------*/

@isTest
private class StarTrackNoDataConsignmentPACont_Test {

    @testSetup static void testSetup(){
        
        User support = new User(
     		ProfileId = [SELECT Id FROM Profile WHERE Name = 'StarTrack Support'].Id,
     		LastName = 'last',
     		Email = 'test@user.com',
     		Username = 'test@supportuser123.com',
     		CompanyName = 'TEST',
     		Title = 'title',
     		Alias = 'alias',
     		TimeZoneSidKey = 'America/Los_Angeles',
     		EmailEncodingKey = 'UTF-8',
     		LanguageLocaleKey = 'en_US',
     		LocaleSidKey = 'en_US');
     	insert support;
     	
        List<StarTrackPicklistSettings__c> picklistSettingsList = new List<StarTrackPicklistSettings__c>();
        picklistSettingsList.add(new StarTrackPicklistSettings__c(Name = 'Delivery Type - Premium', PicklistFieldName__c = 'Delivery Type', PicklistValue__c = 'Premium'));
        picklistSettingsList.add(new StarTrackPicklistSettings__c(Name = 'Delivery Type - Express', PicklistFieldName__c = 'Delivery Type', PicklistValue__c = 'Express'));
        insert picklistSettingsList;
        
        System.runAs(support) {
            Network__c testNetwork = TestDataProvider.createTestNetwork();
            testNetwork.Preferred_Method_of_Tasking__c = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_EMAIL;
            testNetwork.ST_Email__c = true;
            testNetwork.Email__c = 'te@st.comz';
            testNetwork.State__c = 'ACT';
            testNetwork.Facility__c = 'Express';
            testNetwork.Business_Hours__c = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
            testNetwork.Email__c = 'te@st.zzz';
            testNetwork.RecordTypeId = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Metro').getRecordTypeId(); 
            insert testNetwork;
    
            Depot_Area__c testDepotArea = new Depot_Area__c();
            testDepotArea.Name = 'Test Depot Area';
            testDepotArea.Depot__c = testNetwork.Id;
            testDepotArea.Area__c = StarTrack_Constants.DEPOTAREA_AREA_BRANCHMANAGEMENT;
            insert testDepotArea;
    
            Depot_Area_User__c testDepotAreaUser = new Depot_Area_User__c();
            testDepotAreaUser.Name = 'Test Depot Area User';
            testDepotAreaUser.Depot_Role__c = testDepotArea.Id;
            testDepotAreaUser.User__c = UserInfo.getUserId();
            insert testDepotAreaUser;
    
            Article__c testArticle = TestDataProvider.createTestArticle();
            testArticle.Service_Type__c = 'Express';
            testArticle.Network__c = testNetwork.Id;
            insert testArticle;
    
            Id delEnquiryRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
            Case testCase = TestDataProvider.createTestCase();
            testCase.RecordTypeId = delEnquiryRecTypeId;
            testCase.Call_Purpose__c = 'Other';
            testCase.Enquiry_Type__c = 'POD';
            testCase.ArticleTest__c = testArticle.Id;
            testCase.Network__c = testNetwork.Id;
            insert testCase;
        }
        
    }
    
    static testMethod void testNoDataConsignment(){
        
        User support = [SELECT Id FROM User WHERE UserName = 'test@supportuser123.com'];
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(queryCase);
        StarTrackNoDataConsignmentPAController con = new StarTrackNoDataConsignmentPAController(sc);
        
        System.runAs(support) {
            
            
            Test.startTest();
            con.getDeliveryTypeValues();
            con.noDataConsignment = true;
            con.selectedDeliveryType = 'Premium';
            con.updateRecord();
            Test.stopTest();
        }
        
        //test if case is updated
        System.assertEquals(true, con.existingCase.No_Data_Change__c);
        System.assert(con.existingCase.Number_of_No_Data_Consignment_Updates__c > 0);
        System.assertEquals('Premium', con.existingCase.ArticleTest__r.Service_Type__c);
        
    }
    
    static testMethod void testErrors(){
        
        User support = [SELECT Id FROM User WHERE UserName = 'test@supportuser123.com'];
        
        System.runAs(support) {
            Case queryCase = [SELECT Id FROM Case LIMIT 1];
            ApexPages.StandardController sc = new ApexPages.StandardController(queryCase);
            StarTrackNoDataConsignmentPAController con = new StarTrackNoDataConsignmentPAController(sc);
            
            Test.startTest();
            con.getDeliveryTypeValues();
            con.noDataConsignment = true;
            con.selectedDeliveryType = '';
            con.updateRecord();
            //test error message
            System.assert(ApexPages.hasMessages());
            
            con.getDeliveryTypeValues();
            con.noDataConsignment = false;
            con.selectedDeliveryType = 'Premium';
            con.updateRecord();
            //test error message
            System.assert(ApexPages.hasMessages());
            
            Case c = con.existingCase;
            c.ArticleTest__c = null;
            update c;
            con.existingCase = c;
            con.updateRecord();
            //test error message
            System.assert(ApexPages.hasMessages());
            Test.stopTest();
        }
        
    }
}