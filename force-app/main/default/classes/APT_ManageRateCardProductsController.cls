/**
Description - This apex class is controller for vf page APT_ManageRateCardProducts. This class will manage
              domestic and international rate card pricing creation using batch.
Created By - Mausam Padhiyar
Created Date - 28th Sept, 2015
**/
public with sharing class APT_ManageRateCardProductsController {
    
    public boolean haserrorMessages {get; set;}
    
    public String startDate {get; set;}
    public String startHour {get; set;}
    public String startMin {get; set;}
    
    public Integer numDates {get; set;}
    
    public Map<Integer,String> mapInt2Months = new Map<Integer,String>
        {1=>APT_Constants.MONTH_JAN,2=>APT_Constants.MONTH_Feb,3=>APT_Constants.MONTH_Mar,4=>APT_Constants.MONTH_Apr,5=>APT_Constants.MONTH_May,6=>APT_Constants.MONTH_Jun,7=>APT_Constants.MONTH_Jul,8=>APT_Constants.MONTH_Aug,9=>APT_Constants.MONTH_Sep,10=>APT_Constants.MONTH_Oct,11=>APT_Constants.MONTH_Nov,12=>APT_Constants.MONTH_Dec};
    
    /**
    constructor
    **/
    public APT_ManageRateCardProductsController() {
        haserrorMessages = false;
        if(!String.isEmpty(APT_Constants.ADD_TEN))
            startHour = APT_Constants.ADD_TEN;
        if(!String.isEmpty(APT_Constants.ADD_DOUBLEZERO))
            startMin  = APT_Constants.ADD_DOUBLEZERO;
        numDates  = 30;
    }
    
    /**
    start hours
    **/
    public List<selectOption> getStartHours() {
        List<selectOption> options = new List<selectOption>();
        try {
            selectOption so1 = new selectOption(APT_Constants.DEFINE_STRING,APT_Constants.DEFINE_STRING);
            for (Integer iH = 0; iH < 24; iH++) {
                String numberVal = String.valueOf(iH);
                if (iH < 10) numberVal = APT_Constants.ADD_ZERO + numberVal;
                so1 = new selectOption(numberVal, numberVal);
                options.add(so1);
            }
        } catch(system.exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null; 
        }
        return options;
    }

    /**
    start mins
    **/
    public List<selectOption> getStartMins() {
        List<selectOption> options = new List<selectOption>();
        try {
            selectOption so1 = new selectOption(APT_Constants.DEFINE_STRING,APT_Constants.DEFINE_STRING);
            for (Integer iM = 0; iM < 60; iM++) {
                String numberVal = String.valueOf(iM);
                if (iM < 10) numberVal = APT_Constants.ADD_ZERO + numberVal;
                so1 = new selectOption(numberVal, numberVal);
                options.add(so1);
            }
            return options;
        } catch(system.exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null; 
        }
    }
    
    /**
    start dates
    **/
    public List<selectOption> getStartDates() {
        
        List<selectOption> options = new List<selectOption>();
        try {
            Date wrkDate = System.Today().addDays(-1);
            selectOption so1 = new selectOption(APT_Constants.DEFINE_STRING,APT_Constants.DEFINE_STRING);
            
            for (Integer iD = 0 ; iD <= numDates ; iD++) {
    
                wrkDate = wrkDate.addDays(1);
    
                String strDate    = APT_Constants.DEFINE_STRING;
                strDate = strDate + String.valueOf(wrkDate.day());
                strDate = strDate + APT_Constants.ADD_HYPHEN;
                strDate = strDate + mapInt2Months.get(wrkDate.month());
                strDate = strDate + APT_Constants.ADD_HYPHEN;
                strDate = strDate + String.valueOf(wrkDate.year());
    
                String strDateVal = APT_Constants.DEFINE_STRING;
                strDateVal = strDateVal + String.valueOf(wrkDate.day());
                strDateVal = strDateVal + APT_Constants.ADD_WHITESPACE;
                strDateVal = strDateVal + String.valueOf(wrkDate.month());
                strDateVal = strDateVal + APT_Constants.ADD_COLON;
                strDateVal = strDateVal + String.valueOf(wrkDate.year());
                so1 = new selectOption(strDateVal, strDate);
                options.add(so1);
    
            }
        } catch(system.exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null; 
        }
        return options;
    }
    
    /**
        This method will call batch to calculate international pricing.
        i.e. Price List Item, Price Matrix and Price Matrix Entry
     */
    public PageReference calculateInternationalPricing() {
        try {            
            //String startDateDM = startDate.split('\\:')[0];
            //String startDateYY = startDate.split('\\:')[1];
            String strJob = APT_Constants.INTERNATIONAL_PRICING_JOB;    //job name
            
            //cron expression
            String strTimer = APT_Constants.ADD_ZERO         // Secs
                            + APT_Constants.ADD_WHITESPACE
                            + startMin    // Mins
                            + APT_Constants.ADD_WHITESPACE
                            + startHour   // Hrs
                            + APT_Constants.ADD_WHITESPACE
                            + startDate   // Day + space + Month
                            + APT_Constants.ADD_WHITESPACE
                            + APT_Constants.ADD_QUESTIONMARK         // Day Of Week = Any
                            + APT_Constants.ADD_WHITESPACE
                            + APT_Constants.ADD_ASTERISK         // 
                        ;
            
            APT_CalculateInternationalPricingSched runClass = new APT_CalculateInternationalPricingSched();
            System.Schedule(strJob, strTimer, runClass);    
            
            haserrorMessages = true;    // not an error. set as true to display info message
            //add info message
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, APT_Constants.JOB_EXECUTION_SUCCESSFUL));
        } catch(system.exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null; 
        }
        
        return null;
    }
    
    /**
        This method will calculate domestic pricing
     */
    public PageReference calculateDomesticPricing() {
        try {
            //String startDateDM = startDate.split('\\:')[0];
            //String startDateYY = startDate.split('\\:')[1];
            String strJob = APT_Constants.DOMESTIC_PRICING_JOB;    //job name
            
            //cron expression
            String strTimer = APT_Constants.ADD_ZERO        // Secs
                            + APT_Constants.ADD_WHITESPACE
                            + startMin    // Mins
                            + APT_Constants.ADD_WHITESPACE
                            + startHour   // Hrs
                            + APT_Constants.ADD_WHITESPACE
                            + startDate   // Day + space + Month
                            + APT_Constants.ADD_WHITESPACE
                            + APT_Constants.ADD_QUESTIONMARK         // Day Of Week = Any
                            + APT_Constants.ADD_WHITESPACE
                            + APT_Constants.ADD_ASTERISK        // 
                        ;
            
            APT_CalculateDomesticPricingSched runClass = new APT_CalculateDomesticPricingSched();
            System.Schedule(strJob, strTimer, runClass);    
            
            haserrorMessages = true;    // not an error. set as true to display info message
            //add info message
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, APT_Constants.JOB_EXECUTION_SUCCESSFUL));
            
        } catch(System.Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
        
        return null;
    }
}