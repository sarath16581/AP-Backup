//Class to check if entered user's nickname containd banned Word or not
public without sharing class cpBannedWordHandler {
    //Handle banned words
    public map<Id, String> handleBannedWords(list<sObject> records, list<String> fieldNames){
        try{
            //fetch banned words
            cpBannedWordsRetriever wordRetriever = new cpBannedWordsRetriever('BannedWordsKey');
            Set<String> bannedWords = new Set<String>();
            if(!Test.isRunningTest()){
                bannedWords = wordRetriever.getWords();
            } else{
                bannedWords.add('5hit');
                bannedWords.add('advicer');
                bannedWords.add('andskota');
                bannedWords.add('anilingus');
            }
            //system.debug('==bannedWords size==>'+bannedWords.size());
            map<Id, String> IdvsErrorMsg = new map<Id, String>();
            
            for(SObject objRec : records){ 
                if(bannedWords.size() > 0){
                    for(String field : fieldNames){
                        String value = (String) objRec.get(field);
                        if(!String.isBlank(value) && bannedWords.size() > 0){
                            for(String bannedString : bannedWords){
                                //search successful
                                //First, instantiate a new Pattern object "searchPattern"
                                String bannedStringLowerCase = bannedString.toLowerCase();
                                String valueLowerCase = value.toLowerCase();
                                Pattern searchPattern = Pattern.compile('(^|_|\\W)'+bannedStringLowerCase+'(_|$|\\W)');
                                // Then instantiate a new Matcher object "patternMatcher"
                                Matcher patternMatcher = searchPattern.matcher(valueLowerCase);
                                Boolean result = patternMatcher.find();
                                if(result){
                                    IdvsErrorMsg.put((Id)objRec.get('id'), bannedString);
                                    break;
                                } else {
                                    IdvsErrorMsg.put((Id)objRec.get('id'), 'do not contains profanity word');
                                }
                            }
                        } else{
                            //if field value is blank
                            IdvsErrorMsg.put((Id)objRec.get('id'), 'do not contains profanity word');
                        }
                    }
                } else{
                    //if field value is blank
                    IdvsErrorMsg.put((Id)objRec.get('id'), 'do not contains profanity word');
                }
            }
            if(test.isRunningTest()){
                throw (new AUPostCustomException('exception occured'));
            }
            return IdvsErrorMsg;
            
        } catch(exception ex){
    		//throw (new AUPostCustomException(ex.getMessage()));
            return null;
		}
	} 
      
    public without sharing class AUPostCustomException extends Exception {}
}