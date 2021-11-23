/**
* @description 1.Trigger to create or remove/cancel jobs on the creation and update of a booking exception:
*              2.Validate jobs before booking exception creation and prevents a booking exception creation
*                if a job is already available for that date and day
* @changelog
* 2021-08-17 - Arjun Singh - Added before update and before insert trigger event and validation before booking exception creation/update
*/
trigger PUD_Booking_ExceptionTrigger on PUD_Booking_Exception__c (after insert, after update, after delete, before insert, before update) {
    if(Trigger.isBefore){
        if(Trigger.isUpdate || Trigger.isInsert){            
            PUD_Booking_ExceptionUtil.validate(Trigger.new);
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isUpdate || Trigger.isInsert || Trigger.isDelete){
            List<PUD_Booking_Exception__c> bookingExceptionList = new List<PUD_Booking_Exception__c>();
            if(Trigger.isUpdate || Trigger.isInsert){
                for(PUD_Booking_Exception__c bookingEx : Trigger.New){ 
                    bookingExceptionList.add(bookingEx);                              
                }
            }
            if(Trigger.isDelete){
                for(PUD_Booking_Exception__c bookingEx : Trigger.Old){ 
                    bookingExceptionList.add(bookingEx);                              
                }
            }         
            if(bookingExceptionList.size() > 0){
                
                //Call method to refresh jobs impacted by change to booking
        		PUD_Booking_ExceptionUtil.refreshJobs(bookingExceptionList);
            }
        }
    }
}