/**************************************************
Type:       Test Class for Apex class "DisplayFreightItemsFromJobController" 
Purpose:    To test the the freight items fetched and retrieved in the apex class without exception          
History:
--------------------------------------------------
15.02.2019      Anshul Goyal      Created
**************************************************/
@isTest(SeeAllData=false)
public class DisplayFreightItemsFromJobCont_Test {
	@testSetup static void setup() {
           
    }
    
    static testmethod void testgetFreightItemList(){
    	Test.startTest();
            
            DisplayFreightItemsFromJobController contObj = new DisplayFreightItemsFromJobController();
            List <FreightItem__c>  freightList = new List <FreightItem__c>(contObj.freightItemList);
            System.assertNotEquals(freightList, null); 
        
        Test.stopTest();        
    } 
    
}