//Class to retrieve the profile of the user who updating the community nickname.
//Validation on banned word will only apply on community user profile not all other user such as sysadmin 
public without sharing class cpNicknameModifierProfileCheck {

    public list<user> nicknameModifierCheck(list<User> users){
        try{
            list<user> lastModifiers = new list<user>();
            list<user> usersModifiedByCommunityProfile = new list<user>();
            map<Id, list<User>> modifierIdVsUser = new map<Id, list<User>>();
    
            for(User userRec : users){
                if(!modifierIdVsUser.containsKey(userRec.LastModifiedById)){
                    modifierIdVsUser.put(userRec.LastModifiedById, new list<User> {userRec});
                } else {
                    modifierIdVsUser.get(userRec.LastModifiedById).add(userRec);
                }
            }
    
            //Query to get 'DDC Consumer Community User' profile Id
            String communityProfileId = [Select Id, Name from Profile where name = 'DDC Consumer Community User' limit 1].id;
    
            lastModifiers = [SELECT Id, ProfileId FROM User Where Id IN: modifierIdVsUser.keySet()];
    
            for(User modifier : lastModifiers){
                if(modifier.ProfileId == communityProfileId){
                    usersModifiedByCommunityProfile.addAll(modifierIdVsUser.get(modifier.Id));
                }
            }
            
            return usersModifiedByCommunityProfile;
        } catch(exception ex){
            //throw (new AUPostCustomException(ex.getMessage()));
            return null;
		}
    }
   
    public without sharing class AUPostCustomException extends Exception {}
}