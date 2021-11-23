//Trigger on user object, customer community use this trigger to check on nickname update against list of banned words
trigger User_trigger on User (after insert, before insert, after update, before update) {
  
    if ( Trigger.isInsert ) {   
        if ( Trigger.isAfter ) {
            /*
            list<User> usersModifiedByCommunity = new list<User>();
            //sanity Check for last Modified by User profile if it is ADMIN or Community User
            cpNicknameModifierProfileCheck sanityProfileCheck = new cpNicknameModifierProfileCheck();
            usersModifiedByCommunity = sanityProfileCheck.nicknameModifierCheck(trigger.new);
            //system.debug('==After Insert trigger usersModifiedByCommunity.size()==>'+usersModifiedByCommunity.size());
            //check for the profanity word in nickname
            if(usersModifiedByCommunity.size() > 0){
                cpUserNickNameHandler handler = new cpUserNickNameHandler();
                handler.userNicknameProfanityCheck(usersModifiedByCommunity);
            }
            */
            
            List<id> UserIds = new List<id>();
            String varSales;
            for ( user u: Trigger.new ) {
                if (u.Auto_Chatter_Groups__c == 'Sales' ||u.Auto_Chatter_Groups__c == 'Startrack' ||u.Auto_Chatter_Groups__c == 'SSSW' ||u.Auto_Chatter_Groups__c == 'PON' ) {
                 	UserIds.add(u.id);
                  	varSales =u.Auto_Chatter_Groups__c ;
             	}            
            }
            
            if ( UserIds.size() > 0 ) {
                AsyncUserApex.addUserToGroup(UserIds,varSales ); 
            }

		}
	}
    
    //Auspost Community Project: Trigger to check for profanity word in nickname update BY community member.
    if(trigger.isAfter && trigger.isUpdate){
        list<User> usersModifiedByCommunity = new list<User>();
        //sanity Check for last Modified by User profile if it is ADMIN or Community User
        cpNicknameModifierProfileCheck sanityProfileCheck = new cpNicknameModifierProfileCheck();
        usersModifiedByCommunity = sanityProfileCheck.nicknameModifierCheck(trigger.new);
        //system.debug('==Before update usersModifiedByCommunity.size()==>'+usersModifiedByCommunity.size());
        //check for the profanity word in nickname
        if(usersModifiedByCommunity.size() > 0){
            cpUserNickNameHandler handler = new cpUserNickNameHandler();
            handler.userNicknameProfanityCheck(usersModifiedByCommunity);
        }
    }

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            //copy the username across to federation Id field.
            //A workflow rule or a process builder couldn't be used to this because the onereg flow that creates the user also creates an Account.
            //which triggers the "MIXED_DML-OPERATION" error.

            Id communityProfId = [select Id from Profile where Name = 'DDC Consumer Community User' limit 1].Id;

            for(User newUser : Trigger.new ) {
                System.debug(newUser.ProfileId);
                if(newUser.ProfileId == communityProfId) {
                    newUser.FederationIdentifier = newUser.Username;
                }
            }
        }
        if (Trigger.isUpdate) {

            Id communityProfId = [select Id from Profile where Name = 'DDC Consumer Community User' limit 1].Id;
            for (User newUser : Trigger.new ) {
                //check if the username has been changed.
                System.debug(newUser.ProfileId);
                if (newUser.ProfileId == communityProfId && newUser.Username != Trigger.oldMap.get(newUser.Id).Username) {
                    //copy the username across to federation Id field.
                    //A workflow rule or a process builder couldn't be used to this because the onereg flow that creates the user also creates an Account.
                    //which triggers the "MIXED_DML-OPERATION" error.
                    newUser.FederationIdentifier = newUser.Username;
                }
            }
        }
    }
    
}