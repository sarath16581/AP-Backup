/**
    Description: This apex class is the controller for Visualforce page - APT_ManageLodgementPointLookup.
    Created By: Raviteja Epuri
    Created Date: 19th Nov, 2015
    Last Modified By: Vera Octavia
    Last Modified Date: 26/09/2019 - REQ1287372 - Added new fields to be listed on the billing account search
**/
public with sharing class APT_ManageLodgementPointLookupController {

    public List<Billing_Account__c> billingAccAvailable { get; set; }  
    public List<APT_Cash_Account__c> cashAccAvailable { get; set; } 
    public List<APT_Charge_Account__c > chargeAccAvailable { get; set; } 
    public List<APT_Sub_Account__c> subAccAvailable { get; set; }   
    public String inputAccName{ get; set; }
    public String source{ get; set; }
    public ID prodConfigId{ get; set; }
    public ID accId;
    public ID quoteId;
    Public Boolean haserrorMessages{get;set;}
    
    public static final string strTitle = 'Lookup';
    public static string strGetValTitle {get{return strTitle;} set;}
    
    public static final string strTitleBillingAcc = 'Enter Billing Account Name';
    public static string strGetValTitleBillingAcc {get{return strTitleBillingAcc;} set;}
    
    public static final string strSearch = 'Search';
    public static string strGetValSearch {get{return strSearch;} set;}
    
    public static final string strShowBillingAcc = 'Show all Billing Accounts for this Organisation';
    public static string strGetValShowBillingAcc {get{return strShowBillingAcc;} set;}
    
    public static final string strShowAll = 'Show All';
    public static string strGetValShowAll {get{return strShowAll;} set;}
    
    public static final string strWait = 'Please wait..';
    public static string strGetValWait {get{return strWait;} set;}
    
    public static final string strTitleAcc = 'Billing Accounts';
    public static string strGetValTitleAcc {get{return strTitleAcc;} set;}
    
    public static final string strTitleCashAcc = 'Cash Accounts';
    public static string strGetValTitleCashAcc {get{return strTitleCashAcc;} set;}
    
    public static final string strTitleChargeAcc = 'charge Accounts';
    public static string strGetValTitleChargeAcc {get{return strTitleChargeAcc;} set;}
    
    public static final string strTitleSubAcc = 'Sub Accounts';
    public static string strGetValTitleSubAcc {get{return strTitleSubAcc;} set;}
    
      /**
        Constructor to get the values form Url and to get the Billing account records based on input value. 
     **/   
    public APT_ManageLodgementPointLookupController(){  
        try {
            
            billingAccAvailable = new  List<Billing_Account__c>(); 
            cashAccAvailable = new  List<APT_Cash_Account__c>();
            chargeAccAvailable = new  List<APT_Charge_Account__c >();
            subAccAvailable = new  List<APT_Sub_Account__c>();
            inputAccName = Apexpages.currentpage().getparameters().get(APT_Constants.ENTEREDACCVAL);
            prodConfigId = Apexpages.currentpage().getparameters().get(APT_Constants.PRODCONID); 
                        
            if(!String.isEmpty(Apexpages.currentpage().getparameters().get(APT_Constants.QUOTEID))){    //APOST-1861
                quoteId= Apexpages.currentpage().getparameters().get(APT_Constants.QUOTEID);
            }                   
            
            if(!String.isEmpty(Apexpages.currentpage().getparameters().get(APT_Constants.PARAM_ACCOUNT_ID))){   //APOST-1861
                accId = Apexpages.currentpage().getparameters().get(APT_Constants.PARAM_ACCOUNT_ID);
            }
            
            source = Apexpages.currentpage().getparameters().get(APT_Constants.URL_SOURCE);
        
          
           getBillingAccounts();
        } catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));            
        }
    }
     
     /**
        Method to get the Billing account records based on input value. 
     **/
    public PageReference getBillingAccounts(){        
        billingAccAvailable = new List<Billing_Account__c>();
        system.debug('*** quoteId ***'+quoteId);
         try {
            if(source.equalsIgnorecase(APT_Constants.BILLINGACCCPQ)){
                Apttus_Config2__ProductConfiguration__c pC = [select id,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c from Apttus_Config2__ProductConfiguration__c where id =:prodConfigId];
                accId = pC.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c;
            } else {   
                if(!String.isEmpty(quoteId)){   //APOST-1861
                    accId  = [select id, Apttus_Proposal__Account__c from  Apttus_Proposal__Proposal__c where Id = :quoteId limit 1].Apttus_Proposal__Account__c;
                }  
            }
            if(inputAccName !=APT_Constants.EMPTY_STRING && !(String.isEmpty(accId))){   
                billingAccAvailable =[select id,name,Customer_Name__c,Suburb__c,State__c,Customer_Number__c,LEGACY_ID__c,SAP_marked_for_deletion__c from Billing_Account__c where name like: APT_Constants.SEPARATOR_PERCENT +inputAccName+ APT_Constants.SEPARATOR_PERCENT AND Organisation__c =:accId];       
            }   
        } catch(Exception ex) {
                haserrorMessages = true;
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                return null;
            }     
        return null;
   }
     
      /**
        This method is invoked from 'Go' button on the page and used to get the Billing account records based on input value. 
     **/
     public PageReference searchbillingAcc() {         
       try{
        getBillingAccounts();        
        if(billingAccAvailable.size() == 0){
             haserrorMessages = true;
             ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, APT_Constants.PLEASE_ENTER_BILLING_ACCOUNT));
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
        This method is invoked from 'Show all Biiling Accounts for this organisation' button on the page and used to get the Billing account records based on Organisation number. 
     **/
    public PageReference showAllbillingAccs() {
     try{
       billingAccAvailable =[select id,name,Suburb__c,State__c,Customer_Name__c,Customer_Number__c,LEGACY_ID__c,SAP_marked_for_deletion__c from Billing_Account__c where Organisation__c =:accId];        
       if(billingAccAvailable.size() == 0){
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, APT_Constants.THERE_ARE_NO_BILLING_ACCOUNTS1));
            return null;
         } 
       inputAccName =APT_Constants.EMPTY_STRING;       
     } catch(Exception ex) {
        haserrorMessages = true;
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        return null;
     }
        return null;
    }  
    
    /**
        Method to get the records based on input value. 
     **/
    public PageReference searchAccouts() { 
      try{ 
       if(inputAccName.equalsIgnorecase(APT_Constants.EMPTY_STRING)){
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, APT_Constants.PLEASE_ENTER_SOME_TEXT1));
            return null;
         } 
       
       if(source.equalsIgnorecase(APT_Constants.CASHACCOUNTCLM)){       
         cashAccAvailable =[select  id,Name,APT_Cust_Name__c,APT_ABN__c,APT_ACN__c from APT_Cash_Account__c where name like: APT_Constants.SEPARATOR_PERCENT +inputAccName+ APT_Constants.SEPARATOR_PERCENT AND APT_Proposal__c=:quoteId]; 
       }         
        if(source.equalsIgnorecase(APT_Constants.CHARGEACCOUNTCLM)){       
         chargeAccAvailable =[select id,Name,APT_Company_Name__c,APT_ABN__c,APT_ACN__c,APT_Credit_Limit_Required__c from APT_Charge_Account__c where name like: APT_Constants.SEPARATOR_PERCENT +inputAccName+ APT_Constants.SEPARATOR_PERCENT AND APT_Quote_Proposal__c =:quoteId];
        }
       
        if(source.equalsIgnorecase(APT_Constants.SUBACCOUNTCLM)){       
         subAccAvailable =[select id,Name,APT_Sub_Account_Contact_Name__c,APT_Sub_Account_Contact_Email_Address__c,APT_Charge_Account__c from APT_sub_Account__c where name like: APT_Constants.SEPARATOR_PERCENT +inputAccName+ APT_Constants.SEPARATOR_PERCENT AND APT_Quote_Proposal__c =:quoteId];       
        }
    
       } catch(Exception ex) {
        haserrorMessages = true;
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        return null;
     }
    
      return null;
    } 
    
    /**
        Method to show all records related to quote. 
     **/
    public void showAllAccs() {   
      
      try{ 
       if(source.equalsIgnorecase(APT_Constants.CASHACCOUNTCLM)){       
         cashAccAvailable =[select id,Name,APT_Cust_Name__c,APT_ABN__c,APT_ACN__c from APT_Cash_Account__c where APT_Proposal__c=:quoteId];
       }
       
        if(source.equalsIgnorecase(APT_Constants.CHARGEACCOUNTCLM)){       
         chargeAccAvailable =[select id,Name,APT_Company_Name__c,APT_ABN__c,APT_ACN__c,APT_Credit_Limit_Required__c from APT_Charge_Account__c where APT_Quote_Proposal__c =:quoteId];       
       }
       
        if(source.equalsIgnorecase(APT_Constants.SUBACCOUNTCLM)){       
         subAccAvailable =[select id,Name,APT_Sub_Account_Contact_Name__c,APT_Sub_Account_Contact_Email_Address__c,APT_Charge_Account__c from APT_sub_Account__c where APT_Quote_Proposal__c =:quoteId];       
       }  
       
       } catch(Exception ex) {
        haserrorMessages = true;
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));        
     }  
    
    }
}