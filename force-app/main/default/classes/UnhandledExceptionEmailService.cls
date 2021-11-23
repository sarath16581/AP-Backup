/**
  * @author        Urmi Chatterjee
  * @date          10/10/2013
  * @description   This Class is invoked in the event of an Email being sent due to an Unhandled Exception thrown by any running class and is used to call method from UTIL_LoggingService class to create the ExceptionLog__c record.
  * 
  * This software and all content is the property of ACCENTURE or its licensors, 
  * and is for the internal and confidential use of employees and authorized agents 
  * of ACCENTURE solely for the benefit of ACCENTURE and its affiliates.  
  * The software and contents are protected by copyright, trade secret and patent laws, 
  * and other local and international laws and treaties.  
  * Unauthorized use may subject the user to civil and criminal penalties.  
  * The software contains confidential information of ACCENTURE and its affiliates.  
  * You may not access, use, copy, install, modify, transfer, or distribute this software 
  * (electronically or otherwise), or create any copy, adaptation, transcription, or 
  * derivative thereof, except as expressly authorized by ACCENTURE.  
  * You may not divulge, disclose or communicate to any other third party, any of the 
  * confidential information contained in the software, including the software itself.  
  * ACCENTURE maintains full and exclusive right, title and ownership interest in and 
  * to the software and all copyright, patent, trade secret, trademark and other intellectual 
  * property rights therein.
  *
  */

global class UnhandledExceptionEmailService implements Messaging.InboundEmailHandler {
    
    /**
      * @description       This method fetches the Inbound email and calls the logUnhandledException method from UTIL_LoggingService class, passing it the email to log an ExceptionLog__c record.
      * @param             email A reference to the Messaging.InboundEmail object
      * @param             envelope A reference to the Messaging.InboundEnvelope object
      * @return            Messaging.InboundEmailResult
      * @throws            NA
      */
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope){
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();        
        UTIL_LoggingService.logUnhandledException(email);
        return result;
    }
}