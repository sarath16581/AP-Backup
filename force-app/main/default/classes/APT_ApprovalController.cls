/**
 * This class is being called using Validate Approvals button from Cart Page. The class will check if approval is required or not? If yes then mark as approval required
 * and if not then removed approval required status from configuration and line item both.
 * Created By - Mausam Padhiyar
 * Created Date - 6th Oct, 2016
 
 * Last Modified By - Mausam Padhiyar
 * Last Modified Date - 3rd Nov, 2016 | Validate Approvals
 */
public with sharing class APT_ApprovalController {
    
    public String quoteId;
    public String configId;
    public String configRequestId;
    public String flow;
    
    map<string,string> mapUrlParam = new map<string,string>();
    public boolean haserrorMessages{get;set;}
    
    public APT_ApprovalController() {
        init();
    }
    
    public void init() {
        haserrorMessages = false;
        /*
        quoteId = Apexpages.currentpage().getparameters().get(APT_Constants.URL_BUSINESS_OBJECT_ID);
        source = Apexpages.currentpage().getparameters().get(APT_Constants.URL_SOURCE);
        if(source != APT_Constants.URL_QUOTE){
          source = APT_Constants.URL_CART;
        }
        
        if(source==APT_Constants.URL_QUOTE){
            saveAndGoBack =APT_Constants.LABEL_BACK_TO_QUOTE;
            list<Apttus_Config2__ProductConfiguration__c> lstconfig =[select id,Apttus_Config2__VersionNumber__c,Apttus_QPConfig__Proposald__r.RecordType.name from Apttus_Config2__ProductConfiguration__c where Apttus_QPConfig__Proposald__c =:quoteId and Apttus_Config2__Status__c != :APT_Constants.LABEL_SUPERSEDED ORDER by Apttus_Config2__VersionNumber__c DESC];
            if(lstconfig.size()>0){
                prodConfigId=lstconfig[0].ID;
            }  
        } else{
            saveAndGoBack =APT_Constants.LABEL_BACK_TO_SHOPPING_CART;
            prodConfigId=Apexpages.currentpage().getparameters().get(APT_Constants.URL_ID);
            list<Apttus_Proposal__Proposal__c> lstProposal =[select id,RecordType.name from Apttus_Proposal__Proposal__c where id=:quoteId ];
            if(lstProposal.size()>0){
                quoteRecordType=lstProposal[0].RecordType.name;                            
            }          
        }
        */
        
        quoteId = Apexpages.currentpage().getparameters().get(APT_Constants.URL_BUSINESS_OBJECT_ID);
        configId = Apexpages.currentpage().getparameters().get(APT_Constants.URL_ID);
        configRequestId = Apexpages.currentpage().getparameters().get(APT_Constants.URL_CONFIG_REQUEST_ID);
        flow = Apexpages.currentpage().getparameters().get(APT_Constants.LABEL_FLOW);
        
        
        
        URL u=new URL(ApexPages.currentPage().getHeaders().get(APT_Constants.URL_REFERER));
        getCartParameters(u);
    }
    
    private void getCartParameters(URL u) {
        String parentPageURL = u.getQuery(); 
        if(String.isNotBlank(parentPageURL)){
            for(string s:parentPageURL.split(APT_Constants.SEPERATOR_AND)){
                List<string> lstParam = s.split(APT_Constants.SEPERATOR_EQUAL);
                if(lstParam.size()==2){
                  mapUrlParam.put(lstParam[0],lstParam[1]);
                }     
            }
        }
    }
    
    public PageReference validateApprovals() {
        try {
            list<Id> listLineItemIds = new list<Id>();
            map<Id, Apttus_Config2__LineItem__c> mapLineItem = new map<Id, Apttus_Config2__LineItem__c>();
            for(Apttus_Config2__LineItem__c li : [SELECT Id, Apttus_CQApprov__Approval_Status__c
            										FROM Apttus_Config2__LineItem__c
            										WHERE Apttus_Config2__ConfigurationId__c = :configId]) {
            	listLineItemIds.add(li.Id);
            	mapLineItem.put(li.Id, li);
            }
            
            if(listLineItemIds.size() > 0) {
            	list<Boolean> listObjectIds = Apttus_Approval.ApprovalsWebService.checkIfApprovalRequired(listLineItemIds);
            	if(listObjectIds != null && listObjectIds.size() > 0) {
            		Integer iCount = 0;
            		Integer iApprovalRequiredCount = 0;
            		list<Apttus_Config2__LineItem__c> listUpdateLineItem = new list<Apttus_Config2__LineItem__c>();
            		for(id liId : listLineItemIds) {
            		    Apttus_Config2__LineItem__c li = mapLineItem.get(liId);
            			if(listObjectIds[iCount]) {
            				if(li != null) {
            					li.Apttus_CQApprov__Approval_Status__c = 'Approval Required';
            					listUpdateLineItem.add(li);
            					iApprovalRequiredCount++;
            				}				
            			} else {
            			    if(li != null && String.isNotBlank(li.Apttus_CQApprov__Approval_Status__c) && li.Apttus_CQApprov__Approval_Status__c.equalsIgnoreCase('Approval Required')) {
            					li.Apttus_CQApprov__Approval_Status__c = null;
            					listUpdateLineItem.add(li);
            				}
            			}
            			iCount++;
            		}
            		
            		Apttus_Config2__ProductConfiguration__c configSO = [SELECT Id, Apttus_CQApprov__Approval_Status__c, Apttus_Config2__Status__c, APT_Validate_Approvals__c
            															FROM Apttus_Config2__ProductConfiguration__c 
            															WHERE Id = :configId];
            		
            		if(iApprovalRequiredCount > 0 && configSO != null) {
            			configSO.Apttus_CQApprov__Approval_Status__c = 'Approval Required';
            			configSO.Apttus_Config2__Status__c = 'Approval Required';
            			//update configSO;
            		} else if(iApprovalRequiredCount == 0 && configSO != null 
            		    && ((String.isNotBlank(configSO.Apttus_CQApprov__Approval_Status__c) && configSO.Apttus_CQApprov__Approval_Status__c.equalsIgnoreCase('Approval Required'))
            		    || (String.isNotBlank(configSO.Apttus_Config2__Status__c) && configSO.Apttus_Config2__Status__c.equalsIgnoreCase('Approval Required')))) {
            		    
            		    configSO.Apttus_Config2__Status__c = 'Saved';
            		    configSO.Apttus_CQApprov__Approval_Status__c = null;
            		    //update configSO;
            		} else {}
            		
            		
            		configSO.APT_Validate_Approvals__c = true;
            		update configSO;
            		
            	
            		if(listUpdateLineItem.size() > 0) {
            		    update listUpdateLineItem;
            		}
            	}
            }
        
        
        //redirect to cart
        //PageReference cartPage;  
            /*
            if(source == APT_Constants.URL_QUOTE) {
                return new pageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH + quoteId);
            } else {
                APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
                if(r2tSystemProperties != null) {
                    if(r2tSystemProperties.APT_Enable_Classic_UI__c == true) {
                        cartPage = Page.Apttus_Config2__CartDetailView;
                        cartPage.getParameters().put(APT_Constants.LABEL_FLOW, mapUrlParam.get(APT_Constants.LABEL_FLOW));
                        cartPage.getParameters().put(APT_Constants.URL_LAUNCH_STATE,mapUrlParam.get(APT_Constants.URL_LAUNCH_STATE));
                    } else if(r2tSystemProperties.APT_Enable_Classic_UI__c == false){
                        cartPage = Page.Apttus_Config2__Cart;
                        cartPage.getParameters().put(APT_Constants.LABEL_FLOW, mapUrlParam.get(APT_Constants.LABEL_FLOW)+APT_Constants.STRING_FORWARD_CART);
                    } else {}
                } else {
                    cartPage = Page.Apttus_Config2__CartDetailView;
                    cartPage.getParameters().put(APT_Constants.LABEL_FLOW, mapUrlParam.get(APT_Constants.LABEL_FLOW));
                    cartPage.getParameters().put(APT_Constants.URL_LAUNCH_STATE,mapUrlParam.get(APT_Constants.URL_LAUNCH_STATE));
                }
                Apttus_Config2__TempObject__c temp = [Select id from Apttus_Config2__TempObject__c where Apttus_Config2__ConfigurationId__c =:prodConfigId limit 1];        
                
                cartPage.getParameters().put(APT_Constants.URL_ID, prodConfigId);
                cartPage.getParameters().put(APT_Constants.URL_CONFIG_REQUEST_ID, temp.Id);
                cartPage.setRedirect(true);       
            
            }
            */
            
            PageReference cartPage = Page.Apttus_Config2__Cart;
            cartPage.getParameters().put(APT_Constants.LABEL_FLOW, flow);
            cartPage.getParameters().put(APT_Constants.URL_ID, configId);
            cartPage.getParameters().put(APT_Constants.URL_CONFIG_REQUEST_ID, configRequestId);
            cartPage.getParameters().put(APT_Constants.URL_LAUNCH_STATE, mapUrlParam.get(APT_Constants.URL_LAUNCH_STATE));
            
            return cartPage;
        } catch(system.exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;  
        }
        
        return null;
    }
}