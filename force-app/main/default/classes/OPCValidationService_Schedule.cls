/**************************************************
Type:       Class to schedule OPCValidationService_Schedulable
Purpose:    Obtains BatchJobSettings custom setting values and schedules the OPCValidationService_Schedulable class.
Used By:    RunBatchJobs.cls
History:
--------------------------------------------------
11-Sep-2013  Clinton McIntyre (Salesforce.com)    OPC Rebuild
**************************************************/
public without sharing class OPCValidationService_Schedule {

  public static void scheduleOPCValidation() {
    String hours = BatchJobSettings__c.getInstance().OPC_Validation_Hours__c;
    System.assert(hours != null, 'BatchJobSettings custom setting value for hours is required (* acceptable): ' + hours);

    String minutes = BatchJobSettings__c.getInstance().OPC_Validation_Minutes__c;
    System.assert(minutes != null, 'BatchJobSettings custom setting value for minutes is required (* acceptable): ' + minutes);

    String dayOfWeek = BatchJobSettings__c.getInstance().OPC_Validation_Day_Of_Week__c;
    System.assert(dayOfWeek != null, 'BatchJobSettings custom setting value for dayOfWeek is required (* acceptable): ' + dayOfWeek);
    
    OPCValidationService_Schedulable oftrSchedule = new OPCValidationService_Schedulable();
    String scheduleString = '0 ' + minutes + ' ' + hours + ' ? * ' + dayOfWeek + ' *';
    System.debug('##DEBUG:scheduleString: ' + scheduleString);
    System.schedule('OPCValidationService', scheduleString, oftrSchedule);
  }

}