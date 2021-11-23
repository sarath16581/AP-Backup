/**************************************************
Description:    Trigger Handler on Social Persona
                Delete dummy social post when the persona record is changed
History:
--------------------------------------------------
2018-05-06  clint.dsilva@auspost.com.au  Created
**************************************************/


public without sharing class SocialPersonaHandler {
    // prefix NAME_PREFIX has a space at the end
    public static final string NAME_PREFIX = 'DPP ';
    public static final string CONTENT_PREFIX = 'Dummy';


    /**
     * @description       When the parent field is changed forom dummmy post to something else, remove dummy post
     * @param             trigger new and old
     * @return            Void
     * @throws            NA
     */
    public static void onChangeofParentRemoveDummyPostLink( list<socialPersona> newLst,  Map<id,socialPersona> sperOldMap ){

        // delete dummy Social Post if reparented to other sObjects
        list<SocialPost> spDelLst = new list<SocialPost>();
        set<ID> spId = new set<ID>();
        list<socialPersona> sperLstOld = sperOldMap.values();
        for(socialPersona sp:newLst){
            socialPersona spOld = sperOldMap.get(sp.id);
            if(spOld != null && spOld.parentid != sp.parentid ){
                spId.add(spOld.parentid);
            }
        }
        list<SocialPost> spLst = [select id,name,content from SocialPost where id in :spId] ;
        // delete dummy Social Post only if pre-fix exists for name and comment

        for(SocialPost sp: spLst ){
            string nam = sp.name;
            nam = nam == null?'':nam;
            string cont =  sp.Content;
            cont =  cont == null?'':cont;

            if(nam.left(4) == NAME_PREFIX && cont.left(5) == CONTENT_PREFIX  ){
                spDelLst.add(sp);
            }
        }
        if(spDelLst.size() > 0){
            delete spDelLst;
        }

    }
}