/***
 * @author Nathan Franklin
 * @date 2024-05-16
 * @changelog
 */
public class TIBCOArticleSubscriptionSOAPService {
	private static final String s_ns0 = 'http://soap.sforce.com/2005/09/outbound';

	public class CaseNotification {
		public String Id;
		public TIBCOArticleSubscriptionSchema.Case_x sObject_x;
		private transient String[] Id_type_info = new String[]{'Id',s_ns0,'ID','1','1','false'};
		private transient String[] sObject_x_type_info = new String[]{'sObject',s_ns0,'Case','1','1','false'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'Id','sObject_x'};
	}

	public class Notification {
		public String endpoint_x = 'https://salesforce-bw.auspost.com.au:10543/Services/CustomerContractManagement_v1/CreateAdminEventPortEndpoint';
		public Map<String,String> inputHttpHeaders_x;
		public Map<String,String> outputHttpHeaders_x;
		public String clientCertName_x;
		public String clientCert_x;
		public String clientCertPasswd_x;
		public Integer timeout_x;
		private transient String[] ns_map_type_info = new String[]{'urn:enterprise.soap.sforce.com','enterpriseSoapSforceCom','urn:sobject.enterprise.soap.sforce.com','sobjectEnterpriseSoapSforceCom','http://soap.sforce.com/2005/09/outbound','ArticleSubscriptionService'};

		public Boolean notifications(String OrganizationId, String ActionId, String SessionId, String EnterpriseUrl, String PartnerUrl, TIBCOArticleSubscriptionSOAPService.CaseNotification Notification) {

			TIBCOArticleSubscriptionSOAPService.notifications_element request_x = new TIBCOArticleSubscriptionSOAPService.notifications_element();
			TIBCOArticleSubscriptionSOAPService.notificationsResponse_element response_x;

			request_x.OrganizationId = OrganizationId;
			request_x.ActionId = ActionId;
			request_x.SessionId = SessionId;
			request_x.EnterpriseUrl = EnterpriseUrl;
			request_x.PartnerUrl = PartnerUrl;
			request_x.Notification = Notification;

			// A map of key-value pairs that represent the response that the external service sends after receiving the request. In each pair, the key is a response identifier. The value is the response object, which is an instance of a type that is created as part of the auto-generated stub class.
			Map<String, TIBCOArticleSubscriptionSOAPService.notificationsResponse_element> response_map_x = new Map<String, TIBCOArticleSubscriptionSOAPService.notificationsResponse_element>();

			response_map_x.put('response_x', response_x);

			WebServiceCallout.invoke(
					this, // stub - An instance of the Apex class that is auto-generated from a WSDL (the stub class).
					request_x, // request - The request to the external service. The request is an instance of a type that is created as part of the auto-generated stub class.
					response_map_x, // response
					new String[]{
							endpoint_x, // the URL of the external web service
							'', // The SOAP action.
							s_ns0, // The request namespace.
							'notifications', // The request name.
							s_ns0, // The response namespace.
							'notificationsResponse', // The response name.
							'TIBCOArticleSubscriptionSOAPService.notificationsResponse_element'} // The response type.
			);

			response_x = response_map_x.get('response_x');
			System.debug('SETH response_x: ' + response_x);

			return response_x.Ack;
		}
	}

	public class notifications_element {
		public String OrganizationId;
		public String ActionId;
		public String SessionId;
		public String EnterpriseUrl;
		public String PartnerUrl;
		public TIBCOArticleSubscriptionSOAPService.CaseNotification Notification;
		private transient String[] OrganizationId_type_info = new String[]{'OrganizationId',s_ns0,'ID','1','1','false'};
		private transient String[] ActionId_type_info = new String[]{'ActionId',s_ns0,'ID','1','1','false'};
		private transient String[] SessionId_type_info = new String[]{'SessionId',s_ns0,'string','1','1','true'};
		private transient String[] EnterpriseUrl_type_info = new String[]{'EnterpriseUrl',s_ns0,'string','1','1','false'};
		private transient String[] PartnerUrl_type_info = new String[]{'PartnerUrl',s_ns0,'string','1','1','false'};
		private transient String[] Notification_type_info = new String[]{'Notification',s_ns0,'CaseNotification','1','100','false'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'OrganizationId','ActionId','SessionId','EnterpriseUrl','PartnerUrl','Notification'};
	}

	public class notificationsResponse_element {
		public Boolean Ack;
		private transient String[] Ack_type_info = new String[]{'Ack',s_ns0,'boolean','1','1','false'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'Ack'};
	}
}