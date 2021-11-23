/**************************************************
Type:       Utility Class for Deleted Record Object
Purpose:    Create "deleted" record/s in the Deleted Record object when record/s (Account, Lead, Opportunity and OpportunityLineItem) is/are deleted (soft or hard)
            Remove "undeleted" record/s from the Deleted Record object when record/s (Account, Lead and Opportunity) is/are undeleted
Used By:    Various Triggers (Account, Lead, Opportunity and OpportunityLineItem)
History:
--------------------------------------------------
15.05.2011  M. Isidro (Cloud Sherpas)   Created
17.05.2011  M. Isidro (Cloud Sherpas)   Added cascaded delete on Opportunity -> OpportunityLineItem
25.05.2012  M. Isidro (Cloud Sherpas)   Added method to reset Root Id of deleted Account/s to its/their own Id
                                        Added method to recompute the Overall Total Revenue of the Root Account of deleted Account/s
28.05.2012  M. Isidro (Cloud Sherpas)   Added methods to create/remove a deleted record log when an Account is deactivated/activated    
05.06.2012  M. Isidro (Cloud Sherpas)   Modified code for Opportunity/OpportunityLineItem:
                                            - Populate the Unique Id with a composite value – Opportunity Number + Opportunity Item Number
                                            - Only OpportunityLineItem is logged (Opportunity is not) 
28.06.2012  M. Isidro (Cloud Sherpas)   Added an underscore between the Opportunity ID and Opportunity Item Number for the Unique ID
02.11.2012  Richard Enojas (Salesforce) Added logic to populate Integration Modified Date on 'undelete' scenario 
30.10.2015  Kalpita Talwadekar          Added start and end date to opportunity product in testDeletedRecord() for inYearRevenue request                                                                   
26.08.2016  Kalpita Talwadekar          Updated class to optimize the code and follow coding standards.
**************************************************/

public with sharing class DeletedRecordUtil {
    
    
    
 
    /**
      * @description       Create deleted record/s when an after delete trigger fires up on (Account, Lead, Opportunity and OpportunityLineItem)
      * @param             List<SObject> listSObject, String objType
      * @return            NA
      * @throws            NA
      */
    public static void createDeletedRecord (List<SObject> listSObject, String objType){
        try{
            system.debug('***' + objType + '***' + listSObject);
            Map<Id, String> mapOpptyIdOpptyNumber = new Map<Id, String>();
            List<String> opptyIdList = new List<String>();
            if (SSSWConstants.OPP_LINE_ITEM.equalsIgnoreCase(objType)){
                for (SObject oli : listSObject){
                    opptyIdList.add( String.valueOf(oli.get(SSSWConstants.OPP_ID)) );
                }  
                List<Opportunity> opptyList = [SELECT Id, Opportunity_Number__c FROM Opportunity WHERE Id in : opptyIdList];
                for (Opportunity oppty : opptyList){
                    mapOpptyIdOpptyNumber.put(oppty.Id, oppty.Opportunity_Number__c);
                }
            }
            
            List<Deleted_Record__c> listDeletedRecords = new List<Deleted_Record__c>();
            List<String> listIds = new List<String>();
            String uniqueID;
            for(SObject so : listSObject){
                listIds.add(so.id);

                if (SSSWConstants.ACC_OBJ_TYPE.equalsIgnoreCase(objType)){
                    uniqueID = String.valueOf( so.get(SSSWConstants.LEGACY_ID) );
                } else if (SSSWConstants.OPP_OBJ_TYPE.equalsIgnoreCase(objType) ){
                    uniqueID = String.valueOf( so.get(SSSWConstants.OPP_NUMBER) );
                } else if (SSSWConstants.OPP_LINE_ITEM.equalsIgnoreCase(objType)){
                    uniqueID = mapOpptyIdOpptyNumber.get(String.valueOf( so.get(SSSWConstants.OPP_ID) ) ) + '_' +  String.valueOf( so.get(SSSWConstants.OPP_ITEM_NUMBER) );  
                } else if ('Lead'.equalsIgnoreCase(objType)){
                    uniqueID = String.valueOf( so.get(SSSWConstants.LEAD_NUMBER) );
                }
                
                // Do not add deleted record for Opportunity for now, remove this if Opportunity needs to be logged
                if (!SSSWConstants.OPP_OBJ_TYPE.equalsIgnoreCase(objType)){
                    listDeletedRecords.add(
                        new Deleted_Record__c(
                            Original_System_Id__c = so.id,
                            Unique_Id__c = uniqueID,
                            IsDeleted__c = true,
                            SObject__c = objType
                        )
                    );              
                }
            }
            
            system.debug('***listIds: ' + listIds);
            
            if (SSSWConstants.OPP_OBJ_TYPE.equalsIgnoreCase(objType)){
                for (Opportunity oppty : [SELECT Id, Opportunity_Number__c, (Select Id, Opportunity_Item_Number__c From OpportunityLineItems) FROM Opportunity WHERE Id in :listIds]) {
                    for (OpportunityLineItem oli : oppty.OpportunityLineItems) {
                        listDeletedRecords.add(
                            new Deleted_Record__c(
                                Original_System_Id__c = oli.id,
    //                            Unique_Id__c = oli.Opportunity_Item_Number__c,
                                Unique_Id__c = oppty.Opportunity_Number__c + '_' + oli.Opportunity_Item_Number__c,
                                IsDeleted__c = true,
                                SObject__c = SSSWConstants.OPP_LINE_ITEM
                            )
                        );  
                    }               
                }
            }   
            
            if(!listDeletedRecords.isEmpty()){
                system.debug('***listDeletedRecords' + listDeletedRecords);
                database.insert(listDeletedRecords);
            }
        }catch(Exception exp){
            System.debug(exp.getMessage());
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                            DeletedRecordUtil.class.getName(), 'resetRootId', 
                                            'account or lead trigger', LoggingLevel.ERROR);
        }
    }
    
    
    /**
      * @description       Undelete deleted record/s when an after undelete trigger fires up on (Account, Lead and Opportunity)
      * @param             List<SObject> listSObject
      * @return            NA
      * @throws            NA
      */
    public static void undeleteDeletedRecord (List<SObject> listSObject){
        try{
            List<String> listIds = new List<String>();
            for(SObject so : listSObject){
                listIds.add(so.id);
            }   

            if(!listIds.isEmpty()){

                system.debug('***listIds: ' + listIds);
            
                if (SSSWConstants.OPP_OBJ_TYPE.equalsIgnoreCase(listSObject[0].getSObjectType().getDescribe().getLabel())){
                    for (Opportunity oppty : [SELECT Id, (Select Id From OpportunityLineItems) FROM Opportunity WHERE Id in :listIds]) {
                        for (OpportunityLineItem oli : oppty.OpportunityLineItems) {
                            listIds.add(oli.id);                            
                        }               
                    }
                }
                
                if (SSSWConstants.ACC_OBJ_TYPE.equalsIgnoreCase(listSObject[0].getSObjectType().getDescribe().getName())){
                    List<Account> updacctlist = new List<Account>();
                    for (Account acct : [SELECT Id, LastModifiedDate, Integration_Mod_Date__c FROM Account WHERE Id in :listIds]) {
                        acct.Integration_Mod_Date__c = acct.LastModifiedDate;
                        updacctlist.add(acct);
                    }
                    
                    system.debug('***Update Account Integration Modified Date***');
                    database.update(updacctlist);    
                    
                    
                }
                   
                List<Deleted_Record__c> listUndeletedRecords = [SELECT Original_System_Id__c FROM Deleted_Record__c WHERE Original_System_Id__c in : listIds];
                if(!listUndeletedRecords.isEmpty()){
                    system.debug('***' + listUndeletedRecords);
                    database.delete(listUndeletedRecords);
                    Database.emptyRecycleBin(listUndeletedRecords); 
                }
            }
        }catch(Exception exp){
            System.debug(exp.getMessage());  
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                            DeletedRecordUtil.class.getName(), 'undeleteDeletedRecord', 
                                            'account or lead trigger', LoggingLevel.ERROR);
        }
    }
    
    /**
      * @description       Reset Root Id to own Id on Delete
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public static void resetRootId (List<Account> listAccount){
        Set<Id> idList = new Set<Id>();
        for(Account acct : listAccount){
            idList.add(acct.Id);    
        }
        List<Account> updateAccountList = [SELECT Id, Root_Id__c FROM Account WHERE id in : idList];
        for (Account acct : updateAccountList){
            acct.Root_Id__c = acct.id;          
        }
        
        system.debug('*** resetRootId : updateAccountList: ' + updateAccountList);
        if(!updateAccountList.isEmpty()) {
            database.update(updateAccountList);
        }
        
    }  
 

/*     
    // Recompute the Overall Total Revenue for the Root Account/s
    public static void recomputeOverallTotalBudgetandRevenue (List<Account> listAccount){
        Set<Id> rootIds = new Set<Id>();
        for(Account acct : listAccount){
            rootIds.add(acct.Root_Id__c);
        }
        
        List<Account> updateAccountList = [SELECT Id, Overall_Total_Revenue__c, Overall_Total_Original_Budget__c, Overall_Total_Revised_Budget__c FROM Account WHERE id in : rootIds];
        for (Account updateAccount : updateAccountList){
            if (updateAccount.Overall_Total_Revenue__c == null){
                updateAccount.Overall_Total_Revenue__c = 0;
            }
            
            if (updateAccount.Overall_Total_Original_Budget__c == null){
                updateAccount.Overall_Total_Original_Budget__c = 0;
            }
            
            if (updateAccount.Overall_Total_Revised_Budget__c == null){
                updateAccount.Overall_Total_Revised_Budget__c = 0;
            }
            for (Account acct : listAccount){
                if (acct.Root_Id__c == updateAccount.id){
                    updateAccount.Overall_Total_Revenue__c = updateAccount.Overall_Total_Revenue__c - acct.Total_Net_Revenue__c;
                    updateAccount.Overall_Total_Original_Budget__c = updateAccount.Overall_Total_Original_Budget__c - acct.Overall_Total_Original_Budget__c;
                    updateAccount.Overall_Total_Revised_Budget__c = updateAccount.Overall_Total_Revised_Budget__c - acct.Overall_Total_Revised_Budget__c;
                }
            }
        }
        system.debug('*** recomputeOverallTotalRevenue : updateAccountList: ' + updateAccountList);
        update updateAccountList;
    }    
*/    
    
   
    /**
      * @description       Check if Account/s is/are deactivated/activated, if so, add/remove delete log 
      * @param             Map<Id, Account> newMap, Map<Id, Account> oldMap, List<Account> acctList
      * @return            NA
      * @throws            NA
      */
    public static void deactivateActivateAccount (Map<Id, Account> newMap, Map<Id, Account> oldMap, List<Account> acctList){
        
        List<Account> deactivateAccountList = new List<Account>();
        List<Account> activateAccountList = new List<Account>();
        
        for (Account acct: acctList){
            if ( oldMap.get(acct.id).Archiving_Flag__c != newMap.get(acct.id).Archiving_Flag__c ){
                if (newMap.get(acct.id).Archiving_Flag__c) {
                    // Deactivated
                    deactivateAccountList.add(acct);    
                } else {
                    // Activated
                    activateAccountList.add(acct);
                }                               
            }       
        }
        
        if (!deactivateAccountList.isEmpty()){
            createDeletedRecord(deactivateAccountList, SSSWConstants.ACC_OBJ_TYPE);      
        }   
        
        if (!activateAccountList.isEmpty()){
            undeleteDeletedRecord(activateAccountList); 
        }
    }
    
    
    /**
      * @description       test method to test the delete scenarios
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    @isTest(seeAllData=true)
    private static void testDeletedRecord(){
        RecordType orgRecType = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = :SSSWConstants.ACC_OBJ_TYPE AND Name = 'Organisation' limit 1];
        
        List<Account> acctList = new List<Account>();
        //create account
        // 11/25/2019 - duplicate_detected error fix: removed ABN value
        Account orgAccount = new Account(
            name='Organisation Account', 
            recordtypeid=orgRecType.Id, 
            phone='12345678900', 
            email__c='xp@x.com',
            abn__c='', 
            Website='www.google.com'            
        );
        insert orgAccount;
  
        
        //create child account
        // 11/25/2019 - duplicate_detected error fix: removed ABN value
        Account childAccount = new Account(
            name='Child Account',
            ParentId=orgAccount.id, 
            recordtypeid=orgRecType.Id, 
            phone='12345678901', 
            email__c='xc@x.com',
            abn__c='', 
            Website='www.googlex.com'            
            
        );
        insert childAccount;  

/*        
        //create grandchild account
        Account grandchildAccount = new Account(
            name='Granchild Account',
            ParentId=childAccount.id, 
            recordtypeid=orgRecType.Id, 
            phone='12345678902', 
            email__c='xg@x.com',
            abn__c='12345678903', 
            Website='www.googley.com'                  
        );
        insert grandchildAccount;                  
        
        //create Budget and Revenue
        Budget_and_Revenue__c bar = new Budget_and_Revenue__c(
            Organisation__c=grandchildAccount.id,
            Total_Revenue_Amount__c=100, 
            Total_Credit_Amount__c=10, 
            Total_Rebate_Amount__c=5
        );
        insert bar;         
*/        
        //create account
        Opportunity oppty = new Opportunity(
            name=SSSWConstants.OPP_OBJ_TYPE, 
            StageName = 'Identify',
            closedate = date.today(),
            accountid=orgAccount.id,
            type='New Customer',Contract_Number__c='99999', Contract_Start_Date__c=Date.newInstance(2012, 07 ,27),Contract_End_Date__c=Date.newInstance(2012, 07 ,27)
        );
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
                Classification__c = 'New Business',
                Quantity = 1,
                TotalPrice = 1000,
                Contract_End_Date__c = system.today()+10,
                Contract_Start_Date__c = system.today()
            );
            oliList.add(oli);
        }
        insert oliList;     
        
        //create lead
        Lead leadRec = new Lead(
            LastName='Lead Record',
            FirstName='First Name',
            Email='x@x.com',
            Street='Street',
            City='City',
            State='State',
            Country='Country',
            PostalCode='1000',
            Parcels_per_week__c='1-9'            
        );
        insert leadRec; 
        
        test.startTest();
        
            orgAccount.Archiving_Flag__c = true;
            update orgAccount;
            orgAccount.Archiving_Flag__c = false;
            update orgAccount;

            delete leadRec;
            system.assertEquals(leadRec.id, [SELECT Original_System_Id__c FROM Deleted_Record__c WHERE Original_System_Id__c=:leadRec.id limit 1].Original_System_Id__c);
            undelete leadRec;
            delete oliList[nCount-1];
            delete oppty;
            //system.assertEquals(oppty.id, [SELECT Original_System_Id__c FROM Deleted_Record__c WHERE Original_System_Id__c=:oppty.id limit 1].Original_System_Id__c);
            system.assertEquals(oliList[0].id, [SELECT Original_System_Id__c FROM Deleted_Record__c WHERE Original_System_Id__c=:oliList[0].id limit 1].Original_System_Id__c);
            undelete oppty;
            system.assertEquals(oppty.id, [SELECT Id FROM Opportunity WHERE Id=:oppty.id limit 1].Id);
            delete childAccount;
        test.stopTest();
    }
}