/**************************************************
Type:       Test class for Helper class for ContractAssistanceForm__c
Purpose:    test class for helper class for ContractAssistanceFormHandler_Test.Data creation for this calsss is from ContractAssistanceFormController_Test
History:
--------------------------------------------------
07.12.2017    Clint D'Silva    Created
26.06.2018    heguang.miao@coroma.com.au    [TDO-73] Rewrote tests based on scenarios
02.06.2020    shashwat.nath@accenture.com Updated the method to set the Stagename to Identify to sync with the validation of opportunity creation in Identify stage only
**************************************************/

@isTest
class ContractAssistanceFormHandler_Test {

    @testSetup
    static void setupTestData() {

        // Get a list of record types
        List<RecordType> recordTypes = [
                SELECT
                        Id, DeveloperName, SobjectType
                FROM
                        RecordType
                WHERE
                SobjectType in ('Account', 'Task') and DeveloperName in ('Business_Account', 'Sales_Task')
        ];

        // Create the SobjectType-DeveloperName map
        Map<String, RecordType> recordTypeBySobjectName = new Map<String, RecordType>();
        for (RecordType rec : recordTypes) {
            if (!recordTypeBySobjectName.containsKey(rec.SobjectType + rec.DeveloperName)) {
                recordTypeBySobjectName.put(rec.SobjectType + rec.DeveloperName, rec);
            }
        }

        // Use current user
        User currUser = [
                SELECT
                        Id, ProfileId,
                        FirstName, LastName,
                        Email, Username, CompanyName,
                        Title, Alias, TimeZoneSidKey,
                        EmailEncodingKey, LanguageLocaleKey,
                        LocaleSidKey, UserRoleId
                FROM User
                WHERE
                        Id = :UserInfo.getUserId()
        ];

        // Create an account for the user
        Account account = new Account(
                RecordTypeId = recordTypeBySobjectName.get('AccountBusiness_Account').Id,
                Name = 'TestAccount',
                OwnerId = UserInfo.getUserId()
        );
        insert account;


        // Create an opportunity
        Opportunity opportunity = new Opportunity(
                Name = 'opp1',
                Type = 'Existing Customer',
                Offering_Type__c = 'Solutions',
                StageName = 'Identify',
                CloseDate = Date.today(),
                AccountId = account.Id,
                OwnerId = UserInfo.getUserId()
        );
        insert opportunity;

        System.runAs(currUser) {

            // Create a form. Note that the owner will be specified by the trigger and will not be of type user.
            ContractAssistanceForm__c contractAssistanceForm = new ContractAssistanceForm__c(
                    Opportunity__c = opportunity.Id,
                    Status__c = 'New',
                    Specific_Terms_and_Clauses__c = '2 free text',
                    Related_Contract_Tender__c = '3 free text',
                    DateOpened__c = Date.today(),
                    Contract_Start_Date__c = Date.today(),
                    Initial_Contract_Term__c = '1',
                    Site_of_Services__c = 'AP Site',
                    AP_IP__c = '5 free text',
                    Customer_IP__c = '6 free text',
                    New_IP__c = '7 free text',
                    Third_Party_Involvement__c = '10 free text',
                    Business_Consultation__c = '12 free text',
                    Previous_Legal_Involvement__c = '9 free text',
                    Comments__c = 'Comments__c',
                    Product_Manager_s__c = '11 free text',
                    Documents_Attached__c = false,
                    OpportunityOwner__c = opportunity.OwnerId
            );
            insert contractAssistanceForm;
            contractAssistanceForm = [SELECT Id, OwnerId FROM ContractAssistanceForm__c WHERE Id = :contractAssistanceForm.Id];
        }
    }

    /**
     * SCENARIO: Given contract assistance forms, create ContractAssistanceForm__Share objects for opportunity owners.
     */
    @isTest
    static void shareContractAssistanceFormWithOpportunityOwner_normal() {

        ContractAssistanceForm__c form = [
                SELECT
                        Id, Opportunity__c, OwnerId
                FROM
                        ContractAssistanceForm__c
                LIMIT 1
        ];

        List<ContractAssistanceForm__c> cafLst = new List<ContractAssistanceForm__c>();
        cafLst.add(form);
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            Test.startTest();
            ContractAssistanceFormHandler.shareContractAssistanceFormWithOpportunityOwner(cafLst);
            Test.stopTest();
        }

        // TODO: assertion. The original class bypasses the insertion statements if it's testing env, can't detect anything here.
    }

    /**
     * SCENARIO: Update the form without changing its owner
     */
    @isTest
    static void addContractAssistanceOwnerToOpportunityTeam_ownerUnchanged() {

        ContractAssistanceForm__c form = [
                SELECT
                        Id, Opportunity__c, OwnerId, OpportunityOwner__c
                FROM
                        ContractAssistanceForm__c
                LIMIT 1
        ];

        // Just change the comment
        form.Comments__c = 'Comments__c1';
        update form;

        // See if there's any team members created
        List<OpportunityTeamMember> insertedTeamMembers = [SELECT Id from OpportunityTeamMember];
        System.assertEquals(0, insertedTeamMembers.size(),
                'ContractAssistanceFormHandler_addContractAssistanceOwnerToOpportunityTeam_ownerUnchanged : ' +
                        'no team members will be created');
    }

    /**
     * SCENARIO: Change the form's owner, but the owner is also the opportunity owner
     */
    @isTest
    static void addContractAssistanceOwnerToOpportunityTeam_oppotunityOwnerIsFormOwner() {
        ContractAssistanceForm__c form = [
                SELECT
                        Id, Opportunity__c, OwnerId, OpportunityOwner__c
                FROM
                        ContractAssistanceForm__c
                LIMIT 1
        ];

        Test.startTest();
        // Set the owner Id to be the opportunity owner's Id
        form.OwnerId = form.OpportunityOwner__c;

        update form;
        Test.stopTest();

        // See if there's any team members created
        List<OpportunityTeamMember> insertedTeamMembers = [SELECT Id from OpportunityTeamMember];
        System.assertEquals(0, insertedTeamMembers.size(),
                'ContractAssistanceFormHandler_addContractAssistanceOwnerToOpportunityTeam_oppotunityOwnerIsFormOwner : ' +
                        'no OpportunityTeamMember should be created if the new form owner is the opportunity owner');
    }

    /**
     * SCENARIO: Change the form's owner and the owner is not the opportunity owner
     */
    @isTest
    static void addContractAssistanceOwnerToOpportunityTeam_oppotunityOwnerIsNotFormOwner() {

        User currentUser = [SELECT ID from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            ContractAssistanceForm__c form = [
                    SELECT
                            Id, Opportunity__c, OwnerId, OpportunityOwner__c
                    FROM
                            ContractAssistanceForm__c
                    LIMIT 1
            ];

            // Create a new user who is not the opportunity owner;
            User testUser = TestDataProvider.createTestUsers();
            insert testUser;

            Test.startTest();
            // Make the user the owner
            form.OwnerId = testUser.Id;
            update form;
            Test.stopTest();

            List<OpportunityTeamMember> insertedTeamMembers = [SELECT Id from OpportunityTeamMember];
            System.assertEquals(1, insertedTeamMembers.size(),
                    'ContractAssistanceFormHandler_addContractAssistanceOwnerToOpportunityTeam_oppotunityOwnerIsNotFormOwner : ' +
                            'a team member should be created if the new form owner is not the opportunity owner');
        }
    }

    /**
     * SCENARIO: Valid contract modification
     */
    @isTest
    static void validate_pass() {
        User currentUser = [SELECT ID from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            ContractAssistanceForm__c form = [
                    SELECT
                            Id, Opportunity__c, OwnerId, OpportunityOwner__c, Final_Risk_Position__c, RejectionReason__c
                    FROM
                            ContractAssistanceForm__c
                    LIMIT 1
            ];

            Test.startTest();
            // This is harmless
            form.Comments__c = 'Nothing happens';

            try {
                update form;
            } catch (Exception e) {
                System.assert(false,
                        'ContractAssistanceFormHandler_validate_pass : The validation should be successful');
            }
            Test.stopTest();
        }
    }

    /**
     * SCENARIO: Invalid form modification: a normal user is changing Final_Risk_Position__c
     */
    @isTest
    static void validate_invalidFinalRiskPosition() {
        User currentUser = [SELECT ID from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            ContractAssistanceForm__c form = [
                    SELECT
                            Id, Opportunity__c, OwnerId, OpportunityOwner__c, Final_Risk_Position__c, RejectionReason__c
                    FROM
                            ContractAssistanceForm__c
                    LIMIT 1
            ];

            Test.startTest();
            form.Final_Risk_Position__c = 'invalid';

            try {
                update form;
            } catch (Exception e) {
                System.assert(e.getMessage().contains('Final Risk Position'),
                        'normal user cannot change Final_Risk_Position__c');
            }
            Test.stopTest();
        }
    }

    /**
     * SCENARIO: Invalid form modification: a normal user is changing RejectionReason__c
     */
    @isTest
    static void ContractAssistanceFormHandler_validate_invalidRejectionReason() {
        User currentUser = [SELECT ID from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            ContractAssistanceForm__c form = [
                    SELECT
                            Id, Opportunity__c, OwnerId, OpportunityOwner__c, Final_Risk_Position__c, RejectionReason__c
                    FROM
                            ContractAssistanceForm__c
                    LIMIT 1
            ];

            Test.startTest();
            form.RejectionReason__c = 'invalid';

            try {
                update form;
            } catch (Exception e) {
                System.assert(e.getMessage().contains('Rejection Reason'),
                        'normal user cannot change RejectionReason__c');
            }
            Test.stopTest();
        }
    }

    /**
     * SCENARIO: Before insert tasks, the task's Email__c should be updated
     */
    @isTest
    static void checkAllCompletedTasks_beforeInsert() {
        User currentUser = [SELECT ID from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {

            ContractAssistanceForm__c form = [
                    SELECT
                            Id, Opportunity__c, OwnerId, OpportunityOwner__c, Final_Risk_Position__c, RejectionReason__c
                    FROM
                            ContractAssistanceForm__c
                    LIMIT 1
            ];

            // Create a new user for email purpose
            User testUser = TestDataProvider.createTestUsers();
            testUser.Email = 'contractassistance@test.com';
            insert testUser;

            // Alter the form
            form.OwnerId = testUser.Id;
            update form;

            List<Task> tasks = new List<Task>();

            // Create a task, whose email is supposed to be changed.
            Task task = new Task(
                    Subject = 'sub1',
                    Type = 'Reminder',
                    Category__c = 'Sales',
                    Status = 'Completed',
                    Priority = 'Normal',
                    WhatId = form.Id
            );

            tasks.add(task);

            Test.startTest();

            ContractAssistanceFormHandler.checkAllCompletedTasks(tasks, null, true, false, true, true);

            Test.stopTest();

            System.assertEquals('contractassistance@test.com', task.Email__c,
                    'ContractAssistanceFormHandler_checkAllCompletedTasks_beforeInsert : ' +
                            'tasks email field should be updated');
        }
    }

    /**
     * SCENARIO: close a task, but there are still open tasks for a form
     */
    @isTest
    static void checkAllCompletedTasks_afterUpdate_notAllComplete() {
        User currentUser = [SELECT ID from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            ContractAssistanceForm__c form = [
                    SELECT
                            Id, Opportunity__c, OwnerId, OpportunityOwner__c, Final_Risk_Position__c, RejectionReason__c
                    FROM
                            ContractAssistanceForm__c
                    LIMIT 1
            ];

            // Create a task that is not completed
            Task task1 = new Task(
                    Subject = 'sub1',
                    Type = 'Reminder',
                    Category__c = 'Sales',
                    Status = 'Not Started', // This marks the task is open
                    Priority = 'Normal',
                    WhatId = form.Id
            );
            insert task1;

            // Create another
            Task task2 = new Task(
                    Subject = 'sub2',
                    Type = 'Reminder',
                    Category__c = 'Sales',
                    Status = 'Not Started',
                    Priority = 'Normal',
                    WhatId = form.Id
            );
            insert task2;

            Task oldTask2 = task2.clone();

            // Close task2
            task2.Status = 'Completed';
            update task2;

            // Refresh
            task2 = [SELECT Id, Subject, Type, Category__c, State__c, Priority, WhatId, IsClosed FROM Task WHERE Id = :task2.Id];

            // There's no trigger at all. We have to manually call the method.
            List<Task> newTasks = new List<Task>();
            newTasks.add(task2);

            Map<Id, Task> oldRecordsMap = new Map<Id, Task>();
            oldRecordsMap.put(oldTask2.Id, oldTask2);

            Test.startTest();

            ContractAssistanceFormHandler.checkAllCompletedTasks(newTasks, oldRecordsMap, false, true, true, true);

            Test.stopTest();

            List<Task> reviewTasks = [SELECT Id FROM Task WHERE Subject = 'CAF Review Required' AND WhatId = :form.Id];

            System.assertEquals(0, reviewTasks.size(),
                    'ContractAssistanceFormHandler_checkAllCompletedTasks_afterUpdate_notAllComplete :' +
                            'no review tasks will be created if there is any unfinished task');
        }
    }

    /**
     * SCENARIO: close a task and all tasks for that form are closed
     */
    @isTest
    static void checkAllCompletedTasks_afterUpdate_allComplete() {
        User currentUser = [SELECT ID from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            ContractAssistanceForm__c form = [
                    SELECT
                            Id, Opportunity__c,
                            OwnerId, OpportunityOwner__c,
                            Final_Risk_Position__c, RejectionReason__c
                    FROM
                            ContractAssistanceForm__c
                    LIMIT 1
            ];

            // Create a task that is closed
            Task task1 = new Task(
                    Subject = 'sub1',
                    Type = 'Reminder',
                    Category__c = 'Sales',
                    Status = 'Completed', // This marks the task is closed
                    Priority = 'Normal',
                    WhatId = form.Id
            );
            insert task1;

            // Create another
            Task task2 = new Task(
                    Subject = 'sub2',
                    Type = 'Reminder',
                    Category__c = 'Sales',
                    Status = 'Not Started',
                    Priority = 'Normal',
                    WhatId = form.Id
            );
            insert task2;

            Task oldTask2 = task2.clone();

            // Close task2
            task2.Status = 'Completed';
            update task2;

            // Refresh
            task2 = [SELECT Id, Subject, Type, Category__c, State__c, Priority, WhatId, IsClosed FROM Task WHERE Id = :task2.Id];

            // There's no trigger at all. We have to manually call the method.
            List<Task> newTasks = new List<Task>();
            newTasks.add(task2);

            Map<Id, Task> oldRecordsMap = new Map<Id, Task>();
            oldRecordsMap.put(oldTask2.Id, oldTask2);

            Test.startTest();

            ContractAssistanceFormHandler.checkAllCompletedTasks(newTasks, oldRecordsMap, false, true, true, true);

            Test.stopTest();

            List<Task> reviewTasks = [SELECT Id FROM Task WHERE Subject = 'CAF Review Required' AND WhatId = :form.Id];

            System.assertEquals(1, reviewTasks.size(),
                    'ContractAssistanceFormHandler_checkAllCompletedTasks_afterUpdate_allComplete :' +
                            'a review tasks will be created if all other tasks are completed');
        }
    }

    /**
     * SCENARIO: close a task and there is already a review task for that form
     */
    @isTest
    static void checkAllCompletedTasks_afterUpdate_reviewTaskExists() {
        User currentUser = [SELECT ID from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            ContractAssistanceForm__c form = [
                    SELECT
                            Id, Opportunity__c,
                            OwnerId, OpportunityOwner__c,
                            Final_Risk_Position__c, RejectionReason__c
                    FROM
                            ContractAssistanceForm__c
                    LIMIT 1
            ];

            // Create a review task
            Task task1 = new Task(
                    Subject = 'CAF Review Required',
                    Type = 'Reminder',
                    Category__c = 'Sales',
                    Status = 'Not Started',
                    Priority = 'Normal',
                    WhatId = form.Id
            );
            insert task1;

            // Create a normal task
            Task task2 = new Task(
                    Subject = 'sub2',
                    Type = 'Reminder',
                    Category__c = 'Sales',
                    Status = 'Not Started',
                    Priority = 'Normal',
                    WhatId = form.Id
            );
            insert task2;

            Task oldTask2 = task2.clone();

            // Close task2
            task2.Status = 'Completed';
            update task2;

            // Refresh
            task2 = [SELECT Id, Subject, Type, Category__c, State__c, Priority, WhatId, IsClosed FROM Task WHERE Id = :task2.Id];

            // There's no trigger at all. We have to manually call the method.
            List<Task> newTasks = new List<Task>();
            newTasks.add(task2);

            Map<Id, Task> oldRecordsMap = new Map<Id, Task>();
            oldRecordsMap.put(oldTask2.Id, oldTask2);

            Test.startTest();

            ContractAssistanceFormHandler.checkAllCompletedTasks(newTasks, oldRecordsMap, false, true, true, true);

            Test.stopTest();

            List<Task> reviewTasks = [SELECT Id FROM Task WHERE Subject = 'CAF Review Required' AND WhatId = :form.Id];

            System.assertEquals(1, reviewTasks.size(),
                    'ContractAssistanceFormHandler_checkAllCompletedTasks_afterUpdate_reviewTaskExists :' +
                            'no new review tasks bing created if there is an existing one');
        }
    }
}