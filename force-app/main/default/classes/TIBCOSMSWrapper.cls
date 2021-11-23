public with sharing class TIBCOSMSWrapper {
	static final string SUCCESS_CODE = 'ESB-SMS-10000';
	
	public static string sendSMS(string phone, string message){
		string result = '';
		try {
			TIBCOSMSActivityEvent.SMSHTTPS11Binding_v1 sms = new TIBCOSMSActivityEvent.SMSHTTPS11Binding_v1();
			AusPostSettings__c smsSettings = AusPostSettings__c.getValues('TIBCOSMS');
			sms.endpoint_x = smsSettings.URL__c;
			/*sms.clientCert_x = smsSettings.ApplicationName__c;
			sms.clientCertName_x = smsSettings.Username__c;
			sms.clientCertPasswd_x = smsSettings.Password__c;*/
			
			sms.Header = new TIBCOSMSDataModelCommon.InterfaceHeader();
	        sms.Header.InterfaceName = 'sendSMS';
	        sms.Header.InterfaceVersion = '1.0';
	        sms.Header.MessageType = 'Request';
	        sms.Header.BusinessReferenceID = 'SMS-' + System.now().format('ddMMyyyyHHmmssSSS');
	        sms.Header.SourceSystemID = 'SFDC';
	        sms.Header.Timestamp = System.now();

			TIBCOSMSDataModelEvent.ReturnMessage_element r = sms.sendSMS_v1(phone, message);

			if(r != null && r.Code != null && r.Code.equals(SUCCESS_CODE)){
				result = 'Success:' + r.Description;
			}else {
				result = 'Error:' + r.Description;
			}
		}catch(Exception ex){
			system.debug('George says: Unable to send SMS via TIBCO = ' + ex.getMessage());
			result = 'Error: Unable to send SMS via TIBCO = ' + ex.getMessage();
		}
		
		
		return result;
	}

}