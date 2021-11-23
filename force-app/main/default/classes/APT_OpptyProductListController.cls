/**
Description: This apex class containing the server side actions/methods for oppProductDataTable(lwc).
Created By: Mathew Jose
Created Date: 21st March, 2021
*/
public with sharing class APT_OpptyProductListController {
    /*Description : Method to retrieve Opportunitylineitems under a given opportunity 
     Which are then presented in a lightning datatable.
    */
    @AuraEnabled(cacheable=true) 
    public static List<OpportunityLineItem> getOpptyProducts(Id oppId){        
        return [Select Id, Contract_Start_Date__c, Contract_End_Date__c, Product2.Name,
                Opportunity.Name, 
                Contract_Product__c, Change_Classification__c,
                Classification__c,Quantity,UnitPrice,TotalPrice,Contract_Number__c 
                from OpportunityLineItem where OpportunityId = : oppId ] ;                 
    }

    /*Description : Method to update a list of Opportunitylineitems leveraging saveresult.
     A JSON string is returned with the status of the update as well as details of errors if any.
    */
    @AuraEnabled
    public static string updateOppProducts(List<OpportunityLineItem> oppProds ){
        Database.SaveResult[] srList = Database.update(oppProds, false);        
        // Iterate through each returned result
        Errors err = new Errors();
        List<RowError> rows = new List<RowError>();
        TableError table = new TableError();
        Set<String>tableErrorMessages = new Set<String>();
        Integer errorCount = 0;
        for(Integer i=0;i<srList.size();i++){
            System.debug('Id'+srList[i].getId());
            if (srList[i].isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted Opp Prod ID: ' + srList[i].getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error er : srList[i].getErrors()) { 
                    errorCount++;
                    RowError row = new RowError();
                    List<String> messageList = new List<String>();
                    messageList.add(er.getMessage());
                    row.rowId = oppProds[i].Id;
                    //row.title = er.getStatusCode() + ': ' + er.getMessage();
                    row.title = 'Error!!' ;
                    row.fieldNames = er.getFields();
                    row.errorMessages = messageList;
                    System.debug(er.getStatusCode() + ': ' + er.getMessage());
                    rows.add(row);
                    tableErrorMessages.addAll(messageList);
                }
            }
        }
        if(errorCount > 0){
            err.status = 'Errors';
            table.title = 'We found '+errorCount+' errors';
            table.errorMessages = new List<String>(tableErrorMessages);
            err.rows = rows;
            err.table = table;
        }else{
            err.status = 'Success';
        }
        return JSON.serialize(err);

    }
    //Wrapper class used to determine the error type accepted by lightning datatable.
    Public class Errors{
        Public String status;
        Public RowError[] rows;
        Public TableError table;
    }

    Public class RowError{
        Public String rowId;
        Public String title;
        Public String[] fieldNames;
        Public String[] errorMessages;        
    }
    Public class TableError{
        Public String title;
        Public String[] errorMessages;        
    }
}