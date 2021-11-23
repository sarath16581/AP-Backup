global Class toUpdateContactField implements Database.Batchable<sObject>, Database.Stateful{

   global String Query;
   global String email;
   global Map<Id,Contact> toUpdate;

    global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator('select id, APCN__c from Contact where APCN__c != null and APCN__c != \'\' order by LastModifiedDate');
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
     Date to = system.today();
     toUpdate = new Map<Id,Contact>();
     for(sobject s : scope){
        Contact first = (Contact)s;
        Integer i = 0;
        for(Contact c : [select APCN__c, Email from Contact where APCN__c =:first.APCN__c and APCN__c != '' and APCN__c != null and LastModifiedDate != :to order by createdDate ]) {
            if(i>0) {
                c.APCN__c = '';
                if(c.Email == null || c.email =='') {
                    c.Email = '';
                }
                toUpdate.put(c.Id,c);
            } else {
                i++;
            }
        }
     }
     system.debug(toUpdate);
     if(toUpdate.size()>0) {
         update toUpdate.values();
           Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    
            mail.setToAddresses(new String[] {email});
            mail.setReplyTo('shruthi.kunchinadka@bluewolfgroup.com');
            mail.setSenderDisplayName('Batch Processing');
            mail.setSubject('Batch Process Completed');
            mail.setPlainTextBody('Batch Process has completed:'+toUpdate.size()+'\n'+toUpdate);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

   global void finish(Database.BatchableContext BC){
       /**toUpdateContactField t = new toUpdateContactField();
       t.query = 'select id, APCN__c from Contact where APCN__c != null order by LastModifiedDate';
       Database.executeBatch(t);**/
       system.debug(toUpdate);
       
   }
}