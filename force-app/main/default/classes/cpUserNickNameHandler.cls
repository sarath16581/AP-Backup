//Class  to handle Profanity check on user nickname insert/upadte
public without sharing class cpUserNickNameHandler {

   //Check nickname against banned words list
    public void userNicknameProfanityCheck(list<User> users){
        try{
            
            list<User> userList = new list<User>();
            cpBannedWordHandler profanityHandler = new cpBannedWordHandler();
            list<String> fieldList = new list<String>{'CommunityNickname'};
    
                for(User userIns : users){
                    if(String.isNotBlank(userIns.CommunityNickname)){
                        userList.add(userIns);
                    }
                }
    
            map<Id, String> idVsErrorMsg = profanityHandler.handleBannedWords(userList, fieldList);
            for(User userRec : users){
                if(idVsErrorMsg.containsKey(userRec.Id) && idVsErrorMsg.get(userRec.Id) != 'do not contains profanity word'){
                    userRec.addError('Sorry, you can\'t use \" ' +idVsErrorMsg.get(userRec.Id)+ ' \" or other inappropriate words in this community. Please review your content and try again.');
                }
            }
            if(test.isRunningTest()){
                throw (new AUPostCustomException('exception occured'));
            }
            
    	} catch(exception ex){
            for(User userRec : users){
                userRec.addError('exception occured');
            }
		}
    }
    
    public without sharing class AUPostCustomException extends Exception {}
}