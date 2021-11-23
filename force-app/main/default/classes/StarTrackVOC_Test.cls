/**
 ** Description: Test Class for StarTrackVOCEnquiryCalculation, StarTrackVOCEnquiryDueDateCalculation, StarTrackVOCIncidentCalculation class
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: March 7, 2016
 ** History:--------------------------------------------
 **         March 7, 2016 David Catindoy - Created
 **/
@isTest
private class StarTrackVOC_Test {
    @testSetup static void testSetup(){
        StarTrack_Settings__c cs = new StarTrack_Settings__c();
        cs.Number_of_Hours_per_Business_Days__c = 10;
        cs.Number_of_Business_Days__c = 10;
        cs.StarTrack_Related_Contact_RecType_Id__c = Schema.SObjectType.AuthorisedContacts__c.getRecordTypeInfosByName().get('StarTrack Related Contact').getRecordTypeId();
        INSERT cs;
        
        BusinessHours stdBusinessHours = [SELECT Id from BusinessHours WHERE Name = 'Default'];
        
        Network__c testNetwork = TestDataProvider.createNetwork('Test Network', 1)[0];
        INSERT testNetwork;
        
        Case testVOCCase = new Case();
        testVOCCase.Status = 'New';
        testVOCCase.Subject = 'Test VOC Enquiry';
        testVOCCase.Origin = 'Email';
        testVOCCase.Classification__c = 'Complaint';
        testVOCCase.Priority = 'Normal';
        testVOCCase.BusinessHoursId = stdBusinessHours.Id;
        testVOCCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Voice of Customer Enquiry').getRecordTypeId();
        INSERT testVOCCase;
        
        Id incidentRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Voice of Customer Incident').getRecordTypeId();
        List<Case> testVOCIncidentList = new List<Case>();
        testVOCIncidentList.add(new Case(Subject = 'Test VOC 1', Description = 'Sample VOC 1', ParentId = testVOCCase.Id, Recent_Caller_First_Name__c = 'David', Recent_Caller_Last_Name__c = 'Catindoy', Parent_Status__c = 'New', Status = 'New', Business_Unit__c = 'Commercial', Nominated_Advocate_Email__c = 'david.catindoy@cloudsherpas.com', Nominated_Advocate__c = 'David', CallBackRequired__c = true, Network__c = testNetwork.Id, RecordTypeId = incidentRecType, BusinessHoursId = stdBusinessHours.Id));
        testVOCIncidentList.add(new Case(Subject = 'Test VOC 2', Description = 'Sample VOC 2', ParentId = testVOCCase.Id, Recent_Caller_First_Name__c = 'April', Recent_Caller_Last_Name__c = 'Cervantes', Parent_Status__c = 'New', Status = 'Closed', ResolutionCode__c = 'Apology', Business_Unit__c = 'Commercial', Nominated_Advocate_Email__c = 'david.catindoy@cloudsherpas.com', Nominated_Advocate__c = 'Patrick', CallBackRequired__c = true, Network__c = testNetwork.Id, RecordTypeId = incidentRecType, BusinessHoursId = stdBusinessHours.Id));
        INSERT testVOCIncidentList;
    }
    @isTest static void testVOCEnquiry(){
        Case caseRec = [SELECT Id FROM Case WHERE Subject = 'Test VOC Enquiry']; 
        
        Test.startTest();
            StarTrackVOCEnquiryCalculation.VOCEnquiryCalculation(new List<Id>{caseRec.Id});
        Test.stopTest();
        
        caseRec = [SELECT Id, Number_of_Open_VOC_Incidents__c, Number_of_VOC_Incidents__c FROM Case WHERE Id = :caseRec.Id];
        System.assertEquals(1, caseRec.Number_of_Open_VOC_Incidents__c);
        System.assertEquals(2, caseRec.Number_of_VOC_Incidents__c);
    }
    
    @isTest static void testVOCEnquiryDueDate(){
        Case caseRec = [SELECT Id FROM Case WHERE Subject = 'Test VOC Enquiry']; 
        StarTrack_Settings__c cs = StarTrack_Settings__c.getOrgDefaults();
        
        Test.startTest();
            StarTrackVOCEnquiryDueDateCalculation.VOCEnquiryDueDateCalculation(new List<Id>{caseRec.Id});
        Test.stopTest();
        
        caseRec = [SELECT Id, Number_of_Open_VOC_Incidents__c, Number_of_VOC_Incidents__c, BusinessHoursId, Due_Date__c, CreatedDate FROM Case WHERE Id = :caseRec.Id];
        System.assertEquals(Date.valueOf(BusinessHours.add(caseRec.BusinessHoursId, caseRec.CreatedDate, (3600000 * Integer.valueOf(cs.Number_of_Hours_per_Business_Days__c*cs.Number_of_Business_Days__c))).format('yyyy-MM-dd HH:mm:ss')).format(), caseRec.Due_Date__c.format());
        System.assertNotEquals(null, caseRec.BusinessHoursId);
        System.assertNotEquals(null, caseRec.Due_Date__c);
    }
    
    @isTest static void testVOCIncident(){
        Case caseRec = [SELECT Id FROM Case WHERE Status = 'New' LIMIT 1]; 
        StarTrack_Settings__c cs = StarTrack_Settings__c.getOrgDefaults();
        
        Test.startTest();
            StarTrackVOCIncidentCalculation.VOCIncidentCalculation(new List<Id>{caseRec.Id});
            caseRec = [SELECT Id, BusinessHoursId, CreatedDate, Due_Date__c FROM Case WHERE Id = :caseRec.Id];
            System.assertEquals(Date.valueOf(BusinessHours.add(caseRec.BusinessHoursId, caseRec.CreatedDate, (3600000 * Integer.valueOf(cs.Number_of_Hours_per_Business_Days__c*5))).format('yyyy-MM-dd HH:mm:ss')).format(), caseRec.Due_Date__c.format());
            
            caseRec.Priority = 'High';
            update caseRec;
            StarTrackVOCIncidentCalculation.VOCIncidentCalculation(new List<Id>{caseRec.Id});
            caseRec = [SELECT Id, BusinessHoursId, CreatedDate, Due_Date__c FROM Case WHERE Id = :caseRec.Id];
            System.assertEquals(Date.valueOf(BusinessHours.add(caseRec.BusinessHoursId, caseRec.CreatedDate, (3600000 * Integer.valueOf(cs.Number_of_Hours_per_Business_Days__c*3))).format('yyyy-MM-dd HH:mm:ss')).format(), caseRec.Due_Date__c.format());
            
            caseRec.Priority = 'Urgent';
            update caseRec;
            StarTrackVOCIncidentCalculation.VOCIncidentCalculation(new List<Id>{caseRec.Id});
            caseRec = [SELECT Id, BusinessHoursId, CreatedDate, Due_Date__c FROM Case WHERE Id = :caseRec.Id];
            System.assertEquals(Date.valueOf(BusinessHours.add(caseRec.BusinessHoursId, caseRec.CreatedDate, (3600000 * Integer.valueOf(cs.Number_of_Hours_per_Business_Days__c))).format('yyyy-MM-dd HH:mm:ss')).format(), caseRec.Due_Date__c.format());
            
            caseRec.Priority = 'Critical';
            update caseRec;
            StarTrackVOCIncidentCalculation.VOCIncidentCalculation(new List<Id>{caseRec.Id});
        Test.stopTest();
        
        caseRec = [SELECT Id, BusinessHoursId, CreatedDate, Due_Date__c FROM Case WHERE Id = :caseRec.Id];
        System.assertEquals(Date.valueOf(BusinessHours.add(caseRec.BusinessHoursId, caseRec.CreatedDate, (3600000 * Integer.valueOf(cs.Number_of_Hours_per_Business_Days__c))).format('yyyy-MM-dd HH:mm:ss')).format(), caseRec.Due_Date__c.format());
    }
}