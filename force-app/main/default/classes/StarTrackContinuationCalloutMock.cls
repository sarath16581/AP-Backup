/**
 * @description Mock Class for .NET StarTrack Consignment Search Integration Response
 * @changelog:
 * 2024-05-22 - Seth Heang - updated getResponse_singleConsign to add FurtherReference2
 * 2024-06-25 - Seth Heang - updated getResponse_singleConsign and updated SourceSystem value to TEAM
 * 2024-07-15 - Seth Heang - added new mock responses for duplicate consignment scenarios
 */
@isTest
public class StarTrackContinuationCalloutMock {

	public static String getResponse_singleConsign() {
		return '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">' +
		   '<s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
			  '<SearchResponse xmlns="http://www.auspost.com.au/Schema/CustomerCareManagement/CustomerCommunicationsManagement/StarTrackMediation/publishConsignmentArticleEvent:v1">' +
				 '<SearchResult>' +
					'<Header>' +
					   '<TimeStamp>2016-02-09T00:37:23.913Z</TimeStamp>' +
					   '<TransactionId>2016-02-09T00:37:23.913Z</TransactionId>' +
					   '<SourceId>test</SourceId>' +
					   '<Action>Reply</Action>' +
					   '<NbrOfRows>1</NbrOfRows>' +
					'</Header>' +
					'<Consignment>' +
					   '<SourceSystem>TEAM</SourceSystem>' +
					   '<ActualWeight>12</ActualWeight>' +
					   '<ConsignmentID>TR2_66a94898-0927-450e-abfa-defa36972669</ConsignmentID>' +
					   '<ConsignmentNumber>2AT71923</ConsignmentNumber>' +
					   '<BillingAccount>P1234567</BillingAccount>' +
					   '<ControlledReturn>false</ControlledReturn>' +
					   '<Cubing>0</Cubing>' +
					   '<DangerousGoods>false</DangerousGoods>' +
					   '<DeliveryInstructions>Special Instruciton 7</DeliveryInstructions>' +
					   '<DispatchDate>2013-10-18T00:00:00</DispatchDate>' +
					   '<ExpectedDeliveryDate>2024-01-21</ExpectedDeliveryDate>' +
					   '<InsuranceAmount>0.00</InsuranceAmount>' +
					   '<InsuranceClass/>' +
					   '<Network>SYD</Network>' +
					   '<NumberofItems>2</NumberofItems>' +
					   '<ReceiverAddress>28-32 PEACHTREE RD, PENRITH, 2750</ReceiverAddress>' +
					   '<ReceiverAddressLine1>28-32 PEACHTREE RD</ReceiverAddressLine1>' +
					   '<ReceiverAddressLine2/>' +
					   '<ReceiverAddressLine3/>' +
					   '<ReceiverCompany>COFFEY ENGINEERING</ReceiverCompany>' +
					   '<ReceiverEmail/>' +
					   '<ReceiverName>REBECCA</ReceiverName>' +
					   '<ReceiverPhone>0247313344</ReceiverPhone>' +
					   '<ReceiverFax/>' +
					   '<ReceiverMobile/>' +
					   '<ReceiverPostcode>2750</ReceiverPostcode>' +
					   '<ReceiverSuburb>PENRITH</ReceiverSuburb>' +
					   '<SenderAddress>1 Merriwa Street, GORDON, 2072</SenderAddress>' +
					   '<SenderAddressLine1>1 Merriwa Street</SenderAddressLine1>' +
					   '<SenderAddressLine2/>' +
					   '<SenderAddressLine3/>' +
					   '<SenderCompany>AaE Retail - FreightMaster Tes</SenderCompany>' +
					   '<SenderEmail/>' +
					   '<SenderPhone/>' +
					   '<SenderFax/>' +
					   '<SenderMobile/>' +
					   '<SenderName>aae</SenderName>' +
					   '<SenderPostcode>2072</SenderPostcode>' +
					   '<SenderSuburb>GORDON</SenderSuburb>' +
					   '<ServiceCode>ARL</ServiceCode>' +
					   '<ServiceDescription>Airlock</ServiceDescription>' +
					   '<ManifestReference>45956</ManifestReference>' +
					   '<PrintDate>2013-10-18</PrintDate>' +
					   '<ImportedDate>2013-10-18</ImportedDate>' +
					   '<ManifestDate>2013-10-18</ManifestDate>' +
					   '<Length>0.000000</Length>' +
					   '<Width>0.000000</Width>' +
					   '<Height>0.000000</Height>' +
					   '<CubicWeight>302.00</CubicWeight>' +
					   '<ChargeWeight>12.00000000</ChargeWeight>' +
					   '<Volume>0</Volume>' +
					   '<Invoice>""</Invoice>' +
					   '<CustomerType>AAE</CustomerType>' +
					   '<FurtherReference1>D05 1</FurtherReference1>' +
						'<FurtherReference2>E05 1</FurtherReference2>' +
					   '<DescriptionofGoods>Boxes</DescriptionofGoods>' +
					   '<Articles>' +
						  '<Article>' +
							 '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
							 '<ArticleID>TR1_783660b1-6f2b-4f39-82e3-044858c612ed</ArticleID>' +
							 '<ArticleNumber>2G897466</ArticleNumber>' +
							 '<Events>' +
								'<Event>' +
								   '<EventID>TR1_EVENT_65b02079-9737-e311-b5f4-0050569f13f9</EventID>' +
								   '<EventSource>MTS</EventSource>' +
								   '<EventDescription>Freight Manifest Transmitted</EventDescription>' +
								   '<EventType>FMMF</EventType>' +
								   '<EventSubType>FMMF</EventSubType>' +
								   '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
								   '<ActualDateTime>2013-10-18T00:00:00</ActualDateTime>' +
								   '<DepotCode>MGT</DepotCode>' +
								   '<DepotName>Mornington</DepotName>' +
								'</Event>' +
								'<Event>' +
								   '<EventID>TR1_EVENT_20e294e0-373c-e311-b5f4-0050569f13f9</EventID>' +
								   '<EventSource>STE</EventSource>' +
								   '<EventDescription>Onboard with driver for delivery</EventDescription>' +
								   '<EventType>OUTG</EventType>' +
								   '<EventSubType>Successful</EventSubType>' +
								   '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
								   '<ActualDateTime>2013-10-24T10:07:15</ActualDateTime>' +
								   '<DepotCode>SYZ</DepotCode>' +
								   '<DepotName>SYDNEY</DepotName>' +
								   '<AddressLine1/>' +
								   '<AddressLine2/>' +
								   '<AddressLine3/>' +
								   '<City/>' +
								   '<Phone/>' +
								   '<Name/>' +
								   '<ContactName/>' +
								'</Event>' +
								'<Event>' +
								   '<EventID>TR1_EVENT_402696b5-3c3c-e311-b5f4-0050569f13f9</EventID>' +
								   '<EventSource>STE</EventSource>' +
								   '<EventDescription>Onboard with driver for delivery</EventDescription>' +
								   '<EventType>OUTG</EventType>' +
								   '<EventSubType>Successful</EventSubType>' +
								   '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
								   '<ActualDateTime>2013-10-24T10:41:54</ActualDateTime>' +
								   '<DepotCode>SYZ</DepotCode>' +
								   '<DepotName>SYDNEY</DepotName>' +
								   '<AddressLine1/>' +
								   '<AddressLine2/>' +
								   '<AddressLine3/>' +
								   '<City/>' +
								   '<Phone/>' +
								   '<Name/>' +
								   '<ContactName/>' +
								'</Event>' +
								'<Event>' +
								   '<EventID>TR1_EVENT_a85d62d0-0a3d-e311-b5f4-0050569f13f9</EventID>' +
								   '<EventSource>STE</EventSource>' +
								   '<EventDescription>Delivery attempt unsuccessful. Reason: Refused by receiver - damaged</EventDescription>' +
								   '<EventType>DELV</EventType>' +
								   '<EventSubType>UnsuccessfulDelivery</EventSubType>' +
								   '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
								   '<ActualDateTime>2013-10-24T12:43:15</ActualDateTime>' +
								   '<DepotCode>SYZ</DepotCode>' +
								   '<DepotName>SYDNEY</DepotName>' +
								   '<SignatoryName/>' +
								   '<PostOfficeName/>' +
								   '<AddressType>SCTR</AddressType>' +
								   '<AddressLine1/>' +
								   '<AddressLine2/>' +
								   '<AddressLine3/>' +
								   '<AddressPostCode/>' +
								   '<City/>' +
								   '<Phone/>' +
								   '<Name/>' +
								'</Event>' +
							 '</Events>' +
						  '</Article>' +
					   '</Articles>' +
					   '<ProofOfDeliveries>' +
						  '<ProofOfDelivery>' +
							 '<PODId>TR2_35c50bf9-16c9-473a-bb71-77e763b3c7a8_POD_-1000009290</PODId>' +
							 '<PODReceivedDate>2015-08-04T14:14:15</PODReceivedDate>' +
							 '<Signedby>TFVB V</Signedby>' +
							 '<DeliveryAddress>SDF, , , PARRAMATTA, 2150</DeliveryAddress>' +
							 '<QCStatus/>' +
							 '<SignatureXString>iVBORw0KGgoAAAANSUhEUgAAAP8AAAD/CAYAAAA</SignatureXString>' +
							 '<Attachments>' + 
								'<Attachment>' + 
									'<Name>' +
										'testName' + 
									'</Name>'+
								'</Attachment>' + 
							 '</Attachments>' +
						  '</ProofOfDelivery>' +
					   '</ProofOfDeliveries>' +
					   '<BookinNotes>' +
						  '<BookinNote>' +
							 '<BookinNoteId>TR2_35c50bf9-16c9-473a-bb71-77e763b3c7a8_BIN_-1000009290</BookinNoteId>' +
							 '<StartFrom>2015-08-04T14:14:15</StartFrom>' +
							 '<DateEntered>2015-08-04T14:14:15</DateEntered>' +
							 '<DataSourcedFrom>TFVB V</DataSourcedFrom>' +
						  '</BookinNote>' +
					   '</BookinNotes>' +
					   '<SubDockets>' +
						  '<SubDocket>' +
							 '<SubDocketId>TR2_35c50bf9-16c9-473a-bb71-77e763b3c7a8_SID_-1000009290</SubDocketId>' +
							 '<SubDocketNumber>12314</SubDocketNumber>' +
							 '<DeliveryDepot>TFVB V</DeliveryDepot>' +
							 '<Supervisor>SupVsor</Supervisor>' +
							 '<Description>Desc-Subdockets</Description>' +
							 '<PayerAccountNumber>234215</PayerAccountNumber>' +
							 '<PayerName>TFVB V</PayerName>' +
							 '<DateRegistered>2015-08-04T14:14:15</DateRegistered>' +
						  '</SubDocket>' +
					   '</SubDockets>' +
					'</Consignment>' +
					'<ResponseMetrics>' +
					   '<TotalRows>1</TotalRows>' +
					   '<RowsReturned>1</RowsReturned>' +
					   '<FirstRow>1</FirstRow>' +
					   '<LastRow>1</LastRow>' +
					   '<ErrorCode>0</ErrorCode>' +
					   '<Performance>' +
						  '<TotalMilliseconds>416</TotalMilliseconds>' +
						  '<WrapperMilliseconds>0</WrapperMilliseconds>' +
						  '<DatabaseMilliseconds>63</DatabaseMilliseconds>' +
						  '<TotalTicks>5965197</TotalTicks>' +
						  '<WrapperTicks>1929</WrapperTicks>' +
						  '<DatabaseTicks>912953</DatabaseTicks>' +
						  '<DatabaseCalls>1</DatabaseCalls>' +
					   '</Performance>' +
					'</ResponseMetrics>' +
				 '</SearchResult>' +
			  '</SearchResponse>' +
		   '</s:Body>' +
		'</s:Envelope>';
	}
	
	public static String getResponse_publishCD() {
		return '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">' +
		   '<s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
			  '<PublishCDResponse xmlns="http://www.auspost.com.au/Schema/CustomerCareManagement/CustomerCommunicationsManagement/StarTrackMediation/publishConsignmentArticleEvent:v1">' +
				 '<PublishCDResult>' +
					'true' +
				 '</PublishCDResult>' +
			  '</PublishCDResponse>' +
		   '</s:Body>' +
		'</s:Envelope>';
	}
	
	public static String getResponse_DUPCON() {
		return '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">' +
		   '<s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
			  '<DUPCONResponse xmlns="http://www.auspost.com.au/Schema/CustomerCareManagement/CustomerCommunicationsManagement/StarTrackMediation/publishConsignmentArticleEvent:v1">' +
					'<DUPCONResult>' +
						'<Results>' +
						  '<DUPCON_DataDetail>' +
							 '<Consignment>2AT71886</Consignment>' +
							 '<DupSeq>1</DupSeq>' +
							 '<TotalNumber>2</TotalNumber>' +
							 '<DateSent>2016-02-23T13:10:02</DateSent>' +
							 '<ReceiverName></ReceiverName>' +
							 '<ReceiverSuburb>SYDNEY</ReceiverSuburb>' +
							 '<Service>O/N</Service>' +
							 '<Items>1</Items>' +
							 '<DeadWeight>1.00000000</DeadWeight>' +
							 '<ConGUID>c17b27d6-3f98-41a1-a3b9-493dfb1e013b</ConGUID>' +
							 '<UniqueExternalId>TR2_c17b27d6-3f98-41a1-a3b9-493dfb1e013b</UniqueExternalId>' +
							 '<System>AIR</System>' +
						  '</DUPCON_DataDetail>' +
						  '<DUPCON_DataDetail>' +
							 '<Consignment>2AT71886</Consignment>' +
							 '<DupSeq>2</DupSeq>' +
							 '<TotalNumber>2</TotalNumber>' +
							 '<DateSent>2013-10-18T00:00:00</DateSent>' +
							 '<ReceiverName>LINDA  JURY</ReceiverName>' +
							 '<ReceiverSuburb>WYONG</ReceiverSuburb>' +
							 '<Service>ECO</Service>' +
							 '<Items>4</Items>' +
							 '<DeadWeight>13.00000000</DeadWeight>' +
							 '<ConGUID>ff7b48e9-f074-408d-aaa1-2089ca7a13ba</ConGUID>' +
							 '<UniqueExternalId>TR2_ff7b48e9-f074-408d-aaa1-2089ca7a13ba</UniqueExternalId>' +
							 '<System>AIR</System>' +
						  '</DUPCON_DataDetail>' +
					   '</Results>' +
				 '</DUPCONResult>' +
			  '</DUPCONResponse>' +
		   '</s:Body>' +
		'</s:Envelope>';
	}
	
	public static String getResponse_subscribe() {
		return '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">' +
		   '<s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
			  '<SubscribeResponse xmlns="http://www.auspost.com.au/Schema/CustomerCareManagement/CustomerCommunicationsManagement/StarTrackMediation/publishConsignmentArticleEvent:v1">' +
				 '<SubscribeResult>' +
					'<IsSubscribed>' +
						'true' +
					'</IsSubscribed>' +
				 '</SubscribeResult>' +
			  '</SubscribeResponse>' +
		   '</s:Body>' +
		'</s:Envelope>';
	}
	
	public static String getResponse_multConsign() {
		return '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">' +
		   '<s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
			  '<SearchResponse xmlns="http://www.auspost.com.au/Schema/CustomerCareManagement/CustomerCommunicationsManagement/StarTrackMediation/publishConsignmentArticleEvent:v1">' +
				 '<SearchResult>' +
					'<Header>' +
					   '<TimeStamp>2016-02-09T00:37:23.913Z</TimeStamp>' +
					   '<TransactionId>2016-02-09T00:37:23.913Z</TransactionId>' +
					   '<SourceId>test</SourceId>' +
					   '<Action>Reply</Action>' +
					   '<NbrOfRows>2</NbrOfRows>' +
					'</Header>' +
					'<SearchResults>' +
					   '<ResponseMetrics>' +
						  '<TotalRows>2</TotalRows>' +
						  '<RowsReturned>2</RowsReturned>' +
						  '<FirstRow>1</FirstRow>' +
						  '<LastRow>2</LastRow>' +
						  '<ErrorCode>0</ErrorCode>' +
						  '<Performance>' +
							 '<TotalMilliseconds>109</TotalMilliseconds>' +
							 '<WrapperMilliseconds>0</WrapperMilliseconds>' +
							 '<DatabaseMilliseconds>109</DatabaseMilliseconds>' +
							 '<TotalTicks>1574580</TotalTicks>' +
							 '<WrapperTicks>2152</WrapperTicks>' +
							 '<DatabaseTicks>1572428</DatabaseTicks>' +
							 '<DatabaseCalls>1</DatabaseCalls>' +
						  '</Performance>' +
					   '</ResponseMetrics>' +
					   '<Results>' +
						  '<DUPCON_DataDetail>' +
							 '<Consignment>2AT71886</Consignment>' +
							 '<DupSeq>1</DupSeq>' +
							 '<TotalNumber>2</TotalNumber>' +
							 '<DateSent>2016-02-23T13:10:02</DateSent>' +
							 '<ReceiverName></ReceiverName>' +
							 '<ReceiverSuburb>SYDNEY</ReceiverSuburb>' +
							 '<Service>O/N</Service>' +
							 '<Items>1</Items>' +
							 '<DeadWeight>1.00000000</DeadWeight>' +
							 '<ConGUID>c17b27d6-3f98-41a1-a3b9-493dfb1e013b</ConGUID>' +
							 '<UniqueExternalId>TR2_c17b27d6-3f98-41a1-a3b9-493dfb1e013b</UniqueExternalId>' +
							 '<System>AIR</System>' +
						  '</DUPCON_DataDetail>' +
						  '<DUPCON_DataDetail>' +
							 '<Consignment>2AT71886</Consignment>' +
							 '<DupSeq>2</DupSeq>' +
							 '<TotalNumber>2</TotalNumber>' +
							 '<DateSent>2013-10-18T00:00:00</DateSent>' +
							 '<ReceiverName>LINDA  JURY</ReceiverName>' +
							 '<ReceiverSuburb>WYONG</ReceiverSuburb>' +
							 '<Service>ECO</Service>' +
							 '<Items>4</Items>' +
							 '<DeadWeight>13.00000000</DeadWeight>' +
							 '<ConGUID>ff7b48e9-f074-408d-aaa1-2089ca7a13ba</ConGUID>' +
							 '<UniqueExternalId>TR2_ff7b48e9-f074-408d-aaa1-2089ca7a13ba</UniqueExternalId>' +
							 '<System>AIR</System>' +
						  '</DUPCON_DataDetail>' +
					   '</Results>' +
					'</SearchResults>' +
					'<ResponseMetrics>' +
					   '<TotalRows>2</TotalRows>' +
					   '<RowsReturned>2</RowsReturned>' +
					   '<FirstRow>1</FirstRow>' +
					   '<LastRow>2</LastRow>' +
					   '<ErrorCode>0</ErrorCode>' +
					   '<Performance>' +
						  '<TotalMilliseconds>110</TotalMilliseconds>' +
						  '<WrapperMilliseconds>0</WrapperMilliseconds>' +
						  '<DatabaseMilliseconds>109</DatabaseMilliseconds>' +
						  '<TotalTicks>1585642</TotalTicks>' +
						  '<WrapperTicks>2152</WrapperTicks>' +
						  '<DatabaseTicks>1572428</DatabaseTicks>' +
						  '<DatabaseCalls>1</DatabaseCalls>' +
					   '</Performance>' +
					'</ResponseMetrics>' +
				 '</SearchResult>' +
			  '</SearchResponse>' +
		   '</s:Body>' +
		'</s:Envelope>';
	}

	/**
	 * @description	mock response for duplicate consignments where one of two duplicates has dateSent attribute set within the last 6 months
	 */
	public static String getResponse_multiConsignWithOneConsignmentWithinLast6Months() {
		return '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">' +
					'<s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
						'<SearchResponse xmlns="http://www.auspost.com.au/Schema/CustomerCareManagement/CustomerCommunicationsManagement/StarTrackMediation/publishConsignmentArticleEvent:v1">' +
							'<SearchResult>' +
								'<Header>' +
									'<TimeStamp>2016-02-09T00:37:23.913Z</TimeStamp>' +
									'<TransactionId>2016-02-09T00:37:23.913Z</TransactionId>' +
									'<SourceId>test</SourceId>' +
									'<Action>Reply</Action>' +
									'<NbrOfRows>2</NbrOfRows>' +
								'</Header>' +
								'<SearchResults>' +
									'<ResponseMetrics>' +
										'<TotalRows>2</TotalRows>' +
										'<RowsReturned>2</RowsReturned>' +
										'<FirstRow>1</FirstRow>' +
										'<LastRow>2</LastRow>' +
										'<ErrorCode>0</ErrorCode>' +
										'<Performance>' +
											'<TotalMilliseconds>109</TotalMilliseconds>' +
											'<WrapperMilliseconds>0</WrapperMilliseconds>' +
											'<DatabaseMilliseconds>109</DatabaseMilliseconds>' +
											'<TotalTicks>1574580</TotalTicks>' +
											'<WrapperTicks>2152</WrapperTicks>' +
											'<DatabaseTicks>1572428</DatabaseTicks>' +
											'<DatabaseCalls>1</DatabaseCalls>' +
										'</Performance>' +
									'</ResponseMetrics>' +
									'<Results>' +
										'<DUPCON_DataDetail>' +
											'<Consignment>2AT71886</Consignment>' +
											'<DupSeq>1</DupSeq>' +
											'<TotalNumber>2</TotalNumber>' +
											'<DateSent>2016-02-23T13:10:02</DateSent>' +
											'<ReceiverName></ReceiverName>' +
											'<ReceiverSuburb>SYDNEY</ReceiverSuburb>' +
											'<Service>O/N</Service>' +
											'<Items>1</Items>' +
											'<DeadWeight>1.00000000</DeadWeight>' +
											'<ConGUID>c17b27d6-3f98-41a1-a3b9-493dfb1e013b</ConGUID>' +
												'<UniqueExternalId>TR2_c17b27d6-3f98-41a1-a3b9-493dfb1e013b</UniqueExternalId>' +
											'<System>AIR</System>' +
										'</DUPCON_DataDetail>' +
										'<DUPCON_DataDetail>' +
											'<Consignment>2AT71886</Consignment>' +
											'<DupSeq>2</DupSeq>' +
											'<TotalNumber>2</TotalNumber>' +
											'<DateSent>'+ DateTime.now().addMonths(-3).format('yyyy-MM-dd\'T\'HH:mm:ss')  +'</DateSent>' +
											'<ReceiverName>LINDA  JURY</ReceiverName>' +
											'<ReceiverSuburb>WYONG</ReceiverSuburb>' +
											'<Service>ECO</Service>' +
											'<Items>4</Items>' +
											'<DeadWeight>13.00000000</DeadWeight>' +
											'<ConGUID>ff7b48e9-f074-408d-aaa1-2089ca7a13ba</ConGUID>' +
											'<UniqueExternalId>TR2_66a94898-0927-450e-abfa-defa36972669</UniqueExternalId>' +
											'<System>AIR</System>' +
										'</DUPCON_DataDetail>' +
									'</Results>' +
								'</SearchResults>' +
								'<ResponseMetrics>' +
									'<TotalRows>2</TotalRows>' +
									'<RowsReturned>2</RowsReturned>' +
									'<FirstRow>1</FirstRow>' +
									'<LastRow>2</LastRow>' +
									'<ErrorCode>0</ErrorCode>' +
									'<Performance>' +
										'<TotalMilliseconds>110</TotalMilliseconds>' +
										'<WrapperMilliseconds>0</WrapperMilliseconds>' +
										'<DatabaseMilliseconds>109</DatabaseMilliseconds>' +
										'<TotalTicks>1585642</TotalTicks>' +
										'<WrapperTicks>2152</WrapperTicks>' +
										'<DatabaseTicks>1572428</DatabaseTicks>' +
										'<DatabaseCalls>1</DatabaseCalls>' +
									'</Performance>' +
								'</ResponseMetrics>' +
							'</SearchResult>' +
						'</SearchResponse>' +
					'</s:Body>' +
				'</s:Envelope>';
	}

	/**
	 * @description	mock response for duplicate consignments where all duplicates have dateSent attribute set within the last 6 months
	 */
	public static String getResponse_multiConsignWhereAllConsignmentsWithinLast6Months() {
		return '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">' +
					'<s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
					'<SearchResponse xmlns="http://www.auspost.com.au/Schema/CustomerCareManagement/CustomerCommunicationsManagement/StarTrackMediation/publishConsignmentArticleEvent:v1">' +
						'<SearchResult>' +
							'<Header>' +
								'<TimeStamp>2016-02-09T00:37:23.913Z</TimeStamp>' +
								'<TransactionId>2016-02-09T00:37:23.913Z</TransactionId>' +
								'<SourceId>test</SourceId>' +
								'<Action>Reply</Action>' +
								'<NbrOfRows>2</NbrOfRows>' +
							'</Header>' +
							'<SearchResults>' +
								'<ResponseMetrics>' +
									'<TotalRows>2</TotalRows>' +
									'<RowsReturned>2</RowsReturned>' +
									'<FirstRow>1</FirstRow>' +
									'<LastRow>2</LastRow>' +
									'<ErrorCode>0</ErrorCode>' +
									'<Performance>' +
										'<TotalMilliseconds>109</TotalMilliseconds>' +
										'<WrapperMilliseconds>0</WrapperMilliseconds>' +
										'<DatabaseMilliseconds>109</DatabaseMilliseconds>' +
										'<TotalTicks>1574580</TotalTicks>' +
										'<WrapperTicks>2152</WrapperTicks>' +
										'<DatabaseTicks>1572428</DatabaseTicks>' +
										'<DatabaseCalls>1</DatabaseCalls>' +
									'</Performance>' +
								'</ResponseMetrics>' +
								'<Results>' +
									'<DUPCON_DataDetail>' +
										'<Consignment>2AT71886</Consignment>' +
										'<DupSeq>1</DupSeq>' +
										'<TotalNumber>2</TotalNumber>' +
										'<DateSent>'+ DateTime.now().addMonths(-5).format('yyyy-MM-dd\'T\'HH:mm:ss')  +'</DateSent>' +
										'<ReceiverName></ReceiverName>' +
										'<ReceiverSuburb>SYDNEY</ReceiverSuburb>' +
										'<Service>O/N</Service>' +
										'<Items>1</Items>' +
										'<DeadWeight>1.00000000</DeadWeight>' +
										'<ConGUID>c17b27d6-3f98-41a1-a3b9-493dfb1e013b</ConGUID>' +
										'<UniqueExternalId>TR2_c17b27d6-3f98-41a1-a3b9-493dfb1e013b</UniqueExternalId>' +
										'<System>AIR</System>' +
									'</DUPCON_DataDetail>' +
									'<DUPCON_DataDetail>' +
										'<Consignment>2AT71886</Consignment>' +
										'<DupSeq>2</DupSeq>' +
										'<TotalNumber>2</TotalNumber>' +
										'<DateSent>'+ DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss')  +'</DateSent>' +
										'<ReceiverName>LINDA  JURY</ReceiverName>' +
										'<ReceiverSuburb>WYONG</ReceiverSuburb>' +
										'<Service>ECO</Service>' +
										'<Items>4</Items>' +
										'<DeadWeight>13.00000000</DeadWeight>' +
										'<ConGUID>ff7b48e9-f074-408d-aaa1-2089ca7a13ba</ConGUID>' +
										'<UniqueExternalId>TR2_66a94898-0927-450e-abfa-defa36972669</UniqueExternalId>' +
										'<System>AIR</System>' +
									'</DUPCON_DataDetail>' +
								'</Results>' +
							'</SearchResults>' +
							'<ResponseMetrics>' +
								'<TotalRows>2</TotalRows>' +
								'<RowsReturned>2</RowsReturned>' +
								'<FirstRow>1</FirstRow>' +
								'<LastRow>2</LastRow>' +
								'<ErrorCode>0</ErrorCode>' +
								'<Performance>' +
									'<TotalMilliseconds>110</TotalMilliseconds>' +
									'<WrapperMilliseconds>0</WrapperMilliseconds>' +
									'<DatabaseMilliseconds>109</DatabaseMilliseconds>' +
									'<TotalTicks>1585642</TotalTicks>' +
									'<WrapperTicks>2152</WrapperTicks>' +
									'<DatabaseTicks>1572428</DatabaseTicks>' +
									'<DatabaseCalls>1</DatabaseCalls>' +
								'</Performance>' +
							'</ResponseMetrics>' +
						'</SearchResult>' +
					'</SearchResponse>' +
					'</s:Body>' +
				'</s:Envelope>';
	}
	
	public static String getResponse_uniqueIdResp() {
		return '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">' +
		   '<s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
			  '<SearchResponse xmlns="http://www.auspost.com.au/Schema/CustomerCareManagement/CustomerCommunicationsManagement/StarTrackMediation/publishConsignmentArticleEvent:v1">' +
				 '<SearchResult>' +
					'<Header>' +
					   '<TimeStamp>2016-02-09T00:37:23.913Z</TimeStamp>' +
					   '<TransactionId>2016-02-09T00:37:23.913Z</TransactionId>' +
					   '<SourceId>test</SourceId>' +
					   '<Action>Reply</Action>' +
					'</Header>' +
					'<Consignment>' +
					   '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
					   '<ActualWeight>12</ActualWeight>' +
					   '<ConsignmentID>TR2_66a94898-0927-450e-abfa-defa36972669</ConsignmentID>' +
					   '<ConsignmentNumber>2AT71923</ConsignmentNumber>' +
					   '<BillingAccount>P1234567</BillingAccount>' +
					   '<ControlledReturn>false</ControlledReturn>' +
					   '<Cubing>0</Cubing>' +
					   '<DangerousGoods>false</DangerousGoods>' +
					   '<DeliveryInstructions>Special Instruciton 7</DeliveryInstructions>' +
					   '<DispatchDate>2013-10-18T00:00:00</DispatchDate>' +
					   '<ExpectedDeliveryDate>2013-10-21</ExpectedDeliveryDate>' +
					   '<InsuranceAmount>0.00</InsuranceAmount>' +
					   '<InsuranceClass/>' +
					   '<Network>SYD</Network>' +
					   '<NumberofItems>2</NumberofItems>' +
					   '<ReceiverAddress>28-32 PEACHTREE RD, PENRITH, 2750</ReceiverAddress>' +
					   '<ReceiverAddressLine1>28-32 PEACHTREE RD</ReceiverAddressLine1>' +
					   '<ReceiverAddressLine2/>' +
					   '<ReceiverAddressLine3/>' +
					   '<ReceiverCompany>COFFEY ENGINEERING</ReceiverCompany>' +
					   '<ReceiverEmail/>' +
					   '<ReceiverName>REBECCA</ReceiverName>' +
					   '<ReceiverPhone>0247313344</ReceiverPhone>' +
					   '<ReceiverFax/>' +
					   '<ReceiverMobile/>' +
					   '<ReceiverPostcode>2750</ReceiverPostcode>' +
					   '<ReceiverSuburb>PENRITH</ReceiverSuburb>' +
					   '<SenderAddress>1 Merriwa Street, GORDON, 2072</SenderAddress>' +
					   '<SenderAddressLine1>1 Merriwa Street</SenderAddressLine1>' +
					   '<SenderAddressLine2/>' +
					   '<SenderAddressLine3/>' +
					   '<SenderCompany>AaE Retail - FreightMaster Tes</SenderCompany>' +
					   '<SenderEmail/>' +
					   '<SenderPhone/>' +
					   '<SenderFax/>' +
					   '<SenderMobile/>' +
					   '<SenderName>aae</SenderName>' +
					   '<SenderPostcode>2072</SenderPostcode>' +
					   '<SenderSuburb>GORDON</SenderSuburb>' +
					   '<ServiceCode>ARL</ServiceCode>' +
					   '<ServiceDescription>Airlock</ServiceDescription>' +
					   '<ManifestReference>45956</ManifestReference>' +
					   '<PrintDate>2013-10-18</PrintDate>' +
					   '<ImportedDate>2013-10-18</ImportedDate>' +
					   '<ManifestDate>2013-10-18</ManifestDate>' +
					   '<Length>0.000000</Length>' +
					   '<Width>0.000000</Width>' +
					   '<Height>0.000000</Height>' +
					   '<CubicWeight>302.00</CubicWeight>' +
					   '<ChargeWeight>12.00000000</ChargeWeight>' +
					   '<Volume>0</Volume>' +
					   '<Invoice>""</Invoice>' +
					   '<CustomerType>AAE</CustomerType>' +
					   '<FurtherReference1>D05 1</FurtherReference1>' +
					   '<DescriptionofGoods>Boxes</DescriptionofGoods>' +
					   '<Articles>' +
						  '<Article>' +
							 '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
							 '<ArticleID>TR1_783660b1-6f2b-4f39-82e3-044858c612ed</ArticleID>' +
							 '<ArticleNumber>2G897466</ArticleNumber>' +
							 '<Events>' +
								'<Event>' +
								   '<EventID>TR1_EVENT_65b02079-9737-e311-b5f4-0050569f13f9</EventID>' +
								   '<EventSource>MTS</EventSource>' +
								   '<EventDescription>Freight Manifest Transmitted</EventDescription>' +
								   '<EventType>FMMF</EventType>' +
								   '<EventSubType>FMMF</EventSubType>' +
								   '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
								   '<ActualDateTime>2013-10-18T00:00:00</ActualDateTime>' +
								   '<DepotCode>MGT</DepotCode>' +
								   '<DepotName>Mornington</DepotName>' +
								'</Event>' +
								'<Event>' +
								   '<EventID>TR1_EVENT_20e294e0-373c-e311-b5f4-0050569f13f9</EventID>' +
								   '<EventSource>STE</EventSource>' +
								   '<EventDescription>Onboard with driver for delivery</EventDescription>' +
								   '<EventType>OUTG</EventType>' +
								   '<EventSubType>Successful</EventSubType>' +
								   '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
								   '<ActualDateTime>2013-10-24T10:07:15</ActualDateTime>' +
								   '<DepotCode>SYZ</DepotCode>' +
								   '<DepotName>SYDNEY</DepotName>' +
								   '<AddressLine1/>' +
								   '<AddressLine2/>' +
								   '<AddressLine3/>' +
								   '<City/>' +
								   '<Phone/>' +
								   '<Name/>' +
								   '<ContactName/>' +
								'</Event>' +
								'<Event>' +
								   '<EventID>TR1_EVENT_402696b5-3c3c-e311-b5f4-0050569f13f9</EventID>' +
								   '<EventSource>STE</EventSource>' +
								   '<EventDescription>Onboard with driver for delivery</EventDescription>' +
								   '<EventType>OUTG</EventType>' +
								   '<EventSubType>Successful</EventSubType>' +
								   '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
								   '<ActualDateTime>2013-10-24T10:41:54</ActualDateTime>' +
								   '<DepotCode>SYZ</DepotCode>' +
								   '<DepotName>SYDNEY</DepotName>' +
								   '<AddressLine1/>' +
								   '<AddressLine2/>' +
								   '<AddressLine3/>' +
								   '<City/>' +
								   '<Phone/>' +
								   '<Name/>' +
								   '<ContactName/>' +
								'</Event>' +
								'<Event>' +
								   '<EventID>TR1_EVENT_a85d62d0-0a3d-e311-b5f4-0050569f13f9</EventID>' +
								   '<EventSource>STE</EventSource>' +
								   '<EventDescription>Delivery attempt unsuccessful. Reason: Refused by receiver - damaged</EventDescription>' +
								   '<EventType>DELV</EventType>' +
								   '<EventSubType>UnsuccessfulDelivery</EventSubType>' +
								   '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
								   '<ActualDateTime>2013-10-24T12:43:15</ActualDateTime>' +
								   '<DepotCode>SYZ</DepotCode>' +
								   '<DepotName>SYDNEY</DepotName>' +
								   '<SignatoryName/>' +
								   '<PostOfficeName/>' +
								   '<AddressType>SCTR</AddressType>' +
								   '<AddressLine1/>' +
								   '<AddressLine2/>' +
								   '<AddressLine3/>' +
								   '<AddressPostCode/>' +
								   '<City/>' +
								   '<Phone/>' +
								   '<Name/>' +
								'</Event>' +
							 '</Events>' +
						  '</Article>' +
						  '<Article>' +
							 '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
							 '<ArticleID>TR1_eb7b835f-10a2-4240-8de7-0edeadd8b7f0</ArticleID>' +
							 '<ArticleNumber>2G897467</ArticleNumber>' +
							 '<Events>' +
								'<Event>' +
								   '<EventID>TR1_EVENT_66b02079-9737-e311-b5f4-0050569f13f9</EventID>' +
								   '<EventSource>MTS</EventSource>' +
								   '<EventDescription>Freight Manifest Transmitted</EventDescription>' +
								   '<EventType>FMMF</EventType>' +
								   '<EventSubType>FMMF</EventSubType>' +
								   '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
								   '<ActualDateTime>2013-10-18T00:00:00</ActualDateTime>' +
								   '<DepotCode>MGT</DepotCode>' +
								   '<DepotName>Mornington</DepotName>' +
								'</Event>' +
								'<Event>' +
								   '<EventID>TR1_EVENT_0c701b11-403c-e311-b5f4-0050569f13f9</EventID>' +
								   '<EventSource>STE</EventSource>' +
								   '<EventDescription>Onboard with driver for delivery</EventDescription>' +
								   '<EventType>OUTG</EventType>' +
								   '<EventSubType>Successful</EventSubType>' +
								   '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
								   '<ActualDateTime>2013-10-24T11:05:54</ActualDateTime>' +
								   '<DepotCode>SYZ</DepotCode>' +
								   '<DepotName>SYDNEY</DepotName>' +
								   '<AddressLine1/>' +
								   '<AddressLine2/>' +
								   '<AddressLine3/>' +
								   '<City/>' +
								   '<Phone/>' +
								   '<Name/>' +
								   '<ContactName/>' +
								'</Event>' +
								'<Event>' +
								   '<EventID>TR1_EVENT_a45d62d0-0a3d-e311-b5f4-0050569f13f9</EventID>' +
								   '<EventSource>STE</EventSource>' +
								   '<EventDescription>Delivery attempt unsuccessful. Reason: Refused by receiver - damaged</EventDescription>' +
								   '<EventType>DELV</EventType>' +
								   '<EventSubType>UnsuccessfulDelivery</EventSubType>' +
								   '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
								   '<ActualDateTime>2013-10-24T12:43:15</ActualDateTime>' +
								   '<DepotCode>SYZ</DepotCode>' +
								   '<DepotName>SYDNEY</DepotName>' +
								   '<SignatoryName/>' +
								   '<PostOfficeName/>' +
								   '<AddressType>SCTR</AddressType>' +
								   '<AddressLine1/>' +
								   '<AddressLine2/>' +
								   '<AddressLine3/>' +
								   '<AddressPostCode/>' +
								   '<City/>' +
								   '<Phone/>' +
								   '<Name/>' +
								'</Event>' +
							 '</Events>' +
						  '</Article>' +
					   '</Articles>' +
					   '<Events>' +
						  '<Event>' +
							 '<EventID>TR2_EVENT_65B02079-9737-E311-B5F4-0050569F13F9</EventID>' +
							 '<EventSource>MTS</EventSource>' +
							 '<EventDescription>Freight Manifest Transmitted</EventDescription>' +
							 '<EventType>FMMF</EventType>' +
							 '<EventSubType>FMMF</EventSubType>' +
							 '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
							 '<ActualDateTime>2013-10-18T00:00:00</ActualDateTime>' +
							 '<DepotCode>MGT</DepotCode>' +
							 '<DepotName>Mornington</DepotName>' +
						  '</Event>' +
						  '<Event>' +
							 '<EventID>TR2_EVENT_0C701B11-403C-E311-B5F4-0050569F13F9</EventID>' +
							 '<EventSource>STE</EventSource>' +
							 '<EventDescription>Onboard with driver for delivery</EventDescription>' +
							 '<EventType>OUTG</EventType>' +
							 '<EventSubType>Successful</EventSubType>' +
							 '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
							 '<ActualDateTime>2013-10-24T11:05:54</ActualDateTime>' +
							 '<DepotCode>SYZ</DepotCode>' +
							 '<DepotName>SYDNEY</DepotName>' +
							 '<AddressLine1/>' +
							 '<AddressLine2/>' +
							 '<AddressLine3/>' +
							 '<City/>' +
							 '<Phone/>' +
							 '<Name/>' +
							 '<ContactName/>' +
						  '</Event>' +
						  '<Event>' +
							 '<EventID>TR2_EVENT_A85D62D0-0A3D-E311-B5F4-0050569F13F9</EventID>' +
							 '<EventSource>STE</EventSource>' +
							 '<EventDescription>Delivery attempt unsuccessful. Reason: Refused by receiver - damaged</EventDescription>' +
							 '<EventType>DELV</EventType>' +
							 '<EventSubType>UnsuccessfulDelivery</EventSubType>' +
							 '<SourceSystem>TRACK &amp; TRACE</SourceSystem>' +
							 '<ActualDateTime>2013-10-24T12:43:15</ActualDateTime>' +
							 '<DepotCode>SYZ</DepotCode>' +
							 '<DepotName>SYDNEY</DepotName>' +
							 '<SignatoryName/>' +
							 '<PostOfficeName/>' +
							 '<PostOfficeCode>0</PostOfficeCode>' +
							 '<AddressType>SCTR</AddressType>' +
							 '<AddressLine1/>' +
							 '<AddressLine2/>' +
							 '<AddressLine3/>' +
							 '<AddressPostCode/>' +
							 '<City/>' +
							 '<Phone/>' +
							 '<Name/>' +
						  '</Event>' +
					   '</Events>' +
					   '<ProofOfDeliveries/>' +
					'</Consignment>' +
					'<ResponseMetrics>' +
					   '<TotalRows>0</TotalRows>' +
					   '<RowsReturned>0</RowsReturned>' +
					   '<FirstRow>0</FirstRow>' +
					   '<LastRow>0</LastRow>' +
					   '<ErrorCode>0</ErrorCode>' +
					   '<Performance>' +
						  '<TotalMilliseconds>624</TotalMilliseconds>' +
						  '<WrapperMilliseconds>0</WrapperMilliseconds>' +
						  '<DatabaseMilliseconds>0</DatabaseMilliseconds>' +
						  '<TotalTicks>8941052</TotalTicks>' +
						  '<WrapperTicks>0</WrapperTicks>' +
						  '<DatabaseTicks>0</DatabaseTicks>' +
						  '<DatabaseCalls>0</DatabaseCalls>' +
					   '</Performance>' +
					'</ResponseMetrics>' +
				 '</SearchResult>' +
			  '</SearchResponse>' +
		   '</s:Body>' +
		'</s:Envelope>';
	}
	
	public static String getResponse_eventsResp() {
		return '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">' +
		   '<s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
			  '<SearchResponse xmlns="http://www.auspost.com.au/Schema/CustomerCareManagement/CustomerCommunicationsManagement/StarTrackMediation/publishConsignmentArticleEvent:v1">' +
				 '<SearchResult>' +
					'<Header>' +
					   '<TimeStamp>2016-02-09T00:37:23.913Z</TimeStamp>' +
					   '<TransactionId>2016-02-09T00:37:23.913Z</TransactionId>' +
					   '<SourceId>test</SourceId>' +
					   '<Action>Reply</Action>' +
					'</Header>' +
					'<Consignment>' +
					   '<ConsignmentID>TM2_LSR06512_0000</ConsignmentID>' +
					   '<ConsignmentNumber>LSR06512</ConsignmentNumber>' +
					   '<Events>' +
						  '<Event>' +
							 '<EventID>TM2_EVENT_LSR06512_0000_MEL_MANIFESTED_20140401090000</EventID>' +
							 '<EventSource>S</EventSource>' +
							 '<EventDescription>ON BOARD FOR DELIVERY</EventDescription>' +
							 '<EventType>MANIFESTED</EventType>' +
							 '<SourceSystem>TEAM</SourceSystem>' +
							 '<ActualDateTime>2014-04-01T09:00:00</ActualDateTime>' +
							 '<CommentText/>' +
							 '<DepotCode>MEL</DepotCode>' +
							 '<DepotName>MELBOURNE</DepotName>' +
							 '<SignatoryName/>' +
							 '<AddressLine1>SHOP 4, NUMBER 4</AddressLine1>' +
							 '<AddressLine2>4 HIGH ST</AddressLine2>' +
							 '<AddressLine3/>' +
							 '<AddressPostCode>3153</AddressPostCode>' +
							 '<City>BAYSWATER (VIC)</City>' +
							 '<Phone/>' +
							 '<ScannerID/>' +
						  '</Event>' +
						  '<Event>' +
							 '<EventID>TM2_EVENT_LSR06512_0000_MEL_DELIVERED_20140401161300</EventID>' +
							 '<EventSource>S</EventSource>' +
							 '<EventDescription>DELIVERED. SIGNATORY - A MY</EventDescription>' +
							 '<EventType>DELIVERED</EventType>' +
							 '<SourceSystem>TEAM</SourceSystem>' +
							 '<ActualDateTime>2014-04-01T16:13:00</ActualDateTime>' +
							 '<CommentText>Driver SSUDEETH</CommentText>' +
							 '<DepotCode>MEL</DepotCode>' +
							 '<DepotName>MELBOURNE</DepotName>' +
							 '<SignatoryName>A MY</SignatoryName>' +
							 '<AddressLine1>SHOP 4, NUMBER 4</AddressLine1>' +
							 '<AddressLine2>4 HIGH ST</AddressLine2>' +
							 '<AddressLine3/>' +
							 '<AddressPostCode>3153</AddressPostCode>' +
							 '<City>BAYSWATER (VIC)</City>' +
							 '<Phone/>' +
							 '<ScannerID/>' +
						  '</Event>' +
					   '</Events>' +
					'</Consignment>' +
					'<ResponseMetrics>' +
					   '<TotalRows>0</TotalRows>' +
					   '<RowsReturned>0</RowsReturned>' +
					   '<FirstRow>0</FirstRow>' +
					   '<LastRow>0</LastRow>' +
					   '<ErrorCode>0</ErrorCode>' +
					   '<Performance>' +
						  '<TotalMilliseconds>97</TotalMilliseconds>' +
						  '<WrapperMilliseconds>0</WrapperMilliseconds>' +
						  '<DatabaseMilliseconds>0</DatabaseMilliseconds>' +
						  '<TotalTicks>1400986</TotalTicks>' +
						  '<WrapperTicks>0</WrapperTicks>' +
						  '<DatabaseTicks>0</DatabaseTicks>' +
						  '<DatabaseCalls>0</DatabaseCalls>' +
					   '</Performance>' +
					'</ResponseMetrics>' +
				 '</SearchResult>' +
			  '</SearchResponse>' +
		   '</s:Body>' +
		'</s:Envelope>';
	}
}