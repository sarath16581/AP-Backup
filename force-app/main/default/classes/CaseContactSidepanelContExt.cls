/**************************************************
Type:       Visualforce controller
Purpose:    Provides the controller logic to create the fields on the page from a field set and 
            the bottom tabs dynamically based on a custom setting
Used By:    CaseContactSidepanel.page         
History:
--------------------------------------------------
18.12.2013  Mohamed.Atheek@bluewolf.com      Created           
20.05.2016  eugene.jandusay@auspost.com.au   Updated save method to be similar with the myCustomer search logic regarding account name 
26.09.2016  nandan.narasappa@auspost.com.au  Replaced strAccountName != '' with String.isNotEmpty(strAccountName) in save method
26 May 2017 dion.gunn@auspost.com.au         Added logic to handle duplicate DML errors with new Duplicate Checking rules.
18 Aug 2017	dilshan.egodawela@auspost.com.au added verified name and verified mobile as readonly fields.
06 Jun 2018 clint.dsilva@auspost.com.au      added ability to handle nulls account on page
20 Aug 2018 nanda.kothamasu@auspost.com.au	 Fix the FIND search string with special char as per INC1132653
10 May 2021	Madhuri.awasthi@auspost.com.au			Add a preferred name field in contact areas of Salesforce (REQ2476162)
**************************************************/

public with sharing class CaseContactSidepanelContExt {
    private Case caseRec;
    private Boolean newContact = false;
    private Account associatedPersonAccount = null;
    public AddressExtension mailingAddress { get; set; }
    public Contact caseContact { get; set; }
    public String strCustomerType { get; set; }
    public String strAccountNumber { get; set; }
    public String strAccountName { get; set; }
    public Boolean showAccName { get; set; }
    public Boolean isReadOnly { get; set; }
    public Boolean isEditable { get; set; }
    public Boolean lockFields { get; set; }
    

    private static final String ANY_VAL = '- Any -';
    private static final String WHITE_SPACE = '';
    private static final String CUSTOMER_TYPE_FLD = 'CustomerType__c';

    // Get Customer Type Picklist values from Account
    public List<SelectOption> getCustomerTypes() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(WHITE_SPACE, ANY_VAL));
        Map<String, Schema.SObjectField> fieldMap = Account.sObjectType.getDescribe().fields.getMap();
        // Schema describe for customer type picklist 
        for (Schema.PicklistEntry pickEntry : fieldMap.get(CUSTOMER_TYPE_FLD).getDescribe().getPickListValues()) {
            options.add(new SelectOption(pickEntry.getValue(), pickEntry.getLabel()));
        }
        return options;
    }


    public CaseContactSidepanelContExt(ApexPages.StandardController stdController) {
        showAccName = true;

        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String>{
                    'ContactId', 'RecordTypeid'
            });
        }
        caseRec = (Case) stdController.getRecord();
        
        system.debug('caseRec.ContactId -'+caseRec.ContactId);

        if (caseRec.ContactId != null) {
            isEditable = false;
            caseContact = loadCaseContact(caseRec.contactId);
            //hat to get account name from a different query so that we can update person accounts.
            //adding the Account.Name on the main contact query will fire an error
            List<Contact> conList = [Select Account.Name,Account.LevelOfAssurance__pc FROM Contact WHERE ID = :caseContact.Id];
            system.debug('conList[0].Account.Name -'+conList[0].Account.Name);
            
            if (caseContact.IsPersonAccount) {
                showAccName = false;
                isReadOnly = false;
				lockFields = true;
            } else {

                isReadOnly = true;
            }
            strAccountName =  strAccountName == null? '': strAccountName;
            if (conList.size() > 0) {
                strAccountName = conList[0].Account.Name;
            }

            if (caseContact != null) {
                mailingAddress = new AddressExtension(caseContact.MailingStreet, caseContact.MailingStreet2__c, caseContact.MailingCity, caseContact.MailingState, caseContact.MailingPostalCode, caseContact.MailingDPID__c, caseContact.MailingCountry);
            }

            List<Account> accs = [SELECT Id,Name FROM Account WHERE PersonContactId = :caseRec.ContactId];
            if (!accs.isEmpty()) {
                associatedPersonAccount = accs[0];

            }

        }

        if (caseContact == null) {
            caseContact = new Contact();
            newContact = true;
            mailingAddress = new AddressExtension();
            isReadOnly = false;
            isEditable = true;
        }
    }

    public Boolean ErrorsPresent {
        get {
            System.debug('---hasMessages(): ' + ApexPages.hasMessages());
            return ApexPages.hasMessages();
        }
    }

    Contact loadCaseContact(id contactId) {
        string query = 'select ';
        for (Schema.FieldSetMember f : Schema.SObjectType.Contact.fieldSets.CaseContactDetails.getFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += 'IsPersonAccount,LegalFirstName__c,LegalLastName__c,VerifiedMobile__c,MailingCity,MailingDPID__c,MailingPostalCode,MailingState,MailingStreet,MailingStreet2__c,MailingCountry FROM Contact WHERE Id=:contactId';
        List<Contact> contList = Database.query(query);
        return contList.isEmpty() ? null : contList[0];
    }

    public Component.Apex.OutputPanel getTabs() {
        List<CaseContactSidePanelTabSettings__c> tabSettings = sortList(CaseContactSidePanelTabSettings__c.getAll().values());

        Component.Apex.OutputPanel tabContainer = new Component.Apex.OutputPanel();
        String tabNavsMarkup = '<ul class="nav nav-tabs">';

        for (Integer i = 0; i < tabSettings.size(); i++) {
            if (!tabSettings[i].HideTab__c) {
                tabNavsMarkup += '<li class="' + (i == 0 ? 'active' : '') +
                        '"><a href="#tab' + i + '" data-toggle="tab">' + tabSettings[i].TabLabel__c + '</a></li>';
            }
        }
        tabNavsMarkup += '</ul>';
        Component.Apex.OutputText tabNavs = new Component.Apex.OutputText();
        tabNavs.value = tabNavsMarkup;
        tabNavs.escape = false;
        tabContainer.childComponents.add(tabNavs);

        Component.Apex.OutputText tabPanStart = new Component.Apex.OutputText();
        tabPanStart.value = '<div class="tab-content">';
        tabPanStart.escape = false;
        tabContainer.childComponents.add(tabPanStart);

        for (Integer i = 0; i < tabSettings.size(); i++) {
            if (!tabSettings[i].HideTab__c) {
                Component.Apex.OutputText tabStart = new Component.Apex.OutputText();
                tabStart.value = i == 0 ? '<div class="tab-pane fade in active" id="tab0">' : '<div class="tab-pane fade" id="tab' + i + '">';
                tabStart.escape = false;
                tabContainer.childComponents.add(tabStart);

                tabContainer.childComponents.add(createTab(tabSettings[i]));

                Component.Apex.OutputText tabEnd = new Component.Apex.OutputText();
                tabEnd.value = '</div>';
                tabEnd.escape = false;
                tabContainer.childComponents.add(tabEnd);
            }
        }


        Component.Apex.OutputText tabPanEnd = new Component.Apex.OutputText();
        tabPanEnd.value = '</div>';
        tabPanEnd.escape = false;
        tabContainer.childComponents.add(tabPanEnd);

        return tabContainer;
    }

    public String mapURL {
        get {
            String contAddr = getContactAddressForMap();

            String value = 'http://maps.googleapis.com/maps/api/staticmap?center=' +
                    contAddr + '&markers=' + contAddr + '&zoom=15&size=300x300&sensor=false';

            return value;
        }
        set;
    }

    private String getContactAddressForMap() {
        String addr = string.isEmpty(caseContact.MailingStreet) ? '' : caseContact.MailingStreet + ' ';
        addr += string.isEmpty(caseContact.MailingStreet2__c) ? '' : caseContact.MailingStreet2__c + ' ';
        addr += string.isEmpty(caseContact.MailingCity) ? '' : caseContact.MailingCity + ' ';
        addr += string.isEmpty(caseContact.MailingState) ? '' : caseContact.MailingState + ' ';
        addr += string.isEmpty(caseContact.MailingPostalCode) ? '' : caseContact.MailingPostalCode + ' ';
        addr += string.isEmpty(caseContact.MailingCountry) ? '' : caseContact.MailingCountry + ' ';
        return string.isEmpty(addr) ? 'Australia' : EncodingUtil.urlEncode(addr, 'utf-8');
    }

    private Component.Apex.OutputPanel createTab(CaseContactSidePanelTabSettings__c tabSetting) {
        Component.Apex.OutputPanel tab = new Component.Apex.OutputPanel();

        Id subject = associatedPersonAccount == null ? caseContact.Id : associatedPersonAccount.Id;
        tab.childComponents.add(RelatedListComponent.getRelatedList(subject, caseContact.Id, tabSetting));

        return tab;
    }
    
    /**************************************************

    20.06.2016  eugene.jandusay@auspost.com.au  updated method when creating a new contact/person account                                               
    **************************************************/
    public PageReference save() {
        system.debug('Saving contact details...');
        String accountId = '';
        String billingAccountId = '';
        system.debug('strAccountName in save  -'+strAccountName);
        //If Account Name is provided, trying to find the matching Account or Billing Account using SOSL    
        if (String.isNotEmpty(strAccountName)) {        // Nandan : Replaced empty check to standard Salesforce method

            String accountWhereClause = strAccountName.trim() != '' ? 'Name = \'' + string.escapesinglequotes(strAccountName.trim()) + '\'' : '';
            String billingWhereClause = strAccountName.trim() != '' ? 'Name = \'' + string.escapesinglequotes(strAccountName.trim()) + '\'' : '';
            String findClause = strAccountName.trim() != '' ? '"' + string.escapesinglequotes(strAccountName.trim()) + '*"' : '';
            String acctFindClause = strAccountName.trim() != '' ? '{' + string.escapesinglequotes(strAccountName.trim()) + '*}' : '';

            findClause = '\'' + findClause + '\'';
            acctFindClause = '\'' + acctFindClause + '\'';//modified by yuanyuan zhang 2014-08-13

            String queryString = 'Find ' + acctFindClause + ' IN ALL FIELDS RETURNING ' +
                    'Account(id where isPersonAccount = false and ' + accountWhereClause + '),' +
                    'Billing_Account__c(id,Organisation__c where ' + billingWhereClause + ')  limit 1';
				system.debug('queryString ..'+ queryString);
            
            List<List<SObject>> queryResults = search.query(queryString);
           
            if (!queryResults.isEmpty()) {
               
                if (!queryResults[0].isEmpty()) { 
                    accountId = queryResults[0][0].Id; 
                } else {
                    List<Billing_Account__c> billingAccounts = queryResults[1]; 
                    if (!billingAccounts.isEmpty()) { 
                        billingAccountId = billingAccounts[0] .Id;
                        accountId = billingAccounts[0].Organisation__c; 
                    }
                }
                 system.debug('accountId ..'+ accountId);
            }
        }
        
        system.debug('caseRec.ContactId in save  -'+caseRec.ContactId);
        //check if there is a contact associated within the case
        //if there is no contact, create one if details are supplied
        if (caseRec.ContactId == null) {

            //if account name is blank, create a person account
            if ( strAccountName == null ||  String.isEmpty(strAccountName.trim())) {

                system.debug('###created person account');
                Account newPersonAccount = new Account();

                //check if null first before trimming
                if (caseContact.FirstName != null) {
                    newPersonAccount.FirstName = caseContact.FirstName.trim();
                }
                if (caseContact.LastName != null) {
                    newPersonAccount.LastName = caseContact.LastName.trim();
                }
                 if (caseContact.Preferred_Name__c != null) {
                    newPersonAccount.Preferred_Name__pc = caseContact.Preferred_Name__c.trim();
                }
                //Populating either mobile or home phone based on the starting digits
                    /*
                    && (CaseContact.MobilePhone.trim().replaceAll('[^0-9]', '').startsWith('04') || 
                            CaseContact.MobilePhone.trim().replaceAll('[^0-9]', '').startsWith('614') || 
                            CaseContact.MobilePhone.trim().replaceAll('[^0-9]', '').startsWith('6104'))
                    
                    */

                if (CaseContact.MobilePhone != null) {
                    newPersonAccount.PersonMobilePhone = caseContact.MobilePhone.trim();
                } else {
                    if (caseContact.HomePhone != null) {
                        newPersonAccount.PersonHomePhone = caseContact.HomePhone.trim();
                    }

                }
                //check if null first before trimming
                if (caseContact.Email != null) {
                    newPersonAccount.PersonEmail = caseContact.Email.trim();
                }

                //populate mailing address based on component
                newPersonAccount.PersonMailingStreet = mailingAddress.line1;
                newPersonAccount.MailingStreet2__pc = mailingAddress.line2;
                newPersonAccount.PersonMailingCity = mailingAddress.city;
                newPersonAccount.PersonMailingState = mailingAddress.state;
                newPersonAccount.PersonMailingPostalCode = mailingAddress.postcode;
                newPersonAccount.PersonMailingCountry = mailingAddress.country;
                newPersonAccount.MailingDPID__pc = mailingAddress.dpid;

                system.debug('@@@newPersonAccount.PersonMobilePhone: ' + newPersonAccount.PersonMobilePhone);
                newPersonAccount.RequiresOrganisation__c = true;

                Database.SaveResult savenewPersonAccount = Database.insert(newPersonAccount, false);
                if (!savenewPersonAccount.isSuccess()) {
                    for (Database.Error error : savenewPersonAccount.getErrors()) {
                        //If the failure is because of duplicate rules, handle the results.
                        if (error instanceof Database.DuplicateError) {
                            ApexPages.message dupeMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' +
                                    error.getStatusCode() + ': ' + 'A consumer with the same first name, last name and ' +
                                    'email or phone number already exists. Use Contact Lookup to assign a new contact to the record.');
                            ApexPages.addMessage(dupeMsg);
                        } else {
                            ApexPages.Message exceptionMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' +
                                    error.getStatusCode() + ': ' + error.getMessage());
                            ApexPages.addMessage(exceptionMsg);
                        }
                    }
                    return null;
                }
                Id personAccId = [Select Id,Name,PersonContactId FROM Account WHERE ID = :newPersonAccount.Id].PersonContactId;
                //assign the personcontactid of the person account created on the associated case
                caseRec.ContactId = personAccId;

                //result = newPersonAccount.id;
            } else {
                //If an Account name is entered, create a contact
                system.debug('###created contact');
                Contact newContact = new Contact();

                //check if null first before trimming
                if (caseContact.FirstName != null) {
                    newContact.FirstName = caseContact.FirstName.trim();
                }
                //check if null first before trimming
                if (caseContact.LastName != null) {
                    newContact.LastName = caseContact.LastName.trim();
                }
                //check if null preferred name before trimming
                if (caseContact.Preferred_Name__c != null) {
                    newContact.Preferred_Name__c = caseContact.Preferred_Name__c.trim();
                }
                //Populating either mobile or home phone based on the starting digits
                if (CaseContact.MobilePhone != null) {
                    newContact.MobilePhone = CaseContact.MobilePhone.trim();
                } else {
                    if (caseContact.HomePhone != null) {
                        newContact.HomePhone = caseContact.HomePhone.trim();
                    }

                }
                //check if null before trimming
                if (caseContact.Email != null) {
                    newContact.Email = caseContact.Email.trim();
                }
                
                system.debug('accountId in save  -'+accountId);

                //check if there is an existing account with the same name from query above
                if (accountId != '') {
                    newContact.accountid = accountId;
                } else {
                    //if there is no match, create a new one
                    Account newAccount = new Account(Name = strAccountName.trim());
                    try {
                        insert newAccount;
                    } catch (Exception e) {
                        ApexPages.addMessages(e);
                    }
                    newContact.accountId = newAccount.id;
                    system.debug('new accountId in save  -'+newAccount.id);
                    system.debug('new accountId to contact update save  -'+newContact.accountId);
                }
                //check if there is a matching billing account
                if (billingAccountId != '') {
                    newContact.BillingAccount__c = billingAccountId;
                }

                //populate address based on address component
                newContact.MailingStreet = mailingAddress.line1;
                newContact.MailingStreet2__c = mailingAddress.line2;
                newContact.MailingCity = mailingAddress.city;
                newContact.MailingState = mailingAddress.state;
                newContact.MailingPostalCode = mailingAddress.postcode;
                newContact.MailingCountry = mailingAddress.country;
                newContact.MailingDPID__c = mailingAddress.dpid;
                //15/06/2017 Dion Gunn - Modified the below insert statement to better handle duplicate blocker
                //exceptions

                Database.SaveResult saveNewContact = Database.insert(newContact, false);
                if (!saveNewContact.isSuccess()) {
                    for (Database.Error error : saveNewContact.getErrors()) {
                        ApexPages.Message exceptionMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' +
                                error.getStatusCode() + ': ' + error.getMessage());
                        ApexPages.addMessage(exceptionMsg);
                    }
                    return null;
                }
                //update case record contact
                caseRec.ContactId = newContact.Id;
            }

            //update case record
            try {
                update caseRec;

            } catch (Exception e) {
                system.debug('save contact exeption e: ' + e.getMessage());
                ApexPages.addMessages(e);
            }
        } else {
            try {
                //update scenario if there is an existing contact associated with the case
                caseContact.MailingStreet = mailingAddress.line1;
                caseContact.MailingStreet2__c = mailingAddress.line2;
                caseContact.MailingCity = mailingAddress.city;
                caseContact.MailingState = mailingAddress.state;
                caseContact.MailingPostalCode = mailingAddress.postcode;
                caseContact.MailingDPID__c = mailingAddress.dpid;
                caseContact.MailingCountry = mailingAddress.country;
                system.debug('@@@caseContact.IsPersonAccount: ' + caseContact.IsPersonAccount);
                if (!caseContact.IsPersonAccount) {
                    system.debug('@@@enter here');
                    //check if there is an existing account with the same name from query above
                    if (accountId != '') {
                        caseContact.accountid = accountId;
                    } else {
                        //if there is no match, create a new one
                        Account newAccount = new Account(Name = strAccountName.trim());
                        insert newAccount;
                        caseContact.accountId = newAccount.id;
                         system.debug('NK .. New record on try');
                    }
                    //check if there is a matching billing account
                    if (billingAccountId != '') {
                        caseContact.BillingAccount__c = billingAccountId;
                    }
                }
            } catch (Exception e) {
                system.debug('save contact exeption e: ' + e.getMessage());
                ApexPages.addMessages(e);
            }
            Database.SaveResult savecaseContact = Database.update(caseContact, false);
            if (!savecaseContact.isSuccess()) {
                for (Database.Error error : savecaseContact.getErrors()) {
                    ApexPages.Message exceptionMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' +
                            error.getStatusCode() + ': ' + error.getMessage());
                    ApexPages.addMessage(exceptionMsg);
                }
                return null;
            }
        }

        return null;
    }

    public PageReference cancel() {
        system.debug('Cancel contact details...');
        PageReference pr = Page.CaseContactSidepanel;
        pr.getParameters().put('id', caseRec.Id);
        pr.setRedirect(true);
        return pr;
    }

    private List<CaseContactSidePanelTabSettings__c> sortList(List<CaseContactSidePanelTabSettings__c> tabSettings) {
        List<ComparableSObjectWrapper> wrapperList = new List<ComparableSObjectWrapper>();
        for (CaseContactSidePanelTabSettings__c s : tabSettings) {
            wrapperList.add(new ComparableSObjectWrapper(s, 'DisplayOrder__c'));
        }
        wrapperList.sort();

        List<CaseContactSidePanelTabSettings__c> sortedList = new List<CaseContactSidePanelTabSettings__c>();
        for (ComparableSObjectWrapper w : wrapperList) {
            sortedList.add((CaseContactSidePanelTabSettings__c) w.sObj);
        }
        return sortedList;
    }

}