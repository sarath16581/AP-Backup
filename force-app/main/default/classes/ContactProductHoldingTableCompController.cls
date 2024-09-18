/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 19/10/2015
  * @description  : Controller class for listing product holdings in tabular format
  * @assumption   : NA
  */  
public with sharing class ContactProductHoldingTableCompController {

    public List<ProdHoldWrapp> listOfProdHold {get;set;}
    //public List<Addresses__x> listOfAdd {get;set;}
    public boolean showLast {get;set;}
    public MyPostCards__x pstCrd {get;set;}
    private boolean notFrst = true;
    public boolean showPopup {get;set;}
    public String typePrdHld {get;set;}
    public String statusPrdHld {get;set;}
    public Addresses__x delAddrss {get;set;}
    public List<Addresses__x> delAddrssList {get;set;}
    public List<Assets__x> assetVal {get;set;}
    public Map<String, leaseheaders__x> lhdMap {get;set;}
    public String instId {get;set;}
    public leaseheaders__x lhd {get;set;}
    // instantiate the StandardSetController from a query locator
    public ApexPages.StandardSetController con {get;set;}
    public ApexPages.StandardSetController conAddress {get;set;}
    private String conApcn = ''; 
    private Boolean hereFrst = true;
    private static final string CLASS_NAME = 'ContactProductHoldingTableCompController';
    private static final string METHOD_NAME1 = 'retrieveProdtHoldings';
    private static final string METHOD_NAME2 = 'getListOfProdHold';
   
    //constants used in class
    private static final String MYPOST_CARD = 'MYPOST_CARD';
    private static final String MYPOST_CONSUMER = 'MYPOST_CONSUMER';
    private static final String MYDELIVERIES = 'MYDELIVERIES';
    private static final String PARCEL_LOCKER = 'PARCEL_LOCKER';
    private static final String PARCEL_COLLECT = 'PARCEL_COLLECT';
    private static final String POB = 'POB';
    private static final String ZDCE_UPL_D = 'ZDCE_UPL_D';    
    private static final String ZDCE_COL_P = 'ZDCE_COL_P';    
    private static final String IMG_URL_CONCAT = 'productholdings/';
    private static final String IMG_FORMAT = '.png';                
    private static final String COLOR_CODED_STATUSES = 'Active,New,Replaced due to loss,Replaced due to name change,Passed,Expired,Invalidate,Inactive' + 
                                 '17000,67909,CASEMAN,  IDV_MYPOST,MPBiz,MYDELIVERIES,MYIDENTITY,MYPOST_CARD,MYPOST_CONSUMER,PARCEL_COLLECT,' +
                                 'PARCEL_LOCKER, POB, RECEIVER_SERVICES,APOLN';
    private static final String DATE_FORMAT = 'dd/MM/yy HH:mm';
    private static final String ZONE = 'Australia/Sydney';
    
    /**
      * @description       method called on click of product holding to query internal table
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    public void showPopup() {
        try {
            showPopup = true;
            system.debug(typePrdHld );
            system.debug(instId);
            assetVal = new List<Assets__x>();
            pstCrd = new MyPostCards__x ();
            delAddrss = new Addresses__x();
            lhd = new leaseheaders__x();
            delAddrssList = new List<Addresses__x>();
            lhdMap = new Map<String, leaseheaders__x>();
            
                if(MYPOST_CARD.equalsIgnoreCase(typePrdHld) || MYPOST_CONSUMER.equalsIgnoreCase(typePrdHld)) {
                     for(MyPostCards__x pCrd:[select ActivationDate__c, APCN__c, AvailableStampEntitlement__c, CardNumber__c, NextStampAllocationDate__c,CardStatusID__c 
                                from MyPostCards__x  where APCN__c = :conApcn and CardNumber__c=:instId]) { pstCrd = pCrd;     
                    }
                }
                else if(MYDELIVERIES.equalsIgnoreCase(typePrdHld)) {
                     for(Addresses__x add:[select DeliveryAddressee__c, APCN__c, UsageTypeID__c ,Street__c, Street2__c, RegionID__c,City__c,CountryID__c,PostCode__c
                                from Addresses__x where APCN__c = :conApcn  ]) { if(add.UsageTypeID__c !=ZDCE_UPL_D && add.UsageTypeID__c!=ZDCE_COL_P ) delAddrssList.add(add); }
                }
                else if(PARCEL_LOCKER.equalsIgnoreCase(typePrdHld)) {
                      for(Addresses__x add:[select DeliveryAddressee__c, APCN__c,UsageTypeID__c, Street__c, Street2__c, RegionID__c,City__c,CountryID__c,PostCode__c
                               from Addresses__x where APCN__c = :conApcn  ]) { if(add.UsageTypeID__c==ZDCE_UPL_D) delAddrssList.add(add); }
                }
                else if(PARCEL_COLLECT.equalsIgnoreCase(typePrdHld)) {
                     for(Addresses__x add:[select DeliveryAddressee__c, APCN__c,UsageTypeID__c , Street__c, Street2__c, RegionID__c,City__c,CountryID__c,PostCode__c
                                from Addresses__x where APCN__c = :conApcn ]) { if(add.UsageTypeID__c==ZDCE_COL_P) delAddrssList.add(add); }
                }
                else if(POB.equalsIgnoreCase(typePrdHld)) {
                     for(LeaseHeaders__x lHdr : [select LeaseID__c, APCN__c, ServiceDescription__c, ServiceLocation__c,assetId__c ,StatusId__c,ServiceType__c,IsInvoiceDue__c
                        from LeaseHeaders__x where APCN__c=:conApcn and assetId__c =:instId]) { lhd = lhdr; }
                }
            if(!delAddrssList.isEmpty()) {
                conAddress = new  ApexPages.StandardSetController((delAddrssList));
                conAddress.setPageSize(2);
            }
        }
        catch(Exception exp) {
            //log the exception record
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, CLASS_NAME, 'showPopup', null, LoggingLevel.ERROR);
        }
    }
    
    
    /**
      * @description       method to close the popup window
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    public void closePopup() {
        showPopup = false;
    }    
    
    //getter setter for producy holding icon map
    public Map<String,String> prdHoldIconMap {
        get {
            Map<String,String> mIcnMap = new Map<String,String>();
            for(ProductHolding_IconColor_Settings__c mp: ProductHolding_IconColor_Settings__c.getAll().values()) {
                if(mp.isColor__c) {
                    mIcnMap.put(mp.Name,mp.Value__c);
                }
                else {
                    mIcnMap.put(mp.Name,IMG_URL_CONCAT+mp.Value__c+IMG_FORMAT);
                }
            }
            
            return mIcnMap;
        } set;
    }
    
   //getter to get all the status for color coding
   public String statusKeyValues  {get {
       String statusKeyValues  = COLOR_CODED_STATUSES;
       return statusKeyValues;
   } set;}
   
    //getter setter for personContactId
    public Id contId {
        get; set {
             if (value != null && notFrst ) {
                listOfProdHold = new List<ProdHoldWrapp>();
                contId = value;
                retrieveProdtHoldings(value);
                getlistOfProdHold();
                notFrst = false;
            }
        }
    }
    
    //inner class to hold product holding data
    @TestVisible
    public class ProdHoldWrapp {
        public String prdId {get;set;}
        public String prodDesc {get;set;}
        public DateTime lastChngDate {get;set;}
        public String statusDesc {get;set;}      
        public String UCTDateTime {get;set;}     
        public String instId {get;set;}
        public ProdHoldWrapp (String prodDesc, DateTime lastChngDate, String statusDesc,String instId,String prdId ) {
            this.prodDesc = prodDesc;
            this.lastChngDate = lastChngDate;
            UCTDateTime = lastChngDate.format(DATE_FORMAT, ZONE);
            this.statusDesc = statusDesc;
            this.instId = instId ;
            this.prdId = prdId;
        }
    }
      
     /**
      * @description       method to query on the product holing external object
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    public void retrieveProdtHoldings(String contId) {
        
        try {
            if(con == null && contId !=null ) {
                List<ProductHoldings__x> px = new List<ProductHoldings__x>();
                showPopup = false;
                conApcn = [Select Id, APCN__pc from Account where PersonContactId =:contId limit 1].APCN__pc;
                if(!String.isBlank(conApcn)) {
                   px = [SELECT CategoryID__c, ProductDescription__c,LastChangeDate__c,StatusDescription__c, InstanceID__c, ProductID__c
                                        FROM ProductHoldings__x WHERE APCN__c = :conApcn order by InstanceID__c desc];
                   con = new ApexPages.StandardSetController((px));
                   //system.debug('-con-'+con);
                   con.setPageSize(5);
                }
            }  
        } catch(Exception exp) {
            //log the exception record
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                CLASS_NAME, METHOD_NAME1, null, LoggingLevel.ERROR);
        }
    }

    // returns a list of wrapper objects for the sObjects in the current page set
    public List<ProdHoldWrapp> getlistOfProdHold() {
    
        try {
            
            if(con != null ) {
                listOfProdHold = new List<ProdHoldWrapp>();
                for (ProductHoldings__x c: (List<ProductHoldings__x >)con.getRecords())
                    listOfProdHold.add(new ProdHoldWrapp(c.ProductDescription__c, c.LastChangeDate__c,c.StatusDescription__c,c.InstanceID__c,c.ProductID__c));
            }
        } catch(Exception exp) {
            //log the exception record
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                CLASS_NAME, METHOD_NAME1, null, LoggingLevel.ERROR);
        }
        return listOfProdHold;
    }

    // indicates whether there are more records after the current page set.
    public Boolean hasNext {
        get {
            return con!=null ? con.getHasNext() : false;
        } set;
    }

    // indicates whether there are more records before the current page set.
    public Boolean hasPrevious {
        get {
            return con!=null ? con.getHasPrevious() : false;
        } set;
    }

    // returns the page number of the current page set
    public Integer pageNumber {
        get {
            return con!=null ? con.getPageNumber() : 1 ;
        } set;
    }

    // returns the first page of records
     public void first() {
         if(!Test.isRunningTest() && con!=null) con.first() ;
         getlistOfProdHold();
     }

     // returns the last page of records
     public void last() {
         if(!Test.isRunningTest() && con!=null) con.last() ;
         getlistOfProdHold();
     }

     // returns the previous page of records
     public void previous() {
         if(!Test.isRunningTest() && con!=null)con.previous() ;
         getlistOfProdHold();
     }

     // returns the next page of records
     public void next() {
         if(!Test.isRunningTest() && con!=null)con.next() ;
         getlistOfProdHold();
     }
     
     // returns the previous page of records
     public void previousAdd() {
         if(!Test.isRunningTest() && conAddress!=null)conAddress.previous() ;  
     }

     // returns the next page of records
     public void nextAdd() {
         if(!Test.isRunningTest() && conAddress!=null)conAddress.next() ;
     }
     
     // indicates whether there are more records before the current page set.
    public Boolean hasPreviousAdd {
        get {
            return conAddress!=null ? conAddress.getHasPrevious() : false;
        }
        set;
    }
    
    // indicates whether there are more records before the current page set.
    public Boolean hasNextAdd {
        get {
            return conAddress!=null ? conAddress.gethasNext() : false;
        } set;
    }
     
    // returns the list of addresses for standardSetController for paginating
    public List<Addresses__x> getlistOfAdd() {
        List<Addresses__x> listOfAdd;
        try {
            if(conAddress != null ) { listOfAdd = new List<Addresses__x>();
                listOfAdd = (List<Addresses__x>)conAddress.getRecords();
            } 
        }catch(Exception exp) {
            //log the exception record
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                CLASS_NAME, 'getlistOfAdd', 
                                                null, LoggingLevel.ERROR);
        }
        return listOfAdd;
    }

}