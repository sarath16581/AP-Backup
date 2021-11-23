/**
* @author       : haraprasad.sahoo@auspost.com.au
* @date         : 26/05/2020
* @description  : Test class for Testing scenarios on MyNetworkPODSafedrop controller
* History
--------------------------------------------------
26/05/2020 - Hara Sahoo Created
2021-06-29 - Ranjeewa Silva - Added more test methods for including event message attachments in Case PDF.
*/
@isTest
public class MyNetworkPODSafedropTest {
    // Constants
    private static final String myNetworkPortal_profile = 'MyNetwork Portal';
    private static final Profile prof = [SELECT Id,Name 
                                         FROM 
                                         Profile 
                                         where 
                                         Name =: myNetworkPortal_profile 
                                         LIMIT 1];
    
    @testSetup
    static void setupTestData() {
        User myNetwork_User = new User(Alias = 'portal', Email='user@testorg.a', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                       LocaleSidKey='en_US', ProfileId = prof.Id, TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');
        Database.insert(myNetwork_User);
        // Create articles.
        Article__c article1 = new Article__c(Name = 'a1');
        Database.insert(article1); 
        //insert EM scan for delivered scan with Safe drop with existing image   
        EventMessage__c em1 = new EventMessage__c(EventType__c='DD-ER38', Safe_Drop_GUID__c='12345', Article__c=article1.Id);

        //insert EM scan for delivered scan with safe drop no existing image 1st time view of PDF        
        EventMessage__c em2 = new EventMessage__c(EventType__c='DD-ER33', Safe_Drop_GUID__c='12345A', Article__c=article1.Id);

        //insert EM scan for CARDED_PICTURE image with attachment already existing
        EventMessage__c em3 = new EventMessage__c(EventType__c='AFC-ER7', AttachmentGUID__c='12345B', AttachmentType__c = 'CARDED_PICTURE' , Article__c=article1.Id);

        //insert EM scan for CARDED_PICTURE image with attachment not existing
        EventMessage__c em4 = new EventMessage__c(EventType__c='AFC-ER7', AttachmentGUID__c='12345C', AttachmentType__c = 'CARDED_PICTURE' , Article__c=article1.Id);

        Database.insert(new List<EventMessage__c>{em1, em2, em3, em4});

        // safe drop file
        Attachment att = new Attachment (ContentType='image/jpeg', Body=EncodingUtil.base64Decode('This'), Name='SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME',ParentId = em1.Id);

        // event message attachment CARDED_PICTURE
        Attachment att2 = new Attachment (ContentType='image/jpeg', Body=EncodingUtil.base64Decode('This'), Name = (EventMessageUtil.EVENT_MESSAGE_ATTACHMENT_PREFIX + em3.AttachmentGUID__c),ParentId = em3.Id);
        Database.insert(new List<Attachment>{att, att2});
    }
/**********************************************************************
*  Scenario 1:
*      Checking for the POD SafeDrop display pdf- image exists
**********************************************************************/
    @isTest
    static void testSafedropImage_Exists()
    {
        //query the scan event for safe drop
        EventMessage__c em = [Select Id from EventMessage__c where EventType__c = 'DD-ER38' limit 1];
        User myNetwork_User = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'portal' LIMIT 1];
        
        //insert authentication settings for callout
        SafeDropUtility_Test.insertAuthSettings();
        //run as portal user
        System.runAs(myNetwork_User) {
            test.startTest();
            Object continuation = MyNetworkPODSafedrop.getArticleImageList(String.valueOf(em.Id));
            test.stopTest();
        }
    }
    
 /**********************************************************************
*  Scenario 2:
*      Checking for the POD SafeDrop display pdf- attachment doesnt exist
**********************************************************************/
    @isTest
    static void testSafedropImage_Notexists()
    {
        //query the scan event for safe drop
        EventMessage__c em = [Select Id from EventMessage__c where EventType__c = 'DD-ER33' limit 1];
        User myNetwork_User = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'portal' LIMIT 1];
        
        //insert authentication settings for callout
        SafeDropUtility_Test.insertAuthSettings();
        //run as portal user
        System.runAs(myNetwork_User) {
            test.startTest();
            Object continuation = MyNetworkPODSafedrop.getArticleImageList(String.valueOf(em.Id));
            //call to setup requestlabel
            MyNetworkPODSafedrop.ContinuationState  req = SafeDropUtility_Test.getmyNetworkInvokedContinuationLabel_ConState(continuation);
            //set other continuation state params
            req.eventMessageId = em.Id;
            req.attachmentGUID = '12345';
            req.isSafeDrop = true;
            //call to get response
            SafeDropUtility_Test.setmyNetworkSuccessContinuationResponse_ConState(req);
            //get the response from callback method
            String resp = (String)MyNetworkPODSafedrop.callback(req);
            test.stopTest();
        }
    }

    /**********************************************************************
    *  Scenario 3:
    *      Checking for the Event Message attachment - image exists
    **********************************************************************/
    @isTest
    static void testAttachmentGUID_AttachmentExists()
    {
        //query the scan event for non safedrop attachment guid
        EventMessage__c em = [Select Id from EventMessage__c where AttachmentGUID__c = '12345B' limit 1];
        User myNetwork_User = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'portal' LIMIT 1];

        //run as portal user
        System.runAs(myNetwork_User) {
            test.startTest();
            Object continuation = MyNetworkPODSafedrop.getArticleImageList(String.valueOf(em.Id));
            test.stopTest();
            System.assertEquals('OK', ((String)continuation), 'Should not retrieve the event message attachment if already existing');
        }
    }

    /**********************************************************************
    *  Scenario 4:
    *      Checking for the Event Message attachment - image does not exist
    **********************************************************************/
    @isTest
    static void testAttachmentGUID_AttachmentDoesNotExist()
    {
        //query the scan event for non safedrop attachment guid
        EventMessage__c em = [Select Id, AttachmentGUID__c from EventMessage__c where AttachmentGUID__c = '12345C' limit 1];
        User myNetwork_User = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'portal' LIMIT 1];

        //insert authentication settings for callout
        SafeDropUtility_Test.insertAuthSettings();
        //run as portal user
        System.runAs(myNetwork_User) {

            Test.startTest();

            Object continuation = MyNetworkPODSafedrop.getArticleImageList(String.valueOf(em.Id));
            //call to setup requestlabel
            MyNetworkPODSafedrop.ContinuationState  req = SafeDropUtility_Test.getmyNetworkInvokedContinuationLabel_ConState(continuation);
            //set other continuation state params
            req.eventMessageId = em.Id;
            req.attachmentGUID = '12345C';
            req.isSafeDrop = false;
            //call to get response
            SafeDropUtility_Test.setmyNetworkSuccessContinuationResponse_ConState(req);
            //get the response from callback method
            String resp = (String)MyNetworkPODSafedrop.callback(req);

            Test.stopTest();
        }

        List<Attachment> attachments = [Select Id, Name from Attachment Where ParentId = :em.Id];
        System.assertEquals(1, attachments.size(), 'Expected event message image to be created as an attachment');
        System.assert(attachments[0].Name != null, 'Expected attachment name to have a valid value');
        System.assert(attachments[0].Name.startsWith(EventMessageUtil.EVENT_MESSAGE_ATTACHMENT_PREFIX), 'Expected event message attachment file name to have the prefix ' + EventMessageUtil.EVENT_MESSAGE_ATTACHMENT_PREFIX);
        System.assert(attachments[0].Name.contains(em.AttachmentGUID__c), 'Expected event message attachment file name to include the guid.');

    }
    
    
}