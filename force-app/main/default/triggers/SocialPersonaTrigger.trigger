/**************************************************
Type:       Trigger Handler on Social Persona
Purpose:    call On Change of Parent RemoveDummyPostLink

Used By:
History:
--------------------------------------------------
Date        User                                Description

**************************************************/

trigger SocialPersonaTrigger on SocialPersona (after update) {
    if(trigger.isAfter && trigger.isupdate ){
        SocialPersonaHandler.onChangeofParentRemoveDummyPostLink(Trigger.new, trigger.oldMap );
    }

}