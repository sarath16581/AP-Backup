//Scheduler Class to retrieve and populate Banned Words into Platform Cache
global class cpSetBannedWordsCacheToOrg implements Schedulable{

    private String sessionId;
		//Get session Id
    global cpSetBannedWordsCacheToOrg( String sessionId ) {
        this.sessionId = sessionId;
    }
		//Set org cache
    global void execute(SchedulableContext ctx) {
        setOrgCache(sessionId);
    }

    @future(callout=true)
		//Set org cache
    public static void setOrgCache(String sessionId){
        
        system.debug('==sessionId from setOrgCache==>'+sessionId);
        datetime qryStart = datetime.now();
        //cpSessionidRetriever sessionRetriever = new cpSessionidRetriever();
        /* default time to live in cache */
    	 final Integer DEFAULT_TTL = 86400;
    	 final String cacheKey = 'BannedWordsKey';
        /*
         String sessionId = '';
        //read from contentcriteria and add it to the cache.
        if(!Test.isRunningTest()){
            sessionId = userInfo.getSessionId();
        	//sessionId = sessionRetriever.getSessionId();
        }else{
            sessionId = userInfo.getSessionId();
        }*/
        Set<String> bannedWords = new Set<String>();
        if(String.isNotBlank(sessionId)){
            try{
                if(!Test.isRunningTest()){
                    bannedWords = cpBannedWordDetector.fetchBannedWords(sessionId);
                }else{
                    bannedWords.add('5hit');
                    bannedWords.add('advicer');
                    bannedWords.add('andskota');
                    bannedWords.add('anilingus');
                }
                system.debug('==bannedWords size==>'+bannedWords.size());
                Cache.Org.put(cacheKey, bannedWords, DEFAULT_TTL);
                datetime qryEnd = datetime.now();
                system.debug('execution elapsed time(in miliseconds)===>'+ (qryEnd.getTime() - qryStart.getTime()) );
                
            } catch (exception ex){
                throw (new AUPostCustomException(ex.getMessage()));
            }
        } else 
            throw (new AUPostCustomException('Session id can\'t be blank'));
    }
    
    public without sharing class AUPostCustomException extends Exception {}
}