/**
* @author Ranjeewa Silva
* @date 2021-06-03
* @description Batch class for sending email notifications on Credit Approval Matrix updates. Notifications are delivered
 *             nightly (outside of business hours) to cover Credit Approval Matrix records updated during the day.
 *             Users who should get the notification are configured as DIRECT members of the public group.
* @changelog
* 2021-06-03 - Ranjeewa Silva - Created.
*/
public with sharing class NotifyCreditAppMatrixUpdatesBatchable implements Database.Batchable<SObject>, Database.Stateful, System.Schedulable {

    // default batch size
    @TestVisible private static final Integer DEFAULT_BATCH_SIZE = 10;
    // default public group name with recipients
    @TestVisible private static final String DEFAULT_RECIPIENTS_PUBLIC_GROUP_NAME = 'Credit_Approval_Matrix_Update_Alerts';
    // default email template name
    @TestVisible private static final String DEFAULT_EMAIL_TEMPLATE_DEVELOPER_NAME = 'Credit_Approval_Matrix_Updated';
    // default email subject
    @TestVisible private static final String DEFAULT_EMAIL_SUBJECT = 'ATTENTION: Credit Approval Matrix updated';
    // default from email address
    @TestVisible private static final String DEFAULT_FROM_EMAIL_ADDRESS = 'noreply@auspost.com.au';

    // batch size to use.
    private Integer batchSize;
    // name of the email template.
    private String emailTemplateName;
    // name of the public group where all recipients are configured
    private String recipientsPublicGroupDeveloperName;
    // email subject
    private String emailSubject;

    // application logs collected during execution.
    private List<Application_Log__c> applicationLogs = new List<Application_Log__c>();

    private EmailTemplate template {
        get {
            if (template == null) {
                EmailTemplatesSelector selector = EmailTemplatesSelector.newInstance(1);
                Map<Id, EmailTemplate> templates = selector.selectByDeveloperName(emailTemplateName);
                if (!templates.isEmpty()) {
                    template = templates.values()[0];
                }
            }
            return template;
        }
        set {}
    }

    public Database.QueryLocator start(Database.BatchableContext ctx) {

        if (template == null) {
            String message = 'Email template with developer name [' + emailTemplateName + '] not found.';
            applicationLogs.add(new Application_Log__c(Debug_Level__c = 'Info', Source__c = NotifyCreditAppMatrixUpdatesBatchable.class.getName(), Source_Function__c = 'start', Reference_Information__c = 'EmailTemplate - ' + emailTemplateName, Message__c = message));
            saveApplicationLogs();
            return null;
        }

        CreditApprovalMatrixSelector selector = CreditApprovalMatrixSelector.newInstance();
        return selector.selectByLastModifiedDateQueryLocator(0, new Set<Object>());
    }

    public void execute(Database.BatchableContext ctx, List<SObject> scope) {

        try {

            List<Messaging.SingleEmailMessage> notificationEmails = new List<Messaging.SingleEmailMessage>();

            List<Id> emailRecipients = getRecipients();
            // retrieve 'noreply@auspost.com.au' orgWideEmailAddress, so that Send From Address is 'noreply@auspost.com.au'
            List<OrgWideEmailAddress> fromAddress = OrgWideEmailAddressSelector.newInstance().selectByAddress(DEFAULT_FROM_EMAIL_ADDRESS).values();

            for (CreditApprovalMatrix__c creditApprovalMatrix : (List<CreditApprovalMatrix__c>) scope) {

                Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
                emailMessage.setToAddresses(emailRecipients);
                emailMessage.setWhatId(creditApprovalMatrix.Id);
                emailMessage.saveAsActivity = false;

                // set the html body and plain text body configured in email template here. merge fields are resolved
                // by setting emailMessage.setTreatBodiesAsTemplate(true);
                // not possible to use 'setTemplateId' due to the requirement to also set 'emailMessage.setTargetObjectId()'
                // setting target object id to user do not allow setting WhatId to credit approval matrix record.
                emailMessage.setHtmlBody(template.HtmlValue);
                emailMessage.setPlainTextBody(template.Body);
                emailMessage.setSubject(emailSubject);
                emailMessage.setTreatBodiesAsTemplate(true);
                if (!fromAddress.isEmpty()) {
                    emailMessage.setOrgWideEmailAddressId(fromAddress[0].Id);
                }

                notificationEmails.add(emailMessage);
            }

            if (!notificationEmails.isEmpty()) {
                List<Messaging.SendEmailResult> results = Messaging.sendEmail(notificationEmails, false);
                for (Messaging.SendEmailResult result : results) {
                    if (!result.isSuccess()) {
                        String message = 'Email send failed. Root Cause : ' + result.errors;
                        applicationLogs.add(new Application_Log__c(Debug_Level__c = 'Info', Source__c = NotifyCreditAppMatrixUpdatesBatchable.class.getName(), Source_Function__c = 'start', Reference_Information__c = 'EmailTemplate - ' + emailTemplateName, Message__c = message));

                    }
                }
            }
        } finally {
            saveApplicationLogs();
        }
    }

    public void finish(Database.BatchableContext ctx) {
    }


    private List<Id> getRecipients() {

        GroupsSelector groupsSelector = GroupsSelector.newInstance(1);
        Map<Id, Group> publicGroups = groupsSelector.selectByDeveloperName(new Set<String>{recipientsPublicGroupDeveloperName});

        List<Id> recipientUsers = new List<Id>();

        if (!publicGroups.isEmpty()) {

            Map<Id, GroupMember> groupMembers = GroupMembersSelector.newInstance().selectByGroupIds(publicGroups.keySet());
            for (GroupMember member: groupMembers.values()) {
                if (member.UserOrGroupId != null && member.UserOrGroupId.getSobjectType() == User.SObjectType) {
                    recipientUsers.add(member.UserOrGroupId);
                }
            }
        }

        return recipientUsers;
    }

    private void saveApplicationLogs() {
        if(!applicationLogs.isEmpty()) {
            List<Database.SaveResult> results = ApplicationDatabase.getInstance().dmlInsert(applicationLogs, false);
            System.debug('log results: ' + results);
        }
        applicationLogs.clear();
    }


    public void execute(SchedulableContext schedulableContext) {
        NotifyCreditAppMatrixUpdatesBatchable batchable = new NotifyCreditAppMatrixUpdatesBatchable(this.batchSize, this.emailTemplateName, this.emailSubject, this.recipientsPublicGroupDeveloperName);
        Database.executeBatch(batchable, batchSize);
    }

    public NotifyCreditAppMatrixUpdatesBatchable() {
        // Use default values
        batchSize = DEFAULT_BATCH_SIZE;
        emailTemplateName = DEFAULT_EMAIL_TEMPLATE_DEVELOPER_NAME;
        recipientsPublicGroupDeveloperName = DEFAULT_RECIPIENTS_PUBLIC_GROUP_NAME;
        emailSubject = DEFAULT_EMAIL_SUBJECT;
    }

    public NotifyCreditAppMatrixUpdatesBatchable(Integer batchSize, String templateName, String subject, String recipientsPublicGroup) {
        this.batchSize = (batchSize != null ? batchSize : DEFAULT_BATCH_SIZE);
        this.emailTemplateName = (templateName != null ? templateName : DEFAULT_EMAIL_TEMPLATE_DEVELOPER_NAME);
        this.emailSubject = (subject != null ? subject : DEFAULT_EMAIL_SUBJECT);
        this.recipientsPublicGroupDeveloperName = (recipientsPublicGroup != null ? recipientsPublicGroup : DEFAULT_RECIPIENTS_PUBLIC_GROUP_NAME);
    }
}