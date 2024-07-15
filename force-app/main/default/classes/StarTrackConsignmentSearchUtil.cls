/**************************************************
* @Test StarTrackTrackingIDSearchUtil_Test,bspEnquiryUplift_Test,StarTrack_ConsignSearch_Controller_Test,ResourceV1IVRStarTrackSuccessful_Test

Description:	Util class that makes a web callout to search and upsert Consignment objects
				Need to use without sharing, as other user profile are calling the class
History:
--------------------------------------------------
2016-01-21 - Patrick James Franco - Created
2018-05-22 - nathan.franklin@auspost.com.au - Refactoring code. Deprecated generateSearchResult and removed generateHeader (moved into StarTrackConsignmentSearchUtil)
2018-06-19 - dilshan.egodawela@auspost.com.au - added an extra try catch to handle "ApexPages.addMessage", on searchConsignment method to haldble calles from non-pagecontroller
2018-07-01 - clint.dsilva@auspost.com.au - Added functionality to upsert Event Message Attachments
2018-10-12 - nathan.franklin@auspost.com.au - Added Attachment_Key__c as an external id for the Message attachment
2020-03-25 - Swati.mogadala@auspost.cm.au - Updated the method formatdate() to use format('dd-MMM-yyyy') instead of ('dd-MMM-YYYY') as per REQ2094412
2021-09-16 - prerna.rahangdale@auspost.cm.au - Updated the save Events method to popuate the truckId , FacilitySublocationId and FacilitySubLocationName for WP-40 Agg
2021-10-21 - naveen.rajanna@auspost.cm.au - Addded null check when making soql call and changed api version to 52
2024-07-12 - Seth Heang - Added new attributes to ConsignmentWrapper
**************************************************/
public without sharing class StarTrackConsignmentSearchUtil {

	static StarTrack_Settings__c stSettings = StarTrack_Settings__c.getOrgDefaults();

	/**
	 * StarTrack method that generates stub for async callout
	 * This is the handler for initiating an async request.
	 *
	 **/
	public static AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 generateAsyncStub() {

		AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 emsAsyncStub = new AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2();
		Map<String,String> httpHeaders = new Map<String,String>();
		String endpoint = '';
		String clientCert = '';

		// Basic Authentication
		if(stSettings.StarTrack_ConSearch_Authentication_Level__c == 1) {
			endpoint = stSettings.StarTrack_ConSearch_BA_Endpoint__c;
			httpHeaders.put(StarTrack_Constants.AUTHORIZATION, StarTrack_Constants.BASIC + stSettings.StarTrack_ConSearch_BA_Password__c);
		} else if(stSettings.StarTrack_ConSearch_Authentication_Level__c == 2) {
			// Client Certificate
			endpoint = stSettings.StarTrack_ConSearch_Cert_Endpoint__c;
			clientCert = stSettings.StarTrack_ConSearch_Client_Cert__c;
		}

		// defines the async params
		if(stSettings.Use_Continuation_for_Consignment_Search__c) {
			emsAsyncStub.endpoint_x = endpoint;

			if(!httpHeaders.isEmpty()) {
				emsAsyncStub.inputHttpHeaders_x = httpHeaders;
			}
			if(String.isNotBlank(clientCert)){
				emsAsyncStub.clientCertName_x = clientCert;
			}
		}

		return emsAsyncStub;
	}

	/**
	 * StarTrack method that generates header used in request
	 *
	 * @param sourceId Determines level of result to retrieve (BspConstants.BSP_SOURCEID / StarTrack_Constants.SOURCEID_SALESFORCE)
	 * @param userName Makes up a part of the Transaction Id in the header
	 */
	public static wwwAuspostComAuSchemaCustomercarema.Header generateHeader(String sourceId, String userName) {
		wwwAuspostComAuSchemaCustomercarema.Header header = new wwwAuspostComAuSchemaCustomercarema.Header();
		DateTime nowDT = DateTime.now();
		header.TimeStamp = nowDT;
		header.TransactionId = userName + '_' + nowDT.format(StarTrack_Constants.DATETIMEFORMAT);
		header.SourceId = sourceId;
		header.Action = StarTrack_Constants.ACTION_SEARCH;
		return header;
	}

	/**
	 * StarTrack method that generates search request
	 *
	 * @param value Connote Number / Invoice Id etc...
	 * @param searchType CONSIGNMENT / UNIQUEEXTERNALID / SUBDOCKET / REFERENCE_INVOICE / REFERENCE_BOOKING etc..
	 * @param action The level of result to provide (StarTrack_Constants.REQUEST_ACTION_FULL / StarTrack_Constants.REQUEST_ACTION_SUMMARY)
	 */
	public static wwwAuspostComAuSchemaCustomercarema.SearchRequest generateSearchRequest(String value, String searchType, String action) {
		wwwAuspostComAuSchemaCustomercarema.Header header = generateHeader(StarTrack_Constants.SOURCEID_SALESFORCE, UserInfo.getUserName());
		wwwAuspostComAuSchemaCustomercarema.SearchRequest request = new wwwAuspostComAuSchemaCustomercarema.SearchRequest();
		request.Header = header;
		request.Value = value;
		request.Type_x = searchType;
		request.Action = action;
		return request;
	}

	/**
	 * StarTrack method that generates search request
	 *
	 * @param value Connote Number / Invoice Id etc...
	 * @param searchType CONSIGNMENT / UNIQUEEXTERNALID / SUBDOCKET / REFERENCE_INVOICE / REFERENCE_BOOKING etc..
	 * @param action The level of result to provide (StarTrack_Constants.REQUEST_ACTION_FULL / StarTrack_Constants.REQUEST_ACTION_SUMMARY)
	 * @param sourceId Determines the profile of result to retrieve (BspConstants.BSP_SOURCEID / StarTrack_Constants.SOURCEID_SALESFORCE)
	 * @param userName Makes up a part of the Transaction Id in the header
	 */
	public static wwwAuspostComAuSchemaCustomercarema.SearchRequest generateSearchRequest(String value, String searchType, String action, String sourceId, String userName) {
		wwwAuspostComAuSchemaCustomercarema.Header header = generateHeader(sourceId, userName);
		wwwAuspostComAuSchemaCustomercarema.SearchRequest request = new wwwAuspostComAuSchemaCustomercarema.SearchRequest();
		request.Header = header;
		request.Value = value;
		request.Type_x = searchType;
		request.Action = action;
		return request;
	}

	/*------------------------------------------------------------
	Author:			Patrick James Franco
	Company:		Cloud Sherpas
	Description:	Method that will prepare a callout request to search for Consignments
	Inputs:			String, String, Date, Date, Date, String
	Returns:		ConsignmentWrapper
	History:
	January 21, 2016 - Patrick James Franco - Created
	February 18, 2016 - Patrick James Franco - Added logic for EVENTS callout type
	February 24, 2016 - Patrick James Franco - Added authentication to web callout
	------------------------------------------------------------*/
	public static ConsignmentWrapper searchConsignment(String searchString, String searchType, Date dateType, Date startdate, Date endDate, String searchSuburb){
		wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2 emsStub = new wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2();
		wwwAuspostComAuSchemaCustomercarema.ConsignmentData emsResponse;

		wwwAuspostComAuSchemaCustomercarema.Header header = new wwwAuspostComAuSchemaCustomercarema.Header();
		header.TimeStamp = DateTime.now();
		header.TransactionId = UserInfo.getUserName() + '_' + (DateTime.now()).format('YYYYMMddHHmmss');
		header.SourceId = 'Salesforce';
		header.Action = 'Search';

		wwwAuspostComAuSchemaCustomercarema.SearchRequest request = new wwwAuspostComAuSchemaCustomercarema.SearchRequest();
		request.Date_x = DateTime.now();
		request.Header = header;
		//request.Suburb = searchSuburb;
		request.Type_x = searchType;
		request.Value = searchString;
		if(stSettings.Get_All_Consignment_Details__c){
			request.Action = 'FULL';
		}
		else{
			request.Action = 'SUMMARY';
		}

		String endpoint = '';
		Map<String,String> httpHeaders = new Map<String,String>();
		String clientCert = '';

		// Basic Authentication
		if(stSettings.StarTrack_ConSearch_Authentication_Level__c == 1){
			endpoint = stSettings.StarTrack_ConSearch_BA_Endpoint__c;
			httpHeaders.put('Authorization','Basic ' + stSettings.StarTrack_ConSearch_BA_Password__c);
		}
		// Certificate
		else if(stSettings.StarTrack_ConSearch_Authentication_Level__c == 2){
			endpoint = stSettings.StarTrack_ConSearch_Cert_Endpoint__c;
			clientCert = stSettings.StarTrack_ConSearch_Client_Cert__c;
		}

		try{
			emsStub.endpoint_x = endpoint;
			if(!httpHeaders.isEmpty()){
				emsStub.inputHttpHeaders_x = httpHeaders;
			}
			if(String.isNotBlank(clientCert)){
				emsStub.clientCertName_x = clientCert;
			}
			emsStub.timeout_x = Integer.valueOf(stSettings.Sync_Web_Service_Callout_Timeout__c * 1000);

			System.debug('~~ request.Type_x : ' + request.Type_x);
			System.debug('~~ request : ' + request);

			if(request.Type_x.equals('UNIQUEEXTERNALID')){
				//edited temporarily to follow edited method, TODO: confirm if it will still be used
				//return processResponse(emsStub.Search_x(request));
				return processResponse(emsStub.Search_x(request), false);
			}
			else if(request.Type_x.equals('EVENTS')){
				processResponse(emsStub.Search_x(request), request.Value, 'EVENTS');
			}
		}
		catch(Exception e){
			GlobalUtility.logMessage('ERROR', 'StarTrackConsignmentSearchUtil', 'searchConsignment', '', 'Exception', e.getMessage(), String.valueOf(request), e, 0);
			//this method is also called from ResourceV1IVRStarTrackSuccessful class where addMessage is not possible. 
			//So as a fix we are using a try catch to catch the thrown exceptipn and log it in instead.
			try {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			}
			catch(Exception ex) {
					GlobalUtility.logMessage('ERROR', 'StarTrackConsignmentSearchUtil', 'searchConsignment', '', 'Exception', ex.getMessage(), String.valueOf(request), ex, 0);
			}
		}

		return null;
	}


	public static ConsignmentWrapper processResponse(wwwAuspostComAuSchemaCustomercarema.ConsignmentData emsResponse, boolean isConsole){
		return processResponse(emsResponse, isConsole, true);
	}

	/*------------------------------------------------------------
	Author:			Patrick James Franco
	Company:		Cloud Sherpas
	Description:	Method that will consume the callout response
	Inputs:			wwwAuspostComAuSchemaCustomercarema.ConsignmentData
	Returns:		ConsignmentWrapper
	History:
	January 21, 2016 - Patrick James Franco - Created
	------------------------------------------------------------*/
	public static ConsignmentWrapper processResponse(wwwAuspostComAuSchemaCustomercarema.ConsignmentData emsResponse, boolean isConsole, boolean isUI){
		try{

			// Single result
			if(emsResponse.Header.NbrOfRows == 1 || emsResponse.Consignment != NULL){
				Article__c thisConsignment = new Article__c();
				thisConsignment.RecordTypeId = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Consignment').getRecordTypeId();
				thisConsignment.ActualWeight__c = emsResponse.Consignment.ActualWeight;
				thisConsignment.ArticleID__c = emsResponse.Consignment.ConsignmentID;
				thisConsignment.Barcode__c = emsResponse.Consignment.BarcodeNumber;

				thisConsignment.Controlled_Return__c = (emsResponse.Consignment.ControlledReturn != null) ? emsResponse.Consignment.ControlledReturn : false;
				thisConsignment.Cubing__c = emsResponse.Consignment.Cubing;
				thisConsignment.Dangerous_Goods__c = (emsResponse.Consignment.DangerousGoods != null) ? emsResponse.Consignment.DangerousGoods : false;
				thisConsignment.Dangerous_Goods_Class__c = emsResponse.Consignment.DangerousGoodsClass;

				thisConsignment.DeliveryInstructions__c = emsResponse.Consignment.DeliveryInstructions ;
				thisConsignment.Dispatch_Date__c = emsResponse.Consignment.DispatchDate;
				thisConsignment.Dispatch_Date_Str__c = formatDate(emsResponse.Consignment.DispatchDate);
				thisConsignment.Dispatch_ID__c = emsResponse.Consignment.DispatchID;
				thisConsignment.InsuranceAmount__c = emsResponse.Consignment.InsuranceAmount;
				//thisConsignment.InsuranceRequired__c = emsResponse.Consignment.InsuranceRequired;
				thisConsignment.Last_Scan_Event__c = emsResponse.Consignment.LastScanEvent;
				thisConsignment.Last_Scan_Event_Str__c = formatDate(emsResponse.Consignment.LastScanEvent);
				thisConsignment.Name = emsResponse.Consignment.ConsignmentNumber;
				thisConsignment.Insurance_Class__c = emsResponse.Consignment.InsuranceClass;

				/*if(String.isNotBlank(emsResponse.Consignment.Network)){
					List<Network__c> networkList = [SELECT Id FROM Network__c WHERE Depot_Id__c = :emsResponse.Consignment.Network LIMIT 1];
					if(!networkList.isEmpty()){
						thisConsignment.Network__c = networkList[0].Id;
					}
				}*/
				thisConsignment.Depot_Specified_By_Source__c = emsResponse.Consignment.Network;
				thisConsignment.Number_of_Items__c = emsResponse.Consignment.NumberofItems;
				thisConsignment.POD__c = (emsResponse.Consignment.DoesithavePOD != null) ? emsResponse.Consignment.DoesithavePOD : false;
				thisConsignment.Receiver_Phone__c = emsResponse.Consignment.ReceiverPhone;
				thisConsignment.Receiver_Fax__c = emsResponse.Consignment.ReceiverFax;
				thisConsignment.Receiver_Mobile__c = emsResponse.Consignment.ReceiverMobile;
				thisConsignment.Receiver_Suburb__c = emsResponse.Consignment.ReceiverSuburb;
				thisConsignment.ReceiverAddress__c = emsResponse.Consignment.ReceiverAddress;
				thisConsignment.ReceiverAddressLine1__c = emsResponse.Consignment.ReceiverAddressLine1;
				thisConsignment.ReceiverAddressLine2__c = emsResponse.Consignment.ReceiverAddressLine2;
				thisConsignment.ReceiverAddressLine3__c = emsResponse.Consignment.ReceiverAddressLine3;
				thisConsignment.ReceiverAddressLine4__c = emsResponse.Consignment.ReceiverAddressLine4;
				thisConsignment.ReceiverCompany__c = emsResponse.Consignment.ReceiverCompany;
				thisConsignment.ReceiverCountry__c = emsResponse.Consignment.ReceiverCountry;
				thisConsignment.ReceiverEmail__c = emsResponse.Consignment.ReceiverEmail;
				thisConsignment.ReceiverName__c = emsResponse.Consignment.ReceiverName;
				thisConsignment.ReceiverPostcode__c = emsResponse.Consignment.ReceiverPostcode;
				thisConsignment.ReceiverState__c = emsResponse.Consignment.ReceiverState;
				thisConsignment.Sender_Suburb__c = emsResponse.Consignment.SenderSuburb;
				thisConsignment.SenderAddress__c = emsResponse.Consignment.SenderAddress;
				thisConsignment.SenderAddressLine1__c = emsResponse.Consignment.SenderAddressLine1;
				thisConsignment.SenderAddressLine2__c = emsResponse.Consignment.SenderAddressLine1;
				thisConsignment.SenderAddressLine3__c = emsResponse.Consignment.SenderAddressLine3;
				thisConsignment.SenderAddressLine4__c = emsResponse.Consignment.SenderAddressLine4;
				thisConsignment.SenderCompany__c = emsResponse.Consignment.SenderCompany;
				thisConsignment.SenderCountry__c = emsResponse.Consignment.SenderCountry;
				thisConsignment.SenderEmail__c = emsResponse.Consignment.SenderEmail;
				thisConsignment.SenderName__c = emsResponse.Consignment.SenderName;
				thisConsignment.SenderPostcode__c = emsResponse.Consignment.SenderPostcode;
				thisConsignment.SenderState__c = emsResponse.Consignment.SenderState;
				thisConsignment.Sender_Phone__c = emsResponse.Consignment.SenderPhone;
				thisConsignment.Sender_Fax__c = emsResponse.Consignment.SenderFax;
				thisConsignment.Sender_Mobile__c = emsResponse.Consignment.SenderMobile;
				thisConsignment.ServiceCode__c = emsResponse.Consignment.ServiceCode;
				thisConsignment.Subdocket__c = emsResponse.Consignment.SubdocketNumber;
				thisConsignment.Unit_Type__c = emsResponse.Consignment.UnitType;
				thisConsignment.ExpectedDeliveryDate__c = emsResponse.Consignment.ExpectedDeliveryDate;
				thisConsignment.ExpectedDeliveryDate_Str__c = formatDate(thisConsignment.ExpectedDeliveryDate__c);
				thisConsignment.ArticleTransitAmountValue__c = emsResponse.Consignment.InsuranceAmount;
				thisConsignment.SenderAddressLine2__c = emsResponse.Consignment.SenderAddressLine2;
				thisConsignment.Service_Description__c = emsResponse.Consignment.ServiceDescription;
				thisConsignment.Manifest_Reference__c = emsResponse.Consignment.ManifestReference;
				thisConsignment.Print_Date__c = emsResponse.Consignment.PrintDate;
				thisConsignment.Print_Date_Str__c = formatDate(emsResponse.Consignment.PrintDate);
				thisConsignment.ConsignmentParcelCount__c = emsResponse.Consignment.ConsignmentParcelCount;
				thisConsignment.Imported_Date__c = emsResponse.Consignment.ImportedDate;
				thisConsignment.Imported_Date_Str__c = formatDate(emsResponse.Consignment.ImportedDate);
				thisConsignment.CID__c = emsResponse.Consignment.CID;
				thisConsignment.Manifest_Date__c = emsResponse.Consignment.ManifestDate;
				thisConsignment.Manifest_Date_Str__c = formatDate(emsResponse.Consignment.ManifestDate);
				thisConsignment.Length__c = emsResponse.Consignment.Length;
				thisConsignment.Width__c = emsResponse.Consignment.Width;
				thisConsignment.Height__c = emsResponse.Consignment.Height;
				thisConsignment.Cubic_Weight__c = emsResponse.Consignment.CubicWeight;
				thisConsignment.Charge_Weight__c = emsResponse.Consignment.ChargeWeight;
				thisConsignment.Volume__c = emsResponse.Consignment.Volume;
				thisConsignment.Invoice__c = emsResponse.Consignment.Invoice;
				thisConsignment.Customer_Type__c = emsResponse.Consignment.CustomerType;
				thisConsignment.FurtherReference1__c = emsResponse.Consignment.FurtherReference1;
				thisConsignment.FurtherReference2__c = emsResponse.Consignment.FurtherReference2;
				thisConsignment.Delivery_Window__c = emsResponse.Consignment.DeliveryWindow;
				thisConsignment.SMS_Notify_Flag__c = (emsResponse.Consignment.SMSNotifyFlag != null) ? emsResponse.Consignment.SMSNotifyFlag : false;
				thisConsignment.Email_Notify_Flag__c = (emsResponse.Consignment.EmailNotifyFlag != null) ? emsResponse.Consignment.EmailNotifyFlag : false;
				thisConsignment.ATL_Flag__c = (emsResponse.Consignment.ATLFlag != null) ? emsResponse.Consignment.ATLFlag : false;
				thisConsignment.Deliver_On_Date__c = emsResponse.Consignment.DeliverOnDate;
				thisConsignment.Deliver_On_Date_Str__c = formatDate(emsResponse.Consignment.DeliverOnDate);
				thisConsignment.Bookin_Flag__c = (emsResponse.Consignment.BookinFlag != null) ? emsResponse.Consignment.BookinFlag : false;
				thisConsignment.BookIn_Not_Before__c = emsResponse.Consignment.BookInNotBefore;
				thisConsignment.BookIn_Not_Before_Str__c = formatDate(emsResponse.Consignment.BookInNotBefore);
				thisConsignment.BookIn_Not_After__c = emsResponse.Consignment.BookInNotAfter;
				thisConsignment.BookIn_Not_After_Str__c = formatDate(emsResponse.Consignment.BookInNotAfter);
				thisConsignment.UN_Number__c = emsResponse.Consignment.UNNumber;
				thisConsignment.Description_of_Goods__c = emsResponse.Consignment.DescriptionofGoods;
				thisConsignment.Transfer_Movement__c = (emsResponse.Consignment.TransferMovement != null) ? emsResponse.Consignment.TransferMovement : false;
				thisConsignment.International__c = (emsResponse.Consignment.International != null) ? emsResponse.Consignment.International : false; 
				thisConsignment.Source_System__c = emsResponse.Consignment.SourceSystem;
				thisConsignment.Dispatch_Depot__c = emsResponse.Consignment.DispatchDepot;
				thisConsignment.Freight_Amount__c = emsResponse.Consignment.FreightAmount;
				thisConsignment.Consignment_Summary_Status__c = emsResponse.Consignment.SummaryStatus;

				//24-07-17 Dion Gunn: Below added to manage Additional/Surcharge info from Startrack
				String concatenatedAttributes = '';
				if(emsResponse.Consignment.Attributes != null) {
					for(Integer i=0;i < emsResponse.Consignment.Attributes.Attribute.size();i++) {
						String attribute = emsResponse.Consignment.Attributes.Attribute[i] + ',';
						concatenatedAttributes += attribute;
					}

					thisConsignment.Additionals__c = concatenatedAttributes.removeEnd(',');
				}

				if(emsResponse.Consignment.BillingAccount != null) {
					List<Billing_Account__c> billingAccount = new List<Billing_Account__c>([SELECT Id FROM Billing_Account__c WHERE LEGACY_ID__c =: emsResponse.Consignment.BillingAccount LIMIT 1]);

					if (billingAccount != null && !billingAccount.isEmpty()) {
						thisConsignment.Billing_Account__c = billingAccount[0].Id;
					}
				}

				thisConsignment.Last_Update_Received__c = DateTime.now();

				/*else if (!String.isEmpty(stSettings.Default_Billing_Account__c)) {
					thisConsignment.Billing_Account__c = Id.valueOf(stSettings.Default_Billing_Account__c);
				} else {
					System.debug('~~ No BILLING ACCOUNT : ' + emsResponse.Consignment.BillingAccount);
					return new ConsignmentWrapper(false, 'Billing Account with ID ' + emsResponse.Consignment.BillingAccount + ' not found', new List<Article__c>());
				}*/

				try{
					String startTimeStamp = String.valueOf(DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
					System.debug('~~ thisConsignment : ' + thisConsignment);
					System.debug('~~ thisConsignment.Last_Update_Received__c : ' + thisConsignment.Last_Update_Received__c);
					UPSERT thisConsignment ArticleID__c;
					String endTimeStamp = String.valueOf(DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));

					if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
						StarTrackIntegrationLogging.logRequestResponse('StarTrackConsignmentSearchUtil', 'processResponse', thisConsignment.ArticleID__c, 'INT-UPSERT >> START - consignment', startTimeStamp, emsResponse);
						StarTrackIntegrationLogging.logRequestResponse('StarTrackConsignmentSearchUtil', 'processResponse', thisConsignment.ArticleID__c, 'INT-UPSERT >> END - consignment', endTimeStamp, emsResponse);
					}
				}
				catch(Exception e){
					System.debug('~~~ UPSERT ERROR ' + e.getMessage());
					if(isUI) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
					} else {
						GlobalUtility.logMessage('ERROR', 'StarTrackConsignmentSearchUtil', 'processResponse', '', 'Exception', e.getMessage(), '', e, 0);
						throw e;
					}
				}
				
				// Save Articles
				if (emsResponse.Consignment.Articles != null) {
					System.debug('UNSORTABLE SAVE ARTICLE WITH UPSERT '+emsResponse.Consignment.ConsignmentID+ ' - '+ emsResponse.Consignment.Articles.Article);
					saveArticles(emsResponse.Consignment.Articles.Article, emsResponse.Consignment.ConsignmentID);
				}

				if(stSettings.Get_All_Consignment_Details__c || (!stSettings.Get_All_Consignment_Details__c && !isConsole)){
					
					String startTimeStamp = String.valueOf(DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
					
					// Save Consignment Events
					if(emsResponse.Consignment.Events != null){
						List<EventMessage__c> eventMsgs = saveEvents(emsResponse.Consignment.Events.Event, emsResponse.Consignment.ConsignmentID);
						if (!eventMsgs.isEmpty()) {
							UPSERT eventMsgs EventID__c;
						}
					}
					// Save Article Events
					if(emsResponse.Consignment.Articles != null){
						saveArticleEvents(emsResponse.Consignment.Articles.Article);
					}
					// Save Book In Notes
					if(emsResponse.Consignment.BookinNotes != null){
						saveBookInNotes(emsResponse.Consignment.BookinNotes.BookinNote, emsResponse.Consignment.ConsignmentID);
					}
					// Save Sub Dockets
					if(emsResponse.Consignment.SubDockets != null){
						saveSubdockets(emsResponse.Consignment.SubDockets.SubDocket, emsResponse.Consignment.ConsignmentID);
					}
					// Save Proof Of Deliveries
					if(emsResponse.Consignment.ProofOfDeliveries != null){
						saveProofOfDeliveries(emsResponse.Consignment.ProofOfDeliveries.ProofOfDelivery, emsResponse.Consignment.ConsignmentID);
					}
					
					String endTimeStamp = String.valueOf(DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
					
					if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
						StarTrackIntegrationLogging.logRequestResponse('StarTrackConsignmentSearchUtil', 'processResponse', thisConsignment.ArticleID__c, 'INT-UPSERT >> START - events, articles, bookinnotes, subdockets, pod', startTimeStamp, emsResponse);
						StarTrackIntegrationLogging.logRequestResponse('StarTrackConsignmentSearchUtil', 'processResponse', thisConsignment.ArticleID__c, 'INT-UPSERT >> END - events, articles, bookinnotes, subdockets, pod', endTimeStamp, emsResponse);
					}
				}

				return new ConsignmentWrapper(true, '0', new List<Article__c>{thisConsignment});
			}
			// Multiple results
			else if(emsResponse.Header.NbrOfRows > 1){
				List<Article__c> articleList = new List<Article__c>();

				for(wwwAuspostComAuSchemaCustomercarema.DUPCON_DataDetail data : emsResponse.SearchResults.Results.DUPCON_DataDetail){
					Article__c thisConsignment = new Article__c();
					thisConsignment.ArticleID__c = data.UniqueExternalId;
					thisConsignment.Name = data.Consignment;
					thisConsignment.ReceiverName__c = data.ReceiverName;
					thisConsignment.Receiver_Suburb__c = data.ReceiverSuburb;
					thisConsignment.Dispatch_Date__c = data.DateSent;
					thisConsignment.SenderName__c = data.SenderName;
					thisConsignment.ReceiverAddress__c = data.ReceiverAddress;
					thisConsignment.Dispatch_Date_Str__c = formatDate(data.DateSent);
					//Added by David Catindoy (Feb. 23, 2017)
					thisConsignment.Consignment_Summary_Status__c = data.SummaryStatus;
					thisConsignment.ExpectedDeliveryDate__c = Date.valueOf(data.ExpectedDeliveryDate);
					articleList.add(thisConsignment);
				}

				return new ConsignmentWrapper(false, '0', articleList);
			}
			// Found nothing
			else{
				return new ConsignmentWrapper(false, 'Article Not Found', new List<Article__c>());
			}
		}
		catch(Exception e){
			if (e.getMessage().contains('Signature XString: data value too large') || e.getMessage().contains('Billing Account with ID ')) {
				GlobalUtility.logMessage('ERROR', 'StarTrackConsignmentSearchUtil', 'processResponse', '', 'Exception', e.getMessage(), '', e, 0);
				throw e;
			} else {
				GlobalUtility.logMessage('ERROR', 'StarTrackConsignmentSearchUtil', 'processResponse', '', 'Exception', e.getMessage(), '', e, 0);
				return new ConsignmentWrapper(false, e.getMessage(), new List<Article__c>());
			}
		}
	}

	/*------------------------------------------------------------
	Author:			Jen Karen Tan
	Company:		Cloud Sherpas
	Description:	Method that will convert DateTime values to Date
	Inputs:			DateTime
	Returns:		Date
	History:
	February 24, 2016 - Jen Karen Tan - Created
	------------------------------------------------------------*/
	public static Date convertDateTimeToDate(DateTime dateTimeValue) {
		Date dateValue = null;
		if (dateTimeValue != null) {
			dateValue = date.newInstance(dateTimeValue.year(), dateTimeValue.month(), dateTimeValue.day());
		}
		return dateValue;
	}

	/*------------------------------------------------------------
	Author:			Jen Karen Tan
	Company:		Cloud Sherpas
	Description:	Method that will convert Date values to DateTime
	Inputs:			Date
	Returns:		DateTime
	History:
	April 8, 2016 - Jen Karen Tan - Created
	------------------------------------------------------------*/
	public static DateTime convertDateToDateTime(Date dateValue) {
		DateTime dateTimeValue = null;
		if (dateValue != null) {
			dateTimeValue = DateTime.newInstance(dateValue.year(), dateValue.month(), dateValue.day());
		}
		return dateTimeValue;
	}

	/*------------------------------------------------------------
	Author:			Jen Karen Tan
	Company:		Cloud Sherpas
	Description:	Method that will convert Date or DateTime values to String
	Inputs:			Object
	Returns:		String
	History:
	April 8, 2016 - Jen Karen Tan - Created
	------------------------------------------------------------*/
	public static String formatDate(Date dateValue) {
		String dateStrValue = '';
		if (dateValue != null) {
			dateStrValue = convertDateToDateTime(dateValue).format('dd-MMM-yyyy');
		}
		return dateStrValue;
	}
	public static String formatDate(DateTime dateValue) {
		String dateStrValue = '';
		if (dateValue != null) {
			dateStrValue = DateTime.newInstance(dateValue.yearGmt(), dateValue.monthGmt(), dateValue.dayGmt()).format('dd-MMM-yyyy');
			dateStrValue += convertTo12hrStr(dateValue);
		}
		return dateStrValue;
	}

	public static String convertTo12hrStr(DateTime dateTimeValue) {
		String timeStr = '';
		String mm = dateTimeValue.minuteGmt() == 0 ? '00' : String.valueOf(dateTimeValue.minuteGmt());
		mm = (dateTimeValue.minuteGmt() != 0 && dateTimeValue.minuteGmt() < 10) ? ('0' + mm) : mm;
		if (dateTimeValue.hourGmt() == 0) {
			timeStr = '12:' + mm + ' AM';
		} else if (dateTimeValue.hourGmt() > 12) {
			timeStr = String.valueOf(dateTimeValue.hourGmt() - 12) + ':' + mm + ' PM';
		} else if (dateTimeValue.hourGmt() == 12) {
			timeStr = String.valueOf(dateTimeValue.hourGmt()) + ':' + mm + ' PM';
		} else {
			timeStr = String.valueOf(dateTimeValue.hourGmt()) + ':' + mm + ' AM';
		}
		return timeStr;
	}


	/*------------------------------------------------------------
	Author:			Patrick James Franco
	Company:		Cloud Sherpas
	Description:	Method that will consume the callout response without upserting Consignment/Article
	Inputs:			wwwAuspostComAuSchemaCustomercarema.ConsignmentData
	Returns:
	History:
	February 18, 2016 - Patrick James Franco - Created
	------------------------------------------------------------*/
	public static void processResponse(wwwAuspostComAuSchemaCustomercarema.ConsignmentData emsResponse, String parentId, String calloutType){
		try{
			if(emsResponse.Consignment != NULL && String.isNotBlank(calloutType)){
				if(calloutType.equals('EVENTS')){
					if(emsResponse.Consignment.Articles != null){
						System.debug('UNSORTABLE SAVE ARTICLE NO UPSERT '+emsResponse.Consignment.Articles.Article);
						saveArticles(emsResponse.Consignment.Articles.Article, parentId);
					}
					// Save Consignment Events
					if(emsResponse.Consignment.Events != null){
						List<EventMessage__c> eventMsgs = saveEvents(emsResponse.Consignment.Events.Event, parentId);
						if (!eventMsgs.isEmpty()) {
							UPSERT eventMsgs EventID__c;
						}
						
						Article__c thisConsignment = new Article__c();
						thisConsignment.Last_Update_Received__c = DateTime.now();
						thisConsignment.ArticleID__c = parentId;

						UPSERT thisConsignment ArticleID__c;
						System.debug('~~ thisConsignment (from scan events) : ' + thisConsignment);
					}
					// Save Article Events
					if(emsResponse.Consignment.Articles != null){
						saveArticleEvents(emsResponse.Consignment.Articles.Article);
					}
				}
			}
		}
		catch(CalloutException e){
			GlobalUtility.logMessage('ERROR', 'StarTrack_Case_ConsignSearch_ControllerX', 'processSearchConsignment', '', 'CalloutException', e.getMessage(), '', e, 0);

			if(e.getMessage().contains('Time out')){
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, Consignment_Search_Settings__c.getValues('Search Consignment Timeout').Field_Name__c));
			}
			else if(e.getMessage().contains('Failed to get next element') || e.getMessage().contains('Policy Falsified')){
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Authentication_Error__c));
			}
			else if(e.getMessage().contains('Could not find client cert with dev name')){
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Client_Cert_Error__c));
			}
		}
		catch(Exception e){
			GlobalUtility.logMessage('ERROR', 'StarTrackConsignmentSearchUtil', 'processResponse', '', 'Exception', e.getMessage(), '', e, 0);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
		}
	}


	public static list<Event_Message_Attachment__c> saveEventAttachment( list<wwwAuspostComAuSchemaCustomercarema.AttachmentType> thisAttachmentLst , String parentId){
		list<Event_Message_Attachment__c> RtnAttchLst = new list<Event_Message_Attachment__c>();
		if(thisAttachmentLst != null){
			for(wwwAuspostComAuSchemaCustomercarema.AttachmentType eAttType : thisAttachmentLst ){
				if(eAttType != null){
					Event_Message_Attachment__c thisAttch = new Event_Message_Attachment__c();
					thisAttch.EventMessage__r = new EventMessage__c(EventID__c = parentId);
					thisAttch.Msg_Description__c = eAttType.Description;
					thisAttch.Msg_Name__c = eAttType.Name;
					thisAttch.Attachment_Key__c = parentId + (String.isEmpty(eAttType.Description) ? '' : eAttType.Description);
					RtnAttchLst.add(thisAttch);
				}
			}
		}
		return RtnAttchLst;
	}


	/*------------------------------------------------------------
	Author:			Patrick James Franco
	Company:		Cloud Sherpas
	Description:	Method that will save Event Messages
	Inputs:			List<wwwAuspostComAuSchemaCustomercarema.EventType>, String
	Returns:		List<EventMessage__c>
	History:
	January 21, 2016 - Patrick James Franco - Created
	------------------------------------------------------------*/
	public static List<EventMessage__c> saveEvents(List<wwwAuspostComAuSchemaCustomercarema.EventType> thisEventList, String parentId){
		List<EventMessage__c> eventList = new List<EventMessage__c>();

		if(thisEventList != null){
			for(wwwAuspostComAuSchemaCustomercarema.EventType eventMsg : thisEventList){
				EventMessage__c thisEvent = new EventMessage__c();

				thisEvent.RecordTypeId = getRecordTypeIdForEventMessage(eventMsg.EventType);

				thisEvent.Article__r = new Article__c(ArticleID__c = parentId);
				thisEvent.ActualDateTime__c = eventMsg.ActualDateTime;
				thisEvent.ActualDateTime_TimeStamp__c = formatDate(eventMsg.ActualDateTime);
				thisEvent.CommentText__c = eventMsg.CommentText;
				thisEvent.EventDescription__c = eventMsg.EventDescription;
				thisEvent.EventID__c = eventMsg.EventID;
				thisEvent.EventSource__c = eventMsg.EventSource;
				thisEvent.EventType__c = eventMsg.EventType;
				thisEvent.SignatoryName__c = eventMsg.SignatoryName;
				thisEvent.UserName__c = eventMsg.UserName;
				thisEvent.Event_Sub_Type__c = eventMsg.EventSubType;
				thisEvent.Depot_Code__c = eventMsg.DepotCode;
				thisEvent.Depot_Name__c = eventMsg.DepotName;
				thisEvent.Event_Completion_Time__c = eventMsg.EventCompletionTime;
				thisEvent.Event_Completion_Time_TimeStamp__c = formatDate(eventMsg.EventCompletionTime);
				thisEvent.Route_Reference__c = eventMsg.RouteReference;
				thisEvent.NHCL_Barcode_No__c = eventMsg.NHCLBarcodeNo;
				thisEvent.ATL_Barcode__c = eventMsg.ATLBarcodeNo;
				thisEvent.Machine_ID__c = eventMsg.MachineID;
				thisEvent.Length__c = eventMsg.Length;
				thisEvent.Width__c = eventMsg.Width;
				thisEvent.Height__c = eventMsg.Height;
				thisEvent.Weight__c = eventMsg.Weight;
				thisEvent.Volume__c = eventMsg.Volume;
				
				thisEvent.Post_Office_Name__c = eventMsg.PostOfficeName;
				thisEvent.Post_Office_Code__c = eventMsg.PostOfficeCode;

				thisEvent.Address_Type__c = eventMsg.AddressType;
				thisEvent.Address_Line_1__c = eventMsg.AddressLine1;
				thisEvent.Address_Line_2__c = eventMsg.AddressLine2;
				thisEvent.Address_Line_3__c = eventMsg.AddressLine3;
				thisEvent.Address_Post_Code__c = eventMsg.AddressPostCode;
				thisEvent.City__c = eventMsg.City;
				thisEvent.Phone__c = eventMsg.Phone;
				thisEvent.Name__c = eventMsg.Name;
				thisEvent.Contact_Name__c = eventMsg.ContactName;
				thisEvent.Rego__c = eventMsg.Rego;
				thisEvent.From_Destination__c = eventMsg.FromDestination;
				thisEvent.To_Destination__c = eventMsg.ToDestination;
				thisEvent.Destination_Post_Code__c = eventMsg.DestinationPostCode;
				thisEvent.Decision_ID__c = eventMsg.DecisionID;
				if (thisEvent.Decision_ID__c != null) {
					List<String> decIdStr = thisEvent.Decision_ID__c.split(':');
					if (decIdStr != null && decIdStr.size() > 1) {
						try {
							thisEvent.Scan_Count__c = Integer.valueOf(decIdStr[1]);
						} catch (Exception e) {
							System.debug('Decision Id second value cannot be converted to Integer.');
						}
					}
				}
				thisEvent.Redirect_Count__c = eventMsg.RedirectCount;
				thisEvent.Discharge_Chute_ID__c = eventMsg.DischargeChuteID;
				thisEvent.Scanner_ID__c = eventMsg.ScannerID;
				thisEvent.Scan_Mode__c = eventMsg.ScanMode;
				thisEvent.Booking_Reference__c = eventMsg.BookingReference;
				thisEvent.Type__c = eventMsg.LaneType;
				thisEvent.Read__c = eventMsg.Read;
				thisEvent.Source_System__c = eventMsg.SourceSystem;
				thisEvent.Event_Type_Code__c = eventMsg.EventTypeCode;
				//Added by David Catindoy (Feb. 23, 2017)
				thisEvent.ShowtoExternals__c = eventMsg.DisplayExt == null ? false : eventMsg.DisplayExt;
				thisEvent.ExternalDescription__c = eventMsg.ExtDesc;
				// Prerna Rahangdale AggWP-40 Start
				thisEvent.TruckId__c = eventMsg.TruckId;
				thisEvent.FacilitySubLocationId__c = eventMsg.FacilitySubLocationId;
				thisEvent.FacilitySubLocationName__c = eventMsg.FacilitySubLocationName;
				// Prerna Rahangdale AggWP-40 End

				if(eventMsg.EventID == null){
					String tStamp = string.valueof(eventMsg.EventCompletionTime);
					tStamp = tStamp.replace('-','');
					tStamp = tStamp.replace(':','');
					tStamp = tStamp.replace(' ','');
					thisEvent.EventID__c = parentId + '_' + tStamp;
				}
				eventList.add(thisEvent);
			}
			System.debug('~~ UPSERT : eventList : ' + eventList);
			//UPSERT eventList EventID__c;
		}
		return eventList;
	}

	/*------------------------------------------------------------
	Author:			Jen Karen Tan
	Company:		Cloud Sherpas
	Description:	Method that determine Event Message's Record Type base on Event Type
	Inputs:			String eventType
	Returns:
	History:
	April 4, 2016 - Jen Karen Tan - Created
	------------------------------------------------------------*/
	public static Id getRecordTypeIdForEventMessage(String eventType) {
		Id recordTypeId = null;
		if (String.isBlank(eventType) 
			|| StarTrackConsignmentConstants.EVENT_TYPE_TRTR_OUTG.equals(eventType) 
			|| StarTrackConsignmentConstants.EVENT_TYPE_TRTR_PKUP.equals(eventType) 
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_MANIFESTED.equals(eventType) 
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_PICKED_UP.equals(eventType)
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_BOOKIN.equals(eventType)
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_TRUCK_OUT.equals(eventType)) {
			recordTypeId = Schema.SObjectType.EventMessage__c.getRecordTypeInfosByName().get(StarTrackConsignmentConstants.REC_TYPE_EVENT_MESSAGE_ST_PICKUP_EVENT).getRecordTypeId();
		} else if (StarTrackConsignmentConstants.EVENT_TYPE_TRTR_DELV.equals(eventType) 
			|| StarTrackConsignmentConstants.EVENT_TYPE_TRTR_ATL.equals(eventType)
			|| StarTrackConsignmentConstants.EVENT_TYPE_TRTR_ADA.equals(eventType)
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_DELIVERED.equals(eventType) 
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_RETURNED.equals(eventType)
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_UNSGND_AIR_SAT.equals(eventType)
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_REDELIVER.equals(eventType)) {
			recordTypeId = Schema.SObjectType.EventMessage__c.getRecordTypeInfosByName().get(StarTrackConsignmentConstants.REC_TYPE_EVENT_MESSAGE_ST_DELIVERY_ATL_NHCL_MANFEVNT).getRecordTypeId();
		} else if (StarTrackConsignmentConstants.EVENT_TYPE_TRTR_INCG.equals(eventType) 
			|| StarTrackConsignmentConstants.EVENT_TYPE_TRTR_HATB.equals(eventType)
			|| StarTrackConsignmentConstants.EVENT_TYPE_TRTR_TRSF.equals(eventType)
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_HELD.equals(eventType) 
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_RET_SENDER.equals(eventType)
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_RECONSIGNED.equals(eventType)
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_NZ_SCANNING.equals(eventType)
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_TRANSFER.equals(eventType) 
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_REFSD_PEND.equals(eventType)
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_FINAL_SHORTGE.equals(eventType)
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_LBL_SCN_TRNST.equals(eventType)
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_SCNND_IN_TRNST.equals(eventType)) {
			recordTypeId = Schema.SObjectType.EventMessage__c.getRecordTypeInfosByName().get(StarTrackConsignmentConstants.REC_TYPE_EVENT_MESSAGE_ST_INCG_HATB_TRSF_EVNT).getRecordTypeId();
		} else if (StarTrackConsignmentConstants.EVENT_TYPE_TRTR_ASN.equals(eventType) 
			|| StarTrackConsignmentConstants.EVENT_TYPE_TRTR_FMMF.equals(eventType)
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_CONN_RET.equals(eventType) 
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_REG_BMS.equals(eventType)
			|| StarTrackConsignmentConstants.EVENT_TYPE_TEAM_POD_FILED.equals(eventType)) {
			recordTypeId = Schema.SObjectType.EventMessage__c.getRecordTypeInfosByName().get(StarTrackConsignmentConstants.REC_TYPE_EVENT_MESSAGE_ST_OTHR_EVENT).getRecordTypeId();
		} else if (StarTrackConsignmentConstants.EVENT_TYPE_TRTR_CUBE.equals(eventType)) {
			recordTypeId = Schema.SObjectType.EventMessage__c.getRecordTypeInfosByName().get(StarTrackConsignmentConstants.REC_TYPE_EVENT_MESSAGE_ST_CUBE_EVENT).getRecordTypeId();
		} else {
			recordTypeId = Schema.SObjectType.EventMessage__c.getRecordTypeInfosByName().get(StarTrackConsignmentConstants.REC_TYPE_EVENT_MESSAGE_ST_PICKUP_EVENT).getRecordTypeId();
		}
		return recordTypeId;
	}

	/*------------------------------------------------------------
	Author:			Patrick James Franco
	Company:		Cloud Sherpas
	Description:	Method that will save Consignment's Articles
	Inputs:			List<wwwAuspostComAuSchemaCustomercarema.ArticleType>, String
	Returns:
	History:
	January 21, 2016 - Patrick James Franco - Created
	------------------------------------------------------------*/
	public static void saveArticles(List<wwwAuspostComAuSchemaCustomercarema.ArticleType> thisArticleList, String parentId){
		Id articleRecTypeId = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Article').getRecordTypeId();
		List<Article__c> articleList = new List<Article__c>();

		DateTime dtNow = DateTime.now();
		if(thisArticleList != null){
			for(wwwAuspostComAuSchemaCustomercarema.ArticleType resultArticle : thisArticleList){
				System.debug('DG: Article: ' + resultArticle);
				Article__c thisArticle = new Article__c();
				thisArticle.RecordTypeId = articleRecTypeId;
				thisArticle.Consignment__r = new Article__c(ArticleID__c = parentId);
				thisArticle.Source_System__c = resultArticle.SourceSystem;
				thisArticle.ArticleID__c = resultArticle.ArticleID;
				thisArticle.Name = resultArticle.ArticleNumber;
				thisArticle.Last_Update_Received__c = dtNow;

				//24-07-17 Dion Gunn: Below added to manage Additional/Surcharge info from Startrack
				String concatenatedAttributes = '';
				if(resultArticle.Attributes != null) {
					for(Integer i=0;i < resultArticle.Attributes.Attribute.size();i++) {
						String attribute = resultArticle.Attributes.Attribute[i] + ',';
						concatenatedAttributes += attribute;
					}

					thisArticle.Additionals__c = concatenatedAttributes.removeEnd(',');
				}
				articleList.add(thisArticle);
			}
			
			System.debug('~~ UPSERT : articleList : ' + articleList);
			UPSERT articleList ArticleID__c;
		}
	}

	/*------------------------------------------------------------
	Author:			Patrick James Franco
	Company:		Cloud Sherpas
	Description:	Helper method that will save Article's Event Messages
	Inputs:			List<wwwAuspostComAuSchemaCustomercarema.Article>
	Returns:
	History:
	January 21, 2016 - Patrick James Franco - Created
	------------------------------------------------------------*/
	public static void saveArticleEvents(List<wwwAuspostComAuSchemaCustomercarema.ArticleType> articleList){
		if(articleList != null){
			List<EventMessage__c> allEventMsgs = new List<EventMessage__c>();
			for(wwwAuspostComAuSchemaCustomercarema.ArticleType savedArticle : articleList){
				List<EventMessage__c> eventMsgs = new List<EventMessage__c>(saveEvents(savedArticle.Events.Event, savedArticle.ArticleID));
				if (!eventMsgs.isEmpty()) {
					allEventMsgs.addAll(eventMsgs);
				}
			}
			System.debug('~~ UPSERT : articleEventsList : ' + allEventMsgs);
			if (!allEventMsgs.isEmpty()) {
				UPSERT allEventMsgs EventID__c ;

				// Save Article Events Attachments
				list<Event_Message_Attachment__c> evtAttchLst = new list<Event_Message_Attachment__c>();
				if(articleList != null){
					for(wwwAuspostComAuSchemaCustomercarema.ArticleType savedArticle : articleList){
						if(savedArticle != null && savedArticle.Events != null && savedArticle.Events.Event != null ){
							for(wwwAuspostComAuSchemaCustomercarema.EventType savedEvent : savedArticle.Events.Event){
								if(savedEvent != null && savedEvent.Attachments != null && savedEvent.Attachments.Attachment != null ){

									list<Event_Message_Attachment__c> evtAttchLstTmp = saveEventAttachment(savedEvent.Attachments.Attachment, savedEvent.eventID);
									if(evtAttchLstTmp != null){
										evtAttchLst.addAll(evtAttchLstTmp) ;
									}
								}
							}
						}
					}
				}



				if(!evtAttchLst.isEmpty()){
					upsert evtAttchLst Attachment_Key__c;
				}
			}
		}
	}

	/*------------------------------------------------------------
	Author:			Patrick James Franco
	Company:		Cloud Sherpas
	Description:	Method that will save Consignment's Book In Notes
	Inputs:			List<wwwAuspostComAuSchemaCustomercarema.BookinNoteType>, String
	Returns:
	History:
	February 16, 2016 - Patrick James Franco - Created
	------------------------------------------------------------*/
	public static void saveBookInNotes(List<wwwAuspostComAuSchemaCustomercarema.BookinNoteType> thisBookInNoteList, String parentId){
		List<Book_In_Note__c> bookInNoteList = new List<Book_In_Note__c>();

		if(thisBookInNoteList != null){
			for(wwwAuspostComAuSchemaCustomercarema.BookinNoteType resultBookInNote : thisBookInNoteList){
				Book_In_Note__c thisBookInNote = new Book_In_Note__c();
				thisBookInNote.Name = resultBookInNote.BookinNoteId;
				thisBookInNote.BookInNoteExtId__c = resultBookInNote.BookinNoteId;
				thisBookInNote.By__c = resultBookInNote.By_x;
				thisBookInNote.Consignment__r = new Article__c(ArticleID__c = parentId);
				thisBookInNote.Data_Sourced_From__c = resultBookInNote.DataSourcedFrom;
				thisBookInNote.Date_Entered__c = resultBookInNote.DateEntered;
				thisBookInNote.Date_Entered_Str__c = formatDate(resultBookInNote.DateEntered);
				thisBookInNote.Notes__c = resultBookInNote.Notes;
				thisBookInNote.Number_of_Records__c = resultBookInNote.NumberofRecords;
				thisBookInNote.Start_From__c = resultBookInNote.StartFrom;
				thisBookInNote.Start_From_Str__c = formatDate(resultBookInNote.StartFrom);
				thisBookInNote.Date_Entered__c = resultBookInNote.DateEntered;
				thisBookInNote.Date_Entered_Str__c = formatDate(resultBookInNote.DateEntered);
				bookInNoteList.add(thisBookInNote);
			}
			
			System.debug('~~ UPSERT : bookInNoteList : ' + bookInNoteList);
			UPSERT bookInNoteList BookInNoteExtId__c;

		}
	}

	/*------------------------------------------------------------
	Author:			Patrick James Franco
	Company:		Cloud Sherpas
	Description:	Method that will save Consignment's Sub Dockets
	Inputs:			List<wwwAuspostComAuSchemaCustomercarema.SubDocketType>, String
	Returns:
	History:
	February 16, 2016 - Patrick James Franco - Created
	------------------------------------------------------------*/
	public static void saveSubdockets(List<wwwAuspostComAuSchemaCustomercarema.SubDocketType> thisSubDocketList, String parentId){
		List<Sub_Docket__c> subDocketList = new List<Sub_Docket__c>();

		if(thisSubDocketList != null){
			for(wwwAuspostComAuSchemaCustomercarema.SubDocketType resultSubDocket : thisSubDocketList){
				Sub_Docket__c thisSubDocket = new Sub_Docket__c();
				thisSubDocket.Name = resultSubDocket.SubDocketId;
				thisSubDocket.SubDocketExtId__c = resultSubDocket.SubDocketId;
				thisSubDocket.Consignment__r = new Article__c(ArticleID__c = parentId);
				thisSubDocket.Date_Registered__c = resultSubDocket.DateRegistered;
				thisSubDocket.Date_Registered_Str__c = formatDate(resultSubDocket.DateRegistered);
				thisSubDocket.Delivery_Depot__c = resultSubDocket.DeliveryDepot;
				thisSubDocket.Description__c = resultSubDocket.Description;
				thisSubDocket.Payer__c = resultSubDocket.PayerName;
				thisSubDocket.Payer_Account_Number__c = resultSubDocket.PayerAccountNumber;
				thisSubDocket.Supervisor__c = resultSubDocket.Supervisor;
				subDocketList.add(thisSubDocket);
			}
			
			System.debug('~~ UPSERT : subDocketList : ' + subDocketList);
			UPSERT subDocketList SubDocketExtId__c;
		}
	}

	/*------------------------------------------------------------
	Author:			Patrick James Franco
	Company:		Cloud Sherpas
	Description:	Method that will save Consignment's Proof Of Deliveries
	Inputs:			List<wwwAuspostComAuSchemaCustomercarema.ProofOfDeliveryType>, String
	Returns:
	History:
	February 16, 2016 - Patrick James Franco - Created
	------------------------------------------------------------*/
	public static void saveProofOfDeliveries(List<wwwAuspostComAuSchemaCustomercarema.ProofOfDeliveryType> thisPODList, String parentId){
		List<Proof_of_Delivery__c> podList = new List<Proof_of_Delivery__c>();

		if(thisPODList != null){
			for(wwwAuspostComAuSchemaCustomercarema.ProofOfDeliveryType resultPOD : thisPODList){
				Proof_of_Delivery__c thisPOD = new Proof_of_Delivery__c();
				thisPOD.Name = resultPOD.PODId;
				thisPOD.PODExtId__c = resultPOD.PODId;
				thisPOD.Consignment__r = new Article__c(ArticleID__c = parentId);
				thisPOD.Article_Listing__c = resultPOD.ArticleListing;
				thisPOD.Delivery_Address__c = resultPOD.DeliveryAddress;
				thisPOD.POD_Received_Date__c = resultPOD.PODReceivedDate;
				thisPOD.POD_Received_Date_Str__c = formatDate(resultPOD.PODReceivedDate);
				thisPOD.QC_Status__c = resultPOD.QCStatus;
				thisPOD.SignatureXString__c = resultPOD.SignatureXString;
				thisPOD.Signed_by__c = resultPOD.Signedby;
				thisPOD.POD_Type__c = resultPOD.PODType;
				podList.add(thisPOD);
			}
			
			System.debug('~~ UPSERT : podList : ' + podList);
			UPSERT podList PODExtId__c;
		}
	}

	/*------------------------------------------------------------
	Author:			Patrick James Franco
	Company:		Cloud Sherpas
	Description:	Wrapper class that contains
	History:
	January 21, 2016 - Patrick James Franco - Created
	------------------------------------------------------------*/
	public class ConsignmentWrapper {
		public Boolean isConsignmentSaved { get; set; }
		public String errorCode { get; set; }
		public List<Article__c> articleList { get; set; }
		public List<String> warningMessages { get; set; }
		public AdditionalStarTrackCallout requiredAdditionalCallout { get; set; }

		public ConsignmentWrapper(Boolean isConsignmentSaved, String errorCode, List<Article__c> articleList) {
			this.isConsignmentSaved = isConsignmentSaved;
			this.errorCode = errorCode;
			this.articleList = articleList;
		}

		public ConsignmentWrapper(Boolean isConsignmentSaved, String errorCode, List<Article__c> articleList, List<String> warningMessages) {
			this.isConsignmentSaved = isConsignmentSaved;
			this.errorCode = errorCode;
			this.articleList = articleList;
			this.warningMessages = warningMessages;
		}

		public ConsignmentWrapper(Boolean isConsignmentSaved, String errorCode, List<Article__c> articleList, AdditionalStarTrackCallout additionalCallout) {
			this.isConsignmentSaved = isConsignmentSaved;
			this.errorCode = errorCode;
			this.articleList = articleList;
			this.requiredAdditionalCallout = additionalCallout;
		}
	}
	
	/**
	 * @description Used to store an information related to additional StarTrack callout for Duplicate Consignment scenario
	 */
	public class AdditionalStarTrackCallout {
		public String searchType { get; set; }
		public String value { get; set; }

		public AdditionalStarTrackCallout(String searchType, String value) {
			this.searchType = searchType;
			this.value = value;
		}
	}

	/*------------------------------------------------------------
	Author:			Jen Karen Tan
	Company:		Cloud Sherpas
	Description:	Method that logs request/response
	History:
	April 19, 2016 - Jen Karen Tan - Created
	------------------------------------------------------------*/
	/*public static void log(DateTime sendDateTime, String userName, String consignmentNumber, DateTime rcveDateTime, String xml) {
		ExceptionLog__c e = new ExceptionLog__c();
		e.Send_DateTime__c = sendDateTime;
		e.UserName__c = userName;
		e.ConsignmentNumber__c = consignmentNumber;
		e.Receive_DateTime__c = rcveDateTime;
		e.XML__c = xml;
		insert e;
	}*/

	public static Boolean isFromWebservice(List<Article__c> articles) {
		Boolean isFromWebservice = true;
		for (Article__c a : articles) {
			if (a.Source_System__c != 'TEAM' && a.Source_System__c != 'TRACK & TRACE') {
				isFromWebservice = false;
				break;
			}
		}
		return isFromWebservice;
	}

	public static Boolean isFromWebservice(List<EventMessage__c> eventMsgs) {
		Boolean isFromWebservice = true;
		for (EventMessage__c em : eventMsgs) {
			if (em.Source_System__c != 'TEAM' && em.Source_System__c != 'TRACK & TRACE') {
				isFromWebservice = false;
				break;
			} 
		}
		return isFromWebservice;
	}

	public static Boolean isWaitDone(String articleId) {
		Boolean waitDone = false;
		if(!String.isBlank(articleId)) {
			List<Article__c> articles = new List<Article__c>([Select Id, ArticleID__c, Last_Update_Received__c FROM Article__c WHERE ArticleID__c =: articleId]);

			if (stSettings.Wait_In_Minutes_Before_Searching_Events__c == null) {
				waitDone = true;
			} else if (!articles.isEmpty() && stSettings.Wait_In_Minutes_Before_Searching_Events__c != null && articles[0].Last_Update_Received__c != null
				&& (articles[0].Last_Update_Received__c.addMinutes(Integer.valueOf(stSettings.Wait_In_Minutes_Before_Searching_Events__c))) < DateTime.now() ) {
				waitDone = true;
			}
		}
		return waitDone;
	}

}