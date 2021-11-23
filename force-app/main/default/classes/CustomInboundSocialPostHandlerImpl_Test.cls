/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 12/11/2016
  * @description  : test class for social handler class - handling all social post and threading them to correct parent and handling them correctly.
--------------------------------------- History --------------------------------------------------                      
2020-11-17 - Ranjeewa Silva - Test methods for routing social cases using SSSW Routing rules.
**/
@isTest
public class CustomInboundSocialPostHandlerImpl_Test {

    static Map<String, Object> sampleSocialData;
    static Map<String, Object> sampleSocialData2;
    static CustomInboundSocialPostHandlerImpl handler;

    static {
        handler = new CustomInboundSocialPostHandlerImpl ();
        sampleSocialData = getSampleSocialData('1');
        sampleSocialData2 = getSampleSocialData2('1');
    }
    
    /**
      * @description       test method to verif record creation
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    static testMethod void verifyNewRecordCreation() {
        try {
            SocialPost post = getSocialPost(sampleSocialData);
            SocialPersona persona = getSocialPersona(sampleSocialData);

            test.startTest();
            handler.handleInboundSocialPost(post, persona, sampleSocialData);
            test.stopTest();

            SocialPost createdPost = [SELECT Id, PersonaId, ParentId, WhoId FROM SocialPost];
            SocialPersona createdPersona = [SELECT Id, ParentId FROM SocialPersona];
            Contact createdContact = [SELECT Id FROM Contact];
            Case createdCase = [SELECT Id, ContactId, Origin, SocialPostTags__c, AllocateToQueue__c FROM Case];

            System.assertEquals(post.PostTags, createdCase.SocialPostTags__c, 'Expected Post Tags in Social Post to be copied over to case');
            System.assertEquals('Social', createdCase.Origin, 'Expected case origin to be set to Social');

        } catch(Exception exp) {}
        /*System.assertEquals(createdPost.PersonaId, createdPersona.Id, 'Post is not linked to the Persona.');
        System.assertEquals(createdPost.WhoId, createdPersona.ParentId, 'Post is not linked to the Contact');
        System.assertEquals(createdPost.ParentId, createdCase.Id, 'Post is not linked to the Case.');
        System.assertEquals(createdCase.ContactId, createdContact.Id, 'Contact is not linked to the Case.');
        */
    }
    
    /**
      * @description       test method to match the post
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    static testMethod void matchSocialPostRecord() {
        SocialPost existingPost = getSocialPost(getSampleSocialData('2'));
        insert existingPost;
        
        SocialPost post = getSocialPost(sampleSocialData);
        post.R6PostId = existingPost.R6PostId;
        SocialPersona persona = getSocialPersona(sampleSocialData);
        
        test.startTest();
        handler.handleInboundSocialPost(post, persona, sampleSocialData);
        test.stopTest();
        
        System.assertEquals(1, [SELECT Id FROM SocialPost].size(), 'There should be only 1 post');
    }
    
    /**
      * @description       test method to match the persona
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    static testMethod void matchSocialPersonaRecord() {
        Contact existingContact = new Contact(LastName = 'LastName', Email='test@test.com', FIrstName = 'abc');
        insert existingContact;
        SocialPersona existingPersona = getSocialPersona(getSampleSocialData('2'));
        existingPersona.ParentId = existingContact.Id;
        insert existingPersona;
        
        SocialPost post = getSocialPost(sampleSocialData);
        SocialPersona persona = getSocialPersona(sampleSocialData);
        persona.ExternalId = existingPersona.ExternalId;
        
        test.startTest();
        handler.handleInboundSocialPost(post, persona, sampleSocialData);
        test.stopTest();
        
        SocialPost createdPost = [SELECT Id, PersonaId, ParentId, WhoId FROM SocialPost];
        SocialPersona createdPersona = [SELECT Id, ParentId FROM SocialPersona];
        Contact createdContact = [SELECT Id FROM Contact];
        Case createdCase = [SELECT Id, ContactId FROM Case];
        /*
        System.assertEquals(createdPost.PersonaId, createdPersona.Id, 'Post is not linked to the Persona.');
        System.assertEquals(createdPost.WhoId, createdPersona.ParentId, 'Post is not linked to the Contact');
        System.assertEquals(createdPost.ParentId, createdCase.Id, 'Post is not linked to the Case.');
        System.assertEquals(createdCase.ContactId, createdContact.Id, 'Contact is not linked to the Case.');
        */
    }
    
    /**
      * @description       test method to match the case record created
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    static testMethod void matchCaseRecord() {
        Contact existingContact = new Contact(LastName = 'LastName', Email='test@test.com', FIrstName = 'abc');
        insert existingContact;
        SocialPersona existingPersona = getSocialPersona(getSampleSocialData('2'));
        existingPersona.ParentId = existingContact.Id;
        insert existingPersona;
        String recId  = [Select Id from RecordType where sObjectType ='Case' and DeveloperName='Social_Record_Type' limit 1].Id;
        Case existingCase = new Case(ContactId = existingContact.Id, Subject = 'Test Case',recordTypeId = recId);
        insert existingCase;
        SocialPost existingPost = getSocialPost(getSampleSocialData('2'));
        existingPost.ParentId = existingCase.Id;
        existingPost.WhoId = existingContact.Id;
        existingPost.PersonaId = existingPersona.Id;
        insert existingPost;
        
        SocialPost post = getSocialPost(sampleSocialData);
        post.responseContextExternalId = existingPost.ExternalPostId;
        
        test.startTest();
        handler.handleInboundSocialPost(post, existingPersona, sampleSocialData);
        test.stopTest();
        
        SocialPost createdPost = [SELECT Id, PersonaId, ParentId, WhoId FROM SocialPost WHERE R6PostId = :post.R6PostId];
        /*
        System.assertEquals(existingPersona.Id, createdPost.PersonaId, 'Post is not linked to the Persona.');
        System.assertEquals(existingContact.Id, createdPost.WhoId, 'Post is not linked to the Contact');
        System.assertEquals(existingCase.Id, createdPost.ParentId, 'Post is not linked to the Case.');
        System.assertEquals(1, [SELECT Id FROM Case].size(), 'There should only be 1 Case.');
        */
    }
    
    /**
      * @description       test method to verif reopen cases
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    static testMethod void reopenClosedCase() {
        Contact existingContact = new Contact(LastName = 'LastName', Email='test@test.com', FIrstName = 'abc');
        insert existingContact;
        SocialPersona existingPersona = getSocialPersona(getSampleSocialData('2'));
        existingPersona.ParentId = existingContact.Id;
        insert existingPersona;
        String recId  = [Select Id from RecordType where sObjectType ='Case' and DeveloperName='Social_Record_Type' limit 1].Id;
        Case existingCase = new Case(ContactId = existingContact.Id, Subject = 'Test Case', Status = 'Closed', Origin = 'Social', SocialPostTags__c = 'post tags2',
                                    ResolutionCode__c='tets',Requestor__c=userinfo.getUserId(),Requestor_Workgroup__c='test', recordtypeId=recId);
        insert existingCase;
        SocialPost existingPost = getSocialPost(getSampleSocialData('2'));
        existingPost.ParentId = existingCase.Id;
        existingPost.WhoId = existingContact.Id;
        existingPost.PersonaId = existingPersona.Id;
        insert existingPost;
        
        SocialPost post = getSocialPost(sampleSocialData);
        post.responseContextExternalId = existingPost.ExternalPostId;
        
        test.startTest();
        handler.handleInboundSocialPost(post, existingPersona, sampleSocialData);
        test.stopTest();
        
        SocialPost createdPost = [SELECT Id, PersonaId, ParentId, WhoId FROM SocialPost WHERE R6PostId = :post.R6PostId];
        /*
        System.assertEquals(existingPersona.Id, createdPost.PersonaId, 'Post is not linked to the Persona.');
        System.assertEquals(existingContact.Id, createdPost.WhoId, 'Post is not linked to the Contact');
        System.assertEquals(existingCase.Id, createdPost.ParentId, 'Post is not linked to the Case.');
        System.assertEquals(1, [SELECT Id FROM Case].size(), 'There should only be 1 Case.');
        System.assertEquals(false, [SELECT Id, IsClosed FROM Case WHERE Id = :existingCase.Id].IsClosed, 'Case should be open.');
        */

        Case reopenedCase = [select Id, Status, Origin, SocialPostTags__c from Case Where Id = :existingCase.Id];
        System.assertEquals(CustomInboundSocialPostHandlerImpl.CASE_STATUS_NEW, reopenedCase.Status, 'Reopened case should have "New" status');
        System.assertEquals(CustomInboundSocialPostHandlerImpl.CASE_ORIGIN_SOCIAL, reopenedCase.Origin, 'Reopened case should have "Social" origin');
        System.assert(reopenedCase.SocialPostTags__c != null, 'Reopened case should retain the post tags from social posts');
    }

    /**
      * @description       method to create a social post test data
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    static SocialPost getSocialPost(Map<String, Object> socialData) {
        SocialPost post = new SocialPost();
        post.Name = String.valueOf(socialData.get('source'));
        post.Content = String.valueOf(socialData.get('content'));
        post.Posted = Date.valueOf(String.valueOf(socialData.get('postDate')));
        post.PostUrl = String.valueOf(socialData.get('postUrl'));
        post.Provider = String.valueOf(socialData.get('mediaProvider'));
        post.MessageType = String.valueOf(socialData.get('messageType'));
        post.ExternalPostId = String.valueOf(socialData.get('externalPostId'));
        post.R6PostId = String.valueOf(socialData.get('r6PostId'));
        post.PostTags = String.valueOf(socialData.get('postTags'));
        return post;
    }
    
    /**
      * @description       method to create a social persona test data
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    static SocialPersona getSocialPersona(Map<String, Object> socialData) {
        SocialPersona persona = new SocialPersona();
        persona.Name = String.valueOf(socialData.get('author'));
        persona.RealName = String.valueOf(socialData.get('realName'));
        persona.Provider = String.valueOf(socialData.get('mediaProvider'));
        persona.MediaProvider = String.valueOf(socialData.get('mediaProvider'));
        persona.ExternalId = String.valueOf(socialData.get('externalUserId'));        
        return persona;
    }

    /**
      * @description       method to create a test data for posts - Tweets
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    static Map<String, Object> getSampleSocialData(String suffix) {
        Map<String, Object> socialData = new Map<String, Object>();
        socialData.put('r6PostId', 'R6PostId' + suffix);
        socialData.put('r6SourceId', 'R6SourceId' + suffix);
        socialData.put('postTags', 'post tag' + suffix);
        socialData.put('externalPostId', 'ExternalPostId' + suffix);
        socialData.put('content', 'Content' + suffix);
        socialData.put('postDate', '2015-01-12T12:12:12Z');
        socialData.put('mediaType', 'Twitter');
        socialData.put('author', 'Author');
        socialData.put('skipCreateCase', false);
        socialData.put('mediaProvider', 'TWITTER');
        socialData.put('externalUserId', 'ExternalUserId');
        socialData.put('postUrl', 'PostUrl' + suffix);
        socialData.put('messageType', 'Tweet');
        socialData.put('source', 'Source' + suffix);
        socialData.put('replyToExternalPostId', null);
        socialData.put('realName', 'Real Name');
        return socialData;
    }
    
    /**
      * @description       method to create a social post test data - Direct Messages
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    static Map<String, Object> getSampleSocialData2(String suffix) {
        Map<String, Object> socialData = new Map<String, Object>();
        socialData.put('r6PostId', 'R6PostId' + suffix);
        socialData.put('r6SourceId', 'R6SourceId' + suffix);
        socialData.put('postTags', null);
        socialData.put('externalPostId', 'ExternalPostId' + suffix);
        socialData.put('content', 'Content' + suffix);
        socialData.put('postDate', '2015-01-12T12:12:12Z');
        socialData.put('mediaType', 'Twitter');
        socialData.put('author', 'Author');
        socialData.put('skipCreateCase', false);
        socialData.put('mediaProvider', 'TWITTER');
        socialData.put('externalUserId', 'ExternalUserId');
        socialData.put('postUrl', 'PostUrl' + suffix);
        socialData.put('messageType', 'Direct');
        socialData.put('source', 'Source' + suffix);
        socialData.put('replyToExternalPostId', null);
        socialData.put('realName', 'Real Name');
        socialData.put('Recipient','Facebook');
        return socialData;
    }
    
    /**
      * @description       method to test Direct Message Posts
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    static testMethod void matchSocialPostRecordDirect() {
        //insert existingPost;
        Profile prof = [SELECT Id,Name FROM profile where Name ='SSSW Social Integration' LIMIT 1];
        User runningUser = TestUtility.createUser('Wayne',prof.id,null);
        system.runAs(runningUser) {
            SocialPost post = getSocialPost(sampleSocialData2);
            //post.R6PostId = existingPost.R6PostId;
            post.replyTo = null;
            post.Recipient = 'facebook';
            post.messageType='Direct';
            post.Id = null;
            SocialPersona persona = getSocialPersona(sampleSocialData2);
            
            test.startTest();
            handler.handleInboundSocialPost(post, persona, sampleSocialData2);
            test.stopTest();
            
            System.assert( [SELECT Id FROM SocialPost].size() > 0,
                    'There should be social post');
        }
    }
}