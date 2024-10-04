/**************************************************
Type:       Utility Class for Opportunity Product Classification
Purpose:    Generate revenue schedule for OpportunityLineItem
                        
History:
--------------------------------------------------
03.07.2012  M. Isidro (Cloud Sherpas)       Created
04.07.2012  M. Isidro (Cloud Sherpas)       Added generation of revenue schedule functionality
10.07.2012  M. Isidro (Cloud Sherpas)       Added new logic to the generation of revenue schedule (Fiscal Year from July 1 to June 30)
07.08.2012  Richard Enojas (Salesforce.com) Modified logic to derive FY value for the Revenue Schedule records
09.07.2015  Eric Shen (Auspost)             Update  StageName = 'Identify',
02/06/2020   shashwat.a.nath@accenture.com Updated Methods to assign PS to running user to bypass Opportunity Creation Restriction in Classic and Restrict_Using_Path_Button_for_Closure
**************************************************/
public with sharing class OpportunityProductClassificationUtil {
    
    
    private static boolean alreadyCreatedSchedules = false;

    public static boolean hasCreatedSchedules() {
        return alreadyCreatedSchedules;
    }

    public static void setAlreadyCreatedSchedules() {
        alreadyCreatedSchedules = true;
    }
    
    public static void generateRevenueSchedule(List<OpportunityLineItem> oliList) {
        system.debug('*** ENTERED');
        system.debug('***oliList: ' + oliList);
        Map<String, Opportunity> idOpptyMap = new Map<String, Opportunity>();
        Map<String, String> pbeIdproductIdMap = new Map<String, String>();
        //Map<String, Revenue_Schedule__c> yearRevenueMap = new Map<String, Revenue_Schedule__c>();
        List<String> opptyIdList = new List<String>();
        List<String> pbeIdList = new List<String>();
        List<Revenue_Schedule__c> revSched = new List<Revenue_Schedule__c>();
        
        for (OpportunityLineItem oli : oliList) {
            //opptyIdList.add(oli.OpportunityId);
            pbeIdList.add(oli.PricebookEntryId);
        }
        
        List<PricebookEntry> pbeList = [SELECT Id, Product2Id FROM PricebookEntry WHERE Id in : pbeIdList];
        if (!pbeList.isEmpty()) {
            for (PricebookEntry pbe : pbeList) {
                pbeIdproductIdMap.put(pbe.id, pbe.Product2Id);          
            }
        }       
        
        /*
        List<Opportunity> opptyList = [SELECT Id, Contract_Start_Date__c, Contract_End_Date__c, StageName FROM Opportunity WHERE StageName='Closed Won' And Id in : opptyIdList];
        if (!opptyList.isEmpty()) {
            for (Opportunity oppty : opptyList) {
                idOpptyMap.put(oppty.id, oppty);            
            }
        }*/
        
        // Added by Adrian Recio
        // BAU Fix for Quote to Cash to get Ids for OLI for revenue schedule flushing/delete.
        // Date: 22/06/2017
        Set<Id> oliFlushSet = (new Map<Id,OpportunityLineItem>(oliList)).keySet();
        
        for (OpportunityLineItem oli : oliList) {
            system.debug('***oliList: ' + oliList);
/*          Opportunity oppty = idOpptyMap.get(oli.OpportunityId);
            if (oppty <> null) {
                
                Date dOrigStart = oppty.Contract_Start_Date__c;
                Date dStart = oppty.Contract_Start_Date__c;
                Date dEnd = oppty.Contract_End_Date__c;
*/
                Date dOrigStart = oli.Contract_Start_Date__c;
                Date dStart = oli.Contract_Start_Date__c;
                Date dEnd = oli.Contract_End_Date__c;
                system.debug('***generateRevenueSchedule - Start Date: ' + dStart);
                system.debug('***generateRevenueSchedule - End Date: ' + dEnd);
                                
                List<String> monthYearList = new List<String>();
                
                monthYearList = generateMonthYear(dStart, dEnd);
                
                system.debug('***monthYearList: ' + monthYearList);
            
                Map<String, Revenue_Schedule__c> yearRevenueMap = new Map<String, Revenue_Schedule__c>();
            
                for (String strMY : monthYearList) {
                    system.debug ('***For Loop***');
                    String financialYear = strMY.substring(0, 4);
                    String curYear = strMY.substring(4, 8);
                    String curMonth = strMY.substring(8, 11);
                    
                    system.debug('***FY: ' + financialYear);
                    
                    Decimal dTotalPrice = oli.TotalPrice;
                    Integer nParts = monthYearList.size();
                    //Double dEach = dTotalPrice / nParts; 
                    Decimal dEach = dTotalPrice.divide(nParts, 2, System.RoundingMode.UP);
                    
                    String prodId = pbeIdproductIdMap.get(oli.PricebookEntryId);
                    
                    if (yearRevenueMap.containsKey(financialYear)) {
                        Revenue_Schedule__c rs = new Revenue_Schedule__c();  
                        rs = yearRevenueMap.get(financialYear);
                        rs = populateRevenueSchedule(rs, curMonth, financialYear.substring(0, 4), financialYear, 
                                                     dEach, dOrigStart, dEnd, oli, prodId, false); 
                        yearRevenueMap.put(financialYear, rs);
                    } else {
                        Revenue_Schedule__c rs = new Revenue_Schedule__c();  
                        yearRevenueMap.put( financialYear, populateRevenueSchedule(rs, curMonth, financialYear.substring(0, 4), financialYear, dEach, dOrigStart, dEnd, oli, prodId, false) );  
                    }
                }   
                
                system.debug('***yearRevenueMap: ' + yearRevenueMap);  
                for (Revenue_Schedule__c rs : yearRevenueMap.values()) {
                    revSched.add(rs);           
                }       
            //}
        }
        
        // Added by: Adrian Recio
        // BAU Fix for Quote to Contract: Added to flush old revenue schedule
        // Date: 22/06/2017
        
        try{
            List<Revenue_Schedule__c>revenueFlushList = [Select Id from Revenue_Schedule__c where OpportunityLineItem__c In :oliFlushSet];
            if (revenueFlushList.size()>0){
                delete revenueFlushList;
            }
        }catch(exception e){
            system.debug('revenueFlushMessage:' + e.getMessage());
            system.debug('revenueFlushLineNumber:' + e.getLineNumber());
            system.debug('revenueCause:' + e.getCause());
        }
        
        if (!revSched.isEmpty()) {
            system.debug('***revSched: ' + revSched);           
            insert revSched;
        }
        
        
    }

/*
    public static void updateRevenueSchedule(List<OpportunityLineItem> oliListOrig, Map<Id, OpportunityLineItem> oldMap, Map<Id, OpportunityLineItem> newMap) {
        system.debug('*** ENTERED');
        system.debug('***oliList: ' + oliListOrig);
        Map<String, Opportunity> idOpptyMap = new Map<String, Opportunity>();
        Map<String, String> pbeIdproductIdMap = new Map<String, String>();
        //Map<String, Revenue_Schedule__c> yearRevenueMap = new Map<String, Revenue_Schedule__c>();
        List<String> opptyIdList = new List<String>();
        List<String> pbeIdList = new List<String>();
        List<Revenue_Schedule__c> revSched = new List<Revenue_Schedule__c>();
        List<String> oliIdList = new List<String>();
        List<OpportunityLineItem> oliListReclassified = new List<OpportunityLineItem>();
        Map<String, Revenue_Schedule__c> oliIdYearRevSchedIdMap = new Map<String, Revenue_Schedule__c>();
        
        for (OpportunityLineItem oli : oliListOrig) {
            system.debug('***newMap: ' + newMap);
            system.debug('***oldMap: ' + oldMap);
            if (newMap.get(oli.Id).Classification__c != oldMap.get(oli.Id).Classification__c) {
                oliListReclassified.add(oli);   
            }   
        }

        system.debug('***oliListReclassified: ' + oliListReclassified);
        for (OpportunityLineItem oli : oliListReclassified) {
            opptyIdList.add(oli.OpportunityId);
            pbeIdList.add(oli.PricebookEntryId);
            oliIdList.add(oli.Id);
        }
        
        List<PricebookEntry> pbeList = [SELECT Id, Product2Id FROM PricebookEntry WHERE Id in : pbeIdList];
        if (!pbeList.isEmpty()) {
            for (PricebookEntry pbe : pbeList) {
                pbeIdproductIdMap.put(pbe.id, pbe.Product2Id);          
            }
        }       
        
        List<Opportunity> opptyList = [SELECT Id, Contract_Start_Date__c, Contract_End_Date__c, StageName FROM Opportunity WHERE StageName='Closed Won' And Id in : opptyIdList];
        if (!opptyList.isEmpty()) {
            for (Opportunity oppty : opptyList) {
                idOpptyMap.put(oppty.id, oppty);            
            }
        }
        
        for (OpportunityLineItem oli : oliListReclassified) {
            system.debug('***oliList: ' + oliListReclassified);
            Opportunity oppty = idOpptyMap.get(oli.OpportunityId);
            if (oppty <> null) {

                Date dOrigStart = oli.Contract_Start_Date__c;
                Date dStart = oli.Contract_Start_Date__c;
                Date dEnd = oli.Contract_End_Date__c;
                                
                List<String> monthYearList = new List<String>();
                
                monthYearList = generateMonthYear(dStart, dEnd);
                
                system.debug('***monthYearList: ' + monthYearList);
            
                Map<String, Revenue_Schedule__c> yearRevenueMap = new Map<String, Revenue_Schedule__c>();
            
                for (String strMY : monthYearList) {
                    String financialYear = strMY.substring(0, 4);
                    String curYear = strMY.substring(4, 8);
                    String curMonth = strMY.substring(8, 11);
                    
                    Decimal dTotalPrice = oli.TotalPrice;
                    Integer nParts = monthYearList.size();
                    //Decimal dEach = dTotalPrice / nParts; 
                    Decimal dEach = dTotalPrice.divide(nParts, 2, System.RoundingMode.UP);
                    
                    String prodId = pbeIdproductIdMap.get(oli.PricebookEntryId);
                    
                    if (yearRevenueMap.containsKey(financialYear)) {
                        Revenue_Schedule__c rs = new Revenue_Schedule__c();  
                        rs = yearRevenueMap.get(financialYear);
                        rs = populateRevenueSchedule(rs, curMonth, financialYear.substring(0, 4), financialYear, dEach, dOrigStart, dEnd, oli, prodId, true); 
                        yearRevenueMap.put(financialYear, rs);
                    } else {
                        Revenue_Schedule__c rs = new Revenue_Schedule__c();  
                        yearRevenueMap.put( financialYear, populateRevenueSchedule(rs, curMonth, financialYear.substring(0, 4), financialYear, dEach, dOrigStart, dEnd, oli, prodId, true) );  
                    }
                }   
                
                system.debug('***yearRevenueMap: ' + yearRevenueMap);  
                for (Revenue_Schedule__c rs : yearRevenueMap.values()) {
                    revSched.add(rs);           
                } 
                
                for (Revenue_Schedule__c rs : revSched) {
                    oliIdYearRevSchedIdMap.put(rs.OpportunityLineItem__c + ':' + rs.CalendarYear__c, rs);
                }                        
            }
        }
        
        if (!revSched.isEmpty()) {
            system.debug('***revSched: ' + revSched);     

            List<Revenue_Schedule__c> rsList = [SELECT Id, CalendarYear__c, Financial_Year__c, Contract_Start_Date__c,
                Contract_End_Date__c, Classification_c__c, Opportunity__c, Product__c, OpportunityLineItem__c,
                Jan_Claimed_Revenue__c, Feb_Claimed_Revenue__c, Mar_Claimed_Revenue__c, 
                Apr_Claimed_Revenue__c, May_Claimed_Revenue__c, Jun_Claimed_Revenue__c,
                Jul_Claimed_Revenue__c, Aug_Claimed_Revenue__c, Sep_Claimed_Revenue__c,
                Oct_Claimed_Revenue__c, Nov_Claimed_Revenue__c, Dec_Claimed_Revenue__c
                FROM Revenue_Schedule__c WHERE OpportunityLineItem__c in : oliIdList];
            
            if (!rsList.isEmpty()) {
                for (Revenue_Schedule__c rs : rsList) {
                    Revenue_Schedule__c tempRS = new Revenue_Schedule__c();
                    tempRS = oliIdYearRevSchedIdMap.get(rs.OpportunityLineItem__c + ':' + rs.CalendarYear__c);

                    rs.CalendarYear__c = tempRS.CalendarYear__c;
                    rs.Financial_Year__c = tempRS.Financial_Year__c;
                    rs.Contract_Start_Date__c = tempRS.Contract_Start_Date__c;
                    rs.Contract_End_Date__c = tempRS.Contract_End_Date__c;
                    rs.Classification_c__c = tempRS.Classification_c__c;
                    rs.Opportunity__c = tempRS.Opportunity__c;
                    rs.Product__c = tempRS.Product__c;
                    rs.OpportunityLineItem__c = tempRS.OpportunityLineItem__c;
                    rs.Reclassified__c = tempRS.Reclassified__c;
                    
                    rs.Jan_Claimed_Revenue__c = tempRS.Jan_Claimed_Revenue__c;
                    rs.Feb_Claimed_Revenue__c = tempRS.Feb_Claimed_Revenue__c;
                    rs.Mar_Claimed_Revenue__c = tempRS.Mar_Claimed_Revenue__c;
                    rs.Apr_Claimed_Revenue__c = tempRS.Apr_Claimed_Revenue__c;
                    rs.May_Claimed_Revenue__c = tempRS.May_Claimed_Revenue__c;
                    rs.Jun_Claimed_Revenue__c = tempRS.Jun_Claimed_Revenue__c;
                    rs.Jul_Claimed_Revenue__c = tempRS.Jul_Claimed_Revenue__c;
                    rs.Aug_Claimed_Revenue__c = tempRS.Aug_Claimed_Revenue__c;
                    rs.Sep_Claimed_Revenue__c = tempRS.Sep_Claimed_Revenue__c;
                    rs.Oct_Claimed_Revenue__c = tempRS.Oct_Claimed_Revenue__c;
                    rs.Nov_Claimed_Revenue__c = tempRS.Nov_Claimed_Revenue__c;
                    rs.Dec_Claimed_Revenue__c = tempRS.Dec_Claimed_Revenue__c;
                }  
                update rsList;
            }
        }
    }
*/


    public static void updateRevenueSchedule(List<OpportunityLineItem> oliList, Map<Id, OpportunityLineItem> oldMap) {
        List<String> oliIdList = new List<String>();
        Map<Id, String> oliMap = new Map<Id, String>();
        List<Revenue_Schedule__c> rsUpdList = new List<Revenue_Schedule__c>();
    	/*
        for(OpportunityLineItem oli : oliList) {
            if (oli.Classification__c!=oldMap.get(oli.Id).Classification__c){
                system.debug('Reclassification!');
                oliIdList.add(oli.Id);
                oliMap.put(oli.Id, oli.Classification__c);
            }           
        }
        */
        List<Revenue_Schedule__c> rsList = [SELECT Id, Classification_c__c, OpportunityLineItem__c 
                                            FROM Revenue_Schedule__c 
                                            WHERE OpportunityLineItem__c in : oliIdList];
        
        if(!rsList.isEmpty()){
            system.debug('Update Revenue Schedules');
            for (Revenue_Schedule__c rs : rsList){
                if(oliMap.containsKey(rs.OpportunityLineItem__c)){
                    rs.Classification_c__c = oliMap.get(rs.OpportunityLineItem__c);
                    rsUpdList.add(rs);
                }   
            }
        
        
            if(!rsUpdList.isEmpty())
                update rsUpdList;
        
        }       
    }
    
    
    public static Revenue_Schedule__c populateRevenueSchedule(Revenue_Schedule__c rs, String curMonth, String curYear, String financialYear, Decimal dEach, Date dStart, Date dEnd, OpportunityLineItem oli, String prodId, Boolean Reclassified) {
        rs.CalendarYear__c = curYear;
        rs.Financial_Year__c = financialYear;
        rs.Contract_Start_Date__c = dStart;
        rs.Contract_End_Date__c = dEnd;
        rs.Classification_c__c = oli.Classification__c;
        rs.Opportunity__c = oli.OpportunityId;
        rs.Product__c = prodId;
        rs.OpportunityLineItem__c = oli.Id;
        rs.Reclassified__c = Reclassified;
        
        if (curMonth == 'Jan') {
            rs.Jan_Claimed_Revenue__c = dEach;
        } else if (curMonth == 'Feb') {
            rs.Feb_Claimed_Revenue__c = dEach;
        } else if (curMonth == 'Mar') {
            rs.Mar_Claimed_Revenue__c = dEach;                      
        } else if (curMonth == 'Apr') {
            rs.Apr_Claimed_Revenue__c = dEach;                      
        } else if (curMonth == 'May') {
            rs.May_Claimed_Revenue__c = dEach;                      
        } else if (curMonth == 'Jun') {
            rs.Jun_Claimed_Revenue__c = dEach;                      
        } else if (curMonth == 'Jul') {
            rs.Jul_Claimed_Revenue__c = dEach;                      
        } else if (curMonth == 'Aug') {
            rs.Aug_Claimed_Revenue__c = dEach;                      
        } else if (curMonth == 'Sep') {
            rs.Sep_Claimed_Revenue__c = dEach;                      
        } else if (curMonth == 'Oct') {
            rs.Oct_Claimed_Revenue__c = dEach;                      
        } else if (curMonth == 'Nov') {
            rs.Nov_Claimed_Revenue__c = dEach;                      
        } else if (curMonth == 'Dec') {
            rs.Dec_Claimed_Revenue__c = dEach;                      
        }                       
        return rs;
    }   

    
    public static List<String> generateMonthYear(Date startDate, Date endDate) {
        system.debug('***generateMonthYear - Start Date: ' + startDate);
        system.debug('***generateMonthYear - End Date: ' + endDate);
        Date dStart = startDate;
        Date dEnd = endDate;
        List<String> monthYearList = new List<String>();
        
        while ( (dStart < dEnd) || ( dStart >= dEnd && dStart.month() == dEnd.month() ) ) {
            system.debug('generate monthYearList');
            monthYearList.add( getMonthYear(dStart) );
            dStart = dStart.addMonths(1);
        }
        
        system.debug('***dStart: ' + dStart);
        system.debug('***dEnd: ' + dEnd);
                   
        return monthYearList;
    }   
    

    public static String getMonthYear(Date theDate) {
        String ret = '';
        Integer nYear = theDate.year();
        Integer nMonth = theDate.month();
/*
        if (nMonth >= 7) {
            ret = ret + String.valueOf(nYear) + '/' +  String.valueOf(nYear + 1) + String.valueOf(nYear);       
        } else {
            ret = ret + String.valueOf(nYear - 1) + '/' +  String.valueOf(nYear) + String.valueOf(nYear);       
        }
*/
/***07.08.2012***
        if (nMonth >= 7) {
            ret = ret + String.valueOf(nYear + 1) + '/' +  String.valueOf(nYear + 2) + String.valueOf(nYear + 1);       
        } else {
            ret = ret + String.valueOf(nYear) + '/' +  String.valueOf(nYear + 1) + String.valueOf(nYear + 1);       
        }
***/
        if (nMonth >= 7) {
            ret = ret + String.valueOf(nYear+1) + String.valueOf(nYear+1);       
        } else {
            ret = ret + String.valueOf(nYear) + String.valueOf(nYear+1);       
        }

        if (nMonth == 1) {
            ret = ret + 'Jan';  
        } else if (nMonth == 2) {
            ret = ret + 'Feb';  
        } else if (nMonth == 3) {
            ret = ret + 'Mar';  
        } else if (nMonth == 4) {
            ret = ret + 'Apr';  
        } else if (nMonth == 5) {
            ret = ret + 'May';          
        } else if (nMonth == 6) {
            ret = ret + 'Jun';  
        } else if (nMonth == 7) {
            ret = ret + 'Jul';  
        } else if (nMonth == 8) {
            ret = ret + 'Aug';  
        } else if (nMonth == 9) {
            ret = ret + 'Sep';  
        } else if (nMonth == 10) {
            ret = ret + 'Oct';  
        } else if (nMonth == 11) {
            ret = ret + 'Nov';          
        } else if (nMonth == 12) {
            ret = ret + 'Dec';  
        }
        return ret;     
    }
    
        
    
    @isTest(seeAllData=true)
    private static void testGenerateRevenueSchedule() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Team'];            
        User u1 = new User(Alias = 'testname', Email='test@auspost.com.au',                         
                        EmailEncodingKey='UTF-8', LastName='xTesting', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id, isActive = true,
                        TimeZoneSidKey='America/Los_Angeles', UserName='auTestX@auspost.com.au');
        insert u1;
        
        // Query your permission set name from Organization to bypass the validation.
        List<PermissionSet>  psList = new List<PermissionSet>();
        psList = [SELECT Id FROM PermissionSet WHERE Name = 'ValidationRuleBypassClassicRestrictions' LIMIT 1];
       
        // Assign the above inserted user for the above Permission Set.
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = u1.Id;
        psa.PermissionSetId = psList[0].id;
        insert psa;
        
        System.runAs(u1) {
            List<Account> acctList = new List<Account>();
        RecordType orgrectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];   
            
        //create account
         Account orgAccount = new Account(
            name='test org', recordtypeid=orgrectype.Id, type='Small Business',  
            phone='11111111', email__c='test@test.com', abn__c='12345678901', Website='www.google.com',
            Organisation_Trading_Name__c='Trade',
            BillingCity='City',
            BillingCountry='Country',
            BillingState='State',
            BillingPostalCode='12345',
            ShippingCity='City',
            ShippingCountry='Country',
            ShippingState='State',
            ShippingStreet='Street',
            ShippingPostalCode='12345'          
        );
        insert orgAccount;
        
        Organisation_Role__c orgRole = [SELECT Id, Role_Type__c FROM Organisation_Role__c WHERE Organisation__c =: orgAccount.Id limit 1];
        orgRole.Role_Type__c='Customer';        
        update OrgRole;   
        
        //create child account
        Account childAccount = new Account(
            name='Child Account',
            ParentId=orgAccount.id, 
            //recordtypeid=orgRecType.Id, 
            phone='12345678901', 
            email__c='xc@x.com',
            abn__c='12345678902', 
            Website='www.googlex.com'            
            
        );
        insert childAccount;  
            
        //create account
        Opportunity oppty = new Opportunity(
            name='Opportunity', 
            StageName = 'Identify',
            closedate = date.today(),
            Contract_Start_Date__c=date.today(),
            Contract_End_Date__c=date.today() + 1000,
            Closed_Reason__c='Reason',
            accountid=orgAccount.id,
            Type='New Customer',Contract_Number__c='99999'
        );
            // 10/23/19: Closed Won Governance requirements
            oppty.Pre_Entry__c = true;                  // Pre-Entry scenario
            oppty.Offline_Contract_Received__c = true;  // For Opportunity Products that require Contracts
            oppty.Data_Integrity_Compliance__c = true;  // Data Integrity Compliance
        insert oppty;
        
        String code = 'TEST';
        Integer nCount = 2;
        Pricebook2 pb = [select id from Pricebook2 where IsStandard = true];
        
        List<Product2> prodList = new List<Product2>();
        for(integer i = 0; i < nCount; i++) {
            Product2 prod = new Product2(
                Name = 'Sample Product' + String.valueOf(i),
                IsActive = true,
                ProductCode = code
            );
            prodList.add(prod);
        }
        insert prodList;        
   
        List<PricebookEntry> pbeList = new List<PricebookEntry>();       
        for(integer i = 0; i < nCount; i++) {
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = pb.Id,
                Product2Id = prodList[i].Id, 
                IsActive = true,
                UnitPrice = 1000,
                UseStandardPrice=false
            );
            pbeList.add(pbe);
        }
        insert pbeList;
      
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for(integer i = 0; i < nCount; i++) {
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = oppty.id,
                PriceBookEntryId = pbeList[i].Id,
                Quantity = 1,
                TotalPrice = 1000,
                Classification__c = 'New Business',
                Contract_Start_Date__c=date.today(),
                Contract_End_Date__c=date.today() + 1000,
                Contract_Number__c='99999'
            );
            oliList.add(oli);
        }
        insert oliList; 
        
        oppty.StageName = 'Closed Won';
        oppty.Hidden_Restrict_Path_Closure__c = true; // shashwat.a.nath added to bypass the validation Restrict_Using_Path_Button_for_Closure
        update oppty;  
        
        oliList[0].Classification__c = 'New Business - One Off';
        update oliList;
        
        List<OpportunityLineItem> delList = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId =:oppty.Id limit 1];
        delete delList;  
        }
        
            
    }

}