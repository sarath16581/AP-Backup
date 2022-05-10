/****************************************************************************************
	@author: Victor Cheng
	@description:  Test class to cover CaseTriggerHelper.sendClosureEmails() functionality
    @history:
-----------------------------------------------------------------------------------------
21-05-2020     vcheng@salesforce.com            Test class created
21-07-2020     seth.heang@auspost.com.au 		STP2240/STP2242: Update test classes to validate outbound email sent when the case is closed
*****************************************************************************************/
@isTest
public class BGSCase_Test {
	
    /**
     * @description: Test send outbound email functionality when the BGS case is 'closed'
     */
    testMethod
    public static void TestCaseClosure()
    {
        // create an organisation
        // Setup the Entitlement Organisation
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Account testAccount = TestUtility.createBusinessAccount('Minor Works',
                accRecTypeMap.get('Organisation').getRecordTypeId());
        Database.insert(testAccount);

        String contactEmail = 'test@123.com';

        // create a contact
        Contact con = TestUtility.createContact('Test','Tester',contactEmail, testAccount.Id);
        con.MailingState = 'VIC';
        con.MailingPostalCode = '3000';
        insert con;

        // create a BGS Case
        Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
        Id serviceDeliveryRT = caseRecTypeMap.get(BGSConstants.SERVICE_DELIVERY_NAME).getRecordTypeId();
        Case csRec = TestUtility.createCase('Enquiry', 'In Progress', 'General Enquiry', testAccount.Id, con.Id, serviceDeliveryRT);
        csRec.Product_Type__c = 'Domestic Parcels';
        csRec.Work_Type__c = 'Account Info';
        csRec.Support_Work_Type__c = 'New Account';
        insert csRec;
        
        Case csRec2 = TestUtility.createCase('Enquiry', 'In Progress', 'General Enquiry', testAccount.Id, con.Id, serviceDeliveryRT);
        csRec2.Product_Type__c = 'Domestic Parcels';
        csRec2.Work_Type__c = 'Account Info';
        csRec2.Support_Work_Type__c = 'New Account';
        insert csRec2;

        // close the case
        Test.startTest();

        csRec.Status = 'Closed';
        csRec.ResolutionCode__c = 'Assistance Provided';
        csRec.Type = 'General Enquiry';
        csRec.ProductCategory__c = 'Domestic Parcels';
        csRec.ProductSubCategory__c = 'eParcel';
        csRec.EnquirySubType__c = 'Tracking';
        update csRec;

        // Assert that an email is sent, when the case is "closed" and the resolution code is not 'Closed - Duplicate'
        System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent upon case closure');
        
        csRec2.Status = 'Closed';
        csRec2.ResolutionCode__c = 'Closed - Duplicate';
        csRec.Type = 'General Enquiry';
        csRec.ProductCategory__c = 'Domestic Parcels';
        csRec.ProductSubCategory__c = 'eParcel';
        csRec.EnquirySubType__c = 'Tracking';
        update csRec2;
        // Assert that No email is sent when the "closed" case has resolution code as 'Closed - Duplicate'
        System.assertEquals(1, Limits.getEmailInvocations(), 'No email should be sent, so email log remain 1 due to duplicate reason');
        
        // send an inbound email
        List <EmailMessage> inboundEmails = new List<EmailMessage>();
        EmailMessage emailToClosedCase = new EmailMessage();
        emailToClosedCase.FromAddress = contactEmail;
        emailToClosedCase.Incoming = true;
        emailToClosedCase.ToAddress = '';
        emailToClosedCase.Subject = 'Testing Email';
        emailToClosedCase.TextBody = 'Testing Email Body';
        emailToClosedCase.ParentId = csRec.Id;

        inboundEmails.add(emailToClosedCase);
        insert inboundEmails;
		
        Test.stopTest();
        
       	List<EmailMessage> closureAlertEmail = [Select id, FromName, FromAddress 
                                         From EmailMessage 
                                         Where ParentId =: csRec.Id
                                               And Incoming = false Limit 1];
        // Assert that the outbound email for "Closed" Case, was sent from 'No Reply' AusPost Email
        System.assertEquals('No Reply', closureAlertEmail[0].FromName, 'From Name should be No Reply');
        System.assertEquals('noreply@auspost.com.au', closureAlertEmail[0].FromAddress, 'From Address should be noreply@auspost.com.au');
        
        List<EmailMessage> closureDuplicateEmail = [Select id, FromName, FromAddress 
                                         From EmailMessage 
                                         Where ParentId =: csRec2.Id Limit 1];
        // Assert that there is no outbound email if the case is closed due to duplicate
        System.assertEquals(closureDuplicateEmail.size(), 0, 'No email should be sent when resolution code is duplicate');
    }
}