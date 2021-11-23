/**************************************************
Type:       Batch Class - Perform Validation of OPC classification on line items.
Purpose:    Validate if line item OPC classifications are correct.  If not, then raise a case and set OPC record for review.
            This batch replaces the "checkForException" method in the original "OPCUtility" class.
History:
 9-Sep-2013 Clinton McIntyre (Salesforce.com)     Initial Batch Build

**************************************************/
global without sharing class OPCValidationService_Batchable implements Database.Batchable<SObject> {

    /* Constants */
    static final String ERROR_EMAIL = BatchJobSettings__c.getInstance().OPC_Validation_Error_Email__c;

    /* Private Variables */
    private String query;
    
    global OPCValidationService_Batchable(Boolean testRun) {
        system.debug('### START OPCValidationServiceBatchable, HeapSize : ' + Limits.getHeapSize() );
        System.assert(ERROR_EMAIL != null, 'The ERROR_EMAIL constant cannot be null');
        
        /* Query unprocessed Line Items, Opportunity, and Product Deatils from pricebook in a single statement */
        /* Only look at Opportunities closed from a fixed date */
        query = 'SELECT Id, OPCValidated__c, Classification__c, Contract_Start_Date__c, PricebookEntry.Product2Id, PricebookEntry.Name, '
        + 'Opportunity.Id, Opportunity.OwnerId, Opportunity.CloseDate, Opportunity.AccountId, Opportunity.Account.Name '
        + 'FROM OpportunityLineItem '
        + 'WHERE OPCValidated__c <> true AND PricebookEntryId <> null AND Classification__c <> null AND Contract_Start_Date__c <> null AND Contract_End_Date__c <> null '
        + 'AND Opportunity.AccountId <> null AND Opportunity.StageName = \'Closed Won\' AND Opportunity.CloseDate >= 2013-07-01 '
        + 'ORDER BY Opportunity.AccountId, Opportunity.Id';

        //append 200 query limit for testing
        if(testRun) query = query + ' limit 200';
    }
    
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug(System.LoggingLevel.DEBUG, '##DEBUG: START - query: ' + query);
        return Database.getQueryLocator(query);
    }

    
    global void finish(Database.BatchableContext BC) {
        system.debug('*** FINISH:');    
    }   


    global void execute(Database.BatchableContext BC, List<OpportunityLineItem> optyItems) {
        system.debug('### EXECUTE BATCH OPCValidationServiceBatchable, HeapSize : ' + Limits.getHeapSize() );
        system.debug('*** HeapSize Limit: ' + Limits.getLimitHeapSize());
        
        // List to store any errors in creating/updating records.
        List<String> errorsList = new List<String>();

        // Cache the list of Accounts for all Opportunities in this batch
        Set<String> AccountIdList = new Set<String>();
        List<String> OptyItemIdList = new List<String>();
        if (!optyItems.isEmpty()) {
            for (OpportunityLineItem OptyItemRecord : optyItems) {
                string accountId = OptyItemRecord.Opportunity.AccountId;
                if (accountId != '' && accountId != null)
                {
                    if(!AccountIdList.contains(accountId)) AccountIdList.add( accountId );
                    //errorsList.add('DEBUG: Adding Account ' + accountId);
                }
                string optyItemId = OptyItemRecord.Id;
                if (optyItemId != '' && optyItemId != null) OptyItemIdList.add( optyItemId );
                //errorsList.add('DEBUG: Adding Opportunity ' + OptyItemRecord.Id);
            }
        }

        // Cache the list of Revenue Schedule records for all given Line Items
        List<Revenue_Schedule__c> rsList = new List<Revenue_Schedule__c>();
        rsList = [Select Id, OpportunityLineItem__c, Opportunity_Product_Classification__c, Exception_Override__c
                  FROM Revenue_Schedule__c
                  WHERE OpportunityLineItem__c in : OptyItemIdList];

        // Build the list of OPC Id's, and capture any exception flags on RS Records.
        List<String> OPCIdList = new List<String>();
        Set<String> RSExeceptionList = new Set<String>();
        Map<String, Set<String>> LineItemToOPCMap = new Map<String, Set<String>>();

        if (!rsList.isEmpty()) {
            for (Revenue_Schedule__c RSRecord : rsList) {
                // Add to list of OPC Id's.
                string opcId = RSRecord.Opportunity_Product_Classification__c;
                if (opcId != '' && opcId != null) 
                {
                    // Add to list of all OPC Id's.
                    OPCIdList.add( opcId );
                    
                    // Add to map of Line Items to OPC records.
                    if(LineItemToOPCMap.containsKey(RSRecord.OpportunityLineItem__c)){
                        // If the Line Item is already in the map, then add the new OPC record to the map.
                        Set<String> LineItemOPCSet = LineItemToOPCMap.get(RSRecord.OpportunityLineItem__c);
                        if(!LineItemOPCSet.contains(opcId)) LineItemOPCSet.add(opcId);
                        //errorsList.add('DEBUG: OPC Record (to existing map)' + opcId);
                    }
                    else
                    {
                        // If the Line Item is not already in the map, the create new OPC Item Id Set and add it to the map.
                        Set<String> LineItemOPCSet = new Set<String>();
                        LineItemOPCSet.add(opcId);
                        LineItemToOPCMap.put(RSRecord.OpportunityLineItem__c,LineItemOPCSet);
                        //errorsList.add('DEBUG: OPC Record (to new map)' + opcId);
                    }
                }
                
                // Add to set of RS Exceptions
                if(RSRecord.Exception_Override__c) {
                    if(!RSExeceptionList.contains(RSRecord.OpportunityLineItem__c)) RSExeceptionList.add( RSRecord.OpportunityLineItem__c );
                    //errorsList.add('DEBUG: Adding RS Exception : ' + RSRecord.Id + ' for line ' + RSRecord.OpportunityLineItem__c);
                }
            }
        }

        // Cache the list of OPC Records
        List<Opp_Product_Classification__c> opcList = new List<Opp_Product_Classification__c>();
        opcList = [SELECT Id, Account__c, Under_Review_by_Sales_Manager__c, Hidden_Under_Review__c
                   FROM Opp_Product_Classification__c 
                   WHERE Id in :OPCIdList];

        // Build a map of the OPC Records so that we can update them later.
        Map<String, Opp_Product_Classification__c> idOPCMap = new Map<String, Opp_Product_Classification__c>();
        if (!opcList.isEmpty()) {
            for (Opp_Product_Classification__c opcItem : opcList) {
                idOPCMap.put(opcItem.id, opcItem);
            }
        }

        // Build a list of whether there was product revenue for each given year + month (Product:YYYY:MM).
        Set<string> barMonthSet = new Set<String>();
        if (!AccountIdList.isEmpty()) buildBARSets(barMonthSet, AccountIdList);

        String rtId = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType='Case' AND Name='OPC Exception' Limit 1].Id;  
        List<Case> caseList = new List<Case>(); 
        
        String returnErrorString = '';
        String OPCRecordsFlagged = '';
        for (OpportunityLineItem OptyItemRecord : optyItems) {
            if( !RSExeceptionList.contains(OptyItemRecord.Id) )
            {
                // If there is no exception on the Revenue Schedule Record, then validate the line item.
                returnErrorString = validateClassification(barMonthSet, OptyItemRecord);
            }
            else returnErrorString='';
            //errorsList.add('DEBUG: Validating ' + OptyItemRecord.Id + ' result = ' + returnErrorString );
            
            if (returnErrorString.length()>=1) {
                OPCRecordsFlagged = '';

                // Check if there are OPC records related to this Line Item (via Revenue Schedule records)
                if(LineItemToOPCMap.containsKey(OptyItemRecord.Id)){
                    Set<String> LineItemOPCSet = LineItemToOPCMap.get(OptyItemRecord.Id);        
                    for (String OPCIdString : LineItemOPCSet) {
                        //system.debug('***Setting Under Review flag on OPC Record: ' + OPCIdString);        
                        Opp_Product_Classification__c opcItemUpdate = idOPCMap.get(OPCIdString);    
                        // Set Review flag on OPC record.
                        opcItemUpdate.Hidden_Under_Review__c = true;        
                        OPCRecordsFlagged += opcItemUpdate.Id + ' ';
                    }
                }
                
                // Create Case Record
                createCase(OptyItemRecord, caseList, returnErrorString, rtId, OPCRecordsFlagged);  
                //errorsList.add('DEBUG: Creating Case.  OPC Records Flagged = ' + OPCRecordsFlagged );
            }
            OptyItemRecord.OPCValidated__c = true;
            
            //addded by Kalpita for in year revenue request (revenue start and end date are now mandatory)
            OptyItemRecord.Contract_Start_Date__c = OptyItemRecord.Contract_Start_Date__c == null ? OptyItemRecord.Opportunity.CloseDate : OptyItemRecord.Contract_Start_Date__c; 
            
            // Updated by Adrian Recio
            // Description: Code is not used anymore. OP End date should not be assigned based on contract end date.
            // Date: 17/7/2017
            // OptyItemRecord.Contract_End_Date__c = OptyItemRecord.Contract_End_Date__c == null ? OptyItemRecord.Opportunity.CloseDate + 365 : OptyItemRecord.Contract_End_Date__c;
            
        }
        
        system.debug('***FinalgetHeapSize: ' + Limits.getHeapSize());        

        Integer counter = 0;
        String errorMessageAndCode = '';

        // Update the items that have been set to validated.
        List<Database.SaveResult> optyItemSaveResults = Database.update(optyItems, false);
        // Loop through Item Save results and check for errors
        for (counter = 0; counter < optyItemSaveResults.size(); counter++) {
            Database.SaveResult optyItemSaveResultItem = optyItemSaveResults[counter];
            // If errors exist, add to a List collection for later notification to admin
            if (!optyItemSaveResultItem.isSuccess()) {
                for (Database.Error error : optyItemSaveResultItem.getErrors()) {
                    errorMessageAndCode = 'Unable to set OPCValidated__c to true on Opty Item : ' + optyItems[counter].Id + ': ';
                    errorMessageAndCode += error.getStatusCode() +':'+ error.getMessage();
                    errorsList.add(errorMessageAndCode);
                }
            }
        }

        // Write the cases        
        if (!caseList.isEmpty()) {
            // Update the items that have been set to validated.
            List<Database.SaveResult> caseSaveResults = Database.insert(caseList, false);
            
            // Loop through Update results and check for errors
            for (counter = 0; counter < caseSaveResults.size(); counter++) {
                Database.SaveResult caseSaveResultItem = caseSaveResults[counter];
                // If errors exist, add to a List collection for later notification to admin
                if (!caseSaveResultItem.isSuccess()) {
                    for (Database.Error error : caseSaveResultItem.getErrors()) {
                        errorMessageAndCode = 'Unable to write case record : ' + caseList[counter].Id + ' : ' + + caseList[counter];
                        errorMessageAndCode += error.getStatusCode() +':'+ error.getMessage();
                        errorsList.add(errorMessageAndCode);
                    }
                }
            }
        }
    
        // Update the OPC records that have been flagged for review.
        List<Database.SaveResult> opcSaveResults = Database.update(opcList, false);
        // Loop through Save results and check for errors
        for (counter = 0; counter < opcSaveResults.size(); counter++) {
            Database.SaveResult opcSaveResultItem = opcSaveResults[counter];
            // If errors exist, add to a List collection for later notification to admin
            if (!opcSaveResultItem.isSuccess()) {
                for (Database.Error error : opcSaveResultItem.getErrors()) {
                    errorMessageAndCode = 'Unable to set OPC Hidden_Under_Review__c = true flag on OPC record : ' + opcList[counter].Id + ': ';
                    errorMessageAndCode += error.getStatusCode() +':'+ error.getMessage();
                    errorsList.add(errorMessageAndCode);
                }
            }
        }
        
        // If there are any errors, email the nominated administrator.
        if ( !errorsList.isEmpty() ) {
            // Send an email to the Custom Setting email address notifying of errors in batch.
            // Note: the email address should be a Salesforce user to avoid the daily limits on sending email from code.
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {ERROR_EMAIL};
            mail.setToAddresses(toAddresses);
            mail.setSubject('OPC Validation Errors: ' + System.now() + ' :Batch Job Id: ' + BC.getJobId());

            String messageHtmlBody = '<h2>Errors List - </h2> <br/>';
            for (String errorsListItem :  errorsList) {
                messageHtmlBody += errorsListItem + '<br/>';
            }

            mail.setHtmlBody ('<p>The OPCValidationServiceBatchable batch Apex job ' + BC.getJobId() +
                ' had the following errors:</p>' + messageHtmlBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        
    }
    

    public static List<Case> createCase(OpportunityLineItem OptyItemRecord, List<Case> caseList, String strReason, String rtId, String OPCRecordsFlagged) {
        if (OptyItemRecord != null) {
            Case kase = new Case();
            kase.AccountId = OptyItemRecord.Opportunity.AccountId;
            kase.Subject = strReason;
            kase.RecordTypeId = rtId;
            kase.Reason_Code__c = strReason;
            kase.OwnerId = OptyItemRecord.Opportunity.OwnerId;
            kase.Product__c = OptyItemRecord.PricebookEntry.Product2Id;
            kase.Origin = 'Web';
            kase.Opportunity__c = OptyItemRecord.Opportunity.Id;           
            
            DateTime itemDate = OptyItemRecord.Contract_Start_Date__c;
            String dateString =  itemDate.format('dd/MM/yyyy');
            
            kase.Description = 
              'Product Name: ' + OptyItemRecord.PricebookEntry.Name + '\n'
            + 'Classification: ' + OptyItemRecord.Classification__c + '\n'
            + 'Item Revenue Start Date: ' + dateString + '\n'
            + 'Opportunity Product Line Item: ' + OptyItemRecord.Id + '\n'
            + 'OPC Records Flagged: ' + OPCRecordsFlagged + '\n';
            
            caseList.add(kase);

            return caseList;    
        } else {
            return null;
        }
    }


    public static void addBarItem( Set<String> barMonthSet, String AccountId, String productId, String barMonth, String barYear )
    {
        // Add revenue for that particular product
        String uniqueId = AccountId + ':' + productId + ':' +  barYear + ':' +  barMonth; 
        if (!barMonthSet.contains(uniqueId)) {
            barMonthSet.add(uniqueId);
        }

        // Capture that revenue exists for any product in a given month
        uniqueId = AccountId + ':X:' +  barYear + ':' +  barMonth; 
        if (!barMonthSet.contains(uniqueId)) {
            barMonthSet.add(uniqueId);
        }
    }
    
    public static void buildBARSets( Set<String> barMonthSet, Set<String> AccountIdList )
    {
        /* Query BAR table for revenue for relevant products for this given Account, and build two sets (one forever, one by month) */
        List< Budget_and_Revenue__c> barList = [Select Organisation__c, Product__c, Financial_Year__c, 
            Jan_Revenue_Amount__c, Feb_Revenue_Amount__c, Mar_Revenue_Amount__c,
            Apr_Revenue_Amount__c, May_Revenue_Amount__c, Jun_Revenue_Amount__c,
            Jul_Revenue_Amount__c, Aug_Revenue_Amount__c, Sep_Revenue_Amount__c,
            Oct_Revenue_Amount__c, Nov_Revenue_Amount__c, Dec_Revenue_Amount__c
            From Budget_and_Revenue__c
            Where Organisation__c <> null
            And Product__c <> null
            And Financial_Year__c <> null
            And Organisation__c  in : AccountIdList
        ]; 
        
        // Note - consider restricting the BAR items by product, i.e. - And Product__c in : prodIdList

        String barMonth = '';
        String barYear = '';
        String productId = '';
        String AccountId = '';
                
        for (Budget_and_Revenue__c bar : barList) {
            productId = bar.Product__c;
            AccountId = bar.Organisation__c;
            if(bar.Jan_Revenue_Amount__c>0) { 
                barMonth = '1'; 
                barYear = bar.Financial_Year__c;
                addBarItem( barMonthSet, AccountId, productId, barMonth, barYear );
            }
            if(bar.Feb_Revenue_Amount__c>0) { 
                barMonth = '2'; 
                barYear = bar.Financial_Year__c; 
                addBarItem( barMonthSet, AccountId, productId, barMonth, barYear );
            }
            if(bar.Mar_Revenue_Amount__c>0) { 
                barMonth = '3'; 
                barYear = bar.Financial_Year__c; 
                addBarItem( barMonthSet, AccountId, productId, barMonth, barYear );
            }
            if(bar.Apr_Revenue_Amount__c>0) { 
                barMonth = '4'; 
                barYear = bar.Financial_Year__c; 
                addBarItem( barMonthSet, AccountId, productId, barMonth, barYear );
            }
            if(bar.May_Revenue_Amount__c>0) { 
                barMonth = '5'; 
                barYear = bar.Financial_Year__c; 
                addBarItem( barMonthSet, AccountId, productId, barMonth, barYear );
            }
            if(bar.Jun_Revenue_Amount__c>0) { 
                barMonth = '6'; 
                barYear = bar.Financial_Year__c; 
                addBarItem( barMonthSet, AccountId, productId, barMonth, barYear );
            }
            if(bar.Jul_Revenue_Amount__c>0) { 
                barMonth = '7'; 
                barYear = string.valueof( integer.valueof(bar.Financial_Year__c)-1 ); 
                addBarItem( barMonthSet, AccountId, productId, barMonth, barYear );
            }
            if(bar.Aug_Revenue_Amount__c>0) { 
                barMonth = '8'; 
                barYear = string.valueof( integer.valueof(bar.Financial_Year__c)-1 ); 
                addBarItem( barMonthSet, AccountId, productId, barMonth, barYear );
            }
            if(bar.Sep_Revenue_Amount__c>0) { 
                barMonth = '9'; 
                barYear = string.valueof( integer.valueof(bar.Financial_Year__c)-1 ); 
                addBarItem( barMonthSet, AccountId, productId, barMonth, barYear );
            }
            if(bar.Oct_Revenue_Amount__c>0) { 
                barMonth = '10'; 
                barYear = string.valueof( integer.valueof(bar.Financial_Year__c)-1 ); 
                addBarItem( barMonthSet, AccountId, productId, barMonth, barYear );
            }
            if(bar.Nov_Revenue_Amount__c>0) { 
                barMonth = '11'; 
                barYear = string.valueof( integer.valueof(bar.Financial_Year__c)-1 ); 
                addBarItem( barMonthSet, AccountId, productId, barMonth, barYear );
            }
            if(bar.Dec_Revenue_Amount__c>0) { 
                barMonth = '12'; 
                barYear = string.valueof( integer.valueof(bar.Financial_Year__c)-1 ); 
                addBarItem( barMonthSet, AccountId, productId, barMonth, barYear );
            }
        } 
    }

    public static string validateClassification( Set<String> barMonthSet, OpportunityLineItem OptyItem )
    {
        // Valid classification values are - Renewal, Growth, New Business, New Business - One Off, Cross Sell, Win Back
        String returnErrorString = '';
        Date dateItem;    // Date to start lookback.
        Integer monthsCountback;     // Number of months to count back.

        // If it is Renewal or Win Back, look at the previous 12 months prior to the Revenue Start Date on the Line Item.
        if( OptyItem.Classification__c=='Renewal' || OptyItem.Classification__c=='Win Back' )
        {
            dateItem = OptyItem.Contract_Start_Date__c;
            monthsCountback=12;
        }

        // If it is New Business, Cross Sell, Growth or look back to 2011 from the Opportunity Close Date
        if( OptyItem.Classification__c=='New Business' || OptyItem.Classification__c=='New Business - One Off' ||
            OptyItem.Classification__c=='Cross Sell' || OptyItem.Classification__c=='Growth' )
        {
            dateItem = OptyItem.Opportunity.CloseDate;
            monthsCountback=999;
        }
        
        // Lookback from the prior month only.
        Integer itemYear = dateItem.year();
        Integer itemMonth = dateItem.month();
            
        if(itemMonth == 1) 
        {
            itemMonth = 12;
            itemYear--;
        }
        else itemMonth--;

        Boolean revenueFound = false;
        String checkUniqueId='';
        
        for(Integer countback = 0; countback < monthsCountback; countback++){
            // If it is New Business then look for revenue on ANY product, otherwise look for specific product revenue.
            if(OptyItem.Classification__c=='New Business' || OptyItem.Classification__c=='New Business - One Off')
            {
                checkUniqueId = OptyItem.Opportunity.AccountId + ':X:' + string.valueof(itemYear) + ':' +  string.valueof(itemMonth); 
            }
            else checkUniqueId = OptyItem.Opportunity.AccountId + ':' + OptyItem.PricebookEntry.Product2Id + ':' + string.valueof(itemYear) + ':' +  string.valueof(itemMonth); 
            
            if(barMonthSet.contains(checkUniqueId)) {
                revenueFound = true;
                break;
            }

            // Loop back through the months.
            if(itemMonth == 1) 
            {
                itemMonth = 12;
                itemYear--;
            }
            else itemMonth--;

            // Stop looping at 06/2010, as there is no revenue loaded before this year.
            if(itemYear==2010 && itemMonth==6)break;
        }

        /***** NOW PERFORM THE VALIDATIONS *****/                        
        // Revenue must not be found for Win Back.
        if(OptyItem.Classification__c=='Win Back' && revenueFound ){
            returnErrorString += 'OPC Error - product \''+ OptyItem.PricebookEntry.Name + '\' incorrectly classified as Win Back (revenue found for this product in the last ' + monthsCountback + ' months).';
        }

        // Revenue must be found for Renewal.
        if(OptyItem.Classification__c=='Renewal' && !revenueFound){
            returnErrorString += 'OPC Error - product \''+ OptyItem.PricebookEntry.Name + '\' incorrectly classified as Renewal (revenue not found for this product in last ' + monthsCountback + ' months).';
        }
        
        // If it is Cross Sell, raise exception if any revenue for this particular product is found.
        if( OptyItem.Classification__c=='Cross Sell' && revenueFound )
        {
            returnErrorString += 'OPC Error - product \''+ OptyItem.PricebookEntry.Name + '\' incorrectly classified as Cross Sell (revenue found for this product).';
        }

        // If it is Growth, raise exception if any revenue for this particular product is not found.
        if( OptyItem.Classification__c=='Growth' && !revenueFound )
        {
            returnErrorString += 'OPC Error - product \''+ OptyItem.PricebookEntry.Name + '\' incorrectly classified as Growth (revenue not found for this product).';
        }

        // If it is New Business, raise exception if any existing revenue is found.
        if( (OptyItem.Classification__c=='New Business' || OptyItem.Classification__c=='New Business - One Off') && revenueFound)
        {
            returnErrorString += 'OPC Error - product \''+ OptyItem.PricebookEntry.Name + '\' incorrectly classified as New Business (revenue exists for this account).';
        }

        return returnErrorString;     
    }
}