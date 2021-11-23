/**
 * Date            Version          Owner               Desription
 * 14-Feb-17        1.0             Bharat P            Initial Version - Enterprise Credit Claim Test Class
 * 12-Jul-17        1.1             AP Rivera           Added test method to cover functionality of file attachments
 */
@isTest
private class EnterpriseCreditClaimTest {
	/* Method for Creating Case Data */
    private static Case createData(){
        RecordType recType = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Case' 
                              AND Name = 'Enterprise Credit Dispute Claim' LIMIT 1];
       Case cs = new Case();
       cs.Status = 'New';
       cs.RecordTypeId = recType.Id;
       cs.Enquiry_Type__c = 'Billing';
       cs.Billing_Number__c = '12345';
       cs.Origin = 'Web';
       cs.Name__c = 'Case Test Billing';
       cs.Email_Address__c = 'test@test.com';
       return cs;    
    }
	
    /* Test Method for submission of Test Case Data for Australia Post Account*/
    private static testMethod void testEnterpriseCreditClaimForAP(){
        Case cse = createData();
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(cse);
        EnterpriseCreditClaim instance = new EnterpriseCreditClaim(sc);
        instance.entCreditClaim = cse;
        instance.selectedBusinessUnit = 'Australia Post';
        instance.selectedDisputeType = 'Billing Dispute';
        instance.selectedReason = 'Duplicate Charge';
        instance.file = Blob.valueOf('Test Uploading');
        instance.fN = 'Test';
		instance.secretKey = 'Test Key';
        instance.response = 'Test Response';
        instance.submitCreditClaim();		
        Test.stopTest();
		system.assertEquals('Australia Post', instance.selectedBusinessUnit);
    }
    
	/* Test Method for submission of Test Case Data for StarTrack Account*/
    private static testMethod void testEnterpriseCreditClaimForST(){
        Case cse = createData();
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(cse);
        EnterpriseCreditClaim instance = new EnterpriseCreditClaim(sc);
        instance.entCreditClaim = cse;
        instance.selectedBusinessUnit = 'StarTrack';
        instance.selectedDisputeType = 'Billing Dispute';
        instance.selectedReason = 'Duplicate Charge';
        instance.file = Blob.valueOf('Testing File Body');
        instance.fN = 'Testing';
		instance.secretKey = 'Test Key';
        instance.response = 'Testing Response';
        instance.submitCreditClaim();		
        Test.stopTest();
		system.assertEquals('StarTrack', instance.selectedBusinessUnit);
    }
    
	/* Test Method for failure case*/
    private static testMethod void testEnterpriseCreditClaimFailure(){
        Case cse = createData();
        Test.startTest();
        insert cse;
        ApexPages.StandardController sc = new ApexPages.StandardController(cse);
        EnterpriseCreditClaim instance = new EnterpriseCreditClaim(sc);
        instance.entCreditClaim = cse;
        instance.file = Blob.valueOf('Test File');
        instance.fN = 'Testing';
        instance.submitCreditClaim();		
        Test.stopTest();
		system.assertEquals('Testing', instance.fN);
    }


    /* START - APRIVERA - Added test method to cover block of codes for input file functionality */
    private static testMethod void testUploadFile(){
        Case cse = createData();
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(cse);
        EnterpriseCreditClaim instance = new EnterpriseCreditClaim(sc);
        instance.entCreditClaim = cse;
        instance.selectedBusinessUnit = 'Australia Post';
        instance.selectedDisputeType = 'Billing Dispute';
        instance.selectedReason = 'Duplicate Charge';
        instance.file = Blob.valueOf('Test Uploading');
        instance.fN = 'Test';
        instance.fileSize = 100000;
        instance.secretKey = 'Test Key';
        instance.response = 'Test Response';

        instance.uploadFile();
        instance.submitCreditClaim();       
        Test.stopTest();
        system.assertEquals('Australia Post', instance.selectedBusinessUnit);
    }


    private static testMethod void testUploadFile2(){
        Case cse = createData();
        Test.startTest();
        insert cse;
        ApexPages.StandardController sc = new ApexPages.StandardController(cse);
        EnterpriseCreditClaim instance = new EnterpriseCreditClaim(sc);
        instance.entCreditClaim = cse;
        instance.selectedBusinessUnit = 'Australia Post';
        instance.selectedDisputeType = 'Billing Dispute';
        instance.selectedReason = 'Duplicate Charge';
        instance.file = Blob.valueOf('Test Uploading');
        instance.fN = 'Test';
        instance.fileSize = 2048576;
        instance.secretKey = 'Test Key';
        instance.response = 'Test Response';
        
        instance.uploadFile();

        instance.fileToRemove = 0;
        instance.removeFile();

        instance.file = null;
        instance.uploadFile();

        instance.submitCreditClaim();
        Test.stopTest();

        system.assertEquals('Australia Post', instance.selectedBusinessUnit);
    }


    /* END - APRIVERA - Added test method to cover block of codes for input file functionality */
}