/**
  * @author       : disha.kariya@auspost.com.au
  * @date         : 24/06/2017
  * @description  : Queueable class to send band update to COM
  * /*******************************  History ************************************************
    *24/06/2017        disha.kariya@auspost.com.au   Created
    *01/05/2020        disha.kariya@auspost.com.au   Modified to create exception log
	*26/08/2024			changing exception email to default support email
  */
  global class SendProductDetailstoCOM implements System.Queueable, Database.AllowsCallouts {
    private List<Asset> assetList;

	private static final String DEFAULT_NOTIFICATIONEMAIL = 'DLITRCPCMSalesforceSupport@auspost.com.au';

	private static UserDeactivationSettings__c CONFIG {
		get {
			if(CONFIG == null) {
				CONFIG = UserDeactivationSettings__c.getOrgDefaults();
			}
			return CONFIG;
		}
		private set;
	}

	private static final String CONFIG_NOTIFICATIONEMAIL = String.valueOf(CONFIG?.NotificationEmail__c) ?? DEFAULT_NOTIFICATIONEMAIL;

    public sendProductDetailstoCOM(List<Asset> assetList) {
        this.assetList = assetList;
    }

    public void execute(QueueableContext qc) {
        
        String token = '';
        String TOKEN_REQUEST = 'asset';
//        AusPostSettings__c bsoTibco= AusPostSettings__c.getValues('BSO_TIBCO');
        HttpRequest req = new HttpRequest();
        String username = bsoTibco.Username__c;
        String password= bsoTibco.Password__c;
        String businessRef = 'Salesforce' + bsoTibco.Number1__c;
        DateTime DT = System.now();
        String timeStamp = DT.format('yyyy-MM-dd\'T\'HH:mm:ss');
        System.debug('bsoTibco---->'+bsoTibco);
        try{
            Http http = new Http();
            req.setEndpoint(bsoTibco.URL__c);
            req.setMethod('PUT');
            Blob headerValue = Blob.valueOf(username +':' +password);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            System.debug('Encoder Value' + EncodingUtil.base64Encode(headerValue));
            req.setHeader('Authorization', authorizationHeader);
            req.setHeader('business_reference_id',businessRef);
            req.setHeader('source_system_id','Salesforce');
            req.setHeader('request_timestamp',timeStamp);
            HttpResponse res;
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeFieldName(TOKEN_REQUEST);
            gen.writeStartArray();
            for(Asset a : assetList){
                gen.writeStartObject();
                gen.writeStringField('asset_id', a.Account_Legacy_Id__c);
                gen.writeStringField('product_name', a.Product_Name__c);
                gen.writeEndObject();
            }
            gen.writeEndArray();
            gen.writeEndObject();
            System.debug(gen.getAsString());
            req.setBody(gen.getAsString());
//            if(Test.isRunningTest())
//            {
//                System.debug('Before MOck---->');
//              //  Test.setMock(HttpCalloutMock.class, new BSOtoTibcoIntegration());
//                System.debug('After MOck---->');
//            }
//            else{
                res = http.send(req);
                System.debug(res.getBody());
                //JSONParser parser = JSON.createParser(res.getBody());
                //System.debug('parser---->'+parser);
//            }
            bsoTibco.Number1__c = bsoTibco.Number1__c+1;
            update bsoTibco;
        }
        catch(Exception exp) {
            // Error Logged to Exception object for analysis
            handleException(exp, UserInfo.getOrganizationId());
        }
    }

    public  void handleException(Exception exp, String orgID) {


        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        String[] toAddresses = new String[]{
			CONFIG_NOTIFICATIONEMAIL
        };

        mail.setToAddresses(toAddresses);

        mail.setSubject('Salesforce to TiBco Integration');

        System.debug('exp---->' + exp);

        mail.setPlainTextBody('The integration failed due to ' + exp + ' <---Records failed are --->' + assetList);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                mail
        });

        UTIL_LoggingService.logHandledException(exp, orgID, 'BSO TIBCO Integration',

                'sendProductDetailstoCOMIntegration', 'execute',

                null, LoggingLevel.ERROR);
    }

    public AusPostSettings__c bsoTibco {
        get {
            if(bsoTibco == null) {
                bsoTibco = AusPostSettings__c.getValues('BSO_TIBCO');
            }
            return bsoTibco;
        }
        private set;
    }
}