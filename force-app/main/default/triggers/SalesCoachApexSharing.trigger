/* 
## Tigger Title: Sales Mnanager Coaching Trigger 
## Created by: Wayne.Helena@Accenture.com
## Date Creatd: 19 June 2017
## Purpose: Trigger inserts read access to the sales coaching record for the caoching receiver as well as the coaching receiver's Manager
 */
 
trigger SalesCoachApexSharing on Sales_Coaching__c (after insert) {
    
    if(trigger.isInsert){
        // Create a new list of sharing objects for Job
        List<Sales_Coaching__Share> CoShrs  = new List<Sales_Coaching__Share>();
        
        // Declare variables for recruiting and hiring manager sharing
        Sales_Coaching__Share ReceiverShr;
        Sales_Coaching__Share ReceiverManagerShr;
        
        for(Sales_Coaching__c SalesCoaching: trigger.new){
            // Instantiate the sharing objects
            ReceiverShr = new Sales_Coaching__Share();
            ReceiverManagerShr = new Sales_Coaching__Share();
            
            // Set the ID of record being shared
            ReceiverShr.ParentId = SalesCoaching.Id;
            ReceiverManagerShr.parentid = SalesCoaching.Id;
           
            
            // Set the ID of user or group being granted access
            ReceiverShr.UserOrGroupId = SalesCoaching.CoachingReceiver__c;
            ReceiverManagerShr.UserOrGroupId = SalesCoaching.CoachingReceiverManagerID__c;
            
            // Set the access level
            ReceiverShr.AccessLevel = 'read';
            ReceiverManagerShr.AccessLevel = 'read';
            
            // Set the Apex sharing reason for hiring manager and recruiter
            ReceiverShr.RowCause = Schema.Sales_Coaching__Share.RowCause.ReceiverShr__c;
            ReceiverManagerShr.RowCause = Schema.Sales_Coaching__Share.RowCause.ReceiverManagerShr__c;

            
            
            // Add objects to list for insert
            CoShrs.add(ReceiverShr);
            CoShrs.add(ReceiverManagerShr);
            
        }
        
        // Insert sharing records and capture save result 
        // The false parameter allows for partial processing if multiple records are passed 
        // into the operation 
        Database.SaveResult[] lsr = Database.insert(CoShrs,false);
        
        // Create counter
        Integer i=0;
        
        // Process the save results
        for(Database.SaveResult sr : lsr){
            if(!sr.isSuccess()){
                // Get the first save result error
                Database.Error err = sr.getErrors()[0];
                
                // Check if the error is related to a trivial access level
                // Access levels equal or more permissive than the object's default 
                // access level are not allowed. 
                // These sharing records are not required and thus an insert exception is 
                // acceptable. 
                if(!(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  
                                               &&  err.getMessage().contains('AccessLevel'))){
                    // Throw an error when the error is not related to trivial access level.
                    trigger.newMap.get(CoShrs[i].ParentId).
                      addError(
                       'Unable to grant sharing access due to following exception: '
                       + err.getMessage());
                }
            }
            i++;
        }   
    }
    
}