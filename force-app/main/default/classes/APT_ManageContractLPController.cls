/**
    Description: This apex class is the controller for Visualforce page - APT_ManageContarctLodgementPoint.
    Created By: Raviteja Epuri
    Created Date: 26th Nov, 2015
    Last Modified By: Krishna Velani
    Last Modified Date: 7th April, 2021
    Description: STP-4984 STPAC - Update the lodgement search solution
**/

public with sharing class APT_ManageContractLPController {     

    public List<APT_Agreement_Lodgement_Point__c> listAgreementLPLodgementPointSelected { get; set; }
    public String bussinessUnit { get; set; }
    public network__c lodgementPoint { get; set; }
    Public Boolean haserrorMessages{get;set;}
    Public list<lodgementPointWrapper> listLodgementPointWrapper{get; set;}
    public String aId{ get; set; }
    public String billingAcc { get; set; }
    public String cashAcc{ get; set; }
    public String chargeAcc{ get; set; }
    public String subAcc{ get; set; }
    public APT_Agreement_Lodgement_Point__c aLP { get; set; }
    public Id agreementId;
    public Id quoteId { get; set; }
    public Id accountId { get; set; }   //APOST-1861
    public string source{ get; set; }    
    public List<agreementLIWrapper> listAgreementLineItemWrap{ get; set; }
    Apttus__AgreementLineItem__c aLISelected = new Apttus__AgreementLineItem__c();
    Apttus__APTS_Agreement__c agreement=new Apttus__APTS_Agreement__c();
    set<string> setProductNames = new set<string>();
    public string postCodeStart;
    public string postCodeEnd;
    List<APT_Lodgement_Zone__c> lstLodgementZone =new List<APT_Lodgement_Zone__c>();
    public String stateVal{get; set;}
    public String domesticLodgementZone{get; set;}
    Public List<SelectOption> statePickval{get;set;}
    public integer searchRecCount{get;set;}
    public integer offSetVal{get;set;}
    public integer recordsperpage;
    public Integer subAccCount{get;set;}
    public Integer cashAccCount{get;set;}
    public Integer chargeAccCount{get;set;}
    public String productId;
    
    public static final string strTitle = 'Manage Lodgement Points and Account Numbers';
    public static string strGetValTitle {get{return strTitle;} set;}

     /**STP-4984 Krishna Velani created below map to use for new logic**/
    Map<string,string> mapLodgement =new Map<string,string>();
    
    /**
        Constructor to get the Id of Agreement and to retrieve already added Quote Lodgement Points.
     **/
    public APT_ManageContractLPController(){     
      try{
            init();
      
      } catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            
        }  
    }
    /**
      init method
    **/
    public void init () {
          agreementId= ApexPages.currentPage().getParameters().get(APT_Constants.AGREEMENT_ID);
          listLodgementPointWrapper =new list<lodgementPointWrapper>();
          listAgreementLPLodgementPointSelected =new List<APT_Agreement_Lodgement_Point__c>();
          lodgementPoint = new Network__c(); 
          listAgreementLineItemWrap =new List<agreementLIWrapper>();
          source = APT_Constants.EMPTY_STRING;
          aLP = new APT_Agreement_Lodgement_Point__c(); 
          offSetVal=0;
          
          if(string.iSEMPTY(System.Label.APT_Manage_LP_records_per_Page)){      
              recordsperpage = 100;
            }else{
               recordsperpage = integer.valueof(System.Label.APT_Manage_LP_records_per_Page);
           }
           
          agreement =[select id,Apttus__Account__c,Billing_Account__c,Apttus_QPComply__RelatedProposalId__c from Apttus__APTS_Agreement__c where id=: agreementId];
          quoteId =agreement.Apttus_QPComply__RelatedProposalId__c;
          accountId = agreement.Apttus__Account__c; //APOST-1861
          listAgreementLPLodgementPointSelected = [select id,APT_Status__c,APT_Lodgement_Point_Name__c,APT_Billing_Account__c ,APT_Address__c,APT_eParcel_Enabled__c,APT_Transport_Capability__c,APT_Organisation_ID__c,APT_DWS_ID__c,APT_Selected_Lodgement_Point__c,APT_LP_Post_Code__c,APT_Lodgement_Zone__c,APT_Product__c,APT_Outlet_Type__c,APT_Billing_Account_Flag__c from APT_Agreement_Lodgement_Point__c where APT_Agreement__c =:agreementId]; 
          
          setProductNames =APT_Default_Billing_Account_Products__c.getall().keyset();
          system.debug('*** quoteId ***'+quoteId);
          if(!String.isEmpty(quoteId)){ //APOST-1861
            subAccCount  =[select count() from APT_Sub_Account__c where APT_Quote_Proposal__c =:quoteId];
            chargeAccCount  =[select count() from APT_Charge_Account__c where APT_Quote_Proposal__c =:quoteId]; 
            cashAccCount  =[select count() from APT_Cash_Account__c where APT_Proposal__c =:quoteId];  
          } 
          //APOST-1861
          else {
            subAccCount = 0;
            chargeAccCount = 0;
            cashAccCount = 0;
          }
          //APOST-1861
            
          
          system.debug('*** subAccCount ***'+subAccCount);
          system.debug('*** chargeAccCount ***'+chargeAccCount);
          system.debug('*** cashAccCount ***'+cashAccCount);
    }
    
    /**
        Method to render components for Generic Lodgement Point.
     **/
     public PageReference addGenericLP(){      
      try {
          listAgreementLineItemWrap =new List<agreementLIWrapper>();
          listLodgementPointWrapper = new list<lodgementPointWrapper>();
          aLP =new APT_Agreement_Lodgement_Point__c();
          source = APT_Constants.GENERIC;      
          //aLP.APT_Billing_Account__c = agreement.Billing_Account__c;
          //Method to set the State picklist values
            setstatePickvalues(Null);
          return null;
      }  catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        } 
     }

    /**
        Method to retrieve the products related to agreement.
     **/
    public PageReference addProdSpecificLP() {    
       try{
       productId = null;
       listLodgementPointWrapper = new List<lodgementPointWrapper>();
       listAgreementLineItemWrap =new List<agreementLIWrapper>();    
       agreementLIWrapper aLIWrapper;

       for(Apttus__AgreementLineItem__c  aLI :[Select id,Name,Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Post_Code_End__c,Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Post_Code_Start__c,Apttus__AgreementId__r.Apttus__Account__c,Apttus__AgreementId__r.Billing_Account__r.name, Apttus__ProductId__r.name,Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.Name,Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__ProductId__r.ProductCode  from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =:agreementId AND Apttus_CMConfig__IsPrimaryLine__c = True AND Apttus_CMConfig__LineType__c != :APT_Constants.LABEL_LINE_TYPE_OPTION]){
       
           aLIWrapper = new agreementLIWrapper();
           aLIWrapper.IsSelectedLI = false;
           aLIWrapper.agLI= aLI;
           listAgreementLineItemWrap.add(aLIWrapper);             
       }  
        if(listAgreementLineItemWrap.size() == 0){
           haserrorMessages = true;
           ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, APT_Constants.MSG_NO_LINE_ITEMS));
           return null;
       } 
       } catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }      
        return null;
    }
    
      /**
       Method to populate product, lodgement zone and Billing Account
     **/
    public PageReference doSelectALIMthd() {        
        try{
        productId = null;
        string selectedALIId = Apexpages.currentPage().getParameters().get(APT_Constants.SELECTALIID);
        source = APT_Constants.PRODSPECIFIC;                               
        for(agreementLIWrapper aLIWrapper : listAgreementLineItemWrap) {
           if(aLIWrapper.agLI.Id == selectedALIId) {            
               aLISelected =aLIWrapper.agLI; 
               productId = aLIWrapper.agLI.Apttus__ProductId__c;
               break;             
           }           
        } 
        
        for(APT_Agreement_Lodgement_Point__c billAccALP : listAgreementLPLodgementPointSelected){ 
           
         if(setProductNames.size() !=0 && setProductNames.contains(billAccALP.APT_Product__c) && (billAccALP.APT_Status__c).equalsIgnoreCase(APT_Constants.ACTIVE)){
                aLP.APT_Billing_Account__c =billAccALP.APT_Billing_Account__c;
         }else if((aLISelected.Apttus__ProductId__r.name).equalsIgnoreCase(billAccALP.APT_Product__c) && (billAccALP.APT_Status__c).equalsIgnoreCase(APT_Constants.ACTIVE)){         
                aLP.APT_Billing_Account__c = billAccALP.APT_Billing_Account__c;
         }else{
            aLP.APT_Billing_Account__c=null;
         }   
        }     
        aLP.APT_Product__c = aLISelected.Apttus__ProductId__r.name;
        aLP.APT_Lodgement_Zone__c= aLISelected.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.Name;
         
        list<Apttus_Config2__ProductAttributeValue__c> lstProdAttVal= [select id,APT_Postcode__c from Apttus_Config2__ProductAttributeValue__c where Apttus_Config2__LineItemId__c =:aLISelected.Apttus_CMConfig__DerivedFromId__c];
            if(lstProdAttVal.size()>0){               
               lodgementPoint.Post_Code__c  =lstProdAttVal[0].APT_Postcode__c;                
            } 
        
        //Method to set the State picklist values
        setstatePickvalues(aLISelected.Apttus_CMConfig__DerivedFromId__c);        
        
        if(String.IsNotBlank(aLP.APT_Lodgement_Zone__c)){
                  lstLodgementZone = [select id,name,APT_Post_Code_Start__c,APT_Post_Code_End__c from APT_Lodgement_Zone__c where Name=:aLP.APT_Lodgement_Zone__c  ORDER BY APT_Post_Code_Start__c];
                  
            	//STP-4984 Adding List to Map in order to get the LP range
                  if(lstLodgementZone.size()>0){
                      postCodeStart = String.valueof(lstLodgementZone[0].APT_Post_Code_Start__c);
                      postCodeEnd = String.valueof(lstLodgementZone[lstLodgementZone.size()-1].APT_Post_Code_End__c);                 
                  } 
            	for(APT_Lodgement_Zone__c newLP :lstLodgementZone){
                    mapLodgement.put(String.valueof(newLP.APT_Post_Code_Start__c),String.valueof(newLP.APT_Post_Code_End__c)); 
                    }
               }
             system.debug('mapkeyset'+mapLodgement.keySet());
             system.debug('mapvalues'+mapLodgement.values()); // STP-4984 Krishna Velani: logic completes here
           
        } catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }  
        
        return null;
    }  
    
    /**
       Method to show all lodgement point records with in lodgement Zone.
     **/
    public PageReference showallLodgementpoints() {
    
    try{ 
      listAgreementLineItemWrap.clear();
      if(source.equalsIgnoreCase(APT_Constants.PRODSPECIFIC) && aLP.APT_Lodgement_Zone__c !=null){      
       listLodgementPointWrapper =new List<lodgementPointWrapper>();
       lodgementPointWrapper lpWrapper;
 
       // Adrian Recio, Replaced Business Unit with APT Business Unit , 22/5/2017
       for(Network__c nw :[select id,Name,Post_Code__c,State__c,APT_Business_Unit__c,APT_eParcel_Enabled__c,Org_ID__c,APT_DWS_ID__c,
                                  Network_Address__c,APT_Transport_Capability__c,APT_MCAT__c,APT_Threshold_Categories__c from Network__c 
                                  where Post_Code__c >=:postCodeStart AND 
                                  Post_Code__c <=:postCodeEnd AND 
                                  Status__c != :APT_Constants.CLOSED AND 
                                  APT_Business_Unit__c!=null AND 
                                  recordtypeID in (Select id from RecordType where DeveloperName in 
                                                  (:APT_Constants.DELIVERY1,:APT_Constants.RETAIL2,:APT_Constants.BUSINESS_HUB3) 
                                                  and SobjectType = :APT_Constants.NETWORK_C1) ORDER BY Post_Code__c 
                                                  limit: recordsperpage OFFSET: offSetVal]){
        
        lpWrapper = new lodgementPointWrapper();
        lpWrapper.IsSelected = false;
        lpWrapper.lodgementPoint = nw;
        listLodgementPointWrapper.add(lpWrapper);              
       } 
       
       // Adrian Recio, Replaced Business Unit with APT Business Unit , 22/5/2017
       searchRecCount = [select count() from Network__c where Post_Code__c >=:postCodeStart AND Post_Code__c <=:postCodeEnd 
                            AND Status__c != :APT_Constants.CLOSED /*AND APT_Apttus_LP__c=True*/ AND APT_Business_Unit__c!=null 
                            AND recordtypeID in (Select id from RecordType where DeveloperName in
                            (:APT_Constants.DELIVERY1,:APT_Constants.RETAIL2,:APT_Constants.BUSINESS_HUB3) 
                            and SobjectType = :APT_Constants.NETWORK_C1)];
       
       
       if(listLodgementPointWrapper.size() == 0){
             haserrorMessages = true;
             ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, APT_Constants.MSG_NO_LODGEMENT_POINT_ZONE));
             return null;
        } 
           stateVal=APT_Constants.SELECT_OPTION_NONE;
           lodgementPoint.Post_Code__c =null;
           bussinessUnit =APT_Constants.SELECT_OPTION_NONE;       
        
      }
        } catch(Exception ex) {
           haserrorMessages = true;
           ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
           return null;
        }    
        return null;
    }
    
    
     /** 
        Method to get the First records of Search results 
    **/ 
    
    public void searchLPButton(){
         try {
             offSetVal =0;
             SearchLP();     
        
         }  catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
           
        } 
     }
   
  
   /** 
        Method to get the Previous records of Search results 
   **/  
    
    public void goPrevious(){
         try {
             offSetVal =offSetVal-recordsperpage;
             SearchLP();
         }  catch(Exception ex) {
                haserrorMessages = true;
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
               
        } 
    }
    
    /** 
        Method to get the next records of Search results 
    **/ 
    
    public pageReference goNext(){
         try {
             offSetVal =offSetVal+recordsperpage;  
                    
             if(offSetVal >2000){
                haserrorMessages = true;
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, APT_Constants.MORE_THAN_2000_LP));
                return null;         
             }
             
             SearchLP();
             return null;
         }  catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        } 
    }
    
    /** 
        Method to get the Last records of Search results 
    **/ 
    
    public pageReference goLast(){         
         try {
             Integer count = 0;
             while ((searchRecCount - count) > recordsperpage) {              
                count = count+recordsperpage;
                offSetVal = count;       
             }
             if(offSetVal >2000){
                haserrorMessages = true;
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, APT_Constants.MORE_THAN_2000_LP));
                return null;         
             }
                      
                SearchLP();
                
               return null; 
         }  catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        } 
    }
    

    /**
       Method to construct the dynamic SOQL query and to get the Lodgement point (Network) records based on filter criteria.
     **/
     public PageReference SearchLP(){   
      String tempBusinessUnit = bussinessUnit;     
      try{ 
        haserrorMessages = False; 
        String selectedPostCode;
        String selectedState;
        String TransportCapability;
        String eParcelEnabled;
        String postCodeStartLZ;
        String postCodeEndLZ;
        List<ID> networkHubIds = new List<ID>();
        listLodgementPointWrapper =new List<lodgementPointWrapper>(); 
        listAgreementLineItemWrap.clear();         
        
        //Get Included LP Detils from Custom Metadata
        Map<String, List<String>> inclExclLPModel = APT_Utils.getIncExcLPDetails(productId);
         
        if(lodgementPoint.Post_Code__c == Null && stateVal ==APT_Constants.SELECT_OPTION_NONE && domesticLodgementZone==APT_Constants.SELECT_OPTION_NONE && bussinessUnit ==APT_Constants.SELECT_OPTION_NONE && lodgementPoint.APT_Transport_Capability__c == Null && lodgementPoint.APT_eParcel_Enabled__c ==Null){             
              haserrorMessages = true;
              ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, APT_Constants.MSG_FILL_FILTER));
              return null;        
        }
            // STP-4984 Using Map values to set new search range of LP
          Integer count=0;
        if(lodgementPoint.Post_Code__c != Null && source.equalsIgnoreCase(APT_Constants.PRODSPECIFIC) && aLP.APT_Lodgement_Zone__c !=null){            
            
            Decimal postCodeEntered= Integer.valueof(lodgementPoint.Post_Code__c);
          /**  if(aLISelected.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__c !=Null && postCodeEntered < aLISelected.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Post_Code_Start__c || postCodeEntered > aLISelected.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Post_Code_End__c){
              haserrorMessages = true;
              ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, APT_Constants.MSG_POSTCODE_OUTSIDE_ZONE));
              return null;                
            }   **/  
             for(string startPC:mapLodgement.keySet()){
              	string endPC=mapLodgement.get(startPC);
              	system.debug('startpostcode'+startPC);
              	system.debug('endpostcode'+endPC);
              
              	if(postCodeEntered < Decimal.valueof(startPC)||postCodeEntered > Decimal.valueof(endPC)){
                  count++;
              	}
         	 }
         	if(count==mapLodgement.size() && (aLISelected.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) || aLISelected.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS))){
        		haserrorMessages = true;
         		ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, APT_Constants.MSG_POSTCODE_OUTSIDE_ZONE));
         		return null;
            	} //STP-4984 Krishna Velani: logic completes here
            
          }            
            String queryStr=APT_Constants.QUERY_STR1 ;
        
            string countQryStr =APT_Constants.COUNTQRYSTR1;
        
        	// STP-4984 Krishna Velani: reframed the query formation to iterate through entire range and append related Post codes
            if(source.equalsIgnoreCase(APT_Constants.PRODSPECIFIC) && aLP.APT_Lodgement_Zone__c !=null){   
                Integer countPostCodes=0;
                for(string startPC: mapLodgement.keySet())
      			  {
          	  		string endPC=mapLodgement.get(startPC);
           	 		countPostCodes += 1;

            		if(string.isNotBlank(startPC) && string.isNotBlank(endPC))
            		{
               		 if(mapLodgement.size() > 1 && countPostCodes == 1)
               		 {
                   	 queryStr = queryStr +' AND ((Post_Code__c >=:startPC AND Post_Code__c <=:endPC)';
                   	 countQryStr = countQryStr +' AND ((Post_Code__c >=:startPC AND Post_Code__c <=:endPC)';
               		 }

               		 else if(countPostCodes > 1 && countPostCodes < mapLodgement.size())
                	{
                    queryStr = queryStr +' OR (Post_Code__c >=:startPC AND Post_Code__c <=:endPC)';
                    countQryStr = countQryStr +' OR (Post_Code__c >=:startPC AND Post_Code__c <=:endPC)';
                	}

               		 else if(countPostCodes == mapLodgement.size() && countPostCodes != 1)
               		 {
                    queryStr = queryStr +' OR (Post_Code__c >=:startPC AND Post_Code__c <=:endPC))';
                    countQryStr = countQryStr +' OR (Post_Code__c >=:startPC AND Post_Code__c <=:endPC))';
                	}

                	else
                	{
                    queryStr = queryStr + APT_Constants.AND_PC_STRING;
                    countQryStr = countQryStr + APT_Constants.AND_PC_STRING;
                	}
                System.debug('countPostCodes:'+ countPostCodes);
                System.debug('Query String:'+ queryStr);

            }

        }//STP-4984 logic completes here
           }
            if(String.IsNotBlank(lodgementPoint.Post_Code__c)){
                selectedPostCode = lodgementPoint.Post_Code__c;  
                
                if((APT_Constants.HUB).equalsIgnoreCase(bussinessUnit)){
                    List<APT_Network_Hubs__c> networkHubsList = [select id, APT_Post_Code__c,APT_Parent_Hub__c 
                                                                    from APT_Network_Hubs__c 
                                                                    where APT_Post_Code__c =: selectedPostCode];
                                                                    
                    if(networkHubsList != null && networkHubsList.size() > 0){
                        for(APT_Network_Hubs__c hub : networkHubsList){
                            networkHubIds.add(hub.APT_Parent_Hub__c);
                        }
                    }
                }
                String postCodeStr = APT_Constants.POST_CODE_STRING2;
                
                
                queryStr = queryStr + APT_Constants.POST_CODE_STRING2;  
                countQryStr = countQryStr +APT_Constants.POST_CODE_STRING2; 
            }        
             if(!(stateVal.equalsIgnoreCase(APT_Constants.SELECT_OPTION_NONE))){
                selectedState = stateVal;
                queryStr = queryStr + APT_Constants.AND_STATE_STRING1;   
                countQryStr = countQryStr + APT_Constants.AND_STATE_STRING1; 
            }
            if(source==APT_Constants.GENERIC && domesticLodgementZone!=APT_Constants.SELECT_OPTION_NONE){                
                List<APT_Lodgement_Zone__c> lstLZ = [select id,name,APT_Post_Code_Start__c,APT_Post_Code_End__c from APT_Lodgement_Zone__c where Name=:domesticLodgementZone ORDER BY APT_Post_Code_Start__c];                  
                  if(lstLZ.size()>0){
                      postCodeStartLZ = String.valueof(lstLZ[0].APT_Post_Code_Start__c);
                      postCodeEndLZ = String.valueof(lstLZ[lstLZ.size()-1].APT_Post_Code_End__c);                 
                  } 
                
                queryStr = queryStr + APT_Constants.AND_POST_CODE_STRING3;   
                countQryStr = countQryStr + APT_Constants.AND_POST_CODE_STRING3; 
            }            
            if(!bussinessUnit.equalsIgnoreCase(APT_Constants.SELECT_OPTION_NONE)){  
                bussinessUnit += '%';          
                queryStr = queryStr + APT_Constants.AND_BUSINESS_UNIT_1; 
                countQryStr = countQryStr + APT_Constants.AND_BUSINESS_UNIT_1;  
            }
            
            if(String.IsNotBlank(lodgementPoint.APT_Transport_Capability__c)){
                TransportCapability= lodgementPoint.APT_Transport_Capability__c;
                if(TransportCapability.equalsIgnoreCase(APT_Constants.TRANSPORT_CAPABILITY_EITHER_VAN_OR_TRUCK))
                {
                    queryStr = queryStr + APT_Constants.AND_TRANSPORT_CAPABILITY1;
                    countQryStr = countQryStr + APT_Constants.AND_TRANSPORT_CAPABILITY1; 
                }
                else
                {
                    string tempInput = APT_Constants.SEPARATOR_PERCENT + TransportCapability + APT_Constants.SEPARATOR_PERCENT;
                    queryStr = queryStr + APT_Constants.AND_TRANSPORT_CAPABILITY2;
                    countQryStr = countQryStr + APT_Constants.AND_TRANSPORT_CAPABILITY2; 
                } 
            }
            if(String.IsNotBlank(lodgementPoint.APT_eParcel_Enabled__c)){
                eParcelEnabled= lodgementPoint.APT_eParcel_Enabled__c;
                queryStr = queryStr + APT_Constants.AND_EPARCEL_ENABLED1; 
                countQryStr = countQryStr + APT_Constants.AND_EPARCEL_ENABLED1;      
            }

            //STP-4293 STPAC - DLWT: Lodgement Point Updates
            //Filter Lodgment Points based on Custom Metadata
            if(inclExclLPModel != null && inclExclLPModel.size() > 0)
            {
                List<string> incExcLPs = new List<string>();

                if(inclExclLPModel.get(APT_Constants.INCLUDE) != null)
                {
                    incExcLPs = inclExclLPModel.get(APT_Constants.INCLUDE);
                    queryStr = queryStr + APT_Constants.AND_INCLUDE_LP_FILTER;
                    countQryStr = countQryStr + APT_Constants.AND_INCLUDE_LP_FILTER;
                }
                else if(inclExclLPModel.get(APT_Constants.EXCLUDE) != null)
                {
                    incExcLPs = inclExclLPModel.get(APT_Constants.EXCLUDE);
                    queryStr = queryStr + APT_Constants.AND_EXCLUDE_LP_FILTER;
                    countQryStr = countQryStr + APT_Constants.AND_EXCLUDE_LP_FILTER;
                }
            }

             queryStr = queryStr +APT_Constants.ORDER_BY_POST_CODE1;
             searchRecCount = Database.countQuery(countQryStr); 
             lodgementPointWrapper lpWrapper;     

             system.debug('LP Selected Post Code:' + selectedPostCode );
             system.debug('LP Networkhub Ids:' + networkHubIds );
             system.debug('LP Postcode Start:' + postCodeStart);
             system.debug('LP Postcode Start:' + postCodeEnd );
             system.debug('LP Query:' + queryStr);

            for(Network__c lp : Database.query(queryStr)) {
                lpWrapper = new lodgementPointWrapper();
                lpWrapper.IsSelected = false;
                lpWrapper.lodgementPoint = lp;
                listLodgementPointWrapper.add(lpWrapper);              
            }  
            
            
            
          if(listLodgementPointWrapper.size() == 0){
                 haserrorMessages = true;
                 ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, APT_Constants.MSG_NO_LODGEMENT_POINT_FOUND ));
                 return null;
            }                
         } catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        } 
        finally
        {
            bussinessUnit = tempBusinessUnit;
        }
        return null;
    }  
    
    
    /**
        Method to insert selected Agreement lodgement Point 
     **/   
     public PageReference AddLP(){  
      try{  
        List<Network__c> lstLodgementPointselected =new List<Network__c>();
        Map<Id,APT_Agreement_Lodgement_Point__c> mapAgLP; 
        List<APT_Agreement_Lodgement_Point__c> lstALPInsert =new List<APT_Agreement_Lodgement_Point__c>(); 
         // Defect 1568
        /*if(cashAccCount >0 && String.isBlank(cashAcc)){
                 haserrorMessages = true;
                 ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.error, APT_Constants.PLEASE_SELECT_CASH_1));
                 return null;           
        }
        if(subAccCount >0 && String.isBlank(subAcc)){
                 haserrorMessages = true;
                 ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.error, APT_Constants.PLEASE_SELECT_SUB_1));
                 return null;           
        }
        if(chargeAccCount>0 && String.isBlank(chargeAcc)){
                 haserrorMessages = true;
                 ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.error, APT_Constants.PLEASE_SELECT_CHARGE_1));
                 return null;           
        } */
         
        for(lodgementPointWrapper lps : listLodgementPointWrapper){
            if(lps.IsSelected == true){
               lstLodgementPointselected.add(lps.lodgementPoint);
               lps.IsSelected = False;
            }        
        }
        
      if(lstLodgementPointselected.size()==0){
                 haserrorMessages = true;
                 ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, APT_Constants.MSG_PLEASE_SELECT_LODGEMENT_POINT));
                 return null;           
      } else {  
        
         String qryStrg = APT_Constants.QRYSTRG1;
        
        ApexPages.Message pagemessage;
        for(APT_Agreement_Lodgement_Point__c agLP: Database.query(qryStrg)){       
        
        if((source ==APT_Constants.PRODSPECIFIC && agLP.APT_Agreement_Line_Item__c == aLISelected.ID) || (source ==APT_Constants.GENERIC && agLP.APT_Product__c == Null)){             
             haserrorMessages = true;
             pagemessage = new ApexPages.Message(ApexPages.Severity.Info, APT_Constants.MSG_LODGEMENT_POINTS_ALREADY_ADDED);
             ApexPages.AddMessage(pagemessage);
             return null;    
         }      
        }
      } 
          APT_Agreement_Lodgement_Point__c aLPInsert;
          for( Network__c lodgementPointselected :lstLodgementPointselected){           
            
            aLPInsert =new APT_Agreement_Lodgement_Point__c();       
            aLPInsert.APT_Agreement__c= agreementId;
            aLPInsert.APT_Organisation__c = agreement.Apttus__Account__c;
            if(source ==APT_Constants.PRODSPECIFIC){
             aLPInsert.APT_Agreement_Line_Item__c = aLISelected.ID;
             aLPInsert.APT_Product__c =aLISelected.Apttus__ProductId__r.name;
             aLPInsert.APT_Lodgement_Zone__c=aLISelected.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.Name;
             aLPInsert.APT_Lodgement_Zone_Lookup__c =aLISelected.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__c;
            }                     
            aLPInsert.APT_Selected_Lodgement_Point__c=lodgementPointselected.Name;
            aLPInsert.APT_Lodgement_Point_Lookup__c= lodgementPointselected.ID;       
            aLPInsert.APT_LP_Post_Code__c = lodgementPointselected.Post_Code__c;
            aLPInsert.APT_LP_State__c =lodgementPointselected.State__c;

            // Adrian Recio, Replaced Business Unit with APT Business Unit , 22/5/2017
            aLPInsert.APT_Outlet_Type__c =lodgementPointselected.APT_Business_Unit__c;
            aLPInsert.APT_Billing_Account__c = aLP.APT_Billing_Account__c;
            aLPInsert.APT_Address__c=lodgementPointselected.Network_Address__c;
            aLPInsert.APT_eParcel_Enabled__c=lodgementPointselected.APT_eParcel_Enabled__c;
            aLPInsert.APT_Transport_Capability__c=lodgementPointselected.APT_Transport_Capability__c;
            aLPInsert.APT_Organisation_ID__c=lodgementPointselected.Org_ID__c;
            aLPInsert.APT_DWS_ID__c=lodgementPointselected.APT_DWS_ID__c;
            aLPInsert.APT_Cash_Account__c=aLP.APT_Cash_Account__c;
            aLPInsert.APT_Charge_Account__c=aLP.APT_Charge_Account__c;
            aLPInsert.APT_Sub_Account__c=aLP.APT_Sub_Account__c;            
               
               lstALPInsert.add(aLPInsert);         
           } 
           
            if(lstALPInsert.size()>0){
            insert lstALPInsert;        
            }
            
            listAgreementLPLodgementPointSelected = [select id,APT_Status__c,APT_Billing_Account__c ,APT_Address__c,APT_eParcel_Enabled__c,APT_Transport_Capability__c,APT_Organisation_ID__c,APT_DWS_ID__c,APT_Selected_Lodgement_Point__c,APT_LP_Post_Code__c,APT_Lodgement_Zone__c,APT_Product__c,APT_Outlet_Type__c,APT_Lodgement_Point_Name__c,APT_Billing_Account_Flag__c from APT_Agreement_Lodgement_Point__c  where APT_Agreement__c =:agreementId]; 
      
     } catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
     } 
        return null;
  } 
    
     /**
        This method to deactivate lodgement points.
     **/
    public PageReference deactivateLP() {
      try{ 
       string deactivateALIId= Apexpages.currentPage().getParameters().get(APT_Constants.DEACTIVATEALIID);
       
       APT_Agreement_Lodgement_Point__c lp =[select id,APT_Status__c from APT_Agreement_Lodgement_Point__c  where id =:deactivateALIId];
       lp.APT_Status__c = APT_Constants.INACTIVE;
       lp.APT_Deactivated_Date__c=system.now();
       lp.APT_Deactivated_By__c= userinfo.getuserid();       
       update lp;
       listAgreementLPLodgementPointSelected = [select id,APT_Status__c,APT_Billing_Account__c ,APT_Address__c,APT_eParcel_Enabled__c,APT_Transport_Capability__c,APT_Organisation_ID__c,APT_DWS_ID__c,APT_Selected_Lodgement_Point__c,APT_LP_Post_Code__c,APT_Lodgement_Zone__c,APT_Product__c,APT_Outlet_Type__c, APT_Lodgement_Point_Name__c,APT_Billing_Account_Flag__c from APT_Agreement_Lodgement_Point__c where APT_Agreement__c =:agreementId]; 
       } catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        } 
       return null;
    }
    
    /**
       Method to show the pick list values for Bussiness unit field
     **/
    public List<SelectOption> getBussinessPickval() {
        try {
            List<SelectOption> options = new List<SelectOption>();
                options.add(new SelectOption(APT_Constants.SELECT_OPTION_NONE,APT_Constants.NONE_2));
                options.add(new SelectOption(APT_Constants.HUB,APT_Constants.HUB));
                options.add(new SelectOption('Retail','Retail'));
                //options.add(new SelectOption(APT_Constants.RETAIL_LPO,APT_Constants.RETAIL_LPO));
                //options.add(new SelectOption(APT_Constants.RETAIL_CORP,APT_Constants.RETAIL_CORP));
                options.add(new SelectOption(APT_Constants.PARCEL_SERVICES,APT_Constants.PARCEL_SERVICES));                        
                options.add(new SelectOption(APT_Constants.POSTAL_DELIVERY,APT_Constants.POSTAL_DELIVERY));
                return options; 
        }  catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        } 
    }
    
    /**
       Method to fecth the pick list values for Domestic Lodgement Zone
     **/
    public List<SelectOption> getdomesticLodgementZoneVal() {
       List<SelectOption> options = new List<SelectOption>();
       try {
           SelectOption so;
            options.add(new SelectOption(APT_Constants.SELECT_OPTION_NONE,APT_Constants.NONE_2));
            for(AggregateResult ar:[select Name from APT_Lodgement_Zone__c Group By Name limit 1000]){   
                so = new SelectOption(string.valueOf(ar.get(APT_Constants.NAME2)),string.valueOf(ar.get(APT_Constants.NAME2)));
                options.add(so);
                }
                return options;   
       }  catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        } 
     }
    
    /**
       Method to show the pick list values for Bussiness unit field
     **/
    public PageReference backToContract() {       
        try{
        return new pageReference (APT_Constants.SEPERATOR_BACKWARD_SLASH + agreementId );
        } catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        } 
    }
    
     /**
       Method to show the pick list values for Bussiness unit field
     **/
    public void setstatePickvalues(ID currentLineItemId) {
        try{
          Schema.DescribeFieldResult fieldResult = Network__c.State__c.getDescribe();
          List<Schema.PicklistEntry> pickVals = fieldResult.getPicklistValues();
          statePickval= new List<SelectOption>();
          statePickval.add(new SelectOption(APT_Constants.SELECT_OPTION_NONE,APT_Constants.NONE_2));       
            
            String selectedStates;
            list<Apttus_Config2__ProductAttributeValue__c> lstProdAttVal= [select id,APT_Lodgement_State__c from Apttus_Config2__ProductAttributeValue__c where Apttus_Config2__LineItemId__c =:currentLineItemId];
            
            if(lstProdAttVal.size()>0){            
            selectedStates =  lstProdAttVal[0].APT_Lodgement_State__c;
            } 
            SelectOption so;
            if(!string.ISEMPTY(selectedStates)){
             set<String> setselectedVals=new set<String>();
             setselectedVals.addall(selectedStates.split(APT_Constants.SEPERATOR_SEMI_COLON));              
               for(Schema.PicklistEntry s : pickVals){
                  if(setselectedVals.contains(String.valueof(s.getValue()))){
                   so = new SelectOption(s.getLabel(),s.getValue());      
                   statePickval.add(so);            
                }
               }
            } else{  
                
          for(Schema.PicklistEntry s : pickVals){
              so = new SelectOption(s.getLabel(),s.getValue());
              statePickval.add(so);         
          }
         }       
       
          } catch(Exception ex) {
                haserrorMessages = true;
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                
          }
    }
    
    
    
    /**
       Method to redirect to new site inspection page.
     **/
    public PageReference redirectSite() {      
      try{
        
        string redirectALIId= Apexpages.currentPage().getParameters().get(APT_Constants.REDIRECTALIID); 
        String lkid = APT_Constants.LKID;
        
        Map<String,APT_SiteInspectionLookupFieldIds__c> mapSiteLK =APT_SiteInspectionLookupFieldIds__c.getall();
        
        APT_Agreement_Lodgement_Point__c siteLP = [SELECT Id, Name,
                                                  APT_Organisation__c, APT_Organisation__r.Name,
                                                  APT_Agreement__c, APT_Agreement__r.name,
                                                  APT_Agreement__r.Apttus__Related_Opportunity__r.KeyContact__r.Name,
                                                  APT_Lodgement_Point_Lookup__c, APT_Lodgement_Zone_Lookup__c,  
                                                  APT_Lodgement_Point_Lookup__r.Name, APT_Lodgement_Point_Name__c,
                                                  APT_Agreement__r.Apttus__Related_Opportunity__r.KeyContact__r.Mailingstreet,
                                                  APT_Agreement__r.Apttus__Related_Opportunity__r.KeyContact__r.MailingCity,
                                                  APT_Agreement__r.Apttus__Related_Opportunity__r.KeyContact__r.MailingPostalCode,
                                                  APT_Agreement__r.Apttus__Related_Opportunity__r.KeyContact__r.MailingState,
                                                  APT_Lodgement_Zone_Lookup__r.Name, APT_Billing_Account_Flag__c
                                                  from APT_Agreement_Lodgement_Point__c 
                                                  where id=: redirectALIId];
        Schema.DescribeSObjectResult destination = APT_Site_Inspection__c.SObjectType.getDescribe();
        PageReference pageRef = new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH + destination.getKeyPrefix() + APT_Constants.FORWARD_E);
        
        if(mapSiteLK.size()>0){        
        pageRef.getParameters().put(mapSiteLK.get(APT_Constants.SOQL_AGREEMENT_LODGEMENT_POINT_OBJECT).Field_Id__c,siteLP.Name);
        pageRef.getParameters().put(mapSiteLK.get(APT_Constants.SOQL_AGREEMENT_LODGEMENT_POINT_OBJECT).Field_Id__c+lkid,siteLP.id);
        pageRef.getParameters().put(mapSiteLK.get(APT_Constants.APT_ORGANISATION_C_OBJECT).Field_Id__c,siteLP.APT_Organisation__r.Name);
        pageRef.getParameters().put(mapSiteLK.get(APT_Constants.APT_ORGANISATION_C_OBJECT).Field_Id__c+lkid,siteLP.APT_Organisation__c);
        pageRef.getParameters().put(mapSiteLK.get(APT_Constants.APT_CONTRACT_C_OBJECT).Field_Id__c,siteLP.APT_Agreement__r.name);
        pageRef.getParameters().put(mapSiteLK.get(APT_Constants.APT_CONTRACT_C_OBJECT).Field_Id__c+lkid,siteLP.APT_Agreement__c);
        pageRef.getParameters().put(mapSiteLK.get(APT_Constants.APT_LODGEMENT_POINT_C_OBJECT).Field_Id__c,siteLP.APT_Lodgement_Point_Lookup__r.name);
        pageRef.getParameters().put(mapSiteLK.get(APT_Constants.APT_LODGEMENT_POINT_C_OBJECT).Field_Id__c+lkid,siteLP.APT_Lodgement_Point_Lookup__c);
        pageRef.getParameters().put(mapSiteLK.get(APT_LODGEMENT_ZONE_C_OBJECT).Field_Id__c,siteLP.APT_Lodgement_Zone_Lookup__r.name); 
        pageRef.getParameters().put(mapSiteLK.get(APT_LODGEMENT_ZONE_C_OBJECT).Field_Id__c+lkid,siteLP.APT_Lodgement_Zone_Lookup__c);   
        pageRef.getParameters().put(mapSiteLK.get(APT_Constants.APT_CUSTOMER_CONTACT_NAME_OBJECT).Field_Id__c,siteLP.APT_Agreement__r.Apttus__Related_Opportunity__r.KeyContact__r.Name);
        pageRef.getParameters().put(mapSiteLK.get(APT_Constants.APT_COLLECTION_STREET_ADDRESS_C_OBJECT).Field_Id__c,siteLP.APT_Agreement__r.Apttus__Related_Opportunity__r.KeyContact__r.Mailingstreet);
        pageRef.getParameters().put(mapSiteLK.get(APT_Constants.APT_SUBURB_C_OBJECT).Field_Id__c,siteLP.APT_Agreement__r.Apttus__Related_Opportunity__r.KeyContact__r.MailingCity);
        pageRef.getParameters().put(mapSiteLK.get(APT_Constants.APT_POSTAL_CODE_C_OBJECT).Field_Id__c,siteLP.APT_Agreement__r.Apttus__Related_Opportunity__r.KeyContact__r.MailingPostalCode);
        pageRef.getParameters().put(mapSiteLK.get(APT_Constants.APT_STATE_C_OBJECT).Field_Id__c,siteLP.APT_Agreement__r.Apttus__Related_Opportunity__r.KeyContact__r.MailingState);
        }
       
        /* PageRef.getParameters().put('CF00NO0000001zd43',siteLP.Name);
        pageRef.getParameters().put('CF00NO0000001zd43_lkid',siteLP.id);
        pageRef.getParameters().put('CF00NO0000001sy2n',siteLP.APT_Organisation__r.Name);
        pageRef.getParameters().put('CF00NO0000001sy2n_lkid',siteLP.APT_Organisation__c);
        pageRef.getParameters().put('CF00NO0000001sy3C',siteLP.APT_Agreement__r.name);
        pageRef.getParameters().put('CF00NO0000001sy3C_lkid',siteLP.APT_Agreement__c);
        pageRef.getParameters().put('CF00NO0000001zcxH',siteLP.APT_Lodgement_Point_Lookup__r.name);
        pageRef.getParameters().put('CF00NO0000001zcxH_lkid',siteLP.APT_Lodgement_Point_Lookup__c);
        pageRef.getParameters().put('CF00NO0000001zcxl',siteLP.APT_Lodgement_Zone_Lookup__r.name);
        pageRef.getParameters().put('CF00NO0000001zcxl_lkid',siteLP.APT_Lodgement_Zone_Lookup__c);*/

        pageRef.setRedirect(true);
        return pageRef; 
        
        } catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));            
            return null;
        } 
    }

   public static final string APT_LODGEMENT_ZONE_C_OBJECT = 'APT_Lodgement_Zone__c';
    /**
       Wrapper class to show radio button and Lodgement point records in table
     **/  
   public with sharing class lodgementPointWrapper {
        public boolean IsSelected {get; set;}
        public Network__c lodgementPoint {get; set;}    
   
    }
    
     /**
       Wrapper class to show radio button and Agreement Line records in table
     **/  
    public with sharing class agreementLIWrapper {
        public boolean IsSelectedLI {get; set;}
        public Apttus__AgreementLineItem__c AgLI {get; set;}    
   
    }
    

    public Boolean displayPopup {get;set;}
    public APT_Agreement_Lodgement_Point__c alpSelectedForupdate {get;set;}
    /**
     This method will display popup
    **/    
    public void showPopup() {
        try {
            string redirectALIId= Apexpages.currentPage().getParameters().get(APT_Constants.REDIRECTALIID); 
            alpSelectedForupdate = [select id, APT_Billing_Account__c,APT_Billing_Account__r.Name, APT_Cash_Account__c,APT_Cash_Account__r.Name, APT_Charge_Account__c,APT_Charge_Account__r.Name, 
                                        APT_Sub_Account__c,APT_Sub_Account__r.Name, Name, APT_Lodgement_Point_Name__c, APT_Billing_Account_Flag__c
                                        from APT_Agreement_Lodgement_Point__c where id =: redirectALIId];
            
            if(alpSelectedForupdate != null){
                system.debug('*** alpSelectedForupdate **'+alpSelectedForupdate);
                displayPopup = true;
                cashAcc = alpSelectedForupdate.APT_Cash_Account__r.Name;//'';
                billingAcc = alpSelectedForupdate.APT_Billing_Account__r.Name;//'';
                chargeAcc = alpSelectedForupdate.APT_Charge_Account__r.Name;//'';
                subAcc = alpSelectedForupdate.APT_Sub_Account__r.Name;//'';
            }  
        } catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        } 
    }
    /**
     This method will close popup
    **/    
    public void closePopup() {
        displayPopup = false;
    }
    /**
     This method will redirect from popup
    **/
    public void redirectPopup() {
        system.debug('*** alpSelectedForupdate.APT_Billing_Account__c ***'+alpSelectedForupdate.APT_Billing_Account__c);
        if(String.isNotBlank(alpSelectedForupdate.APT_Billing_Account__c) 
                || String.isNotBlank(alpSelectedForupdate.APT_Sub_Account__c) 
                || String.isNotBlank(alpSelectedForupdate.APT_Cash_Account__c) 
                || String.isNotBlank(alpSelectedForupdate.APT_Charge_Account__c) ){
                    
            alpSelectedForupdate.APT_Billing_Account_Flag__c = true;
            try
            {
                update alpSelectedForupdate;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, APT_Constants.Record_Update_Successfull));
                listAgreementLPLodgementPointSelected = [select id,APT_Status__c,APT_Billing_Account__c ,APT_Address__c,APT_eParcel_Enabled__c,APT_Transport_Capability__c,APT_Organisation_ID__c,APT_DWS_ID__c,APT_Selected_Lodgement_Point__c,APT_LP_Post_Code__c,APT_Lodgement_Zone__c,APT_Product__c,APT_Outlet_Type__c, APT_Lodgement_Point_Name__c,APT_Billing_Account_Flag__c from APT_Agreement_Lodgement_Point__c where APT_Agreement__c =:agreementId]; 
                cashAcc = '';
                billingAcc = '';
                chargeAcc = '';
                subAcc = '';
            } catch(Exception ex) {
                haserrorMessages = true;
                //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            
            } 
        }
        
        displayPopup = false;
    }
    



}