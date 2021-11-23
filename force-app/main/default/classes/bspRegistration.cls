public class bspRegistration
{
    /**************************************************
    Type:         Controller for visualforce page bspRegistration
    History:
    --------------------------------------------------
    2014-06-26    Louis Wang (Bluewolf)        Updated.
    2016-11-22    David Catindoy               Updated line 70.
    2019-01-22    saiswetha.pingali@auspost.com.au - Corrected the phone number format as per REQ1610773
    2019-03-13    saiswetha.pingali@auspost.com.au - Fix for INC1308447 - Creating bsp users for existing contacts errored.
    2019-07-31    nathan.franklin@auspost.com.au - Uplift to create BAM Application rules
    **************************************************/

    public Contact c {get; set;}
    public String section {get; set;}
    public String businessName {get; set;}
    public String businessNumber {get; set;}

    public AddressExtension mailingAddress {get;set;}
    private string ccuProfileId {get;set;}
    private string generalRecordTypeId {get;set;}
    private string usernameExtension {get;set;}
    private string caseSubject {get; set;}

    public bspRegistration() {
        c = new Contact();
        // default to Australia
        c.MailingCountry = 'Australia';

        // initialise component variables
        mailingAddress = new AddressExtension(c.MailingStreet, c.MailingStreet2__c, c.MailingCity, c.MailingState, c.MailingPostalCode, c.Mailing_DPID__c,
                c.MailingCountry);

        getBSPSetting();
        setPageHeaders();
    }

    public pageReference redirect() {
        system.debug('INFO:'+Userinfo.getUserType());
        if(Userinfo.getUserType()<>'Guest') {
            PageReference p= new PageReference('/bsp/bspEnquiry');
            return p;
        }
        return null;
    }

    private void getBSPSetting()
    {
        // grab detail from Custom Setting
        CCUSettings__c configSetting = CCUSettings__c.getInstance();
        ccuProfileId = configSetting.CCUCommunityUserProfileId__c;
        generalRecordTypeId = configSetting.GeneralRecordTypeId__c;
        usernameExtension = configSetting.UsernameExtension__c;
        caseSubject = configSetting.AdminCaseSubject__c;
    }

    public PageReference save()
    {
        setPageHeaders();
        c.Phone = c.Phone.replaceAll('[^\\d]','');


        // When Create Account button is clicked,
        //    - create a Contact
        //    - create a User
        //    - Create a Case
        SavePoint sp = Database.setSavepoint();
        String myBusinessName;
        myBusinessName = string.escapeSingleQuotes(businessName.trim());
        system.debug('BUSINESS NAME:'+myBusinessName);
        myBusinessName = '\''+myBusinessName + '\'';
        system.debug('BUSINESS NAME:'+myBusinessName);
        //myBusinessName = string.escapeSingleQuotes(myBusinessName.trim());
        businessNumber = string.escapeSingleQuotes(businessNumber.trim());

        //Updated Nov. 22, 2016 - StarTrack update to not allow portal guest to create new account against StarTrack billing account (Australia Post account number) and StarTrack Account Name (Business Name)
        String query = 'SELECT Id, Organisation__r.Id, Organisation__r.Name FROM Billing_Account__c WHERE Organisation__r.Name = ' + myBusinessName + ' AND LEGACY_ID__c = \''+businessNumber+'\' AND Source_System__c = \'' + BspConstants.SOURCE_SYSTEM_SAP_ERP + '\' LIMIT 1';

        // Check if entered Business name and Australia Post account number exists
        List<Billing_Account__c> accts = Database.query(query);
        if(accts.size() == 0){
            string msgString = 'Your account is not created. Please provide the right Business Name and Australia Post account number.';
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, msgString);
            ApexPages.addMessage(myMsg);
            return null;
        }
        // pick the first record from the list
        Billing_Account__c a = accts[0];

        // check if the contact already exists in CRM,
        //    based on FirstName, LastName and Email
        List<Contact> checkContacts = new List<Contact>();
        system.debug('*** details***');
        system.debug(c.FirstName);
        system.debug(c.LastName);
        system.debug(c.Email);
        system.debug(a.Organisation__r.Name);
        Boolean canICreateContact = true;
        Boolean canIUpdateContact = false;
        //Fix - INC1308447 Updated SOQL to include Phone
        checkContacts = [SELECT Id, Email, FirstName, LastName,Account.Name,Phone
        FROM Contact
        WHERE FirstName = : c.FirstName
        AND LastName = : c.LastName
        AND Email = : c.Email
        AND BillingAccount__c = :a.Id
        AND IsPersonAccount = false
        ORDER BY CreatedDate];
        if(checkContacts.size()==0) {
            checkContacts = [SELECT Id, Email,Phone
            FROM Contact
            WHERE FirstName = : c.FirstName
            AND LastName = : c.LastName
            AND Email = : c.Email
            AND BillingAccount__c = null
            AND IsPersonAccount = false
            ORDER BY CreatedDate];
            if(checkContacts.size()==0)
            {
                checkContacts = [SELECT Id, Email,Phone
                FROM Contact
                WHERE FirstName = : c.FirstName
                AND LastName = : c.LastName
                AND Email = : c.Email
                AND IsPersonAccount = false
                ORDER BY CreatedDate];
                if(checkContacts.size()>0) {
                    // if the Contact already exists, throw error
                    string msgString = 'You already have an existing account with Australia Post related to a different Billing Account. Please contact Australia Post to update your details.';
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, msgString);
                    ApexPages.addMessage(myMsg);
                    return null;
                }
            }
            else
            {
                canIUpdateContact = true;
                c = checkContacts[0];
            }
        } else {
            canICreateContact = false;
            c = checkContacts[0];
        }



        // check if the particular username already been taken
        List<User> checkUsers = [SELECT Id
        FROM User
        WHERE Username = : c.Email + usernameExtension];
        if(checkUsers.size()>0)
        {
            // if the User already exists, throw error
            string msgString = 'The Email Address/Login Name is already taken. Please contact us to enable your account. Or use forget password to receive your latest credentials via Email';
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, msgString);
            ApexPages.addMessage(myMsg);
            return null;
        }


        //Set contact details
        c.accountId = a.Organisation__r.Id;
        // fetch info from component variable
        c.MailingStreet = mailingAddress.line1.split(',',2)[0];
        system.debug('c.mailingStreet:'+c.MailingStreet+mailingAddress.dpid);
        c.MailingStreet2__c = mailingAddress.line2;
        c.MailingCity = mailingAddress.city;
        c.MailingState = mailingAddress.state;
        c.MailingPostalCode = mailingAddress.postcode;
        c.MailingCountry = mailingAddress.countryName;
        c.Mailing_DPID__c = mailingAddress.dpid;
        // set billing account on contact
        c.BillingAccount__c = a.Id;

        try
        {
            If(CanIUpdateContact) {
                update c;
            }
            else If(CanICreateContact) {
                insert c;
            }

            // grab the bam application
            BAMApplication__c app = [Select Id From BAMApplication__c Where AppKey__c = 'BSP'];
            BAMApplicationRole__c role = [Select Id From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' and Role__c = 'User'];

            // create BAM application and contact role for initial state
            BAMContactApplication__c contactApp = new BAMContactApplication__c(Application__c = app.Id, Contact__c = c.Id, Status__c = 'Active');
            insert contactApp;

            BAMContactRole__c contactRole = new BAMContactRole__c(ContactApplication__c = contactApp.Id, ApplicationRole__c = role.Id, Status__c = 'Active');
            insert contactRole;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            Database.rollback(sp);
            return null;
        }

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.EmailHeader.triggerUserEmail = true;
        string aliasString = c.FirstName.substring(0,1) + c.LastName;
        if(c.LastName.Length()>4)
        {
            aliasString = c.FirstName.substring(0,1) + c.LastName.substring(0,4);
        }


        //PageReference p = site.login(u.username,password,'ssswdev1-auspostccu.cs5.force.com/ccu');
        User u = new User(  alias = aliasString,
                firstname = c.FirstName,
                Street = mailingAddress.line1,
                City = mailingAddress.city,
                State = mailingAddress.state,
                PostalCode = mailingAddress.postcode,
                Country = mailingAddress.countryName,
                DPID__c = mailingAddress.dpid,
                CompanyName = businessName,
                Phone = c.Phone,
                MobilePhone = c.MobilePhone,
                email=c.email,
                emailencodingkey='UTF-8',
                lastname=c.LastName,
                languagelocalekey='en_US',
                localesidkey='en_AU',
                profileid = ccuProfileId,
                contactId=c.Id,
                timezonesidkey='Australia/Sydney',
                username=c.email+usernameExtension);
        u.setOptions(dmo);

        try
        {
            insert u;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            Database.rollback(sp);
            return null;
        }

        Case myCase = new Case(RecordTypeId=generalRecordTypeId,
                Subject=caseSubject,
                Type='General Enquiry',
                Origin='BSP',
                ContactId=c.Id);
        try
        {
            insert myCase;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            Database.rollback(sp);
            return null;
        }

        // if reaches here, then everything are saved successfully. Move to next section.
        section = 'thankyou';
        return null;
    }

    private void setPageHeaders()
    {
        // the following code resolved IE8/9 mis-aligned rendering issue

        // Make sure IE9 will use edge (IE9) mode - without the insertion of the following header
        // <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
        // comes too late and gives this error
        // HTML1115: X-UA-Compatible META tag ('IE=edge,chrome=1') ignored because document mode is already finalized.
        // Caused by Vf outputing tags and content prior to this meta tag
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=edge,chrome=1');

        // Add headers as advised by security review 2013-02-15
        Apexpages.currentPage().getHeaders().put('X-Frame-Options', 'SameOrigin'); // To prevent clickjacking
        Apexpages.currentPage().getHeaders().put('Cache-control', 'no-store'); // To prevent the browser to store personal information into its cache
        Apexpages.currentPage().getHeaders().put('Pragma', 'no-cache');
    }


}