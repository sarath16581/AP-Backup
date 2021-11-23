/**************************************************************************
Description:    Test class for SocialPersonaHandler
History:
--------------------------------------------------
June-2018: clint.dsilva@auspost.com.au Created
***************************************************************************/


@IsTest
private class SocialPersonaHandlerTest {
    static socialPost sp;
    static account acc;
    static socialPersona persona;
    static list<SocialPost> bulkSp;
    static list<SocialPersona> bulkSper;
    static boolean isBulk= false;

    @testSetup
    public static void createData(){
        // Create Social post and account data
        string  name_prefix = SocialPersonaHandler.NAME_PREFIX;
        string  comment_prefix = SocialPersonaHandler.CONTENT_PREFIX;
        acc = TestDataProvider.createBusinessAccount();
        insert acc;
        if(!isBulk){
            sp = new SocialPost(name = name_prefix + ' name' , content =  comment_prefix + ' Comment');
            insert sp;

            //Create a persona
            persona = new socialPersona();
            persona.Name = 'author';
            persona.RealName = 'realName';
            persona.Provider = 'TWITTER';
            persona.MediaProvider = 'TWITTER';
            persona.ExternalId = 'externalUserId';

            persona.parentid = sp.id ;

            insert persona;
        } else {
            bulkSp = new  list<SocialPost>();
            bulkSper = new list<SocialPersona>();
            for(integer i=0 ; i < 200 ; i++){
                SocialPost spP = new SocialPost(name = name_prefix + ' name' + i , content =  comment_prefix + ' Comment' + i);
                bulkSp.add(spP);
            }
            insert  bulkSp;
            for(integer i=0 ; i < 200 ; i++ ){
                SocialPost spB = bulkSp[i];
                persona = new socialPersona();
                persona.Name = 'author';
                persona.RealName = 'realName' + i;
                persona.Provider = 'TWITTER';
                persona.MediaProvider = 'TWITTER';
                persona.ExternalId = 'externalUserId' + i;

                persona.parentid = spB.id ;
                bulkSper.add(persona);
            }
            insert bulkSper;
        }

    }

    /*****************************************************************************************
    *  Scenario:
    *      Create Social persona . Then update it to change the persona parent.
    *      the dummp psot is deleted
    ******************************************************************************************/
    static testMethod void testDeleteDummySocialPos() {
        isBulk = false;
        createData();
        //dummy social post created
        list<SocialPersona> spOld = new list<SocialPersona>();
        list<SocialPersona> splst = new list<SocialPersona>();
        splst.add(persona);
        socialPost createdSp = [select id from socialpost where id = :sp.id];
        socialPersona personaOld = persona.clone(true,true);
        spOld.add(personaOld);
        map<id,SocialPersona> spOldMap = new map<id,SocialPersona>(spOld);

        test.startTest();
        persona.parentid = acc.id ;
        update  persona;
        //Force invoke the handler process , just incase the trigger is disabled and coverage is required
        SocialPersonaHandler.onChangeofParentRemoveDummyPostLink( splst,spOldMap);

        test.stopTest();

        socialPost createdSpDel;
        try{
            createdSpDel = [select id from socialpost where id = :sp.id];
        } catch(Exception ex){
            // do nothing
        }


        system.assert(createdSp != null &&  createdSpDel == null,
                'Dummy Social Post should have been deleted' );
    }

    /*****************************************************************************************
    *  Scenario:
    *      Create Social persona . Then update any other field. The dummy parent is not deleted
    *
    ******************************************************************************************/
    static testMethod void testDoNotDeleteDummySocialPostCurrent() {
        isBulk = false;
        createData();
        //dummy social post created
        list<SocialPersona> spOld = new list<SocialPersona>();
        list<SocialPersona> splst = new list<SocialPersona>();
        splst.add(persona);
        socialPost createdSp = [select id from socialpost where id = :sp.id];
        socialPersona personaOld = persona.clone(true,true);
        spOld.add(personaOld);
        map<id,SocialPersona> spOldMap = new map<id,SocialPersona>(spOld);
        test.startTest();
        /* Do not update parent id, testing to see there should not be a delete
        * Update any field
        persona.parentid = acc.id ;
        */
        persona.RealName = 'realName1' ;
        update  persona;
        //Force invoke the handler process , just incase the trigger is disabled and coverage is required
        SocialPersonaHandler.onChangeofParentRemoveDummyPostLink( splst,spOldMap);

        test.stopTest();

        socialPost createdSpDel;
        try{
            createdSpDel = [select id from socialpost where id = :sp.id];
        } catch(Exception ex){
            // do nothing
        }


        system.assert(createdSp != null &&  createdSpDel != null,
                'Dummy Social Post should not be deleted' );
    }


    /*****************************************************************************************
    *  Scenario:
    *      Chech multiple updates on social persona does not change parent id
    *
    ******************************************************************************************/
    static testMethod void testBulkUpdateofSocialPersona() {
        isBulk = true;
        createData();
        SocialPersona perAssertObj, perAssertObjAftUpdate;
        for(SocialPersona persona : bulkSper){
            persona.RealName =  persona.RealName + ' updated' ;
            perAssertObj =persona;
        }

        update  bulkSper;
        perAssertObjAftUpdate = [select id,parentid from SocialPersona where id = :perAssertObj.id ];

        system.assertEquals(perAssertObj.parentid ,perAssertObjAftUpdate.parentid,'Parent id must not change when persona is updated' );

    }

}