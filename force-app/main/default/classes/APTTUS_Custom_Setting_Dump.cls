global Class APTTUS_Custom_Setting_Dump implements Schedulable{
    list<string> lstFld ;
    map<string,string> mapOfStrToReplaceStr=new map<string,string>();
    SObjectType sObjTyp;
    
    global void execute(SchedulableContext SC) {
      APTTUS_Custom_Setting_Dump d = new APTTUS_Custom_Setting_Dump();
      SendEmail();
    }

    public void SendEmail(){
        mapOfStrToReplaceStr = new map<string,string>();
        mapOfStrToReplaceStr.put('apttus_config2__productattributeruleid__c','apttus_config2__productattributeruleid__r.apts_ext_id__c');
        Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
        String[] toAddresses = new list<string> {UserInfo.getUserEmail()};
        String subject = 'PTEST, CUSTOM SETTING' + UserInfo.getUserName() + ' CSV';
        email.setSubject(subject);
        email.setToAddresses( toAddresses );
        email.setPlainTextBody(UserInfo.getUserName() + ' CSV ');
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{
            //getAttachment(export_FE()),
            //getAttachment(export_PAR()),
            //getAttachment(export_PARa()),
            //getAttachment(export_PAGM_AttrExp()),
            //getAttachment(export_POC_defQtyExp()),
            getAttachment(export_objectData(Apttus_Config2__ConfigSystemProperties__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Config2__UserView__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Config2__ObjectSummarySettings__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Config2__ConfigFieldSet__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Config2__ObjectSummarySettings__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Approval__ApprovalsCustomConfig__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Approval__ApprovalsSystemProperties__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Config2__InstalledProductsSettings__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Config2__OrderLineItemCriteriaFields__c.SObjectType,'Apttus_Config2__CriteriaFieldNames__c','CSV',false)),
            getAttachment(export_objectData(Apttus_Config2__OrderSystemProperties__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Config2__LookupFieldSettings__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Proposal__ProposalCustomClasses__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Proposal__ProposalSystemProperties__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_XApps__XAuthorForExcelSystemProperties__c.SObjectType,'name','JSON',true)),
            //getAttachment(export_objectData(Apttus_Billing__BillingCustomClasses2__c.SObjectType,'name','JSON',true)),
            //getAttachment(export_objectData(Apttus_Billing__BillingSystemProperties__c.SObjectType,'name','JSON',true)),
            //getAttachment(export_objectData(Apttus_Revenue2__RevenueAgreementFilterProperties__c.SObjectType,'name','JSON',true)),
            //getAttachment(export_objectData(Apttus_Revenue2__RevenueSystemProperties__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus__ComplyCustomProperties__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus__ComplySystemProperties__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Config2__ConfigConstraintCriteriaFields__c.SObjectType,'Apttus_Config2__FieldName__c','CSV',false)),
            getAttachment(export_objectData(Apttus_Config2__ConfigCustomClasses__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Config2__ConfigCustomDisplayActions__c.SObjectType,'apttus_config2__flow__c,apttus_config2__displaytype__c,apttus_config2__actionname__c','CSV',false)),
            getAttachment(export_objectData(Apttus_Config2__ConfigCustomDisplayColumns__c.SObjectType,'apttus_config2__flow__c,apttus_config2__displaytype__c,apttus_config2__fieldname__c','CSV',false)),
            getAttachment(export_objectData(Apttus_Config2__DataCache__c.SObjectType,'name','CSV',true)),
            getAttachment(export_objectData(Apttus_Config2__ConfigFieldExpressionsCriteriaFields__c.SObjectType,'Apttus_Config2__FieldName__c','CSV',false)),
            getAttachment(export_objectData(Apttus_Config2__ConfigFlow__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Config2__ConfigHeaderCriteriaFields__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Config2__ConfigLineItemCriteriaFields__c.SObjectType,'name','CSV',false)),
            getAttachment(export_objectData(Apttus_Config2__ConfigLineItemCustomFields__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Config2__ConfigSelectBundleOptionsSettings__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Config2__ConfigSelectConfigProductsSettings__c.SObjectType,'name','JSON',true)),
            getAttachment(export_objectData(Apttus_Config2__ConfigUserPreferences__c.SObjectType,'name','JSON',true))
        });
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }

    string export_objectData(SObjectType TempSObjTyp,string orderby,String fileType, Boolean needName){
        String returnString;
        sObjTyp = TempSObjTyp;
        lstFld = getAllFieldsQuery(sObjTyp);
        if(needName){
            lstFld.add('name');
        }
        string strQry = 'SELECT ' + string.join(lstFld,',') + 
                        ' FROM ' + sObjTyp.getDescribe().Name +
                        ' ' + '' + ' ' + ' order by '+ orderby;
        if(fileType == 'CSV'){
            returnString = CreateCSV(strQry,'');
        }
        else{
            returnString = CreateJSON(strQry,'');
        }
                            
        return returnString;
    }
    string export_FE(){
        sObjTyp = Apttus_Config2__FieldExpression__c.SObjectType;
        lstFld = getAllFieldsQuery(sObjTyp);
        lstFld.add('name');
        string strQry = 'SELECT ' + string.join(lstFld,',') + 
                        ' FROM ' + sObjTyp.getDescribe().Name +
                        ' ' + '' + ' ' + ' order by APTS_Ext_ID__c';
        return CreateCSV(strQry);
    }

    string export_PAR(){
        sObjTyp = Apttus_Config2__ProductAttributeRule__c.SObjectType;
        lstFld = getAllFieldsQuery(sObjTyp);
        lstFld.add('name');
        string strQry = 'SELECT ' + string.join(lstFld,',') + 
                        ' FROM ' + sObjTyp.getDescribe().Name +
                        ' ' + '' + ' ' + ' order by APTS_Ext_ID__c';
        return CreateCSV(strQry,'PAR');
    }

    string export_PARa(){
        sObjTyp = Apttus_Config2__ProductAttributeRuleAction__c.SObjectType;
        lstFld = getAllFieldsQuery(sObjTyp);
        lstFld.add('name');
        string strQry = 'SELECT ' + string.join(lstFld,',') + 
                        ' FROM ' + sObjTyp.getDescribe().Name +
                        ' ' + '' + ' ' + ' order by APTS_Ext_ID__c';
        

        return CreateCSV(strQry);
    }

    string export_PAGM_AttrExp(){
        sObjTyp = Apttus_Config2__ProductAttributeGroupMember__c.SObjectType;
        lstFld = getAllFieldsQuery(sObjTyp);
        lstFld = new list<string>();
        lstFld.add('apts_ext_id__c');
        lstFld.add('Apttus_Config2__ProductId__r.apts_ext_id__c');
        lstFld.add('Apttus_Config2__AttributeGroupId__r.apts_ext_id__c');
        lstFld.add('Apttus_Config2__ProductId__r.name');
        lstFld.add('Apttus_Config2__AttributeGroupId__r.name');

        lstFld.add('Apttus_Config2__FieldUpdateCriteriaIds__c');
        
        string strQry = 'SELECT ' + string.join(lstFld,',') + 
                        ' FROM ' + sObjTyp.getDescribe().Name +
                        ' ' + '' + ' ' + ' order by APTS_Ext_ID__c';
        return CreateCSV(strQry,'PAGM');
    }

    string export_POC_defQtyExp(){
        sObjTyp = Apttus_Config2__ProductOptionComponent__c.SObjectType;
        lstFld = getAllFieldsQuery(sObjTyp);
        lstFld = new list<string>();
        lstFld.add('apts_ext_id__c');
        lstFld.add('Apttus_Config2__ParentProductId__r.apts_ext_id__c');
        lstFld.add('Apttus_Config2__ComponentProductId__r.apts_ext_id__c');
        lstFld.add('Apttus_Config2__ParentProductId__r.name');
        lstFld.add('Apttus_Config2__ComponentProductId__r.name');

        lstFld.add('Apttus_Config2__DefaultQuantityExpressionId__r.apts_ext_id__c');
        lstFld.add('Apttus_Config2__DefaultQuantityExpressionId__r.Apttus_Config2__Expression__c');

        lstFld.add('Apttus_Config2__MaxQuantityExpressionId__r.apts_ext_id__c');
        lstFld.add('Apttus_Config2__MaxQuantityExpressionId__r.Apttus_Config2__Expression__c');

        lstFld.add('Apttus_Config2__MinQuantityExpressionId__r.apts_ext_id__c');
        lstFld.add('Apttus_Config2__MinQuantityExpressionId__r.Apttus_Config2__Expression__c');
        
        string strQry = 'SELECT ' + string.join(lstFld,',') + 
                        ' FROM ' + sObjTyp.getDescribe().Name +
                        ' where Apttus_Config2__DefaultQuantityExpressionId__c<>null ' + '' + ' ' + ' order by APTS_Ext_ID__c';
        return CreateCSV(strQry);
    }
    

    string CreateCSV(string strQry){
        return CreateCSV(strQry,'');
    }
    string CreateCSV(string strQry, string flag){
        List<sObject> sobjList = Database.query(strQry);
        List<sObject> sobjListToUpdt = new List<sObject>();
        string finalstr = '"' ;
        for(SObject SO: sobjList){
            if (flag!='PAGM' || so.get('Apttus_Config2__FieldUpdateCriteriaIds__c')!=null){
                if (finalstr == '"'){
                    for(string key:lstFld)
                        if(key!='id')
                            finalstr = finalstr + '","' + key;
                }
                finalstr = finalstr +'"\n"';
                for(string key:lstFld){
                    if (key=='apts_ext_id__c' && SO.get(key)==null){
                        SO.put('apts_ext_id__c',SO.get('id'));
                        sobjListToUpdt.add(SO);
                    }
                    if(key.contains('.')){
                        String nextField = key.substringAfter('.');
                        String relation = key.substringBefore('.');
                        if (SO.getSobject(relation)==null)
                            finalstr = finalstr  + '","' + '';
                        else
                            finalstr = finalstr  + '","' + SO.getSobject(relation).get(nextField);
                    }
                    else if(key!='id'){
                        //system.debug(flag + key + SO.get(key));
                        if (flag=='PAGM' && key == 'Apttus_Config2__FieldUpdateCriteriaIds__c' && (string)SO.get(key)!=null){
                            string keyVal = '';//updateToFldExpExtID((string)SO.get(key));
                            finalstr = finalstr  + '","' +  keyVal;
                        }
                        else if (flag=='PAR' && key == 'Apttus_Config2__ProductScope__c' && (string)SO.get(key)!='All'){
                            string keyVal = '';//updateToProdExtID((string)SO.get(key));
                            finalstr = finalstr  + '","' +  keyVal;
                        }
                        else if (flag=='PAR' && key == 'Apttus_Config2__ProductGroupScope__c' && (string)SO.get(key)!='All'){
                            string keyVal = '';//updateToProdGrpExtID((string)SO.get(key));
                            finalstr = finalstr  + '","' +  keyVal;
                        }
                        else{
                            finalstr = finalstr  + '","' + SO.get(key);
                        }
                    }
                }
            }
        }
        finalstr= finalstr+'"';
        if (!sobjListToUpdt.isempty())
            update sobjListToUpdt;
        return finalstr;
    }

    string CreateJSON(string strQry, string flag){
        List<sObject> sobjList = Database.query(strQry);
        List<sObject> sobjListToUpdt = new List<sObject>();
        string finalstr = '"' ;
        for(SObject SO: sobjList){
            for(string key:lstFld){
                if (key=='apts_ext_id__c' && SO.get(key)==null){
                    SO.put('apts_ext_id__c',SO.get('id'));
                    sobjListToUpdt.add(SO);
                }
                if(key.contains('.')){
                    String nextField = key.substringAfter('.');
                    String relation = key.substringBefore('.');
                    if (SO.getSobject(relation)==null)
                        finalstr = finalstr  + '' + key + ':' + '';
                    else
                        finalstr = finalstr  + '\n' + key + ':"'  + SO.getSobject(relation).get(nextField) + '"';
                }
                else if(key!='id'){
                    //system.debug(flag + key + SO.get(key));
                        finalstr = finalstr  + '\n' + key + ':"' + SO.get(key) + '"';
                }
            }
        }
        if (!sobjListToUpdt.isempty())
            update sobjListToUpdt;
        return finalstr;
    }

    
    Messaging.EmailFileAttachment getAttachment(string CSVtext){
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(CSVtext);
        string csvname= sObjTyp.getDescribe().Name+'.csv';
        csvAttc.setFileName(csvname);
        csvAttc.setBody(csvBlob);
        return csvAttc;
    }
    
    private list<string> getAllFieldsQuery(Schema.SObjectType sObjTyp){
        set<String> lstOfFields = new set<String>(sObjTyp.getDescribe().fields.getMap().keySet());
        for(string s:lstOfFields) {
            if (s.indexof('__c')<0 && s!='id'){
                lstOfFields.remove(s);
            }else if (mapOfStrToReplaceStr.containskey(s)){
                lstOfFields.remove(s);
                lstOfFields.add(mapOfStrToReplaceStr.get(s));
            }
        }
        list<String> lst = new list<string>(lstOfFields);
        lst.sort();
        return lst;
    }
}