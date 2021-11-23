/* @author 
 * @date 2020-12-10
 * @group Tests
 * @tag Selector
 * @tag Deal_Support_Request__c
 * @domain Core
 * @description test class for DealSupportRequestTriggerHandler
 * @changelog
 * 2020-12-10 - seth.heang@austpost.com.au - Created
 * 2021-02-26 - seth.heang@austpost.com.au - Updated Queue Routing to cover Unassigned DSR and Credit Limit Review queue scenario
 * 2021-03-15 - seth.heang@austpost.com.au - Updated Queue Routing to cover Credit Risk Team queue scenario
 */
@isTest
public class DealSupportRequestTriggerHandler_Test {
   
    /*
     * This test class is specifically for covering the code in the 'After Update' trigger for Deal Support Request Object
	*/
    private static TestMethod void DealSupportRequestTriggerCoverage(){
        // Data preparation
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, null, null, false)[0];
        insert dealSupportRequest;
        // cover the 'After Update' code in trigger
        update dealSupportRequest;
    }
    
    /*
     * This test class is covering the queue routing functionality upon submission of the DSR record, based on mapping from the SSSW_Routing Object
	*/
    private static TestMethod void CreditDSRSubmissionQueueRoutingTest() {
        Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        
        // Query Record Type ID of 'Credit_DSR_Routing' for SSSWRouting object, then create a testing SSSWRouting record
        Id recTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('SSSWRouting__c', new Set<String>{'Credit_DSR_Routing'}).values()[0].Id;
        SSSWRouting__c legalRecoveryMapping = ApplicationTestDataFactory.getSSSWRoutings(1, recTypeId, 'M12', 'seth@test.com', 'Legal Recovery Team', 'Credit Person Code', true)[0];
        SSSWRouting__c creditLimitReviewMapping = ApplicationTestDataFactory.getSSSWRoutings(1, recTypeId, '', 'seth@test.com', 'Credit Limit Review', 'Credit Limit Review', true)[0];
		SSSWRouting__c unassignedMapping = ApplicationTestDataFactory.getSSSWRoutings(1, recTypeId, '', '', 'Unassigned Credit Management Requests', 'Unassigned Credit Management Requests', true)[0];
        SSSWRouting__c creditRiskMapping = ApplicationTestDataFactory.getSSSWRoutings(1, recTypeId, '', '', 'Credit Risk Team', 'Credit Risk Team', true)[0];

        // Create a testing Group record
        Group legalRecoveryGroup = ApplicationTestDataFactory.getGroups(1,'queue', true)[0];
        legalRecoveryGroup.Name = 'Legal Recovery Team';
        
        // Create a testing Group record
        Group creditLimitGroup = ApplicationTestDataFactory.getGroups(1,'queue', true)[0];
        creditLimitGroup.Name = 'Credit Limit Review';
        
        // Create a testing Group record
        Group unassignedGroup = ApplicationTestDataFactory.getGroups(1,'queue', true)[0];
        unassignedGroup.Name = 'Unassigned Credit Management Requests';
        
        // Get the 'Unassigned_Credit_Management_Requests' queue
        Group qUnassignedDSR = GroupsSelector.newInstance().selectByGroupTypeAndDeveloperName(new Set<String>{'queue'},new Set<String>{'Unassigned_Credit_Management_Requests'}).values()[0];

        // Create the 'Credit Risk Team' queue
        Group creditRiskGroup = ApplicationTestDataFactory.getGroups(1,'queue', true)[0];
        creditRiskGroup.Name = 'Credit Risk Team';
        
        // Create a testing email template of 'Visualforce' type
        EmailTemplate emailTemplate = ApplicationTestDataFactory.getVFEmailTemplate(1, 'Credit DSR Template', 'Credit_DSR_Submission_to_queue', 'New Credit Management Request submitted :', 'htmlValue', 'body', 
        '<messaging:emailTemplate subject="New Credit Management Request submitted : {!relatedTo.Name}" renderUsingSystemContextWithoutSharing="True" recipientType="User" relatedToType="Deal_Support_Request__c">' +
         '<messaging:htmlEmailBody > <p>Hello,</p> <p>A new support request has been submitted : {!relatedTo.Name} </p> <p>Request can be reviewed by following the below link:<br/>'+
        '<apex:outputlink value="{!LEFT($Api.Partner_Server_URL_140,FIND(\'.com\',$Api.Partner_Server_URL_140)+4)+relatedTo.Id}">{!relatedTo.Name}</apex:outputlink> '+
        '<br/>or by entering support request number in global search within Salesforce.</p><p>Regards <br/>Salesforce</p></messaging:htmlEmailBody></messaging:emailTemplate>',true)[0];
        
        // Create OrgWideEmailAddress
        OrgWideEmailAddress noReplyOWA = ApplicationTestDataFactory.getOrgWideEmail(1, 'No Reply', 'noreply@auspost.com.au', true)[0];

        // setting up test data for DSR
        List<Deal_Support_Request__c> dsrLists = new List<Deal_Support_Request__c>();
        Map<Id, Deal_Support_Request__c> oldDsrMap = new Map<Id, Deal_Support_Request__c>();
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, null, null, false)[0];
        dealSupportRequest.recordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Deal_Support_Request__c', new Set<String>{'Credit_Management_Request'}).values()[0].Id;
        dealSupportRequest.Stage__c = 'New';
        dealSupportRequest.Status__c = 'Draft';
        oldDsrMap.put(dealSupportRequest.Id, dealSupportRequest);
        // Update DSR's stage and status to 'Submitted' and record type to 'Credit Management Request', to fulfill the condition of the trigger for queue routing
        dealSupportRequest.Stage__c = 'Submitted';
        dealSupportRequest.Status__c = 'Submitted';
        // Set up Worktype information and its associated field
        dealSupportRequest.Credit_Work_Type__c = 'Close billing account';
        dealSupportRequest.Customer_Request_Attached__c = 'Yes';
		dealSupportRequest.Credit_Person_Code__c = 'M12';
        // recalculate formula doesn't work when the mock record has existing mock ID
        dealSupportRequest.recalculateFormulas();
        // assign mock Id After formula calculation
        dealSupportRequest.Id = ApplicationTestDataFactory.getDealSupportRequests(1, null, null, true)[0].id;
        dsrLists.add(dealSupportRequest);
        
        // Test DSR with Work type = Credit Limit Review
        Deal_Support_Request__c dsrCreditLimitReview = dealSupportRequest.clone(false,true,true,false);
        dsrCreditLimitReview.Credit_Work_Type__c = 'Credit limit review';
        dsrCreditLimitReview.recalculateFormulas();
        dsrCreditLimitReview.Id = ApplicationTestDataFactory.getDealSupportRequests(1, null, null, true)[0].id;
        dsrLists.add(dsrCreditLimitReview);
        
        // Test DSR with Blank Credit Person Code
        Deal_Support_Request__c dsrBlankCode = dealSupportRequest.clone(false,true,true,false);
        dsrBlankCode.Credit_Person_Code__c = '';
        dsrBlankCode.recalculateFormulas();
        dsrBlankCode.Id = ApplicationTestDataFactory.getDealSupportRequests(1, null, null, true)[0].id;
        dsrLists.add(dsrBlankCode);

        // Test DSR with Work type = Add lodgement point
        // More than 4 Lodgement Points => Credit Risk Team
        Deal_Support_Request__c dsrCreditRiskTeam = dealSupportRequest.clone(false,true,true,false);
        dsrCreditRiskTeam.Credit_Work_Type__c = 'Add lodgement point';
        dsrCreditRiskTeam.Lodgement_Point_Counter__c = 5;
        dsrCreditRiskTeam.recalculateFormulas();
        dsrCreditRiskTeam.Id = ApplicationTestDataFactory.getDealSupportRequests(1, null, null, true)[0].id;
        dsrLists.add(dsrCreditRiskTeam);
        
        // =====================================
		// Stubbing
		// =====================================

        DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);   
        SSSWRoutingSelector ssswRoutingSelector = (SSSWRoutingSelector)MockUtility.mockSelector(SSSWRoutingSelector.class);   
        GroupsSelector groupSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);   
        EmailTemplatesSelector emailTemplateSelector = (EmailTemplatesSelector)MockUtility.mockSelector(EmailTemplatesSelector.class);   
        OrgWideEmailAddressSelector owaSelector = (OrgWideEmailAddressSelector)MockUtility.mockSelector(OrgWideEmailAddressSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		
        
        
        // set up our responses
		MockUtility.Mocks.startStubbing();
        
        // DSR response selected by ID
        Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
        mockDsrMap.put(dsrCreditLimitReview.Id, dsrCreditLimitReview);
        mockDsrMap.put(dsrBlankCode.Id, dsrBlankCode);
        mockDsrMap.put(dsrCreditRiskTeam.Id, dsrCreditRiskTeam);
        MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset())).thenReturn(mockDsrMap);
        
        // SSSWRouting__c response selected By RecordTypeId
        Map<Id, SSSWRouting__c> mockSSSWMap = new Map<Id, SSSWRouting__c>{legalRecoveryMapping.Id => legalRecoveryMapping};
        mockSSSWMap.put(creditLimitReviewMapping.Id, creditLimitReviewMapping);
        mockSSSWMap.put(unassignedMapping.Id, unassignedMapping);
        mockSSSWMap.put(creditRiskMapping.Id, creditRiskMapping);
        MockUtility.Mocks.when(ssswRoutingSelector.selectByRecordTypeId(new set<id>{recTypeId})).thenReturn(mockSSSWMap);
        
        // Group response selected By Group Type And Group Name
        Map<Id, Group> mockGroup = new Map<Id, Group>{legalRecoveryGroup.Id => legalRecoveryGroup};
        mockGroup.put(creditLimitGroup.Id, creditLimitGroup);
        mockGroup.put(qUnassignedDSR.Id, qUnassignedDSR);
        mockGroup.put(unassignedGroup.Id, unassignedGroup);
        mockGroup.put(creditRiskGroup.Id, creditRiskGroup);
        MockUtility.Mocks.when(groupSelector.selectByGroupTypeAndName(new Set<String>{'queue'},new Set<String>{'Legal Recovery Team','Credit Limit Review', 'Credit Risk Team', 'Unassigned Credit Management Requests'})).thenReturn(mockGroup);
        MockUtility.Mocks.when(groupSelector.selectByGroupTypeAndDeveloperName(new Set<String>{'queue'},new Set<String>{'Unassigned_Credit_Management_Requests'})).thenReturn(mockGroup);
        
        // EmailTemplate response selected By Developer Name
        Map<Id, EmailTemplate> mockEmailTemplate = new Map<Id, EmailTemplate>{emailTemplate.Id => emailTemplate};
        MockUtility.Mocks.when(emailTemplateSelector.selectByDeveloperName('Credit_DSR_Submission_to_queue')).thenReturn(mockEmailTemplate);

		// OrgWideEmailAddress response selected By Email Address        
		Map<Id, OrgWideEmailAddress> mockOWA = new Map<Id, OrgWideEmailAddress>{noReplyOWA.Id => noReplyOWA};
        MockUtility.Mocks.when(owaSelector.selectByAddress('noreply@auspost.com.au')).thenReturn(mockOWA);
        
        // mock database, set response for DML update
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.stopStubbing();

        Test.startTest();
        DealSupportRequestTriggerHandler.afterUpdateHandler(dsrLists, oldDsrMap);
        DealSupportRequestTriggerHandler.creditDSR_QueueRouting(dsrLists);
        Test.stopTest();
        // Assert that the DSR owner is updated to a queue named 'Legal Recovery Team'
        System.assertEquals(mockDsrMap.values()[0].OwnerId, legalRecoveryGroup.Id, 'Expected Queue Update to Legal Recovery Team');
        // Assert that the DSR owner is updated to a queue named 'Credit Limit Review'
        System.assertEquals(mockDsrMap.values()[1].OwnerId, creditLimitGroup.Id, 'Expected Queue Update to Credit Limit Review');
        // Assert that the DSR owner is updated to a queue named 'Unassigned Credit Management Requests'
        System.assertEquals(mockDsrMap.values()[2].OwnerId, unassignedGroup.Id, 'Expected Queue Update to Unassigned Credit Management Requests');
        // Assert that the DSR owner is updated to a queue named 'Credit Risk Team'
        System.assertEquals(mockDsrMap.values()[3].OwnerId, creditRiskGroup.Id, 'Expected Queue Update to Credit Risk Team');
        // Check if the DSR record has been updated once
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
    }
    
    /*
     * This test class is covering the queue routing functionality upon submission of the DSR record, based on mapping from the SSSW_Routing Object
	*/
    private static TestMethod void CreditDSRSubmissionInvalidCreditPersonCode() {
        Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        
        // Query Record Type ID of 'Credit_DSR_Routing' for SSSWRouting object, then create a testing SSSWRouting record
        Id recTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('SSSWRouting__c', new Set<String>{'Credit_DSR_Routing'}).values()[0].Id;
        SSSWRouting__c creditDSRQueueMapping = ApplicationTestDataFactory.getSSSWRoutings(1, recTypeId, 'M12', 'seth@test.com', 'Legal Recovery Team', 'Credit Person Code', true)[0];
        
        // Get the 'Unassigned_Credit_Management_Requests' queue
        Group qUnassignedDSR = GroupsSelector.newInstance().selectByGroupTypeAndDeveloperName(new Set<String>{'queue'},new Set<String>{'Unassigned_Credit_Management_Requests'}).values()[0];
        
        // Create a testing email template of 'Visualforce' type
        EmailTemplate emailTemplate = ApplicationTestDataFactory.getVFEmailTemplate(1, 'Credit DSR Template', 'Credit_DSR_Submission_to_queue', 'New Credit Management Request submitted :', 'htmlValue', 'body', 
        '<messaging:emailTemplate subject="New Credit Management Request submitted : {!relatedTo.Name}" renderUsingSystemContextWithoutSharing="True" recipientType="User" relatedToType="Deal_Support_Request__c">' +
         '<messaging:htmlEmailBody > <p>Hello,</p> <p>A new support request has been submitted : {!relatedTo.Name} </p> <p>Request can be reviewed by following the below link:<br/>'+
        '<apex:outputlink value="{!LEFT($Api.Partner_Server_URL_140,FIND(\'.com\',$Api.Partner_Server_URL_140)+4)+relatedTo.Id}">{!relatedTo.Name}</apex:outputlink> '+
        '<br/>or by entering support request number in global search within Salesforce.</p><p>Regards <br/>Salesforce</p></messaging:htmlEmailBody></messaging:emailTemplate>',true)[0];
        
        // Create OrgWideEmailAddress
        OrgWideEmailAddress noReplyOWA = ApplicationTestDataFactory.getOrgWideEmail(1, 'No Reply', 'noreply@auspost.com.au', true)[0];
        
        // setting up test data for DSR
        List<Deal_Support_Request__c> dsrLists = new List<Deal_Support_Request__c>();
        Map<Id, Deal_Support_Request__c> oldDsrMap = new Map<Id, Deal_Support_Request__c>();
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, false)[0];
        dealSupportRequest.recordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Deal_Support_Request__c', new Set<String>{'Credit_Management_Request'}).values()[0].Id;
        dealSupportRequest.Stage__c = 'New';
        dealSupportRequest.Status__c = 'Draft';
        oldDsrMap.put(dealSupportRequest.Id, dealSupportRequest);
        // Update DSR's stage and status to 'Submitted' and record type to 'Credit Management Request', to fulfill the condition of the trigger for queue routing
        dealSupportRequest.Stage__c = 'Submitted';
        dealSupportRequest.Status__c = 'Submitted';
        // Set up Worktype information and its associated field
        dealSupportRequest.Credit_Work_Type__c = 'Close billing account';
        dealSupportRequest.Customer_Request_Attached__c = 'Yes';
		dealSupportRequest.Credit_Person_Code__c = 'INVALID';
        // recalculate formula doesn't work when the mock record has existing mock ID
        dealSupportRequest.recalculateFormulas();
        // assign mock Id After formula calculation
        dealSupportRequest.Id = ApplicationTestDataFactory.getDealSupportRequests(1, null, null, true)[0].id;
        dsrLists.add(dealSupportRequest);

        
        // =====================================
		// Stubbing
		// =====================================

        DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);   
        SSSWRoutingSelector ssswRoutingSelector = (SSSWRoutingSelector)MockUtility.mockSelector(SSSWRoutingSelector.class);   
        GroupsSelector groupSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);   
        EmailTemplatesSelector emailTemplateSelector = (EmailTemplatesSelector)MockUtility.mockSelector(EmailTemplatesSelector.class);   
        OrgWideEmailAddressSelector owaSelector = (OrgWideEmailAddressSelector)MockUtility.mockSelector(OrgWideEmailAddressSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        
        // set up our responses
		MockUtility.Mocks.startStubbing();
        
        // DSR response selected by ID
        Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
        MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset())).thenReturn(mockDsrMap);
        
        // SSSWRouting__c response selected By RecordTypeId
        Map<Id, SSSWRouting__c> mockSSSWMap = new Map<Id, SSSWRouting__c>{creditDSRQueueMapping.Id => creditDSRQueueMapping};
        MockUtility.Mocks.when(ssswRoutingSelector.selectByRecordTypeId(new set<id>{recTypeId})).thenReturn(mockSSSWMap);
		
        // Group response selected By Group Type And Group Name
        Map<Id, Group> mockGroup = new Map<Id, Group>{qUnassignedDSR.id => qUnassignedDSR};
        MockUtility.Mocks.when(groupSelector.selectByGroupTypeAndDeveloperName(new Set<String>{'queue'},new Set<String>{'Unassigned_Credit_Management_Requests'})).thenReturn(mockGroup);

        
        // EmailTemplate response selected By Developer Name
        Map<Id, EmailTemplate> mockEmailTemplate = new Map<Id, EmailTemplate>{emailTemplate.Id => emailTemplate};
        MockUtility.Mocks.when(emailTemplateSelector.selectByDeveloperName('Credit_DSR_Submission_to_queue')).thenReturn(mockEmailTemplate);

		// OrgWideEmailAddress response selected By Email Address        
		Map<Id, OrgWideEmailAddress> mockOWA = new Map<Id, OrgWideEmailAddress>{noReplyOWA.Id => noReplyOWA};
        MockUtility.Mocks.when(owaSelector.selectByAddress('noreply@auspost.com.au')).thenReturn(mockOWA);
        
        // mock database, set response for DML update
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.stopStubbing();

        Test.startTest();
        DealSupportRequestTriggerHandler.afterUpdateHandler(dsrLists, oldDsrMap);
        DealSupportRequestTriggerHandler.creditDSR_QueueRouting(dsrLists);
        Test.stopTest();
        // Assert that the Invalid Credit Person Code flag set to True
        System.assertEquals(mockDsrMap.values()[0].Invalid_Credit_Person_Code__c, true, 'Expected Invalid Credit Person Code flag set to True');
		// Assert that the DSR owner is updated to a queue named 'Unassigned Credit Management Requests'
		System.assertEquals(mockDsrMap.values()[0].OwnerId, qUnassignedDSR.Id, 'Expected Queue Update to Unassigned Credit Management Requests');
        // Check if the DSR record has been updated once
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
    }
}