/**
 * Date            Version          Owner               Desription
 * 07-Mar-17        1.0             Adrian A            Test data builder for I2C implementation
 */
public class I2CTestDataBuilder {
     /* Method to Create Case Data */
	 public static Case createCase(){
        RecordType recType = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Case' 
                              AND Name = 'Enterprise Credit Dispute Claim' LIMIT 1];
   		Case caseVar = new Case();
        caseVar.Status = 'New';
        caseVar.RecordTypeId = recType.Id;
        caseVar.Business_Unit__c = 'Australia Post';
        caseVar.Enquiry_Type__c = 'Billing';
        caseVar.Origin = 'Phone';
        caseVar.Name__c = 'Case Test Billing';
        caseVar.Email_Address__c = 'test@test.com';
        return caseVar;    
    }
	
    /* Method to Create List of Disputed Items Data */
    public static List<Disputed_Item__c> createDisputeItem(Case pCaseVar){
        List<Disputed_Item__c> listDisputedItems = new List<Disputed_Item__c>();

        // Parcel
        Disputed_Item__c disputedItemParcel = new Disputed_Item__c();
        disputedItemParcel.Case__c = pCaseVar.Id;
        disputedItemParcel.Product__c = 'Parcels';
        disputedItemParcel.Product_Desciption__c = 'Test Parcels Dispute';
        disputedItemParcel.Disputed_Reason__c = 'Duplicate Billing';
        disputedItemParcel.Service_Date__c = Date.newInstance(2017, 02, 09);
        disputedItemParcel.Type__c = 'Non-Discretionary';
        listDisputedItems.add(disputedItemParcel);

        // letter
        Disputed_Item__c disputedItemLetter = new Disputed_Item__c();
        disputedItemLetter.Case__c = pCaseVar.Id;
        disputedItemLetter.Product__c = 'Letters';
        disputedItemLetter.Product_Desciption__c = 'Test Letters Dispute';
        disputedItemLetter.Disputed_Reason__c = 'Incorrect Product';
        disputedItemLetter.Service_Date__c = Date.newInstance(2017, 02, 09);
        disputedItemLetter.Type__c = 'Non-Discretionary';
        listDisputedItems.add(disputedItemLetter);

        // Trusted Services
        Disputed_Item__c disputedItemTS = new Disputed_Item__c();
        disputedItemTS.Case__c = pCaseVar.Id;
        disputedItemTS.Product__c = 'Trusted Services';
        disputedItemTS.Product_Desciption__c = 'Test TS Dispute';
        disputedItemTS.Disputed_Reason__c = 'Incorrect Product';
        disputedItemTS.Service_Date__c = Date.newInstance(2017, 02, 09);
        disputedItemTS.Type__c = 'Non-Discretionary';
        listDisputedItems.add(disputedItemTS);

        // Road
        Disputed_Item__c disputedItemRoad = new Disputed_Item__c();
        disputedItemRoad.Case__c = pCaseVar.Id;
        disputedItemRoad.Product__c = 'Road';
        disputedItemRoad.Product_Desciption__c = 'Test Road Dispute';
        disputedItemRoad.Disputed_Reason__c = 'Incorrect Product';
        disputedItemRoad.Service_Date__c = Date.newInstance(2017, 02, 09);
        disputedItemRoad.Type__c = 'Non-Discretionary';
        listDisputedItems.add(disputedItemRoad);

        // Air
        Disputed_Item__c disputedItemAir = new Disputed_Item__c();
        disputedItemAir.Case__c = pCaseVar.Id;
        disputedItemAir.Product__c = 'Air';
        disputedItemAir.Product_Desciption__c = 'Test Air Dispute';
        disputedItemAir.Disputed_Reason__c = 'Incorrect Product';
        disputedItemAir.Service_Date__c = Date.newInstance(2017, 02, 09);
        disputedItemAir.Type__c = 'Non-Discretionary';
        listDisputedItems.add(disputedItemAir);

        return listDisputedItems;
    }
}