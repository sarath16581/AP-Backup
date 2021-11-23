//PUD ajudd@salesforce.com 18/09/2019 Added to update address fields on booking location
trigger NetworkTrigger on Network__c (after update) {
   NetworkUtil.updateBookingLocationAddress(Trigger.oldMap, Trigger.new); 
}