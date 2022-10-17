/*
* Description: test class for CaseCommentCustomController
* 23-08-2022 - George Nguyen - created
*/
@IsTest
public class CaseCommentCustomController_Test {

    @IsTest
    static void checkingPropertiesAreInitialisedCorrectly() {
        List<Account> accs = ApplicationTestDataFactory.getAccounts(1, false);
        insert accs;
        List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accs[0].Id, false);
        insert contacts;
        List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
        cases[0].ContactId = contacts[0].Id;
        insert cases;
        List<CaseComment> comments = new List<CaseComment>{new CaseComment(ParentId = cases[0].Id, CommentBody = 'test1'), new CaseComment(ParentId = cases[0].Id, CommentBody = 'test2')};
        insert comments;
        ApexPages.StandardController sc = new ApexPages.StandardController(cases[0]);
        CaseCommentCustomController controller = new CaseCommentCustomController(sc);
        Boolean expectedCurrentUserIsPartOfOmniGroup = OmniChannelService.currentUserIsPartOfOmniGroup;
        System.assertEquals(expectedCurrentUserIsPartOfOmniGroup, controller.currentUserIsPartOfOmniGroup, 'Should match');
        System.assertEquals(cases[0].Id, controller.currentCase.Id, 'Should initialise the correct case');
        System.assertEquals(2, controller.caseComments.size(), 'Should initialise the correct case comments');
        System.assertEquals('test1', controller.caseComments[0].CommentBody, 'Should initialise in the correct order by created date');
    }

    /*
    * Testing the addComment method where it inserts a CaseComment based on the passed values. 
    * If preventStatusChange is True then set the preventStatusChange__c and Email_Bypass_Data_enforcement__c on the case to True
    */
    @IsTest
    static void addComment() {
        List<Account> accs = ApplicationTestDataFactory.getAccounts(1, false);
        insert accs;
        List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accs[0].Id, false);
        insert contacts;
        List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
        cases[0].ContactId = contacts[0].Id;
        cases[0].preventStatusChange__c = false;
        cases[0].Email_Bypass_Data_enforcement__c = false;
        insert cases;
        CaseCommentCustomController.addComment(cases[0].Id, 'test comment', false, true);
        Case actualCase = [SELECT preventStatusChange__c, Email_Bypass_Data_enforcement__c FROM Case WHERE Id = :cases[0].Id LIMIT 1];
        CaseComment actualCaseComment = [SELECT CommentBody,isPublished FROM CaseComment WHERE ParentId = :cases[0].Id LIMIT 1];
        System.assertEquals(true, actualCase.preventStatusChange__c, 'Should be true');
        System.assertEquals(true, actualCase.Email_Bypass_Data_enforcement__c, 'Should be true');
        System.assertEquals(false, actualCaseComment.isPublished, 'Should be false');
        System.assertEquals('test comment', actualCaseComment.CommentBody, 'Should be matching');
    }

}