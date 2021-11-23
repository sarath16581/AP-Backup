//Created by David Catindoy - March 31, 2017
/**************************************************
Type:       |
Purpose:    |
Used By:
History:
--------------------------------------------------
31.03.2017  David Catindoy  Created
04.02.2020 Hasantha.liyanage@auspost.com.au updates Furtherreferences and the Attachment on Article to check for international tracking URL
**************************************************/

@isTest
public class BSPAusPostContinuationCalloutMock {

	public static String getResponse_singleConsign() {
        return '<?xml version="1.0" encoding="UTF-8"?>' +
                '<pfx2:Envelope xmlns:pfx="http://www.auspost.com.au/schemas/ESBFramework:v1" xmlns:pfx2="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.tibco.com/pe/EngineTypes" xmlns:pfx3="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:ns2="http://www.auspost.com.au/Schema/TransportandLogisticsServices/EventManagement/queryTrackEvents:v1" xmlns:tib="http://www.tibco.com/bw/xslt/custom-functions" xmlns:ns1="http://www.tibco.com/pe/DeployedVarsType" xmlns:ns4="http://www.auspost.com.au/Schema/CommonDataModel/Event:v2" xmlns:ns3="http://www.auspost.com.au/Schema/CommonDataModel/Mail_Product:v2" xmlns:ns6="http://www.auspost.com.au/Schema/CommonDataModel/InvolvedParty/Customer:v1" xmlns:ns5="http://www.auspost.com.au/Schema/CommonDataModel/Product:v1" xmlns:ns8="http://www.auspost.com.au/Schema/CommonDataModel/Location:v1" xmlns:ns7="http://www.auspost.com.au/Schema/CommonDataModel/InvolvedParty:v1" xmlns:pd="http://xmlns.tibco.com/bw/process/2003" xmlns:BW="java://com.tibco.pe.core.JavaCustomXPATHFunctions" xmlns:ns12="http://www.tibco.com/pe/GenerateErrorActivity/InputSchema">' +
                    '<pfx2:Header>' +
                        '<pfx3:InterfaceHeader>' +
                            '<pfx3:InterfaceName>queryArticle</pfx3:InterfaceName>' +
                            '<pfx3:InterfaceVersion>1.0</pfx3:InterfaceVersion>' +
                            '<pfx3:MessageType>Reply</pfx3:MessageType>' +
                            '<pfx3:BusinessReferenceID>JDQ0184460</pfx3:BusinessReferenceID>' +
                            '<pfx3:SourceSystemID>SFDC</pfx3:SourceSystemID>' +
                            '<pfx3:SourceInformation/>' +
                            '<pfx3:Timestamp>2017-03-29T10:34:01.173+11:00</pfx3:Timestamp>' +
                        '</pfx3:InterfaceHeader>' +
                    '</pfx2:Header>' +
                    '<pfx2:Body>' +
                        '<ns2:QueryTrackEventsResponse>' +
                            '<ns2:TrackingResults>' +
                                '<ns2:TrackingResult>' +
                                    '<ns2:TrackingID>JDQ0184460</ns2:TrackingID>' +
                                    '<ns2:ReturnCode>ESB-BUS-DATA-100</ns2:ReturnCode>' +
                                    '<ns2:ResultDescription>Success</ns2:ResultDescription>' +
                                    '<ns2:ConsignmentDetails>' +
                                        '<ns2:ConsignmentEnvelope>' +
                                            '<ns2:Consignment>' +
                                                '<ns3:ActionCode>U</ns3:ActionCode>' +
                                                '<ns3:ConsignmentId>JDQ0184460</ns3:ConsignmentId>' +
                                                '<ns3:MerchantId>20355936</ns3:MerchantId>' +
                                                '<ns3:MerchantLocationId>JDQ</ns3:MerchantLocationId>' +
                                                '<ns3:ExpectedDeliveryDateTime>2017-02-01T10:34:02+11:00</ns3:ExpectedDeliveryDateTime>' +
                                                '<ns3:DeliveryContacts>' +
                                                    '<ns6:Customer>' +
                                                        '<ns7:Individual/>' +
                                                        '<ns7:ElectronicContact>' +
                                                            '<pfx3:Internet>' +
                                                                '<pfx3:ContactType>EMAIL</pfx3:ContactType>' +
                                                                '<pfx3:ContactDetail>k@aus.com</pfx3:ContactDetail>' +
                                                            '</pfx3:Internet>' +
                                                        '</ns7:ElectronicContact>' +
                                                        '<ns7:Address>' +
                                                            '<ns8:AddressUsage>POSTAL</ns8:AddressUsage>' +
                                                            '<ns8:AddressDetails>' +
                                                                '<ns8:AustralianAddress>' +
                                                                    '<ns8:PostCode>3000</ns8:PostCode>' +
                                                                    '<ns8:Country>' +
                                                                        '<ns8:CountryCode>AU</ns8:CountryCode>' +
                                                                    '</ns8:Country>' +
                                                                '</ns8:AustralianAddress>' +
                                                            '</ns8:AddressDetails>' +
                                                        '</ns7:Address>' +
                                                    '</ns6:Customer>' +
                                                    '<ns3:DeliveryContactType>Delivery</ns3:DeliveryContactType>' +
                                                '</ns3:DeliveryContacts>' +
                                                '<ns3:DeliveryContacts>' +
                                                    '<ns6:Customer>' +
                                                        '<ns7:Individual>' +
                                                            '<ns7:Name>' +
                                                                '<ns7:NameUsage>IND</ns7:NameUsage>' +
                                                                '<ns7:FullName>Winning Group Test Account</ns7:FullName>' +
                                                            '</ns7:Name>' +
                                                            '<ns7:Name>' +
                                                                '<ns7:NameUsage>ORG</ns7:NameUsage>' +
                                                                '<ns7:FullName>Winning Group Test Account</ns7:FullName>' +
                                                            '</ns7:Name>' +
                                                        '</ns7:Individual>' +
                                                        '<ns7:Address>' +
                                                           '<ns8:AddressUsage>POSTAL</ns8:AddressUsage>' +
                                                            '<ns8:AddressDetails>' +
                                                                '<ns8:AustralianAddress>' +
                                                                    '<ns8:UnstructuredAddress>' +
                                                                        '<ns8:AddressLine>GPO Box 1777</ns8:AddressLine>' +
                                                                    '</ns8:UnstructuredAddress>' +
                                                                    '<ns8:SuburbOrPlaceOrLocality>MELBOURNE</ns8:SuburbOrPlaceOrLocality>' +
                                                                    '<ns8:StateOrTerritory>VIC</ns8:StateOrTerritory>' +
                                                                    '<ns8:PostCode>3001</ns8:PostCode>' +
                                                                    '<ns8:Country>' +
                                                                        '<ns8:CountryCode>AU</ns8:CountryCode>' +
                                                                    '</ns8:Country>' +
                                                                '</ns8:AustralianAddress>' +
                                                            '</ns8:AddressDetails>' +
                                                        '</ns7:Address>' +
                                                    '</ns6:Customer>' +
                                                    '<ns3:DeliveryContactType>Sender</ns3:DeliveryContactType>' +
                                                '</ns3:DeliveryContacts>' +
                                                '<ns3:TotalActualWeight>4</ns3:TotalActualWeight>' +
                                                '<ns3:Insurance>' +
                                                    '<ns3:InsuranceAmount>50</ns3:InsuranceAmount>' +
                                                '</ns3:Insurance>' +
                                                '<ns3:SignatureRequired>true</ns3:SignatureRequired>' +
                                                '<ns3:DangerousGoodsIndicator>false</ns3:DangerousGoodsIndicator>' +
                                                '<ns3:RecordModificationDateTime>2017-03-29T10:34:02+11:00</ns3:RecordModificationDateTime>' +
                                            '</ns2:Consignment>' +
                                            '<ns2:ArticleEnvelope>' +
                                                '<ns2:Article>' +
                                                    '<ns3:TrackingIdentification>' +
                                                        '<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
                                                        '<pfx3:TrackingID>JDQ018446001000930209</pfx3:TrackingID>' +
                                                    '</ns3:TrackingIdentification>' +
                                                    '<ns3:FurtherReferences>' +
                                                        '<pfx3:ReferenceCodeSet>EXPECTED_DEL_DATE</pfx3:ReferenceCodeSet>' +
                                                        '<pfx3:ReferenceID>20170201</pfx3:ReferenceID>' +
                                                    '</ns3:FurtherReferences>' +
                                                    '<ns3:FurtherReferences>' +
                                                        '<pfx3:ReferenceCodeSet>CONSIGNMENT_ID</pfx3:ReferenceCodeSet>' +
                                                        '<pfx3:ReferenceID>JDQ0184460</pfx3:ReferenceID>' +
                                                    '</ns3:FurtherReferences>' +
                                                    '<ns3:FurtherReferences>' +
                                                        '<pfx3:ReferenceCodeSet>MANIFEST_ID</pfx3:ReferenceCodeSet>' +
                                                        '<pfx3:ReferenceID>P5180</pfx3:ReferenceID>' +
                                                    '</ns3:FurtherReferences>' +
                                                    '<ns3:FurtherReferences>' +
                                                        '<pfx3:ReferenceCodeSet>ARTICLE_GUID</pfx3:ReferenceCodeSet>' +
                                                        '<pfx3:ReferenceID>1000000003726519TE0031</pfx3:ReferenceID>' +
                                                    '</ns3:FurtherReferences>' +
                                                    '<ns3:ActionCode>U</ns3:ActionCode>' +
                                                    '<ns3:ArticleId>JDQ018446001000930209</ns3:ArticleId>' +
                                                    '<ns3:ProductID>146</ns3:ProductID>' +
                                                    '<ns3:ProductName>Parcel Post</ns3:ProductName>' +
                                                    '<ns3:SubProductID>93</ns3:SubProductID>' +
                                                    '<ns3:SubProductName>Parcel Post</ns3:SubProductName>' +
                                                    '<ns3:BaseServiceCode>02</ns3:BaseServiceCode>' +
                                                    '<ns3:MerchantLocationId>JDQ</ns3:MerchantLocationId>' +
                                                    '<ns3:MeasurementData>' +
                                                        '<pfx3:HeightCM>1</pfx3:HeightCM>' +
                                                        '<pfx3:WidthCM>1</pfx3:WidthCM>' +
                                                        '<pfx3:LengthCM>1</pfx3:LengthCM>' +
                                                        '<pfx3:WeightKG>4</pfx3:WeightKG>' +
                                                    '</ns3:MeasurementData>' +
                                                    '<ns3:FullBarcode>019931265099999891JDQ018446001000930209|4208000|8008170130152452</ns3:FullBarcode>' +
                                                    '<ns3:EventNotification>01</ns3:EventNotification>' +
                                                    '<ns3:TransitCoverRequired>true</ns3:TransitCoverRequired>' +
                                                    '<ns3:Status>' +
                                                        '<ns3:StatusAttributeName>Destination_Country</ns3:StatusAttributeName>' +
                                                        '<ns3:StatusAttributeValue>Australia</ns3:StatusAttributeValue>' +
                                                    '</ns3:Status>' +
                                                    '<ns3:Status>' +
                                                        '<ns3:StatusAttributeName>Delivery Status of Article</ns3:StatusAttributeName>' +
                                                        '<ns3:StatusAttributeValue>Delivered</ns3:StatusAttributeValue>' +
                                                        '<ns3:StatusModificationDateTime>2017-03-06T14:50:53+11:00</ns3:StatusModificationDateTime>' +
                                                    '</ns3:Status>' +
                                                    '<ns3:Status>' +
                                                        '<ns3:StatusAttributeName>Physical Condition of Article</ns3:StatusAttributeName>' +
                                                        '<ns3:StatusAttributeValue>OK</ns3:StatusAttributeValue>' +
                                                        '<ns3:StatusModificationDateTime>2017-03-29T10:34:02Z</ns3:StatusModificationDateTime>' +
                                                    '</ns3:Status>' +
                                                    '<ns3:Status>' +
                                                        '<ns3:StatusAttributeName>Delivery Services Allowed</ns3:StatusAttributeName>' +
                                                        '<ns3:StatusAttributeValue>false</ns3:StatusAttributeValue>' +
                                                        '<ns3:StatusModificationDateTime>2017-03-06T14:50:53+11:00</ns3:StatusModificationDateTime>' +
                                                    '</ns3:Status>' +
                                                    '<ns3:Status>' +
                                                        '<ns3:StatusAttributeName>Track Status of Article</ns3:StatusAttributeName>' +
                                                        '<ns3:StatusAttributeValue>Delivered</ns3:StatusAttributeValue>' +
                                                        '<ns3:StatusModificationDateTime>2017-03-06T14:50:53+11:00</ns3:StatusModificationDateTime>' +
                                                    '</ns3:Status>' +
                                                    '<ns3:Insurance>' +
                                                        '<ns3:InsuranceRequired>true</ns3:InsuranceRequired>' +
                                                        '<ns3:InsuranceAmount>50</ns3:InsuranceAmount>' +
                                                        '<ns3:InsuranceChargeAmount>0.75</ns3:InsuranceChargeAmount>' +
                                                    '</ns3:Insurance>' +
                                                    '<ns3:RecordModificationDateTime>2017-03-29T10:34:02+11:00</ns3:RecordModificationDateTime>' +
                                                '</ns2:Article>' +
                                                '<ns2:MailEvent>' +
                                                    '<ns4:EventType>AFC-ER31</ns4:EventType>' +
                                                    '<ns4:EventDescription>Lodged by customer</ns4:EventDescription>' +
                                                    '<ns4:EventDateTime>2017-03-21T13:30:56+11:00</ns4:EventDateTime>' +
                                                    '<ns4:EventMessageTransmissionDateTime>2017-03-21T13:31:10+11:00</ns4:EventMessageTransmissionDateTime>' +
                                                    '<ns4:DataEntryType>A</ns4:DataEntryType>' +
                                                    '<ns4:SenderEventMessageNumber>1b96468c-e054-4781-870a-035d40b2536b</ns4:SenderEventMessageNumber>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>CONSIGNMENT_ID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>JDQ0184460</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>BULK_DM_ID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>TM-00JDQP5180</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>EVENT_GUID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>5000000006501197TE0031</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>PROCESSED_DATE</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>2017-03-21T02:31:13+00:00</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:TrackingIdentification>' +
                                                        '<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
                                                        '<pfx3:TrackingID>JDQ018446001000930209</pfx3:TrackingID>' +
                                                    '</ns4:TrackingIdentification>' +
                                                    '<ns4:ArticleEventDetails>' +
                                                        '<ns4:TransitCoverCharge>0.75</ns4:TransitCoverCharge>' +
                                                    '</ns4:ArticleEventDetails>' +
                                                    '<ns4:ConsignmentEventDetails>' +
                                                        '<ns4:DangerousGoodsIndicator>false</ns4:DangerousGoodsIndicator>' +
                                                    '</ns4:ConsignmentEventDetails>' +
                                                    '<ns4:LocationIdentifications>' +
                                                        '<ns4:LocationCodeSet>WORK_CENTRE</ns4:LocationCodeSet>' +
                                                        '<ns4:LocationCodeID>201531</ns4:LocationCodeID>' +
                                                        '<ns4:LocationCodeName>COFFS HARBOUR DC</ns4:LocationCodeName>' +
                                                        '<ns4:Address>' +
                                                            '<ns8:UnstructuredAddress>' +
                                                                '<ns8:AddressLine/>' +
                                                                '<ns8:AddressLine>2 MANSBRIDGE DRIVE</ns8:AddressLine>' +
                                                                '<ns8:AddressLine>NORTH BOAMBEE VALLEY NSW</ns8:AddressLine>' +
                                                            '</ns8:UnstructuredAddress>' +
                                                            '<ns8:StateOrTerritoryOrProvince>NSW</ns8:StateOrTerritoryOrProvince>' +
                                                            '<ns8:PostCode>2450</ns8:PostCode>' +
                                                        '</ns4:Address>' +
                                                    '</ns4:LocationIdentifications>' +
                                                    '<ns4:DeliveryPostcode>8000</ns4:DeliveryPostcode>' +
                                                '</ns2:MailEvent>' +
                                                '<ns2:MailEvent>' +
                                                    '<ns4:EventType>DD-ER9</ns4:EventType>' +
                                                    '<ns4:EventDescription>Attempted delivery</ns4:EventDescription>' +
                                                    '<ns4:EventDateTime>2017-03-07T12:14:33+11:00</ns4:EventDateTime>' +
                                                    '<ns4:EventMessageTransmissionDateTime>2017-03-07T12:14:59+11:00</ns4:EventMessageTransmissionDateTime>' +
                                                    '<ns4:EventReasonText>OPQ</ns4:EventReasonText>' +
                                                    '<ns4:DataEntryType>A</ns4:DataEntryType>' +
                                                    '<ns4:SenderEventMessageNumber>344e37b0-f904-4aa1-b8de-035cf85384ff</ns4:SenderEventMessageNumber>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>CONSIGNMENT_ID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>JDQ0184460</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>BULK_DM_ID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>TM-00JDQP5180</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>EVENT_GUID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>5000000006484526TE0031</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>PROCESSED_DATE</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>2017-03-07T01:15:04+00:00</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:TrackingIdentification>' +
                                                        '<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
                                                        '<pfx3:TrackingID>JDQ018446001000930209</pfx3:TrackingID>' +
                                                    '</ns4:TrackingIdentification>' +
                                                    '<ns4:ArticleEventDetails>' +
                                                        '<ns4:TransitCoverCharge>0.75</ns4:TransitCoverCharge>' +
                                                    '</ns4:ArticleEventDetails>' +
                                                    '<ns4:ConsignmentEventDetails>' +
                                                        '<ns4:DangerousGoodsIndicator>false</ns4:DangerousGoodsIndicator>' +
                                                    '</ns4:ConsignmentEventDetails>' +
                                                    '<ns4:LocationIdentifications>' +
                                                        '<ns4:LocationCodeSet>WORK_CENTRE</ns4:LocationCodeSet>' +
                                                        '<ns4:LocationCodeID>201531</ns4:LocationCodeID>' +
                                                        '<ns4:LocationCodeName>COFFS HARBOUR DC</ns4:LocationCodeName>' +
                                                        '<ns4:Address>' +
                                                            '<ns8:UnstructuredAddress>' +
                                                                '<ns8:AddressLine/>' +
                                                                '<ns8:AddressLine>2 MANSBRIDGE DRIVE</ns8:AddressLine>' +
                                                                '<ns8:AddressLine>NORTH BOAMBEE VALLEY NSW</ns8:AddressLine>' +
                                                            '</ns8:UnstructuredAddress>' +
                                                            '<ns8:StateOrTerritoryOrProvince>NSW</ns8:StateOrTerritoryOrProvince>' +
                                                            '<ns8:PostCode>2450</ns8:PostCode>' +
                                                        '</ns4:Address>' +
                                                    '</ns4:LocationIdentifications>' +
                                                    '<ns4:Comments>OPQ</ns4:Comments>' +
                                                    '<ns4:DeliveryPostcode>8000</ns4:DeliveryPostcode>' +
                                                '</ns2:MailEvent>' +
                                                '<ns2:MailEvent>' +
                                                    '<ns4:EventType>DD-ER11</ns4:EventType>' +
                                                    '<ns4:EventDescription>Attempted delivery - redirected to Post Office</ns4:EventDescription>' +
                                                    '<ns4:EventDateTime>2017-03-06T14:51:52+11:00</ns4:EventDateTime>' +
                                                    '<ns4:EventMessageTransmissionDateTime>2017-03-06T14:51:54+11:00</ns4:EventMessageTransmissionDateTime>' +
                                                    '<ns4:DataEntryType>A</ns4:DataEntryType>' +
                                                    '<ns4:SenderEventMessageNumber>259babf1-47d8-4ec1-b188-035cf3bcd7ff</ns4:SenderEventMessageNumber>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>CONSIGNMENT_ID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>JDQ0184460</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>BULK_DM_ID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>TM-00JDQP5180</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>EVENT_GUID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>5000000006483533TE0031</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>PROCESSED_DATE</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>2017-03-06T03:51:59+00:00</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:TrackingIdentification>' +
                                                        '<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
                                                        '<pfx3:TrackingID>JDQ018446001000930209</pfx3:TrackingID>' +
                                                    '</ns4:TrackingIdentification>' +
                                                    '<ns4:ArticleEventDetails>' +
                                                        '<ns4:TransitCoverCharge>0.75</ns4:TransitCoverCharge>' +
                                                    '</ns4:ArticleEventDetails>' +
                                                    '<ns4:ConsignmentEventDetails>' +
                                                        '<ns4:DangerousGoodsIndicator>false</ns4:DangerousGoodsIndicator>' +
                                                    '</ns4:ConsignmentEventDetails>' +
                                                    '<ns4:LocationIdentifications>' +
                                                        '<ns4:LocationCodeSet>WORK_CENTRE</ns4:LocationCodeSet>' +
                                                        '<ns4:LocationCodeID>201531</ns4:LocationCodeID>' +
                                                        '<ns4:LocationCodeName>COFFS HARBOUR DC</ns4:LocationCodeName>' +
                                                        '<ns4:Address>' +
                                                            '<ns8:UnstructuredAddress>' +
                                                                '<ns8:AddressLine/>' +
                                                                '<ns8:AddressLine>2 MANSBRIDGE DRIVE</ns8:AddressLine>' +
                                                                '<ns8:AddressLine>NORTH BOAMBEE VALLEY NSW</ns8:AddressLine>' +
                                                            '</ns8:UnstructuredAddress>' +
                                                            '<ns8:StateOrTerritoryOrProvince>NSW</ns8:StateOrTerritoryOrProvince>' +
                                                            '<ns8:PostCode>2450</ns8:PostCode>' +
                                                        '</ns4:Address>' +
                                                    '</ns4:LocationIdentifications>' +
                                                    '<ns4:DeliveryPostcode>8000</ns4:DeliveryPostcode>' +
                                                '</ns2:MailEvent>' +
                                                '<ns2:CommunicationEvent>' +
                                                    '<ns4:EventType>DD-ER9123</ns4:EventType>' +
                                                    '<ns4:EventDescription>Attempted delivery - redirected to Post Office</ns4:EventDescription>' +
                                                    '<ns4:EventDateTime>2017-03-06T14:51:52+11:00</ns4:EventDateTime>' +
                                                    '<ns4:EventMessageTransmissionDateTime>2017-03-06T14:51:54+11:00</ns4:EventMessageTransmissionDateTime>' +
                                                    '<ns4:EventReasonID>091283</ns4:EventReasonID>' +
                                                    '<ns4:EventReasonText>Sample Reason</ns4:EventReasonText>' +
                                                    '<ns4:DataEntryType>A</ns4:DataEntryType>' +
                                                    '<ns4:SenderEventMessageNumber>259babf1-47d8-4ec1-b188-035cf3bcd7ff</ns4:SenderEventMessageNumber>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>CONSIGNMENT_ID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>JDQ0184460</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>BULK_DM_ID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>TM-00JDQP5180</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>EVENT_GUID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>5000000006483533TE0031</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>PROCESSED_DATE</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>2017-03-06T03:51:59+00:00</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:TrackingIdentification>' +
                                                        '<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
                                                        '<pfx3:TrackingID>JDQ018446001000930209</pfx3:TrackingID>' +
                                                    '</ns4:TrackingIdentification>' +
                                                '</ns2:CommunicationEvent>' +
                                                '<ns2:DeviceEvent>' +
                                                    '<ns4:EventType>DD-ER0424</ns4:EventType>' +
                                                    '<ns4:EventDescription>Attempted delivery - redirected to Post Office</ns4:EventDescription>' +
                                                    '<ns4:EventDateTime>2017-03-06T14:51:52+11:00</ns4:EventDateTime>' +
                                                    '<ns4:EventMessageTransmissionDateTime>2017-03-06T14:51:54+11:00</ns4:EventMessageTransmissionDateTime>' +
                                                    '<ns4:EventReasonID>091283</ns4:EventReasonID>' +
                                                    '<ns4:EventReasonText>Sample Reason</ns4:EventReasonText>' +
                                                    '<ns4:DataEntryType>A</ns4:DataEntryType>' +
                                                    '<ns4:ActiveStatus>Open</ns4:ActiveStatus>' +
                                                    '<ns4:WorkCenter>Melbourne</ns4:WorkCenter>' +
                                                    '<ns4:ContractAssigneTo>David Catindoy</ns4:ContractAssigneTo>' +
                                                    '<ns4:SenderEventMessageNumber>259babf1-47d8-4ec1-b188-035cf3bcd7ff</ns4:SenderEventMessageNumber>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>CONSIGNMENT_ID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>JDQ0184460</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>BULK_DM_ID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>TM-00JDQP5180</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>EVENT_GUID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>5000000006483533TE0031</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>PROCESSED_DATE</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>2017-03-06T03:51:59+00:00</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:TrackingIdentification>' +
                                                        '<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
                                                        '<pfx3:TrackingID>JDQ018446001000930209</pfx3:TrackingID>' +
                                                    '</ns4:TrackingIdentification>' +
                                                '</ns2:DeviceEvent>' +
                                            '</ns2:ArticleEnvelope>' +
                                        '</ns2:ConsignmentEnvelope>' +
                                    '</ns2:ConsignmentDetails>' +
                                '</ns2:TrackingResult>' +
                            '</ns2:TrackingResults>' +
                        '</ns2:QueryTrackEventsResponse>' +
                    '</pfx2:Body>' +
                '</pfx2:Envelope>';
    }

	public static String getResponse_article() {
		return '<?xml version="1.0" encoding="UTF-8"?>' +
				'<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' +
				'	<SOAP-ENV:Header>' +
				'		<pfx3:InterfaceHeader xmlns:xs="http://www.w3.org/2001/XMLSchema"' +
				'		                      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' +
				'		                      xmlns:ns0="http://schemas.xmlsoap.org/soap/envelope/"' +
				'		                      xmlns:jms1="http://www.tibco.com/namespaces/tnt/plugins/jms"' +
				'		                      xmlns:pfx="http://www.auspost.com.au/schemas/ESBFramework:v1"' +
				'		                      xmlns:pfx2="http://schemas.xmlsoap.org/soap/envelope/"' +
				'		                      xmlns:ns="http://www.tibco.com/pe/EngineTypes"' +
				'		                      xmlns:pfx3="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1"' +
				'		                      xmlns:xsd="http://www.w3.org/2001/XMLSchema"' +
				'		                      xmlns:ns2="http://www.auspost.com.au/Schema/TransportandLogisticsServices/EventManagement:v1"' +
				'		                      xmlns:tib="http://www.tibco.com/bw/xslt/custom-functions"' +
				'		                      xmlns:ns1="http://www.tibco.com/pe/DeployedVarsType"' +
				'		                      xmlns:ns4="http://www.auspost.com.au/Schema/CommonDataModel/Event:v2"' +
				'		                      xmlns:ns3="http://www.auspost.com.au/Schema/CommonDataModel/Mail_Product:v2"' +
				'		                      xmlns:ns6="http://www.auspost.com.au/Schema/CommonDataModel/InvolvedParty/Customer:v1"' +
				'		                      xmlns:ns5="http://www.auspost.com.au/Schema/CommonDataModel/Product:v1"' +
				'		                      xmlns:ns8="http://www.auspost.com.au/Schema/CommonDataModel/Location:v1"' +
				'		                      xmlns:ns7="http://www.auspost.com.au/Schema/CommonDataModel/InvolvedParty:v1"' +
				'		                      xmlns:pd="http://xmlns.tibco.com/bw/process/2003"' +
				'		                      xmlns:BW="java://com.tibco.pe.core.JavaCustomXPATHFunctions"' +
				'		                      xmlns:ns12="http://www.tibco.com/pe/GenerateErrorActivity/InputSchema">' +
				'			<pfx3:InterfaceName>queryArticle</pfx3:InterfaceName>' +
				'			<pfx3:InterfaceVersion>1.0</pfx3:InterfaceVersion>' +
				'			<pfx3:MessageType>Reply</pfx3:MessageType>' +
				'			<pfx3:BusinessReferenceID>42N236054201000935101</pfx3:BusinessReferenceID>' +
				'			<pfx3:SourceSystemID>SFDC</pfx3:SourceSystemID>' +
				'			<pfx3:SourceInformation/>' +
				'			<pfx3:Timestamp>2019-06-15T08:38:00.362+10:00</pfx3:Timestamp>' +
				'		</pfx3:InterfaceHeader>' +
				'	</SOAP-ENV:Header>' +
				'	<SOAP-ENV:Body>' +
				'		<ns0:QueryTrackEventsResponse' +
				'			xmlns:ns0="http://www.auspost.com.au/Schema/TransportandLogisticsServices/EventManagement/queryTrackEvents:v1">' +
				'			<ns0:TrackingResults>' +
				'				<pfx4:TrackingResult xmlns:pfx="http://www.auspost.com.au/schemas/ESBFramework:v1"' +
				'				                     xmlns:pfx2="http://schemas.xmlsoap.org/soap/envelope/"' +
				'				                     xmlns:ns="http://www.tibco.com/pe/EngineTypes"' +
				'				                     xmlns:pfx3="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1"' +
				'				                     xmlns:pfx4="http://www.auspost.com.au/Schema/TransportandLogisticsServices/EventManagement/queryTrackEvents:v1"' +
				'				                     xmlns:xsd="http://www.w3.org/2001/XMLSchema"' +
				'				                     xmlns:tib="http://www.tibco.com/bw/xslt/custom-functions"' +
				'				                     xmlns:ns1="http://www.tibco.com/pe/DeployedVarsType"' +
				'				                     xmlns:ns4="http://www.auspost.com.au/Schema/CommonDataModel/Mail_Product:v2"' +
				'				                     xmlns:ns3="http://www.auspost.com.au/Schema/TransportandLogisticsServices/EventManagement:v1"' +
				'				                     xmlns:ns6="http://www.auspost.com.au/Schema/CommonDataModel/Product:v1"' +
				'				                     xmlns:ns5="http://www.auspost.com.au/Schema/CommonDataModel/Event:v2"' +
				'				                     xmlns:ns8="http://www.auspost.com.au/Schema/CommonDataModel/InvolvedParty:v1"' +
				'				                     xmlns:ns7="http://www.auspost.com.au/Schema/CommonDataModel/InvolvedParty/Customer:v1"' +
				'				                     xmlns:pd="http://xmlns.tibco.com/bw/process/2003"' +
				'				                     xmlns:BW="java://com.tibco.pe.core.JavaCustomXPATHFunctions"' +
				'				                     xmlns:ns9="http://www.auspost.com.au/Schema/CommonDataModel/Location:v1"' +
				'				                     xmlns:ns12="http://www.tibco.com/pe/GenerateErrorActivity/InputSchema">' +
				'					<pfx4:TrackingID>42N236054201000935101</pfx4:TrackingID>' +
				'					<pfx4:ArticleDetails>' +
				'						<pfx4:ArticleEnvelope>' +
				'							<pfx4:Article>' +
				'								<ns4:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns4:TrackingIdentification>' +
				'								<ns4:FurtherReferences>' +
				'									<pfx3:ReferenceCodeSet>INTERNAT_TRACK_ID</pfx3:ReferenceCodeSet>' +
				'									<pfx3:ReferenceID>811_LP7898923408909234j082</pfx3:ReferenceID>' +
				'								</ns4:FurtherReferences>' +
				'								<ns4:FurtherReferences>' +
				'									<pfx3:ReferenceCodeSet>DELIVERED_BY_DATE</pfx3:ReferenceCodeSet>' +
				'									<pfx3:ReferenceID>20190614</pfx3:ReferenceID>' +
				'								</ns4:FurtherReferences>' +
				'								<ns4:FurtherReferences>' +
				'									<pfx3:ReferenceCodeSet>LODGEMENT_DATE</pfx3:ReferenceCodeSet>' +
				'									<pfx3:ReferenceID>20190608</pfx3:ReferenceID>' +
				'								</ns4:FurtherReferences>' +
				'								<ns4:FurtherReferences>' +
				'									<pfx3:ReferenceCodeSet>RD_INEL_REASON</pfx3:ReferenceCodeSet>' +
				'									<pfx3:ReferenceID>4</pfx3:ReferenceID>' +
				'								</ns4:FurtherReferences>' +
				'								<ns4:FurtherReferences>' +
				'									<pfx3:ReferenceCodeSet>SD_INEL_REASON</pfx3:ReferenceCodeSet>' +
				'									<pfx3:ReferenceID>6</pfx3:ReferenceID>' +
				'								</ns4:FurtherReferences>' +
				'								<ns4:FurtherReferences>' +
				'									<pfx3:ReferenceCodeSet>EXPECTED_DEL_DATE</pfx3:ReferenceCodeSet>' +
				'									<pfx3:ReferenceID>20190614</pfx3:ReferenceID>' +
				'								</ns4:FurtherReferences>' +
				'								<ns4:FurtherReferences>' +
				'									<pfx3:ReferenceCodeSet>LATEST_EVT_DATE_TIME</pfx3:ReferenceCodeSet>' +
				'									<pfx3:ReferenceID>2019-06-15T01:55:39+10:00</pfx3:ReferenceID>' +
				'								</ns4:FurtherReferences>' +
				'								<ns4:FurtherReferences>' +
				'									<pfx3:ReferenceCodeSet>LATEST_EVT_LOCATION</pfx3:ReferenceCodeSet>' +
				'									<pfx3:ReferenceID>DARLINGHURST NSW</pfx3:ReferenceID>' +
				'								</ns4:FurtherReferences>' +
				'								<ns4:FurtherReferences>' +
				'									<pfx3:ReferenceCodeSet>LATEST_EVT_LOC_WC</pfx3:ReferenceCodeSet>' +
				'									<pfx3:ReferenceID>231765</pfx3:ReferenceID>' +
				'								</ns4:FurtherReferences>' +
				'								<ns4:FurtherReferences>' +
				'									<pfx3:ReferenceCodeSet>LATEST_EVT_LOC_ID</pfx3:ReferenceCodeSet>' +
				'									<pfx3:ReferenceID>DD-ER4</pfx3:ReferenceID>' +
				'								</ns4:FurtherReferences>' +
				'								<ns4:FurtherReferences>' +
				'									<pfx3:ReferenceCodeSet>CONSIGNMENT_ID</pfx3:ReferenceCodeSet>' +
				'									<pfx3:ReferenceID>42N2360542</pfx3:ReferenceID>' +
				'								</ns4:FurtherReferences>' +
				'								<ns4:FurtherReferences>' +
				'									<pfx3:ReferenceCodeSet>MANIFEST_ID</pfx3:ReferenceCodeSet>' +
				'									<pfx3:ReferenceID>AP08378208</pfx3:ReferenceID>' +
				'								</ns4:FurtherReferences>' +
				'								<ns4:FurtherReferences>' +
				'									<pfx3:ReferenceCodeSet>ARTICLE_GUID</pfx3:ReferenceCodeSet>' +
				'									<pfx3:ReferenceID>1000001741508364PE1031</pfx3:ReferenceID>' +
				'								</ns4:FurtherReferences>' +
				'								<n6:Attachments '+
				'												xmlns:jms1="http://www.tibco.com/namespaces/tnt/plugins/jms"'+
				'												xmlns:pfx="http://www.auspost.com.au/Schema/CommonDataModel/External:v1"'+
				'												xmlns:pfx2="http://www.auspost.com.au/EventManagement"'+
				'												xmlns:ns="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1"'+
				'												xmlns:pfx3="http://www.auspost.com.au/Service/SCEMSRV/Event:v1"'+
				'												xmlns:ns2="http://www.tibco.com/pe/EngineTypes"'+
				'												xmlns:ns4="http://xmlns.tibco.com/encodings/mime"'+
				'												xmlns:ns3="http://www.auspost.com.au/Schema/CommonMessageModel/ActivityEvent:v4"'+
				'												xmlns:ns6="http://schemas.tibco.com/bw/pe/plugin/5.0/exceptions"'+
				'												xmlns:ns5="http://schemas.tibco.com/bw/plugins/http/5.0/httpExceptions"'+
				'												xmlns:ns8="http://www.auspost.com.au/Schema/CommonDataModel/Mail_Product:v2"'+
				'												xmlns:ns7="http://www.auspost.com.au/Schema/CommonDataModel/Product:v1"'+
				'												xmlns:ns12="http://www.auspost.com.au/Schema/CommonDataModel/Location:v1"'+
				'												xmlns:pfx6="http://www.auspost.com.au/ESB/schema/ESBTypes"'+
				'												xmlns:pfx7="http://www.auspost.com.au/Schema/Services/DeliverySvcs/queryTrackEvents:v1"'+
				'												xmlns:pfx8="http://www.nrf-arts.org/IXRetail/namespace/"'+
				'												xmlns:pfx9="http://www.auspost.com.au/Schema/CommonMessageModel/ActivityEvent:v1"'+
				'												xmlns:pfx4="http://www.auspost.com.au/schema/Services/DeliverySvcs/TrackTrace/ArticleEventMediation"'+
				'												xmlns:pfx5="http://www.tibco.com/pe/GenerateErrorActivity/InputSchema"'+
				'												xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"'+
				'												xmlns:ns13="http://www.tibco.com/schemas/SAP-EM/Resources/Schemas/StandardErrorSchema.xsd"'+
				'												xmlns:ns9="http://www.auspost.com.au/Schema/CommonDataModel/Event:v2"'+
				'												xmlns:ns11="http://www.auspost.com.au/Schema/CommonDataModel/InvolvedParty:v1"'+
				'												xmlns:ns10="http://www.auspost.com.au/Schema/CommonDataModel/InvolvedParty/Customer:v1"'+
				'												xmlns:ns17="http://www.auspost.com.au/Schema/CommonMessageModel/ActivityEvent:v4"'+
				'												xmlns:ns16="http://www.tibco.com/pe/WriteToLogActivitySchema"'+
				'												xmlns:ns15="http://www.auspost.com.au/Schema/CommonDataModel/InvolvedParty:v1"'+
				'												xmlns:ns14="http://www.auspost.com.au/Schema/Private/SAP-EM/AdditionalErrorDetail"'+
				'												xmlns:ns19="http://www.auspost.com.au/Schema/CommonDataModel/Mail_Product:v2"'+
				'												xmlns:ns18="http://www.auspost.com.au/Schema/CommonDataModel/Event:v2"'+
				'												xmlns:pfx19="http://www.auspost.com.au/Schema/ProductandServiceFulfilment/CardServices/checkCardAvailability:v1"'+
				'												xmlns:pfx17="http://www.auspost.com.au/Schema/TransportandLogisticsServices/EventManagement:v1"'+
				'												xmlns:pfx18="http://www.auspost.com.au/schemas/ESBFramework:v1"'+
				'												xmlns:pfx11="http://www.tibco.com/schemas/TrackEventService/Resources/Schemas/Common Data Model/Operations/QueryTrackEvents/Schema.xsd"'+
				'												xmlns:pfx12="http://www.auspost.com.au/Schema/Services/DeliverySvcs/ConsignmentEvents"'+
				'												xmlns:pfx10="http://www.auspost.com.au/concrete/Services/DeliverySvcs/TrackTrace/ArticleEventMediation"'+
				'												xmlns:pfx15="http://www.tibco.com/ns/no_namespace_schema_location/Resources/Web Services/SAP-EM/S09_ConsignmentByIDQuery_v0.04.wsdl"'+
				'												xmlns:pfx16="http://xmlns.example.com/1228701988187"'+
				'												xmlns:pfx13="http://www.auspost.com.au/Service/SCEMSRV/Product:v1"'+
				'												xmlns:pfx14="http://www.auspost.com.au/Schema/CommonDataModel/Product:v1"'+
				'												xmlns:n0="http://www.auspost.com.au/Schema/CommonDataModel/External:v1"'+
				'												xmlns:n1="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1"'+
				'												xmlns:n2="http://www.auspost.com.au/Schema/CommonDataModel/Event:v2"'+
				'												xmlns:n3="http://www.auspost.com.au/Schema/CommonDataModel/InvolvedParty/Customer:v1"'+
				'												xmlns:pfx71="http://www.auspost.com.au/schemas/ESBFramework:v1"'+
				'												xmlns:n4="http://www.auspost.com.au/Schema/CommonDataModel/InvolvedParty:v1"'+
				'												xmlns:n5="http://www.auspost.com.au/Schema/CommonDataModel/Location:v1"'+
				'												xmlns:n6="http://www.auspost.com.au/Schema/CommonDataModel/Mail_Product:v2"'+
				'												xmlns:n7="http://www.auspost.com.au/Schema/CommonDataModel/Product:v1"'+
				'												xmlns:n8="http://www.auspost.com.au/Schema/CommonMessageModel/ActivityEvent:v4"'+
				'												xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/"'+
				'												xmlns:prx="urn:sap.com:proxy:TE0:/1SAI/TAS03757F78BC40FC6627D4:740">'+
				'									<n6:Attachment>'+
				'										<n1:AttachmentType>ExternalTrackingURL</n1:AttachmentType>'+
				'										<n1:ContentType>URL</n1:ContentType>'+
				'										<n1:URL>inttrack32534710239093092309</n1:URL>'+
				'									</n6:Attachment>'+
				'								</n6:Attachments>'+
				'								<ns4:ActionCode>U</ns4:ActionCode>' +
				'								<ns4:ArticleId>42N236054201000935101</ns4:ArticleId>' +
				'								<ns4:ProductID>146</ns4:ProductID>' +
				'								<ns4:ProductName>Parcel Post</ns4:ProductName>' +
				'								<ns4:SubProductID>93</ns4:SubProductID>' +
				'								<ns4:SubProductName>Parcel Post</ns4:SubProductName>' +
				'								<ns4:BaseServiceCode>51</ns4:BaseServiceCode>' +
				'								<ns4:MerchantLocationId>42N</ns4:MerchantLocationId>' +
				'								<ns4:MeasurementData>' +
				'									<pfx3:Quantity>1</pfx3:Quantity>' +
				'									<pfx3:HeightCM>1.0</pfx3:HeightCM>' +
				'									<pfx3:WidthCM>5.0</pfx3:WidthCM>' +
				'									<pfx3:LengthCM>10.0</pfx3:LengthCM>' +
				'									<pfx3:WeightKG>2.0</pfx3:WeightKG>' +
				'								</ns4:MeasurementData>' +
				'								<ns4:FullBarcode>01993126509999989142N236054201000935101&#124;4202010&#124;8008190607022248</ns4:FullBarcode>' +
				'								<ns4:EventNotification>01</ns4:EventNotification>' +
				'								<ns4:Status>' +
				'									<ns4:StatusAttributeName>Destination_Country</ns4:StatusAttributeName>' +
				'									<ns4:StatusAttributeValue>Australia</ns4:StatusAttributeValue>' +
				'								</ns4:Status>' +
				'								<ns4:Status>' +
				'									<ns4:StatusAttributeName>Delivery Status of Article</ns4:StatusAttributeName>' +
				'									<ns4:StatusAttributeValue>Awaiting Collection</ns4:StatusAttributeValue>' +
				'									<ns4:StatusModificationDateTime>2019-06-14T14:19:43+10:00</ns4:StatusModificationDateTime>' +
				'								</ns4:Status>' +
				'								<ns4:Status>' +
				'									<ns4:StatusAttributeName>Milestone</ns4:StatusAttributeName>' +
				'									<ns4:StatusAttributeValue>Awaiting collection</ns4:StatusAttributeValue>' +
				'									<ns4:StatusModificationDateTime>2019-06-14T14:19:43+10:00</ns4:StatusModificationDateTime>' +
				'								</ns4:Status>' +
				'								<ns4:Status>' +
				'									<ns4:StatusAttributeName>Physical Condition of Article</ns4:StatusAttributeName>' +
				'									<ns4:StatusAttributeValue>OK</ns4:StatusAttributeValue>' +
				'									<ns4:StatusModificationDateTime>2019-06-15T08:37:59Z</ns4:StatusModificationDateTime>' +
				'								</ns4:Status>' +
				'								<ns4:Status>' +
				'									<ns4:StatusAttributeName>Customer ATL Request Status</ns4:StatusAttributeName>' +
				'									<ns4:StatusAttributeValue>Expired</ns4:StatusAttributeValue>' +
				'									<ns4:StatusModificationDateTime>2019-06-14T13:34:19+10:00</ns4:StatusModificationDateTime>' +
				'								</ns4:Status>' +
				'								<ns4:Status>' +
				'									<ns4:StatusAttributeName>Redirect Allowed Status</ns4:StatusAttributeName>' +
				'									<ns4:StatusAttributeValue>Unavailable</ns4:StatusAttributeValue>' +
				'									<ns4:StatusModificationDateTime>2019-06-14T06:21:43+10:00</ns4:StatusModificationDateTime>' +
				'								</ns4:Status>' +
				'								<ns4:Status>' +
				'									<ns4:StatusAttributeName>Delivery Services Allowed</ns4:StatusAttributeName>' +
				'									<ns4:StatusAttributeValue>false</ns4:StatusAttributeValue>' +
				'									<ns4:StatusModificationDateTime>2019-06-14T06:21:43+10:00</ns4:StatusModificationDateTime>' +
				'								</ns4:Status>' +
				'								<ns4:Status>' +
				'									<ns4:StatusAttributeName>Track Status of Article</ns4:StatusAttributeName>' +
				'									<ns4:StatusAttributeValue>Awaiting collection</ns4:StatusAttributeValue>' +
				'									<ns4:StatusModificationDateTime>2019-06-14T14:19:43+10:00</ns4:StatusModificationDateTime>' +
				'								</ns4:Status>' +
				'								<ns4:DeliveryContacts>' +
				'									<ns7:Customer>' +
				'										<ns8:Individual>' +
				'											<ns8:Name>' +
				'												<ns8:NameUsage>IND</ns8:NameUsage>' +
				'												<ns8:FullName>Arpana Nair</ns8:FullName>' +
				'											</ns8:Name>' +
				'										</ns8:Individual>' +
				'										<ns8:ElectronicContact>' +
				'											<pfx3:Telephone>' +
				'												<pfx3:ServiceLine>MOBILE</pfx3:ServiceLine>' +
				'												<pfx3:TelephoneNumber>0406986484</pfx3:TelephoneNumber>' +
				'												<pfx3:CommunicationType>VOICE ENABLED</pfx3:CommunicationType>' +
				'											</pfx3:Telephone>' +
				'										</ns8:ElectronicContact>' +
				'										<ns8:ElectronicContact>' +
				'											<pfx3:Internet>' +
				'												<pfx3:ContactType>EMAIL</pfx3:ContactType>' +
				'												<pfx3:ContactDetail>arpana_89@hotmail.com</pfx3:ContactDetail>' +
				'											</pfx3:Internet>' +
				'										</ns8:ElectronicContact>' +
				'										<ns8:Address>' +
				'											<ns9:AddressUsage>POSTAL</ns9:AddressUsage>' +
				'											<ns9:AddressDetails>' +
				'												<ns9:AustralianAddress>' +
				'													<ns9:UnstructuredAddress>' +
				'														<ns9:AddressLine>Unit 1 99-115 Flinders St</ns9:AddressLine>' +
				'													</ns9:UnstructuredAddress>' +
				'													<ns9:DeliveryPointIdentifier>62700255</ns9:DeliveryPointIdentifier>' +
				'													<ns9:SuburbOrPlaceOrLocality>SURRY HILLS' +
				'													</ns9:SuburbOrPlaceOrLocality>' +
				'													<ns9:StateOrTerritory>NSW</ns9:StateOrTerritory>' +
				'													<ns9:PostCode>2010</ns9:PostCode>' +
				'													<ns9:Country>' +
				'														<ns9:CountryCode>AU</ns9:CountryCode>' +
				'													</ns9:Country>' +
				'												</ns9:AustralianAddress>' +
				'											</ns9:AddressDetails>' +
				'										</ns8:Address>' +
				'									</ns7:Customer>' +
				'									<ns4:DeliveryContactType>Delivery</ns4:DeliveryContactType>' +
				'								</ns4:DeliveryContacts>' +
				'								<ns4:DeliveryContacts>' +
				'									<ns7:Customer>' +
				'										<ns8:Individual>' +
				'											<ns8:Name>' +
				'												<ns8:NameUsage>IND</ns8:NameUsage>' +
				'												<ns8:FullName>Online Channels</ns8:FullName>' +
				'											</ns8:Name>' +
				'											<ns8:Name>' +
				'												<ns8:NameUsage>ORG</ns8:NameUsage>' +
				'												<ns8:FullName>Online Channels</ns8:FullName>' +
				'											</ns8:Name>' +
				'											<ns8:Name>' +
				'												<ns8:NameUsage>TRADE</ns8:NameUsage>' +
				'												<ns8:FullName>Australia Post</ns8:FullName>' +
				'											</ns8:Name>' +
				'										</ns8:Individual>' +
				'										<ns8:ElectronicContact>' +
				'											<pfx3:Internet>' +
				'												<pfx3:ContactType>EMAIL</pfx3:ContactType>' +
				'												<pfx3:ContactDetail>OnlineShopops@auspost.com.au</pfx3:ContactDetail>' +
				'											</pfx3:Internet>' +
				'										</ns8:ElectronicContact>' +
				'										<ns8:Address>' +
				'											<ns9:AddressUsage>POSTAL</ns9:AddressUsage>' +
				'											<ns9:AddressDetails>' +
				'												<ns9:AustralianAddress>' +
				'													<ns9:UnstructuredAddress>' +
				'														<ns9:AddressLine>Level 14 111 Bourke St</ns9:AddressLine>' +
				'													</ns9:UnstructuredAddress>' +
				'													<ns9:SuburbOrPlaceOrLocality>MELBOURNE</ns9:SuburbOrPlaceOrLocality>' +
				'													<ns9:StateOrTerritory>VIC</ns9:StateOrTerritory>' +
				'													<ns9:PostCode>3000</ns9:PostCode>' +
				'													<ns9:Country>' +
				'														<ns9:CountryCode>AU</ns9:CountryCode>' +
				'													</ns9:Country>' +
				'												</ns9:AustralianAddress>' +
				'											</ns9:AddressDetails>' +
				'										</ns8:Address>' +
				'									</ns7:Customer>' +
				'									<ns4:DeliveryContactType>Sender</ns4:DeliveryContactType>' +
				'								</ns4:DeliveryContacts>' +
				'								<ns4:RecordModificationDateTime>2019-06-15T08:37:59+10:00</ns4:RecordModificationDateTime>' +
				'							</pfx4:Article>' +
				'							<pfx4:CommunicationEvent>' +
				'								<ns5:EventType>CE-TR03</ns5:EventType>' +
				'								<ns5:EventDescription>Track extract requested</ns5:EventDescription>' +
				'								<ns5:EventDateTime>2019-06-15T01:55:39+10:00</ns5:EventDateTime>' +
				'								<ns5:EventMessageTransmissionDateTime>2019-06-15T01:55:39+10:00</ns5:EventMessageTransmissionDateTime>' +
				'								<ns5:DataEntryType>E</ns5:DataEntryType>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_GUID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>5000010316349473PE1031</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>PROCESSED_DATE</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>2019-06-14T15:55:50+00:00</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:EventSource>' +
				'									<pfx3:SenderID>SF</pfx3:SenderID>' +
				'									<pfx3:SenderName>SalesForce</pfx3:SenderName>' +
				'								</ns5:EventSource>' +
				'								<ns5:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns5:TrackingIdentification>' +
				'							</pfx4:CommunicationEvent>' +
				'							<pfx4:CommunicationEvent>' +
				'								<ns5:EventType>CE-EN01</ns5:EventType>' +
				'								<ns5:EventDescription>Subscribed to tracking notifications</ns5:EventDescription>' +
				'								<ns5:EventDateTime>2019-06-07T14:47:07+10:00</ns5:EventDateTime>' +
				'								<ns5:EventMessageTransmissionDateTime>2019-06-07T14:48:17+10:00</ns5:EventMessageTransmissionDateTime>' +
				'								<ns5:DataEntryType>E</ns5:DataEntryType>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_GUID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>5000010226855019PE1031</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>PROCESSED_DATE</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>2019-06-07T04:48:39+00:00</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:EventSource>' +
				'									<pfx3:SenderID>eParcel</pfx3:SenderID>' +
				'									<pfx3:SenderName>eParcel</pfx3:SenderName>' +
				'									<pfx3:UserName>COM0020038694</pfx3:UserName>' +
				'								</ns5:EventSource>' +
				'								<ns5:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns5:TrackingIdentification>' +
				'							</pfx4:CommunicationEvent>' +
				'							<pfx4:MailEvent>' +
				'								<ns5:EventType>ADMIN-ER44</ns5:EventType>' +
				'								<ns5:EventDescription>Enquiry received from Receiver and/or Sender' +
				'								</ns5:EventDescription>' +
				'								<ns5:EventDateTime>2019-06-15T01:55:39+10:00</ns5:EventDateTime>' +
				'								<ns5:EventMessageTransmissionDateTime>2019-06-15T01:55:39+10:00</ns5:EventMessageTransmissionDateTime>' +
				'								<ns5:EventReasonText>General Enquiry Hi, My parcel (tracking number:' +
				'									42N236054201000935101) is curre' +
				'								</ns5:EventReasonText>' +
				'								<ns5:DataEntryType>E</ns5:DataEntryType>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIG_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BULK_DM_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>TM-0042NAP08378208</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>ULD_ASSET_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>ULD100765925</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIGNMENT_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BAG_VISA_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>911275226101400100093988</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF1</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>00598779</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF2</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>APonlineshop</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_GUID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>5000010316349474PE1031</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>PROCESSED_DATE</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>2019-06-14T15:55:50+00:00</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:EventSource>' +
				'									<pfx3:SenderID>SF</pfx3:SenderID>' +
				'									<pfx3:SenderName>SalesForce</pfx3:SenderName>' +
				'								</ns5:EventSource>' +
				'								<ns5:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns5:TrackingIdentification>' +
				'								<ns5:LocationIdentifications>' +
				'									<ns5:LocationCodeSet>WORK_CENTRE</ns5:LocationCodeSet>' +
				'									<ns5:LocationCodeID/>' +
				'								</ns5:LocationIdentifications>' +
				'								<ns5:Comments>General Enquiry Hi, My parcel (tracking number: 42N236054201000935101) is' +
				'									currently at DARLINGHUR' +
				'								</ns5:Comments>' +
				'								<ns5:DeliveryPostcode>2010</ns5:DeliveryPostcode>' +
				'							</pfx4:MailEvent>' +
				'							<pfx4:MailEvent>' +
				'								<ns5:EventType>DD-ER4</ns5:EventType>' +
				'								<ns5:EventDescription>Awaiting collection at DARLINGHURST POST SHOP' +
				'								</ns5:EventDescription>' +
				'								<ns5:EventDateTime>2019-06-14T14:19:43+10:00</ns5:EventDateTime>' +
				'								<ns5:EventMessageTransmissionDateTime>2019-06-14T14:21:27+10:00</ns5:EventMessageTransmissionDateTime>' +
				'								<ns5:DataEntryType>E</ns5:DataEntryType>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIG_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BULK_DM_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>TM-0042NAP08378208</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>ULD_ASSET_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>ULD100765925</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIGNMENT_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BAG_VISA_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>911275226101400100093988</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF1</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>00598779</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF2</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>APonlineshop</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_GUID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>5000010309927947PE1031</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_REASON</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>Held for Collection</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>PROCESSED_DATE</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>2019-06-14T04:21:35+00:00</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:EventSource>' +
				'									<pfx3:SenderID>MOBILESTAR</pfx3:SenderID>' +
				'									<pfx3:SenderName>MOBILESTAR</pfx3:SenderName>' +
				'									<pfx3:DeviceID>832688ea04c4f86e</pfx3:DeviceID>' +
				'									<pfx3:UserName>231765_3</pfx3:UserName>' +
				'									<pfx3:UserRole>FAC</pfx3:UserRole>' +
				'								</ns5:EventSource>' +
				'								<ns5:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns5:TrackingIdentification>' +
				'								<ns5:LocationIdentifications>' +
				'									<ns5:LocationCodeSet>WORK_CENTRE</ns5:LocationCodeSet>' +
				'									<ns5:LocationCodeID>231765</ns5:LocationCodeID>' +
				'									<ns5:LocationCodeName>DARLINGHURST POST SHOP</ns5:LocationCodeName>' +
				'									<ns5:Address>' +
				'										<ns9:UnstructuredAddress>' +
				'											<ns9:AddressLine/>' +
				'											<ns9:AddressLine>SUITE 1 GROUND FLOOR 1-19 OXFORD STREET</ns9:AddressLine>' +
				'											<ns9:AddressLine>DARLINGHURST NSW</ns9:AddressLine>' +
				'										</ns9:UnstructuredAddress>' +
				'										<ns9:StateOrTerritoryOrProvince>NSW</ns9:StateOrTerritoryOrProvince>' +
				'										<ns9:PostCode>2010</ns9:PostCode>' +
				'									</ns5:Address>' +
				'								</ns5:LocationIdentifications>' +
				'								<ns5:DeliveryPostcode>2010</ns5:DeliveryPostcode>' +
				'							</pfx4:MailEvent>' +
				'							<pfx4:MailEvent>' +
				'								<ns5:EventType>DD-ER4</ns5:EventType>' +
				'								<ns5:EventDescription>Awaiting collection at DARLINGHURST POST SHOP' +
				'								</ns5:EventDescription>' +
				'								<ns5:EventDateTime>2019-06-14T14:18:39+10:00</ns5:EventDateTime>' +
				'								<ns5:EventMessageTransmissionDateTime>2019-06-14T14:19:11+10:00</ns5:EventMessageTransmissionDateTime>' +
				'								<ns5:DataEntryType>A</ns5:DataEntryType>' +
				'								<ns5:SenderEventMessageNumber>b3d4a9ca-89ab-4583-92a3-036da6341078' +
				'								</ns5:SenderEventMessageNumber>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIG_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BULK_DM_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>TM-0042NAP08378208</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>ULD_ASSET_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>ULD100765925</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIGNMENT_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BAG_VISA_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>911275226101400100093988</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF1</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>00598779</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF2</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>APonlineshop</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_GUID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>5000010309944226PE1031</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>PROCESSED_DATE</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>2019-06-14T04:22:18+00:00</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:EventSource>' +
				'									<pfx3:SenderID>BB60</pfx3:SenderID>' +
				'									<pfx3:SenderName>Blackbay</pfx3:SenderName>' +
				'									<pfx3:DeviceID>0050BF7A60E20996940107473DA13800</pfx3:DeviceID>' +
				'									<pfx3:UserRole>FAC</pfx3:UserRole>' +
				'								</ns5:EventSource>' +
				'								<ns5:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns5:TrackingIdentification>' +
				'								<ns5:LocationIdentifications>' +
				'									<ns5:LocationCodeSet>WORK_CENTRE</ns5:LocationCodeSet>' +
				'									<ns5:LocationCodeID>231765</ns5:LocationCodeID>' +
				'									<ns5:LocationCodeName>DARLINGHURST POST SHOP</ns5:LocationCodeName>' +
				'									<ns5:Address>' +
				'										<ns9:UnstructuredAddress>' +
				'											<ns9:AddressLine/>' +
				'											<ns9:AddressLine>SUITE 1 GROUND FLOOR 1-19 OXFORD STREET</ns9:AddressLine>' +
				'											<ns9:AddressLine>DARLINGHURST NSW</ns9:AddressLine>' +
				'										</ns9:UnstructuredAddress>' +
				'										<ns9:StateOrTerritoryOrProvince>NSW</ns9:StateOrTerritoryOrProvince>' +
				'										<ns9:PostCode>2010</ns9:PostCode>' +
				'									</ns5:Address>' +
				'								</ns5:LocationIdentifications>' +
				'								<ns5:DeliveryPostcode>2010</ns5:DeliveryPostcode>' +
				'							</pfx4:MailEvent>' +
				'							<pfx4:MailEvent>' +
				'								<ns5:EventType>TTP-ER37</ns5:EventType>' +
				'								<ns5:EventDescription>Transferred to DARLINGHURST POST SHOP</ns5:EventDescription>' +
				'								<ns5:EventDateTime>2019-06-14T14:18:38+10:00</ns5:EventDateTime>' +
				'								<ns5:EventMessageTransmissionDateTime>2019-06-14T14:19:09+10:00</ns5:EventMessageTransmissionDateTime>' +
				'								<ns5:DataEntryType>A</ns5:DataEntryType>' +
				'								<ns5:SenderEventMessageNumber>aa013524-ad5d-4cd8-bbf7-036da6340ecb' +
				'								</ns5:SenderEventMessageNumber>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIG_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BULK_DM_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>TM-0042NAP08378208</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>ULD_ASSET_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>ULD100765925</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIGNMENT_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BAG_VISA_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>911275226101400100093988</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF1</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>00598779</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF2</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>APonlineshop</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_GUID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>5000010309944181PE1031</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>PROCESSED_DATE</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>2019-06-14T04:22:18+00:00</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:EventSource>' +
				'									<pfx3:SenderID>BB60</pfx3:SenderID>' +
				'									<pfx3:SenderName>Blackbay</pfx3:SenderName>' +
				'									<pfx3:DeviceID>0920001B060073E65B76064901080103</pfx3:DeviceID>' +
				'									<pfx3:UserName>DEGENJ</pfx3:UserName>' +
				'									<pfx3:UserRole>PDO</pfx3:UserRole>' +
				'									<pfx3:Recipient>F TRAN</pfx3:Recipient>' +
				'								</ns5:EventSource>' +
				'								<ns5:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns5:TrackingIdentification>' +
				'								<ns5:LocationIdentifications>' +
				'									<ns5:LocationCodeSet>WORK_CENTRE</ns5:LocationCodeSet>' +
				'									<ns5:LocationCodeID>281391</ns5:LocationCodeID>' +
				'									<ns5:LocationCodeName>ALEXANDRIA DF</ns5:LocationCodeName>' +
				'									<ns5:Address>' +
				'										<ns9:UnstructuredAddress>' +
				'											<ns9:AddressLine/>' +
				'											<ns9:AddressLine>10-12 RALPH STREET</ns9:AddressLine>' +
				'											<ns9:AddressLine>ALEXANDRIA NSW</ns9:AddressLine>' +
				'										</ns9:UnstructuredAddress>' +
				'										<ns9:StateOrTerritoryOrProvince>NSW</ns9:StateOrTerritoryOrProvince>' +
				'										<ns9:PostCode>2015</ns9:PostCode>' +
				'									</ns5:Address>' +
				'								</ns5:LocationIdentifications>' +
				'								<ns5:LocationIdentifications>' +
				'									<ns5:LocationCodeSet>TO_LOCATION</ns5:LocationCodeSet>' +
				'									<ns5:LocationCodeID>231765</ns5:LocationCodeID>' +
				'									<ns5:LocationCodeName>DARLINGHURST POST SHOP</ns5:LocationCodeName>' +
				'								</ns5:LocationIdentifications>' +
				'								<ns5:ProofOfDelivery>' +
				'									<pfx3:SignerName>F TRAN</pfx3:SignerName>' +
				'									<pfx3:Signature>' +
				'										iVBORw0KGgoAAAANSUhEUgAAAPoAAABkAQMAAACVTr9NAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAGUExURQAAAP///6XZn90AAAAJcEhZcwAADsMAAA7DAcdvqGQAAADnSURBVEjH7dQ7DsIwDAbg3oKRI/QG9FhsZGDkAGz0JoSNkQEhMSAiFtgaRIUCysN0bYr8DxlgiOdPlh+yC+JjU2SQQQYZ/A3wCLyTwTMZNAick8E6GcxSQQgAeCEAkABYCBQARgOgTSpQFgEveSADAAICqljQrUoiwGfwCFgCRVryigUGA3tigSazrwAodxxQ1NQtByQdhePBIR5VHwiaR00MQMmCQGEMgBMA3AmACwILBEYAhCkALw1AqwDYIlBLAAYvLAKOAHgMvmQErh6AFQITywP3ZdI9YGnJg1t3OCxQRDygX4EPjq4+sGMco+MAAAAASUVORK5CYII=' +
				'									</pfx3:Signature>' +
				'								</ns5:ProofOfDelivery>' +
				'								<ns5:RoundNumber>9380</ns5:RoundNumber>' +
				'								<ns5:DeliveryPostcode>2010</ns5:DeliveryPostcode>' +
				'							</pfx4:MailEvent>' +
				'							<pfx4:MailEvent>' +
				'								<ns5:EventType>DD-ER11</ns5:EventType>' +
				'								<ns5:EventDescription>Attempted delivery - No one in attendance</ns5:EventDescription>' +
				'								<ns5:EventDateTime>2019-06-14T13:34:19+10:00</ns5:EventDateTime>' +
				'								<ns5:EventMessageTransmissionDateTime>2019-06-14T13:34:27+10:00</ns5:EventMessageTransmissionDateTime>' +
				'								<ns5:DataEntryType>A</ns5:DataEntryType>' +
				'								<ns5:SenderEventMessageNumber>7da63b5d-1c2b-41e1-9a80-036da60b239c' +
				'								</ns5:SenderEventMessageNumber>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIG_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BULK_DM_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>TM-0042NAP08378208</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>ULD_ASSET_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>ULD100765925</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIGNMENT_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BAG_VISA_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>911275226101400100093988</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF1</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>00598779</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF2</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>APonlineshop</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_GUID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>5000010309213339PE1031</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>PROCESSED_DATE</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>2019-06-14T03:34:48+00:00</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:EventSource>' +
				'									<pfx3:SenderID>BB60</pfx3:SenderID>' +
				'									<pfx3:SenderName>Blackbay</pfx3:SenderName>' +
				'									<pfx3:DeviceID>0920001B060073E65B76064901080103</pfx3:DeviceID>' +
				'									<pfx3:UserName>DEGENJ</pfx3:UserName>' +
				'									<pfx3:UserRole>PDO</pfx3:UserRole>' +
				'								</ns5:EventSource>' +
				'								<ns5:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns5:TrackingIdentification>' +
				'								<ns5:LocationIdentifications>' +
				'									<ns5:LocationCodeSet>WORK_CENTRE</ns5:LocationCodeSet>' +
				'									<ns5:LocationCodeID>281391</ns5:LocationCodeID>' +
				'									<ns5:LocationCodeName>ALEXANDRIA DF</ns5:LocationCodeName>' +
				'									<ns5:Address>' +
				'										<ns9:UnstructuredAddress>' +
				'											<ns9:AddressLine/>' +
				'											<ns9:AddressLine/>' +
				'											<ns9:AddressLine>SURRY HILLS NSW</ns9:AddressLine>' +
				'										</ns9:UnstructuredAddress>' +
				'										<ns9:SuburbOrTownOrLocality>Surry Hills</ns9:SuburbOrTownOrLocality>' +
				'										<ns9:StateOrTerritoryOrProvince>NSW</ns9:StateOrTerritoryOrProvince>' +
				'									</ns5:Address>' +
				'								</ns5:LocationIdentifications>' +
				'								<ns5:RoundNumber>9380</ns5:RoundNumber>' +
				'								<ns5:DeliveryPostcode>2010</ns5:DeliveryPostcode>' +
				'							</pfx4:MailEvent>' +
				'							<pfx4:MailEvent>' +
				'								<ns5:EventType>CE-SR09</ns5:EventType>' +
				'								<ns5:EventDescription>Day of delivery notification sent to Receiver' +
				'								</ns5:EventDescription>' +
				'								<ns5:EventDateTime>2019-06-14T06:48:58+10:00</ns5:EventDateTime>' +
				'								<ns5:EventMessageTransmissionDateTime>2019-06-14T06:55:54+10:00</ns5:EventMessageTransmissionDateTime>' +
				'								<ns5:DataEntryType>E</ns5:DataEntryType>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIG_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BULK_DM_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>TM-0042NAP08378208</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>ULD_ASSET_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>ULD100765925</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIGNMENT_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BAG_VISA_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>911275226101400100093988</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF1</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>00598779</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF2</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>APonlineshop</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_GUID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>5000010302134476PE1031</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>PROCESSED_DATE</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>2019-06-13T20:56:03+00:00</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:EventSource>' +
				'									<pfx3:SenderID>EEMID</pfx3:SenderID>' +
				'									<pfx3:SenderName>EEMID</pfx3:SenderName>' +
				'								</ns5:EventSource>' +
				'								<ns5:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns5:TrackingIdentification>' +
				'								<ns5:LocationIdentifications>' +
				'									<ns5:LocationCodeSet>WORK_CENTRE</ns5:LocationCodeSet>' +
				'									<ns5:LocationCodeID/>' +
				'								</ns5:LocationIdentifications>' +
				'								<ns5:DeliveryPostcode>2010</ns5:DeliveryPostcode>' +
				'							</pfx4:MailEvent>' +
				'							<pfx4:MailEvent>' +
				'								<ns5:EventType>ZPT_END_AGGREGATION</ns5:EventType>' +
				'								<ns5:EventDescription>Item removed from container</ns5:EventDescription>' +
				'								<ns5:EventDateTime>2019-06-14T06:45:04+10:00</ns5:EventDateTime>' +
				'								<ns5:EventMessageTransmissionDateTime>2019-06-14T06:45:04+10:00</ns5:EventMessageTransmissionDateTime>' +
				'								<ns5:DataEntryType>E</ns5:DataEntryType>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIG_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BULK_DM_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>TM-0042NAP08378208</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>ULD_ASSET_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>ULD100765925</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIGNMENT_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BAG_VISA_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>911275226101400100093988</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF1</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>00598779</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF2</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>APonlineshop</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_GUID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>5000010301983549PE1031</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>PROCESSED_DATE</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>2019-06-13T20:47:59+00:00</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:EventSource>' +
				'									<pfx3:SenderID>EMRLS</pfx3:SenderID>' +
				'									<pfx3:SenderName>Event Management Rules</pfx3:SenderName>' +
				'								</ns5:EventSource>' +
				'								<ns5:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns5:TrackingIdentification>' +
				'								<ns5:LocationIdentifications>' +
				'									<ns5:LocationCodeSet>WORK_CENTRE</ns5:LocationCodeSet>' +
				'									<ns5:LocationCodeID>281391</ns5:LocationCodeID>' +
				'									<ns5:LocationCodeName>ALEXANDRIA DF</ns5:LocationCodeName>' +
				'									<ns5:Address>' +
				'										<ns9:UnstructuredAddress>' +
				'											<ns9:AddressLine/>' +
				'											<ns9:AddressLine>10-12 RALPH STREET</ns9:AddressLine>' +
				'											<ns9:AddressLine>ALEXANDRIA NSW</ns9:AddressLine>' +
				'										</ns9:UnstructuredAddress>' +
				'										<ns9:StateOrTerritoryOrProvince>NSW</ns9:StateOrTerritoryOrProvince>' +
				'										<ns9:PostCode>2015</ns9:PostCode>' +
				'									</ns5:Address>' +
				'								</ns5:LocationIdentifications>' +
				'								<ns5:DeliveryPostcode>2010</ns5:DeliveryPostcode>' +
				'							</pfx4:MailEvent>' +
				'							<pfx4:MailEvent>' +
				'								<ns5:EventType>AFP-ER15</ns5:EventType>' +
				'								<ns5:EventDescription>Onboard for delivery with PDO</ns5:EventDescription>' +
				'								<ns5:EventDateTime>2019-06-14T06:21:43+10:00</ns5:EventDateTime>' +
				'								<ns5:EventMessageTransmissionDateTime>2019-06-14T06:48:41+10:00</ns5:EventMessageTransmissionDateTime>' +
				'								<ns5:DataEntryType>A</ns5:DataEntryType>' +
				'								<ns5:SenderEventMessageNumber>9e293ebe-49fe-476f-a02f-036da497a195' +
				'								</ns5:SenderEventMessageNumber>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIG_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BULK_DM_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>TM-0042NAP08378208</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>ULD_ASSET_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>ULD100765925</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIGNMENT_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BAG_VISA_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>911275226101400100093988</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF1</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>00598779</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF2</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>APonlineshop</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_GUID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>5000010302002371PE1031</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>PROCESSED_DATE</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>2019-06-13T20:49:10+00:00</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:EventSource>' +
				'									<pfx3:SenderID>BB60</pfx3:SenderID>' +
				'									<pfx3:SenderName>Blackbay</pfx3:SenderName>' +
				'									<pfx3:DeviceID>0920001B060073E65B76064901080103</pfx3:DeviceID>' +
				'									<pfx3:UserName>WEATHERILLS1</pfx3:UserName>' +
				'									<pfx3:UserRole>PDO</pfx3:UserRole>' +
				'								</ns5:EventSource>' +
				'								<ns5:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns5:TrackingIdentification>' +
				'								<ns5:LocationIdentifications>' +
				'									<ns5:LocationCodeSet>WORK_CENTRE</ns5:LocationCodeSet>' +
				'									<ns5:LocationCodeID>281391</ns5:LocationCodeID>' +
				'									<ns5:LocationCodeName>ALEXANDRIA DF</ns5:LocationCodeName>' +
				'									<ns5:Address>' +
				'										<ns9:UnstructuredAddress>' +
				'											<ns9:AddressLine/>' +
				'											<ns9:AddressLine>10-12 RALPH STREET</ns9:AddressLine>' +
				'											<ns9:AddressLine>ALEXANDRIA NSW</ns9:AddressLine>' +
				'										</ns9:UnstructuredAddress>' +
				'										<ns9:StateOrTerritoryOrProvince>NSW</ns9:StateOrTerritoryOrProvince>' +
				'										<ns9:PostCode>2015</ns9:PostCode>' +
				'									</ns5:Address>' +
				'								</ns5:LocationIdentifications>' +
				'								<ns5:RoundNumber>9380</ns5:RoundNumber>' +
				'								<ns5:DeliveryPostcode>2010</ns5:DeliveryPostcode>' +
				'							</pfx4:MailEvent>' +
				'							<pfx4:MailEvent>' +
				'								<ns5:EventType>NSS-ER42</ns5:EventType>' +
				'								<ns5:EventDescription>Processed at sortation facility</ns5:EventDescription>' +
				'								<ns5:EventDateTime>2019-06-13T03:09:28+10:00</ns5:EventDateTime>' +
				'								<ns5:EventMessageTransmissionDateTime>2019-06-13T03:10:25+10:00</ns5:EventMessageTransmissionDateTime>' +
				'								<ns5:DataEntryType>A</ns5:DataEntryType>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIG_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BULK_DM_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>TM-0042NAP08378208</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>ULD_ASSET_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>ULD100765925</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIGNMENT_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BAG_VISA_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>911275226101400100093988</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF1</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>00598779</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF2</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>APonlineshop</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_GUID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>5000010283648206PE1031</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>PROCESSED_DATE</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>2019-06-12T17:10:30+00:00</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:EventSource>' +
				'									<pfx3:SenderID>MPS</pfx3:SenderID>' +
				'									<pfx3:SenderName>MPS</pfx3:SenderName>' +
				'									<pfx3:DeviceID>821_MPS-MS01.IU06R</pfx3:DeviceID>' +
				'								</ns5:EventSource>' +
				'								<ns5:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns5:TrackingIdentification>' +
				'								<ns5:MeasurementData>' +
				'									<pfx3:WeightKG>0.35</pfx3:WeightKG>' +
				'									<pfx3:Authority>LFT_WEIGHT</pfx3:Authority>' +
				'								</ns5:MeasurementData>' +
				'								<ns5:LocationIdentifications>' +
				'									<ns5:LocationCodeSet>WORK_CENTRE</ns5:LocationCodeSet>' +
				'									<ns5:LocationCodeID>283717</ns5:LocationCodeID>' +
				'									<ns5:LocationCodeName>SYDNEY GATEWAY FACILITY</ns5:LocationCodeName>' +
				'									<ns5:Address>' +
				'										<ns9:UnstructuredAddress>' +
				'											<ns9:AddressLine/>' +
				'											<ns9:AddressLine>2A FACTORY STREET</ns9:AddressLine>' +
				'											<ns9:AddressLine>GRANVILLE NSW</ns9:AddressLine>' +
				'										</ns9:UnstructuredAddress>' +
				'										<ns9:StateOrTerritoryOrProvince>NSW</ns9:StateOrTerritoryOrProvince>' +
				'										<ns9:PostCode>2142</ns9:PostCode>' +
				'									</ns5:Address>' +
				'								</ns5:LocationIdentifications>' +
				'								<ns5:DeliveryPostcode>2010</ns5:DeliveryPostcode>' +
				'							</pfx4:MailEvent>' +
				'							<pfx4:MailEvent>' +
				'								<ns5:EventType>ZPT_END_AGGREGATION</ns5:EventType>' +
				'								<ns5:EventDescription>Item removed from container</ns5:EventDescription>' +
				'								<ns5:EventDateTime>2019-06-13T03:05:03+10:00</ns5:EventDateTime>' +
				'								<ns5:EventMessageTransmissionDateTime>2019-06-13T03:05:03+10:00</ns5:EventMessageTransmissionDateTime>' +
				'								<ns5:DataEntryType>E</ns5:DataEntryType>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIG_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BULK_DM_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>TM-0042NAP08378208</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>ULD_ASSET_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>ULD100765925</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIGNMENT_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BAG_VISA_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>911275226101400100093988</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF1</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>00598779</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF2</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>APonlineshop</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_GUID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>5000010283644098PE1031</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>PROCESSED_DATE</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>2019-06-12T17:07:19+00:00</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:EventSource>' +
				'									<pfx3:SenderID>EMRLS</pfx3:SenderID>' +
				'									<pfx3:SenderName>Event Management Rules</pfx3:SenderName>' +
				'								</ns5:EventSource>' +
				'								<ns5:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns5:TrackingIdentification>' +
				'								<ns5:LocationIdentifications>' +
				'									<ns5:LocationCodeSet>WORK_CENTRE</ns5:LocationCodeSet>' +
				'									<ns5:LocationCodeID>283717</ns5:LocationCodeID>' +
				'									<ns5:LocationCodeName>SYDNEY GATEWAY FACILITY</ns5:LocationCodeName>' +
				'									<ns5:Address>' +
				'										<ns9:UnstructuredAddress>' +
				'											<ns9:AddressLine/>' +
				'											<ns9:AddressLine>2A FACTORY STREET</ns9:AddressLine>' +
				'											<ns9:AddressLine>GRANVILLE NSW</ns9:AddressLine>' +
				'										</ns9:UnstructuredAddress>' +
				'										<ns9:StateOrTerritoryOrProvince>NSW</ns9:StateOrTerritoryOrProvince>' +
				'										<ns9:PostCode>2142</ns9:PostCode>' +
				'									</ns5:Address>' +
				'								</ns5:LocationIdentifications>' +
				'								<ns5:DeliveryPostcode>2010</ns5:DeliveryPostcode>' +
				'							</pfx4:MailEvent>' +
				'							<pfx4:MailEvent>' +
				'								<ns5:EventType>NSS-ER42</ns5:EventType>' +
				'								<ns5:EventDescription>Processed at sortation facility</ns5:EventDescription>' +
				'								<ns5:EventDateTime>2019-06-11T18:52:37+10:00</ns5:EventDateTime>' +
				'								<ns5:EventMessageTransmissionDateTime>2019-06-11T19:00:16+10:00</ns5:EventMessageTransmissionDateTime>' +
				'								<ns5:DataEntryType>A</ns5:DataEntryType>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIG_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BULK_DM_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>TM-0042NAP08378208</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>ULD_ASSET_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>ULD100765925</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIGNMENT_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BAG_VISA_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>911275226101400100093988</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF1</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>00598779</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF2</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>APonlineshop</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_GUID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>5000010261286283PE1031</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>PROCESSED_DATE</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>2019-06-11T09:00:26+00:00</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:EventSource>' +
				'									<pfx3:SenderID>LPSM2</pfx3:SenderID>' +
				'									<pfx3:SenderName>LPSM2</pfx3:SenderName>' +
				'									<pfx3:DeviceID>812_LPSM2-30.25.01</pfx3:DeviceID>' +
				'								</ns5:EventSource>' +
				'								<ns5:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns5:TrackingIdentification>' +
				'								<ns5:MeasurementData>' +
				'									<pfx3:WeightKG>0.35</pfx3:WeightKG>' +
				'									<pfx3:Authority>LFT_WEIGHT</pfx3:Authority>' +
				'								</ns5:MeasurementData>' +
				'								<ns5:LocationIdentifications>' +
				'									<ns5:LocationCodeSet>WORK_CENTRE</ns5:LocationCodeSet>' +
				'									<ns5:LocationCodeID>319230</ns5:LocationCodeID>' +
				'									<ns5:LocationCodeName>MELBOURNE PARCEL FACILITY</ns5:LocationCodeName>' +
				'									<ns5:Address>' +
				'										<ns9:UnstructuredAddress>' +
				'											<ns9:AddressLine/>' +
				'											<ns9:AddressLine>133-169 FAIRBAIRN ROAD</ns9:AddressLine>' +
				'											<ns9:AddressLine>SUNSHINE WEST VIC</ns9:AddressLine>' +
				'										</ns9:UnstructuredAddress>' +
				'										<ns9:StateOrTerritoryOrProvince>VIC</ns9:StateOrTerritoryOrProvince>' +
				'										<ns9:PostCode>3020</ns9:PostCode>' +
				'									</ns5:Address>' +
				'								</ns5:LocationIdentifications>' +
				'								<ns5:DeliveryPostcode>2010</ns5:DeliveryPostcode>' +
				'							</pfx4:MailEvent>' +
				'							<pfx4:MailEvent>' +
				'								<ns5:EventType>AFC-ER64</ns5:EventType>' +
				'								<ns5:EventDescription>Lodged by Sender (Inferred scan event)</ns5:EventDescription>' +
				'								<ns5:EventDateTime>2019-06-08T00:40:58+10:00</ns5:EventDateTime>' +
				'								<ns5:EventMessageTransmissionDateTime>2019-06-08T01:57:33+10:00</ns5:EventMessageTransmissionDateTime>' +
				'								<ns5:DataEntryType>E</ns5:DataEntryType>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIG_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BULK_DM_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>TM-0042NAP08378208</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>ULD_ASSET_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>ULD100765925</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIGNMENT_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BAG_VISA_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>911275226101400100093988</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF1</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>00598779</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF2</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>APonlineshop</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_GUID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>5000010232527572PE1031</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>PROCESSED_DATE</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>2019-06-07T15:57:34+00:00</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:EventSource>' +
				'									<pfx3:SenderID>EEMID</pfx3:SenderID>' +
				'									<pfx3:SenderName>EEMID</pfx3:SenderName>' +
				'								</ns5:EventSource>' +
				'								<ns5:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns5:TrackingIdentification>' +
				'								<ns5:LocationIdentifications>' +
				'									<ns5:LocationCodeSet>WORK_CENTRE</ns5:LocationCodeSet>' +
				'									<ns5:LocationCodeID>346896</ns5:LocationCodeID>' +
				'									<ns5:LocationCodeName>MELBOURNE PARCEL FACILITY DWS</ns5:LocationCodeName>' +
				'									<ns5:Address>' +
				'										<ns9:UnstructuredAddress>' +
				'											<ns9:AddressLine/>' +
				'											<ns9:AddressLine>133-169 FAIRBAIRN ROAD</ns9:AddressLine>' +
				'											<ns9:AddressLine>SUNSHINE WEST VIC</ns9:AddressLine>' +
				'										</ns9:UnstructuredAddress>' +
				'										<ns9:StateOrTerritoryOrProvince>VIC</ns9:StateOrTerritoryOrProvince>' +
				'										<ns9:PostCode>3020</ns9:PostCode>' +
				'									</ns5:Address>' +
				'								</ns5:LocationIdentifications>' +
				'								<ns5:DeliveryPostcode>2010</ns5:DeliveryPostcode>' +
				'							</pfx4:MailEvent>' +
				'							<pfx4:MailEvent>' +
				'								<ns5:EventType>ADMIN-ER40</ns5:EventType>' +
				'								<ns5:EventDescription>Manifest accepted by Australia Post</ns5:EventDescription>' +
				'								<ns5:EventDateTime>2019-06-07T15:17:18+10:00</ns5:EventDateTime>' +
				'								<ns5:EventMessageTransmissionDateTime>2019-06-07T19:55:11+10:00</ns5:EventMessageTransmissionDateTime>' +
				'								<ns5:DataEntryType>E</ns5:DataEntryType>' +
				'								<ns5:SenderEventMessageNumber>PCMS-1559901311362-9</ns5:SenderEventMessageNumber>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIG_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BULK_DM_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>TM-0042NAP08378208</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>ULD_ASSET_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>ULD100765925</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIGNMENT_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BAG_VISA_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>911275226101400100093988</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF1</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>00598779</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF2</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>APonlineshop</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_GUID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>5000010230889781PE1031</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>PROCESSED_DATE</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>2019-06-07T09:55:24+00:00</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:EventSource>' +
				'									<pfx3:SenderID>eParcel</pfx3:SenderID>' +
				'									<pfx3:SenderName>eParcel</pfx3:SenderName>' +
				'									<pfx3:UserName>COM0020038694</pfx3:UserName>' +
				'								</ns5:EventSource>' +
				'								<ns5:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns5:TrackingIdentification>' +
				'								<ns5:LocationIdentifications>' +
				'									<ns5:LocationCodeSet>WORK_CENTRE</ns5:LocationCodeSet>' +
				'									<ns5:LocationCodeID>346896</ns5:LocationCodeID>' +
				'									<ns5:LocationCodeName>MELBOURNE PARCEL FACILITY DWS</ns5:LocationCodeName>' +
				'									<ns5:Address>' +
				'										<ns9:UnstructuredAddress>' +
				'											<ns9:AddressLine/>' +
				'											<ns9:AddressLine>133-169 FAIRBAIRN ROAD</ns9:AddressLine>' +
				'											<ns9:AddressLine>SUNSHINE WEST VIC</ns9:AddressLine>' +
				'										</ns9:UnstructuredAddress>' +
				'										<ns9:StateOrTerritoryOrProvince>VIC</ns9:StateOrTerritoryOrProvince>' +
				'										<ns9:PostCode>3020</ns9:PostCode>' +
				'									</ns5:Address>' +
				'								</ns5:LocationIdentifications>' +
				'								<ns5:DeliveryPostcode>2010</ns5:DeliveryPostcode>' +
				'							</pfx4:MailEvent>' +
				'							<pfx4:MailEvent>' +
				'								<ns5:EventType>ADMIN-ER39</ns5:EventType>' +
				'								<ns5:EventDescription>Manifest received from Sender</ns5:EventDescription>' +
				'								<ns5:EventDateTime>2019-06-07T14:47:07+10:00</ns5:EventDateTime>' +
				'								<ns5:EventMessageTransmissionDateTime>2019-06-07T14:48:17+10:00</ns5:EventMessageTransmissionDateTime>' +
				'								<ns5:DataEntryType>E</ns5:DataEntryType>' +
				'								<ns5:SenderEventMessageNumber>PCMS-1559882896907-9</ns5:SenderEventMessageNumber>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIG_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BULK_DM_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>TM-0042NAP08378208</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>ULD_ASSET_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>ULD100765925</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CONSIGNMENT_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>42N2360542</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>BAG_VISA_ID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>911275226101400100093988</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF1</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>00598779</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>CUST_REF2</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>APonlineshop</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>EVENT_GUID</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>5000010226855018PE1031</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:FurtherReference>' +
				'									<ns5:ReferenceCodeSet>PROCESSED_DATE</ns5:ReferenceCodeSet>' +
				'									<ns5:ReferenceID>2019-06-07T04:48:39+00:00</ns5:ReferenceID>' +
				'								</ns5:FurtherReference>' +
				'								<ns5:EventSource>' +
				'									<pfx3:SenderID>eParcel</pfx3:SenderID>' +
				'									<pfx3:SenderName>eParcel</pfx3:SenderName>' +
				'									<pfx3:UserName>COM0020038694</pfx3:UserName>' +
				'								</ns5:EventSource>' +
				'								<ns5:TrackingIdentification>' +
				'									<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
				'									<pfx3:TrackingID>42N236054201000935101</pfx3:TrackingID>' +
				'								</ns5:TrackingIdentification>' +
				'								<ns5:LocationIdentifications>' +
				'									<ns5:LocationCodeSet>WORK_CENTRE</ns5:LocationCodeSet>' +
				'									<ns5:LocationCodeID>346896</ns5:LocationCodeID>' +
				'									<ns5:LocationCodeName>MELBOURNE PARCEL FACILITY DWS</ns5:LocationCodeName>' +
				'									<ns5:Address>' +
				'										<ns9:UnstructuredAddress>' +
				'											<ns9:AddressLine/>' +
				'											<ns9:AddressLine>133-169 FAIRBAIRN ROAD</ns9:AddressLine>' +
				'											<ns9:AddressLine>SUNSHINE WEST VIC</ns9:AddressLine>' +
				'										</ns9:UnstructuredAddress>' +
				'										<ns9:StateOrTerritoryOrProvince>VIC</ns9:StateOrTerritoryOrProvince>' +
				'										<ns9:PostCode>3020</ns9:PostCode>' +
				'									</ns5:Address>' +
				'								</ns5:LocationIdentifications>' +
				'								<ns5:DeliveryPostcode>2010</ns5:DeliveryPostcode>' +
				'							</pfx4:MailEvent>' +
				'						</pfx4:ArticleEnvelope>' +
				'					</pfx4:ArticleDetails>' +
				'					<pfx4:ReturnCode>ESB-BUS-DATA-100</pfx4:ReturnCode>' +
				'					<pfx4:ResultDescription>Success</pfx4:ResultDescription>' +
				'				</pfx4:TrackingResult>' +
				'			</ns0:TrackingResults>' +
				'		</ns0:QueryTrackEventsResponse>' +
				'	</SOAP-ENV:Body>' +
				'</SOAP-ENV:Envelope>';
    }


    
    public static String getResponse_singleConsign_NoMLID() {
        return '<?xml version="1.0" encoding="UTF-8"?>' +
                '<pfx2:Envelope xmlns:pfx="http://www.auspost.com.au/schemas/ESBFramework:v1" xmlns:pfx2="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.tibco.com/pe/EngineTypes" xmlns:pfx3="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:ns2="http://www.auspost.com.au/Schema/TransportandLogisticsServices/EventManagement/queryTrackEvents:v1" xmlns:tib="http://www.tibco.com/bw/xslt/custom-functions" xmlns:ns1="http://www.tibco.com/pe/DeployedVarsType" xmlns:ns4="http://www.auspost.com.au/Schema/CommonDataModel/Event:v2" xmlns:ns3="http://www.auspost.com.au/Schema/CommonDataModel/Mail_Product:v2" xmlns:ns6="http://www.auspost.com.au/Schema/CommonDataModel/InvolvedParty/Customer:v1" xmlns:ns5="http://www.auspost.com.au/Schema/CommonDataModel/Product:v1" xmlns:ns8="http://www.auspost.com.au/Schema/CommonDataModel/Location:v1" xmlns:ns7="http://www.auspost.com.au/Schema/CommonDataModel/InvolvedParty:v1" xmlns:pd="http://xmlns.tibco.com/bw/process/2003" xmlns:BW="java://com.tibco.pe.core.JavaCustomXPATHFunctions" xmlns:ns12="http://www.tibco.com/pe/GenerateErrorActivity/InputSchema">' +
                    '<pfx2:Header>' +
                        '<pfx3:InterfaceHeader>' +
                            '<pfx3:InterfaceName>queryArticle</pfx3:InterfaceName>' +
                            '<pfx3:InterfaceVersion>1.0</pfx3:InterfaceVersion>' +
                            '<pfx3:MessageType>Reply</pfx3:MessageType>' +
                            '<pfx3:BusinessReferenceID>JDQ0184460</pfx3:BusinessReferenceID>' +
                            '<pfx3:SourceSystemID>SFDC</pfx3:SourceSystemID>' +
                            '<pfx3:SourceInformation/>' +
                            '<pfx3:Timestamp>2017-03-29T10:34:01.173+11:00</pfx3:Timestamp>' +
                        '</pfx3:InterfaceHeader>' +
                    '</pfx2:Header>' +
                    '<pfx2:Body>' +
                        '<ns2:QueryTrackEventsResponse>' +
                            '<ns2:TrackingResults>' +
                                '<ns2:TrackingResult>' +
                                    '<ns2:TrackingID>JDQ0184460</ns2:TrackingID>' +
                                    '<ns2:ReturnCode>ESB-BUS-DATA-100</ns2:ReturnCode>' +
                                    '<ns2:ResultDescription>Success</ns2:ResultDescription>' +
                                    '<ns2:ConsignmentDetails>' +
                                        '<ns2:ConsignmentEnvelope>' +
                                            '<ns2:Consignment>' +
                                                '<ns3:ActionCode>U</ns3:ActionCode>' +
                                                '<ns3:ConsignmentId>JDQ0184460</ns3:ConsignmentId>' +
                                                '<ns3:MerchantId>20355936</ns3:MerchantId>' +
                                                '<ns3:ExpectedDeliveryDateTime>2017-02-01T10:34:02+11:00</ns3:ExpectedDeliveryDateTime>' +
                                                '<ns3:DeliveryContacts>' +
                                                    '<ns6:Customer>' +
                                                        '<ns7:Individual/>' +
                                                        '<ns7:ElectronicContact>' +
                                                            '<pfx3:Internet>' +
                                                                '<pfx3:ContactType>EMAIL</pfx3:ContactType>' +
                                                                '<pfx3:ContactDetail>k@aus.com</pfx3:ContactDetail>' +
                                                            '</pfx3:Internet>' +
                                                        '</ns7:ElectronicContact>' +
                                                        '<ns7:Address>' +
                                                            '<ns8:AddressUsage>POSTAL</ns8:AddressUsage>' +
                                                            '<ns8:AddressDetails>' +
                                                                '<ns8:AustralianAddress>' +
                                                                    '<ns8:PostCode>3000</ns8:PostCode>' +
                                                                    '<ns8:Country>' +
                                                                        '<ns8:CountryCode>AU</ns8:CountryCode>' +
                                                                    '</ns8:Country>' +
                                                                '</ns8:AustralianAddress>' +
                                                            '</ns8:AddressDetails>' +
                                                        '</ns7:Address>' +
                                                    '</ns6:Customer>' +
                                                    '<ns3:DeliveryContactType>Delivery</ns3:DeliveryContactType>' +
                                                '</ns3:DeliveryContacts>' +
                                                '<ns3:DeliveryContacts>' +
                                                    '<ns6:Customer>' +
                                                        '<ns7:Individual>' +
                                                            '<ns7:Name>' +
                                                                '<ns7:NameUsage>IND</ns7:NameUsage>' +
                                                                '<ns7:FullName>Winning Group Test Account</ns7:FullName>' +
                                                            '</ns7:Name>' +
                                                            '<ns7:Name>' +
                                                                '<ns7:NameUsage>ORG</ns7:NameUsage>' +
                                                                '<ns7:FullName>Winning Group Test Account</ns7:FullName>' +
                                                            '</ns7:Name>' +
                                                        '</ns7:Individual>' +
                                                        '<ns7:Address>' +
                                                           '<ns8:AddressUsage>POSTAL</ns8:AddressUsage>' +
                                                            '<ns8:AddressDetails>' +
                                                                '<ns8:AustralianAddress>' +
                                                                    '<ns8:UnstructuredAddress>' +
                                                                        '<ns8:AddressLine>GPO Box 1777</ns8:AddressLine>' +
                                                                    '</ns8:UnstructuredAddress>' +
                                                                    '<ns8:SuburbOrPlaceOrLocality>MELBOURNE</ns8:SuburbOrPlaceOrLocality>' +
                                                                    '<ns8:StateOrTerritory>VIC</ns8:StateOrTerritory>' +
                                                                    '<ns8:PostCode>3001</ns8:PostCode>' +
                                                                    '<ns8:Country>' +
                                                                        '<ns8:CountryCode>AU</ns8:CountryCode>' +
                                                                    '</ns8:Country>' +
                                                                '</ns8:AustralianAddress>' +
                                                            '</ns8:AddressDetails>' +
                                                        '</ns7:Address>' +
                                                    '</ns6:Customer>' +
                                                    '<ns3:DeliveryContactType>Sender</ns3:DeliveryContactType>' +
                                                '</ns3:DeliveryContacts>' +
                                                '<ns3:TotalActualWeight>4</ns3:TotalActualWeight>' +
                                                '<ns3:Insurance>' +
                                                    '<ns3:InsuranceAmount>50</ns3:InsuranceAmount>' +
                                                '</ns3:Insurance>' +
                                                '<ns3:SignatureRequired>true</ns3:SignatureRequired>' +
                                                '<ns3:DangerousGoodsIndicator>false</ns3:DangerousGoodsIndicator>' +
                                                '<ns3:RecordModificationDateTime>2017-03-29T10:34:02+11:00</ns3:RecordModificationDateTime>' +
                                            '</ns2:Consignment>' +
                                            '<ns2:ArticleEnvelope>' +
                                                '<ns2:Article>' +
                                                    '<ns3:TrackingIdentification>' +
                                                        '<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
                                                        '<pfx3:TrackingID>JDQ018446001000930209</pfx3:TrackingID>' +
                                                    '</ns3:TrackingIdentification>' +
                                                    '<ns3:FurtherReferences>' +
                                                        '<pfx3:ReferenceCodeSet>EXPECTED_DEL_DATE</pfx3:ReferenceCodeSet>' +
                                                        '<pfx3:ReferenceID>20170201</pfx3:ReferenceID>' +
                                                    '</ns3:FurtherReferences>' +
                                                    '<ns3:FurtherReferences>' +
                                                        '<pfx3:ReferenceCodeSet>CONSIGNMENT_ID</pfx3:ReferenceCodeSet>' +
                                                        '<pfx3:ReferenceID>JDQ0184460</pfx3:ReferenceID>' +
                                                    '</ns3:FurtherReferences>' +
                                                    '<ns3:FurtherReferences>' +
                                                        '<pfx3:ReferenceCodeSet>MANIFEST_ID</pfx3:ReferenceCodeSet>' +
                                                        '<pfx3:ReferenceID>P5180</pfx3:ReferenceID>' +
                                                    '</ns3:FurtherReferences>' +
                                                    '<ns3:FurtherReferences>' +
                                                        '<pfx3:ReferenceCodeSet>ARTICLE_GUID</pfx3:ReferenceCodeSet>' +
                                                        '<pfx3:ReferenceID>1000000003726519TE0031</pfx3:ReferenceID>' +
                                                    '</ns3:FurtherReferences>' +
                                                    '<ns3:ActionCode>U</ns3:ActionCode>' +
                                                    '<ns3:ArticleId>JDQ018446001000930209</ns3:ArticleId>' +
                                                    '<ns3:ProductID>146</ns3:ProductID>' +
                                                    '<ns3:ProductName>Parcel Post</ns3:ProductName>' +
                                                    '<ns3:SubProductID>93</ns3:SubProductID>' +
                                                    '<ns3:SubProductName>Parcel Post</ns3:SubProductName>' +
                                                    '<ns3:BaseServiceCode>02</ns3:BaseServiceCode>' +
                                                    '<ns3:MeasurementData>' +
                                                        '<pfx3:HeightCM>1</pfx3:HeightCM>' +
                                                        '<pfx3:WidthCM>1</pfx3:WidthCM>' +
                                                        '<pfx3:LengthCM>1</pfx3:LengthCM>' +
                                                        '<pfx3:WeightKG>4</pfx3:WeightKG>' +
                                                    '</ns3:MeasurementData>' +
                                                    '<ns3:FullBarcode>019931265099999891JDQ018446001000930209|4208000|8008170130152452</ns3:FullBarcode>' +
                                                    '<ns3:EventNotification>01</ns3:EventNotification>' +
                                                    '<ns3:TransitCoverRequired>true</ns3:TransitCoverRequired>' +
                                                    '<ns3:Status>' +
                                                        '<ns3:StatusAttributeName>Destination_Country</ns3:StatusAttributeName>' +
                                                        '<ns3:StatusAttributeValue>Australia</ns3:StatusAttributeValue>' +
                                                    '</ns3:Status>' +
                                                    '<ns3:Status>' +
                                                        '<ns3:StatusAttributeName>Delivery Status of Article</ns3:StatusAttributeName>' +
                                                        '<ns3:StatusAttributeValue>Delivered</ns3:StatusAttributeValue>' +
                                                        '<ns3:StatusModificationDateTime>2017-03-06T14:50:53+11:00</ns3:StatusModificationDateTime>' +
                                                    '</ns3:Status>' +
                                                    '<ns3:Status>' +
                                                        '<ns3:StatusAttributeName>Physical Condition of Article</ns3:StatusAttributeName>' +
                                                        '<ns3:StatusAttributeValue>OK</ns3:StatusAttributeValue>' +
                                                        '<ns3:StatusModificationDateTime>2017-03-29T10:34:02Z</ns3:StatusModificationDateTime>' +
                                                    '</ns3:Status>' +
                                                    '<ns3:Status>' +
                                                        '<ns3:StatusAttributeName>Delivery Services Allowed</ns3:StatusAttributeName>' +
                                                        '<ns3:StatusAttributeValue>false</ns3:StatusAttributeValue>' +
                                                        '<ns3:StatusModificationDateTime>2017-03-06T14:50:53+11:00</ns3:StatusModificationDateTime>' +
                                                    '</ns3:Status>' +
                                                    '<ns3:Status>' +
                                                        '<ns3:StatusAttributeName>Track Status of Article</ns3:StatusAttributeName>' +
                                                        '<ns3:StatusAttributeValue>Delivered</ns3:StatusAttributeValue>' +
                                                        '<ns3:StatusModificationDateTime>2017-03-06T14:50:53+11:00</ns3:StatusModificationDateTime>' +
                                                    '</ns3:Status>' +
                                                    '<ns3:Insurance>' +
                                                        '<ns3:InsuranceRequired>true</ns3:InsuranceRequired>' +
                                                        '<ns3:InsuranceAmount>50</ns3:InsuranceAmount>' +
                                                        '<ns3:InsuranceChargeAmount>0.75</ns3:InsuranceChargeAmount>' +
                                                    '</ns3:Insurance>' +
                                                    '<ns3:RecordModificationDateTime>2017-03-29T10:34:02+11:00</ns3:RecordModificationDateTime>' +
                                                '</ns2:Article>' +
                                                '<ns2:MailEvent>' +
                                                    '<ns4:EventType>AFC-ER31</ns4:EventType>' +
                                                    '<ns4:EventDescription>Lodged by customer</ns4:EventDescription>' +
                                                    '<ns4:EventDateTime>2017-03-21T13:30:56+11:00</ns4:EventDateTime>' +
                                                    '<ns4:EventMessageTransmissionDateTime>2017-03-21T13:31:10+11:00</ns4:EventMessageTransmissionDateTime>' +
                                                    '<ns4:DataEntryType>A</ns4:DataEntryType>' +
                                                    '<ns4:SenderEventMessageNumber>1b96468c-e054-4781-870a-035d40b2536b</ns4:SenderEventMessageNumber>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>CONSIGNMENT_ID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>JDQ0184460</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>BULK_DM_ID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>TM-00JDQP5180</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>EVENT_GUID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>5000000006501197TE0031</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>PROCESSED_DATE</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>2017-03-21T02:31:13+00:00</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:TrackingIdentification>' +
                                                        '<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
                                                        '<pfx3:TrackingID>JDQ018446001000930209</pfx3:TrackingID>' +
                                                    '</ns4:TrackingIdentification>' +
                                                    '<ns4:ArticleEventDetails>' +
                                                        '<ns4:TransitCoverCharge>0.75</ns4:TransitCoverCharge>' +
                                                    '</ns4:ArticleEventDetails>' +
                                                    '<ns4:ConsignmentEventDetails>' +
                                                        '<ns4:DangerousGoodsIndicator>false</ns4:DangerousGoodsIndicator>' +
                                                    '</ns4:ConsignmentEventDetails>' +
                                                    '<ns4:LocationIdentifications>' +
                                                        '<ns4:LocationCodeSet>WORK_CENTRE</ns4:LocationCodeSet>' +
                                                        '<ns4:LocationCodeID>201531</ns4:LocationCodeID>' +
                                                        '<ns4:LocationCodeName>COFFS HARBOUR DC</ns4:LocationCodeName>' +
                                                        '<ns4:Address>' +
                                                            '<ns8:UnstructuredAddress>' +
                                                                '<ns8:AddressLine/>' +
                                                                '<ns8:AddressLine>2 MANSBRIDGE DRIVE</ns8:AddressLine>' +
                                                                '<ns8:AddressLine>NORTH BOAMBEE VALLEY NSW</ns8:AddressLine>' +
                                                            '</ns8:UnstructuredAddress>' +
                                                            '<ns8:StateOrTerritoryOrProvince>NSW</ns8:StateOrTerritoryOrProvince>' +
                                                            '<ns8:PostCode>2450</ns8:PostCode>' +
                                                        '</ns4:Address>' +
                                                    '</ns4:LocationIdentifications>' +
                                                    '<ns4:DeliveryPostcode>8000</ns4:DeliveryPostcode>' +
                                                '</ns2:MailEvent>' +
                                                '<ns2:MailEvent>' +
                                                    '<ns4:EventType>DD-ER9</ns4:EventType>' +
                                                    '<ns4:EventDescription>Attempted delivery</ns4:EventDescription>' +
                                                    '<ns4:EventDateTime>2017-03-07T12:14:33+11:00</ns4:EventDateTime>' +
                                                    '<ns4:EventMessageTransmissionDateTime>2017-03-07T12:14:59+11:00</ns4:EventMessageTransmissionDateTime>' +
                                                    '<ns4:EventReasonText>OPQ</ns4:EventReasonText>' +
                                                    '<ns4:DataEntryType>A</ns4:DataEntryType>' +
                                                    '<ns4:SenderEventMessageNumber>344e37b0-f904-4aa1-b8de-035cf85384ff</ns4:SenderEventMessageNumber>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>CONSIGNMENT_ID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>JDQ0184460</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>BULK_DM_ID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>TM-00JDQP5180</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>EVENT_GUID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>5000000006484526TE0031</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>PROCESSED_DATE</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>2017-03-07T01:15:04+00:00</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:TrackingIdentification>' +
                                                        '<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
                                                        '<pfx3:TrackingID>JDQ018446001000930209</pfx3:TrackingID>' +
                                                    '</ns4:TrackingIdentification>' +
                                                    '<ns4:ArticleEventDetails>' +
                                                        '<ns4:TransitCoverCharge>0.75</ns4:TransitCoverCharge>' +
                                                    '</ns4:ArticleEventDetails>' +
                                                    '<ns4:ConsignmentEventDetails>' +
                                                        '<ns4:DangerousGoodsIndicator>false</ns4:DangerousGoodsIndicator>' +
                                                    '</ns4:ConsignmentEventDetails>' +
                                                    '<ns4:LocationIdentifications>' +
                                                        '<ns4:LocationCodeSet>WORK_CENTRE</ns4:LocationCodeSet>' +
                                                        '<ns4:LocationCodeID>201531</ns4:LocationCodeID>' +
                                                        '<ns4:LocationCodeName>COFFS HARBOUR DC</ns4:LocationCodeName>' +
                                                        '<ns4:Address>' +
                                                            '<ns8:UnstructuredAddress>' +
                                                                '<ns8:AddressLine/>' +
                                                                '<ns8:AddressLine>2 MANSBRIDGE DRIVE</ns8:AddressLine>' +
                                                                '<ns8:AddressLine>NORTH BOAMBEE VALLEY NSW</ns8:AddressLine>' +
                                                            '</ns8:UnstructuredAddress>' +
                                                            '<ns8:StateOrTerritoryOrProvince>NSW</ns8:StateOrTerritoryOrProvince>' +
                                                            '<ns8:PostCode>2450</ns8:PostCode>' +
                                                        '</ns4:Address>' +
                                                    '</ns4:LocationIdentifications>' +
                                                    '<ns4:Comments>OPQ</ns4:Comments>' +
                                                    '<ns4:DeliveryPostcode>8000</ns4:DeliveryPostcode>' +
                                                '</ns2:MailEvent>' +
                                                '<ns2:MailEvent>' +
                                                    '<ns4:EventType>DD-ER11</ns4:EventType>' +
                                                    '<ns4:EventDescription>Attempted delivery - redirected to Post Office</ns4:EventDescription>' +
                                                    '<ns4:EventDateTime>2017-03-06T14:51:52+11:00</ns4:EventDateTime>' +
                                                    '<ns4:EventMessageTransmissionDateTime>2017-03-06T14:51:54+11:00</ns4:EventMessageTransmissionDateTime>' +
                                                    '<ns4:DataEntryType>A</ns4:DataEntryType>' +
                                                    '<ns4:SenderEventMessageNumber>259babf1-47d8-4ec1-b188-035cf3bcd7ff</ns4:SenderEventMessageNumber>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>CONSIGNMENT_ID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>JDQ0184460</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>BULK_DM_ID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>TM-00JDQP5180</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>EVENT_GUID</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>5000000006483533TE0031</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:FurtherReference>' +
                                                        '<ns4:ReferenceCodeSet>PROCESSED_DATE</ns4:ReferenceCodeSet>' +
                                                        '<ns4:ReferenceID>2017-03-06T03:51:59+00:00</ns4:ReferenceID>' +
                                                    '</ns4:FurtherReference>' +
                                                    '<ns4:TrackingIdentification>' +
                                                        '<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
                                                        '<pfx3:TrackingID>JDQ018446001000930209</pfx3:TrackingID>' +
                                                    '</ns4:TrackingIdentification>' +
                                                    '<ns4:ArticleEventDetails>' +
                                                        '<ns4:TransitCoverCharge>0.75</ns4:TransitCoverCharge>' +
                                                    '</ns4:ArticleEventDetails>' +
                                                    '<ns4:ConsignmentEventDetails>' +
                                                        '<ns4:DangerousGoodsIndicator>false</ns4:DangerousGoodsIndicator>' +
                                                    '</ns4:ConsignmentEventDetails>' +
                                                    '<ns4:LocationIdentifications>' +
                                                        '<ns4:LocationCodeSet>WORK_CENTRE</ns4:LocationCodeSet>' +
                                                        '<ns4:LocationCodeID>201531</ns4:LocationCodeID>' +
                                                        '<ns4:LocationCodeName>COFFS HARBOUR DC</ns4:LocationCodeName>' +
                                                        '<ns4:Address>' +
                                                            '<ns8:UnstructuredAddress>' +
                                                                '<ns8:AddressLine/>' +
                                                                '<ns8:AddressLine>2 MANSBRIDGE DRIVE</ns8:AddressLine>' +
                                                                '<ns8:AddressLine>NORTH BOAMBEE VALLEY NSW</ns8:AddressLine>' +
                                                            '</ns8:UnstructuredAddress>' +
                                                            '<ns8:StateOrTerritoryOrProvince>NSW</ns8:StateOrTerritoryOrProvince>' +
                                                            '<ns8:PostCode>2450</ns8:PostCode>' +
                                                        '</ns4:Address>' +
                                                    '</ns4:LocationIdentifications>' +
                                                    '<ns4:DeliveryPostcode>8000</ns4:DeliveryPostcode>' +
                                                '</ns2:MailEvent>' +
                                            '</ns2:ArticleEnvelope>' +
                                        '</ns2:ConsignmentEnvelope>' +
                                    '</ns2:ConsignmentDetails>' +
                                '</ns2:TrackingResult>' +
                            '</ns2:TrackingResults>' +
                        '</ns2:QueryTrackEventsResponse>' +
                    '</pfx2:Body>' +
                '</pfx2:Envelope>';
    }
    
    public static String getResponse_APConsignWithSTProdID() {
        return '<?xml version="1.0" encoding="UTF-8"?>' +
                '<pfx2:Envelope xmlns:pfx="http://www.auspost.com.au/schemas/ESBFramework:v1" xmlns:pfx2="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.tibco.com/pe/EngineTypes" xmlns:pfx3="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:ns2="http://www.auspost.com.au/Schema/TransportandLogisticsServices/EventManagement/queryTrackEvents:v1" xmlns:tib="http://www.tibco.com/bw/xslt/custom-functions" xmlns:ns1="http://www.tibco.com/pe/DeployedVarsType" xmlns:ns4="http://www.auspost.com.au/Schema/CommonDataModel/Event:v2" xmlns:ns3="http://www.auspost.com.au/Schema/CommonDataModel/Mail_Product:v2" xmlns:ns6="http://www.auspost.com.au/Schema/CommonDataModel/InvolvedParty/Customer:v1" xmlns:ns5="http://www.auspost.com.au/Schema/CommonDataModel/Product:v1" xmlns:ns8="http://www.auspost.com.au/Schema/CommonDataModel/Location:v1" xmlns:ns7="http://www.auspost.com.au/Schema/CommonDataModel/InvolvedParty:v1" xmlns:pd="http://xmlns.tibco.com/bw/process/2003" xmlns:BW="java://com.tibco.pe.core.JavaCustomXPATHFunctions" xmlns:ns12="http://www.tibco.com/pe/GenerateErrorActivity/InputSchema">' +
                    '<pfx2:Header>' +
                        '<pfx3:InterfaceHeader>' +
                            '<pfx3:InterfaceName>queryArticle</pfx3:InterfaceName>' +
                            '<pfx3:InterfaceVersion>1.0</pfx3:InterfaceVersion>' +
                            '<pfx3:MessageType>Reply</pfx3:MessageType>' +
                            '<pfx3:BusinessReferenceID>2AT71923</pfx3:BusinessReferenceID>' +
                            '<pfx3:SourceSystemID>SFDC</pfx3:SourceSystemID>' +
                            '<pfx3:SourceInformation/>' +
                            '<pfx3:Timestamp>2017-03-29T10:34:01.173+11:00</pfx3:Timestamp>' +
                        '</pfx3:InterfaceHeader>' +
                    '</pfx2:Header>' +
                    '<pfx2:Body>' +
                        '<ns2:QueryTrackEventsResponse>' +
                            '<ns2:TrackingResults>' +
                                '<ns2:TrackingResult>' +
                                    '<ns2:TrackingID>2AT71923</ns2:TrackingID>' +
                                    '<ns2:ReturnCode>ESB-BUS-DATA-100</ns2:ReturnCode>' +
                                    '<ns2:ResultDescription>Success</ns2:ResultDescription>' +
                                    '<ns2:ConsignmentDetails>' +
                                        '<ns2:ConsignmentEnvelope>' +
                                            '<ns2:Consignment>' +
                                                '<ns3:ActionCode>U</ns3:ActionCode>' +
                                                '<ns3:ConsignmentId>2AT71923</ns3:ConsignmentId>' +
                                                '<ns3:MerchantId>20355936</ns3:MerchantId>' +
                                                '<ns3:MerchantLocationId>JDQ</ns3:MerchantLocationId>' +
                                                '<ns3:ExpectedDeliveryDateTime>2017-02-01T10:34:02+11:00</ns3:ExpectedDeliveryDateTime>' +
                                                '<ns3:DeliveryContacts>' +
                                                    '<ns6:Customer>' +
                                                        '<ns7:Individual/>' +
                                                        '<ns7:ElectronicContact>' +
                                                            '<pfx3:Internet>' +
                                                                '<pfx3:ContactType>EMAIL</pfx3:ContactType>' +
                                                                '<pfx3:ContactDetail>k@aus.com</pfx3:ContactDetail>' +
                                                            '</pfx3:Internet>' +
                                                        '</ns7:ElectronicContact>' +
                                                        '<ns7:Address>' +
                                                            '<ns8:AddressUsage>POSTAL</ns8:AddressUsage>' +
                                                            '<ns8:AddressDetails>' +
                                                                '<ns8:AustralianAddress>' +
                                                                    '<ns8:PostCode>3000</ns8:PostCode>' +
                                                                    '<ns8:Country>' +
                                                                        '<ns8:CountryCode>AU</ns8:CountryCode>' +
                                                                    '</ns8:Country>' +
                                                                '</ns8:AustralianAddress>' +
                                                            '</ns8:AddressDetails>' +
                                                        '</ns7:Address>' +
                                                    '</ns6:Customer>' +
                                                    '<ns3:DeliveryContactType>Delivery</ns3:DeliveryContactType>' +
                                                '</ns3:DeliveryContacts>' +
                                                '<ns3:DeliveryContacts>' +
                                                    '<ns6:Customer>' +
                                                        '<ns7:Individual>' +
                                                            '<ns7:Name>' +
                                                                '<ns7:NameUsage>IND</ns7:NameUsage>' +
                                                                '<ns7:FullName>Winning Group Test Account</ns7:FullName>' +
                                                            '</ns7:Name>' +
                                                            '<ns7:Name>' +
                                                                '<ns7:NameUsage>ORG</ns7:NameUsage>' +
                                                                '<ns7:FullName>Winning Group Test Account</ns7:FullName>' +
                                                            '</ns7:Name>' +
                                                        '</ns7:Individual>' +
                                                        '<ns7:Address>' +
                                                           '<ns8:AddressUsage>POSTAL</ns8:AddressUsage>' +
                                                            '<ns8:AddressDetails>' +
                                                                '<ns8:AustralianAddress>' +
                                                                    '<ns8:UnstructuredAddress>' +
                                                                        '<ns8:AddressLine>GPO Box 1777</ns8:AddressLine>' +
                                                                    '</ns8:UnstructuredAddress>' +
                                                                    '<ns8:SuburbOrPlaceOrLocality>MELBOURNE</ns8:SuburbOrPlaceOrLocality>' +
                                                                    '<ns8:StateOrTerritory>VIC</ns8:StateOrTerritory>' +
                                                                    '<ns8:PostCode>3001</ns8:PostCode>' +
                                                                    '<ns8:Country>' +
                                                                        '<ns8:CountryCode>AU</ns8:CountryCode>' +
                                                                    '</ns8:Country>' +
                                                                '</ns8:AustralianAddress>' +
                                                            '</ns8:AddressDetails>' +
                                                        '</ns7:Address>' +
                                                    '</ns6:Customer>' +
                                                    '<ns3:DeliveryContactType>Sender</ns3:DeliveryContactType>' +
                                                '</ns3:DeliveryContacts>' +
                                                '<ns3:TotalActualWeight>4</ns3:TotalActualWeight>' +
                                                '<ns3:Insurance>' +
                                                    '<ns3:InsuranceAmount>50</ns3:InsuranceAmount>' +
                                                '</ns3:Insurance>' +
                                                '<ns3:SignatureRequired>true</ns3:SignatureRequired>' +
                                                '<ns3:DangerousGoodsIndicator>false</ns3:DangerousGoodsIndicator>' +
                                                '<ns3:RecordModificationDateTime>2017-03-29T10:34:02+11:00</ns3:RecordModificationDateTime>' +
                                            '</ns2:Consignment>' +
                                            '<ns2:ArticleEnvelope>' +
                                                '<ns2:Article>' +
                                                    '<ns3:TrackingIdentification>' +
                                                        '<pfx3:TrackingIDCodeSet>ARTICLE_ID</pfx3:TrackingIDCodeSet>' +
                                                        '<pfx3:TrackingID>2G897466</pfx3:TrackingID>' +
                                                    '</ns3:TrackingIdentification>' +
                                                    '<ns3:FurtherReferences>' +
                                                        '<pfx3:ReferenceCodeSet>EXPECTED_DEL_DATE</pfx3:ReferenceCodeSet>' +
                                                        '<pfx3:ReferenceID>20170201</pfx3:ReferenceID>' +
                                                    '</ns3:FurtherReferences>' +
                                                    '<ns3:FurtherReferences>' +
                                                        '<pfx3:ReferenceCodeSet>CONSIGNMENT_ID</pfx3:ReferenceCodeSet>' +
                                                        '<pfx3:ReferenceID>2AT71923</pfx3:ReferenceID>' +
                                                    '</ns3:FurtherReferences>' +
                                                    '<ns3:FurtherReferences>' +
                                                        '<pfx3:ReferenceCodeSet>MANIFEST_ID</pfx3:ReferenceCodeSet>' +
                                                        '<pfx3:ReferenceID>P5180</pfx3:ReferenceID>' +
                                                    '</ns3:FurtherReferences>' +
                                                    '<ns3:FurtherReferences>' +
                                                        '<pfx3:ReferenceCodeSet>ARTICLE_GUID</pfx3:ReferenceCodeSet>' +
                                                        '<pfx3:ReferenceID>1000000003726519TE0031</pfx3:ReferenceID>' +
                                                    '</ns3:FurtherReferences>' +
                                                    '<ns3:ActionCode>U</ns3:ActionCode>' +
                                                    '<ns3:ArticleId>2G897466</ns3:ArticleId>' +
                                                    '<ns3:ProductID>002</ns3:ProductID>' +
                                                    '<ns3:ProductName>Parcel Post</ns3:ProductName>' +
                                                    '<ns3:SubProductID>93</ns3:SubProductID>' +
                                                    '<ns3:SubProductName>Parcel Post</ns3:SubProductName>' +
                                                    '<ns3:BaseServiceCode>02</ns3:BaseServiceCode>' +
                                                    '<ns3:MerchantLocationId>JDQ</ns3:MerchantLocationId>' +
                                                    '<ns3:MeasurementData>' +
                                                        '<pfx3:HeightCM>1</pfx3:HeightCM>' +
                                                        '<pfx3:WidthCM>1</pfx3:WidthCM>' +
                                                        '<pfx3:LengthCM>1</pfx3:LengthCM>' +
                                                        '<pfx3:WeightKG>4</pfx3:WeightKG>' +
                                                    '</ns3:MeasurementData>' +
                                                    '<ns3:FullBarcode>019931265099999891JDQ018446001000930209|4208000|8008170130152452</ns3:FullBarcode>' +
                                                    '<ns3:EventNotification>01</ns3:EventNotification>' +
                                                    '<ns3:TransitCoverRequired>true</ns3:TransitCoverRequired>' +
                                                    '<ns3:Status>' +
                                                        '<ns3:StatusAttributeName>Destination_Country</ns3:StatusAttributeName>' +
                                                        '<ns3:StatusAttributeValue>Australia</ns3:StatusAttributeValue>' +
                                                    '</ns3:Status>' +
                                                    '<ns3:Status>' +
                                                        '<ns3:StatusAttributeName>Delivery Status of Article</ns3:StatusAttributeName>' +
                                                        '<ns3:StatusAttributeValue>Delivered</ns3:StatusAttributeValue>' +
                                                        '<ns3:StatusModificationDateTime>2017-03-06T14:50:53+11:00</ns3:StatusModificationDateTime>' +
                                                    '</ns3:Status>' +
                                                    '<ns3:Status>' +
                                                        '<ns3:StatusAttributeName>Physical Condition of Article</ns3:StatusAttributeName>' +
                                                        '<ns3:StatusAttributeValue>OK</ns3:StatusAttributeValue>' +
                                                        '<ns3:StatusModificationDateTime>2017-03-29T10:34:02Z</ns3:StatusModificationDateTime>' +
                                                    '</ns3:Status>' +
                                                    '<ns3:Status>' +
                                                        '<ns3:StatusAttributeName>Delivery Services Allowed</ns3:StatusAttributeName>' +
                                                        '<ns3:StatusAttributeValue>false</ns3:StatusAttributeValue>' +
                                                        '<ns3:StatusModificationDateTime>2017-03-06T14:50:53+11:00</ns3:StatusModificationDateTime>' +
                                                    '</ns3:Status>' +
                                                    '<ns3:Status>' +
                                                        '<ns3:StatusAttributeName>Track Status of Article</ns3:StatusAttributeName>' +
                                                        '<ns3:StatusAttributeValue>Delivered</ns3:StatusAttributeValue>' +
                                                        '<ns3:StatusModificationDateTime>2017-03-06T14:50:53+11:00</ns3:StatusModificationDateTime>' +
                                                    '</ns3:Status>' +
                                                    '<ns3:Insurance>' +
                                                        '<ns3:InsuranceRequired>true</ns3:InsuranceRequired>' +
                                                        '<ns3:InsuranceAmount>50</ns3:InsuranceAmount>' +
                                                        '<ns3:InsuranceChargeAmount>0.75</ns3:InsuranceChargeAmount>' +
                                                    '</ns3:Insurance>' +
                                                    '<ns3:RecordModificationDateTime>2017-03-29T10:34:02+11:00</ns3:RecordModificationDateTime>' +
                                                '</ns2:Article>' +
                                            '</ns2:ArticleEnvelope>' +
                                        '</ns2:ConsignmentEnvelope>' +
                                    '</ns2:ConsignmentDetails>' +
                                '</ns2:TrackingResult>' +
                            '</ns2:TrackingResults>' +
                        '</ns2:QueryTrackEventsResponse>' +
                    '</pfx2:Body>' +
                '</pfx2:Envelope>';
    }
}