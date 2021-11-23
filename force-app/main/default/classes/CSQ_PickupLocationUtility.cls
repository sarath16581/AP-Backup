/*
 * @date 2021-04-10
 * @group Pick_Up Location
 * @tag Pick_Up Location
 * @domain Core
 * @description Apex class for updating Primary Pickup Location using quick action button on UI.
 * @changelog
 * 2021-04-10 - Dheeraj.Mandavilli@auspost.com.au - Created
 * 2021-05-28 - Dheeraj.Mandavilli@auspost.com.au - Added a new method to create pick up location.
 * 2021-07-14 - Seth.heang@auspost.com.au	-	Added inner class under 'without sharing' context to bypass the approval process locking mechanism on CSQ(Master) when updating Pick-up Location(Details)
 */
public with sharing class CSQ_PickupLocationUtility {

    public static List<Pick_Up_Location__c> locRec = new List<Pick_Up_Location__c>();

    @AuraEnabled
    public static boolean getPrimaryPickupLocationDetails(Id opptyId){

        boolean primaryLocFound = false;
        locRec = [SELECT Id,Primary_Pick_Up_Location__c,CSQ__r.Opportunity__c FROM Pick_Up_Location__c where CSQ__r.Opportunity__c =:opptyId and Primary_Pick_Up_Location__c= True];
        System.debug('locRec = ' + locRec);

        if(locRec.Size()>0){
            primaryLocFound = true;
            return primaryLocFound;
        }
        else{
            primaryLocFound = false;
            return primaryLocFound;
        }
    }

    @AuraEnabled
    public static Id getOppId(Id pickupLocId){

        Id oppId;
        locRec = [Select Id,CSQ__r.Opportunity__c from Pick_Up_Location__c where Id=:pickupLocId];
        if(locRec.Size()>0){
            for(Pick_Up_Location__c location:locrec){
                oppId= location.CSQ__r.Opportunity__c;
            }
        }
        System.debug('oppId = ' + oppId);
        //getPrimaryPickupLocationDetails(oppId);
        return oppId;
    }

    /**
     * @description		Used by a LWC button displayed on Pick-up Location record
     * 					Method to set the primary pickup location flag on the current pick-up location 
     * 					and unset the other primary pickup locations under the same parent CSQ, 
     * 					and also update the primary pickup location field on Opportunity.
     * @param			Id of Pick_Up_Location__c, Id of Opportunity
     * @return			boolean: true for successful update, false if encounter error
     */
    @AuraEnabled
    public static boolean updatePickupLocation(Id locRecId,Id oppId) {

        Map<Id, Pick_Up_Location__c> locsUpdateMap = new Map<Id, Pick_Up_Location__c>();
        Map<Id,Opportunity> oppUpdateMap = new Map<Id, Opportunity>();
        boolean updateSuccessful = false;
        try{
            // retrieve all pick-up location records under the same opportunity
            locRec = [SELECT Id,Primary_Pick_Up_Location__c,CSQ__r.Opportunity__c,CSQ__r.Opportunity__r.Primary_Pick_Up_Location__c FROM Pick_Up_Location__c where CSQ__r.Opportunity__c = :oppId];
    
            if (locRec.Size() > 0) {
                for (Pick_Up_Location__c location : locrec) {
                    // unset the flag to false on all pick-up location
                    if (location.Primary_Pick_Up_Location__c == true) {
                        location.Primary_Pick_Up_Location__c = false;
                    }
                    locsUpdateMap.put(location.Id, location);
                    // set the current pick-up location which matches the pickup location ID passed into the method, to true
                    // and update the primary pickup location field on Opportunity with this ID
                    if (location.Id == locRecId && location.Primary_Pick_Up_Location__c == false) {
                        location.Primary_Pick_Up_Location__c = true;
                        location.CSQ__r.Opportunity__r.Primary_Pick_Up_Location__c = locRecId;
                        if(!oppUpdateMap.containsKey(location.CSQ__r.Opportunity__c)){
                            oppUpdateMap.put(location.CSQ__r.Opportunity__c,location.CSQ__r.Opportunity__r);
                        }
                    }
                    locsUpdateMap.put(location.Id, location);    
                }
            }
            // update opportunity field
            if (oppUpdateMap.size() > 0) {
                ApplicationDatabase.getInstance().dmlUpdate(oppUpdateMap.values());
            }
            // update pickup-location using 'without-sharing' context, to bypass approval process locking mechanism on pickup-location(Detail) that inherited from CSQ(Master)
            if (locsUpdateMap.size() > 0) {
                InnerPrimaryPickupLocation saveWithoutSharingContext = new InnerPrimaryPickupLocation();
                saveWithoutSharingContext.overridePrimaryPickupLocation(locsUpdateMap.values());
                updateSuccessful = true;
            }
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return updateSuccessful;
    }

    @AuraEnabled
    public static Id createPickupLocation(Pick_Up_Location__c pickupLocRec) {

        Id pLocId = null;
        system.debug('Record from LWC:::'+pickupLocRec);

        if (pickupLocRec!=null) {
            try{
                insert pickupLocRec;
                system.debug('Record after Insert:::'+pickupLocRec.Id);
                pLocId = pickupLocRec.Id;

            }
            catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }

        }
        system.debug('Record after Insert:::'+pLocId);
        return pLocId;
    }
	/**
     * @description		private Inner Class that is in 'without sharing' context,
     *                  containing a method to perform update DML 
     */
    private without sharing class InnerPrimaryPickupLocation{
        /**
         * @description		Method to perform update DML in 'without sharing context'
         * @param			List<SObject>
         * @return			void
         */
        private void overridePrimaryPickupLocation(List<SObject> updateSObject){
            try{
                ApplicationDatabase.getInstance().dmlUpdate(updateSObject);
            }catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
    }
}