public with sharing class bspCaseFieldset 
{
    /**************************************************
    Type:       BSP Case Fieldset Controller 
    Purpose:    Used by CaseFieldset component to show different fieldsets and field Labels based on CaseType         
    History:
    --------------------------------------------------
    2014-05  Louis Wang (Bluewolf)  Created                                            
    **************************************************/
    public bspEnquiry topController {get;set;}
    
    private string enquiryType;
    private string fieldSetName;
    
    public string enquiryParamsValue 
    {
        get;
        set
        {
            // component will only load the AssignTo into class variable after the constructor is executed
            // so need to execute the code here
            enquiryParamsValue = value;   
            if(enquiryParamsValue != null)
            {
                // separate the string parameters
                list<string> enquiryList = enquiryParamsValue.split(';');
                enquiryType = enquiryList[0];
                fieldSetName = enquiryList[1];
            
            }
//            system.debug('xxx3 setValue enquiryParamsValue ' + enquiryParamsValue);
            
            initializePage();
            
            
        }
    }


    public Case myCase {get; set;}
    public Id caseId {get; set;}
    public List<FieldSetWrapper> members {get; set;}
    public Map<String,CustomFieldLabelling__c> caseFieldLabelling {get; set;}
    public Boolean issues {get; set;}
    public Boolean warnings {get; set;}
    
    static final string USAGE = 'BSP';
    
    public bspCaseFieldset() 
    {
        warnings = false;
        issues = false;
    }

    public Boolean getErrorsPresent()
    {
      return ApexPages.hasMessages(ApexPages.Severity.ERROR);
    }

    
    public pageReference save() {
        System.debug('myCase**:'+myCase); 
        try {       
            System.debug('myCaseDetails**'+myCase.ReferenceID__c+myCase.ProductCategory__c);
            update myCase;
           // members.clear();
            System.debug('myCase**:'+myCase);
           // initializePage();
        } catch(Exception e) {
            ApexPages.addMessages(e);
            issues = true;
        }     
        
        return null;
    }
    
    public pageReference close() {
        myCase.Status = 'Closed – Manual';
        try {       
            update myCase;
        } catch(Exception e) {
            ApexPages.addMessages(e);
            issues = true;
        }     
        
        return null;
    }
    
  
   
    public void initializePage() 
    {
        // 2014-05 CCU / BSP
        //    This function is derived from CaseDetail Apex class.
        //    It will update few public properties for Visualforce to consume
        //    By passing in a CaseType, it will loop through Case FieldSet and found the matched one,
        //    to obtain the list of fields to be displayed. 
        //    It will also use CustomFieldLabelling__c to determine the CCU version of labelling for each field. 
 
    
        string compareType = enquiryType;
    
        myCase = new Case();

        Map<String, Schema.FieldSet> fsMap = Schema.SObjectType.Case.fieldSets.getMap();
        members = new List<FieldSetWrapper>();
        caseFieldLabelling = new Map<String,CustomFieldLabelling__c>();

        for(CustomFieldLabelling__c cf : [Select 
                                          Id, UniqueKey__c, CaseType__c, 
                                          CaseFieldLabel__c, CaseFieldAPIName__c 
                                          from CustomFieldLabelling__c
                                          where CaseType__c = :compareType
                                          AND CFLUsage__c = :USAGE]) 
        {

            caseFieldLabelling.put(cf.UniqueKey__c.toLowerCase(), cf);
        }

        if(compareType!=null) 
        {
//            String query = 'SELECT Id, Type';
            for(String fsName : fsMap.keyset()) 
            {
                String fsLabel = fsName.replace('_',' ');
                System.debug('FieldSetNames**'+fsLabel);
                
                // target for fieldset that starts with BSP
//                if(fsLabel.containsIgnoreCase(USAGE + ' ' + compareType)) 
                if(fsLabel.containsIgnoreCase(fieldSetName)) 
                { 
                    System.debug('FieldSets**'+fsMap.get(fsName));
                    List<FieldSetMemberWrapper> fmem = new List<FieldSetMemberWrapper>();
                    for(Schema.FieldSetMember f : fsMap.get(fsName).getFields()) 
                    {
//                        if(!query.contains(f.getFieldPath())) 
//                        {
//                            query += ',' + f.getFieldPath();
//                        }
                        
                        if(f.getFieldPath().contains('.') || Schema.SObjectType.Case.fields.getMap().get(f.getFieldPath()).getDescribe().isAccessible()) 
                        {
                            FieldSetMemberWrapper x;

                            string cflKey = USAGE + f.getFieldPath() + compareType;
                            cflKey = cflKey.toLowerCase();
                            //System.debug('xxx cflKey = ' + cflKey);

                            // get custom label                                                        
                            if(caseFieldLabelling.get(cflKey)!=null) 
                            {
                                x = new FieldSetMemberWrapper(caseFieldLabelling.get(cflKey).CaseFieldLabel__c,f);
                                //system.debug('xxx exists x = ' + x);
                            } 
                            else 
                            {
                                x = new FieldSetMemberWrapper(f.Label,f);
                                system.debug('xxx not exists x = ' + x);
                            }
                            fmem.add(x);
                        }
                    }
                    FieldSetWrapper m = new FieldSetWrapper(fsMap.get(fsName).getLabel(), fsMap.get(fsName).getName(), fmem);
                    members.add(m);
                }
            }
//            this.myCase = Database.query(query+' from Case where Id = :caseId limit 1');
        }
        else
        {
            ApexPages.Message noFields = new ApexPages.Message(ApexPages.Severity.INFO,'Oops! You need a Case Type to see additional details. Please use Case Summary to update Case Type');
            ApexPages.addMessage(noFields);
            warnings = true;
        }

        
        if(!warnings && members.isEmpty()) 
        {
            ApexPages.Message noFields = new ApexPages.Message(ApexPages.Severity.INFO,'Please request access from your Administrator to view the fields for Case Type: '+compareType);
            ApexPages.addMessage(noFields);
            warnings = true;
        }
        else
        {
            members.sort();
        }
    }

    public List<SelectOption> getArticleTypes()
    {
        return topController.getPicklistValues('ArticleType__c', false, null);
    }

    public List<SelectOption> getServiceUsed()
    {
        return topController.getPicklistValues('CCUServiceUsed__c', true, 'Please select');
    }
    
    public List<SelectOption> getItemContents()
    {
        return topController.getPicklistValues('CCUItemContents__c', true, 'Please select');
    }
        
    public List<SelectOption> getStates()
    {
        List<selectOption> options = new List<selectOption>();
        options.add(new selectOption('', 'Select'));
        options.add(new selectOption('ACT', 'ACT'));
        options.add(new selectOption('NSW', 'NSW'));
        options.add(new selectOption('NT', 'NT'));
        options.add(new selectOption('QLD', 'QLD'));
        options.add(new selectOption('SA', 'SA'));                
        options.add(new selectOption('TAS', 'TAS'));
        options.add(new selectOption('VIC', 'VIC'));
        options.add(new selectOption('WA', 'WA'));                                
        return options;
    }  
}