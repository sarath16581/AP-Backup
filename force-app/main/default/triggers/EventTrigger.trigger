/**************************************************
Type:       Trigger for Event Object
Purpose:    Update associated Account with Last Activity Date
History:
--------------------------------------------------
19.10.2011    Carl Vescovi(Australia Post contractor)    Created
08.11.2011    Carl Vescovi                               added linkEventToPrimaryOrg script
02.01.2014    Louis Wang (Bluewolf)                     Removed concept of Partner / Individual, such that standard Account-Contact is reestablished
**************************************************/

trigger EventTrigger on Event (before insert, before update, after insert, after update) {

    if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
        ActivityUtil.updateLastActivityFromEvent(trigger.new);
    }
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
        // Adrian Recio / Populate work day value 
        // 8/9/2017
        ActivityUtil.identifyWorkDay(new List<Task>(),trigger.new);
        ActivityUtil.updateLastActivityDateFromActivity(trigger.new);
    }
    // CV: added 8/11/11
    // purpose is to check event before insert, and if the Whoid and WhatId both point to the Individual, then adjust WhatId to the OrgId of primary Org.
    // this then allows for aggregated Activity Hx under Organisation for primary business contacts.
    // LW - removed 2/01/2014 
    //      Account no longer has the concept of Primary_Organisation__pc, so this code is no longer relevant and is removed.        

}