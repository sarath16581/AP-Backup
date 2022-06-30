/**************************************************
Type:       Utility Class for Opportunity Product Classification (OPC)
Purpose:    
Used By:    
History:
--------------------------------------------------
10.08.2012  M. Isidro (Cloud Sherpas)   Created
13.08.2012  M. Isidro (Cloud Sherpas)   Converted GenerateOPCBatch Schedulable Class methods to methods of this Class
15.08.2012  M. Isidro (Cloud Sherpas)   Consolidation of logic flow and OPCUtility Class
22.08.2012  M. Isidro (Cloud Sherpas)   Do not update growth field when Revenue Schedule is in the future
                                        Do not raise a Case for New Customer, Cross Sell and Win Back if exception is found AND the Revenue Schedule Multi-year flag is set
31.08.2012  M. Isidro (Cloud Sherpas)   Added checking for null values (Revenues)
04.09.2012  M. Isidro (Cloud Sherpas)   Added test coverage
11.09.2012  M. Isidro (Cloud Sherpas)   Fixed heap size too large error
12.09.2012  M. Isidro (Cloud Sherpas)   Changed logic of query of existing OPC records
26.09.2012  M. Isidro (Cloud Sherpas)   Modified test coverage (Removed @isTest(seeAllData=true), added test data) 
09.10.2012  M. Isidro (Cloud Sherpas)   Added custom settings for Classifications (With LFY and No LFY)
15.10.2012  R. Enojas (Salesforce)      Added logic to purge OPCs as part of the deleteOPCList method
18.10.2012  R. Enojas (Salesforce)      Added logic to aggregate NRT adjustments for OPCs with multiple related schedules 
23.11.2012  R. Enojas (Salesforce)      Added step in CheckForException to update OPC with actual revenue when it's not the 1st of a multi-year scenario
30.04.2013  Haider Raza (Aus Post)      Commented the code to create the OPC Cases of type "Renewal Classification found for product but no Growth record exist"
10.09.2013  C.McIntyre (Salesforce)     OPC Validation Rebuild - removed legacy OPC validation code (primarily in checkforexception).
12.06.2014  A. Yeo (Aus Post)           Comment out to fix OPC flag issue, Case 91816, SFDC Case 10541274. Comment out code.
02/06/2020  shashwat.a.nath@accenture.com  Fix added to bypass the opportunity creation restriction in Classic and Restrict_Using_Path_Button_for_Closure
28/06/2022 KMcGuire			 Modified for including related account sales in OPC classification
**************************************************/
public class OPCUtility {

    public static void deleteOPCList(List<String> opcIdList) {
        system.debug('*** deleteOPCList: ' + opcIdList);
        
        List<Opp_Product_Classification__c> delOPCList = [SELECT Id FROM Opp_Product_Classification__c where Under_Review_by_Sales_Manager__c = false and Id in : opcIdList];
        if (!delOPCList.isEmpty()) {
            delete delOPCList;
            
            //Added to purge OPC records
            Database.emptyRecycleBin(delOPCList);
            
            delOPCList.clear();
        }
    }

   public static  Map<String,ParentAccountRevenue> createBARMap( Map<String,ParentAccountRevenue> idBARMap, List<String> acctIdList, List<String> prodIdList) {
            
        return getParentAccountRevenueMap(acctIdList,prodIdList);    
    }


    public static void createMapGrowthClassification(List<Revenue_Schedule__c> rsList, Map<String, String> renewalUpsellMap) {
        
        system.debug('*** createMapGrowthClassification: ' + rsList);
        // Create a Map for the Growth
        for (Revenue_Schedule__c rs : rsList) {
            if (rs.Classification_c__c == 'Growth') {                    /* Changed 'Up Sell' to 'Growth' */
                String uniqueId = rs.Opportunity__r.AccountId + ':'
                +   rs.Product__c + ':'
                +   rs.Contract_Start_Date__c+ ':'
                +   rs.Contract_End_Date__c;                
                if (!renewalUpsellMap.containsKey(uniqueId)) {
                    renewalUpsellMap.put(uniqueId, 'RENEWAL');
                }       
            }   
        }       
    }


    public static void createOPCMap(List<Revenue_Schedule__c> rsList, Map<String, Opp_Product_Classification__c> idOPCMap, Map<String, Revenue_Schedule__c> idRSMap, Map<String, String> renewalUpsellMap) {
        
        system.debug('*** createOPCMap: ' + rsList);
        // Create OPC Map: UniqueId = Customer:Product:Classification:FY
        for (Revenue_Schedule__c rs : rsList) {
            String uniqueId = rs.Opportunity__r.AccountId + ':'
            +   rs.Product__c + ':'
            +   rs.Classification_c__c + ':'
            +   rs.CalendarYear__c; 
            
            if (idOPCMap.containsKey(uniqueId)) {
                system.debug('***uniqueId: ' + uniqueId);
                system.debug('***idOPCMap: ' + idOPCMap);
                Opp_Product_Classification__c opc = new Opp_Product_Classification__c();
                opc = idOPCMap.get(uniqueId);   
                system.debug('***opc BEFORE: ' + opc);
                opc = addOPC(opc, rs, renewalUpsellMap);
                system.debug('***opc AFTER: ' + opc);
                idOPCMap.put(uniqueId, opc);
            } else {
                Opp_Product_Classification__c opc = new Opp_Product_Classification__c();
                idOPCMap.put(uniqueId, populateOPC(opc, rs, renewalUpsellMap));
            }   
            
            if (idRSMap.containsKey(uniqueId)) {
                Revenue_Schedule__c rs2 = new Revenue_Schedule__c();
                rs2 = idRSMap.get(uniqueId);  
                idRSMap.put(uniqueId, rs2);
            } else {
                idRSMap.put(uniqueId, rs);
            }    
            
            system.debug('***idRSMap: ' + idRSMap);           
        }       
    }
    
    
    public static void checkIfOPCExist(Map<String, Opp_Product_Classification__c> idOPCMap, Map<String, Opp_Product_Classification__c> idOPCExistingMap, List<Opp_Product_Classification__c> insertOPCList, List<Opp_Product_Classification__c> updateOPCList) {

        system.debug('***getHeapSize: Inside checkIfOPCExist Before query of OPC Existing TODAY: ' + Limits.getHeapSize());   
        system.debug('***idOPCExistingMap: ' + idOPCExistingMap.size());
        
        Set<String> sAccount = new Set<String>();
        Set<String> sProduct = new Set<String>();
        Set<String> sClass = new Set<String>();
        Set<String> sFY = new Set<String>();

        for (Opp_Product_Classification__c opcNew : idOPCMap.values()) {
            sAccount.add(opcNew.Account__c);
            sProduct.add(opcNew.Product__c);
            sClass.add(opcNew.Classification__c);
            sFY.add(opcNew.Financial_Year__c); 
        }
            
        system.debug('@@@sAccounts: ' + sAccount);
        system.debug('@@@sProduct: ' + sProduct);
        system.debug('@@@sClass: ' + sClass);
        system.debug('@@@sFY: ' + sFY);
                       
            
        for (Opp_Product_Classification__c opcExisting : 

            [Select Id, Account__c, Product__c, Classification__c, Financial_Year__c,
            Jan_Schedule_Amount__c, Feb_Schedule_Amount__c, Mar_Schedule_Amount__c, Apr_Schedule_Amount__c,
            May_Schedule_Amount__c, Jun_Schedule_Amount__c, Jul_Schedule_Amount__c, Aug_Schedule_Amount__c,
            Sep_Schedule_Amount__c, Oct_Schedule_Amount__c, Nov_Schedule_Amount__c, Dec_Schedule_Amount__c,
            
            //Additional fields as per CR 27
            Jan_NRT_Adjustment__c, Feb_NRT_Adjustment__c, Mar_NRT_Adjustment__c, Apr_NRT_Adjustment__c, 
            May_NRT_Adjustment__c, Jun_NRT_Adjustment__c, Jul_NRT_Adjustment__c, Aug_NRT_Adjustment__c,        
            Sep_NRT_Adjustment__c, Oct_NRT_Adjustment__c, Nov_NRT_Adjustment__c, Dec_NRT_Adjustment__c
                          
            From Opp_Product_Classification__c
            Where CreatedDate = today
            And Account__c in :sAccount
            And Product__c in :sProduct
            And Classification__c in :sClass
            And Financial_Year__c in :sFY]             
            
            ) {
                
            system.debug('@@@opcExisting: ' + opcExisting); 
                
            if (opcExisting != null) {
                String uniqueId = opcExisting.Account__c + ':'
                +   opcExisting.Product__c + ':'
                +   opcExisting.Classification__c + ':'
                +   opcExisting.Financial_Year__c; 
                
                if (!idOPCExistingMap.containsKey(uniqueId)) {
                    idOPCExistingMap.put(uniqueId, opcExisting);    
                }                   
            }   
        }    
        
        system.debug('***getHeapSize: Inside checkIfOPCExist After query of OPC Existing TODAY: ' + Limits.getHeapSize());   
        system.debug('***idOPCExistingMap: ' + idOPCExistingMap.size());
            

        // Compare New OPC Map and Existing OPC Map (idOPCMap - New OPC records)
        for (Opp_Product_Classification__c opcNew : idOPCMap.values()) {
            String uniqueId = opcNew.Account__c + ':'
            +   opcNew.Product__c + ':'
            +   opcNew.Classification__c + ':'
            +   opcNew.Financial_Year__c; 
            
            if (idOPCExistingMap.containsKey(uniqueId)) {
                Opp_Product_Classification__c opcExisting = idOPCExistingMap.get(uniqueId); 
                updateExistingOPC(opcExisting, opcNew);     
                updateOPCList.add(opcExisting);     
            } else {
                insertOPCList.add(opcNew);  
            }
        }  
        
                             
        system.debug('***getHeapSize: Before Update/Insert of OPC: ' + Limits.getHeapSize());    
        if (!updateOPCList.isEmpty()) {
            //update updateOPCList;
            Database.SaveResult[] SR = Database.update(updateOPCList, false);
            system.debug('***SR UPDATE: ' + SR);    
            
            SR.clear();
        }               
        
        if (!insertOPCList.isEmpty()) {
            //insert insertOPCList; 
            Database.SaveResult[] SR = Database.insert(insertOPCList, false);
            system.debug('***SR INSERT: ' + SR);    
            
            SR.clear();         
        }
        
        system.debug('***getHeapSize: After Update/Insert of OPC: ' + Limits.getHeapSize());    
        system.debug('***updateOPCList: ' + updateOPCList.size());
        system.debug('***insertOPCList: ' + insertOPCList.size());
    }
    
    
    public static Decimal checkAddends(Decimal arg1, Decimal arg2) {
        if (arg1 >= 0) {
            // arg1 is not null
            if (arg2 >= 0) {
                // arg2 not null
                return (arg1 + arg2);
            } else {
                // arg2 is null
                return arg1;
            }   
        } else {
            // arg1 is null
            if (arg2 >= 0) {
                // arg2 is not null
                return arg2;
            } else {
                // arg2 is null
                return null;
            }
        }   
    }   

    public static void updateExistingOPC(Opp_Product_Classification__c opcExisting, Opp_Product_Classification__c opcNew) {
      
        

        opcExisting.Jan_Schedule_Amount__c = checkAddends(opcExisting.Jan_Schedule_Amount__c, opcNew.Jan_Schedule_Amount__c);      
        opcExisting.Feb_Schedule_Amount__c = checkAddends(opcExisting.Feb_Schedule_Amount__c, opcNew.Feb_Schedule_Amount__c);      
        opcExisting.Mar_Schedule_Amount__c = checkAddends(opcExisting.Mar_Schedule_Amount__c, opcNew.Mar_Schedule_Amount__c);      
        opcExisting.Apr_Schedule_Amount__c = checkAddends(opcExisting.Apr_Schedule_Amount__c, opcNew.Apr_Schedule_Amount__c);      
        opcExisting.May_Schedule_Amount__c = checkAddends(opcExisting.May_Schedule_Amount__c, opcNew.May_Schedule_Amount__c);      
        opcExisting.Jun_Schedule_Amount__c = checkAddends(opcExisting.Jun_Schedule_Amount__c, opcNew.Jun_Schedule_Amount__c);      
        opcExisting.Jul_Schedule_Amount__c = checkAddends(opcExisting.Jul_Schedule_Amount__c, opcNew.Jul_Schedule_Amount__c);      
        opcExisting.Aug_Schedule_Amount__c = checkAddends(opcExisting.Aug_Schedule_Amount__c, opcNew.Aug_Schedule_Amount__c);      
        opcExisting.Sep_Schedule_Amount__c = checkAddends(opcExisting.Sep_Schedule_Amount__c, opcNew.Sep_Schedule_Amount__c);      
        opcExisting.Oct_Schedule_Amount__c = checkAddends(opcExisting.Oct_Schedule_Amount__c, opcNew.Oct_Schedule_Amount__c);      
        opcExisting.Nov_Schedule_Amount__c = checkAddends(opcExisting.Nov_Schedule_Amount__c, opcNew.Nov_Schedule_Amount__c);      
        opcExisting.Dec_Schedule_Amount__c = checkAddends(opcExisting.Dec_Schedule_Amount__c, opcNew.Dec_Schedule_Amount__c);
        
        //Additional fields as per CR 27
        opcExisting.Jan_NRT_Adjustment__c = checkAddends(opcExisting.Jan_NRT_Adjustment__c, opcNew.Jan_NRT_Adjustment__c);
        opcExisting.Feb_NRT_Adjustment__c = checkAddends(opcExisting.Feb_NRT_Adjustment__c, opcNew.Feb_NRT_Adjustment__c);
        opcExisting.Mar_NRT_Adjustment__c = checkAddends(opcExisting.Mar_NRT_Adjustment__c, opcNew.Mar_NRT_Adjustment__c);
        opcExisting.Apr_NRT_Adjustment__c = checkAddends(opcExisting.Apr_NRT_Adjustment__c, opcNew.Apr_NRT_Adjustment__c);
        opcExisting.May_NRT_Adjustment__c = checkAddends(opcExisting.May_NRT_Adjustment__c, opcNew.May_NRT_Adjustment__c);
        opcExisting.Jun_NRT_Adjustment__c = checkAddends(opcExisting.Jun_NRT_Adjustment__c, opcNew.Jun_NRT_Adjustment__c);
        opcExisting.Jul_NRT_Adjustment__c = checkAddends(opcExisting.Jul_NRT_Adjustment__c, opcNew.Jul_NRT_Adjustment__c);
        opcExisting.Aug_NRT_Adjustment__c = checkAddends(opcExisting.Aug_NRT_Adjustment__c, opcNew.Aug_NRT_Adjustment__c);
        opcExisting.Sep_NRT_Adjustment__c = checkAddends(opcExisting.Sep_NRT_Adjustment__c, opcNew.Sep_NRT_Adjustment__c);
        opcExisting.Oct_NRT_Adjustment__c = checkAddends(opcExisting.Oct_NRT_Adjustment__c, opcNew.Oct_NRT_Adjustment__c);
        opcExisting.Nov_NRT_Adjustment__c = checkAddends(opcExisting.Nov_NRT_Adjustment__c, opcNew.Nov_NRT_Adjustment__c);
        opcExisting.Dec_NRT_Adjustment__c = checkAddends(opcExisting.Dec_NRT_Adjustment__c, opcNew.Dec_NRT_Adjustment__c);
         
    }
    
/*  
    public static void createOPCRecords(Map<String, Opp_Product_Classification__c> idOPCMap, List<Opp_Product_Classification__c> opcList) {
        // Create OPC records
        for (Opp_Product_Classification__c opc : idOPCMap.values()) {
            opcList.add(opc);           
        }       
    }   
*/  
    public static Opp_Product_Classification__c addOPC(Opp_Product_Classification__c opc, Revenue_Schedule__c rs, Map<String, String> renewalUpsellMap) {
        system.debug('*** addOPC');
        system.debug('***opc: ' + opc);
        system.debug('***rs: ' + rs);

        opc.Account__c = rs.Opportunity__r.AccountId;   
        opc.Product__c = rs.Product__c; 
        opc.Classification__c = rs.Classification_c__c;
        opc.Financial_Year__c = rs.CalendarYear__c;
        opc.Opportunity__c = rs.Opportunity__c;
        
        if (rs.Hidden_1st_of_Multi_Year__c == 'YES') {
            opc.Hidden_1st_of_Multi_Year__c = true; 
        } else {
            opc.Hidden_1st_of_Multi_Year__c = false;
        }
        
      

        opc.Jan_Schedule_Amount__c = checkAddends(opc.Jan_Schedule_Amount__c, rs.Jan_Claimed_Revenue__c);      
        opc.Feb_Schedule_Amount__c = checkAddends(opc.Feb_Schedule_Amount__c, rs.Feb_Claimed_Revenue__c);      
        opc.Mar_Schedule_Amount__c = checkAddends(opc.Mar_Schedule_Amount__c, rs.Mar_Claimed_Revenue__c);      
        opc.Apr_Schedule_Amount__c = checkAddends(opc.Apr_Schedule_Amount__c, rs.Apr_Claimed_Revenue__c);      
        opc.May_Schedule_Amount__c = checkAddends(opc.May_Schedule_Amount__c, rs.May_Claimed_Revenue__c);      
        opc.Jun_Schedule_Amount__c = checkAddends(opc.Jun_Schedule_Amount__c, rs.Jun_Claimed_Revenue__c);      
        opc.Jul_Schedule_Amount__c = checkAddends(opc.Jul_Schedule_Amount__c, rs.Jul_Claimed_Revenue__c);      
        opc.Aug_Schedule_Amount__c = checkAddends(opc.Aug_Schedule_Amount__c, rs.Aug_Claimed_Revenue__c);      
        opc.Sep_Schedule_Amount__c = checkAddends(opc.Sep_Schedule_Amount__c, rs.Sep_Claimed_Revenue__c);      
        opc.Oct_Schedule_Amount__c = checkAddends(opc.Oct_Schedule_Amount__c, rs.Oct_Claimed_Revenue__c);      
        opc.Nov_Schedule_Amount__c = checkAddends(opc.Nov_Schedule_Amount__c, rs.Nov_Claimed_Revenue__c);      
        opc.Dec_Schedule_Amount__c = checkAddends(opc.Dec_Schedule_Amount__c, rs.Dec_Claimed_Revenue__c); 
        
        //Additional fields as per CR 27
        opc.Jan_NRT_Adjustment__c = checkAddends(opc.Jan_NRT_Adjustment__c, rs.Jan_NRT_Adjustment__c);        
        opc.Feb_NRT_Adjustment__c = checkAddends(opc.Feb_NRT_Adjustment__c, rs.Feb_NRT_Adjustment__c);        
        opc.Mar_NRT_Adjustment__c = checkAddends(opc.Mar_NRT_Adjustment__c, rs.Mar_NRT_Adjustment__c);        
        opc.Apr_NRT_Adjustment__c = checkAddends(opc.Apr_NRT_Adjustment__c, rs.Apr_NRT_Adjustment__c);        
        opc.May_NRT_Adjustment__c = checkAddends(opc.May_NRT_Adjustment__c, rs.May_NRT_Adjustment__c);        
        opc.Jun_NRT_Adjustment__c = checkAddends(opc.Jun_NRT_Adjustment__c, rs.Jun_NRT_Adjustment__c);        
        opc.Jul_NRT_Adjustment__c = checkAddends(opc.Jul_NRT_Adjustment__c, rs.Jul_NRT_Adjustment__c);        
        opc.Aug_NRT_Adjustment__c = checkAddends(opc.Aug_NRT_Adjustment__c, rs.Aug_NRT_Adjustment__c);        
        opc.Sep_NRT_Adjustment__c = checkAddends(opc.Sep_NRT_Adjustment__c, rs.Sep_NRT_Adjustment__c);        
        opc.Oct_NRT_Adjustment__c = checkAddends(opc.Oct_NRT_Adjustment__c, rs.Oct_NRT_Adjustment__c);       
        opc.Nov_NRT_Adjustment__c = checkAddends(opc.Nov_NRT_Adjustment__c, rs.Nov_NRT_Adjustment__c);        
        opc.Dec_NRT_Adjustment__c = checkAddends(opc.Dec_NRT_Adjustment__c, rs.Dec_NRT_Adjustment__c);
        
        return opc;
    }       
    
        
    public static Opp_Product_Classification__c populateOPC(Opp_Product_Classification__c opc, Revenue_Schedule__c rs, Map<String, String> renewalUpsellMap) {
        system.debug('*** populateOPC');
        system.debug('***opc: ' + opc);
        system.debug('***rs: ' + rs);
        system.debug('***rs Exception Override: ' + rs.Exception_Override__c);
        

        
        opc.Account__c = rs.Opportunity__r.AccountId;   
        opc.Product__c = rs.Product__c; 
        opc.Classification__c = rs.Classification_c__c;
        opc.Financial_Year__c = rs.CalendarYear__c;
        opc.Opportunity__c = rs.Opportunity__c;
        
        if (rs.Hidden_1st_of_Multi_Year__c == 'YES') {
            opc.Hidden_1st_of_Multi_Year__c = true; 
        } else {
            opc.Hidden_1st_of_Multi_Year__c = false;
        }        
     
        
        opc.Jan_Schedule_Amount__c = rs.Jan_Claimed_Revenue__c;        
        opc.Feb_Schedule_Amount__c = rs.Feb_Claimed_Revenue__c;        
        opc.Mar_Schedule_Amount__c = rs.Mar_Claimed_Revenue__c;        
        opc.Apr_Schedule_Amount__c = rs.Apr_Claimed_Revenue__c;        
        opc.May_Schedule_Amount__c = rs.May_Claimed_Revenue__c;        
        opc.Jun_Schedule_Amount__c = rs.Jun_Claimed_Revenue__c;        
        opc.Jul_Schedule_Amount__c = rs.Jul_Claimed_Revenue__c;        
        opc.Aug_Schedule_Amount__c = rs.Aug_Claimed_Revenue__c;        
        opc.Sep_Schedule_Amount__c = rs.Sep_Claimed_Revenue__c;        
        opc.Oct_Schedule_Amount__c = rs.Oct_Claimed_Revenue__c;       
        opc.Nov_Schedule_Amount__c = rs.Nov_Claimed_Revenue__c;        
        opc.Dec_Schedule_Amount__c = rs.Dec_Claimed_Revenue__c;  
        
        opc.Jan_NRT_Adjustment__c = rs.Jan_NRT_Adjustment__c;        
        opc.Feb_NRT_Adjustment__c = rs.Feb_NRT_Adjustment__c;        
        opc.Mar_NRT_Adjustment__c = rs.Mar_NRT_Adjustment__c;        
        opc.Apr_NRT_Adjustment__c = rs.Apr_NRT_Adjustment__c;        
        opc.May_NRT_Adjustment__c = rs.May_NRT_Adjustment__c;        
        opc.Jun_NRT_Adjustment__c = rs.Jun_NRT_Adjustment__c;        
        opc.Jul_NRT_Adjustment__c = rs.Jul_NRT_Adjustment__c;        
        opc.Aug_NRT_Adjustment__c = rs.Aug_NRT_Adjustment__c;        
        opc.Sep_NRT_Adjustment__c = rs.Sep_NRT_Adjustment__c;        
        opc.Oct_NRT_Adjustment__c = rs.Oct_NRT_Adjustment__c;       
        opc.Nov_NRT_Adjustment__c = rs.Nov_NRT_Adjustment__c;        
        opc.Dec_NRT_Adjustment__c = rs.Dec_NRT_Adjustment__c;          
        
        return opc;
    }  
    
  
    
    public static Boolean checkIfDateIsAfterToday(String strDate, String strToday) {
        if (strDate > strToday) {
            return true;
            //return false;         
        } else {
            return false;
        }   
    }
    
    
    public static Decimal checkGrowthValues(Decimal arg1, Decimal arg2) {
        if (arg1 >= 0) {
            // arg1 is not null
            if (arg2 >= 0) {
                // arg2 not null
                return (arg1 - arg2);
            } else {
                // arg2 is null
                return arg1;
            }   
        } else {
            // arg1 is null
            if (arg2 >= 0) {
                // arg2 is not null
                return null;
            } else {
                // arg2 is null
                return null;
            }
        }   
    }
    
    
    public static Opp_Product_Classification__c populateGrowthField(Opp_Product_Classification__c opc, Map<String, ParentAccountRevenue> idBARMap, Integer iCurrentFY, Integer iLastFY, Map<String, Revenue_Schedule__c> opcIdRSMap) {
        system.debug('*** populateGrowthField');
        system.debug('***opc: ' + opc);
        system.debug('***idBARMap: ' + idBARMap); 
        if (opc.Account__c == '001N0000003HBvSIAW') {
            system.debug('@@@SUZUKI !!!');
        }
        
        Date dateToday = Date.today();  
        Integer iTodayYear = dateToday.year();
        Integer iTodayMonth = dateToday.month();  
        String strTodayYear = String.valueOf(iTodayYear);
        String strTodayMonth = String.valueOf(iTodayMonth);
        if( strTodayMonth.length() < 2) {
            strTodayMonth = '0' + strTodayMonth;
        }
        String strTodayYearMonth = strTodayYear + strTodayMonth;        
        
        Revenue_Schedule__c rs = new Revenue_Schedule__c(); 
        rs = opcIdRSMap.get(opc.Id);
        Date conStart = rs.Contract_Start_Date__c;
        String conStartMonth;
        if( String.valueOf(conStart.month()).length() < 2) {
            conStartMonth = '0' + String.valueOf(conStart.month());
        } else {
            conStartMonth = String.valueOf(conStart.month());
        }
        String conStartYear = String.valueOf(conStart.year());
        
        Date conEnd = rs.Contract_End_Date__c;
        String conEndMonth;
        if( String.valueOf(conEnd.month()).length() < 2) {
            conEndMonth = '0' + String.valueOf(conEnd.month());
        } else {
            conEndMonth = String.valueOf(conEnd.month());
        }
        String conEndYear = String.valueOf(conEnd.year());
    
        String sYear = opc.Financial_Year__c;
        Integer nYear = Integer.valueOf(sYear);

        if ( idBARMap.containsKey(opc.Account__c + ':' + opc.Product__c + ':' + String.ValueOf(nYear)) ) {
            if ( idBARMap.containsKey(opc.Account__c + ':' + opc.Product__c + ':' + String.ValueOf(nYear - 1)) ) {
                ParentAccountRevenue barCurrent =  idBARMap.get(opc.Account__c + ':' + opc.Product__c + ':' + String.ValueOf(nYear)).ungroup();
                ParentAccountRevenue barLast = idBARMap.get(opc.Account__c + ':' + opc.Product__c + ':' + String.ValueOf(nYear - 1)).ungroup();
                
                system.debug('$$$ INSIDE GROWTH WITH CFY and LFY');
                system.debug('$$$barCurrent: ' + barCurrent);
                system.debug('$$$barLast: ' + barLast);
                
                system.debug('$$$ sYear: ' + sYear + ' and strTodayYearMonth: ' + strTodayYearMonth);
                system.debug('*** CONTRACT START: ' + conStartYear + conStartMonth);
                system.debug('*** CONTRACT END: ' + conEndYear + conEndMonth);
                
                if ( ( (conStartYear + conStartMonth) <= (sYear + '01') ) && ( (conEndYear + conEndMonth) >= (sYear + '01') ) ){
                    system.debug('JAN - within the contract');
                    if ( !checkIfDateIsAfterToday(sYear + '01', strTodayYearMonth) ) {
                        opc.Jan_Growth__c = checkGrowthValues(barCurrent.Jan_Revenue_Amount, barLast.Jan_Revenue_Amount);
                        system.debug('$$$INSIDE JAN');
                    }
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '02') ) && ( (conEndYear + conEndMonth) >= (sYear + '02') ) ){
                    system.debug('FEB - within the contract');
                    if ( !checkIfDateIsAfterToday(sYear + '02', strTodayYearMonth) ) {
                        //opc.Feb_Growth__c = checkAmount(barCurrent.Feb_Revenue_Amount__c) - checkAmount(barLast.Feb_Revenue_Amount__c); 
                        opc.Feb_Growth__c = checkGrowthValues(barCurrent.Feb_Revenue_Amount, barLast.Feb_Revenue_Amount);
                        system.debug('$$$INSIDE FEB');
                    }
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '03') ) && ( (conEndYear + conEndMonth) >= (sYear + '03') ) ){
                    system.debug('MAR - within the contract');
                    if ( !checkIfDateIsAfterToday(sYear + '03', strTodayYearMonth) ) {
                        //opc.Mar_Growth__c = checkAmount(barCurrent.Mar_Revenue_Amount__c) - checkAmount(barLast.Mar_Revenue_Amount__c); 
                        opc.Mar_Growth__c = checkGrowthValues(barCurrent.Mar_Revenue_Amount, barLast.Mar_Revenue_Amount);
                        system.debug('$$$INSIDE MAR');
                    }
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '04') ) && ( (conEndYear + conEndMonth) >= (sYear + '04') ) ){
                    system.debug('APR - within the contract');
                    if ( !checkIfDateIsAfterToday(sYear + '04', strTodayYearMonth) ) {
                        //opc.Apr_Growth__c = checkAmount(barCurrent.Apr_Revenue_Amount__c) - checkAmount(barLast.Apr_Revenue_Amount__c);
                        opc.Apr_Growth__c = checkGrowthValues(barCurrent.Apr_Revenue_Amount, barLast.Apr_Revenue_Amount); 
                        system.debug('$$$INSIDE APR');
                    }
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '05') ) && ( (conEndYear + conEndMonth) >= (sYear + '05') ) ){
                    system.debug('MAY - within the contract');
                    if ( !checkIfDateIsAfterToday(sYear + '05', strTodayYearMonth) ) {
                        //opc.May_Growth__c = checkAmount(barCurrent.May_Revenue_Amount__c) - checkAmount(barLast.May_Revenue_Amount__c); 
                        opc.May_Growth__c = checkGrowthValues(barCurrent.May_Revenue_Amount, barLast.May_Revenue_Amount);
                        system.debug('$$$INSIDE MAY');
                    }
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '06') ) && ( (conEndYear + conEndMonth) >= (sYear + '06') ) ){
                    system.debug('JUN - within the contract');
                    if ( !checkIfDateIsAfterToday(sYear + '06', strTodayYearMonth) ) {
                        //opc.Jun_Growth__c = checkAmount(barCurrent.Jun_Revenue_Amount__c) - checkAmount(barLast.Jun_Revenue_Amount__c); 
                        opc.Jun_Growth__c = checkGrowthValues(barCurrent.Jun_Revenue_Amount, barLast.Jun_Revenue_Amount);
                        system.debug('$$$INSIDE JUN');
                    }
                }   
                
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '07') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '07') ) ){
                    system.debug('JUL - within the contract');
                    if ( !checkIfDateIsAfterToday(String.valueof(nYear - 1) + '07', strTodayYearMonth) ) {
                        //opc.Jul_Growth__c = checkAmount(barCurrent.Jul_Revenue_Amount__c) - checkAmount(barLast.Jul_Revenue_Amount__c); 
                        opc.Jul_Growth__c = checkGrowthValues(barCurrent.Jul_Revenue_Amount, barLast.Jul_Revenue_Amount);
                        system.debug('$$$INSIDE JUL');                      
                    }
                }
                    
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '08') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '08') ) ){
                    system.debug('AUG - within the contract');
                    if ( !checkIfDateIsAfterToday(String.valueof(nYear - 1) + '08', strTodayYearMonth) ) {
                        //opc.Aug_Growth__c = checkAmount(barCurrent.Aug_Revenue_Amount__c) - checkAmount(barLast.Aug_Revenue_Amount__c); 
                        opc.Aug_Growth__c = checkGrowthValues(barCurrent.Aug_Revenue_Amount, barLast.Aug_Revenue_Amount);
                        system.debug('$$$INSIDE AUG');
                    }
                }
                                
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '09') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '09') ) ){
                    system.debug('SEP - within the contract');
                    if ( !checkIfDateIsAfterToday(String.valueof(nYear - 1) + '09', strTodayYearMonth) ) {
                        //opc.Sep_Growth__c = checkAmount(barCurrent.Sep_Revenue_Amount__c) - checkAmount(barLast.Sep_Revenue_Amount__c); 
                        opc.Sep_Growth__c = checkGrowthValues(barCurrent.Sep_Revenue_Amount, barLast.Sep_Revenue_Amount);
                        system.debug('$$$INSIDE SEP');                      
                    }
                }
                    
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '10') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '10') ) ){
                    system.debug('OCT - within the contract');
                    if ( !checkIfDateIsAfterToday(String.valueof(nYear - 1) + '10', strTodayYearMonth) ) {
                        //opc.Oct_Growth__c = checkAmount(barCurrent.Oct_Revenue_Amount__c) - checkAmount(barLast.Oct_Revenue_Amount__c);   
                        opc.Oct_Growth__c = checkGrowthValues(barCurrent.Oct_Revenue_Amount, barLast.Oct_Revenue_Amount);     
                        system.debug('$$$INSIDE OCT');
                    }
                }
                                
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '11') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '11') ) ){
                    system.debug('NOV - within the contract');
                    if ( !checkIfDateIsAfterToday(String.valueof(nYear - 1) + '11', strTodayYearMonth) ) {
                        //opc.Nov_Growth__c = checkAmount(barCurrent.Nov_Revenue_Amount__c) - checkAmount(barLast.Nov_Revenue_Amount__c); 
                        opc.Nov_Growth__c = checkGrowthValues(barCurrent.Nov_Revenue_Amount, barLast.Nov_Revenue_Amount);
                        system.debug('$$$INSIDE NOV');                      
                    }
                }
                    
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '12') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '12') ) ){
                    system.debug('DEC - within the contract');
                    if ( !checkIfDateIsAfterToday(String.valueof(nYear - 1) + '12', strTodayYearMonth) ) {
                        //opc.Dec_Growth__c = checkAmount(barCurrent.Dec_Revenue_Amount__c) - checkAmount(barLast.Dec_Revenue_Amount__c); 
                        opc.Dec_Growth__c = checkGrowthValues(barCurrent.Dec_Revenue_Amount, barLast.Dec_Revenue_Amount);
                        system.debug('$$$INSIDE DEC');                      
                    }
                }

                system.debug('$$$opc.Jan_Growth__c: ' + opc.Jan_Growth__c);
                system.debug('$$$opc.Feb_Growth__c: ' + opc.Feb_Growth__c);
                system.debug('$$$opc.Mar_Growth__c: ' + opc.Mar_Growth__c);
                
                system.debug('$$$opc.Apr_Growth__c: ' + opc.Apr_Growth__c);
                system.debug('$$$opc.May_Growth__c: ' + opc.May_Growth__c);
                system.debug('$$$opc.Jun_Growth__c: ' + opc.Jun_Growth__c);                

                system.debug('$$$opc.Jul_Growth__c: ' + opc.Jul_Growth__c);
                system.debug('$$$opc.Aug_Growth__c: ' + opc.Aug_Growth__c);
                system.debug('$$$opc.Sep_Growth__c: ' + opc.Sep_Growth__c);
                
                system.debug('$$$opc.Oct_Growth__c: ' + opc.Oct_Growth__c);
                system.debug('$$$opc.Nov_Growth__c: ' + opc.Nov_Growth__c);
                system.debug('$$$opc.Dec_Growth__c: ' + opc.Dec_Growth__c);                

            } else {
                ParentAccountRevenue barCurrent =  idBARMap.get(opc.Account__c + ':' + opc.Product__c + ':' + String.ValueOf(nYear)).ungroup();

                system.debug('$$$ INSIDE GROWTH WITH CFY only');
                system.debug('$$$barCurrent: ' + barCurrent);

                
                if ( ( (conStartYear + conStartMonth) <= (sYear + '01') ) && ( (conEndYear + conEndMonth) >= (sYear + '01') ) ){
                    opc.Jan_Growth__c = barCurrent.Jan_Revenue_Amount; 
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '02') ) && ( (conEndYear + conEndMonth) >= (sYear + '02') ) ){
                    opc.Feb_Growth__c = barCurrent.Feb_Revenue_Amount; 
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '03') ) && ( (conEndYear + conEndMonth) >= (sYear + '03') ) ){
                    opc.Mar_Growth__c = barCurrent.Mar_Revenue_Amount; 
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '04') ) && ( (conEndYear + conEndMonth) >= (sYear + '04') ) ){
                    opc.Apr_Growth__c = barCurrent.Apr_Revenue_Amount; 
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '05') ) && ( (conEndYear + conEndMonth) >= (sYear + '05') ) ){
                    opc.May_Growth__c = barCurrent.May_Revenue_Amount; 
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '06') ) && ( (conEndYear + conEndMonth) >= (sYear + '06') ) ){
                    opc.Jun_Growth__c = barCurrent.Jun_Revenue_Amount; 
                }   
                
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '07') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '07') ) ){ 
                    opc.Jul_Growth__c = barCurrent.Jul_Revenue_Amount; 
                }
                    
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '08') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '08') ) ){
                    opc.Aug_Growth__c = barCurrent.Aug_Revenue_Amount; 
                }
                                
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '09') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '09') ) ){
                    opc.Sep_Growth__c = barCurrent.Sep_Revenue_Amount; 
                }
                    
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '10') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '10') ) ){            
                    opc.Oct_Growth__c = barCurrent.Oct_Revenue_Amount;              
                }
                                
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '11') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '11') ) ){
                    opc.Nov_Growth__c = barCurrent.Nov_Revenue_Amount; 
                }
                    
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '12') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '12') ) ){
                    opc.Dec_Growth__c = barCurrent.Dec_Revenue_Amount; 
                }

            }
        }
        return opc;
    }
    // Added this method to calculate values for new group fields
     public static Opp_Product_Classification__c populateGroupGrowthField(Opp_Product_Classification__c opc, Map<String, ParentAccountRevenue> idBARMap, Integer iCurrentFY, Integer iLastFY, Map<String, Revenue_Schedule__c> opcIdRSMap) {
        system.debug('*** populateGrowthField');
        system.debug('***opc: ' + opc);
        system.debug('***idBARMap: ' + idBARMap); 
        if (opc.Account__c == '001N0000003HBvSIAW') {
            system.debug('@@@SUZUKI !!!');
        }
        
        Date dateToday = Date.today();  
        Integer iTodayYear = dateToday.year();
        Integer iTodayMonth = dateToday.month();  
        String strTodayYear = String.valueOf(iTodayYear);
        String strTodayMonth = String.valueOf(iTodayMonth);
        if( strTodayMonth.length() < 2) {
            strTodayMonth = '0' + strTodayMonth;
        }
        String strTodayYearMonth = strTodayYear + strTodayMonth;        
        
        Revenue_Schedule__c rs = new Revenue_Schedule__c(); 
        rs = opcIdRSMap.get(opc.Id);
        Date conStart = rs.Contract_Start_Date__c;
        String conStartMonth;
        if( String.valueOf(conStart.month()).length() < 2) {
            conStartMonth = '0' + String.valueOf(conStart.month());
        } else {
            conStartMonth = String.valueOf(conStart.month());
        }
        String conStartYear = String.valueOf(conStart.year());
        
        Date conEnd = rs.Contract_End_Date__c;
        String conEndMonth;
        if( String.valueOf(conEnd.month()).length() < 2) {
            conEndMonth = '0' + String.valueOf(conEnd.month());
        } else {
            conEndMonth = String.valueOf(conEnd.month());
        }
        String conEndYear = String.valueOf(conEnd.year());
    
        String sYear = opc.Financial_Year__c;
        Integer nYear = Integer.valueOf(sYear);

        if ( idBARMap.containsKey(opc.Account__c + ':' + opc.Product__c + ':' + String.ValueOf(nYear)) ) {
            if ( idBARMap.containsKey(opc.Account__c + ':' + opc.Product__c + ':' + String.ValueOf(nYear - 1)) ) {
                ParentAccountRevenue barCurrent =  idBARMap.get(opc.Account__c + ':' + opc.Product__c + ':' + String.ValueOf(nYear)).group();
                ParentAccountRevenue barLast = idBARMap.get(opc.Account__c + ':' + opc.Product__c + ':' + String.ValueOf(nYear - 1)).group();
                
                system.debug('$$$ INSIDE GROWTH WITH CFY and LFY');
                system.debug('$$$barCurrent: ' + barCurrent);
                system.debug('$$$barLast: ' + barLast);
                
                system.debug('$$$ sYear: ' + sYear + ' and strTodayYearMonth: ' + strTodayYearMonth);
                system.debug('*** CONTRACT START: ' + conStartYear + conStartMonth);
                system.debug('*** CONTRACT END: ' + conEndYear + conEndMonth);
                
                if ( ( (conStartYear + conStartMonth) <= (sYear + '01') ) && ( (conEndYear + conEndMonth) >= (sYear + '01') ) ){
                    system.debug('JAN - within the contract');
                    if ( !checkIfDateIsAfterToday(sYear + '01', strTodayYearMonth) ) {
                        opc.Jan_Group_Growth__c = checkGrowthValues(barCurrent.Jan_Revenue_Amount, barLast.Jan_Revenue_Amount);
                        system.debug('$$$INSIDE JAN');
                    }
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '02') ) && ( (conEndYear + conEndMonth) >= (sYear + '02') ) ){
                    system.debug('FEB - within the contract');
                    if ( !checkIfDateIsAfterToday(sYear + '02', strTodayYearMonth) ) {
                        //opc.Feb_Growth__c = checkAmount(barCurrent.Feb_Revenue_Amount__c) - checkAmount(barLast.Feb_Revenue_Amount__c); 
                        opc.Feb_Group_Growth__c = checkGrowthValues(barCurrent.Feb_Revenue_Amount, barLast.Feb_Revenue_Amount);
                        system.debug('$$$INSIDE FEB');
                    }
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '03') ) && ( (conEndYear + conEndMonth) >= (sYear + '03') ) ){
                    system.debug('MAR - within the contract');
                    if ( !checkIfDateIsAfterToday(sYear + '03', strTodayYearMonth) ) {
                        //opc.Mar_Growth__c = checkAmount(barCurrent.Mar_Revenue_Amount__c) - checkAmount(barLast.Mar_Revenue_Amount__c); 
                        opc.Mar_Group_Growth__c = checkGrowthValues(barCurrent.Mar_Revenue_Amount, barLast.Mar_Revenue_Amount);
                        system.debug('$$$INSIDE MAR');
                    }
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '04') ) && ( (conEndYear + conEndMonth) >= (sYear + '04') ) ){
                    system.debug('APR - within the contract');
                    if ( !checkIfDateIsAfterToday(sYear + '04', strTodayYearMonth) ) {
                        //opc.Apr_Growth__c = checkAmount(barCurrent.Apr_Revenue_Amount__c) - checkAmount(barLast.Apr_Revenue_Amount__c);
                        opc.Apr_Group_Growth__c = checkGrowthValues(barCurrent.Apr_Revenue_Amount, barLast.Apr_Revenue_Amount); 
                        system.debug('$$$INSIDE APR');
                    }
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '05') ) && ( (conEndYear + conEndMonth) >= (sYear + '05') ) ){
                    system.debug('MAY - within the contract');
                    if ( !checkIfDateIsAfterToday(sYear + '05', strTodayYearMonth) ) {
                        //opc.May_Growth__c = checkAmount(barCurrent.May_Revenue_Amount__c) - checkAmount(barLast.May_Revenue_Amount__c); 
                        opc.May_Group_Growth__c = checkGrowthValues(barCurrent.May_Revenue_Amount, barLast.May_Revenue_Amount);
                        system.debug('$$$INSIDE MAY');
                    }
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '06') ) && ( (conEndYear + conEndMonth) >= (sYear + '06') ) ){
                    system.debug('JUN - within the contract');
                    if ( !checkIfDateIsAfterToday(sYear + '06', strTodayYearMonth) ) {
                        //opc.Jun_Growth__c = checkAmount(barCurrent.Jun_Revenue_Amount__c) - checkAmount(barLast.Jun_Revenue_Amount__c); 
                        opc.Jun_Group_Growth__c = checkGrowthValues(barCurrent.Jun_Revenue_Amount, barLast.Jun_Revenue_Amount);
                        system.debug('$$$INSIDE JUN');
                    }
                }   
                
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '07') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '07') ) ){
                    system.debug('JUL - within the contract');
                    if ( !checkIfDateIsAfterToday(String.valueof(nYear - 1) + '07', strTodayYearMonth) ) {
                        //opc.Jul_Growth__c = checkAmount(barCurrent.Jul_Revenue_Amount__c) - checkAmount(barLast.Jul_Revenue_Amount__c); 
                        opc.Jul_Group_Growth__c = checkGrowthValues(barCurrent.Jul_Revenue_Amount, barLast.Jul_Revenue_Amount);
                        system.debug('$$$INSIDE JUL');                      
                    }
                }
                    
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '08') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '08') ) ){
                    system.debug('AUG - within the contract');
                    if ( !checkIfDateIsAfterToday(String.valueof(nYear - 1) + '08', strTodayYearMonth) ) {
                        //opc.Aug_Growth__c = checkAmount(barCurrent.Aug_Revenue_Amount__c) - checkAmount(barLast.Aug_Revenue_Amount__c); 
                        opc.Aug_Group_Growth__c = checkGrowthValues(barCurrent.Aug_Revenue_Amount, barLast.Aug_Revenue_Amount);
                        system.debug('$$$INSIDE AUG');
                    }
                }
                                
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '09') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '09') ) ){
                    system.debug('SEP - within the contract');
                    if ( !checkIfDateIsAfterToday(String.valueof(nYear - 1) + '09', strTodayYearMonth) ) {
                        //opc.Sep_Growth__c = checkAmount(barCurrent.Sep_Revenue_Amount__c) - checkAmount(barLast.Sep_Revenue_Amount__c); 
                        opc.Sep_Group_Growth__c = checkGrowthValues(barCurrent.Sep_Revenue_Amount, barLast.Sep_Revenue_Amount);
                        system.debug('$$$INSIDE SEP');                      
                    }
                }
                    
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '10') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '10') ) ){
                    system.debug('OCT - within the contract');
                    if ( !checkIfDateIsAfterToday(String.valueof(nYear - 1) + '10', strTodayYearMonth) ) {
                        //opc.Oct_Growth__c = checkAmount(barCurrent.Oct_Revenue_Amount__c) - checkAmount(barLast.Oct_Revenue_Amount__c);   
                        opc.Oct_Group_Growth__c = checkGrowthValues(barCurrent.Oct_Revenue_Amount, barLast.Oct_Revenue_Amount);     
                        system.debug('$$$INSIDE OCT');
                    }
                }
                                
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '11') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '11') ) ){
                    system.debug('NOV - within the contract');
                    if ( !checkIfDateIsAfterToday(String.valueof(nYear - 1) + '11', strTodayYearMonth) ) {
                        //opc.Nov_Growth__c = checkAmount(barCurrent.Nov_Revenue_Amount__c) - checkAmount(barLast.Nov_Revenue_Amount__c); 
                        opc.Nov_Group_Growth__c = checkGrowthValues(barCurrent.Nov_Revenue_Amount, barLast.Nov_Revenue_Amount);
                        system.debug('$$$INSIDE NOV');                      
                    }
                }
                    
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '12') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '12') ) ){
                    system.debug('DEC - within the contract');
                    if ( !checkIfDateIsAfterToday(String.valueof(nYear - 1) + '12', strTodayYearMonth) ) {
                        //opc.Dec_Growth__c = checkAmount(barCurrent.Dec_Revenue_Amount__c) - checkAmount(barLast.Dec_Revenue_Amount__c); 
                        opc.Dec_Group_Growth__c = checkGrowthValues(barCurrent.Dec_Revenue_Amount, barLast.Dec_Revenue_Amount);
                        system.debug('$$$INSIDE DEC');                      
                    }
                }

                system.debug('$$$opc.Jan_Growth__c: ' + opc.Jan_Growth__c);
                system.debug('$$$opc.Feb_Growth__c: ' + opc.Feb_Growth__c);
                system.debug('$$$opc.Mar_Growth__c: ' + opc.Mar_Growth__c);
                
                system.debug('$$$opc.Apr_Growth__c: ' + opc.Apr_Growth__c);
                system.debug('$$$opc.May_Growth__c: ' + opc.May_Growth__c);
                system.debug('$$$opc.Jun_Growth__c: ' + opc.Jun_Growth__c);                

                system.debug('$$$opc.Jul_Growth__c: ' + opc.Jul_Growth__c);
                system.debug('$$$opc.Aug_Growth__c: ' + opc.Aug_Growth__c);
                system.debug('$$$opc.Sep_Growth__c: ' + opc.Sep_Growth__c);
                
                system.debug('$$$opc.Oct_Growth__c: ' + opc.Oct_Growth__c);
                system.debug('$$$opc.Nov_Growth__c: ' + opc.Nov_Growth__c);
                system.debug('$$$opc.Dec_Growth__c: ' + opc.Dec_Growth__c);                

            } else {
                ParentAccountRevenue barCurrent =  idBARMap.get(opc.Account__c + ':' + opc.Product__c + ':' + String.ValueOf(nYear)).group();

                system.debug('$$$ INSIDE GROWTH WITH CFY only');
                system.debug('$$$barCurrent: ' + barCurrent);

                
                if ( ( (conStartYear + conStartMonth) <= (sYear + '01') ) && ( (conEndYear + conEndMonth) >= (sYear + '01') ) ){
                    opc.Jan_Group_Growth__c = barCurrent.Jan_Revenue_Amount; 
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '02') ) && ( (conEndYear + conEndMonth) >= (sYear + '02') ) ){
                    opc.Feb_Group_Growth__c = barCurrent.Feb_Revenue_Amount; 
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '03') ) && ( (conEndYear + conEndMonth) >= (sYear + '03') ) ){
                    opc.Mar_Group_Growth__c = barCurrent.Mar_Revenue_Amount; 
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '04') ) && ( (conEndYear + conEndMonth) >= (sYear + '04') ) ){
                    opc.Apr_Group_Growth__c = barCurrent.Apr_Revenue_Amount; 
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '05') ) && ( (conEndYear + conEndMonth) >= (sYear + '05') ) ){
                    opc.May_Group_Growth__c = barCurrent.May_Revenue_Amount; 
                }   

                if ( ( (conStartYear + conStartMonth) <= (sYear + '06') ) && ( (conEndYear + conEndMonth) >= (sYear + '06') ) ){
                    opc.Jun_Group_Growth__c = barCurrent.Jun_Revenue_Amount; 
                }   
                
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '07') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '07') ) ){ 
                    opc.Jul_Group_Growth__c = barCurrent.Jul_Revenue_Amount; 
                }
                    
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '08') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '08') ) ){
                    opc.Aug_Group_Growth__c = barCurrent.Aug_Revenue_Amount; 
                }
                                
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '09') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '09') ) ){
                    opc.Sep_Group_Growth__c = barCurrent.Sep_Revenue_Amount; 
                }
                    
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '10') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '10') ) ){            
                    opc.Oct_Group_Growth__c = barCurrent.Oct_Revenue_Amount;              
                }
                                
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '11') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '11') ) ){
                    opc.Nov_Group_Growth__c = barCurrent.Nov_Revenue_Amount; 
                }
                    
                if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '12') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '12') ) ){
                    opc.Dec_Group_Growth__c = barCurrent.Dec_Revenue_Amount; 
                }

            }
        }
        return opc;
    }
    
    public static Opp_Product_Classification__c populateActualAmounts(Opp_Product_Classification__c opc, Map<String, ParentAccountRevenue> idBARMap, Integer iCurrentFY, Map<String, Revenue_Schedule__c> opcIdRSMap) {
        system.debug('*** populateActualAmounts');
        system.debug('***opc: ' + opc);
        system.debug('***idBARMap: ' + idBARMap);
        system.debug('***opcIdRSMap: ' + opcIdRSMap);          

        Revenue_Schedule__c rs = new Revenue_Schedule__c(); 
        
        rs = opcIdRSMap.get(opc.Id);
        
        system.debug('***RS: ' + rs);
        
        Date conStart = rs.Contract_Start_Date__c;
        String conStartMonth;
        if( String.valueOf(conStart.month()).length() < 2) {
            conStartMonth = '0' + String.valueOf(conStart.month());
        } else {
            conStartMonth = String.valueOf(conStart.month());
        }
        String conStartYear = String.valueOf(conStart.year());
        
        Date conEnd = rs.Contract_End_Date__c;
        String conEndMonth;
        if( String.valueOf(conEnd.month()).length() < 2) {
            conEndMonth = '0' + String.valueOf(conEnd.month());
        } else {
            conEndMonth = String.valueOf(conEnd.month());
        }
        String conEndYear = String.valueOf(conEnd.year());
        
        system.debug('### ConStart: ' + conStart);
        system.debug('### ConStartMonth: ' + conStartMonth);
        system.debug('### ConEnd: ' + conEnd);
        system.debug('### ConEndMonth: ' + conEndMonth);
        system.debug('### ConEndYear: ' + conEndYear);

        String sYear = opc.Financial_Year__c;
        Integer nYear = Integer.valueOf(sYear);
                
        if (idBARMap.containsKey(opc.Account__c + ':' + opc.Product__c + ':' + String.ValueOf(nYear))) {
            ParentAccountRevenue bar = idBARMap.get(opc.Account__c + ':' + opc.Product__c + ':' + String.ValueOf(nYear)).ungroup();
            


            
            if ( ( (conStartYear + conStartMonth) <= (sYear + '01') ) && ( (conEndYear + conEndMonth) >= (sYear + '01') ) ){
                //opc.Jan_Actual_Amount__c = checkAmount(bar.Jan_Revenue_Amount__c);              
                opc.Jan_Actual_Amount__c = bar.Jan_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (sYear + '02') ) && ( (conEndYear + conEndMonth) >= (sYear + '02') ) ){
                //opc.Feb_Actual_Amount__c = checkAmount(bar.Feb_Revenue_Amount__c);              
                opc.Feb_Actual_Amount__c = bar.Feb_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (sYear + '03') ) && ( (conEndYear + conEndMonth) >= (sYear + '03') ) ){
                //opc.Mar_Actual_Amount__c = checkAmount(bar.Mar_Revenue_Amount__c);              
                opc.Mar_Actual_Amount__c = bar.Mar_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (sYear + '04') ) && ( (conEndYear + conEndMonth) >= (sYear + '04') ) ){
                //opc.Apr_Actual_Amount__c = checkAmount(bar.Apr_Revenue_Amount__c);              
                opc.Apr_Actual_Amount__c = bar.Apr_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (sYear + '05') ) && ( (conEndYear + conEndMonth) >= (sYear + '05') ) ){
                //opc.May_Actual_Amount__c = checkAmount(bar.May_Revenue_Amount__c);              
                opc.May_Actual_Amount__c = bar.May_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (sYear + '06') ) && ( (conEndYear + conEndMonth) >= (sYear + '06') ) ){
                //opc.Jun_Actual_Amount__c = checkAmount(bar.Jun_Revenue_Amount__c);              
                opc.Jun_Actual_Amount__c = bar.Jun_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '07') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '07') ) ){
                //opc.Jul_Actual_Amount__c = checkAmount(bar.Jul_Revenue_Amount__c);              
                opc.Jul_Actual_Amount__c = bar.Jul_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '08') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '08') ) ){
                //opc.Aug_Actual_Amount__c = checkAmount(bar.Aug_Revenue_Amount__c);              
                opc.Aug_Actual_Amount__c = bar.Aug_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '09') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '09') ) ){
                //opc.Sep_Actual_Amount__c = checkAmount(bar.Sep_Revenue_Amount__c);              
                opc.Sep_Actual_Amount__c = bar.Sep_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '10') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '10') ) ){
                //opc.Oct_Actual_Amount__c = checkAmount(bar.Oct_Revenue_Amount__c);              
                opc.Oct_Actual_Amount__c = bar.Oct_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '11') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '11') ) ){
                //opc.Nov_Actual_Amount__c = checkAmount(bar.Nov_Revenue_Amount__c);              
                opc.Nov_Actual_Amount__c = bar.Nov_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '12') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '12') ) ){
                //opc.Dec_Actual_Amount__c = checkAmount(bar.Dec_Revenue_Amount__c);              
                opc.Dec_Actual_Amount__c = bar.Dec_Revenue_Amount;              
            }

        }
        return opc;
    }
    
     public static Opp_Product_Classification__c populateGroupActualAmounts(Opp_Product_Classification__c opc, Map<String, ParentAccountRevenue> idBARMap, Integer iCurrentFY, Map<String, Revenue_Schedule__c> opcIdRSMap) {
        system.debug('*** populateActualAmounts');
        system.debug('***opc: ' + opc);
        system.debug('***idBARMap: ' + idBARMap);
        system.debug('***opcIdRSMap: ' + opcIdRSMap);          

        Revenue_Schedule__c rs = new Revenue_Schedule__c(); 
        
        rs = opcIdRSMap.get(opc.Id);
        
        system.debug('***RS: ' + rs);
        
        Date conStart = rs.Contract_Start_Date__c;
        String conStartMonth;
        if( String.valueOf(conStart.month()).length() < 2) {
            conStartMonth = '0' + String.valueOf(conStart.month());
        } else {
            conStartMonth = String.valueOf(conStart.month());
        }
        String conStartYear = String.valueOf(conStart.year());
        
        Date conEnd = rs.Contract_End_Date__c;
        String conEndMonth;
        if( String.valueOf(conEnd.month()).length() < 2) {
            conEndMonth = '0' + String.valueOf(conEnd.month());
        } else {
            conEndMonth = String.valueOf(conEnd.month());
        }
        String conEndYear = String.valueOf(conEnd.year());
        
        system.debug('### ConStart: ' + conStart);
        system.debug('### ConStartMonth: ' + conStartMonth);
        system.debug('### ConEnd: ' + conEnd);
        system.debug('### ConEndMonth: ' + conEndMonth);
        system.debug('### ConEndYear: ' + conEndYear);

        String sYear = opc.Financial_Year__c;
        Integer nYear = Integer.valueOf(sYear);
                
        if (idBARMap.containsKey(opc.Account__c + ':' + opc.Product__c + ':' + String.ValueOf(nYear))) {
            ParentAccountRevenue bar = idBARMap.get(opc.Account__c + ':' + opc.Product__c + ':' + String.ValueOf(nYear)).group();
            


            
            if ( ( (conStartYear + conStartMonth) <= (sYear + '01') ) && ( (conEndYear + conEndMonth) >= (sYear + '01') ) ){
                //opc.Jan_Actual_Amount__c = checkAmount(bar.Jan_Revenue_Amount__c);              
                opc.Jan_Group_Actual_Amount__c = bar.Jan_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (sYear + '02') ) && ( (conEndYear + conEndMonth) >= (sYear + '02') ) ){
                //opc.Feb_Actual_Amount__c = checkAmount(bar.Feb_Revenue_Amount__c);              
                opc.Feb_Group_Actual_Amount__c = bar.Feb_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (sYear + '03') ) && ( (conEndYear + conEndMonth) >= (sYear + '03') ) ){
                //opc.Mar_Actual_Amount__c = checkAmount(bar.Mar_Revenue_Amount__c);              
                opc.Mar_Group_Actual_Amount__c = bar.Mar_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (sYear + '04') ) && ( (conEndYear + conEndMonth) >= (sYear + '04') ) ){
                //opc.Apr_Actual_Amount__c = checkAmount(bar.Apr_Revenue_Amount__c);              
                opc.Apr_Group_Actual_Amount__c = bar.Apr_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (sYear + '05') ) && ( (conEndYear + conEndMonth) >= (sYear + '05') ) ){
                //opc.May_Actual_Amount__c = checkAmount(bar.May_Revenue_Amount__c);              
                opc.May_Group_Actual_Amount__c = bar.May_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (sYear + '06') ) && ( (conEndYear + conEndMonth) >= (sYear + '06') ) ){
                //opc.Jun_Actual_Amount__c = checkAmount(bar.Jun_Revenue_Amount__c);              
                opc.Jun_Group_Actual_Amount__c = bar.Jun_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '07') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '07') ) ){
                //opc.Jul_Actual_Amount__c = checkAmount(bar.Jul_Revenue_Amount__c);              
                opc.Jul_Group_Actual_Amount__c = bar.Jul_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '08') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '08') ) ){
                //opc.Aug_Actual_Amount__c = checkAmount(bar.Aug_Revenue_Amount__c);              
                opc.Aug_Group_Actual_Amount__c = bar.Aug_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '09') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '09') ) ){
                //opc.Sep_Actual_Amount__c = checkAmount(bar.Sep_Revenue_Amount__c);              
                opc.Sep_Group_Actual_Amount__c = bar.Sep_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '10') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '10') ) ){
                //opc.Oct_Actual_Amount__c = checkAmount(bar.Oct_Revenue_Amount__c);              
                opc.Oct_Group_Actual_Amount__c = bar.Oct_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '11') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '11') ) ){
                //opc.Nov_Actual_Amount__c = checkAmount(bar.Nov_Revenue_Amount__c);              
                opc.Nov_Group_Actual_Amount__c = bar.Nov_Revenue_Amount;              
            }

            if ( ( (conStartYear + conStartMonth) <= (String.valueof(nYear - 1) + '12') ) && ( (conEndYear + conEndMonth) >= (String.valueof(nYear - 1) + '12') ) ){
                //opc.Dec_Actual_Amount__c = checkAmount(bar.Dec_Revenue_Amount__c);              
                opc.Dec_Group_Actual_Amount__c = bar.Dec_Revenue_Amount;              
            }

        }
        return opc;
    }
    
    public static void relateRevenueScheduleToOPC(List<Opp_Product_Classification__c> opcList, List<Revenue_Schedule__c> rsList, Map<String, Id> uniqueIdopcIdMap, Map<String, Revenue_Schedule__c> opcIdRSMap) {
        // Update Revenue Schedule records with the associated OPC 
        List<String> opcIdList = new List<String>();
        for (Opp_Product_Classification__c opc : opcList) {
            opcIdList.add(opc.Id);
            uniqueIdopcIdMap.put(opc.Account__c + ':' + opc.Product__c + ':' + opc.Classification__c + ':' + opc.Financial_Year__c, opc.Id);        
        }
        
        system.debug('***getHeapSize: Before query of OPC inserted:' + Limits.getHeapSize());   
        // Query OPC records to include related fields
        if (!opcIdList.isEmpty()) {
            opcList = [Select Id, Product__r.Name, Product__r.Id, Opportunity__r.OwnerId, Opportunity__r.Id, Opportunity__c, Account__r.Name, Account__r.Id, 
                Account__c, Product__c, Classification__c, Financial_Year__c, Hidden_Under_Review__c, Hidden_1st_of_Multi_Year__c, Hidden_Renewal_Missing_Growth__c,
                Jan_Growth__c, Feb_Growth__c, Mar_Growth__c, Apr_Growth__c,
                May_Growth__c, Jun_Growth__c, Jul_Growth__c, Aug_Growth__c,
                Sep_Growth__c, Oct_Growth__c, Nov_Growth__c, Dec_Growth__c,
                
                Jan_Actual_Amount__c, Feb_Actual_Amount__c, Mar_Actual_Amount__c, Apr_Actual_Amount__c,
                May_Actual_Amount__c, Jun_Actual_Amount__c, Jul_Actual_Amount__c, Aug_Actual_Amount__c,
                Sep_Actual_Amount__c, Oct_Actual_Amount__c, Nov_Actual_Amount__c, Dec_Actual_Amount__c,
                
                Jan_Schedule_Amount__c, Feb_Schedule_Amount__c, Mar_Schedule_Amount__c, Apr_Schedule_Amount__c,
                May_Schedule_Amount__c, Jun_Schedule_Amount__c, Jul_Schedule_Amount__c, Aug_Schedule_Amount__c,
                Sep_Schedule_Amount__c, Oct_Schedule_Amount__c, Nov_Schedule_Amount__c, Dec_Schedule_Amount__c              
                
                From Opp_Product_Classification__c
                Where Id in :opcIdList];    
        }
        system.debug('***getHeapSize: After query of OPC inserted:' + Limits.getHeapSize());
        
        // Update Revenue Schedule records with the corresponding OPC Ids for reference
        for (Revenue_Schedule__c rs : rsList) {
            String uniqueId = rs.Opportunity__r.AccountId + ':'
            +   rs.Product__c + ':'
            +   rs.Classification_c__c + ':'
            +   rs.CalendarYear__c; 
            
            system.debug('@@@uniqueId: ' + uniqueId);
            
            if (uniqueIdopcIdMap.containsKey(uniqueId)) {
                rs.Opportunity_Product_Classification__c = uniqueIdopcIdMap.get(uniqueId);
            }   
        }
        
        system.debug('***getHeapSize: Before updating rsList:' + Limits.getHeapSize());
        if (!rsList.isEmpty()) {
            //update rsList;
            Database.SaveResult[] SR = Database.update(rsList, false);
            system.debug('***SR: ' + SR);    
            
            SR.clear();           
            
            
            // Create OPC Id to Revenue Schedule Map to get Contract Start and End Date
            for (Revenue_Schedule__c rs : rsList) {
                if (rs.Opportunity_Product_Classification__c != null) {
                    if (!opcIdRSMap.containsKey(rs.Opportunity_Product_Classification__c)) {
                        opcIdRSMap.put(rs.Opportunity_Product_Classification__c, rs);   
                    } 
                }
                system.debug('@@@opcIdRSMap: ' + opcIdRSMap);
            }
            system.debug('@@@opcIdRSMap Size: ' + opcIdRSMap.size());
            system.debug('***getHeapSize: After mapping opcIdRSMap:' + Limits.getHeapSize());
        } 
               
        
    }
    
    
    public static Boolean checkIfMultiYear(Opp_Product_Classification__c opc, List<Revenue_Schedule__c> rsList) {
        for (Revenue_Schedule__c rs : rsList) {
            if (rs.Opportunity_Product_Classification__c == opc.Id) {
                if (rs.Multi_Year__c == 'YES') {
                    return true;
                }   
            }
        }       
        return false;
    }
    
    
    public static Boolean checkIfExceptionOverride(Opp_Product_Classification__c opc, List<Revenue_Schedule__c> rsList) {
        for (Revenue_Schedule__c rs : rsList) {
            if (rs.Opportunity_Product_Classification__c == opc.Id) {
                if (rs.Exception_Override__c) {
                    return true;
                }   
            }
        }       
        return false;       
    }


    public static String getWithLFYClassifications() {
        String sWithLFY = BatchJobSettings__c.getInstance().With_LFY__c;    
        return (sWithLFY);  
    }
    
    
    public static String getNoLFYClassifications() {
        String sNoLFY = BatchJobSettings__c.getInstance().No_LFY__c;    
        return (sNoLFY);    
    }   


    public static void checkForException(List<Opp_Product_Classification__c> opcList, Map<String, ParentAccountRevenue> idBARMap, Map<String, Revenue_Schedule__c> opcIdRSMap, List<Case> caseList, String rtId, List<Revenue_Schedule__c> rsList) {
        // Check for Exceptions
        /* CMcIntyre 10/09/13 - Function modified as part of OPC Validation Rebuild.  
           This function will no longer generates cases or set the review flag on the OPC Records.  This is now performed by a separate
           batch OPCValidationService_Batchable.
           This function originally contained code to calculate OPC amounts and growth - this has been left untouched to
           reduce the need for broad re-testing.  */
        
        system.debug('!!!opcList: ' + opcList);
        system.debug('!!!rsList: ' + rsList);
        
        for (Opp_Product_Classification__c opc : opcList) {
            
            String sYear = opc.Financial_Year__c;
            Integer nYear = Integer.valueOf(sYear);   
            String sWithLFYClassifications = getWithLFYClassifications();   
            String sNoLFYClassifications = getNoLFYClassifications();   
            system.debug('***sNoLFYClassifications: ' + sNoLFYClassifications);   

            //if (opc.Classification__c == 'New Customer' || opc.Classification__c == 'One Off' || opc.Classification__c == 'Cross Sell' || opc.Classification__c == 'Winback') {         /*** Changed from 'New Product' to 'Cross Sell' ***/
            if (sNoLFYClassifications.contains(opc.Classification__c)) {    
                // Is there Billed Revenue for this customer in the LFY?
                // Org:Prod:FY
                system.debug('***sClassifications: ' + sNoLFYClassifications + ' contains  opc.Classification__c: ' + opc.Classification__c);
                if (idBARMap.containsKey(opc.Account__c + ':' + opc.Product__c + ':' + String.valueOf(nYear - 1))) {
                    
                    //if ( (opc.Classification__c == 'New Customer' || opc.Classification__c == 'One Off' || opc.Classification__c == 'Cross Sell' || opc.Classification__c == 'Winback') ) {
                    if (sNoLFYClassifications.contains(opc.Classification__c)) {                                
                        if( checkIfMultiYear(opc, rsList) ) {
                            if (opc.Hidden_1st_of_Multi_Year__c) {
                                // Do nothing.
                            }
                            else {
                                //Multi-Year scenario, but not the first therefore valid OPC
                                system.debug('NOT the 1st of Multi-Year!!!');
                                opc = populateActualAmounts(opc, idBARMap, nYear, opcIdRSMap);
                                opc = populateGroupActualAmounts(opc, idBARMap, nYear, opcIdRSMap);
                            }
                        } 
                    }
                } 
                else {
                    // Populate Actual Amount from Billed 
                    opc = populateActualAmounts(opc, idBARMap, nYear, opcIdRSMap);
                    opc = populateGroupActualAmounts(opc, idBARMap, nYear, opcIdRSMap);
                }
                
                // Populate Growth Field for all classifications except Renewal
                opc = populateGrowthField(opc, idBARMap, nYear, nYear - 1, opcIdRSMap);
                opc = populateGroupGrowthField(opc, idBARMap, nYear, nYear - 1, opcIdRSMap);
                
            } 
            else if (sWithLFYClassifications.contains(opc.Classification__c)) {               
                // Is there Billed Revenue for this product? 
                if (idBARMap.containsKey(opc.Account__c + ':' + opc.Product__c + ':' + String.valueOf(nYear - 1))) {
                    // Populate Actual Amount from Billed 
                    opc = populateActualAmounts(opc, idBARMap, nYear, opcIdRSMap);
                } 
            } 
            else if (opc.Classification__c == 'Growth') {          /*** Changed from 'Up Sell' to 'Growth' ***/
                // Find record that is the same product AND “Existing Customer (Renewal)” or “Existing Customer (New Product)” or “New Customer” revenue schedule classification exists for the customer
                if (idBARMap.containsKey(opc.Account__c + ':' + opc.Product__c + ':' + String.valueOf(nYear - 1))) {
                    opc = populateGrowthField(opc, idBARMap, nYear, nYear - 1, opcIdRSMap);
                } 
            }
        }
        //update opcList;
        Database.SaveResult[] SR = Database.update(opcList, false);
        system.debug('***SR: ' + SR);        
    }  
    
    
    public static List<Opp_Product_Classification__c> requeryOPCList(List<Opp_Product_Classification__c> opcList, List<Opp_Product_Classification__c> requeryOPCList) {
        system.debug('@@@opcList: ' + opcList);
        system.debug('@@@requeryOPCList: ' + requeryOPCList);
        
        List<String> opcIds = new List<String>();
        if (!opcList.isEmpty()) {
            for (Opp_Product_Classification__c opc : opcList) {
                
                system.debug('@@@opcList is not EMPTY:');
                
                opcIds.add(opc.Id);
            }
            
            system.debug('@@@opcList Size : ' + opcList.size());
            system.debug('***getHeapSize: Before requeryOPCList: ' + Limits.getHeapSize()); 
            
            requeryOPCList = [Select Id, Product__r.Name, Product__r.Id, Opportunity__r.OwnerId, Opportunity__r.Id, Opportunity__c, Account__r.Name, Account__r.Id, 
                Account__c, Product__c, Classification__c, Financial_Year__c, Hidden_Under_Review__c, Hidden_1st_of_Multi_Year__c, Hidden_Renewal_Missing_Growth__c,
                Jan_Growth__c, Feb_Growth__c, Mar_Growth__c, Apr_Growth__c,
                May_Growth__c, Jun_Growth__c, Jul_Growth__c, Aug_Growth__c,
                Sep_Growth__c, Oct_Growth__c, Nov_Growth__c, Dec_Growth__c,
                
                Jan_Actual_Amount__c, Feb_Actual_Amount__c, Mar_Actual_Amount__c, Apr_Actual_Amount__c,
                May_Actual_Amount__c, Jun_Actual_Amount__c, Jul_Actual_Amount__c, Aug_Actual_Amount__c,
                Sep_Actual_Amount__c, Oct_Actual_Amount__c, Nov_Actual_Amount__c, Dec_Actual_Amount__c,
                
                Jan_Schedule_Amount__c, Feb_Schedule_Amount__c, Mar_Schedule_Amount__c, Apr_Schedule_Amount__c,
                May_Schedule_Amount__c, Jun_Schedule_Amount__c, Jul_Schedule_Amount__c, Aug_Schedule_Amount__c,
                Sep_Schedule_Amount__c, Oct_Schedule_Amount__c, Nov_Schedule_Amount__c, Dec_Schedule_Amount__c              
                
                From Opp_Product_Classification__c
                Where Id in :opcIds]; 
                
            system.debug('***getHeapSize: After requeryOPCList: ' + Limits.getHeapSize());      
            system.debug('***requeryOPCList Size: ' + requeryOPCList.size());               
                
            return requeryOPCList;                          
        } else {
            return null;
        }   
    }    
   
   
    @isTest(seeAllData=false)
    private static void testOPCUtility() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Team'];
        User u = new User(Alias = 'x', Email='x@x.com', ProfileId = p.Id,
                        EmailEncodingKey='UTF-8', FirstName='Holding', LastName='User', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', isActive = true,
                        TimeZoneSidKey='America/Los_Angeles', UserName='x356@x.com');
        insert u;
        
        // Query your permission set name from Organization to bypass the validation.
        List<PermissionSet>  psList = new List<PermissionSet>();
        psList = [SELECT Id FROM PermissionSet WHERE Name = 'ValidationRuleBypassClassicRestrictions' LIMIT 1];
       
        // Assign the above inserted user for the above Permission Set.
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = u.Id;
        psa.PermissionSetId = psList[0].id;
        insert psa;
        
       
        
        system.runAs(u) {
            RecordType orgrectype = [SELECT Id 
                                    FROM RecordType 
                                    WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
                                    
        BatchJobSettings__c batchSetting = new BatchJobSettings__c(SetupOwnerId=UserInfo.getOrganizationId());
        batchSetting.No_LFY__c = 'New Business,New Business - One Off,Cross Sell,Win Back';
        Database.insert(batchSetting);                       
            
            //create account
            Account bacct = new Account(
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
            insert bacct;   
            
            Organisation_Role__c orgRole = [SELECT Id, Role_Type__c FROM Organisation_Role__c WHERE Organisation__c =: bacct.Id limit 1];
            orgRole.Role_Type__c='Customer';        
            update OrgRole; 
            
            //create account
            Opportunity oppty = new Opportunity(
                name='Opportunity', 
                StageName = 'Identify',
                Contract_Number__c='CN12345', 
                Probability = 3,
                closedate = date.today(),
                Closed_Reason__c='Reason',
                Contract_Start_Date__c=date.today() - 100,
                Contract_End_Date__c=date.today() + 100,
                Type='New Customer',
                accountid=bacct.id
            );
            // 10/23/19: Closed Won Governance requirements
            // Pre-Entry scenario
            oppty.Pre_Entry__c = true;
            // For Opportunity Products that require Contracts
            oppty.Offline_Contract_Received__c = true;
            // Data Integrity Compliance
            oppty.Data_Integrity_Compliance__c = true;
            insert oppty;
            
            Opportunity oppty2 = new Opportunity(
                name='Opportunity', 
                StageName = 'Identify',
                Contract_Number__c='CN12345', 
                closedate = date.today(),
                Probability = 3,
                Closed_Reason__c='Reason',
                Contract_Start_Date__c=date.today() - 500,
                Contract_End_Date__c=date.today() + 500,
                Type='Existing Customer',
                accountid=bacct.id
            );
            // 10/23/19: Closed Won Governance requirements
            // Pre-Entry scenario
            oppty2.Pre_Entry__c = true;
            // For Opportunity Products that require Contracts
            oppty2.Offline_Contract_Received__c = true;
            // Data Integrity Compliance
            oppty2.Data_Integrity_Compliance__c = true;
            insert oppty2;        
            
            String code = 'TEST';
            Integer nCount = 2;
            
            /** Nandan : Get PriceBook Id **/
            // Get standard price book ID.
            Id pricebookId = Test.getStandardPricebookId();
            /** Ends **/
           
            //Pricebook2 pb = [select id from Pricebook2 where IsStandard = true];
            
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
                    Pricebook2Id = pricebookId,
                    Product2Id = prodList[i].Id, 
                    IsActive = true,
                    UnitPrice = 1000,
                    UseStandardPrice=false
                );
                pbeList.add(pbe);
            }
            insert pbeList;
          
            List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
            List<OpportunityLineItem> oliList2 = new List<OpportunityLineItem>();
            List<String> strList = new List<String>{'New Business', 'New Business - One Off', 'Win Back', 'Cross Sell'};
            List<String> strList2 = new List<String>{'Growth', 'Renewal'};
            for(integer i = 0; i < nCount; i++) {
                OpportunityLineItem oli = new OpportunityLineItem(
                    OpportunityId = oppty.id,
                    Classification__c = strList[Math.mod(i, 4)],
                    PriceBookEntryId = pbeList[Math.mod(i, 2)].Id,
                    Quantity = 100,
                    TotalPrice = 1000,
                    Contract_Start_Date__c=date.today() - 100,
                    Contract_End_Date__c=date.today() + 100,
                    Contract_Number__c='99999'
                );
                oliList.add(oli);
                
                OpportunityLineItem oli3 = new OpportunityLineItem(
                    OpportunityId = oppty.id,
                    Classification__c = strList[Math.mod(i, 4)],
                    PriceBookEntryId = pbeList[Math.mod(i, 2)].Id,
                    Quantity = 100,
                    TotalPrice = 1000,
                    Contract_Start_Date__c=date.today() - 150,
                    Contract_End_Date__c=date.today() + 150,
                    Contract_Number__c='99999'
                );
                oliList.add(oli3);            
                
                OpportunityLineItem oli2 = new OpportunityLineItem(
                    OpportunityId = oppty2.id,
                    Classification__c = strList2[Math.mod(i, 2)],
                    Sub_Classification__c = 'Up Sell',
                    PriceBookEntryId = pbeList[Math.mod(i, 2)].Id,
                    Quantity = 100,
                    TotalPrice = 1000,
                    Contract_Start_Date__c=date.today() - 300,
                    Contract_End_Date__c=date.today() + 300,
                    Contract_Number__c='99999'
                );
                oliList2.add(oli2); 
                
                OpportunityLineItem oli4 = new OpportunityLineItem(
                    OpportunityId = oppty2.id,
                    Classification__c = strList2[Math.mod(i, 2)],
                    Sub_Classification__c = 'Up Sell',
                    PriceBookEntryId = pbeList[Math.mod(i, 2)].Id,
                    Quantity = 100,
                    TotalPrice = 1000,
                    Contract_Start_Date__c=date.today() - 500,
                    Contract_End_Date__c=date.today() + 500,
                    Contract_Number__c='99999'
                );
                oliList2.add(oli4);       
            }
            insert oliList;    
            insert oliList2;     
            
            oppty.StageName = 'Closed Won';    
            oppty.Probability = 100;  
            oppty.Hidden_Restrict_Path_Closure__c  = true;  
            oppty2.StageName = 'Closed Won';
            oppty2.Probability = 100;
            oppty2.Hidden_Restrict_Path_Closure__c  = true; 
            
            update oppty;
            update oppty2;
            
            List<String> oliIds = new List<String>();
            for (OpportunityLineItem oli : oliList) {
                oliIds.add(oli.Id); 
            }
            
            List<Revenue_Schedule__c> rsList = [select id, Exception_Override__c from Revenue_Schedule__c where OpportunityLineItem__c in: oliIds]; 
            for (Revenue_Schedule__c rs : rsList) {
                rs.Exception_Override__c = true;
                rs.Jan_NRT_Adjustment__c = 100;
                rs.Feb_NRT_Adjustment__c = 100; 
                rs.Mar_NRT_Adjustment__c = 100; 
                rs.Apr_NRT_Adjustment__c = 100; 
                rs.May_NRT_Adjustment__c = 100; 
                rs.Jun_NRT_Adjustment__c = 100; 
                rs.Jul_NRT_Adjustment__c = 100; 
                rs.Aug_NRT_Adjustment__c = 100;        
                rs.Sep_NRT_Adjustment__c = 100; 
                rs.Oct_NRT_Adjustment__c = 100; 
                rs.Nov_NRT_Adjustment__c = 100; 
                rs.Dec_NRT_Adjustment__c = 100; 
            }
            update rsList;
            
            List<Budget_and_Revenue__c> barList = new List<Budget_and_Revenue__c>();
            for( Integer i=0; i< nCount * 10; i++){
                Budget_and_Revenue__c bar = new Budget_and_Revenue__c(
                    Organisation__c=bacct.id, 
                    Product__c=prodList[Math.mod(i, 2)].id,
                    Financial_Year__c= String.ValueOf(2019 + Math.mod(i, 5)),
                    Jan_Revenue_Amount__c=100, 
                    Feb_Revenue_Amount__c=200,
                    Mar_Revenue_Amount__c=300,
                    Apr_Revenue_Amount__c=400, 
                    May_Revenue_Amount__c=500,
                    Jun_Revenue_Amount__c=600,
                    Jul_Revenue_Amount__c=700,
                    Aug_Revenue_Amount__c=800,
                    Sep_Revenue_Amount__c=900,
                    Oct_Revenue_Amount__c=1000,
                    Nov_Revenue_Amount__c=1100,
                    Dec_Revenue_Amount__c=1200,
                    Jan_Original_Budget__c=1000,
                    Feb_Original_Budget__c=2000,
                    Mar_Original_Budget__c=3000,
                    Apr_Original_Budget__c=4000,
                    May_Original_Budget__c=5000,
                    Jun_Original_Budget__c=6000,
                    Jul_Original_Budget__c=7000,
                    Aug_Original_Budget__c=8000,
                    Sep_Original_Budget__c=9000,
                    Oct_Original_Budget__c=10000,
                    Nov_Original_Budget__c=11000,
                    Dec_Original_Budget__c=12000
                    );
                    
                barList.add(bar);                                   
            }
    
            insert barList;
            
            // 11/26/19: Uncommented out test OPC data and moved test.startTest() to include insert DML
            // Changed BAR Financial Year from 2012 to 2019
            test.startTest();
            Opp_Product_Classification__c opc = new Opp_Product_Classification__c(
                Account__c = bacct.Id, 
                Product__c = prodList[0].Id, 
                Classification__c = 'Growth', 
                Financial_Year__c = '2012',
                Jan_Schedule_Amount__c = 1, 
                Feb_Schedule_Amount__c = 2, 
                Mar_Schedule_Amount__c = 3, 
                Apr_Schedule_Amount__c = 4,
                May_Schedule_Amount__c = 5, 
                Jun_Schedule_Amount__c = 6, 
                Jul_Schedule_Amount__c = 7, 
                Aug_Schedule_Amount__c = 8,
                Sep_Schedule_Amount__c = 9, 
                Oct_Schedule_Amount__c = 10, 
                Nov_Schedule_Amount__c = 11, 
                Dec_Schedule_Amount__c = 12 
            );
            insert opc;         
                
            GenerateOPCBatchable gob = new GenerateOPCBatchable();
            
            
            gob.testRun = true;
            Id OPCId = Database.executeBatch(gob);
            Opp_Product_Classification__c opc1 = new Opp_Product_Classification__c();
            Opp_Product_Classification__c opc2 = new Opp_Product_Classification__c();
            OPCUtility.updateExistingOPC(opc1,opc2);
        test.stopTest();
        }
        
            
    }
    
    public static Map<String,ParentAccountRevenue> getParentAccountRevenueMap(List<String> acctIdList, List<String> prodIdList) {
        Set<String> accountIdSet = new Set<String>(acctIdList);
        Map<String,String> parentChildAccountIdMap = getParentChildAccountIdMap(accountIdSet);
        accountIdSet.addAll(parentChildAccountIdMap.keySet());
        return getParentAccountRevenueMap(parentChildAccountIdMap,getBudgetAndRevenue(accountIdSet,prodIdList));
    }
    
    public static Map<String,ParentAccountRevenue> getParentAccountRevenueMap(Set<String> accountIdSet) {
        Map<String,String> parentChildAccountIdMap = getParentChildAccountIdMap(accountIdSet);
        accountIdSet.addAll(parentChildAccountIdMap.keySet());
        return getParentAccountRevenueMap(parentChildAccountIdMap,getBudgetAndRevenue(accountIdSet));
    }

    private static Map<String,ParentAccountRevenue> getParentAccountRevenueMap(Map<String,String> parentChildAccountIdMap,List<Budget_and_Revenue__c> budgetAndRevenue) {
        Map<String,ParentAccountRevenue> revenueMap = new Map<String,ParentAccountRevenue>();
        for (Budget_and_Revenue__c bar : budgetAndRevenue) {
            boolean isChildAccount = parentChildAccountIdMap.containsKey(bar.Organisation__c);
            Id parentAccountId = isChildAccount ? parentChildAccountIdMap.get(bar.Organisation__c) : bar.Organisation__c;    
            String revenueKey = constructRevenueKey(parentAccountId, bar);
            if (revenueMap.containsKey(revenueKey)) {
              revenueMap.get(revenueKey).add(bar,isChildAccount);  
            } else {
              revenueMap.put(revenueKey,new ParentAccountRevenue(parentAccountId,bar,isChildAccount));
            } 
        }
        return revenueMap;
    }
    
   private static List<Budget_and_Revenue__c> getBudgetAndRevenue(Set<String> accountIdSet) {
        return [SELECT Organisation__c, Product__c, Financial_Year__c, 
                Jan_Revenue_Amount__c, Feb_Revenue_Amount__c, Mar_Revenue_Amount__c,
                Apr_Revenue_Amount__c, May_Revenue_Amount__c, Jun_Revenue_Amount__c,
                Jul_Revenue_Amount__c, Aug_Revenue_Amount__c, Sep_Revenue_Amount__c,
                Oct_Revenue_Amount__c, Nov_Revenue_Amount__c, Dec_Revenue_Amount__c,
                Total_Revenue_Amount__c
                FROM Budget_and_Revenue__c
                WHERE Organisation__c IN : accountIdSet
                AND Financial_Year__c != NULL
                LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())];
    }
    
   private static List<Budget_and_Revenue__c> getBudgetAndRevenue(Set<String> acctIdList, List<String> prodIdList) {
       return [Select Organisation__c, Product__c, Financial_Year__c, 
               Jan_Revenue_Amount__c, Feb_Revenue_Amount__c, Mar_Revenue_Amount__c,
               Apr_Revenue_Amount__c, May_Revenue_Amount__c, Jun_Revenue_Amount__c,
               Jul_Revenue_Amount__c, Aug_Revenue_Amount__c, Sep_Revenue_Amount__c,
               Oct_Revenue_Amount__c, Nov_Revenue_Amount__c, Dec_Revenue_Amount__c,
               Total_Revenue_Amount__c
               From Budget_and_Revenue__c
               Where Organisation__c <> null
               And Product__c <> null
               And Financial_Year__c <> null
               And Organisation__c in : acctIdList 
               And Product__c in : prodIdList
              LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())]; 
    }
    
    /*
     * Genereates a unique identifier for a budget and revenue record associated with a specified account.
     */                 
    private static Map<String,String> getParentChildAccountIdMap(Set<String> accountIdSet) {
        Map<String,String> parentChildAccountIdMap = new Map<String,String>();
        for (AccountRelationship__c acr: [SELECT ParentAccount__c, RelatedAccount__c 
                                          FROM AccountRelationship__c 
                                          WHERE ParentAccount__c in :accountIdSet 
                                          AND Relationship__c='OPC'
                                          AND EndDate__c = null
                                          LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())]) {
            parentChildAccountIdMap.put(acr.RelatedAccount__c, acr.ParentAccount__c);
        }
        return parentChildAccountIdMap;
    }
    
    /*
     * Genereates a unique identifier for a budget and revenue record associated with a specified account.
     * @parameter parentAccountId : the account id to associate with the budget and revenue figure
     * @parameter record : the budget and revenue record to associate with the account
     * @returns a string identifier.
     */
                     
    private static String constructRevenueKey(Id parentAccountId, Budget_and_Revenue__c record) {
            return String.valueOf(parentAccountId) + String.valueOf(record.Product__c) + record.Financial_Year__c;
    }
    
    /*
     * Data strucutre for containing sum total revenues for accounts and their children accounts.
     */
    
    
    public class ParentAccountRevenue implements Comparable {
        private final integer groupValueOffset = 13;
        private Id accountId;
        private Id productId;
        private String year;
        // Stores revenue amounts for the parent account (0-12) and
        // total revenue for all children accounts (13-25)
        private Decimal[] Revenue;
        // Determines whether to return the Parent Account Revenue OR
        // the Grouped revenue being the sum of Parent Account Revenue and
        // all child account revenue figures.
        private boolean useGroupedValues ;
        
        public Id Organisation {get{return accountId;}}
        public Id Product {get{return productId;}}
        public String Financial_Year {get{return year;}}
        // returns revenue amounts for the parent account OR the total for all child accounts
        public Decimal Total_Revenue_Amount {get{return getRevenue(0);}}
        public Decimal Jan_Revenue_Amount {get{return getRevenue(1);}}
        public Decimal Feb_Revenue_Amount {get{return getRevenue(2);}}
        public Decimal Mar_Revenue_Amount {get{return getRevenue(3);}}
        public Decimal Apr_Revenue_Amount {get{return getRevenue(4);}}
        public Decimal May_Revenue_Amount {get{return getRevenue(5);}}
        public Decimal Jun_Revenue_Amount {get{return getRevenue(6);}}
        public Decimal Jul_Revenue_Amount {get{return getRevenue(7);}}
        public Decimal Aug_Revenue_Amount {get{return getRevenue(8);}}
        public Decimal Sep_Revenue_Amount {get{return getRevenue(9);}}
        public Decimal Oct_Revenue_Amount {get{return getRevenue(10);}}
        public Decimal Nov_Revenue_Amount {get{return getRevenue(11);}}
        public Decimal Dec_Revenue_Amount {get{return getRevenue(12);}}

        /*
         * Constructor
         * @parameter accountId : the account id to associate with the budget and revenue figure
         * @parameter record : the budget and revenue record to associate with the account
         * @returns a string identifier.
         */
        public ParentAccountRevenue(Id accountId, Budget_and_Revenue__c record, boolean isChildAccount) {
            this.accountId = accountId;
            productId = record.Product__c;
            year = record.Financial_Year__c;
            Revenue = new Decimal[]{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
            add(record,isChildAccount);
            useGroupedValues = false;
        }

        public void add(Budget_and_Revenue__c record, boolean isChildAccount) {
            integer offset = isChildAccount ? groupValueOffset : 0;
            Revenue[0+offset] += replaceNullWithZero(record.Total_Revenue_Amount__c);
            Revenue[1+offset] += replaceNullWithZero(record.Jan_Revenue_Amount__c);
            Revenue[2+offset] += replaceNullWithZero(record.Feb_Revenue_Amount__c);
            Revenue[3+offset] += replaceNullWithZero(record.Mar_Revenue_Amount__c);
            Revenue[4+offset] += replaceNullWithZero(record.Apr_Revenue_Amount__c);
            Revenue[5+offset] += replaceNullWithZero(record.May_Revenue_Amount__c);
            Revenue[6+offset] += replaceNullWithZero(record.Jun_Revenue_Amount__c);
            Revenue[7+offset] += replaceNullWithZero(record.Jul_Revenue_Amount__c);
            Revenue[8+offset] += replaceNullWithZero(record.Aug_Revenue_Amount__c);
            Revenue[9+offset] += replaceNullWithZero(record.Sep_Revenue_Amount__c);
            Revenue[10+offset] += replaceNullWithZero(record.Oct_Revenue_Amount__c);
            Revenue[11+offset] += replaceNullWithZero(record.Nov_Revenue_Amount__c);
            Revenue[12+offset] += replaceNullWithZero(record.Dec_Revenue_Amount__c);
                                                  
        }
        
        public ParentAccountRevenue group() {
            useGroupedValues = true;
            return this;
        }
        public ParentAccountRevenue ungroup() {
            useGroupedValues = false;
            return this;
        }
        private Decimal getRevenue(integer monthIndex) {
            return  useGroupedValues ? Revenue[monthIndex] + Revenue[monthIndex+groupValueOffset] : Revenue[monthIndex];
        }
        
        
        private Decimal replaceNullWithZero(Decimal value) {
            return value == null ? 0 : value;
        }

        // Sort records by Year (desc)
        public Integer compareTo(Object compareTo) {
            ParentAccountRevenue otherRevenue = (ParentAccountRevenue)compareTo;
            if (otherRevenue == null) return 1;
            if (year == otherRevenue.year) return 0;
            if (year > otherRevenue.year) return -1;
            return 1;        
        }
    }
}