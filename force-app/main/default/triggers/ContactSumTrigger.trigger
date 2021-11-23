/* Provide summary of Count of Inactive Contacts, 
                      Count of No Email Contacts, 
                      Count of No Job Title Contacts,
                      Count of No Phone/Mobile Contacts
                      Count of Managed Contacts
                      Count of Electronic Email Opted in contacts
                      Total count of all contacts
 on Account record      Eric Shen    05/06/2015  
 
 Nandan Narasappa   18/08/2015  Revise the trigger to enable bulk load handling. 
 Davey Yu           12/08/206   MPB - Add MPB Filter during insert operations only
 
  */  

trigger ContactSumTrigger on Contact(after delete, after insert, after undelete, after update){
    if (!SystemSettings__c.getInstance().Disable_ContactSumTrigger__c) {
        /*** START OF UPDATE DYU MPB 12-AUG-2016 -  Validate if MPB Account  ***/
        List<Contact> contactList = new List<Contact>();
        if(!trigger.isDelete) {
            contactList = ContactUtility.mpbFilter(trigger.new, trigger.isInsert);
            if(contactList.size() > 0)
              ContactSumTriggerHelper.rollUpFields(Trigger.new,Trigger.oldMap);
        }
        else {
            ContactSumTriggerHelper.rollUpFields(Trigger.new,Trigger.oldMap);
        }
        /*** END OF UPDATE DYU MPB 12-AUG-2016 ***/
    }
}