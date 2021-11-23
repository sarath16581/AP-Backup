/**************************************************
Type:       Trigger Handler for Product2 Object
Purpose:    Handle Triggers for the Product2 Object for a cleaner code coverage
--------------------------------------------------
August 3, 2018 - Created by conrad.c.v.borbon
**************************************************/
public class ProductTriggerHandler {
    public static void ProductAfterUpdate(list<Product2> oldProdList, list<Product2> newProdList) {
        // Created by conrad.c.v.borbon - August 3, 2018 - START
        List<Opportunity> updateOpptyList = new List<Opportunity>();
        
        for(Product2 newProd : newProdList) {
            for(Product2 oldProd : oldProdList) {
                if (newProd.ID == oldProd.ID)
                {
                    if(newProd.Is_Exception_Product__c != oldProd.Is_Exception_Product__c)
                    {
                        // Select the related opportunities to the product 
                        List<Opportunity> opptyList = new List<Opportunity>([SELECT Id, Product_Complexity_Rating__C, hidden_Complex_Product_Counter__C FROM Opportunity WHERE Id In (SELECT OpportunityId FROM OpportunityLineItem WHERE Product2.ID = :newProd.ID)]);
                        for (Opportunity updOppty: opptyList)
                        {
                            // If the new value for the Is Exception Product is true, add one to the complex product counter and change the product complexity rating to 3
                            if(newProd.Is_Exception_Product__c)
                            {
                                updOppty.hidden_Complex_Product_Counter__C += 1;
                                if(updOppty.Product_Complexity_Rating__C == 0)
                                {
                                    updOppty.Product_Complexity_Rating__C = 3;
                                }
                            }
                            else
                            {
                                // If the new value for the Is Exception Product is false, subtract one to the complex product counter and change the product complexity rating to 0
                                // if the complex product counter becomes 0
                                if(updOppty.hidden_Complex_Product_Counter__C != null) {
                                    updOppty.hidden_Complex_Product_Counter__C -= 1;
                                }
                                else
                                {
                                    updOppty.hidden_Complex_Product_Counter__C = 0;
                                }
                                if(updOppty.Product_Complexity_Rating__C != 0)
                                {
                                    if (updOppty.hidden_Complex_Product_Counter__C == 0)
                                        updOppty.Product_Complexity_Rating__C = 0;
                                }
                            }
                            updateOpptyList.add(updOppty);
                        }
                    }
                }
            }
        }
        If(updateOpptyList.size()>0){
            update updateOpptyList;  
        }	
        // Created by conrad.c.v.borbon - August 3, 2018 - END
    }
}