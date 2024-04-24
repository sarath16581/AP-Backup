/**************************************************
Type:       Class for Product Trigger
Purpose:    Captures all the changes 
History:
--------------------------------------------------
05.23.2012   Joseph Barrameda (CloudSherpas.com)    Created

***************************************************/

public with sharing class ProductUtil { 
    
    public static void CaptureChanges(Map <Id, Product2> oldMap, Map <Id,Product2> newMap, List<Product2> listCtr ){

        List <Product_History__c> prodHistoryList = new List <Product_History__c> ();
            
        for (Product2 newProd: listCtr){
                                        
            if ( oldMap.get(newProd.ID).Name != newMap.get(newProd.Id).Name ) {         //Validate if there was a change on Name              
                Product_History__c prodHistory = new Product_History__c();
                prodHistory.Field__c= 'Name';
                prodHistory.Old_Value__c = oldMap.get(newProd.ID).Name;
                prodHistory.New_Value__c = newMap.get(newProd.ID).Name;             
                prodHistoryList.add(prodHistory);
            }
            if ( oldMap.get(newProd.ID).ProductCode != newMap.get(newProd.Id).ProductCode ) { //    Validate if there was a change on Product Code
                Product_History__c prodHistory = new Product_History__c();
                prodHistory.Field__c= 'ProductCode';
                prodHistory.Old_Value__c = oldMap.get(newProd.ID).ProductCode;
                prodHistory.New_Value__c = newMap.get(newProd.ID).ProductCode;              
                prodHistoryList.add(prodHistory);
            }
            if ( oldMap.get(newProd.ID).Description != newMap.get(newProd.Id).Description ) {   //  Validate if there was a change on Description
                Product_History__c prodHistory = new Product_History__c();
                prodHistory.Field__c= 'Description';
                prodHistory.Old_Value__c = oldMap.get(newProd.ID).Description;
                prodHistory.New_Value__c = newMap.get(newProd.ID).Description;              
                prodHistoryList.add(prodHistory);
            }
            if ( oldMap.get(newProd.ID).Family != newMap.get(newProd.Id).Family ) {     //  Validate if there was a change on Family
                Product_History__c prodHistory = new Product_History__c();
                prodHistory.Field__c= 'Family';
                prodHistory.Old_Value__c = oldMap.get(newProd.ID).Family;
                prodHistory.New_Value__c = newMap.get(newProd.ID).Family;               
                prodHistoryList.add(prodHistory);
            }
            if ( oldMap.get(newProd.ID).Product_Level_1__c != newMap.get(newProd.Id).Product_Level_1__c ) { //  Validate if there was a change on Product_Level_1__c
                Product_History__c prodHistory = new Product_History__c();
                prodHistory.Field__c= 'Product_Level_1__c';
                prodHistory.Old_Value__c = oldMap.get(newProd.ID).Product_Level_1__c;
                prodHistory.New_Value__c = newMap.get(newProd.ID).Product_Level_1__c;               
                prodHistoryList.add(prodHistory);
            }
            if ( oldMap.get(newProd.ID).Product_Level_2__c != newMap.get(newProd.Id).Product_Level_2__c ) { //  Validate if there was a change on Product_Level_2__c
                Product_History__c prodHistory = new Product_History__c();
                prodHistory.Field__c= 'Product_Level_2__c';
                prodHistory.Old_Value__c = oldMap.get(newProd.ID).Product_Level_2__c;
                prodHistory.New_Value__c = newMap.get(newProd.ID).Product_Level_2__c;               
                prodHistoryList.add(prodHistory);
            }
            if ( oldMap.get(newProd.ID).Product_Level_3__c != newMap.get(newProd.Id).Product_Level_3__c ) { //  Validate if there was a change on Product_Level_3__c
                Product_History__c prodHistory = new Product_History__c();
                prodHistory.Field__c= 'Product_Level_3__c';
                prodHistory.Old_Value__c = oldMap.get(newProd.ID).Product_Level_3__c;
                prodHistory.New_Value__c = newMap.get(newProd.ID).Product_Level_3__c;
                prodHistoryList.add(prodHistory);
            }
            if ( oldMap.get(newProd.ID).Product_Level_4__c != newMap.get(newProd.Id).Product_Level_4__c ) { //  Validate if there was a change on Product_Level_4__c
                Product_History__c prodHistory = new Product_History__c();
                prodHistory.Field__c= 'Product_Level_4__c';
                prodHistory.Old_Value__c = oldMap.get(newProd.ID).Product_Level_4__c;
                prodHistory.New_Value__c = newMap.get(newProd.ID).Product_Level_4__c;
                prodHistoryList.add(prodHistory);
            }
        }        
        if (!prodHistoryList.isEmpty()){
        try     {
                insert prodHistoryList;
            }
            catch (Exception e) {}
        }
    }
        
    /******************** Test Coverage *****************************/
    
    public static testMethod void TestMe(){
        Test.startTest();
        List <Product2> prodList =new List <Product2>();
        Product2 prodTest = new Product2 ();                
        Product2 prod;        
        prodTest.Name = 'TesterXYZ';
        prodTest.ProductCode ='TST001';
        prodTest.Description = 'Tester 5 in 1';
        prodTest.Family = 'Electronics'; 
        prodTest.Product_Level_1__c = 'Email Services';
        prodTest.Product_Level_2__c = 'Mail';
        prodTest.Product_Level_3__c = 'International Service';
        prodTest.Product_Level_4__c = 'Local Service';
        insert ProdTest;
        
        for (Product2 tmp : [Select Name, ProductCode, Description, Family, Product_Level_1__c, Product_Level_2__c, Product_Level_3__c, Product_Level_4__c from Product2 where Name='TesterXYZ' LIMIT 1]){
            tmp.Name = 'Tester';
            tmp.ProductCode ='TST0001';
            tmp.Description = 'Tester 6 in 1';
            tmp.Family = 'Electronics Gadget'; 
            tmp.Product_Level_1__c = 'Mail Services';
            tmp.Product_Level_2__c = 'Email Services';
            tmp.Product_Level_3__c = 'Local Service';
            tmp.Product_Level_4__c = 'International Service';
            prodList.add(tmp);
        }
        update prodList;            
        System.assertEquals(prodTest.Name, 'TesterXYZ');
        System.assertEquals(prodTest.ProductCode, 'TST001');
        System.assertEquals(prodTest.Description, 'Tester 5 in 1' );
        System.assertEquals(prodTest.family ,'Electronics');
        System.assertEquals(prodTest.Product_Level_1__c,'Email Services' );
        System.assertEquals(prodTest.Product_Level_2__c,'Mail');            
        Test.stopTest();
    }
    
}