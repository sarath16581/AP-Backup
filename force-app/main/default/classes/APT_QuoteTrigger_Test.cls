@isTest(SeeAllData=true)
private class APT_QuoteTrigger_Test {

	private static testMethod void CreateQuoteRecord() {
	    
	    Apttus_Config2__ProductConfiguration__c config=new Apttus_Config2__ProductConfiguration__c(Name='Product Config - 2017-Aug_Aged Rights Advocacy Service');
	        insert config;
	    
	    
	    Apttus_Config2__LineItem__c lineNum= new Apttus_Config2__LineItem__c(Apttus_Config2__ConfigurationId__c=config.id,Apttus_Config2__LineNumber__c=10,Apttus_Config2__ItemSequence__c=11,
	    Apttus_Config2__PrimaryLineNumber__c=1,Apttus_Config2__LineType__c='Product/Service',Apttus_Config2__IsPrimaryLine__c=true);
            insert lineNum;	
            
        APT_Quote_Rate_Card__c rateCard=new APT_Quote_Rate_Card__c(APT_Value_15__c='International Economy',APT_Value_1__c='Per Item',APT_Line_Item__c=lineNum.id);	
            insert rateCard;
            
        APT_QuoteRateCardDuplica duplicate=new APT_QuoteRateCardDuplica(rateCard.APT_Value_15__c,rateCard.APT_Line_Item__c,rateCard.APT_Value_1__c);
        
            duplicate.equals(rateCard);
            duplicate.hashCode();
	    

	}

}