/**************************************************
Type:       Controller Class for visualforce component DisplayFreightItemsFromJob 
Purpose:    To query all the freight items related to the job created for the case from TIBCO           
History:
--------------------------------------------------
15.02.2019      Anshul Goyal      Created
**************************************************/
public class DisplayFreightItemsFromJobController {
    ///getter-setters
    public string jobId{get;set;}
    
    //getter method for the vf component to get the freight items related to the job
    public List <FreightItem__c > freightItemList{
        get {
                FreightItemList = new List <FreightItem__c >([
                    SELECT Id,Quantity__c,Description_Of_Goods__c,Weight_Kgs__c,Lenght_mm__c,Width_mm__c,Height_mm__c
                    FROM FreightItem__c
                    WHERE Job__c=:jobId]);
                return FreightItemList;
                       
        }
    	set;
	}
}