public class APT_QuoteRateCardDuplica {
    
   

   public string value15;

   public string lineItemid;

   public string value1;

   public APT_QuoteRateCardDuplica(string quoteValue15 , string quoteLineItem,string quoteValue1){

       value15 = quoteValue15;

       lineItemid = quoteLineItem;
        
       value1 = quoteValue1;
    }

   public Boolean equals(Object obj) {

       if (obj instanceof APT_QuoteRateCardDuplica) {

           APT_QuoteRateCardDuplica p = (APT_QuoteRateCardDuplica)obj;

           return ((value15==p.value15) && (lineItemid==p.lineItemid) && (value1==p.value1));

       }

       return false;

   }

   public Integer hashCode() {

       return (2 * value15.hashCode()) ^ lineItemid.hashCode() ^ value1.hashCode();

   }

}