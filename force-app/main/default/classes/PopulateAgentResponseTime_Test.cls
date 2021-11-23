@isTest
public class PopulateAgentResponseTime_Test {


    static Account a;
    static SocialPersona persona;
    static SocialPost post;
    static Case c,c2;

    static void populateEnvironment(){

        a = new Account(Name='Test Account');
        insert a;

        c = new Case();
        insert c;


        persona = new SocialPersona(Name='testPersona');
        persona.ParentId = a.Id;
        persona.Provider = 'Twitter';
        insert persona;

        post = new SocialPost(Name='testPost');
        post.PersonaId = persona.Id;
        post.ParentId = c.Id;
        post.TopicProfileName = '@testPersona';
        insert post;

    }

    @future
    static void postOutbound(String parentId){
        
        SocialPost outB = new SocialPost();
        outB.ParentId = parentId;
        outB.IsOutbound = true;
        outB.Name = 'test';
        insert outB;
    }
        
         

    static testMethod void testCtr(){
        populateEnvironment();

        System.Test.startTest();
            Case c0 = [Select Id,First_response__c from Case where id =: c.Id ];

            //check that initially case has no reference to when agent response time
            system.assert(c0.First_response__c == null);
            
            //create outBound
            postOutbound(c0.Id);

        System.Test.stopTest();
            c0 = [Select Id,First_response__c,LastModifiedDate from Case where id =: c.Id ];
        //check that after first reply case has  reference to when agent response time
            system.assert(c0.First_response__c != null);
           
        
         //check that after second reply case has  reference to when agent first responded
            SocialPost outB = new SocialPost();
            outB.ParentId = c0.Id;
            outB.IsOutbound = true;
            outB.Name = 'test';

            insert outB;
            Case c1 = [Select Id,First_response__c,LastModifiedDate from Case where id =: c.Id ];
          system.assertEquals(c0.First_response__c, c1.First_response__c);
          
        
          //system.assertNotEquals(c0.LastModifiedDate, c1.LastModifiedDate);
    }
}