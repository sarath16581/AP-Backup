/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 31/03/2017
  * @description  : Handler for Trigger for network response object to handle various events and action accordingly.
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    
*******************************  History ************************************************/
public class NetworkResponseTriggerHandler {

     /**
      * @description       This method is invoked from trigger which in-turn calls the handlers
                           for before and after event.
      * @param             NA 
      * @return            Void
      * @throws            NA
      */        
     public static void execute(){
        if(!System.isFuture()){
            if(Trigger.isBefore){
                beforeHandler();        // invoke of before handler
            }
            else if(Trigger.isAfter){
                afterHandler();         // invoke of after handler
            }
        }
     }
         
      private static void beforeHandler(){
         // NetworkResponseTriggerHelper.manageResponses(trigger.new);
      }
      
      private static void afterHandler(){
         NetworkResponseTriggerHelper.manageResponses(trigger.new);
      }

}