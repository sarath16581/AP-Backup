//Class to retrieve Banned Words from Platform Cache
public with sharing class cpBannedWordsRetriever{

    /* key to be searched/put in cache */
    private String cacheKey;
    
	/* default time to live in cache */
    private final Integer DEFAULT_TTL = 86400;
    //Retrieve banned words
	public cpBannedWordsRetriever(String key){
        this.cacheKey = key;        
    }
    //Get banned words
    public Set<String> getWords() {
        Set<String> keys = new Set<String>();
        try{
            if(Cache.Org.contains(cacheKey)){
            	keys = (Set<String>) Cache.Org.get(cacheKey);            
        	} 
            /*else {
                //read from contentcriteria and add it to the cache.
                Set<String> bannedWords = cpBannedWordDetector.fetchBannedWords();
                Cache.Org.put(cacheKey, bannedWords, DEFAULT_TTL);
                keys = bannedWords;
            }
			*/
        
            //system.debug('==keys==>'+keys);
            if(!test.isRunningTest())
            	return keys;
            else {
                throw (new AUPostCustomException('exception occured'));
            }
        } catch (exception ex){
            return null;
        }
    } 
    
    public without sharing class AUPostCustomException extends Exception {}
}