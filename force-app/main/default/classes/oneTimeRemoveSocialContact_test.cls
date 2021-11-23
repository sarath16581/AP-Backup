/**************************************************
Type:		Test Class for oneTimeRemoveSocialContact
Purpose:	
History:
--------------------------------------------------
07.12.2017    Clint D'Silva    Created
**************************************************/
@isTest
public class oneTimeRemoveSocialContact_test {
    static Map<string, recordtype> recTyBysObjNamRecTyNam = new Map<string, recordtype>();
    static account acc;
    static contact cc;
    static socialPersona persona;
    static socialPost post;
    static Map<String, Object> sampleSocialData;
    static Map<String, Object> sampleSocialData2;
    static CustomInboundSocialPostHandlerImpl handler;

    static {
        handler = new CustomInboundSocialPostHandlerImpl ();
        sampleSocialData = getSampleSocialData('1');
        sampleSocialData2 = getSampleSocialData2('1');
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


    static void CreateData() {
        // system.label.socialAccountName : Social Account
        // create account social
        // Add social contact to social account
        // create social persona
        // create social post
        // create social case
        //

        list<RecordType> recTyLst = [select id,name,sobjecttype, developername from recordtype where sObjectType in ('Account') and developername in ( 'Business_Account')];

        for (Recordtype rec : recTyLst) {
            recTyBysObjNamRecTyNam.put(rec.sobjecttype + '|' + rec.developername, rec);
        }

        string accName;
        accName = system.label.socialAccountName;
        accName = accName == null ? 'Social Account' : accName;

        account acc = new account(name = accName, recordtypeid = recTyBysObjNamRecTyNam.get('Account|Business_Account').id);
        insert acc;
        Contact cc = new contact(lastname = 'Social', accountid = acc.id, firstname='firstname' , email='test@test.com');
        insert cc;
        post = getSocialPost(sampleSocialData);
        persona = getSocialPersona(sampleSocialData);
        persona.parentid = cc.id;
        insert persona;

        handler.handleInboundSocialPost(post, persona, sampleSocialData);

		Attachment att = new Attachment(parentid = cc.id, name='file', body= blob.valueOf('this is file')); 
        insert att;

        Task tsk = new Task(whoid = cc.id);
        insert tsk;
		
        
        Event evt = new Event( whoid = cc.id , DurationInMinutes=30, ActivityDateTime=date.today());
        insert evt;


        //sper = new socialPersona();
        //sp = new socialPost();


    }






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


    static testmethod void RunExecMethod() {
        CreateData();
        test.startTest();
        oneTimeRemoveSocialContact b = new oneTimeRemoveSocialContact('Process1',true,'','');
        database.executeBatch(b);
        test.stopTest();
    }


}