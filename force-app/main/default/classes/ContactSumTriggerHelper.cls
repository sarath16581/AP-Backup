/**************************************************
Description:    Count number of Contacts for a Account

History:
--------------------------------------------------
2015-08-18  Nandan.Narasappa@auspost.com.au     used by ContactSumTrigger
2015-09-01  Eric.Shen@auspost.com.au            add 'Left organisation option' to calculate inactive contacts
2015-09-23  Eric.Shen@auspost.com.au            add 'all contacts'
2018-06-06  clint.dsilva@auspost.com.au        Replace functionality of default social contact to default dummy social post

**************************************************/


public without sharing class ContactSumTriggerHelper{   
    
    // Constants
    private static final String ROLLUP_ERROR_MSG = 'Error occured in roll-up calculation. Please contact system administrator';
    private static final String STATUS_ACTIVE = 'Active';
    private static final String STATUS_INACTIVE = 'Inactive';
    private static final String STATUS_LEAVE = 'Left Organisation';
    private static final String ACCOUNT_MANAGER = 'Account Manager';
    private static final String SOCIAL_PROF = 'SSSW Social Integration';
    
    private static final Id SOCIAL_PROF_ID;
    
    static{
        if(SOCIAL_PROF_ID == null){
            try{
                SOCIAL_PROF_ID = [SELECT Id,Name FROM PROFILE WHERE Name =: SOCIAL_PROF LIMIT 1].Id;
            }
            catch(Exception exp){
                SOCIAL_PROF_ID = Label.SOCIAL_PROF_ID;
            }
        }
    }
    /**
      * @description       method to get the default account to be attached to each persona
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public static string  getDefaultAccountId() {
        string accountName = system.label.socialAccountName;
        string accountId = null;

        try {
            accountId =  [select Id from account where name = :accountName limit 1].Id;
            System.debug('** accountId ==>'+accountId);
        }
        catch(exception e) {}
        return accountId;
    }

    /**
      * @description       This method calculates total active &inactive contacts, managed contacts,
                           contacts with no phone, title & also contacts opted for email
      * @param             emailMsgList - List<EmailMessage>
      * @return            Void
      * @throws            Method might throw exception which is handled by Try-Catch block
      */ 
    public static void rollUpFields(List<Contact> newContList,Map<Id,Contact> oldConMap){
        Set<Id> accIds = new Set<Id>();                     // variable to store account ids
        Map<Id,List<Contact>> accMap = new Map<Id,List<Contact>>();
        Integer rowLimit = Limits.getLimitQueryRows() - Limits.getQueryRows();

        try{
            if(SOCIAL_PROF_ID != UserInfo.getProfileId()){  // by pass contacts created by social user
                // verify if contact list has values
                if((newContList != null && !newContList.isEmpty()) || (newContList == null && !oldConMap.isEmpty())){
                    List<Contact> tmpNewContList = newContList != null ?  newContList : oldConMap.values();

                    for(Contact con : tmpNewContList){
                        if(!con.IsPersonAccount && con.AccountId != null){
                            accIds.add(con.AccountId);
                        }
                        // To handle contact moved from one org to another
                        if(oldConMap != null && !oldConMap.isEmpty() && oldConMap.get(con.Id) != null 
                            && oldConMap.get(con.Id).AccountId != null && con.AccountId != oldConMap.get(con.Id).AccountId ){
                            accIds.add(oldConMap.get(con.Id).AccountId);
                        }
                    }

                    List<Contact> tmpConList = new List<Contact>();
                    List<Account> accList = new List<Account>();
                    
                    if(!accIds.isEmpty()){
                        // exclude social account contacts
                        string socialAcId = getDefaultAccountId();
                        // Fetch all contacts associated to account
                        for(Contact con : [SELECT AccountId,Status__c,Email,Title,Phone,MobilePhone,Record_Maintainer__c,Email_Electronic_Opt_In__c 
                                            FROM Contact WHERE Accountid != :socialAcId and AccountId IN: accIds LIMIT : rowLimit]){
                            tmpConList = new List<Contact>();
                            if(accMap.containsKey(con.AccountId)){
                                tmpConList = accMap.get(con.AccountId);
                                tmpConList.add(con);
                            }
                            else{
                                tmpConList.add(con);
                            }
                            accMap.put(con.AccountId,tmpConList);
                        }

                        // check if account map has values
                        if(!accMap.isEmpty()){
                            for(Id accId : accMap.keyset()){
                                Set<Contact> allContacts= new Set<Contact>();   //Eric Shen 23-Sep-15 add all contacts count
                                Set<Contact> activeContacts = new Set<Contact>();   
                                Set<Contact> inactiveContacts = new Set<Contact>();
                                Set<Contact> noEmailContacts = new Set<Contact>();
                                Set<Contact> managedContacts = new Set<Contact>();
                                Set<Contact> noTitleContacts = new Set<Contact>();
                                Set<Contact> noPhoneContacts = new Set<Contact>();
                                Set<Contact> emailOptInContacts = new Set<Contact>();
                                
                                if(accId != null){
                                    for(Contact con : accMap.get(accId)){    // iterate through contacts associated to account
                                                
                                              allContacts.add(con);     //Eric Shen 23-Sep-15 add all contacts count
                                                 
                                        if(!String.isBlank(con.Status__c)){
                                            if(STATUS_ACTIVE.equalsIgnorecase(con.Status__c)){  // verify if status is active
                                                activeContacts.add(con);
                                            }
                                        }
                                        
                                        // verify if contacts are managed
                                        if(!String.isBlank(con.Record_Maintainer__c) 
                                            && ACCOUNT_MANAGER.equalsIgnorecase(con.Record_Maintainer__c)){
                                            
                                            managedContacts.add(con);
                                            
                                            if(STATUS_INACTIVE.equalsIgnorecase(con.Status__c)|| STATUS_LEAVE.equalsIgnorecase(con.Status__c)){    // verify if status is inactive //01-sep-15 Eric Shen add 'leave organisation' into the count
                                                inactiveContacts.add(con);
                                            }
                                            
                                            if(String.isBlank(con.Email)){  // verify if contact has email
                                                noEmailContacts.add(con);
                                            }
                                            
                                            if(String.isBlank(con.Title)){  // verify if contact has title
                                                noTitleContacts.add(con);
                                            }
                                            
                                            // verify if contact has phone
                                            if(String.isBlank(con.Phone) && String.isBlank(con.MobilePhone)){
                                                noPhoneContacts.add(con);
                                            }
                                            
                                            // verify if contact has opted for Email
                                            if(String.isBlank(con.Email_Electronic_Opt_In__c)){
                                                emailOptInContacts.add(con);
                                            }
                                        }
                                    }
                                    
                                    Account acc = new Account(Id = accId);
                                    acc.All_Contacts__c = allContacts.size();                       //Eric Shen 23-Sep-15 add all contacts count
                                    acc.Total_No_of_Contacts__c = activeContacts.size();
                                    acc.Count_of_Inactive_Contacts__c = inactiveContacts.size();
                                    acc.Count_of_No_Email_Contacts__c = noEmailContacts.size();
                                    acc.Count_of_No_Job_Title_Contact__c = noTitleContacts.size();
                                    acc.Count_of_No_Phone_Mobile_Contacts__c = noPhoneContacts.size();
                                    acc.Count_of_Managed_Contacts__c = managedContacts.size();
                                    acc.Count_of_Email_Opted_In__c = emailOptInContacts.size();
                                    accList.add(acc);
                                }
                            }
                            if(!accList.isEmpty()){
                                Database.update(accList);
                            }
                        }
                    }
                }
            }
        }
        catch(Exception exp){
            for(Contact con : newContList){
                //con.addError(ROLLUP_ERROR_MSG);
                con.addError(exp);
            }
        }
    }
}