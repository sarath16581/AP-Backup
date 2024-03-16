/* 
 * @changelog
 * 2021-08-11 - Seth Heang - Decommision the use of 'al' package by uplifting the soql query and uplift API version to 52
 * 2022-09-08 - Naveen Rajanna - REQ2963906: Added runningInASandbox method
 * 
*/public class Util {
    public static integer MAX_COLLECTION_SIZE = 1000;
    
    public static string googleMapClient(){
        string result = '';
        AusPostSettings__c settings = AusPostSettings__c.getValues('GMKey_DoNotDeleteANDDoNotDistribute');
        if(settings != null && settings.isActive__c != null && settings.isActive__c){
            result = '&client=' + settings.ApplicationName__c;
        }
        return result;
    }
    
    public static string googleMapRequest(string url){
        AusPostSettings__c settings = AusPostSettings__c.getValues('GMKey_DoNotDeleteANDDoNotDistribute');
        string result = url + '&client=' + settings.ApplicationName__c;
        string privateKey = settings.AppKey__c.trim().replace('-', '+').replace('_', '/');
        Blob privateKeyBlob = EncodingUtil.base64Decode(privateKey);
        Blob urlBlob = Blob.valueOf(result);
        Blob signatureBlob = Crypto.generateMac('hmacSHA1', urlBlob, privateKeyBlob);
        String signature = EncodingUtil.base64Encode(signatureBlob);
        result += '&signature=' + signature.replace('+', '-').replace('/', '_');
        return result;
    }
    
    public static string cleanPhoneString(string phone){
        string result = phone.replaceAll('[\\D]', '');
        if(result.length() >= 9){
            result = result.substring(result.length()-9, result.length());
        } 
        return result;
    }
    
    public static string reversePhoneString(string phone){
        string result = '';
        if(!string.isEmpty(phone)) {
            string cleanPhone = cleanPhoneString(phone);
            string[] chars = cleanPhone.split('');
            // Split('') in API version 52, automatically remove whitespace from first character so below line is no longer needed
            //chars.remove(0);
            for(string s: chars){
                result = s + result;
            }
        }
        return result;
    }
    
    public static string searchablePhoneString(string phone){
        string result = '';
        if(!string.isEmpty(phone)) {
            string cleanPhone = cleanPhoneString(phone);
            string[] chars = cleanPhone.split('');
            // Split('') in API version 52, automatically remove whitespace from first character so below line is no longer needed
            //chars.remove(0);
            for(string s: chars){
                result += '%' + s;
            }
        }
        return result;
    }

    public static ID contactIDForNameAndEmail(string fullname, string email){
        string result = null;
        if (email != null && fullname !=null) {
            string name = '%' + fullname.trim();
            List<Contact> contacts = [select id from contact where email=:email.trim() and name like :name order by email, CRMCSSOID__c Nulls Last, APCN__c Nulls Last, createddate];
            if(contacts.size() > 0){
                result = contacts[0].id;
            } 
        }                           
        return result;
    } 
    
    public static string replaceMergeFields(SObject obj, string content){
        system.debug('George says: content = ' + content);
        string result = content;
        string regex = '\\{!' + obj.getSObjectType().getDescribe().getName() + '\\.[a-zA-Z0-9. ]*\\}';
        system.debug('George says: regex = ' + regex);
        
        Map<String, Schema.SObjectField> fieldNames = obj.getSObjectType().getDescribe().fields.getMap();
        Pattern p = Pattern.compile(regex);
        Matcher m = p.matcher(result);
        string fieldName = null;
        while(m.find()){
            try {
                system.debug('George says: match = ' + m.group());
                List<string> l = m.group().split('\\.');
                system.debug('George says: splitting ' + l);
                fieldName = m.group().split('\\.')[1].replace('}', '').trim();
                system.debug('George says: fieldname = ' + fieldName);
                system.debug('George says: fieldNames = ' + fieldNames);
                if(fieldNames.containsKey(fieldName)) {
                    system.debug('George says: replacing with ' + string.valueof(obj.get(fieldName)));
                    result = result.replace(m.group(), string.valueof(obj.get(fieldName)));
                    system.debug('George says: result = ' + result);
                }
            } catch(SObjectException ex) {
                result = result.replace(m.group(), '[' + fieldName + ' is not loaded]');
            }
        }
        return result;
    }
    
    /*
     * The following method is pending for decommission in future date
    */
    public static string getBodyFromEmailTemplate(string templateUniqueName, ID targetObjectId, ID whatId){
        string result = '';
        EmailTemplate et;
        for(EmailTemplate template : [Select body from EmailTemplate where DeveloperName=:templateUniqueName]) {
            et = template;
        }
        if(et != null) {
            SavePoint sp = Database.setSavePoint();
            try {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(et.id);
                mail.setTargetObjectId(targetObjectId);
                mail.setWhatId(whatId);
                mail.setUseSignature(false);
                mail.setBccSender(false);
                mail.setSaveAsActivity(false);
                
                SObject[] objs;
                // Task WhoId can be either Contact or Lead, so check object type and call appropriate selector class for the SOQL query
                if(targetObjectId.getSObjectType().getDescribe().getName() == 'Contact'){
                    objs = ContactsSelector.newInstance().selectById(new Set<Id>{targetObjectId}).values();
                }else if(targetObjectId.getSObjectType().getDescribe().getName() == 'Lead'){
                    objs = LeadsSelector.newInstance().selectById(new Set<Id>{targetObjectId}).values();
                }
                if(objs.size() > 0) {                   
                    string email = string.valueof(objs[0].get('email')); 
                    if(email == null || email.trim() == ''){
                        objs[0].put('email', 'xxxxxx@xxxxxx.com');
                        update objs[0]; 
                    }
                    system.debug('George says: about to fake sendEmail....'); 
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});  
                    result = mail.getHtmlBody();
                    if(result == null)
                        result = mail.getPlainTextBody();

                    system.debug('George says: result = ' + result);
                }
            } finally {
                system.debug('George says: done... rolling back');
                Database.rollback(sp);
            }
        }
        return result;
    }
    
    public static Map<String, RecordType> getRecordTypesByDeveloperName(String sObjectName) {
       Map<String, RecordType> recordTypesByDeveloperName = new Map<String, RecordType>();
       
       List<RecordType> recordTypes =  
            [SELECT     Id, 
                        Name, 
                        DeveloperName 
             FROM       RecordType 
             WHERE      IsActive = true 
              AND      SobjectType = :sObjectName];
                     
        for(RecordType recordType :recordTypes)
            recordTypesByDeveloperName.put(recordType.DeveloperName, recordType); //recordType.DeveloperName, recordType);

        return recordTypesByDeveloperName;        
    }
    
     public static Map<String, String> getRecordTypesDevNameById(String sObjectName) {

       Map<String, String> RecordTypesDevNameById = new Map<String, String>();
       
       List<RecordType> recordTypes =  
            [SELECT     Id, 
                        Name, 
                        DeveloperName 
             FROM       RecordType 
             WHERE      IsActive = true 
              AND      SobjectType = :sObjectName];
                     
        for(RecordType recordType :recordTypes)
            RecordTypesDevNameById.put(recordType.id, recordType.DeveloperName); //recordType.DeveloperName, recordType);

        return RecordTypesDevNameById;        
    }
    
    public static Map<String, string> getRecordTypesNameById(String sObjectName) {
       Map<String, String> RecordTypesNameById = new Map<String, String>();
       
       List<RecordType> recordTypes =  
            [SELECT     Id, 
                        Name, 
                        DeveloperName 
             FROM       RecordType 
             WHERE      IsActive = true 
              AND      SobjectType = :sObjectName];
                     
        for(RecordType recordType :recordTypes)
            RecordTypesNameById.put(recordType.id, recordType.Name); //recordType.DeveloperName, recordType);

        return RecordTypesNameById;      
    }   
    
    public static string replacePlaceholders(object obj, string content){
        string result = content;
        
        
        
        return result;
    }
    
    public static Attachment createAttachment(String name, String b64, String contentType, Id parentId)
    {
        Attachment a = new Attachment(Name = name);
        if (b64 != null)
        {
            Blob b = EncodingUtil.base64Decode(b64);
            a.Body = b;
        }
        a.ContentType = contentType;
        a.ParentId = parentId;
        return a;
    }
    
    // Returns a dynamic SOQL statement for the whole object, includes only creatable fields since we will be inserting a cloned result of this query
    public static string getCreatableFieldsSOQL(String objectName, String whereClause){
         
        String selects = '';
         
        if (whereClause == null || whereClause == ''){ return null; }
         
        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string>();
         
        if (fMap != null){
            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                if (fd.isCreateable()){ // field is creatable
                    selectFields.add(fd.getName());
                }
            }
        }
         
        if (!selectFields.isEmpty()){
            for (string s:selectFields){
                selects += s + ',';
            }
            if (selects.endsWith(',')){selects = selects.substring(0,selects.lastIndexOf(','));}
             
        }
         
        return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;
         
    }

    // Returns true if running from Sandbox
    public static Boolean runningInASandbox {
        get {
            if(runningInASandbox == null) {
                runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            }
            return runningInASandbox;
        }
        set;
    }
	
	@InvocableMethod(label='Get Record URL')
    public static List<String> getRecordUrl(List<String> recordIds) {
        List<String> recordUrls = new List<String>();
        for (String recordId : recordIds) {
            // Construct the URL for the record detail page
            String recordUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId;
            recordUrls.add(recordUrl);
        }
        return recordUrls;
    }
}