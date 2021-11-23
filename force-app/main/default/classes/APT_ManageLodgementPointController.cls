/**
Description: This apex class is the controller for Visualforce page - APT_ManageLodgementPoint.
Created By: Raviteja Epuri
Created Date: 14th Nov, 2015
Last Modified By: Krishna Velani
Last Modified Date: 7th April, 2021
Description: STP-4984 STPAC - Update the lodgement search solution
*/

public with sharing class APT_ManageLodgementPointController { 
        
    Public Apttus_Config2__LineItem__c lineItem{get;set;}
    Public network__c Network{get;set;}
    Public List<Network__c> listLodgementPointResult;
    Public Boolean haserrorMessages{get;set;}
    Public list<lodgementPointWrapper> listLodgementPointWrapper{get; set;}
    Public list<selectedlodgementPointWrapper> listSelectedLodgementPointWrapper{get; set;}
    Public ID prodConfigId { get; set; }
    public String billingAcc { get; set; }
    public Id billingAccId { get; set; }
    public String bussinessUnit { get; set; }
    public String stateVal{ get; set; }
    public String domesticLodgementZone{get; set;}
    public String source { get; set; }
    public List<Network__c> ListlodgementPointselected;
    public List<Network__c> ListlodgementPointselectedRec;
    public String selectedLP;
    public String lZone;
    public Set<String> setLPid ;
    public Set<Id> quotesetLPid ;
    public Apttus_Config2__ProductConfiguration__c prodConfigurationId;
    public Apttus_Proposal__Proposal__c quote;
    public List<Apttus_Config2__LineItem__c> listOfLI;
    Map<Id,Apttus_Config2__LineItem__c > mapLI;
    Set<Id> setLILP;
    public List<Network__c>listLodgementPoints; 
    public Billing_Account__c billingAccountRec;
    public Set<String> quotesetLPidDel;
    public Set<String> setSelectedLP;
    set<string> setProductNames = new set<string>();
    set<string> setpostcodes = new set<string>();
    List<APT_Lodgement_Zone__c> lstLodgementZone =new List<APT_Lodgement_Zone__c>();
    public string postCodeStart;
    public string postCodeEnd;
    Public ID lineItemId;
    public integer searchRecCount{get;set;}
    public integer offSetVal{get;set;}
    public integer recordsperpage;
    Map<string,string> mapUrlParam= new Map<string,string>();
    Public String selectedStates;
    public String parentPageURL;
    public String productId;
    List<string> listLZ = new List<string>();
    Map<string,string> mapLZ =new Map<string,string>();
    Map<id,APT_Lodgement_Zone__c> mapLZRec =new Map<id,APT_Lodgement_Zone__c>();
    
    public static final string strTitle = 'Add Product Lodgement Point';
    public static string strGetValTitle {get{return strTitle;} set;}
    
    public static final string strSubTitle = 'Manage Quote Lodgement Point';
    public static string strGetValSubTitle {get{return strSubTitle;} set;}
    
    /**STP-4984 Krishna Velani created below map to use for new logic**/
    Map<string,string> mapLodgement =new Map<string,string>();
     /**
        Constructor to get the Ids of Line Item and Product configuration from Url
     **/
    Public APT_ManageLodgementPointController(){        
    try{
        parentPageURL = ApexPages.currentPage().getHeaders().get('Referer');
        
        listSelectedLodgementPointWrapper = new List<selectedlodgementPointWrapper>();
        network = new Network__c();
        billingAccountRec = new Billing_Account__c(); 
        listLodgementPointWrapper =new list<lodgementPointWrapper>();   
        ListlodgementPointselected = new List<Network__c> ();
        ListlodgementPointselectedRec = new List<Network__c> ();
        lineItem =new Apttus_Config2__LineItem__c();
        mapLI=new Map<Id,Apttus_Config2__LineItem__c >();
        quote = new Apttus_Proposal__Proposal__c ();           
        haserrorMessages = False;
        selectedLP=null;
        setLPid= new Set<String>();
        setSelectedLP= new Set<String>();
        quotesetLPidDel = new Set<String>();
        setLILP=new Set<Id>();
        quotesetLPid = new Set<Id>();
        offSetVal =0;
        searchRecCount=0;
        
        String referURL = ApexPages.currentPage().getHeaders().get('Referer');
        System.Debug('referURL ---->'+ referURL );
         
        if(String.IsNotBlank(referURL)){
            URL u=new URL(referURL);
            getCartParameters(u); 
        }
               
        
        if(string.iSEMPTY(System.Label.APT_Manage_LP_records_per_Page)){      
          recordsperpage = 100;
        }else{
           recordsperpage = integer.valueof(System.Label.APT_Manage_LP_records_per_Page);
        }
        
        prodConfigId=Apexpages.currentpage().getparameters().get('Id');
        lineItemId=Apexpages.currentpage().getparameters().get('lineItemId');
        prodConfigurationId = new Apttus_Config2__ProductConfiguration__c();          
        
        prodConfigurationId = [Select id,Name,Apttus_QPConfig__Proposald__c from   Apttus_Config2__ProductConfiguration__c where Id =:prodConfigId];
        quote =[Select id,Name,APT_Selected_LP__c from   Apttus_Proposal__Proposal__c where Id =:prodConfigurationId.Apttus_QPConfig__Proposald__c ];
        listOfLI = [SELECT id,name,APT_Lodgement_Zone_Selected__c,Apttus_Config2__ProductId__r.Name, Apttus_Config2__ProductId__r.ProductCode,Apttus_Config2__IsPrimaryLine__c,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c,Apttus_Config2__LineType__c,APT_Billing_Account__c,APT_Selected_LP__c,APT_Lodgement_Zone__c ,Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__c,Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.Name from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c = :prodConfigId];
        if(listOfLI.size()>0){     
            for(Apttus_Config2__LineItem__c  LI :listOfLI){
                if(LI.APT_Selected_LP__c !=null && LI.Apttus_Config2__IsPrimaryLine__c==True && LI.Apttus_Config2__LineType__c!='Option'){                   
                    String[] selectedLpList =  LI.APT_Selected_LP__c.split(',') ;
                    Integer size =selectedLpList.size();
                    String [] lastLP = selectedLpList[size-1].split('~');
                    selectedLpList[size-1]=lastLP [0];                   
                    for(Integer i=0;i<size;i++){
                       if(selectedLpList[i]!=null ||selectedLpList[i]!=''){                          
                            mapLI.put(selectedLpList[i],LI);
                            setLILP.add(selectedLpList[i]);
                        }
                    }
                    if(LI.APT_Lodgement_Zone_Selected__c!=null){
                      listLZ.addall(LI.APT_Lodgement_Zone_Selected__c.split(','));
                    }
                }

            }
        }
        
        if(lineItemId ==null){
          source ='cartbtn'; 
        }else{
          source ='lineItembtn';
        }
        String [] lastLP;
         if(source =='lineItembtn'){ 
   
            list<Apttus_Config2__ProductAttributeValue__c> lstProdAttVal= [select id,APT_Lodgement_State__c,APT_Postcode__c from Apttus_Config2__ProductAttributeValue__c where Apttus_Config2__LineItemId__c =:lineItemId ];
            if(lstProdAttVal.size()>0){
               selectedStates =  lstProdAttVal[0].APT_Lodgement_State__c;
               Network.Post_Code__c =lstProdAttVal[0].APT_Postcode__c;                
            }          
              
        setProductNames =APT_Default_Billing_Account_Products__c.getall().keyset();      
        map<Id,Apttus_Config2__LineItem__c > mapLineItem=new map<Id,Apttus_Config2__LineItem__c >([Select id, Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c,APT_Lodgement_Zone_Selected__c,Apttus_Config2__ProductId__r.Name, Apttus_Config2__ProductId__r.ProductCode, Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__c,
                    Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.Name,APT_Selected_LP__c,
                    Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Post_Code_Start__c ,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c, 
                    Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Post_Code_End__c,APT_Billing_Account__r.Name 
                    from Apttus_Config2__LineItem__c 
                    where Apttus_Config2__ConfigurationId__c =:prodConfigId AND Apttus_Config2__IsPrimaryLine__c = True AND Apttus_Config2__LineType__c !='Option']);                
        
        lineItem = mapLineItem.get(lineItemId);
        String lodgementZoneSelected= lineItem.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.Name;

        //get product id
        productId = lineItem.Apttus_Config2__ProductId__c;
        
                if(lodgementZoneSelected !='' && lodgementZoneSelected !=Null){
                  lstLodgementZone = [select id,name,APT_Post_Code_Start__c,APT_Post_Code_End__c from APT_Lodgement_Zone__c where Name=:lodgementZoneSelected  ORDER BY APT_Post_Code_Start__c];
                
                     //STP-4984 Krishna Velani added logic to add list into map to get entire lodgment point range
                  if(lstLodgementZone.size()>0){
                      postCodeStart = String.valueof(lstLodgementZone[0].APT_Post_Code_Start__c);
                      postCodeEnd = String.valueof(lstLodgementZone[lstLodgementZone.size()-1].APT_Post_Code_End__c);   
                      System.debug('PostCodeStart'+postCodeStart);
                      System.debug('PostCodeEnd'+postCodeEnd);
                  } 
                  
                    for(APT_Lodgement_Zone__c newLP :lstLodgementZone){
                       mapLodgement.put(String.valueof(newLP.APT_Post_Code_Start__c),String.valueof(newLP.APT_Post_Code_End__c)); 
                    }
               }
             system.debug('mapkeyset'+mapLodgement.keySet());
             system.debug('mapvalues'+mapLodgement.values()); // STP-4984 Krishna Velani: logic completes here
        
        Map<string,Apttus_Config2__LineItem__c> mapProdLI =new Map<string,Apttus_Config2__LineItem__c>();
        for(Apttus_Config2__LineItem__c lItem : mapLineItem.Values()){ 
            System.debug('setProductNames'+setProductNames);
          if(setProductNames.size() !=0 && setProductNames.contains(lItem.Apttus_Config2__ProductId__r.Name)){        
            mapProdLI.put(lItem.Apttus_Config2__ProductId__r.Name,lItem);
         }
        }
        
        if(mapProdLI.size()>0){
        if((lineItem.Apttus_Config2__ProductId__r.Name!=mapProdLI.values()[0].Apttus_Config2__ProductId__r.Name && lineItem.APT_Billing_Account__c!=null) || (lineItem.Apttus_Config2__ProductId__r.Name==mapProdLI.values()[0].Apttus_Config2__ProductId__r.Name)){
           billingAcc = lineItem.APT_Billing_Account__r.Name; 
           billingAccId =lineItem.APT_Billing_Account__c;         
        }else if(lineItem.Apttus_Config2__ProductId__r.Name!=mapProdLI.values()[0].Apttus_Config2__ProductId__r.Name && lineItem.APT_Billing_Account__c==null){       
           billingAcc = mapProdLI.values()[0].APT_Billing_Account__r.Name;
           billingAccId =mapProdLI.values()[0].APT_Billing_Account__c;         
        }
         
        } 
        
        
        if(setLILP.size()>0){
           if(lineItem.APT_Lodgement_Zone_Selected__c!=null){
            parseSelectedZone(lineItem.APT_Lodgement_Zone_Selected__c.split(','));
           }
            listLodgementPoints = database.query('Select ' + APT_AmendRenewUtility.getAllAgrFields('Network__c') + ' from   Network__c  where id in :setLILP');
            
           
            for(Network__c lodgementPoint :listLodgementPoints){
                
                if(mapLI.get(lodgementPoint.id).Id==lineItem.Id){
                    selectedlodgementPointWrapper LPline = new selectedlodgementPointWrapper();
                    LPline.Product =mapLI.get(lodgementPoint.id).Apttus_Config2__ProductId__r.Name;
                    //LPline.lodgementZone=mapLI.get(lodgementPoint.id).APT_Lodgement_Zone__c;   
                     if(mapLZ !=null && mapLZ.get(lodgementPoint.Id)!=null && mapLZRec.get(mapLZ.get(lodgementPoint.Id))!=null && (lineItem.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD || lineItem.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)){
                         LPline.lodgementZone=mapLZRec.get(mapLZ.get(lodgementPoint.Id)).Name; 
                        }else{
                         LPline.lodgementZone=mapLI.get(lodgementPoint.id).APT_Lodgement_Zone__c;
                     }                  
                    LPline.ntwrk = lodgementPoint ;
                    listSelectedLodgementPointWrapper.add(LPline);
                }
            }       
            
           }
         }
        else{
            if(setLILP.size()>0){
                listLodgementPoints = database.query('Select ' + APT_AmendRenewUtility.getAllAgrFields('Network__c') + ' from   Network__c  where id in :setLILP');            
                
                parseSelectedZone(listLZ);
                
                for(Network__c lodgementPoint :listLodgementPoints){
                    selectedlodgementPointWrapper LPline = new selectedlodgementPointWrapper();
                    LPline.Product =mapLI.get(lodgementPoint.id).Apttus_Config2__ProductId__r.Name;
                    //LPline.lodgementZone=mapLI.get(lodgementPoint.id).APT_Lodgement_Zone__c;
                    
                    if(mapLZ !=null && mapLZ.get(lodgementPoint.Id)!=null && mapLZRec.get(mapLZ.get(lodgementPoint.Id))!=null){
                         LPline.lodgementZone=mapLZRec.get(mapLZ.get(lodgementPoint.Id)).Name; 
                         
                        }else{
                         LPline.lodgementZone=mapLI.get(lodgementPoint.id).APT_Lodgement_Zone__c;
                         
                     }
                    LPline.ntwrk = lodgementPoint ;
                    listSelectedLodgementPointWrapper.add(LPline);
                }
            }
            if(quote.APT_Selected_LP__c!=null){
                  
                String[] selectedLpList =  quote.APT_Selected_LP__c.split(',') ;
                Integer size =selectedLpList.size();             
                if(selectedLpList[size-1].contains('~')){
                    lastLP = selectedLpList[size-1].split('~');
                    selectedLpList[size-1]=lastLP[0];
                    if(lastLP[1]!=null ||lastLP[1]!=''){
                        billingAccountRec =[SELECT id,name from Billing_Account__c where id =:lastLP[1]];
                        billingAcc=billingAccountRec.Name;
                    }
                }
                for(Integer i=0;i<size;i++){
                    quotesetLPid.add(selectedLpList[i]);
                }
                
                listLodgementPointSelectedRec  = database.query('Select ' + APT_AmendRenewUtility.getAllAgrFields('Network__c') + ' from   Network__c  where id in :quotesetLPid');
                for(Network__c lodgementPointselected1 : listLodgementPointSelectedRec){
                    selectedlodgementPointWrapper LP = new selectedlodgementPointWrapper();
                    Lp.ntwrk = lodgementPointselected1;
                    listSelectedLodgementPointWrapper.add(LP);
                }
            }            
        }
       
        } catch(Exception ex) {
            haserrorMessages = true;            
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
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
        listLodgementPointResult =new List<Network__c>();   
        
        //Get Included LP Detils from Custom Metadata
        Map<String, List<String>> inclExclLPModel = APT_Utils.getIncExcLPDetails(productId);

        if(Network.Post_Code__c == Null && stateVal =='None' && bussinessUnit =='None' && domesticLodgementZone=='None' && Network.APT_Transport_Capability__c == Null && Network.APT_eParcel_Enabled__c ==Null){             
              haserrorMessages = true;
              ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Please enter a filter parameter'));
              return null;        
        }
          
        /** STP-4984 Krishna Velani commented below to add new logic beneath
        if(Network.Post_Code__c != Null && source=='lineItembtn'){            
           
            Decimal postCodeEntered= Integer.valueof(Network.Post_Code__c);
            if(postCodeEntered < lineItem.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Post_Code_Start__c|| postCodeEntered > lineItem.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Post_Code_End__c){
              haserrorMessages = true;
              ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Entered Post Code is out side Lodgement Zone'));
             
              return null;                 
            }            
        }  **/  
        Integer count=0;
        if(Network.Post_Code__c != Null && source=='lineItembtn'){
        Decimal postCodeEntered= Integer.valueof(Network.Post_Code__c);
            system.debug('PostcodeEntered:'+postCodeEntered);
          for(string startPC:mapLodgement.keySet()){
              string endPC=mapLodgement.get(startPC);
              system.debug('startpostcode'+startPC);
              system.debug('endpostcode'+endPC);
              
              if(postCodeEntered < Decimal.valueof(startPC)||postCodeEntered > Decimal.valueof(endPC)){
                  count++;
              }
          }
          if(count==mapLodgement.size() && (lineItem.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD || lineItem.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS))
			{
 				haserrorMessages = true;
 				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Entered Post Code is out side Lodgement Zone'));
 				return null;
            } }//STP-4984 Krishna Velani: new logic completes here
          
            // Adrian Recio, Replaced Business Unit with APT Business Unit , 22/5/2017
            String queryStr='Select id,Name,Post_Code__c,State__c,APT_Business_Unit__c,APT_eParcel_Enabled__c,APT_Comments__c,Org_ID__c,APT_DWS_ID__c,Network_Address__c,APT_Transport_Capability__c,APT_MCAT__c,APT_Threshold_Categories__c from Network__c where Status__c != \'Closed\' AND ' + 
                            'APT_Business_Unit__c!=null AND recordtypeID in (Select id from RecordType where DeveloperName in (\'Delivery_1\',\'Retail_2\',\'Business_Hub_3\') and SobjectType = \'Network__c\')' ;
            
            
            // Adrian Recio, Replaced Business Unit with APT Business Unit , 22/5/2017
            string countStr ='select count() from Network__c where Status__c != \'Closed\' AND APT_Business_Unit__c!=null AND recordtypeID in (Select id from RecordType where DeveloperName in (\'Delivery_1\',\'Retail_2\',\'Business_Hub_3\') and SobjectType = \'Network__c\')' ;
            if(source=='lineItembtn'){  
            //string postCodeStart = String.valueof(lineItem.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Post_Code_Start__c);
            //string postCodeEnd = String.valueof(lineItem.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Post_Code_End__c);
            
                //STP-4984 Krishna Velani updated query string formation for new logic
             	Integer count2=0;

        for(string startPC: mapLodgement.keySet())
        {
            string endPC=mapLodgement.get(startPC);
            count2 += 1;

            if(string.isNotBlank(startPC) && string.isNotBlank(endPC))
            {
                if(mapLodgement.size() > 1 && count2 == 1)
                {
                    queryStr = queryStr +' AND ((Post_Code__c >=:startPC AND Post_Code__c <=:endPC)';
                    countStr = countStr +' AND ((Post_Code__c >=:startPC AND Post_Code__c <=:endPC)';
                }

                else if(count2 > 1 && count2 < mapLodgement.size())
                {
                    queryStr = queryStr +' OR (Post_Code__c >=:startPC AND Post_Code__c <=:endPC)';
                    countStr = countStr +' OR (Post_Code__c >=:startPC AND Post_Code__c <=:endPC)';
                }

                else if(count2 == mapLodgement.size() && count2 != 1)
                {
                    queryStr = queryStr +' OR (Post_Code__c >=:startPC AND Post_Code__c <=:endPC))';
                    countStr = countStr +' OR (Post_Code__c >=:startPC AND Post_Code__c <=:endPC))';
                }

                else
                {
                    queryStr = queryStr +' AND (Post_Code__c >=:startPC AND Post_Code__c <=:endPC)';
                    countStr = countStr +' AND (Post_Code__c >=:startPC AND Post_Code__c <=:endPC)';
                }
                System.debug('count2:'+ count2);
                System.debug('Query String:'+ queryStr);
                System.debug('MapSize:'+ mapLodgement.size());

            }

        }//STP-4984 logic completes here
            }
            if(Network.Post_Code__c != '' && Network.Post_Code__c != Null){
                selectedPostCode = Network.Post_Code__c;  
                system.debug('selectedPostCode:' + selectedPostCode);
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
                
                queryStr = queryStr + APT_Constants.POST_CODE_STRING2;  
                countStr = countStr +APT_Constants.POST_CODE_STRING2; 
            }        
             if(stateVal!='None'){    
                //system.debug('State:' + stateVal);
                 //for(string startPC:mapLodgement.keySet()){
              		// string endPC=mapLodgement.get(startPC);
              		// system.debug('startpostcode'+startPC);
                    // system.debug('endpostcode'+endPC);}
                queryStr = queryStr + ' AND State__c =: stateVal'; 
                countStr = countStr + ' AND State__c =: stateVal';      
            }
            if(source=='cartbtn' && domesticLodgementZone!='None'){                
                List<APT_Lodgement_Zone__c> lstLZ = [select id,name,APT_Post_Code_Start__c,APT_Post_Code_End__c from APT_Lodgement_Zone__c where Name=:domesticLodgementZone ORDER BY APT_Post_Code_Start__c];                  
                  if(lstLZ.size()>0){
                      postCodeStartLZ = String.valueof(lstLZ[0].APT_Post_Code_Start__c);
                      postCodeEndLZ = String.valueof(lstLZ[lstLZ.size()-1].APT_Post_Code_End__c);                 
                  } 
                
                queryStr = queryStr + ' AND Post_Code__c >=:postCodeStartLZ AND Post_Code__c <=:postCodeEndLZ';   
                countStr = countStr + ' AND Post_Code__c >=:postCodeStartLZ AND Post_Code__c <=:postCodeEndLZ'; 
            }  

            // Adrian Recio, Replaced Business Unit with APT Business Unit , 22/5/2017
            if(bussinessUnit !='None'){
                bussinessUnit += '%';         
                queryStr = queryStr + ' AND APT_Business_Unit__c LIKE: bussinessUnit'; 
                countStr = countStr + ' AND APT_Business_Unit__c LIKE: bussinessUnit';
                
            }
            if(Network.APT_Transport_Capability__c !='' && Network.APT_Transport_Capability__c !=Null){
                TransportCapability= Network.APT_Transport_Capability__c;
                if(TransportCapability == APT_Constants.TRANSPORT_CAPABILITY_EITHER_VAN_OR_TRUCK)
                {
                    queryStr = queryStr + ' AND APT_Transport_Capability__c != null';
                    countStr = countStr + ' AND APT_Transport_Capability__c  != null'; 
                }
                else
                {
                    string tempInput = '%' + TransportCapability + '%';
                    queryStr = queryStr + ' AND APT_Transport_Capability__c like: tempInput';
                    countStr = countStr + ' AND APT_Transport_Capability__c like: tempInput'; 
                }
            }
            if(Network.APT_eParcel_Enabled__c !='' && Network.APT_eParcel_Enabled__c !=Null){
                eParcelEnabled= Network.APT_eParcel_Enabled__c;
                queryStr = queryStr + ' AND APT_eParcel_Enabled__c =: eParcelEnabled'; 
                countStr = countStr + ' AND APT_eParcel_Enabled__c =: eParcelEnabled';      
            }

            //STP-4291 STPAC - DLWT: Business Rule 2 - Lodgement point restrictions
            //Filter Lodgment Points based on Custom Metadata
            if(inclExclLPModel != null && inclExclLPModel.size() > 0)
            {
                List<string> incExcLPs = new List<string>();

                if(inclExclLPModel.get(APT_Constants.INCLUDE) != null)
                {
                    incExcLPs = inclExclLPModel.get(APT_Constants.INCLUDE);
                    queryStr = queryStr + ' AND Org_ID__c IN :incExcLPs'; 
                    countStr = countStr + ' AND Org_ID__c IN :incExcLPs';
                }
                else if(inclExclLPModel.get(APT_Constants.EXCLUDE) != null)
                {
                    incExcLPs = inclExclLPModel.get(APT_Constants.EXCLUDE);
                    queryStr = queryStr + ' AND Org_ID__c NOT IN :incExcLPs'; 
                    countStr = countStr + ' AND Org_ID__c NOT IN :incExcLPs';
                }
            }

            queryStr = queryStr +' ORDER BY Post_Code__c Limit: recordsperpage  OFFSET: offSetVal';           
    
             system.debug('LP Selected Post Code:' + selectedPostCode );
             system.debug('LP Networkhub Ids:' + networkHubIds );
             system.debug('LP Postcode Start:' + postCodeStart);
             system.debug('LP Postcode End:' + postCodeEnd );
             system.debug('LP Query:' + queryStr);
             searchRecCount = Database.countQuery(countStr);   
             
            for(Network__c lp: Database.query(queryStr)){            
                lodgementPointWrapper lpWrapper = new lodgementPointWrapper();
                lpWrapper.IsSelected = false;
                lpWrapper.lodgementPoint = lp;
                listLodgementPointWrapper.add(lpWrapper);              
             }
          
            if(listLodgementPointWrapper.size()== 0){
                 haserrorMessages = true;
                 ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, 'No Lodgement Points found.'));
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
   
   /** Method to get the First records of Search results **/ 
    
    public void searchLPButton(){
         offSetVal =0;
         SearchLP();     
     }
   
  
   /** Method to get the Previous records of Search results **/  
    
    public void goPrevious(){
         offSetVal =offSetVal-recordsperpage;
         SearchLP();
    }
    
    /** Method to get the next records of Search results **/ 
    
    public pageReference goNext(){
         
         offSetVal =offSetVal+recordsperpage;  
                
         if(offSetVal >2000){
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, 'More than 2000 Lodgement Points found,Please use filter to Narrow down the results'));
            return null;         
         }
         
         SearchLP();
         return null;
    }
    
    /** Method to get the Last records of Search results **/ 
    
    public pageReference goLast(){         
         
         Integer count = 0;
         while ((searchRecCount - count) > recordsperpage) {              
            count = count+recordsperpage;
            offSetVal = count;            
         }
         
         if(offSetVal >2000){
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, 'More than 2000 Lodgement Points found,Please use filter to Narrow down the results'));
            return null;         
         }
                  
            SearchLP();
            
           return null; 
    }
   
     
     /**
        Method to insert selected Line Item lodgement Point 
     **/   
     public PageReference AddLP(){  
        try{  
            String LPNameVal;
            Boolean flag = false;
            Network__c lodgementPointselected;
            setSelectedLP=new Set<String>();
            Id lineItemId=Apexpages.currentpage().getparameters().get('lineItemId');
            Set<String> setLPid = new Set<String>(); 
            ListlodgementPointselected = new List<Network__c>();          
            selectedLP=null;     
            lZone =null;  
             
            for(lodgementPointWrapper lps : listLodgementPointWrapper){
                if(lps.IsSelected == true){
                    lodgementPointselected = lps.lodgementPoint;
                    lps.IsSelected = False;
                    if(selectedLP==null){
                        selectedLP= String.valueOf(lps.lodgementPoint.Id);
                    }
                    else{
                        selectedLP= selectedLP +','+ String.valueOf(lps.lodgementPoint.Id);
                    }
                    setSelectedLP.add(lodgementPointselected.Id);
                    ListlodgementPointselected.add(lodgementPointselected);
                    
                    if(lineItem.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__c!=null){               
                    if(lZone==null){
                        lZone= String.valueOf(lps.lodgementPoint.Id) + '~' + lineItem.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__c;
                    }else{
                        lZone= lZone +','+ String.valueOf(lps.lodgementPoint.Id) + '~' + lineItem.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__c;
                    }
                  }
                }        
            }
            if(ListlodgementPointselected.size()==0){
                haserrorMessages = true;
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Please select Lodgement Point first'));
                return null;
            }
            else if(source =='lineItembtn'){
                flag=false;
                lineItemId=Apexpages.currentpage().getparameters().get('lineItemId');
                lineItem =[Select id, Apttus_Config2__ProductId__r.Name, Apttus_Config2__ProductId__r.ProductCode,APT_Lodgement_Zone_Selected__c, Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__c,
                    Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.Name,APT_Selected_LP__c, Apttus_Config2__IsPrimaryLine__c,
                    Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Post_Code_Start__c ,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c, 
                    Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.APT_Post_Code_End__c,APT_Billing_Account__r.Name 
                    from Apttus_Config2__LineItem__c 
                    where ID =: lineItemId];               
                
                Set<String> setLPidVal = new Set<String>();
                if(lineItem.APT_Selected_LP__c!=null && lineItem.Apttus_Config2__IsPrimaryLine__c){
                    String[] selectedLpListVal=  lineItem.APT_Selected_LP__c.split(',') ;
                    Integer sizeOfLPSelected =selectedLpListVal.size();
                    String [] lastLPVal = selectedLpListVal[sizeOfLPSelected-1].split('~');
                    selectedLpListVal[sizeOfLPSelected-1]=lastLPVal[0];
                    for(Integer i=0;i<sizeOfLPSelected;i++){
                        setLPidVal.add(selectedLpListVal[i]);
                    }
                    for(String LP : setSelectedLP){
                        if(setLPidVal.contains(LP))
                            flag=true;
                    }
                  }
                if(flag==true){
                    haserrorMessages = true;
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Lodgement point already added'));
                    return null;           
                }
                else {
                    if(billingAcc== '') {
                        if(lineItem.APT_Selected_LP__c!=null ){
                            lineItem.APT_Selected_LP__c=lineItem.APT_Selected_LP__c+ ','+selectedLP;
                        }
                        else{
                           lineItem.APT_Selected_LP__c=selectedLP;
                        }
                    }else{
                        if(lineItem.APT_Selected_LP__c!=null){
                            String [] LPName = lineItem.APT_Selected_LP__c.split('~');
                            lineItem.APT_Selected_LP__c=LPName[0]+','+selectedLP+'~'+String.valueOf(billingAccId);
                            lineItem.APT_Billing_Account__c =billingAccId;
                        }
                        else if(billingAcc !=''){
                            lineItem.APT_Selected_LP__c=selectedLP+'~'+String.valueOf(billingAccId);
                            lineItem.APT_Billing_Account__c =billingAccId;
                        }
                    }
                    
                    if(lZone!=null){
                        if(!string.ISBLANK(lineItem.APT_Lodgement_Zone_Selected__c)){
                          System.debug(' lineItem.APT_Lodgement_Zone_Selected__c   ' + lineItem.APT_Lodgement_Zone_Selected__c);
                          lineItem.APT_Lodgement_Zone_Selected__c = lineItem.APT_Lodgement_Zone_Selected__c + ',' + lZone;
                          System.debug(' After lineItem.APT_Lodgement_Zone_Selected__c   ' + lineItem.APT_Lodgement_Zone_Selected__c);
                          System.debug(' lineItem.APT_Lodgement_Zone_Selected__c  '+  lineItem.APT_Lodgement_Zone_Selected__c  + ','+ lZone);
                        }else{
                          System.debug(' Else lineItem.APT_Lodgement_Zone_Selected__c   ' + lineItem.APT_Lodgement_Zone_Selected__c); 
                          System.debug(' Else lZone   ' + lZone); 
                          lineItem.APT_Lodgement_Zone_Selected__c = lZone;
                        }
                    }
                    
                    if(lineItem.APT_Selected_LP__c !=NULL){lineItem.APT_Added_LP__c=True;}
                    
                    update lineItem; 
                    String[] selectedLpList =  lineItem.APT_Selected_LP__c.split(',') ;
                    Integer size =selectedLpList.size();
                    String [] lastLP = selectedLpList[size-1].split('~');
                    selectedLpList [size-1]=lastLP[0];
                    for(Integer i=0;i<size;i++){
                        setLPid.add(selectedLpList[i]);
                        mapLI.put(selectedLpList[i],lineItem);
                    }
                    if(null != lineItem.APT_Lodgement_Zone_Selected__c && String.isNotBlank(lineItem.APT_Lodgement_Zone_Selected__c)){
                        parseSelectedZone(lineItem.APT_Lodgement_Zone_Selected__c.split(','));
                    }
                    
                    
                    listSelectedLodgementPointWrapper = new List<selectedlodgementPointWrapper>();
                    listLodgementPointSelectedRec  = database.query('Select ' + APT_AmendRenewUtility.getAllAgrFields('Network__c') + ' from   Network__c  where Id =:setLPid ');
                    
                    for(Network__c lodgementPointselected1 : listLodgementPointSelectedRec){
                        selectedlodgementPointWrapper LP = new selectedlodgementPointWrapper();
                        LP.Product =lineItem.Apttus_Config2__ProductId__r.Name;
                        //LP.lodgementZone=lineItem.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.Name;
                        if(mapLZ !=null && mapLZ.get(lodgementPointselected1.Id)!= null && mapLZRec.get(mapLZ.get(lodgementPointselected1.Id))!=null && (lineItem.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD || lineItem.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)){
                         LP.lodgementZone=mapLZRec.get(mapLZ.get(lodgementPointselected1.Id)).Name; 
                        }else{
                            LP.lodgementZone=lineItem.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.Name;
                        }
                        
                        Lp.ntwrk = lodgementPointselected1;
                        listSelectedLodgementPointWrapper.add(LP);
                    }
                }
               
                
            }
            else{
                LPNameVal=quote.APT_Selected_LP__c;
                flag=false;             
                
                Set<String> setLPidVal = new Set<String>();
                if(quote.APT_Selected_LP__c!=null){
                    String[] selectedLpListVal=  quote.APT_Selected_LP__c.split(',') ;
                    Integer sizeOfLPSelected =selectedLpListVal.size();
                    String [] lastLPVal = selectedLpListVal[sizeOfLPSelected-1].split('~');
                    selectedLpListVal [sizeOfLPSelected-1]=lastLPVal[0];
                    for(Integer i=0;i<sizeOfLPSelected;i++){
                        setLPidVal.add(selectedLpListVal[i]);
                    }
                    for(String LP : setSelectedLP){
                        if(setLPidVal.contains(LP))
                            flag=true;
                    }
                }
                
                if(flag==true){
                    haserrorMessages = true;
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Lodgement point already added'));
                    return null;           
                }
                else {
                System.Debug('____Kushal '+billingAcc);
                    if(billingAcc== '' || billingAcc == null){
                         if(quote.APT_Selected_LP__c!=null ){
                            quote.APT_Selected_LP__c=quote.APT_Selected_LP__c+ ','+selectedLP;
                        }
                        else{
                           quote.APT_Selected_LP__c=selectedLP;
                        }
                    }else{
                        if(quote.APT_Selected_LP__c!=null){
                            String [] LPName = quote.APT_Selected_LP__c.split('~');
                            quote.APT_Selected_LP__c=LPName[0]+','+selectedLP+'~'+String.valueOf(billingAccId);
                        }
                        else{
                            quote.APT_Selected_LP__c=selectedLP+'~'+String.valueOf(billingAccId);
                        }
                    }
                    if(quote.APT_Selected_LP__c != null || String.isNotBlank(quote.APT_Selected_LP__c))
                    {
                        quote.APT_Added_Generic_LP__c = true;
                    }
                    update quote; 

                    String[] selectedLpList =  quote.APT_Selected_LP__c.split(',') ;
                    Integer size =selectedLpList.size();
                    String [] lastLP = selectedLpList[size-1].split('~');
                    for(Integer i=0;i<size -1;i++){
                        quotesetLPid.add(selectedLpList[i]);
                    }
                    quotesetLPid.add(lastLP[0]);
                }
                listLodgementPointSelectedRec  = database.query('Select ' + APT_AmendRenewUtility.getAllAgrFields('Network__c') + ' from   Network__c  where Id in:quotesetLPid ');
                for(Network__c lodgementPointselected1 : listLodgementPointSelectedRec){
                    if(LPNameVal!=null){
                        if(!LPNameVal.contains(lodgementPointselected1 .Id)){
                            selectedlodgementPointWrapper LP = new selectedlodgementPointWrapper();
                            Lp.ntwrk = lodgementPointselected1;
                            listSelectedLodgementPointWrapper.add(LP);
                        }
                    }
                    else{
                        selectedlodgementPointWrapper LP = new selectedlodgementPointWrapper();
                        Lp.ntwrk = lodgementPointselected1;
                        listSelectedLodgementPointWrapper.add(LP);
                    }
                }
            }
            

        }
     catch(Exception ex){
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()+' line num '+ex.getlinenumber()));
            return null;
     } 
        return null;
      } 
    
    /**
        Method to delete selected Line Item lodgement Point 
     **/ 
     public PageReference DeleteLP(){
        try{
            String LPName=null;
            string deleteLodgementPointId= Apexpages.currentPage().getParameters().get('deleteLodgementPointId');          
            if(mapLI.get(deleteLodgementPointId)!=null)
            {   
                listSelectedLodgementPointWrapper = new List<selectedlodgementPointWrapper>();
                setLPid=new Set<String>();
                String [] LPSelected = (mapLI.get(deleteLodgementPointId).APT_Selected_LP__c).split(',');
                Integer size =LPSelected.size();
                String [] LPSelected1 = LPSelected[size-1].split('~');
                LPSelected[size-1]=LPSelected1 [0];
                for(Integer i =0;i<size;i++){
                    if(LPSelected[i]==deleteLodgementPointId){
                    }else{
                        if(LPName==null){
                            LPName=LPSelected[i];
                            setLPid.add(LPSelected[i]);
                        }
                        else{
                            LPName=LPName+','+LPSelected[i];
                            setLPid.add(LPSelected[i]);
                        }
                    }
                }
                if(LPName==null){
                    mapLI.get(deleteLodgementPointId).APT_Selected_LP__c=null;
                }else{
                    if(LPSelected1.size()>1 )
                        LPName=LPName+'~'+LPSelected1[1];
                    mapLI.get(deleteLodgementPointId).APT_Selected_LP__c=LPName;
                }
                
               
                if(mapLI.get(deleteLodgementPointId).APT_Selected_LP__c==NULL){
                  mapLI.get(deleteLodgementPointId).APT_Billing_Account__c =NULL;
                  mapLI.get(deleteLodgementPointId).APT_Added_LP__c=False;                  
                }
                
                String lzDelete='';
                if(mapLI.get(deleteLodgementPointId).APT_Lodgement_Zone_Selected__c!=null){                                                             
                    for(string s:mapLI.get(deleteLodgementPointId).APT_Lodgement_Zone_Selected__c.split(',')){ 
                      
                     if(!s.contains(deleteLodgementPointId)){
                       if(lzDelete !=''){
                       lzDelete =lzDelete + ',' + s;
                       }else{
                        lzDelete=s;
                       }
                     }
                    
                  }
                  mapLI.get(deleteLodgementPointId).APT_Lodgement_Zone_Selected__c =lzDelete;
                }
                
                if(mapLI.get(deleteLodgementPointId)!=null)
                    update mapLI.get(deleteLodgementPointId);
                quotesetLPidDel=new Set<String>();
                if(source=='lineItembtn'){
                     if(mapLI.get(deleteLodgementPointId).APT_Lodgement_Zone_Selected__c!=null){
                       parseSelectedZone(mapLI.get(deleteLodgementPointId).APT_Lodgement_Zone_Selected__c.split(','));
                     }
                     
                    listLodgementPointSelectedRec  = database.query('Select ' + APT_AmendRenewUtility.getAllAgrFields('Network__c') + ' from   Network__c  where Id =:setLPid ');
                    
                    if(listLodgementPointSelectedRec.size()>0){
                        for(Network__c lodgementPointselected1 : listLodgementPointSelectedRec){
                            selectedlodgementPointWrapper LP = new selectedlodgementPointWrapper();
                            LP.Product = mapLI.get(deleteLodgementPointId).Apttus_Config2__ProductId__r.Name;
                          //LP.lodgementZone=mapLI.get(deleteLodgementPointId).Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.Name;         
                           
                           if(mapLZ !=null && mapLZ.get(lodgementPointselected1.Id)!= null && mapLZRec.get(mapLZ.get(lodgementPointselected1.Id))!=null && (lineItem.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD || lineItem.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)){
                             LP.lodgementZone=mapLZRec.get(mapLZ.get(lodgementPointselected1.Id)).Name; 
                            }else{
                             LP.lodgementZone= mapLI.get(deleteLodgementPointId).Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.Name;
                            }                           
                            Lp.ntwrk = lodgementPointselected1;
                            listSelectedLodgementPointWrapper.add(LP);
                        }
                    }else{
                        listSelectedLodgementPointWrapper = new List<selectedlodgementPointWrapper>();
                    }
                    
                }
                else{
                    quotesetLPidDel = new Set<String>();
                    if(quote.APT_Selected_LP__c!=null){                        
                        String [] quoteLPSelected = (quote.APT_Selected_LP__c).split(',');                        
                        Integer size1 =quoteLPSelected.size();
                        String [] quoteLPSelected1 = quoteLPSelected[size1-1].split('~');                        
                        quoteLPSelected[size1-1]=quoteLPSelected1[0];                        
                        quotesetLPidDel.addall(quoteLPSelected);
                       
                        listLodgementPointSelectedRec  = database.query('Select ' + APT_AmendRenewUtility.getAllAgrFields('Network__c') + ' from   Network__c  where Id in:quotesetLPidDel');
                        
                        if(listLodgementPointSelectedRec.size()>0){
                            for(Network__c lodgementPointselected1 : listLodgementPointSelectedRec){
                                selectedlodgementPointWrapper LP = new selectedlodgementPointWrapper();                                
                                Lp.ntwrk = lodgementPointselected1;
                                listSelectedLodgementPointWrapper.add(LP);
                            }
                        }
                    }
                    setLILP=new Set<Id>();
                    listLZ = new List<string>();
                    mapLI =new Map<Id,Apttus_Config2__LineItem__c>();
                    List<Apttus_Config2__LineItem__c> listOfLI1 = [SELECT id,name,APT_Lodgement_Zone_Selected__c,Apttus_Config2__ProductId__r.Name, Apttus_Config2__ProductId__r.ProductCode, Apttus_Config2__IsPrimaryLine__c,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c,Apttus_Config2__LineType__c,APT_Billing_Account__c,APT_Selected_LP__c,APT_Lodgement_Zone__c ,Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__c,Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.Name from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c = :prodConfigId];
                    if(listOfLI.size()>0){                  
                        for(Apttus_Config2__LineItem__c  LI :listOfLI1){
                            if(LI.APT_Selected_LP__c !=null && LI.Apttus_Config2__IsPrimaryLine__c){                            
                                String[] selectedLpList =  LI.APT_Selected_LP__c.split(',') ;
                                Integer size1 =selectedLpList.size();
                                String []lastLP = selectedLpList[size1-1].split('~');
                                selectedLpList[size1-1]=lastLP[0];                                
                                for(Integer i=0;i<size1;i++){                                    
                                    if(selectedLpList[i]!=null && selectedLpList[i]!=''){
                                        mapLI.put(selectedLpList[i],LI);
                                        setLILP.add(selectedLpList[i]);
                                    }
                                }
                            }
                            if(LI.APT_Lodgement_Zone_Selected__c!=null){                            
                              listLZ.addall(LI.APT_Lodgement_Zone_Selected__c.split(','));
                            }
                        }
                    }
                      
                    if(setLILP.size()>0){                   
                    parseSelectedZone(listLZ);
                        listLodgementPoints = database.query('Select ' + APT_AmendRenewUtility.getAllAgrFields('Network__c') + ' from   Network__c  where id in :setLILP');                          
                        for(Network__c lodgementPoint :listLodgementPoints ){
                            selectedlodgementPointWrapper LPline = new selectedlodgementPointWrapper();
                            LPline.Product =mapLI.get(lodgementPoint.id).Apttus_Config2__ProductId__r.Name;
                            //LPline.lodgementZone=mapLI.get(lodgementPoint.id).APT_Lodgement_Zone__c;
                            if(mapLZ !=null && mapLZ.get(lodgementPoint.Id)!= null && mapLZRec.get(mapLZ.get(lodgementPoint.Id))!=null){
                             LPline.lodgementZone=mapLZRec.get(mapLZ.get(lodgementPoint.Id)).Name; 
                            }else{
                             LPline.lodgementZone=mapLI.get(lodgementPoint.id).APT_Lodgement_Zone__c;
                            }
                            LPline.ntwrk = lodgementPoint ;
                            listSelectedLodgementPointWrapper.add(LPline);
                        }
                    }

                }
            }
            else if(quote.APT_Selected_LP__c!=null){            
                listSelectedLodgementPointWrapper = new List<selectedlodgementPointWrapper>();
                quotesetLPidDel=new Set<String>();
                if(quote.APT_Selected_LP__c.contains(deleteLodgementPointId)){
                    String [] LPSelected = (quote.APT_Selected_LP__c).split(',');
                    Integer size =LPSelected.size();
                    String [] LPSelected1 = LPSelected [size-1].split('~');
                    LPSelected [size-1]=LPSelected1 [0];
                    for(Integer i =0;i<size;i++){
                        if(LPSelected[i]==deleteLodgementPointId){
                        }else{
                            if(LPName==null){
                            LPName=LPSelected[i];
                            quotesetLPidDel.add(LPSelected[i]);
                            }
                            else{
                                LPName=LPName+','+LPSelected[i];
                                quotesetLPidDel.add(LPSelected[i]);
                            }
                        }
                    }
                    if(LPName==null){
                        quote.APT_Selected_LP__c=null;
                    }else{
                        if(LPSelected1.size()>1)
                            LPName=LPName+'~'+LPSelected1[1];
                        quote.APT_Selected_LP__c=LPName;
                    }              
                    if(quote.APT_Selected_LP__c == null || String.isBlank(quote.APT_Selected_LP__c))
                    {
                        quote.APT_Added_Generic_LP__c = false;
                    }    
                    if(quote!=null)
                        update quote;
                    listLodgementPointSelectedRec  = database.query('Select ' + APT_AmendRenewUtility.getAllAgrFields('Network__c') + ' from   Network__c  where Id in :quotesetLPidDel ');
                    if(listLodgementPointSelectedRec.size()>0){
                        for(Network__c lodgementPointselected1 : listLodgementPointSelectedRec){
                            selectedlodgementPointWrapper LP = new selectedlodgementPointWrapper();                            
                            Lp.ntwrk = lodgementPointselected1;
                            listSelectedLodgementPointWrapper.add(LP);
                            
                        }
                    }else{
                        listSelectedLodgementPointWrapper = new List<selectedlodgementPointWrapper>();
                    }
                    listLZ = new List<string>();                   
                    mapLI = new Map<id,Apttus_Config2__LineItem__c>();
                    setLILP = new set<ID>();
                    if(listOfLI.size()>0){
                        for(Apttus_Config2__LineItem__c  LI :listOfLI ){
                            if(LI.APT_Selected_LP__c !=null && LI.Apttus_Config2__IsPrimaryLine__c){                            
                                String[] selectedLpList =  LI.APT_Selected_LP__c.split(',') ;
                                Integer size1 =selectedLpList.size();
                                String [] lastLP = selectedLpList[size1-1].split('~');
                                selectedLpList[size1-1]=lastLP [0];                                
                                for(Integer i=0;i<size1;i++){                                    
                                    if(selectedLpList[i]!=null && selectedLpList[i]!=''){
                                        mapLI.put(selectedLpList[i],LI);
                                        setLILP.add(selectedLpList[i]);
                                    }
                                }
                            if(LI.APT_Lodgement_Zone_Selected__c!=null){                            
                              listLZ.addall(LI.APT_Lodgement_Zone_Selected__c.split(','));
                            }
                            }
                        }
                    }
                    if(setLILP.size()>0){
                    parseSelectedZone(listLZ);
                        listLodgementPoints = database.query('Select ' + APT_AmendRenewUtility.getAllAgrFields('Network__c') + ' from   Network__c  where id in :setLILP');
                        
                        for(Network__c lodgementPoint :listLodgementPoints ){
                            selectedlodgementPointWrapper LPline = new selectedlodgementPointWrapper();
                            LPline.Product =mapLI.get(lodgementPoint.id).Apttus_Config2__ProductId__r.Name;
                            //LPline.lodgementZone=mapLI.get(lodgementPoint.id).APT_Lodgement_Zone__c;
                            if(mapLZ !=null && mapLZ.get(lodgementPoint.Id)!= null && mapLZRec.get(mapLZ.get(lodgementPoint.Id))!=null){
                             LPline.lodgementZone=mapLZRec.get(mapLZ.get(lodgementPoint.Id)).Name; 
                            }else{
                             LPline.lodgementZone=mapLI.get(lodgementPoint.id).APT_Lodgement_Zone__c;
                            }
                            LPline.ntwrk = lodgementPoint ;
                            listSelectedLodgementPointWrapper.add(LPline);
                        }
                    }

                }
            }

        
        } catch(Exception ex) {
            haserrorMessages = true;
            System.debug('ex.getMessage()'+ex.getMessage());
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        } 
        return null;
    }
    
     /**
       To show all Lodgement points with in a Lodgement zone range.
     **/
     
     public PageReference showallLodgementpoints(){
      try{ 

      if(source =='lineItembtn'){
      
       listLodgementPointWrapper =new List<lodgementPointWrapper>();
      
      // Adrian Recio, Replaced Business Unit with APT Business Unit , 22/5/2017
       for(Network__c nw :[select id,Name,Post_Code__c,State__c,APT_Business_Unit__c,APT_eParcel_Enabled__c,Org_ID__c,APT_DWS_ID__c,APT_Comments__c,Network_Address__c,APT_Transport_Capability__c,APT_MCAT__c,APT_Threshold_Categories__c from Network__c where Post_Code__c >=:postCodeStart AND Post_Code__c <=:postCodeEnd 
                          AND Status__c != 'Closed' /*AND APT_Apttus_LP__c=True*/ AND Business_Unit__c!=null AND recordtypeID in (Select id from RecordType where DeveloperName in ('Delivery_1','Retail_2','Business_Hub_3') and SobjectType = 'Network__c') ORDER BY Post_Code__c limit: recordsperpage OFFSET: offSetVal]){
          
         lodgementPointWrapper lpWrapper = new lodgementPointWrapper();
         lpWrapper.IsSelected = false;
         lpWrapper.lodgementPoint = nw;
         listLodgementPointWrapper.add(lpWrapper);              
       } 
         
         // Adrian Recio, Replaced Business Unit with APT Business Unit , 22/5/2017
          searchRecCount = [select count() from Network__c where Post_Code__c >=:postCodeStart AND Post_Code__c <=:postCodeEnd 
                            AND Status__c != 'Closed' /*AND APT_Apttus_LP__c=True*/ AND APT_Business_Unit__c!=null AND recordtypeID in (Select id from RecordType where DeveloperName in
                            ('Delivery_1','Retail_2','Business_Hub_3') and SobjectType = 'Network__c')];
                
       
       if(listLodgementPointWrapper.size() == 0){
             haserrorMessages = true;
             ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, 'There are No Lodgement Points found for this logdement Zone'));
             return null;
        } 
        stateVal ='None';
        Network.Post_Code__c =null;
        bussinessUnit ='None';       
        
      }
        } catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
        return null;
     }  
   /**
       Method to handle Back to cart button
     **/
    public PageReference backToCart() { 
        
        PageReference cartPage;
        try{  
            Apttus_Config2__TempObject__c temp = [Select id from Apttus_Config2__TempObject__c where Apttus_Config2__ConfigurationId__c =:prodConfigId limit 1];
            
            APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
            if(r2tSystemProperties != null) {
                if(r2tSystemProperties.APT_Enable_Classic_UI__c == true) {
                    cartPage = Page.Apttus_Config2__CartDetailView;
                    cartPage.getParameters().put('flow',mapUrlParam.get('flow'));
                    cartPage.getParameters().put('launchState', mapUrlParam.get('launchState'));
                    cartPage.setRedirect(true);  
                } else if(r2tSystemProperties.APT_Enable_Classic_UI__c == false){
                    cartPage = Page.Apttus_Config2__Cart;
                    //cartPage.getParameters().put('flow', mapUrlParam.get('flow')+'#/cart');
                    cartPage.getParameters().put('flow', mapUrlParam.get('flow'));
                    //cartPage.getParameters().put('flow', 'NewQuote');
                }
            } else {
                cartPage = Page.Apttus_Config2__CartDetailView;
                cartPage.getParameters().put('flow',mapUrlParam.get('flow'));
                cartPage.getParameters().put('launchState',mapUrlParam.get('launchState'));
                cartPage.setRedirect(true);  
            }
            
            System.Debug('cartPage-->' + cartPage);
            System.Debug('launchState-->' + mapUrlParam.get('launchState'));
            System.Debug('flow-->' + mapUrlParam.get('flow'));
            
            cartPage.getParameters().put('Id',prodConfigId);
            cartPage.getParameters().put('configRequestId',temp.Id);
                
        } catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
        
        return cartPage;     
        //return new PageReference(parentPageURL);
    }

    /**
       Method to show the pick list values for Bussiness unit field
     **/
    public List<SelectOption> getBussinessPickval() {

        List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('None','---None---'));
            options.add(new SelectOption('Hub','Hub'));
            options.add(new SelectOption('Retail','Retail'));
//            options.add(new SelectOption('Retail - LPO','Retail - LPO'));
//            options.add(new SelectOption('Retail - Corp','Retail - Corp'));
            options.add(new SelectOption('Parcel Services','Parcel Services'));                       
            options.add(new SelectOption('Postal Delivery','Postal Delivery'));
            return options;      
    }
    
    /**
       Method to fecth the pick list values for Domestic Lodgement Zone
     **/
    public List<SelectOption> getdomesticLodgementZoneVal() {
       List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('None','---None---'));
        for(AggregateResult ar:[select Name from APT_Lodgement_Zone__c Group By Name]){        
            options.add(new SelectOption(string.valueOf(ar.get('Name')),string.valueOf(ar.get('Name'))));
            }
            return options;      
     }
    
    /**
       Method to show the pick list values for Bussiness unit field
     **/
    public List<SelectOption> getstatePickval() {
        try{
          Schema.DescribeFieldResult fieldResult = Network__c.State__c.getDescribe();
          List<Schema.PicklistEntry> pickVals = fieldResult.getPicklistValues();
          List<SelectOption> options = new List<SelectOption>();
          options.add(new SelectOption('None','---None---'));
       
           
         if(source =='lineItembtn'){
         if(!string.ISEMPTY(selectedStates)){
         set<String> setselectedVals=new set<String>();
         setselectedVals.addall(selectedStates.split(';'));              
           for(Schema.PicklistEntry s : pickVals){
              if(setselectedVals.contains(String.valueof(s.getValue()))){        
              options.add(new SelectOption(s.getLabel(),s.getValue()));            
            }
           }
         } else{         
          for(Schema.PicklistEntry s : pickVals){
           options.add(new SelectOption(s.getLabel(),s.getValue()));         
         }
       }
       }else{
              for(Schema.PicklistEntry s : pickVals){
               options.add(new SelectOption(s.getLabel(),s.getValue()));
           }
       } 
       return options; 
          } catch(Exception ex) {
                haserrorMessages = true;
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                return null;
          }
    }
    
    // Method to parse the Selected Lodgement Zone field on line item    
     public void parseSelectedZone(list<string> lstZone) {
         mapLZ =new Map<string,string>();
         for(string z:lstZone){
          if(z!=null){
            String[] selectedLZList =  z.split(',');                                          
            for(string s:selectedLZList){ 
            String [] lstLZ = s.split('~');
            if(lstLZ.size()==2){
            mapLZ.put(lstLZ[0],lstLZ[1]);
           }
           }
          }
         }
                    
      mapLZRec =new Map<Id,APT_Lodgement_Zone__c>([select id,Name from APT_Lodgement_Zone__c where ID IN:mapLZ.values()]);
    }
    
    // Method to get the parameters from url
    
     public void getCartParameters(URL u) {
         System.Debug('u---->'+ u);
         String parentPageURL = u.getQuery(); 
         System.Debug('parentPageURL---->'+ parentPageURL);
         
         if(String.IsNotBlank(parentPageURL )){
             for(string s:parentPageURL.split('&')){
                 System.Debug('s---->'+ s);
         
                List<string> lstParam = s.split('=');
                if(lstParam.size()==2){
                  mapUrlParam.put(lstParam[0],lstParam[1]);
                }     
            }
         }
     }
       
    public class selectedlodgementPointWrapper {
        public String Product {get; set;}
        public String lodgementZone{get; set;}
        public Network__c ntwrk{get; set;}
    }
  
    /**
       Wrapper class to show radio button and Lodgement point records in table
     **/  
    public class lodgementPointWrapper {
        public boolean IsSelected {get; set;}
        public Network__c lodgementPoint {get; set;}    
   
    }
    
}