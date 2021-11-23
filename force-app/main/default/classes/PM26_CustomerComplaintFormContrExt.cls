/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 10/05/2016
  * @description  : Controller class for generating PM26 form
  */
/*******************************  History ************************************************
    Date                User                                       Comments
20.09.2016      kaplita.talwadekar@auspost.com.au        updated to get the dependant values based on product category
                                                           to accomodate clearview code change.  
20.03.2018      kaplita.talwadekar@auspost.com.au        updated to accomodate MW0002314 change
19.042018       hasantha.liyanage@auspost.com.au        Initialise all the booleans to ignore nulls
                                                        modifications to the validate method to handle more validations
10.07.2018      kaplita.talwadekar@auspost.com.au        updated code for new forms expansion for more enquiry types
15.01.2019      saisweth.pingali@auspost.com.au          REQ1539835 -Modified code to include validations for "Damage/Missing Contents" form .
07.02.2019      disha.kariyia@auspost.com.au            Added Parcel Post - Secure Accept and Collect to avoid Compensation
                                                        
*******************************  History ************************************************/
public class PM26_CustomerComplaintFormContrExt {
    
    //to hold to case details to be created
    public Case pm26Case {get;set;}
    private String caseId = SSSWConstants.EMPTY_SPACE;
    //form field values
    public String inspNo {get;set;}
    public List<String> errors {get;set;}
    public string field {get;set;}
    public string field2 {get;set;}
    public List<SelectOption> prodSubCat {get;set;}
    public List<SelectOption> enqSubType {get;set;}
    public string adqPck {get;set;}
    public String trackId {get;set;}
    //fields for holding dependant picklist values
    public Map<String,List<String>> pickValueMap {get;set;}
    //variable to hold the type of complaint/form enquiry 
    public String complaintType {get;set;}
    public boolean complaintSelected {get;set;}
    //to capture case comments/additional information
    public CaseComment comm {get;set;}
    //variable to hold the customer details lodging the complaint
    public Account customer {get;set;}
    //variable for field label to be displayed on UI
    public Map<STring,STring> fieldValueLabelMap {get;set;}
    //to capture compensation details on the form
    public String compensationValue {get;set;}
    //error handling on the form
    public String errString {get;set;}
    public list<String> errFields {get;set;}
    public Map<String,Set<String>> disableComForPSubCat = 
                new Map<String,Set<String>> { 'Domestic Parcels'=> new Set<String>
                                              {'Cash on Delivery', 'eParcel- Express', 'eParcel- Regular','Star Track (Next Flight Premium & Express)','Star Track Courier','Parcel Post - Secure Accept and Collect'},
                                              'Domestic Letters'=> new Set<String>
                                              {'Cash on Delivery', 'Unaddressed Mail'},
                                              'International Letters' => new Set<String>
                                              {'Airmail under 2kg', 'Economy Air under 500g', 'International Courier', 'International Express', 'Pack and Track International', 'Registered Post International', 'ECI', 'ECI Platinum', 'Express Post International' },
                                               'Post Office & Business Hub Services'  => new Set<String>
                                               {'General merchandise', 'Mail Pick up', 'Philatelic (stamps)',  'PO Boxes & Bags', 'Mobile products',  'Stationery and packaging', 'Passport & ID Photos', 'Post office locator' }
                                            };
    
    //boolean to distinguish error occurance
    public Boolean isError {
        get {
            if (isError == null) {
                return false;
            }
            return isError;
        } set;
    }
    
    //boolean for checking if article is retrieved from SAP EM
    public Boolean noArticle {
        get {
            if (noArticle == null) {
                return false;
            }
            return noArticle;
        } set;
    }
    //boolean for evidence of quarantine
    public Boolean evidence {
        get {
            if (evidence == null) {
                return false;
            }
            return evidence;
        } set;
    }
    
    //boolean for no evidence of quarantine
    public Boolean noevidence {
        get {
            if (noevidence == null) {
                return false;
            }
            return noevidence;
        } set;
    }
    
    //boolean to check if product is of international category
    public Boolean yesInt  {
        get {
            if (yesInt == null) {
                return false;
            }
            return yesInt;
        } set;
    }

    //checkbox for user to allow to specify no tracking id is available
    public Boolean noTrackId {
        get {
            if (noTrackId == null) {
                return false;
            }
            return noTrackId;
        } set;
    }
    
    //boolean to check if enquiry is eligible for compensation
    public Boolean compnsation {
        get {
            if (compnsation == null) {
                return false;
            }
            return compnsation;
        } set;
    }
    
    //post eligible - user can decide if compensation is paid or not
    public Boolean nocompnsation {
        get {
            if (nocompnsation == null) {
                return false;
            }
            return nocompnsation;
        } set;
    }
    
    //post eligible - user can decide if compensation is paid or not
    public Boolean yescompnsation {
        get {
            if (yescompnsation == null) {
                return false;
            }
            return yescompnsation;
        } set;
    }
    public PM26_CustomerComplaintFormContrExt () {}
    
    /**
      * @description       This method acts as constructor to do initial setup ased on standard controller Case
      * @param             ApexPages.StandardController stdCon
      * @return            NA
      * @throws            NA
      */
    public PM26_CustomerComplaintFormContrExt (ApexPages.StandardController stdCon) {
        pm26Case = new Case();
        //set case record type to sssw delivery
        pm26Case.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW Delivery').getRecordTypeId();
        //initialize all variables
        customer = new Account();
        yesInt = false;
        evidence = false;
        noevidence = false;
        noTrackId = false;
        yescompnsation = false;
        compensationValue = '';
        pm26Case.Compensation_Paid__c = 0;
        field2 = '';
        
        //if caseId is not null for complaint pdf receipt
        if(stdCon.getRecord().id != null) {
            caseId = stdCon.getRecord().id;
             pm26Case = [Select Id, CaseNumber,Network__r.Name, Network__r.Post_Code__c, ReferenceID__c ,ExtraCover__c,ExtraCoverAmount__c,
                        Bypass_Data_enforcement__c,Email_Bypass_Data_enforcement__c,APT_Charge_Account__c, Contact.Name, Last_Name__c,
                        Requestor__c,PrimaryContactFirstName__c,PrimaryContactLastName__c,Address1Line1__c,SecondaryContact__c,MyPost_Number__c,CaseDetails__c,
                        DescriptionOfContents__c, Address1line2__c,Address2Line1__c,Address1Suburb__c,Address1State__c,TypeofDamage__c,SecondaryContactFirstName__c,
                        SecondaryContactLastName__c,Address2line2__c,Compensation_Paid__c, Address2Suburb__c,Address2State__c,Address2Country__c,SecondaryEmail__c,
                        Phone__c,Address2Postcode__c,ValueofContents__c,eParcelDamages__c,Description 
                        FROM 
                            Case 
                        WHERE 
                            Id= :caseId 
                        LIMIT 1];
            comm = [Select Id, CommentBody 
                    FROM 
                        CaseComment 
                    WHERE 
                        ParentId =: caseId 
                    LIMIT 1];    
        } else {
            //for new form enquiry submission
            evidence = false;
            field=SSSWConstants.DEF_PRD_TYPE;
            pm26Case.Requestor__c = userinfo.getUserId(); 
            pm26Case.Address2Country__c =  SSSWConstants.DEF_COUNTRY; 
            pm26Case.ExtraCover__c = '0';                                              
            prodSubCat = new List<SelectOption>();
            enqSubType = new List<SelectOption>();
            prodSubCat.add(new SelectOption(SSSWConstants.EMPTY_SPACE,SSSWConstants.SEL_PRD_CAT_FRST));
            enqSubType.add(new SelectOption(SSSWConstants.EMPTY_SPACE,'Select Enquiry Sub Type'));
            //create a map to store all the controlling and dependant picklist values
            pickValueMap = 
                    DependentPickListValueController.GetDependentOptions( 'Case',Schema.Case.fields.ProductCategory__c.getDescribe().getNAME(),
                                                                            Schema.Case.fields.ProductSubCategory__c.getDescribe().getNAME() );
        }
         
        //set field label map for labels on form
        setFieldLabels();
    }
    
    /**
      * @description       This method creates a map for field label to be displayed on the form
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    private void setFieldLabels() {
        fieldValueLabelMap = new Map<String,STring>(); 
        fieldValueLabelMap.put(SSSWConstants.SEC_CON_FIRSTNAME,SSSWConstants.FIRSTNAME);
        fieldValueLabelMap.put(SSSWConstants.SEC_CON_LASTNAME,SSSWConstants.LASTNAME);
        fieldValueLabelMap.put(SSSWConstants.ADDRE_ADD1,SSSWConstants.ADD1);
        fieldValueLabelMap.put(SSSWConstants.ADDRE_ADD2,SSSWConstants.ADD2);
        fieldValueLabelMap.put(SSSWConstants.ADDRE_SUB,SSSWConstants.SUBURB);
        fieldValueLabelMap.put(SSSWConstants.ADDRE_STATE,SSSWConstants.STATE);
        fieldValueLabelMap.put(SSSWConstants.ADDRE_COUNTRY,SSSWConstants.COUNTRY);
        fieldValueLabelMap.put(SSSWConstants.ADDRE_POSTCODE,SSSWConstants.POSTCODE);
        fieldValueLabelMap.put(SSSWConstants.ADDRE_EMAIL,SSSWConstants.EMAIL);       
        fieldValueLabelMap.put(SSSWConstants.PHONE,SSSWConstants.PHONE);  
        fieldValueLabelMap.put(Schema.Case.fields.ValueOfContents__c.getDescribe().getLabel(),Schema.Case.fields.ValueOfContents__c.getDescribe().getLabel());
        fieldValueLabelMap.put(Schema.Case.fields.DescriptionOfContents__c.getDescribe().getLabel(),Schema.Case.fields.DescriptionOfContents__c.getDescribe().getLabel());
        fieldValueLabelMap.put(SSSWConstants.DAMAGE_TYPE,SSSWConstants.DAMAGE_TYPE);
        fieldValueLabelMap.put(Schema.Case.fields.Description.getDescribe().getLabel(),Schema.Case.fields.Description.getDescribe().getLabel());
        fieldValueLabelMap.put('Case Details','Other Details');  
        fieldValueLabelMap.put('Product Category','Product Category');  
        fieldValueLabelMap.put('Product Sub Category','Product Sub Category'); 
        fieldValueLabelMap.put('Description of contents','Description of contents');  
        fieldValueLabelMap.put('Value of contents','Value of contents');
        fieldValueLabelMap.put('Last Name','Business Name');
        fieldValueLabelMap.put('Charge Account(s)','Charge Account Number');
        fieldValueLabelMap.put('Reference ID','Tracking Number');
        fieldValueLabelMap.put('Case Number','');
        fieldValueLabelMap.put('Type and Product','');
        fieldValueLabelMap.put('Enquiry Sub Type','Enquiry Sub Type');
    }
    
    /**
      * @description       This method searches for the all networks in which the logged in user resides/works
      * @param             NA
      * @return            List<SelectOption>
      * @throws            NA
      */
    public List<SelectOption> getNetworks() {
      List<SelectOption> options = new List<SelectOption>();
           options.add(new SelectOption(SSSWConstants.EMPTY_SPACE, 'Please select'));
           //check which all networks the logged in user is part of and display on page for user to select
           for( Facility_User__c nuser : [  Select Network__r.Name,Network__c, Network__r.Post_Code__c 
                                            from 
                                                Facility_User__c 
                                            where 
                                                User__c =:userinfo.getUserId() ]) {
              options.add(new SelectOption(nuser.Network__c, nuser.Network__r.Name));
           } 
                
       return options;
    }
    
    /**
      * @description       This method gets all the product categories for case object
      * @param             NA
      * @return            List<SelectOption>
      * @throws            NA
      */
    public List<SelectOption> getProdCat(){
           List<SelectOption> options = new List<SelectOption>();
           //get all product categories on UI
           options.add(new SelectOption(SSSWConstants.EMPTY_SPACE,SSSWConstants.SEL_PRD_CAT));
           for(Schema.PicklistEntry p : Case.ProductCategory__c.getDescribe().getPicklistValues()){
               if(p.getValue().contains('Domestic') || p.getValue().contains('International')  ) {
                   options.add(new SelectOption(p.getValue(), p.getValue())); 
               } else if ('Other'.equalsIgnoreCase(complaintType) && (p.getValue().contains('Domestic') || p.getValue().contains('International') ||
                           p.getValue().contains('Money') || p.getValue().contains('Web') || 
                           p.getValue().contains('Post') || p.getValue().contains('Travel')) ) {
                   options.add(new SelectOption(p.getValue(), p.getValue())); 
               }
           }
           return options;
     }
    
    /**
      * @description       This method sets complaint types for different form enteries
      * @param             NA
      * @return            List<SelectOption>
      * @throws            NA
      */
    public List<SelectOption> getComplaintTypes() {
        List<SelectOption> options = new List<SelectOption>();
        //check which all networks the logged in user is part of and display on page for user to select
        options.add(new SelectOption('','Please Select'));
        options.add(new SelectOption('PM26','Damaged Article/Missing Contents'));
        options.add(new SelectOption('Other','Other'));
            
        return options;
    }
    
    /**
      * @description       This method creates a custom picklist for damage types provided by business
      * @param             NA
      * @return            List<SelectOption>
      * @throws            NA
      */
    public List<SelectOption> getDamageType() {
      List<SelectOption> options = new List<SelectOption>();
      //get all damage types specified by business
      if(String.isBlank(caseId)) {
           options.add(new SelectOption(SSSWConstants.EMPTY_SPACE, SSSWConstants.NONE));
           options.add(new SelectOption(SSSWConstants.DMG_TYPE1,SSSWConstants.DMG_TYPE1));
           options.add(new SelectOption(SSSWConstants.DMG_TYPE2,SSSWConstants.DMG_TYPE2));
           options.add(new SelectOption(SSSWConstants.DMG_TYPE3,SSSWConstants.DMG_TYPE3));
           options.add(new SelectOption(SSSWConstants.DMG_TYPE4,SSSWConstants.DMG_TYPE4));
           options.add(new SelectOption(SSSWConstants.DMG_TYPE5,SSSWConstants.DMG_TYPE5));
           options.add(new SelectOption(SSSWConstants.DMG_TYPE6,SSSWConstants.DMG_TYPE6));
       } 
       return options;
    }
    
    /**
      * @description       This method renders forms based on complaint types
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public void renderForm() {
        complaintSelected = true;
        yescompnsation = false;
        
    }
    
    /**
      * @description       Method to get the product subCategory bsed on product category
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public void initializeProdSubCat () {
        //initialize select options
        prodSubCat = new List<SelectOption>();
        enqSubType = new List<SelectOption>();
        prodSubCat.add(new SelectOption(SSSWConstants.EMPTY_SPACE,SSSWConstants.SEL_PRD_SUB_CAT));
        //yescompnsation = 'Other'.equalsIgnoreCase(complaintType) ? true :false;
                
        //if user has selected a product category, get the dependant sub categories
        pm26Case.Type_and_Product__c = SSSWConstants.INVEST_PRD_TYPE+'|' +field;
        pm26Case.ProductCategory__c = field;
        
        if(!String.isBlank(field)) { 
            //pick the sub categories from product catergory selection
            for(String s :pickValueMap.get(field)) { 
                prodSubCat.add(new SelectOption(s,s));
            }
            yesInt  = field.contains(SSSWConstants.INTERNATIONAL_TYPE) ? true : false ;
        }
        //REQ1539835 - Complaint Type -PM26 to have same validation as "Other"
        if(('Other'.equalsIgnoreCase(complaintType) || 'PM26'.equalsIgnoreCase(complaintType)) && !String.isBlank(field) && !String.isBlank(pm26Case.productSubCategory__c) ) {
            yescompnsation = ('Other'.equalsIgnoreCase(complaintType)|| 'PM26'.equalsIgnoreCase(complaintType)) && !'International Parcels'.equalsIgnoreCase(field) &&
                             !'Money & Insurance'.equalsIgnoreCase(field) && !'Travel & ID'.equalsIgnoreCase(field) 
                             && !'Web & Apps'.equalsIgnoreCase(field)  &&
                             !disableComForPSubCat.get(field).contains(pm26Case.productSubCategory__c) ? true : false ;
            system.debug('YesCompensation- '+yescompnsation);
            if(!yescompnsation ) {compnsation =  false ; compensationValue ='0';  }
        } 
    }
    
    /**
      * @description       Method to check if compensation can be applied for MW0002314
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public void checkComp() { 
        //check if compensation can be entered for damage types
        yescompnsation = !String.isBlank(field2) && (field2.contains('Packaging') ||  field2.contains('Damaged') ||  
                         field2.contains('Contents – repairable') ||  field2.contains('Contents – not repairable')) ? true : false ;
        system.debug('YesCompensation in checkComp - '+yescompnsation);
    }
    
    /**
      * @description       Method to enable enquiry sub type for Other enquiry types when compensation is entered
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public void enableFields() {
        //for compensation on Other enquiry enable enqSubType
        pm26Case.productCategory__c = field;
        pm26Case.Type_and_Product__c = SSSWConstants.INVEST_PRD_TYPE+'|' +field+'|'+pm26Case.productSubCategory__c;
        //yescompnsation = false;
        //REQ1539835 - Complaint Type -PM26 to have same validation as "Other"
        if(('Other'.equalsIgnoreCase(complaintType) || 'PM26'.equalsIgnoreCase(complaintType)) ) {
           
            yescompnsation = !String.isBlank(field) && !'International Parcels'.equalsIgnoreCase(field) &&
                            !'Money & Insurance'.equalsIgnoreCase(field) && !'Travel & ID'.equalsIgnoreCase(field) && !'Web & Apps'.equalsIgnoreCase(field)  &&
                            !disableComForPSubCat.get(field).contains(pm26Case.productSubCategory__c) ? true : false ;
            
            system.debug('YesCompensation in enableFields - '+yescompnsation);
            
            if(!yescompnsation ) { compnsation =  false ; compensationValue ='';  }
        }
        //compnsation = 
        compensationValue = nocompnsation ? ''  :  !String.isBlank(compensationValue) ? compensationValue : '';                     
    }
    
    
    /**
      * @description       This method saves the case record and sets param such that the case is available to required queues.
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public PageReference createCase() {
        //reset failure and redirection variables
        isError = false;
        PageReference pageRef = null;
        String commentBody = '';
        pm26Case.Id = null;
        pm26Case.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW Delivery').getRecordTypeId();

        try {
            //check the error based on field values and validate them
            isError = validate();
            //if there is no error. set the case fields in such a way they route to required queues
            if(!isError) {
                //add compensation details on the comment if entered
                if(!String.isBlank(compensationValue)) 
                    commentBody +=  compnsation && decimal.valueOf(compensationValue) <=50 ? 'Has compensation been paid to the customer? '+
                                    SSSWConstants.HYPHEN_SPACED+ 'YES' + SSSWConstants.NEW_LINE+
                                    'Compensation Value '+SSSWConstants.HYPHEN_SPACED+decimal.valueOf(compensationValue) + 
                                    SSSWConstants.NEW_LINE: SSSWConstants.EMPTY_SPACE ;
                
                //enter all relevant details from the form on the comment 
                commentBody += Schema.Case.fields.ReferenceID__c.getDescribe().getLabel()+SSSWConstants.HYPHEN_SPACED;
                commentBody +=  !String.isBlank(pm26Case.ReferenceID__c) ? pm26Case.ReferenceID__c: 
                                !String.isBlank(trackId )? trackId :SSSWConstants.EMPTY_SPACE ;
                                    
                if('PM26'.equalsIgnoreCase(complaintType)) { 
                    commentBody += SSSWConstants.NEW_LINE+Schema.Case.fields.MyPost_Number__c.getDescribe().getLabel()+SSSWConstants.HYPHEN_SPACED;   
                    commentBody += !String.isblank(pm26Case.myPost_Number__c) ? pm26Case.myPost_Number__c: SSSWConstants.EMPTY_SPACE;
                    commentBody += SSSWConstants.NEW_LINE+LABEL.CL_PM26TransitExtraCover+SSSWConstants.HYPHEN_SPACED + pm26Case.ExtraCover__c;
                }
                // fill the case to be created with relevant form fields
                pm26Case.ReferenceId__c = !String.isBlank(pm26Case.ReferenceID__c) ? pm26Case.ReferenceID__c: 
                                          !String.isBlank(trackId )? trackId :SSSWConstants.EMPTY_SPACE;
                pm26Case.type = SSSWConstants.INVEST_PRD_TYPE;
                pm26Case.AllocateToQueue__c = true;
                pm26Case.isNewForRouting__c = true;
                pm26Case.Subscribe__c = true;
                pm26Case.Origin = SSSWConstants.PM26_ORIGIN;
                pm26Case.EnquirySubType__c  = !String.isBlank(pm26Case.enquirySubType__c) ? pm26Case.enquirySubType__c : SSSWConstants.PM26_ENQ_SUB_TYPE;
                pm26Case.CaseDetails__c = '';
                pm26Case.Bypass_Data_enforcement__c = true;
                pm26Case.Email_Bypass_Data_enforcement__c = true;
                //for PM26 form
                pm26Case.CaseDetails__c += !String.isblank(pm26Case.Last_Name__c) ? SSSWConstants.NEW_LINE+LABEL.CL_PM26BusName+SSSWConstants.HYPHEN_SPACED : SSSWConstants.EMPTY_SPACE ;
                pm26Case.CaseDetails__c += !String.isblank(pm26Case.Last_Name__c) ? pm26Case.Last_Name__c : SSSWConstants.EMPTY_SPACE;
                pm26Case.CaseDetails__c += !String.isblank(pm26Case.APT_Charge_Account__c) ? SSSWConstants.NEW_LINE+LABEL.CL_PM26ChargeAccNo+SSSWConstants.HYPHEN_SPACED: SSSWConstants.EMPTY_SPACE;
                pm26Case.CaseDetails__c += !String.isblank(pm26Case.APT_Charge_Account__c) ? pm26Case.APT_Charge_Account__c : SSSWConstants.EMPTY_SPACE;
                if('PM26'.equalsIgnoreCase(complaintType)) {    
                    pm26Case.CaseDetails__c += SSSWConstants.NEW_LINE+LABEL.CL_PM26AdqPck+SSSWConstants.HYPHEN_SPACED ;
                    pm26Case.CaseDetails__c += !String.isblank(adqPck) ? adqPck : SSSWConstants.EMPTY_SPACE;
                    pm26Case.CaseDetails__c += SSSWConstants.NEW_LINE+LABEL.CL_PM26Evidence+SSSWConstants.HYPHEN_SPACED;
                    pm26Case.CaseDetails__c += evidence ? 'YES' : 'NO';
                    pm26Case.CaseDetails__c +=  SSSWConstants.NEW_LINE+LABEL.CL_PM26CustInpNo+SSSWConstants.HYPHEN_SPACED;
                    pm26Case.CaseDetails__c += !String.isblank(inspNo ) ? inspNo : SSSWConstants.EMPTY_SPACE;
                } 
                pm26Case.CaseDetails__c +=  'PM26'.equalsIgnoreCase(complaintType) ? SSSWConstants.NEW_LINE+LABEL.CL_PM26AddInfo+SSSWConstants.HYPHEN_SPACED :
                                                SSSWConstants.NEW_LINE+'Details of the enquiry'+SSSWConstants.HYPHEN_SPACED;
                pm26Case.CaseDetails__c += !String.isblank(pm26Case.Description) ? pm26Case.Description: SSSWConstants.EMPTY_SPACE;
                //set all address fields on the case
                pm26Case.Address2__c = !String.isBlank(pm26Case.Address2Line1__c ) ? pm26Case.Address2Line1__c + SSSWConstants.COMMA_SEP: SSSWConstants.EMPTY_SPACE;
                pm26Case.Address2__c += !String.isBlank(pm26Case.Address2Line2__c ) ? pm26Case.Address2Line2__c + SSSWConstants.COMMA_SEP :SSSWConstants.EMPTY_SPACE;
                pm26Case.Address2__c += !String.isBlank(pm26Case.Address2Suburb__c ) ? pm26Case.Address2Suburb__c + SSSWConstants.COMMA_SEP :SSSWConstants.EMPTY_SPACE;                
                pm26Case.Address2__c += !String.isBlank(pm26Case.Address2State__c ) ? pm26Case.Address2State__c + SSSWConstants.COMMA_SEP :SSSWConstants.EMPTY_SPACE;   
                pm26Case.Address2__c += !String.isBlank(pm26Case.Address2Country__c ) ? pm26Case.Address2Country__c + SSSWConstants.COMMA_SEP :SSSWConstants.EMPTY_SPACE;
                pm26Case.Address2__c += !String.isBlank(pm26Case.Address2PostCode__c ) ? pm26Case.Address2PostCode__c :SSSWConstants.EMPTY_SPACE;  
                pm26Case.Secondary_Contact__c = pm26Case.SecondaryContactFirstName__c + SSSWConstants.WHITE_SPACE + pm26Case.SecondaryContactLastName__c;
                
                //if compensation is recorded
                if(compnsation && !String.isBlank(compensationValue) && decimal.valueOf(compensationValue) <=50 ) { 
                    pm26Case.Status = 'Closed';
                    pm26Case.ResolutionCode__c = 'MyNetwork Resolution'; 
                }
                //insert the case
                Database.saveResult sr = database.insert(pm26Case);
                
                //set the comment for case comment attaching
                commentBody += SSSWConstants.NEW_LINE+SSSWConstants.FIRSTNAME+SSSWConstants.HYPHEN_SPACED;
                commentBody += !String.isblank(pm26Case.SecondaryContactFirstName__c ) ? pm26Case.SecondaryContactFirstName__c : SSSWConstants.EMPTY_SPACE;
                commentBody += SSSWConstants.NEW_LINE+SSSWConstants.LASTNAME+SSSWConstants.HYPHEN_SPACED;
                commentBody += !String.isblank(pm26Case.SecondaryContactLastName__c ) ? pm26Case.SecondaryContactLastName__c : SSSWConstants.EMPTY_SPACE;
                commentBody += SSSWConstants.NEW_LINE+'Address'+SSSWConstants.HYPHEN_SPACED;
                commentBody += !String.isblank(pm26Case.Address2__c ) ? pm26Case.Address2__c : SSSWConstants.EMPTY_SPACE;
                commentBody += SSSWConstants.NEW_LINE+SSSWConstants.EMAIL+SSSWConstants.HYPHEN_SPACED;
                commentBody += !String.isblank(pm26Case.SecondaryEmail__c) ? pm26Case.SecondaryEmail__c: SSSWConstants.EMPTY_SPACE;
                commentBody += SSSWConstants.NEW_LINE+SSSWConstants.PHONE+SSSWConstants.HYPHEN_SPACED;
                commentBody += !String.isblank(pm26Case.Phone__c ) ? pm26Case.Phone__c : SSSWConstants.EMPTY_SPACE;
                if('PM26'.equalsIgnoreCase(complaintType)) {    
                    commentBody += SSSWConstants.NEW_LINE+Schema.Case.fields.ValueOfContents__c.getDescribe().getLabel()+SSSWConstants.HYPHEN_SPACED;
                    commentBody += pm26Case.ValueOfContents__c!=null ? String.valueOf(pm26Case.ValueOfContents__c): SSSWConstants.EMPTY_SPACE ;
                    commentBody += SSSWConstants.NEW_LINE+Schema.Case.fields.DescriptionOfContents__c.getDescribe().getLabel()+SSSWConstants.HYPHEN_SPACED;
                    commentBody += !String.isblank(pm26Case.DescriptionOfContents__c ) ? pm26Case.DescriptionOfContents__c: SSSWConstants.EMPTY_SPACE ;
                    commentBody += SSSWConstants.NEW_LINE+SSSWConstants.DAMAGE_TYPE+SSSWConstants.HYPHEN_SPACED;
                    commentBody += !String.isblank(pm26Case.TypeofDamage__c) ? pm26Case.TypeofDamage__c : SSSWConstants.EMPTY_SPACE;
                }
                commentBody += !String.isBlank(pm26Case.CaseDetails__c)? pm26Case.CaseDetails__c :SSSWConstants.EMPTY_SPACE ;
                
                //insert case comment
                CaseComment newCom = new CaseComment();
                newCom.CommentBody = commentBody  ;
                newCom.IsPublished = false;
                newCom.ParentId = pm26Case.id;
                Database.saveResult sr1 = database.insert(newCom);
                //if compensation is to be inserted
                if(compnsation && !String.isBlank(compensationValue) && decimal.valueOf(compensationValue) <=50 ) { 
                    String compRecType = [  Select Id 
                                            from 
                                                RecordType 
                                            where 
                                                DeveloperName = 'Retail_Compensation' 
                                            and 
                                                SObjecttype='Compensation__c' 
                                            limit 1].Id;
                    Compensation__c comp = new Compensation__c( Case__c = pm26Case.Id, Contact__c=pm26Case.ContactId, 
                                                                Other__c=decimal.valueOf(compensationValue), 
                                                                Compensation_Amount__c = pm26Case.ValueOfContents__c, 
                                                                Status__c='Retail Compensation Paid',recordtypeId = compRecType,
                                                                Legal_Entity_Name__c = pm26Case.Calc_Link_Account__c );
                    insert comp;   
                } 
                
                if(String.valueOf(URL.getSalesforceBaseUrl()).contains('auspostbusiness')) {
                    // redirection for supporting myNetwork portal change
                    pageRef = new PageReference('/'+ LABEL.MYNETWORK_LABEL +'/PM26_CustomerComplaintFormReceipt?Id='+pm26Case.Id);
                } else {                
                    // redirection for supporting existing users
                    pageRef = new PageReference('/apex/PM26_CustomerComplaintFormReceipt');
                    pageRef.getparameters().put('id',pm26Case.id);
                    pageRef.setRedirect(true);
                }
            }
        }
        catch(Exception exp) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,SSSWConstants.EXCEPTION_MSG));
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'SSSW', 
                                                    SSSWConstants.CLASSNAME, 'createCase', 
                                                    null, LoggingLevel.ERROR);
        }

        return pageRef;
        
    }   
    
    
    /**
      * @description       This method validates the required field entries
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    private Boolean validate() {
        isError = false;
        errFields = new list<String>();
        errString = '';
        pm26Case.TypeofDamage__c = !String.isBlank(field2) ? field2 : pm26Case.TypeofDamage__c; 
        if( String.isBlank(pm26Case.Network__c) ) { 
           isError = true;
           errFields.add('Please select your outlet name');
        }
        if(String.isBlank(pm26Case.productCategory__c) || String.isBlank(pm26Case.productSubCategory__c)) {
            isError = true;
            errFields.add('Please specify both Product Category and Product Sub Category');
        }
        if(String.isBlank(pm26Case.ReferenceId__c) && !noTrackId && 'PM26'.equalsIgnoreCase(complaintType)) {
            isError = true;
           errFields.add('Tracking Number is required (Please check "No Tracking Number" if not available or not known)');
        }
        if( String.isBlank(pm26Case.SecondaryContactFirstName__c ) ) {
            isError = true;
           errFields.add('Please enter First Name ');
        }  
        if( String.isBlank(pm26Case.SecondaryContactLastName__c ) ) {
            isError = true;
           errFields.add('Please enter Last Name ');
        }  
        if( String.isBlank(pm26Case.Address2Line1__c) ) { 
            isError = true;
           errFields.add('Please enter Address Line 1');
        } 
        if( String.isBlank(pm26Case.Address2Suburb__c) ) {
            isError = true;
           errFields.add('Please enter the Suburb');
        }  
        if( String.isBlank(pm26Case.Address2State__c) ) {
            isError = true;
           errFields.add('Please enter the State');
        }  
        if( String.isBlank(pm26Case.Address2PostCode__c) ) {
            isError = true;
           errFields.add('Please enter the Post Code');
        }  
        if( String.isBlank(pm26Case.Address2Country__c) ) {
            isError = true;
           errFields.add('Please enter the Country');
        }  
        if(pm26Case.Address2PostCode__c !=null && !Pattern.matches('^\\d{4}$',pm26Case.Address2PostCode__c ) && 'Australia'.equalsIgnoreCase(pm26Case.Address2Country__c)){
            isError = true;
            errFields.add('Post Code, format is invalid');
        } if (String.isBlank(pm26Case.SecondaryEmail__c) && pm26Case.Phone__c == null ) {
            isError = true;
            errFields.add('Email or Phone is required to process the complaint');
        } else if(!String.isBlank(pm26Case.Phone__c) && 
                ( !Pattern.matches('^\\({0,1}((0|\\+61)(2|4|3|7|8)){0,1}\\){0,1}(\\ |-){0,1}[0-9]{2}(\\ |-){0,1}[0-9]{2}(\\ |-){0,1}[0-9]{1}(\\ |-){0,1}[0-9]{3}$',pm26Case.Phone__c) 
                  || pm26Case.Phone__c.length() < 10   ) ) {
            isError = true;
            errFields.add('Phone number format is invalid');
        } 
        if(String.isBlank(pm26Case.EnquirySubType__c) && 'Other'.equalsIgnoreCase(complaintType)) {
            isError = true;
           errFields.add('Please specify the Enquiry Sub Type');
        }
        if (String.isBlank(pm26Case.TypeofDamage__c)   && 'PM26'.equalsIgnoreCase(complaintType) ) {
            isError = true;
           errFields.add('Please enter the Type of Damage');
        }  
        if( pm26Case.Valueofcontents__c == null  && 'PM26'.equalsIgnoreCase(complaintType) ) {
            isError = true;
           errFields.add('Please enter the Value of Contents');
        }          
        if( String.isBlank(pm26Case.descriptionofcontents__c)   && 'PM26'.equalsIgnoreCase(complaintType) ) {
           isError = true;
           errFields.add('Please enter the Description of Contents ');
        }        
        if( String.isBlank(pm26Case.Description) ) {
            isError = true;
            if('PM26'.equalsIgnoreCase(complaintType)) errFields.add('Please enter the Additional Information');
            else errFields.add('Please enter the Details of Enquiry');
        }  
        if(compensationValue != null && compnsation &&  !String.isBlank(compensationValue)) {
            try {
                if( ( Decimal.valueOf(compensationValue) > 50 || 
                    (compnsation && Decimal.valueOf(compensationValue) <=0)) ) { 
                isError = true;
                errFields.add('Please specify Compensation Value which is $50 or less');
                //errString = 'Error: Compensation Value should be 50 or less';
                }
            }
            catch(Exception exp) {
                isError = true;
                errFields.add('Please enter a numerical value for Compensation  (50 or less)');
            }
        } 
        if((compensationValue == null || String.isBlank(compensationValue)) && compnsation ) {
            isError = true;
            errFields.add('Please specify Compensation Value which is $50 or less');
        }  
        
        //REQ1539835 - Complaint Type -PM26 to have "Adequately Packaged" value entered
        
        if((String.isBlank(adqPck) && 'PM26'.equalsIgnoreCase(complaintType))) {
            isError = true;
            errFields.add('Please specify an option for Adequately Packaged');
        }
        return isError;
    }
    
    /**
      * @description       This method sets that no tracking details is required.
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public void getNoTrackInfo() {
        //if user checks the no track info - then to remove the tracking errors
        errors = new List<String>();
        isError = false;
        pm26Case.ExtraCover__c = '0';
        noArticle = false;
    }
    
    /**
      * @description       This method connects with SAP to pull the article details
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    public PageReference getArticleDetails() {
        // query the article from SAP and upsert in salesforce and if exist show the insurance and contact details to the user
        noArticle = false;
        errors = new List<String>();
        isError = false;
        if(!noTrackId) {
            //reset all values inorder to be pulled out of SAP EM article details
            pm26Case.ExtraCover__c = '0';
            pm26Case.SecondaryContact__c = null;
            pm26Case.ContactId = null;
            pm26Case.SecondaryContactFirstName__c = SSSWConstants.EMPTY_SPACE;
            pm26Case.SecondaryContactLastName__c =  SSSWConstants.EMPTY_SPACE;
            pm26Case.SecondaryContactName__c = SSSWConstants.EMPTY_SPACE;
            pm26Case.Secondary_Contact__c = SSSWConstants.EMPTY_SPACE;
            pm26Case.Address2__c = SSSWConstants.EMPTY_SPACE;
            pm26Case.Address2Line1__c = SSSWConstants.EMPTY_SPACE;
            pm26Case.Address2Line2__c = SSSWConstants.EMPTY_SPACE;
            pm26Case.Address2Suburb__c = SSSWConstants.EMPTY_SPACE;
            pm26Case.Address2State__c = SSSWConstants.EMPTY_SPACE;
            pm26Case.Address2PostCode__c = SSSWConstants.EMPTY_SPACE;
            pm26Case.Address2Country__c =  SSSWConstants.DEF_COUNTRY;                                               
            pm26Case.SecondaryEmail__c =  SSSWConstants.EMPTY_SPACE;
            pm26Case.ReferenceID__c = trackId;
            try {
                //search article using existing interface
                TIBCOSearchResult trackRes = TIBCOArticleService.searchArticles(new List<String> {trackId});
                //if returns tracking results
                if(trackRes.success) {
                    //set the article field on case
                    pm26Case.ArticleTest__c = !trackRes.trackResults.isEMpty() ? trackRes.trackResults[0].articleDetails.proxyArticle.Id : null;
                    noArticle = !trackRes.trackResults.isEMpty() ? trackRes.trackResults[0].articleDetails.proxyArticle == null :
                                 true;
                    system.debug(trackRes.errors);
                    //pull back the cover details for the article
                    pm26Case.ExtraCover__c =!trackRes.trackResults.isEMpty() ? 
                                            !String.isBlank(String.valueOf(trackRes.trackResults[0].articleDetails.proxyArticle.InsuranceAmount__c)) ? 
                                            String.valueOf(trackRes.trackResults[0].articleDetails.proxyArticle.InsuranceAmount__c) : '0' :'0';
                    //set the contact details and address for same.
                    if(!trackRes.trackResults.isEMpty() && trackRes.trackResults[0].articleDetails.proxyArticle!=null) {            
                        pm26Case.SecondaryContactFirstName__c = !String.isBlank(trackRes.trackResults[0].articleDetails.proxyArticle.ReceiverName__c) ? 
                                                                trackRes.trackResults[0].articleDetails.proxyArticle.ReceiverName__c.split(SSSWConstants.WHITE_SPACE)[0] :
                                                                SSSWConstants.EMPTY_SPACE ;
                        pm26Case.SecondaryContactLastName__c =  !String.isBlank(trackRes.trackResults[0].articleDetails.proxyArticle.ReceiverName__c) &&  
                                                                trackRes.trackResults[0].articleDetails.proxyArticle.ReceiverName__c.contains(SSSWConstants.WHITE_SPACE) ? 
                                                                trackRes.trackResults[0].articleDetails.proxyArticle.ReceiverName__c.split(SSSWConstants.WHITE_SPACE)[1] : 
                                                                SSSWConstants.EMPTY_SPACE;
                        pm26Case.Secondary_Contact__c = trackRes.trackResults[0].articleDetails.proxyArticle.ReceiverName__c;
                        pm26Case.Address2Line1__c= trackRes.trackResults[0].articleDetails.proxyArticle.ReceiverAddressLine1__c ;
                        pm26Case.Address2Line2__c = trackRes.trackResults[0].articleDetails.proxyArticle.ReceiverAddressLine2__c;
                        pm26Case.Address2Suburb__c = trackRes.trackResults[0].articleDetails.proxyArticle.ReceiverCity__c;
                        pm26Case.Address2State__c = trackRes.trackResults[0].articleDetails.proxyArticle.ReceiverState__c;
                        pm26Case.Address2PostCode__c = trackRes.trackResults[0].articleDetails.proxyArticle.ReceiverPostcode__c;
                        pm26Case.Address2__c = trackRes.trackResults[0].articleDetails.proxyArticle.ReceiverAddress__c;
                        pm26Case.SecondaryEmail__c =  trackRes.trackResults[0].articleDetails.proxyArticle.ReceiverEmail__c ;            
                    }                         
                    
                    if(!trackRes.trackResults.isEMpty() && !String.isBlank(trackRes.trackResults[0].articleDetails.proxyArticle.Receiver_APCN__c)) {
                        //query customer and populate all values 
                        pm26Case.MyPost_Number__c = trackRes.trackResults[0].articleDetails.proxyArticle.Receiver_APCN__c;
                        for(Contact cont : [Select Id,Name, FirstName, LastName,Email
                                from Contact where APCN__c = :trackRes.trackResults[0].articleDetails.proxyArticle.Receiver_APCN__c limit 1]) {
                            pm26Case.SecondaryContact__c = cont.Id;
                            pm26Case.ContactId = cont.Id;                              
                        }
                    }
                }
                else { //if no article intend to show the error messages to user
                    errors = !trackRes.errors.isempty() ? trackRes.errors : new List<String>();
                    noArticle = true;
                }
            }
            catch(Exception exp) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,SSSWConstants.EXCEPTION_MSG));
                // Error Logged to Exception object for analysis
                UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'SSSW', 
                                                        SSSWConstants.CLASSNAME, 'getArticle', 
                                                        null, LoggingLevel.ERROR);
            }
        }
        return null;
    }
    
    public void initialize() {}
}