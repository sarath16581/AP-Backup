@isTest
private class SocialPersonaDetailCtr_Test {


    static Account a;
    static SocialPersona persona;
    static SocialPost post;
	static Case aCase;

    static void populateEnvironment(){

        aCase = new Case();
        aCase.Subject = 'test this';
        insert aCase;
        
        a = new Account(Name='Test Account');
        insert a;

        persona = new SocialPersona(Name='testPersona');
        persona.ParentId = a.Id;
        persona.Provider = 'Twitter';
        persona.RealName = 'For real';
        insert persona;

        post = new SocialPost(Name='testPost');
        post.PersonaId = persona.Id;
        post.ParentId = aCase.Id;
        insert post;
    }



    static testMethod void test_controller_postID(){
        populateEnvironment();

        System.Test.startTest();

        PageReference pageRef = Page.SocialPersonaDetail;
        pageRef.getParameters().put('id',post.Id);
        System.Test.setCurrentPage(pageRef);

        SocialPersonaDetailCtr ctr = new SocialPersonaDetailCtr();
        System.Test.stopTest();

        System.assertNotEquals(ctr.persona,null);

        SocialPersona sp = ctr.persona;
        system.assertEquals(persona.RealName, sp.RealName);
        
        
    }

    static testMethod void test_controller_caseID(){
        populateEnvironment();

        System.Test.startTest();

        PageReference pageRef = Page.SocialPersonaDetail;
        pageRef.getParameters().put('id',aCase.Id);
        System.Test.setCurrentPage(pageRef);

        SocialPersonaDetailCtr ctr = new SocialPersonaDetailCtr();
        System.Test.stopTest();
		//searches by case and it's related social posts 
		// takes persona from latest post
        System.assertNotEquals(ctr.persona,null);

        SocialPersona sp = ctr.persona;
        system.assertEquals(persona.RealName, sp.RealName);


        system.assertNotEquals(null, ctr.getPostList() );
        system.assertEquals(1, ctr.getPostList().size());

        ctr.getPersonaConversation();
        
        
    }

    static testMethod void test_controller_invalidID(){
        populateEnvironment();

        System.Test.startTest();
        PageReference pageRef = Page.SocialPersonaDetail;
        pageRef.getParameters().put('id',UserInfo.getUserId());
        System.Test.setCurrentPage(pageRef);
        SocialPersonaDetailCtr ctr = new SocialPersonaDetailCtr();
        System.Test.stopTest();
       //no persona should have been found
        System.assertEquals(ctr.persona,null);
        
    }

    /*****************************************************************************************
    *  Scenario:
    *      Create Social persona . execute basic code that's not necesarialy function by coverage related
    ******************************************************************************************/
    static testMethod void additional_Test(){
        SocialPersonaDetailCtr obj = new SocialPersonaDetailCtr();
        obj.theURL = 'dummy url';
        obj.html = 'dummy html';
        obj.offset = 1;
        obj.hasMore = true;
        obj.caseRelatedPosts = new List<SocialPost>();
        obj.firstPost =  new SocialPost();
        string s = obj.getSalesforceUrl();
    }

}