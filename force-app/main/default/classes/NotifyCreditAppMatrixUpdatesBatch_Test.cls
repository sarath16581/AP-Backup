/***
 * @author Ranjeewa Silva
 * @date 2021-06-18
 * @group Tests
 * @tag CustomerResolutions, Tests
 * @description Test Scenarios for notifying credit approval matrix updates.
 * @changelog
 * 2021-06-18 - Ranjeewa Silva - Created.
 */

@IsTest
private class NotifyCreditAppMatrixUpdatesBatch_Test {

    @IsTest
    static void testBatchStart() {
        // =====================================
        // Data Preparation
        // =====================================
        Map<Id, EmailTemplate> emailTemplates = new Map<Id, EmailTemplate>(ApplicationTestDataFactory.getVFEmailTemplate(1, 'test', 'test', 'test', '<html></html>', 'test', 'test', true));

        // =====================================
        // Stubbing
        // =====================================
        EmailTemplatesSelector mockTemplatesSelector = (EmailTemplatesSelector) MockUtility.mockSelector(EmailTemplatesSelector.class);
        CreditApprovalMatrixSelector mockCreditApprovalMatrixSelector = (CreditApprovalMatrixSelector) MockUtility.mockSelector(CreditApprovalMatrixSelector.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockTemplatesSelector.selectByDeveloperName((String)fflib_Match.eq(NotifyCreditAppMatrixUpdatesBatchable.DEFAULT_EMAIL_TEMPLATE_DEVELOPER_NAME))).thenReturn(emailTemplates);
        MockUtility.Mocks.when(mockCreditApprovalMatrixSelector.selectByLastModifiedDateQueryLocator((Integer)fflib_Match.anyInteger(), (Set<Object>)fflib_Match.anyObject())).thenReturn(null);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        NotifyCreditAppMatrixUpdatesBatchable batch = new NotifyCreditAppMatrixUpdatesBatchable();
        batch.start(null);

        Test.stopTest();

        //verify that EmailTemplatesSelector is called once
        ((EmailTemplatesSelector) MockUtility.Mocks.verify(mockTemplatesSelector, MockUtility.Mocks.times(1))).selectByDeveloperName((String)fflib_Match.eq(NotifyCreditAppMatrixUpdatesBatchable.DEFAULT_EMAIL_TEMPLATE_DEVELOPER_NAME));

        //verify that CreditApprovalMatrixSelector is called once to get the query locator
        ((CreditApprovalMatrixSelector) MockUtility.Mocks.verify(mockCreditApprovalMatrixSelector, MockUtility.Mocks.times(1))).selectByLastModifiedDateQueryLocator((Integer)fflib_Match.anyInteger(), (Set<Object>)fflib_Match.anyObject());
    }

    @IsTest
    static void testBatchStartWhenEmailTemplateNotAvailable() {
        // =====================================
        // Data Preparation
        // =====================================
        // None

        // =====================================
        // Stubbing
        // =====================================
        EmailTemplatesSelector mockTemplatesSelector = (EmailTemplatesSelector) MockUtility.mockSelector(EmailTemplatesSelector.class);
        CreditApprovalMatrixSelector mockCreditApprovalMatrixSelector = (CreditApprovalMatrixSelector) MockUtility.mockSelector(CreditApprovalMatrixSelector.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockTemplatesSelector.selectByDeveloperName((String)fflib_Match.eq('invalidtemplate'))).thenReturn(new Map<Id,EmailTemplate>());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        NotifyCreditAppMatrixUpdatesBatchable batch = new NotifyCreditAppMatrixUpdatesBatchable(5, 'invalidtemplate', 'test', 'test');
        batch.start(null);

        Test.stopTest();

        //verify that EmailTemplatesSelector is called once
        ((EmailTemplatesSelector) MockUtility.Mocks.verify(mockTemplatesSelector, MockUtility.Mocks.times(1))).selectByDeveloperName((String)fflib_Match.eq('invalidtemplate'));

        //verify that CreditApprovalMatrixSelector is not called
        ((CreditApprovalMatrixSelector) MockUtility.Mocks.verify(mockCreditApprovalMatrixSelector, MockUtility.Mocks.times(0))).selectByLastModifiedDateQueryLocator((Integer)fflib_Match.anyInteger(), (Set<Object>)fflib_Match.anyObject());
    }

    @IsTest
    static void testBatchExecute() {
        // =====================================
        // Data Preparation
        // =====================================
        Map<Id, EmailTemplate> emailTemplates = new Map<Id, EmailTemplate>(ApplicationTestDataFactory.getVFEmailTemplate(1, 'test', 'test', 'test', '<html></html>', 'test', 'test', true));

        List<CreditApprovalMatrix__c> creditApprovalMatrixRecords = ApplicationTestDataFactory.getCreditApprovalMatrixRecords(3, true, 'Discretionary Credit', 'test', 'test');

        Map<Id, Group> notificationRecipientPublicGroups = new Map<Id, Group>(ApplicationTestDataFactory.getGroups(1, 'Regular', true));
        Map<Id, User> notificationRecipients = new Map<Id, User>(ApplicationTestDataFactory.getUsers(5, true));

        List<Id> groupIdsForGroupMembers = new List<Id>{notificationRecipientPublicGroups.values()[0].Id, notificationRecipientPublicGroups.values()[0].Id, notificationRecipientPublicGroups.values()[0].Id, notificationRecipientPublicGroups.values()[0].Id, notificationRecipientPublicGroups.values()[0].Id};
        Map<Id, GroupMember> notificationRecipientGroupMembers = new Map<Id, GroupMember>(ApplicationTestDataFactory.getGroupMembers(5, groupIdsForGroupMembers, new List<Id>(notificationRecipients.keySet()), true));

        // =====================================
        // Stubbing
        // =====================================
        EmailTemplatesSelector mockTemplatesSelector = (EmailTemplatesSelector) MockUtility.mockSelector(EmailTemplatesSelector.class);
        GroupsSelector mockGroupsSelector = (GroupsSelector) MockUtility.mockSelector(GroupsSelector.class);
        GroupMembersSelector mockGroupMembersSelector = (GroupMembersSelector) MockUtility.mockSelector(GroupMembersSelector.class);
        OrgWideEmailAddressSelector mockOrgWideEmailAddressSelector = (OrgWideEmailAddressSelector) MockUtility.mockSelector(OrgWideEmailAddressSelector.class);

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockTemplatesSelector.selectByDeveloperName((String)fflib_Match.eq(NotifyCreditAppMatrixUpdatesBatchable.DEFAULT_EMAIL_TEMPLATE_DEVELOPER_NAME))).thenReturn(emailTemplates);
        MockUtility.Mocks.when(mockGroupsSelector.selectByDeveloperName((Set<String>)fflib_Match.anyObject())).thenReturn(notificationRecipientPublicGroups);
        MockUtility.Mocks.when(mockGroupMembersSelector.selectByGroupIds((Set<Id>)fflib_Match.eq(notificationRecipientPublicGroups.keySet()))).thenReturn(notificationRecipientGroupMembers);
        MockUtility.Mocks.when(mockOrgWideEmailAddressSelector.selectByAddress((String)fflib_Match.anyString())).thenReturn(new Map<Id,OrgWideEmailAddress>());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        NotifyCreditAppMatrixUpdatesBatchable batch = new NotifyCreditAppMatrixUpdatesBatchable();
        batch.execute(null, creditApprovalMatrixRecords);

        Test.stopTest();

        //verify that EmailTemplatesSelector is called once
        ((EmailTemplatesSelector) MockUtility.Mocks.verify(mockTemplatesSelector, MockUtility.Mocks.times(1))).selectByDeveloperName((String)fflib_Match.eq(NotifyCreditAppMatrixUpdatesBatchable.DEFAULT_EMAIL_TEMPLATE_DEVELOPER_NAME));

        //verify that GroupsSelector is called once
        ((GroupsSelector) MockUtility.Mocks.verify(mockGroupsSelector, MockUtility.Mocks.times(1))).selectByDeveloperName((Set<String>)fflib_Match.anyObject());

        //verify that GroupMembersSelector is called once
        ((GroupMembersSelector) MockUtility.Mocks.verify(mockGroupMembersSelector, MockUtility.Mocks.times(1))).selectByGroupIds((Set<Id>)fflib_Match.eq(notificationRecipientPublicGroups.keySet()));
    }
}