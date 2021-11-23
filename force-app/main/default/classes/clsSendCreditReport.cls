global class clsSendCreditReport implements Schedulable {
  global void execute(SchedulableContext sc) {

      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      mail.setTemplateId('00XO0000000QZ85');
      mail.setSaveAsActivity(false);
      mail.setTargetObjectId('003O000000KGHpU');
      if(!Test.isRunningTest()) {
      	Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
      }
  }
}