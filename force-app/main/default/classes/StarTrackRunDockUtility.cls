/**
 ** Description: Run Dock Utility
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: SEPT.28.2015
 ** History:--------------------------------------------
 **         SEPT.28.2015 David Catindoy - Created
 **/
public class StarTrackRunDockUtility {
    
  public static Map<Id, String> queryPostCodeMapping(List<Case> caseList){
      Set<String> caseNetwork = new Set<String>();
      Set<String> casePostCode = new Set<String>();
      Set<String> caseSuburb = new Set<String>();
      List<PostcodeMapping__c> postCodeMapping = new List<PostcodeMapping__c>();
      Map<Id, String> runDockResult = new Map<Id, String>();
      Map<String, String> postCodeMap = new Map<String, String>();
      
      for(Case caseRecord : caseList){
          caseNetwork.add(caseRecord.Network__c);
        if(caseRecord.ArticleTest__c != null){
          casePostCode.add(caseRecord.ArticleTest__r.ReceiverPostcode__c);
          caseSuburb.add(caseRecord.ArticleTest__r.Receiver_Suburb__c);
        }
      }
    
        try{
            postCodeMapping = [ SELECT Run_Dock__c, Network__c,
                                Postcode__r.Name, Postcode__r.Suburb__c
                                FROM PostcodeMapping__c 
                                WHERE Network__c IN :caseNetwork 
                                AND Postcode__r.Name IN :casePostCode
                                AND Postcode__r.Suburb__c IN :caseSuburb];
        } catch(QueryException e){
            System.debug('No Record were returned');
        }
        
        for(PostcodeMapping__c postCodeRecord : postCodeMapping){
            postCodeMap.put(postCodeRecord.Network__c + '' + postCodeRecord.Postcode__r.Name + '' + postCodeRecord.Postcode__r.Suburb__c.toUpperCase(), postCodeRecord.Run_Dock__c);
        }
        
        if(postCodeMap.size() > 0){
            for(Case caseRecord : caseList){
                if(caseRecord.ArticleTest__c != null && caseRecord.ArticleTest__r.ReceiverPostcode__c != null && caseRecord.ArticleTest__r.Receiver_Suburb__c != null){
                    if(postCodeMap.containsKey(caseRecord.Network__c + '' + caseRecord.ArticleTest__r.ReceiverPostcode__c + '' + caseRecord.ArticleTest__r.Receiver_Suburb__c.toUpperCase())){
                        runDockResult.put(caseRecord.Id, postCodeMap.get(caseRecord.Network__c + '' + caseRecord.ArticleTest__r.ReceiverPostcode__c + '' + caseRecord.ArticleTest__r.Receiver_Suburb__c.toUpperCase()));
                    }
                }
            }
        }
        
        return runDockResult;
    }
}