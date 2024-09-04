/**
 * Test class for TIBCOArticleService
 *
 * @author di.chen
 * @date 2014-06-24
 * @changelog
 * 2017-10-29  nathan.franklin@auspost.com.au  Added error test to trigger exception handling in TIBCODataTranslator
 * 2020-04-10  nathan.franklin@auspost.com.au  Added product and sub product names to the mock payload
 * 2020-04-10  nathan.franklin@auspost.com.au  Updated createArticles and getArticles method
 * 2020-06-04  arjun.singh@auspost.com.au      Modified to consume Sorting related attributes for MyNetwork Community
 * 2020-10-27  disha.kariya@auspost.com.au     Added delivery ETA values from payload
 * 2021-07-01	disha.kariya@auspost.com.au     Added changes for Outside delivery radius and Geo Precision.
 * 2021-07-01	prerna.rahangdale@auspost.com.au     Added changes for Truck Id , Facility Subloaction and Facility SubLoaction Name changes.
 * 2021-10-15 - Nathan Franklin - Increase TIBCOConsignmentWrapper coverage
 * 2024-05-21 - Seth Heang - update article test data  and consignment test data with additional mappings for testing
 */
@isTest
public class TIBCO_Test {
	enum DeliveryAddressType {
		DELIVERY,
		xRETURN,
		PICKUP
	}

	static testMethod void testTIBCOArticleWrapper() {
		List<Article__c> arts = createArticles();
		Article__c art = arts[0];
		Article__c art2 = arts[1];
		Article__c art3 = arts[2];
		Map<Id, List<EventMessage__c>> articleToEventMessages = createEMByArticle(arts);

		TIBCOArticleWrapper testconstructor1_1 = new TIBCOArticleWrapper(art, articleToEventMessages);
		TIBCOArticleWrapper testconstructor1_2 = new TIBCOArticleWrapper(art2, articleToEventMessages);
		TIBCOArticleWrapper testconstructor1_3 = new TIBCOArticleWrapper(art3, articleToEventMessages);

		TIBCOArticleWrapper testconstructor2 = new TIBCOArticleWrapper(null);

		AuspostQueryTrackEventsSchema.ArticleEnvelope ae = createArticleEnvelope();

		TIBCOConsignmentWrapper consiginWrapper = new TIBCOConsignmentWrapper(art, new List<Article__c>{ art2, art3 }, articleToEventMessages);
		TIBCOArticleWrapper testconstructor3 = new TIBCOArticleWrapper(ae, consiginWrapper);
		testconstructor3.copySenderReceiverDetails(testconstructor3, consiginWrapper);
	}

	static testMethod void testTIBCOConsignmentWrapper() {
		AuspostQueryTrackEventsSchema.ConsignmentDetails_element celement = createConsignmentElement();
		TIBCOConsignmentWrapper testWrapper = new TIBCOConsignmentWrapper(celement);

		celement = createConsignmentElement(false, DeliveryAddressType.PICKUP);
		testWrapper = new TIBCOConsignmentWrapper(celement);
	}

	static testMethod void testTIBCOTrackingResultWrapperAndDatATranslator() {
		List<Article__c> arts = createArticles();
		Article__c art = arts[0];
		Article__c art2 = arts[1];
		Article__c art3 = arts[2];
		Map<Id, List<EventMessage__c>> articleToEventMessages = createEMByArticle(arts);
		Map<String, List<Article__c>> consArticles = new Map<String, List<Article__c>>();
		consArticles.put(art.Id, new List<Article__c>{ art2, art3 });

		TIBCOTrackingResultWrapper testWrapper1 = new TIBCOTrackingResultWrapper(art, consArticles, articleToEventMessages);

		AuspostQueryTrackEventsSchema.TrackingResults tr1 = new AuspostQueryTrackEventsSchema.TrackingResults();
		tr1.ArticleDetails = createArticleDetailElement();
		TIBCOTrackingResultWrapper testWrapper2 = new TIBCOTrackingResultWrapper(tr1);

		AuspostQueryTrackEventsSchema.TrackingResults tr2 = new AuspostQueryTrackEventsSchema.TrackingResults();
		tr2.ConsignmentDetails = createConsignmentElement();
		TIBCOTrackingResultWrapper testWrapper3 = new TIBCOTrackingResultWrapper(tr2);

		Test.startTest();
		TIBCODataTranslator dt = new TIBCODataTranslator(new List<TIBCOTrackingResultWrapper>{ testWrapper1, testWrapper2, testWrapper3 });
		dt.save();

		TIBCOTrackingResultComponentCont trcc = new TIBCOTrackingResultComponentCont();
		trcc.setboundTracking(testWrapper1);
		trcc.setboundTracking(testWrapper2);
		trcc.setboundTracking(testWrapper3);

		Test.stopTest();
	}

	/**
	 * Scenario:
	 *      NF: This is used to specifically test the exception handlers
	 */
	static testMethod void testTIBCOTestDirectSave() {
		List<Article__c> arts = createArticles();
		Article__c art = arts[0];
		Article__c art2 = arts[1];
		Article__c art3 = arts[2];

		// DUPLICATE_VALUE
		art2.ArticleID__c = '1234';
		art3.ArticleID__c = '1234';

		Map<String, Article__c> consignments = new Map<String, Article__c>();
		Map<String, Article__c> articles = new Map<String, Article__c>();

		consignments.put(art.Id, art);
		articles.put(art2.Id, art2);
		articles.put(art3.Id, art3);

		Test.startTest();
		TIBCODataTranslator dt = new TIBCODataTranslator(new List<TIBCOTrackingResultWrapper>());

		dt.consignments = consignments;
		dt.articles = articles;
		dt.eventMessages = new Map<String, EventMessage__c>();

		// this will trigger an exception which will be handled internally
		// DUPLICATE_VALUE
		dt.save();

		Test.stopTest();
	}

	static testMethod void testTIBCOSMSActivityEvent() {
		TIBCOSMSActivityEvent.SMSHTTPS11Binding_v1 msae = new TIBCOSMSActivityEvent.SMSHTTPS11Binding_v1();
		msae.sendSMS_v1('121231231', 'test msg');
	}

	static testMethod void testTIBCOSMSDataModelCommon() {
		TIBCOSMSDataModelCommon.Exception_x testException = new TIBCOSMSDataModelCommon.Exception_x();
		TIBCOSMSDataModelCommon.InterfaceHeader testInterface = new TIBCOSMSDataModelCommon.InterfaceHeader();
		TIBCOSMSDataModelCommon.SOAPException_element se = new TIBCOSMSDataModelCommon.SOAPException_element();
	}

	static testMethod void testTIBCOSMSDataModelEvent() {
		TIBCOSMSDataModelEvent.ReturnMessage_element testssr = new TIBCOSMSDataModelEvent.ReturnMessage_element();
	}

	@isTest(seealldata=true)
	static void testTIBCOSMSTestCont() {
		TIBCOSMSTestCont testCont = new TIBCOSMSTestCont();
		testCont.send();
	}

	static testMethod void testTIBCOSMSWrapper() {
		AusPostSettings__c smsSettings = new AusPostSettings__c();
		smsSettings.Name = 'TIBCOSMS';
		insert smsSettings;
		TIBCOSMSWrapper.sendSMS('123718273', 'aasdasd');
	}

	/**
	 * Test to make sure the correct values are populated for the transient attributes for Articles
	 */
	@IsTest
	public static void testArticleTransientAttributes() {
		// =====================================
		// Data Preparation
		// =====================================
		// This method creates an artic le which includes the transient attributes needed for this test
		AuspostQueryTrackEventsSchema.ArticleDetails_element articleElement = createArticleDetailElement();

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		TIBCOArticleWrapper wrapper = new TIBCOArticleWrapper(articleElement);
		System.assertEquals('1.30PM', wrapper.transientAttributes.predictedWindowStart, 'Prediction start transient is not correct');
		System.assertEquals('3.30PM', wrapper.transientAttributes.predictedWindowEnd, 'Prediction end transient is not correct');
	}

	/**
	 * Test to make sure the correct values are populated for the transient attributes for Articles
	 */
	@IsTest
	public static void testConsignmentEventMessageTransientAttributes() {
		// =====================================
		// Data Preparation
		// =====================================
		// This method creates an artic le which includes the transient attributes needed for this test
		AuspostQueryTrackEventsSchema.ConsignmentDetails_element element = createConsignmentElement(true);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Boolean foundEventReason = false;
		TIBCOConsignmentWrapper wrapper = new TIBCOConsignmentWrapper(element);
		for (TIBCOEventMessageWrapper eventMessageWrapper : wrapper.eventMessages) {
			if (!String.isEmpty(eventMessageWrapper.transientAttributes.eventReason)) {
				foundEventReason = true;
				break;
			}
		}

		System.assert(foundEventReason, 'Event reason was not mapped to transient attribute');
	}

	/**
	 * Test to make sure the correct values are populated for the transient attributes for Event Messages
	 */
	@IsTest
	public static void testArticleEventMessageTransientAttributes() {
		// =====================================
		// Data Preparation
		// =====================================
		// This method creates an artic le which includes the transient attributes needed for this test
		AuspostQueryTrackEventsSchema.ArticleDetails_element articleElement = createArticleDetailElement();

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Boolean foundEventReason = false;
		TIBCOArticleWrapper wrapper = new TIBCOArticleWrapper(articleElement);
		for (TIBCOEventMessageWrapper eventMessageWrapper : wrapper.eventMessages) {
			if (!String.isEmpty(eventMessageWrapper.transientAttributes.eventReason)) {
				foundEventReason = true;
				break;
			}
		}

		System.assert(foundEventReason, 'Event reason was not mapped to transient attribute');
	}

	public static AuspostQueryTrackEventsSchema.ArticleEnvelope createArticleEnvelope() {
		AuspostQueryTrackEventsSchema.ArticleEnvelope ae = new AuspostQueryTrackEventsSchema.ArticleEnvelope();

		AuspostMailProductSchema.Article mailarticle = new AuspostMailProductSchema.Article();
		mailarticle.ArticleId = 'auysgdagsd';
		mailarticle.ProductName = 'eParcel';
		mailarticle.SubProductName = 'eParcel Standard';

		AuspostMailProductSchema.ArticleStatus redirectStatus = new AuspostMailProductSchema.ArticleStatus();
		redirectStatus.StatusAttributeName = 'Redirect Allowed Status';
		redirectStatus.StatusAttributeValue = 'Available';
		AuspostMailProductSchema.ArticleStatus deliveryStatus = new AuspostMailProductSchema.ArticleStatus();
		deliveryStatus.StatusAttributeName = 'Delivery Status of Article';
		deliveryStatus.StatusAttributeValue = 'Delivered';
		mailarticle.Status = new List<AuspostMailProductSchema.ArticleStatus>{ redirectStatus, deliveryStatus };

		AuspostCommonSchema.MeasurementData measurementData = new AuspostCommonSchema.MeasurementData();
		measurementData.WeightKG = 100;
		measurementData.Quantity = 100;
		mailarticle.MeasurementData = measurementData;

		Date td = Date.today();
		String monthStr = td.month() > 9 ? td.month() + '' : '0' + td.month();
		String dayStr = td.day() > 9 ? td.day() + '' : '0' + td.day();

		AuspostCommonSchema.FurtherReferences f1 = new AuspostCommonSchema.FurtherReferences();
		f1.ReferenceCodeSet = 'LODGEMENT_DATE';
		f1.ReferenceID = '20130601';

		AuspostCommonSchema.FurtherReferences f2 = new AuspostCommonSchema.FurtherReferences();
		f2.ReferenceCodeSet = 'EXPECTED_DEL_DATE';
		f2.ReferenceID = td.year() + monthStr + dayStr;

		AuspostCommonSchema.FurtherReferences f3 = new AuspostCommonSchema.FurtherReferences();
		f3.ReferenceCodeSet = 'EXPECTED_DEL_DATE';
		td = td.addDays(40);
		monthStr = td.month() > 9 ? td.month() + '' : '0' + td.month();
		dayStr = td.day() > 9 ? td.day() + '' : '0' + td.day();
		f3.ReferenceID = td.year() + monthStr + dayStr;

		AuspostCommonSchema.FurtherReferences f4 = new AuspostCommonSchema.FurtherReferences();
		f4.ReferenceCodeSet = 'EXPECTED_DEL_DATE';
		td = td.addDays(-80);
		monthStr = td.month() > 9 ? td.month() + '' : '0' + td.month();
		dayStr = td.day() > 9 ? td.day() + '' : '0' + td.day();
		f4.ReferenceID = td.year() + monthStr + dayStr;

		AuspostEventSchema.FurtherReferences f5 = new AuspostEventSchema.FurtherReferences();
		f5.ReferenceCodeSet = 'SORT_OUTPUT_COMP';
		f5.ReferenceID = 'S1 - Indirect Outlet 063';

		AuspostEventSchema.FurtherReferences f6 = new AuspostEventSchema.FurtherReferences();
		f6.ReferenceCodeSet = 'SORT_SOURCE';
		f6.ReferenceID = 'SORT_SOURCETest';

		AuspostEventSchema.FurtherReferences f7 = new AuspostEventSchema.FurtherReferences();
		f7.ReferenceCodeSet = 'OCRVCS_DPID';
		f7.ReferenceID = '12';

		AuspostEventSchema.FurtherReferences f8 = new AuspostEventSchema.FurtherReferences();
		f8.ReferenceCodeSet = 'OCRVCS_POSTCODE';
		f8.ReferenceID = '3000';

		AuspostEventSchema.FurtherReferences f9 = new AuspostEventSchema.FurtherReferences();
		f9.ReferenceCodeSet = 'DEFAULT_HEIGHT';
		f9.ReferenceID = '1';

		AuspostEventSchema.FurtherReferences f10 = new AuspostEventSchema.FurtherReferences();
		f10.ReferenceCodeSet = 'DEFAULT_LENGTH';
		f10.ReferenceID = '2';

		AuspostEventSchema.FurtherReferences f11 = new AuspostEventSchema.FurtherReferences();
		f11.ReferenceCodeSet = 'DEFAULT_WIDTH';
		f11.ReferenceID = '3';

		AuspostEventSchema.FurtherReferences f12 = new AuspostEventSchema.FurtherReferences();
		f12.ReferenceCodeSet = 'DEFAULT_WEIGHT';
		f12.ReferenceID = '4';

		AuspostEventSchema.FurtherReferences f13 = new AuspostEventSchema.FurtherReferences();
		f13.ReferenceCodeSet = 'CONT_LINE1_TEXT';
		f13.ReferenceID = 'test1';

		AuspostEventSchema.FurtherReferences f14 = new AuspostEventSchema.FurtherReferences();
		f14.ReferenceCodeSet = 'CONT_LINE2_TEXT';
		f14.ReferenceID = 'test2';

		AuspostEventSchema.FurtherReferences f15 = new AuspostEventSchema.FurtherReferences();
		f15.ReferenceCodeSet = 'SORTER_ARTICLE_REF';
		f15.ReferenceID = 'test3';

		AuspostEventSchema.FurtherReferences f16 = new AuspostEventSchema.FurtherReferences();
		f16.ReferenceCodeSet = 'SORT_DESTINATION';
		f16.ReferenceID = 'test4';

		AuspostEventSchema.FurtherReferences f17 = new AuspostEventSchema.FurtherReferences();
		f17.ReferenceCodeSet = 'SORT_OUTPUT_STATUS';
		f17.ReferenceID = 'test5';

		AuspostEventSchema.FurtherReferences f18 = new AuspostEventSchema.FurtherReferences();
		f18.ReferenceCodeSet = 'SORT_INDUCT_MODE';
		f18.ReferenceID = 'test6';

		AuspostEventSchema.FurtherReferences f19 = new AuspostEventSchema.FurtherReferences();
		f19.ReferenceCodeSet = 'OCRVCS_RESULT_SOURCE';
		f19.ReferenceID = 'test7';

		AuspostEventSchema.FurtherReferences f20 = new AuspostEventSchema.FurtherReferences();
		f20.ReferenceCodeSet = 'OCRVCS_OS_ZONE';
		f20.ReferenceID = '1';

		AuspostEventSchema.FurtherReferences f21 = new AuspostEventSchema.FurtherReferences();
		f21.ReferenceCodeSet = 'CONT_DEST_LOC_REGION';
		f21.ReferenceID = 'test8';

		AuspostEventSchema.FurtherReferences f22 = new AuspostEventSchema.FurtherReferences();
		f22.ReferenceCodeSet = 'CONT_DEST_LOC_POSTCODE';
		f22.ReferenceID = '3000';

		AuspostEventSchema.FurtherReferences f23 = new AuspostEventSchema.FurtherReferences();
		f23.ReferenceCodeSet = 'LOAD_PHYSICAL_CONT';
		f23.ReferenceID = 'test7';

		AuspostEventSchema.FurtherReferences f24 = new AuspostEventSchema.FurtherReferences();
		f24.ReferenceCodeSet = 'SORT_OUTPUT_REASON';
		f24.ReferenceID = 'test7';

		//Delivery ETA details.
		AuspostCommonSchema.FurtherReferences f25 = new AuspostCommonSchema.FurtherReferences();
		f25.ReferenceCodeSet = 'PREDICT_WIN_START';
		f25.ReferenceID = '1.30PM';

		AuspostCommonSchema.FurtherReferences f26 = new AuspostCommonSchema.FurtherReferences();
		f26.ReferenceCodeSet = 'PREDICT_WIN_END';
		f26.ReferenceID = '3.30PM';

		AuspostCommonSchema.FurtherReferences f27 = new AuspostCommonSchema.FurtherReferences();
		f27.ReferenceCodeSet = 'INIT_PRED_WIN_START';
		f27.ReferenceID = '12.33PM';

		AuspostCommonSchema.FurtherReferences f28 = new AuspostCommonSchema.FurtherReferences();
		f28.ReferenceCodeSet = 'INIT_PRED_WIN_END';
		f28.ReferenceID = '2.30PM';

		AuspostEventSchema.FurtherReferences f29 = new AuspostEventSchema.FurtherReferences();
		f29.ReferenceCodeSet = 'OUTSIDE_DELIV_RADIUS';
		f29.ReferenceID = 'FALSE';

		AuspostEventSchema.FurtherReferences f30 = new AuspostEventSchema.FurtherReferences();
		f30.ReferenceCodeSet = 'TRUCK_ID';
		f30.ReferenceID = 'VIC007';

		AuspostEventSchema.FurtherReferences f31 = new AuspostEventSchema.FurtherReferences();
		f31.ReferenceCodeSet = 'FAC_SUBLOCATION_ID';
		f31.ReferenceID = 'TWZ18765';

		AuspostEventSchema.FurtherReferences f32 = new AuspostEventSchema.FurtherReferences();
		f32.ReferenceCodeSet = 'FAC_SUBLOCATION_NAME';
		f32.ReferenceID = 'Melbourne North West';

		AuspostEventSchema.FurtherReferences f33 = new AuspostEventSchema.FurtherReferences();
		f33.ReferenceCodeSet = 'EVENT_REASON';
		f33.ReferenceID = 'Event Reason 1';

		AuspostEventSchema.FurtherReferences f34 = new AuspostEventSchema.FurtherReferences();
		f34.ReferenceCodeSet = 'CONSIGNMENT_ID';
		f34.ReferenceID = 'asjkd12jkjasjkd';

		AuspostEventSchema.FurtherReferences[] frsMail = new List<AuspostEventSchema.FurtherReferences>{
			f5,
			f6,
			f7,
			f8,
			f9,
			f10,
			f11,
			f12,
			f13,
			f14,
			f15,
			f16,
			f17,
			f18,
			f19,
			f20,
			f21,
			f22,
			f23,
			f24,
			f29,
			f30,
			f31,
			f32,
			f34
		};

		AuspostCommonSchema.FurtherReferences[] frs = new List<AuspostCommonSchema.FurtherReferences>{ f1, f2, f25, f26, f27, f28 };
		mailarticle.FurtherReferences = frs;
		mailarticle.TransitAmount = 120;

		AuspostMailProductSchema.DeliveryContact dc1 = createDCByType('DELIVERY');

		AuspostMailProductSchema.DeliveryContact dc2 = createDCByType('PICKUP');
		dc2.Customer.Address[0].AddressDetails.AustralianAddress = null;

		AuspostMailProductSchema.DeliveryContact dc3 = createDCByType('RETURN');
		dc3.Customer.Address[0].AddressDetails.AustralianAddress = null;

		mailarticle.DeliveryContacts = new List<AuspostMailProductSchema.DeliveryContact>{ dc1, dc2, dc3 };

		ae.Article = mailarticle;

		AuspostEventSchema.CommunicationEvent cevent = new AuspostEventSchema.CommunicationEvent();
		cevent.EventType = 'test type';
		cevent.EventDateTime = system.now();
		AuspostCommonSchema.EventSource es = new AuspostCommonSchema.EventSource();
		es.UserName = 'test';
		es.DeviceID = 'alsjkhdka';
		es.SenderID = 'test';
		es.SenderName = 'test';
		es.UserRole = 'test';
		cevent.EventSource = es;

		AuspostCommonSchema.TrackingIdentification tracking1 = new AuspostCommonSchema.TrackingIdentification();
		tracking1.TrackingIDCodeSet = 'ARTICLE_ID';
		tracking1.TrackingID = 'alkshda';
		cevent.TrackingIdentification = tracking1;

		AuspostCommonSchema.TrackingNotification notify1 = new AuspostCommonSchema.TrackingNotification();
		notify1.ContactType = 'EMAIL';
		notify1.NotificationServices = new List<String>{ 'a', 'b' };
		cevent.TrackingNotification = new List<AuspostCommonSchema.TrackingNotification>{ notify1 };

		// add communication event EVENT_REASON
		cevent.FurtherReference = new List<AuspostEventSchema.FurtherReferences>{ f33 };

		ae.CommunicationEvent = new List<AuspostEventSchema.CommunicationEvent>{ cevent };

		AuspostEventSchema.DeviceEvent devent = new AuspostEventSchema.DeviceEvent();
		devent.EventSource = es;
		TIBCOEventMessageWrapper testEMW2 = new TIBCOEventMessageWrapper(devent);
		ae.DeviceEvent = new List<AuspostEventSchema.DeviceEvent>{ devent };

		AuspostEventSchema.MailEvent mevent = new AuspostEventSchema.MailEvent();
		mevent.EventSource = es;
		mevent.FurtherReference = frsMail;
		// 2017-04-13
		// Add the processing of attachments to grab the safe drop image
		// Confirmed this covers additional code written for Safe Drop GUID integration
		// NATHAN FRANKLIN
		AuspostCommonSchema.AttachmentType safeDropAttachment = new AuspostCommonSchema.AttachmentType();
		safeDropAttachment.AttachmentType = 'SAFE_DROP_PICTURE';
		safeDropAttachment.ContentType = 'JPEG';
		safeDropAttachment.URL = '92eb2fff-854d-47bb-88cb-4ae34fb6fef1';
		AuspostEventSchema.Attachments_element attachments = new AuspostEventSchema.Attachments_element();
		attachments.Attachment = new List<AuspostCommonSchema.AttachmentType>{ safeDropAttachment };
		mevent.Attachments = attachments;

		AuspostEventSchema.LocationIdentifications location1 = new AuspostEventSchema.LocationIdentifications();
		location1.LocationCodeSet = 'WORK_CENTRE';
		AuspostEventSchema.Geocode geocode = new AuspostEventSchema.Geocode();
		geocode.Latitude = 32;
		geocode.Longitude = 121;
		geocode.PositionalUncertainty = 31;
		location1.Geocode = geocode;
		mevent.LocationIdentifications = new List<AuspostEventSchema.LocationIdentifications>{ location1 };

		TIBCOEventMessageWrapper testEMW3 = new TIBCOEventMessageWrapper(mevent);
		ae.MailEvent = new List<AuspostEventSchema.MailEvent>{ mevent };

		return ae;
	}

	public static AuspostQueryTrackEventsSchema.ArticleDetails_element createArticleDetailElement() {
		AuspostQueryTrackEventsSchema.ArticleDetails_element articleElement = new AuspostQueryTrackEventsSchema.ArticleDetails_element();
		AuspostQueryTrackEventsSchema.ArticleEnvelope ae = createArticleEnvelope();
		articleElement.ArticleEnvelope = ae;
		return articleElement;
	}

	public static AuspostQueryTrackEventsSchema.ConsignmentDetails_element createConsignmentElement() {
		return createConsignmentElement(false, DeliveryAddressType.DELIVERY);
	}

	public static AuspostQueryTrackEventsSchema.ConsignmentDetails_element createConsignmentElement(Boolean withEvents) {
		return createConsignmentElement(withEvents, DeliveryAddressType.DELIVERY);
	}

	public static AuspostQueryTrackEventsSchema.ConsignmentDetails_element createConsignmentElement(Boolean withEvents, DeliveryAddressType addressType) {
		AuspostQueryTrackEventsSchema.ConsignmentDetails_element celement = new AuspostQueryTrackEventsSchema.ConsignmentDetails_element();
		AuspostQueryTrackEventsSchema.ConsignmentEnvelope ce = new AuspostQueryTrackEventsSchema.ConsignmentEnvelope();
		AuspostMailProductSchema.Consignment consign = new AuspostMailProductSchema.Consignment();
		consign.ConsignmentId = 'asjkd12jkjasjkd';
		consign.ParcelCount = 102;
		consign.SignatureRequired = true;

		AuspostMailProductSchema.DeliveryContact dc1 = createDCByType('DELIVERY');
		if (addressType != DeliveryAddressType.DELIVERY) {
			dc1.Customer.Address[0].AddressDetails.AustralianAddress = null;
		}

		AuspostMailProductSchema.DeliveryContact dc2 = createDCByType('PICKUP');
		if (addressType != DeliveryAddressType.PICKUP) {
			dc2.Customer.Address[0].AddressDetails.AustralianAddress = null;
		}

		AuspostMailProductSchema.DeliveryContact dc3 = createDCByType('RETURN');
		if (addressType != DeliveryAddressType.xRETURN) {
			dc3.Customer.Address[0].AddressDetails.AustralianAddress = null;
		}

		consign.DeliveryContacts = new List<AuspostMailProductSchema.DeliveryContact>{ dc1, dc2, dc3 };

		AuspostCommonSchema.FurtherReferences frLodgementDate = new AuspostCommonSchema.FurtherReferences();
		frLodgementDate.ReferenceCodeSet = 'LODGEMENT_DATE';
		frLodgementDate.ReferenceID = '2021-10-01';

		AuspostCommonSchema.FurtherReferences frDeliveredDate = new AuspostCommonSchema.FurtherReferences();
		frLodgementDate.ReferenceCodeSet = 'DELIVERED_BY_DATE';
		frLodgementDate.ReferenceID = '2021-10-05';

		consign.FurtherReferences = new List<AuspostCommonSchema.FurtherReferences>{ frLodgementDate, frDeliveredDate };

		if (withEvents) {
			// add a CommunicationEvent with an event reason for event message transient attribute mapping
			AuspostEventSchema.CommunicationEvent cevent = new AuspostEventSchema.CommunicationEvent();
			cevent.EventType = 'test type';
			cevent.EventDateTime = System.now();

			AuspostCommonSchema.EventSource es = new AuspostCommonSchema.EventSource();
			es.UserName = 'test';
			es.DeviceID = 'alsjkhdka';
			es.SenderID = 'test';
			es.SenderName = 'test';
			es.UserRole = 'test';
			cevent.EventSource = es;

			AuspostCommonSchema.TrackingIdentification tracking1 = new AuspostCommonSchema.TrackingIdentification();
			tracking1.TrackingIDCodeSet = 'ARTICLE_ID';
			tracking1.TrackingID = 'alkshda';
			cevent.TrackingIdentification = tracking1;

			AuspostCommonSchema.TrackingNotification notify1 = new AuspostCommonSchema.TrackingNotification();
			notify1.ContactType = 'EMAIL';
			notify1.NotificationServices = new List<String>{ 'a', 'b' };
			cevent.TrackingNotification = new List<AuspostCommonSchema.TrackingNotification>{ notify1 };

			// add communication event EVENT_REASON
			AuspostEventSchema.FurtherReferences f1 = new AuspostEventSchema.FurtherReferences();
			f1.ReferenceCodeSet = 'EVENT_REASON';
			f1.ReferenceID = 'Event Reason 1';
			cevent.FurtherReference = new List<AuspostEventSchema.FurtherReferences>{ f1 };

			ce.CommunicationEvent = new List<AuspostEventSchema.CommunicationEvent>{ cevent };
		}
		ce.Consignment = consign;
		celement.ConsignmentEnvelope = ce;

		return celement;
	}

	public static AuspostMailProductSchema.DeliveryContact createDCByType(String typeName) {
		AuspostMailProductSchema.DeliveryContact dc1 = new AuspostMailProductSchema.DeliveryContact();
		dc1.DeliveryContactType = typeName;
		dc1.Comments = 'Send package to 111 Bourke St, Melbourne VIC 3000';
		AuspostCustomerSchema.Customer customer1 = new AuspostCustomerSchema.Customer();
		AuspostInvolvedPartSchema.OrganisationType org = new AuspostInvolvedPartSchema.OrganisationType();
		org.OrganisationName = 'test org';
		customer1.Organisation = org;

		AuspostCustomerSchema.DeliveryPreference_element deliveryPreference = new AuspostCustomerSchema.DeliveryPreference_element();
		AuspostCustomerSchema.Options_element opt1 = new AuspostCustomerSchema.Options_element();
		opt1.OptionCode = 'test code';
		opt1.Description = 'test desc';
		deliveryPreference.Options = new List<AuspostCustomerSchema.Options_element>{ opt1 };
		customer1.DeliveryPreference = deliveryPreference;

		AuspostCommonSchema.ElectronicContactType ect = new AuspostCommonSchema.ElectronicContactType();
		AuspostCommonSchema.InternetType interType = new AuspostCommonSchema.InternetType();
		interType.ContactType = 'EMAIL';
		interType.ContactDetail = 'test';
		ect.Internet = interType;
		customer1.ElectronicContact = new List<AuspostCommonSchema.ElectronicContactType>{ ect };

		AuspostInvolvedPartSchema.IndividualType individualType = new AuspostInvolvedPartSchema.IndividualType();
		AuspostInvolvedPartSchema.IndividualName individualName = new AuspostInvolvedPartSchema.IndividualName();
		individualName.FullName = 'test';
		individualType.Name = new List<AuspostInvolvedPartSchema.IndividualName>{ individualName };
		customer1.Individual = individualType;

		AuspostCustomerSchema.CommunicationDecision cde = new AuspostCustomerSchema.CommunicationDecision();
		customer1.CommunicationDecision = new List<AuspostCustomerSchema.CommunicationDecision>{ cde };

		AuspostLocationSchema.AddressType add1 = new AuspostLocationSchema.AddressType();
		AuspostLocationSchema.AddressDetailsType add1Detail = new AuspostLocationSchema.AddressDetailsType();
		AuspostLocationSchema.StandardAustralianAddressType saadd = new AuspostLocationSchema.StandardAustralianAddressType();
		saadd.PostCode = '12090';
		AuspostLocationSchema.UnstructuredAddressLineType udd = new AuspostLocationSchema.UnstructuredAddressLineType();
		udd.AddressLine = new List<String>{ 'test add 1', 'test add 1', 'test add 1', 'test add 1', 'test add 1' };
		saadd.UnstructuredAddress = udd;

		AuspostLocationSchema.CountryType ct = new AuspostLocationSchema.CountryType();
		ct.CountryCode = 'test';
		saadd.Country = ct;

		AuspostLocationSchema.StandardInternationalAddressType interAdd = new AuspostLocationSchema.StandardInternationalAddressType();
		AuspostLocationSchema.InternationalUnstructuredAddressType udd2 = new AuspostLocationSchema.InternationalUnstructuredAddressType();
		udd2.AddressLine = new List<String>{ 'test add 1', 'test add 1', 'test add 1', 'test add 1', 'test add 1' };
		interAdd.Country = ct;
		interAdd.UnstructuredAddress = udd2;

		add1Detail.AustralianAddress = saadd;
		add1Detail.InternationalAddress = interAdd;
		add1.AddressDetails = add1Detail;
		customer1.Address = new List<AuspostLocationSchema.AddressType>{ add1 };
		dc1.Customer = customer1;

		return dc1;
	}

	public static List<Article__c> getArticles() {
		List<Article__c> articles = new List<Article__c>();

		Article__c art = new Article__c();
		art.ArticleID__c = '123';
		art.Name = '123';
		art.ExpectedDeliveryDate__c = date.today();
		art.ArticleLodgementDate__c = date.today();
		art.SenderPostcode__c = '123';
		art.ReceiverPostcode__c = '3002';
		art.ArticleType__c = 'Regular Parcel';
		art.ReceiverName__c = 'ReceiverFirstName1 ReceiverLastName1';
		art.ReceiverEmail__c = 'dsf@163.com';
		art.Receiver_APCN__c = '123';
		art.Sender_APCN__c = '456';
		art.SenderName__c = 'SenderFirstName1 SenderLastName1';
		art.SenderEmail__c = 'dsf@163.com';
		art.ArticleLodgementDate__c = date.today();
		art.ProductCategory__c = 'eParcel';
		art.ArticleTransitAmountValue__c = 1;
		art.SubProduct__c = 'eParcel Standard';
		art.ActualWeight__c = 2;
		art.DeliveryInstructions__c = '99bb';
		articles.add(art);

		Article__c art2 = new Article__c();
		art2.ArticleID__c = '1234';
		art2.Name = '1234';
		art2.ExpectedDeliveryDate__c = date.today().addDays(-10);
		art2.ArticleLodgementDate__c = date.today();
		art2.SenderPostcode__c = '1234';
		art2.ReceiverPostcode__c = '3002';
		art2.ArticleType__c = 'Regular Parcel';
		art2.ReceiverName__c = 'ReceiverFirstName2 ReceiverLastName2';
		art2.ReceiverEmail__c = 'dsf@163.com';
		art2.Receiver_APCN__c = '789';
		art2.Sender_APCN__c = '101112';
		art2.SenderName__c = 'SenderFirstName2 SenderLastName2';
		art2.SenderEmail__c = 'dsf@163.com';
		art2.ArticleLodgementDate__c = date.today();
		art2.ProductCategory__c = 'eParcel';
		art2.ArticleTransitAmountValue__c = 1;
		art2.SubProduct__c = 'eParcel Standard';
		art2.ActualWeight__c = 2;
		art2.DeliveryInstructions__c = '99bb';
		articles.add(art2);

		Article__c art3 = new Article__c();
		art3.ArticleID__c = '12345';
		art3.Name = '12345';
		art3.ExpectedDeliveryDate__c = date.today().addDays(10);
		art3.ArticleLodgementDate__c = date.today();
		art3.SenderPostcode__c = '12345';
		art3.ReceiverPostcode__c = '3002';
		art3.ArticleType__c = 'Regular Parcel';
		art3.ReceiverName__c = 'ReceiverFirstName3 ReceiverLastName3';
		art3.ReceiverEmail__c = 'dsf@163.com';
		art3.Receiver_APCN__c = '456';
		art3.Sender_APCN__c = '789';
		art3.SenderName__c = 'SenderFirstName3 SenderLastName3';
		art3.SenderEmail__c = 'dsf@163.com';
		art3.ArticleLodgementDate__c = date.today();
		art3.ProductCategory__c = 'eParcel';
		art3.ArticleTransitAmountValue__c = 1;
		art3.SubProduct__c = 'eParcel Standard';
		art3.ActualWeight__c = 2;
		art3.DeliveryInstructions__c = '99bb';
		articles.add(art3);

		return articles;
	}

	public static List<Article__c> createArticles() {
		List<Article__c> articles = getArticles();
		insert articles[0];

		// add consignment references to others
		articles[1].Consignment__c = articles[0].Id;
		articles[2].Consignment__c = articles[0].Id;
		insert new List<Article__c>{ articles[1], articles[2] };
		return articles;
	}

	public static Map<Id, List<EventMessage__c>> createEMByArticle(List<Article__c> arts) {
		Article__c art = arts[0];
		Article__c art2 = arts[1];
		Article__c art3 = arts[2];

		EventMessage__c em = new EventMessage__c();
		em.Article__c = art.Id;
		em.SenderID__c = 'bg';
		em.ActualDateTime__c = date.today() + 1;
		em.EventType__c = 'DD-ER13';
		em.SignatureXString__c = '1';
		insert em;

		EventMessage__c em2 = new EventMessage__c();
		em2.Article__c = art2.Id;
		em2.SenderID__c = 'bg';
		em2.ActualDateTime__c = date.today() + 1;
		em2.EventType__c = 'DD-ER13';
		em2.SignatureXString__c = '1';
		insert em2;

		EventMessage__c em3 = new EventMessage__c();
		em3.Article__c = art3.Id;
		em3.SenderID__c = 'bg';
		em3.ActualDateTime__c = date.today() + 1;
		em3.EventType__c = 'DD-ER13';
		em3.SignatureXString__c = '1';
		insert em3;

		Map<Id, List<EventMessage__c>> articleToEventMessages = new Map<Id, List<EventMessage__c>>();
		articleToEventMessages.put(art.Id, new List<EventMessage__c>{ em });
		articleToEventMessages.put(art2.Id, new List<EventMessage__c>{ em2 });
		articleToEventMessages.put(art3.Id, new List<EventMessage__c>{ em3 });
		return articleToEventMessages;
	}
}