trigger APT_QuoteTrigger on APT_Quote_Rate_Card__c (before insert)
{
   set<string> value15 = new set<string>();

   set<string> lineItemID = new set<string>();
   map<string,string> proName=new map<string,string>();   
   set<string> value1 = new set<string>();
   list<APT_New_ISP_Product__c> countries =[select id,name,Product_Name__c from APT_New_ISP_Product__c];
   for(APT_New_ISP_Product__c proNew:countries){
   proName.put(proNew.Product_Name__c,proNew.Product_Name__c);
   
   }

   set<APT_QuoteRateCardDuplica> dbWrapperSet = new set<APT_QuoteRateCardDuplica>();

   set<APT_QuoteRateCardDuplica> newWrapperSet = new set<APT_QuoteRateCardDuplica>();

   for(APT_Quote_Rate_Card__c newQuote : trigger.new){
   
           
           if(proName.containskey(newQuote.APT_Value_15__c))
           {

       APT_QuoteRateCardDuplica iKey = new APT_QuoteRateCardDuplica(newQuote.APT_Value_15__c,newQuote.APT_Line_Item__c,newQuote.APT_Value_1__c);

       if(newWrapperSet.contains(iKey)){

           newQuote.addError('Duplicate in new rate');

       } else {

           value15.add(newQuote.APT_Value_15__c);

           lineItemID.add(newQuote.APT_Line_Item__c);

           value1.add(newQuote.APT_Value_1__c);

           newWrapperSet.add(iKey);

       }
       }

   }
        if(!lineItemID.isEmpty()){
        
            for(APT_Quote_Rate_Card__c dbLead : [select id, APT_Value_15__c, APT_Line_Item__c,APT_Value_1__c from APT_Quote_Rate_Card__c where APT_Line_Item__c IN: lineItemID]){
            //OR APT_Value_15__c IN: value15 OR APT_Value_1__c IN: value1
                dbWrapperSet.add(new APT_QuoteRateCardDuplica(dbLead.APT_Value_15__c , dbLead.APT_Line_Item__c,dbLead.APT_Value_1__c));
        
            }
        
            for(APT_Quote_Rate_Card__c newLead : trigger.new){
        
               APT_QuoteRateCardDuplica iKey = new APT_QuoteRateCardDuplica(newLead.APT_Value_15__c , newLead.APT_Line_Item__c,newLead.APT_Value_1__c);
        
               if(dbWrapperSet.contains(iKey))
        
                   newLead.addError('You are inserting Duplicate rate');
        
             }

        }

}