public with sharing class APT_DeleteLegacyIntDigitalBundleCnt{
      Public String ConfigIdU;
      Public String BundleLinenoU;
      Public String ProposalIdU;
      public boolean haserrorMessages {get; set;}
    public APT_DeleteLegacyIntDigitalBundleCnt() {
    }
    
    public PageReference doRenewDelete() {
    

    Savepoint sp = Database.setSavepoint();
    try{
            ConfigIdU = string.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(APT_Constants.CONFIGID));
            BundleLinenoU = string.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(APT_Constants.BUNDLELINENO));
            ProposalIdU = string.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(APT_Constants.PROPOSALID));
            system.debug('ConfigIdU----->'+ConfigIdU);
            system.debug('BundleLinenoU------>'+BundleLinenoU);
            system.debug('ProposalIdU------>'+ProposalIdU);
            Apttus_CPQApi.CPQ.RemoveBundleRequestDO request = new Apttus_CPQApi.CPQ.RemoveBundleRequestDO();          
                      Id CarId = ConfigIdU;
                      request.CartId = CarId;            
                      request.LineNumber = Integer.valueOf(BundleLinenoU);
                     
                    
                    //Start === Apttus Support for case CAS-02201-N2D4P3
                    
                    Apttus_CPQApi.CPQ.RemoveBundleResponseDO response = Apttus_CPQApi.CPQWebService.removeBundle(request);
                    
                    Apttus_config2.ConstraintWebService2.applyConstraintRulesOnAddAll(CarId);
                                        
                    //End === Apttus Support for case CAS-02201-N2D4P3
                
                    Integer start = System.Now().millisecond();
                    system.debug(LoggingLevel.ERROR,start); 
                    while(System.Now().millisecond()< start+3000){
                    system.debug(LoggingLevel.ERROR,System.Now().millisecond() + '####' + start); 
                     
                    //redirect to cart
                    PageReference pageRef = Page.Apttus_QPConfig__ProposalConfiguration;
                 
                    pageRef.getParameters().put(APT_Constants.PARAM_ID,ProposalIdU);
                    pageRef.getParameters().put(APT_Constants.PARAM_IS_ASSET_DISABLED, APT_Constants.BOOLEAN_TRUE);
                    pageRef.getParameters().put(APT_Constants.PARAM_USE_ADVANCED_APPROVAL, APT_Constants.BOOLEAN_TRUE);
                    pageRef.getParameters().put(APT_Constants.PARAM_FLOW, APT_Constants.FLOW_RENEW_FLOW);
                    return pageRef;
                    }
                    }
                    catch(System.Exception ex) {
                    throw ex;
                    Database.rollback(sp);
                    haserrorMessages = true;
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                    }
                    return null;
    }
    



}