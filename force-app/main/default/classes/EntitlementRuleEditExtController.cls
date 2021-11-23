public with sharing class EntitlementRuleEditExtController {
    private ApexPages.StandardController sController;
    private final Entitlement_Rule__c entitlementRule;  
    public String subTitle {get; private set;}
    private Id entitleRuleId;
    private Boolean isEdit;
    public List<SelectOption> fieldItems {get; private set;}         
    public Map<String, List<SelectOption>> picklistValuesMap {get; private set;}      
    public Map<String, List<SelectOption>> operatorMap {get; private set;}
    public Integer selectedIndex {get; set;}
      
    private Map<String, List<String>> fieldTypeMap = new Map<String, List<String>>();
    
    private class FilterClass {
        public Integer index {get; set;}    
        public String fieldName {get; set;}
        public String fieldLabel {get; set;}
        public String fieldType {get; set;}
        public String operator {get; set;}
        public String fieldValue {get; set;}
        public String andString {get; set;}
        public Case tempCase {get; set;}
        public FilterClass(Integer idx, String fldName, String fldLabel, String fldType, String oprtr, String fldValue, String andStr, Date fldDate, Datetime fldDatetime) {
            index = idx;    
            fieldName = fldName;
            fieldLabel = fldLabel;
            fieldType = fldType;
            operator = oprtr;
            fieldValue = fldValue;
            andString = andStr;
            tempCase = new Case();
            tempCase.DatePosted__c = fldDate;
            tempCase.ClosedDate = fldDatetime;
        } 
                    
    }
    
    public EntitlementRuleEditExtController() {}
    
    public List<FilterClass> filters {get ;set;}    
    public EntitlementRuleEditExtController(ApexPages.StandardController controller) {
        this.sController = controller;          
        this.entitleRuleId = controller.getId(); 
                
        if (entitleRuleId != null) {  
            entitlementRule = [Select Id, Entitlement_Rule_Name__c, Rule__c From Entitlement_Rule__c Where Id = :this.entitleRuleId];//(Entitlement_Rule__c)controller.getRecord();         
            subTitle = entitlementRule.Entitlement_Rule_Name__c;
            isEdit = true;
        } else {
            subTitle = 'New Entitlement Rule';
            entitlementRule = new Entitlement_Rule__c();
            isEdit = false;         
        }
                
        // fields options
        fieldItems = new List<SelectOption>();
        fieldItems.add(new SelectOption('', '--None--'));
        operatorMap = new Map<String, List<SelectOption>>();        
        picklistValuesMap = new Map<String, List<SelectOption>>(); 
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Case.fields.getMap();                
        for (String key : fieldMap.keySet()) {
            Schema.SObjectField field = fieldMap.get(key);
            Schema.DescribeFieldResult fieldResult = field.getDescribe();
            String fieldType = String.valueOf(fieldResult.getType()).toLowerCase();     
            if (fieldType != 'reference' || key == 'recordtypeid') {  
                String label = key == 'recordtypeid' ? 'Case Record Type' : fieldResult.getLabel();         
                fieldItems.add(new SelectOption(key, label));               
                fieldTypeMap.put(key, new List<String>{fieldType, label});
                 
                // operators
                List<SelectOption> operatorOpt = new List<SelectOption>();
                operatorOpt.add(new SelectOption('', '--None--'));
                operatorMap.put(key, operatorOpt);
                        
                // picklist
                if (fieldType == 'picklist') {
                    List<SelectOption> options = new List<SelectOption>();                  
                    List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
                    for (Schema.PicklistEntry meal : picklistEntries) {
                        options.add(new SelectOption(meal.getValue(), meal.getLabel()));
                    }
                    picklistValuesMap.put(key, options);
                }
                
                // recordtype
                if (key == 'recordtypeid') {
                    List<SelectOption> options = new List<SelectOption>();          
                    for (RecordType rt : [SELECT Id, Name FROM RecordType Where sObjectType = 'Case']) {        
                        options.add(new SelectOption(rt.Id, rt.Name));          
                    }
                    picklistValuesMap.put(key, options);
                }
                
                // boolean
                if (fieldType == 'boolean') {
                    List<SelectOption> options = new List<SelectOption>();
                    options.add(new SelectOption('Yes','Yes'));
                    options.add(new SelectOption('No','No'));
                    picklistValuesMap.put(key, options);
                }                           
            }                   
        }                
        
        // sort fields picklist
        selectOptionSort(fieldItems, 'Label');
                                    
        List<List<String>> filterValues = new List<List<String>>();
        // edit
        if (isEdit && entitlementRule.Rule__c != '' && entitlementRule.Rule__c != null) {                               
            for (String str : entitlementRule.Rule__c.split('\\|\\|')) {
                String[] exp = new List<String>();  
                System.debug('str: ' + str);            
                if (str.contains('=')) {
                    exp = str.split('=');
                    exp.add('=');
                } else if (str.contains('<>')) {
                    exp = str.split('<>');
                    exp.add('<>');
                } else if (str.contains('<')) {
                    exp = str.split('<');
                    exp.add('<');
                } else if (str.contains('>')) {
                    exp = str.split('>');
                    exp.add('>');                
                }
                
                System.debug('exp: ' + exp);
                
                if (exp.size() > 0) {
                    if (fieldTypeMap.containsKey(exp[0])) { 
                        String[] fieldTypeMapValue = fieldTypeMap.get(exp[0]);
                        String fieldValue = '';   
                        String fieldDate = '';
                        String fieldDatetime = ''; 
                        if (fieldTypeMapValue[0] == 'date') {
                            fieldDate = exp[1];
                        } else if (fieldTypeMapValue[0] == 'datetime') {
                            fieldDatetime = exp[1];
                        } else {
                            fieldValue = exp[1];
                        }
                        System.debug('Datetime str : ' + fieldDatetime);
                        System.debug('Datetime dt: ' + stringToDatetime(fieldDatetime));
                        filterValues.add(new List<String>{exp[0], fieldTypeMapValue[1], fieldTypeMapValue[0], exp[2], fieldValue, fieldDate, fieldDatetime});
                        assignOperators(exp[0], fieldTypeMapValue[0]);
                    }
                }
            }
        } 
        
        System.debug('filters before: ' + filterValues);        
        if (filterValues.size() == 0) {
            for (Integer i = 0; i <=4; i++) {
                filterValues.add(new List<String>{'', '', '', '', '', '', ''}); 
            }
        } 
        
        System.debug('filters after: ' + filterValues);
        generateFilterCriteria(filterValues);
        if (filterValues.size() < 5) {
            Integer toAdd = 5 - filterValues.size();
            for (Integer i = 0; i < toAdd; i++) {
                addFilter();
            }
        }
    }       
    
    private void generateFilterCriteria(List<List<String>> listFilters) {
        filters = new List<FilterClass>();
        for (Integer i = 0; i < listFilters.size(); i++) {
            String andStr = 'AND';
            if (i == listFilters.size()-1) andStr = ''; 
            Date tempDate = stringToDate(listFilters[i][5]);
            Datetime tempDatetime = stringToDatetime(listFilters[i][6]); 
            filters.add(new FilterClass(i, listFilters[i][0], listFilters[i][1], listFilters[i][2], listFilters[i][3], listFilters[i][4], andStr, tempDate, tempDatetime));
        }
        System.debug('filters: ' + filters);
    } 
    
    public void addFilter() {
        filters[filters.size()-1].andString = 'AND';
        filters.add(new FilterClass(filters.size(), '', '', '', '', '', '', null, null));   
        system.debug('filters: ' + filters.size());
    }
    
    public void assignFieldType() {                      
        String fieldName = filters[selectedIndex].fieldName;
        System.debug('field: ' + fieldName);
        if (fieldName != '' && fieldName != null) {
            filters[selectedIndex].fieldType = fieldTypeMap.get(fieldName)[0];
            filters[selectedIndex].fieldLabel = fieldTypeMap.get(fieldName)[1];
            // assign operators
            assignOperators(fieldName, filters[selectedIndex].fieldType); 
        } else {
            filters[selectedIndex].fieldType = '';
        }
        filters[selectedIndex].fieldValue = '';
        if (filters[selectedIndex].fieldType == 'date') {
            filters[selectedIndex].tempCase.DatePosted__c = null;
        }
        if (filters[selectedIndex].fieldType == 'datetime') {
          
        }               
    }
    
    private void assignOperators(String fieldName, String fieldType) {
        Set<String> stringTypes = new Set<String>{'string', 'picklist', 'email', 'phone', 'textarea', 'multipicklist', 'reference', 'boolean', 'url', 'id'};
        List<SelectOption> operators = new List<SelectOption>();
        operators.add(new SelectOption('','--None--'));
        if (stringTypes.contains(fieldType)) {              
            operators.add(new SelectOption('=','='));
            operators.add(new SelectOption('<>','<>'));
        } else {
            operators.add(new SelectOption('=','='));
            operators.add(new SelectOption('<','<'));
            operators.add(new SelectOption('>','>'));
            operators.add(new SelectOption('<>','<>'));
        }
        operatorMap.put(fieldName, operators);
    }
    
    public pageReference saveNow() {        
        try {       
            // validate
            String rule = '';
            for (FilterClass f : filters) {
                if (f.fieldName != '' && f.fieldName != null) {
                    if (f.operator != '' && f.operator != null) {
                        if (f.fieldType == 'date') {
                            if (f.tempCase.DatePosted__c != null) {                                  
                                rule+= ('||' + f.fieldName + f.operator + f.tempCase.DatePosted__c.month() + '-' + f.tempCase.DatePosted__c.day() + '-' + f.tempCase.DatePosted__c.year());
                                System.debug('date rule: ' + rule);
                            } else {                            
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, f.fieldLabel + ': Please specify datetime value'));
                            }
                        } else if (f.fieldType == 'datetime') {
                            if (f.tempCase.ClosedDate != null) {        
                                Date tempDate = f.tempCase.ClosedDate.date();                       
                                rule+= ('||' + f.fieldName + f.operator + tempDate.month() + '-' + tempDate.day() + '-' + tempDate.year() + ' ' + f.tempCase.ClosedDate.format('hh:mm a'));
                                System.debug('datetime rule: ' + rule);
                            } else {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, f.fieldLabel + ': Please specify date value'));
                            }      
                        } else {
                            if (f.fieldValue != '' && f.fieldValue != null) {
                                if (f.fieldType == 'double' || f.fieldType == 'currency') {
                                    if (f.fieldValue.replace('.','').isNumeric()) {
                                        rule+= ('||' + f.fieldName + f.operator + f.fieldValue);
                                        System.debug('double rule: ' + rule);
                                    } else {
                                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, f.fieldLabel + ': Invalid value'));
                                    }
                                } else {
                                    rule+= ('||' + f.fieldName + f.operator + f.fieldValue);
                                    System.debug('text rule: ' + rule);
                                }
                                
                            } else {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, f.fieldLabel + ': Please specify a value'));
                            }
                        }
                    } else {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, f.fieldLabel + ': Please specify operator'));
                    }
                } 
            }           
            
            if (!ApexPages.hasMessages()) {
                if (rule.length() > 2) {
                    System.debug('final rule: ' + rule);                    
                    Entitlement_Rule__c eRule = (Entitlement_Rule__c)sController.getRecord();                       
                    eRule.Rule__c = rule.substring(2);          
                    upsert eRule;
                    PageReference page = new PageReference('/' + eRule.Id);
                    page.setRedirect(true);
                    return page;                    
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please specify at least one(1) rule criteria'));
                }   
            }
            return null;            
        } catch(Exception e) {
            System.debug('exception msg: ' + e.getMessage());   
            if (e.getMessage().contains('duplicate value found')) {             
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Entitlement Rule Name already exist'));  
            } else {
                ApexPages.addMessages(e);   
            }
            return null;  
        }                      
    }                     
    
    // sort selectoption
    private void selectOptionSort(List<SelectOption> opts, String sortField) {
        Map<String, Selectoption> mapping = new Map<String, Selectoption>();
        // Suffix to avoid duplicate values like same labels or values are in inbound list 
        Integer suffix = 1;
        for (Selectoption opt : opts) {
            if (sortField == 'Label') {
                mapping.put((opt.getLabel() + suffix++), opt);   
            } else {
                mapping.put((opt.getValue() + suffix++), opt);   
            }
        }
        
        List<String> sortKeys = new List<String>();
        sortKeys.addAll(mapping.keySet());
        sortKeys.sort();
        // clear the original collection to rebuilt it
        opts.clear();
        
        for (String key : sortKeys) {
            opts.add(mapping.get(key));
        }
    }
    
    // convert string (MM-dd-yyyy) to date
    public Date stringToDate(String strDate) {
        Date tempDate = null;
        if (strDate != '' && strDate != null) {
            try {
                String[] dtPart = strDate.split('-');
                if (dtPart.size() == 3) {
                    tempDate = Date.valueOf(dtPart[2]+'-'+dtPart[0]+'-'+dtPart[1] + ' 00:00:00');
                }
            } catch (Exception e) {
                return null;
            }   
        }       
        return tempDate;
    }    
       
    // convert string (MM-dd-yyyy hh:mm a) to datetime
    public Datetime stringToDatetime(String strDatetime) {
        Datetime tempDatetime = null;
        if (strDatetime != '' && strDatetime != null) {
            try {
                String[] dtPart = strDatetime.split('-');
                if (dtPart.size() == 3) {
                    tempDatetime = Datetime.valueOf(dtPart[2].left(4)+'-'+dtPart[0]+'-'+dtPart[1] + ' ' + dtPart[2].substring(5,10) + ':00');
                }
            } catch (Exception e) {
                return null;
            }   
        }       
        return tempDatetime;
    }   
}