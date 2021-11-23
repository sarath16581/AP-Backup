/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 26/10/2015
  * @description  : This Class is controller class for RetailFaxTemplate EM Scan Table component to send accross the new fax template
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    
    
*******************************  History ************************************************/
public  with sharing class RetailFaxEventaMgmtTableContr {
    
   public   List<EventMessage__c > emSort {get;set;}
  
    public RetailFaxEventaMgmtTableContr () {
        
    }
    
     /**
      * @description       Setter method to sort the records of EM scans
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    public List<TIBCOEventMessageWrapper> emWrap  {get; set {
       
           Map<String,dateTime> map1 = new Map<String,DateTime>();
            Map<String, EventMessage__c> map2 = new Map<String,EventMessage__c>();
            List<DateTime> dtSort = new list<DateTime>();
            emSort = new List<EventMessage__c >();
            
            for(TIBCOEventMessageWrapper tbWrap: value) {
            system.debug('--'+tbWrap.proxyEM.EventID__c+'--'+tbWrap.proxyEM.ActualDateTime__c);
                map1.put(tbWrap.proxyEM.EventID__c, tbWrap.proxyEM.ActualDateTime__c);
                map2.put(tbWrap.proxyEM.EventID__c, tbWrap.proxyEM);
            }
            //add values to list and sort
            dtSort.addALL(map1.values());
            dtSort.sort();
            system.debug('--dtSort'+dtSort);
            Set<String> alreadyAdded = new Set<String>();
            for(integer i = dtSort.size()-1 ; i>=0 ; i-- ) {
                for(String key: map1.keyset()) {
                    if(map1.get(key) == dtSort[i] && !alreadyAdded.contains(key)){
                        emSort.add(map2.get(key));
                        alreadyAdded.add(key);
                        system.debug('---map2'+map2.get(key)+'--emSort'+emSort);
                    }
                    
                }
            }
            system.debug('--emSort'+emSort);
            
      }
    
      }
 }