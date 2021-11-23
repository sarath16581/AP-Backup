/**
 ** Description: Depot Calculation Utility
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: OCT.9.2015
 ** History:--------------------------------------------
 **         OCT.9.2015 David Catindoy - Created
 **/
public class StarTrackDepotCalculationUtility {
    
    public static Map<Id, Set<Id>> queryPostCodeMapping(List<Article__c> conList){
      Map<Id, Set<Id>> depotResult = new Map<Id, Set<Id>>();
      Map<String, Set<Id>> postCodeMap = new Map<String, Set<Id>>();
      Set<String> receiverSuburb = new Set<String>();
      Set<String> receiverPostcode = new Set<String>();
      Set<String> serviceType = new Set<String>();
      List<PostcodeMapping__c> postCode = new List<PostcodeMapping__c>();
      for(Article__c con : conList){
          receiverSuburb.add(con.Receiver_Suburb__c);
          receiverPostcode.add(con.ReceiverPostcode__c);
          serviceType.add(con.Service_Type__c);
      }
      postCode = [  SELECT Id, Network__c, Suburb__c, Postcode__c,
                    Network__r.Facility__c, Postcode__r.Name
                    FROM PostcodeMapping__c
                    WHERE Suburb__c IN :receiverSuburb
                    AND Postcode__r.Name IN :receiverPostcode
                    AND Network__r.Facility__c IN :serviceType];
                        
      for(PostcodeMapping__c pcm : postCode){
          if(!postCodeMap.containsKey(pcm.Suburb__c.toUpperCase() + '' + pcm.Postcode__r.Name + '' + pcm.Network__r.Facility__c)){
              postCodeMap.put(pcm.Suburb__c.toUpperCase() + '' + pcm.Postcode__r.Name + '' + pcm.Network__r.Facility__c, new Set<Id>{pcm.Network__c});
          } else{
              postCodeMap.get(pcm.Suburb__c.toUpperCase() + '' + pcm.Postcode__r.Name + '' + pcm.Network__r.Facility__c).add(pcm.Network__c);
          }
      }
      
      for(Article__c con : conList){
        if(postCodeMap.containsKey(con.Receiver_Suburb__c.toUpperCase() + '' + con.ReceiverPostcode__c + '' + con.Service_Type__c)){
            depotResult.put(con.Id, postCodeMap.get(con.Receiver_Suburb__c.toUpperCase() + '' + con.ReceiverPostcode__c + '' + con.Service_Type__c));
        }
      }
      
      return depotResult;
    }
}