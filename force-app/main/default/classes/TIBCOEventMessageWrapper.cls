/***
 * @description
 *
 *
 *
 * @changelog
 * 30.01.2014  Mohamed.Atheek@bluewolf.com  Created
 * 22.02.2016  kalpita.talwadekar@auspost.com.au   Updated to add the mapping for EM scan state
 * 17.03.2016  kalpita.talwadekar@auspost.com.au   updated the em scan code to get the local time
 * 07.11.2016  nandan.narasappa@auspost.com.au	 Added new mapping for Driver Contract as part of Carded Home Delivery
 * 15.03.2017  david.e.catindoy@accenture.com	  Added some logic to save Event Description to External Description field
 *												 and set the Show to External flag to true when the it's the BSP User who initiated the AP Consignment Search.
 * 13.04.2017 nathan.franklin@auspost.com.au	   Add additional support to process attachments element to retrieve the Safe Drop GUID and store in EventMessage__c
 * 12.05.2017 scherukuwada@salesfoce.com		   External fields on Event Message will not be set if it is running in Future Call AND as BSP User
 * 14.01.2019 saiswetha.pingali@auspost.com.au	 Capture ULD_ASSET_ID into container_id - REQ1469903
 * 2020-04-18 - Nathan Franklin - Change the logic that sets ShowtoExternals__c
 * 22.05.2020 arjun.singh@auspost.com.au		   Added code to capture sorting details for MyNetwork Community
 * 2021-05-07 - Ranjeewa Silva - Add support to process attachments element to retrieve attachment type and GUID and store in EventMessage__c
 * 2021-07-01 - Disha Kariya - Added mapping for GPS fields in mail event.
 * 2021-09-09	seth.heang@auspost.com.au   Uplift SF API version to 52
 * 2021-09-22   prerna.rahangdale@auspost.com.au EventMessages
 * 2021-09-30 - Nathan Franklin - adding transient attributes capability (for attributes that are not stored within SF but still mapped for UI only use) + modifying logic for safe drop images
 * * 2022-03-07   prerna.rahangdale@auspost.com.au For VODV Articles location doesn't come for Merchant profile , but when internal user searches the article the location details are show in BSP, resetting the
 * 											     values to get the location from SAP everytime with Merchant profile access controls.
**************************************************/

public class TIBCOEventMessageWrapper implements Comparable {
	/**
	 * Transient attributes are used for mappings that are not persisted in Salesforce.
	 * We do this for attributes that are not mapped in the Subscription (S03) interface
	 */
	public EventTransientAttributes transientAttributes = new EventTransientAttributes();

	public EventMessage__c proxyEM {
		get {
			if (proxyEM == null) {
				proxyEM = new EventMessage__c();
			}
			return proxyEM;
		}
		set;
	}

	public TIBCOEventMessageWrapper(EventMessage__c em) {
		if (em != null) {
			// A clone is probably not necessary anymore since we are now using Lightning for all SAP-EM queries (no more visualforce viewstate)
			// That being said, I'll leave it here but we will now preserve the Id of the passed in object (if there was one)
			proxyEM = em.clone(true, true);
		}
	}

	public TIBCOEventMessageWrapper(AuspostEventSchema.CommunicationEvent ce) {
		proxyEM.EventType__c = ce.EventType;
		//17.03.16 - added by kalpita
		//update to get the local time for em scans	 
		//proxyEM.ActualDateTime__c = ce.EventDateTime;
		String[] timeOffset = ce.EventDateTime != null ? String.valueOf(ce.EventDateTime).split('\\+') : new List<String>();
		if (ce.EventDateTime != null) {
			proxyEM.ActualDateTime__c = DateTime.valueOf(timeOffset[0].replaceall('T', ' '));//.addHours(Integer.valueOf(timeOffset[1].replaceall(':','.'))-9) ;
		}

		// When querying a tracking number in BSP, the profile used is the 'MERCHANT' profile which should already filter any event messages that are exposed to 'merchants'
		// Given this, we can set the ShowtoExternals = true to ensure these events are surfaced in BSP given that BSP relies on only showing 'external' events to its users
		//if(UserInfo.getProfileId().left(15).equals(StarTrack_Settings__c.getOrgDefaults().BSP_Community_User_Profile_Id__c) && !(System.isFuture())) {
		if (BspConstants.CURRENT_USER_IS_VIEWING_BSP && !System.isFuture()) {
			proxyEM.ExternalDescription__c = ce.EventDescription;
			proxyEM.ShowtoExternals__c = true;
		}

		if (ce.EventSource != null) {
			proxyEM.DeviceUser__c = ce.EventSource.UserName;
			proxyEM.SenderID__c = ce.EventSource.SenderID;
			proxyEM.SenderName__c = ce.EventSource.SenderName;
			proxyEM.DeviceID__c = ce.EventSource.DeviceID;
			proxyEM.UserName__c = ce.EventSource.UserName;
			proxyEM.UserRole__c = ce.EventSource.UserRole;
		}

		proxyEM.EventDescription__c = ce.EventDescription;
		proxyEM.StatusText__c = ce.EventDescription;
		proxyEM.EventMessageTransmissionDateTime__c = ce.EventMessageTransmissionDateTime;

		if (ce.TrackingIdentification != null && ce.TrackingIdentification.TrackingIDCodeSet == 'ARTICLE_ID') {
			proxyEM.TrackingID__c = ce.TrackingIdentification.TrackingID;
		}

		if (ce.TrackingNotification != null && ce.TrackingNotification.size() > 0) {
			for (AuspostCommonSchema.TrackingNotification tn : ce.TrackingNotification) {
				if (tn.ContactType == 'EMAIL') {
					proxyEM.TrackingContactType__c = tn.ContactType;
					proxyEM.TrackingContactAddress__c = tn.ContactAddress;
					if (tn.NotificationServices != null) {
						String notifications = '';
						for (String s : tn.NotificationServices) {
							notifications += s + ', ';
						}
						notifications = ArticleUtil.removeAtEnd(notifications, ', ');
						proxyEM.TrackingNotificationServices__c = notifications;
					}
					break;
				}
			}
		}

		if (ce.FurtherReference != null) {
			Map<String, String> references = getFurtherReferenceAttributes(ce.FurtherReference);

			// these values are not mapped in the Subscription (S03) interface, therefore we don't store it in Salesforce, we only use them as transaction values
			transientAttributes.eventReason = references.get('EVENT_REASON');
		}

		// process attachments element and store attachment type and guid in EventMessage__c. if the attachment type is
		// one that we monitor for safe drop image, also populate Safe Drop GUID.
		setAttachmentFields(ce.Attachments);
	}

	public TIBCOEventMessageWrapper(AuspostEventSchema.DeviceEvent de) {
		proxyEM.EventType__c = de.EventType;
		//17.03.16 - added by kalpita
		//update to get the local time for em scans	 
		//proxyEM.ActualDateTime__c = de.EventDateTime;
		String[] timeOffset = de.EventDateTime != null ? String.valueOf(de.EventDateTime).split('\\+') : new List<String>();
		if (de.EventDateTime != null) {
			proxyEM.ActualDateTime__c = DateTime.valueOf(timeOffset[0].replaceall('T', ' ')) ;//.addHours(Integer.valueOf(timeOffset[1].replaceall(':','.'))-9): '';
		}

		// When querying a tracking number in BSP, the profile used is the 'MERCHANT' profile which should already filter any event messages that are exposed to 'merchants'
		// Given this, we can set the ShowtoExternals = true to ensure these events are surfaced in BSP given that BSP relies on only showing 'external' events to its users
		//if(UserInfo.getProfileId().left(15).equals(StarTrack_Settings__c.getOrgDefaults().BSP_Community_User_Profile_Id__c) && !(System.isFuture())) {
		if (BspConstants.CURRENT_USER_IS_VIEWING_BSP && !System.isFuture()) {
			proxyEM.ExternalDescription__c = de.EventDescription;
			proxyEM.ShowtoExternals__c = true;
		}

		if (de.EventSource != null) {
			proxyEM.DeviceUser__c = de.EventSource.UserName;
			proxyEM.SenderID__c = de.EventSource.SenderID;
			proxyEM.SenderName__c = de.EventSource.SenderName;
			proxyEM.DeviceID__c = de.EventSource.DeviceID;
			proxyEM.UserName__c = de.EventSource.UserName;
			proxyEM.UserRole__c = de.EventSource.UserRole;
		}

		proxyEM.EventDescription__c = de.EventDescription;
		proxyEM.StatusText__c = de.EventDescription;
		proxyEM.EventMessageTransmissionDateTime__c = de.EventMessageTransmissionDateTime;

		if (de.TrackingIdentification != null && de.TrackingIdentification.TrackingIDCodeSet == 'ARTICLE_ID') {
			proxyEM.TrackingID__c = de.TrackingIdentification.TrackingID;
		}

		if (de.FurtherReference != null) {
			Map<String, String> references = getFurtherReferenceAttributes(de.FurtherReference);

			// these values are not mapped in the Subscription (S03) interface, therefore we don't store it in Salesforce, we only use them as transaction values
			transientAttributes.eventReason = references.get('EVENT_REASON');
		}

		// process attachments element and store attachment type and guid in EventMessage__c. if the attachment type is
		// one that we monitor for safe drop image, also populate Safe Drop GUID.
		setAttachmentFields(de.Attachments);
	}

	public TIBCOEventMessageWrapper(AuspostEventSchema.MailEvent me) {
		proxyEM.EventType__c = me.EventType;

		//17.03.16 - added by kalpita
		//update to get the local time for em scans	 
		//proxyEM.ActualDateTime__c = me.EventDateTime;
		String[] timeOffset = me.EventDateTime != null ? String.valueOf(me.EventDateTime).split('\\+') : new List<String>();
		if (me.EventDateTime != null) {
			proxyEM.ActualDateTime__c = DateTime.valueOf(timeOffset[0].replaceall('T', ' ')) ;//.addHours(Integer.valueOf(timeOffset[1].replaceall(':','.'))-9): '';
		}

		// When querying a tracking number in BSP, the profile used is the 'MERCHANT' profile which should already filter any event messages that are exposed to 'merchants'
		// Given this, we can set the ShowtoExternals = true to ensure these events are surfaced in BSP given that BSP relies on only showing 'external' events to its users
		//if(UserInfo.getProfileId().left(15).equals(StarTrack_Settings__c.getOrgDefaults().BSP_Community_User_Profile_Id__c) && !(System.isFuture())) {
		if (BspConstants.CURRENT_USER_IS_VIEWING_BSP && !System.isFuture()) {
			proxyEM.ExternalDescription__c = me.EventDescription;
			proxyEM.ShowtoExternals__c = true;
		}

		//07/03/2022 START - added to get the latest location details from SAP,In Case of VODV for merchant profile the location is supressed
		// If internal user queries the article the event messages location are retrieved and resetting these below values would bring the location
		// details from SAP as per access rules for portal access profiles.

		proxyEM.ActualLocation__c = null;
		proxyEM.FacilityOrganisationID__c = null;
		proxyEM.PlannedLocation__c = null;
		proxyEM.WorkCentreText__c = null;

		// 07/03/2022 END


		if (me.LocationIdentifications != null) {
			for (AuspostEventSchema.LocationIdentifications li : me.LocationIdentifications) {
				if (li.LocationCodeSet == 'WORK_CENTRE' || li.LocationCodeSet == 'IPS_OFFICE') {
					if (proxyEM.ActualLocation__c == null
							&& proxyEM.FacilityOrganisationID__c == null
							&& proxyEM.PlannedLocation__c == null
							&& proxyEM.WorkCentreText__c == null) {//Reading only the first set of values
						proxyEM.ActualLocation__c = li.LocationCodeName;
						proxyEM.FacilityOrganisationID__c = li.LocationCodeID;
						proxyEM.PlannedLocation__c = li.LocationCodeName;
						proxyEM.WorkCentreText__c = li.LocationCodeName;
					}
				}
				//added by Kalpita - to capture the state of EM scan
				if (li.Address != null && !String.isBlank(li.Address.StateOrTerritoryOrProvince)) {
					proxyEM.State_Territory_Province__c = li.Address.StateOrTerritoryOrProvince;

				}
			}
		}

		if (me.ArticleEventDetails != null) {
			proxyEM.ArticleCount__c = me.ArticleEventDetails.TotalArticlesCount;
		}

		proxyEM.CommentText__c = me.Comments;
		if (me.MeasurementData != null) {
			proxyEM.Height__c = String.valueOf(me.MeasurementData.HeightCM);
			proxyEM.Length__c = String.valueOf(me.MeasurementData.LengthCM);
			proxyEM.Width__c = String.valueOf(me.MeasurementData.WidthCM);
			proxyEM.Weight__c = String.valueOf(me.MeasurementData.WeightKG);
		}

		if (me.EventSource != null) {
			proxyEM.DeviceUser__c = me.EventSource.UserName;
			proxyEM.SenderID__c = me.EventSource.SenderID;
			proxyEM.SenderName__c = me.EventSource.SenderName;
			proxyEM.DeviceID__c = me.EventSource.DeviceID;
			proxyEM.UserName__c = me.EventSource.UserName;
			proxyEM.UserRole__c = me.EventSource.UserRole;
		}

		proxyEM.EventDescription__c = me.EventDescription;

		if (me.LocationIdentifications != null) {
			for (AuspostEventSchema.LocationIdentifications li : me.LocationIdentifications) {
				if (li.LocationCodeSet == 'WORK_CENTRE' && li.Geocode != null) {
					try {
						proxyEM.EventGeoLocation__Latitude__s = li.Geocode.Latitude;
						proxyEM.EventGeoLocation__Longitude__s = li.Geocode.Longitude;
						proxyEM.Geo_Precision__c = li.Geocode.PositionalUncertainty;
						break;
					} catch (Exception e) {
						System.debug('---Error getting EventGeoLocation__c: ' + e);
					}
				}
				//added by kalpita - to capture the state of EM Scan
				if (li.Address != null && !String.isBlank(li.Address.StateOrTerritoryOrProvince)) {
					proxyEM.State_Territory_Province__c = li.Address.StateOrTerritoryOrProvince;

				}
			}
		}

		proxyEM.RoundNo__c = me.RoundNumber;
		proxyEM.DriverContract__c = me.DriverContractID; // Added new mapping for Driver Contract as part of Carded Home Delivery - Nandan : 07/11/2016

		if (me.ProofOfDelivery != null) {
			proxyEM.SignatoryName__c = me.ProofOfDelivery.SignerName;
			proxyEM.SignatureXString__c = me.ProofOfDelivery.Signature;
		}

		proxyEM.StatusText__c = me.EventDescription;
		proxyEM.EventMessageTransmissionDateTime__c = me.EventMessageTransmissionDateTime;
		proxyEM.EstimatedDeliveryTimeSlot__c = me.EstimatedDeliveryTimeSlot;

		if (me.TrackingIdentification != null && me.TrackingIdentification.TrackingIDCodeSet == 'ARTICLE_ID') {
			proxyEM.TrackingID__c = me.TrackingIdentification.TrackingID;
		}

		//REQ1469903 - Capture ULD_ASSET_ID into Container ID column
		/* if (me.FurtherReference != null )
		 {
		  for (AuspostEventSchema.FurtherReferences fr : me.FurtherReference )
			{
			 System.debug(fr.ReferenceCodeSet +' '+fr.ReferenceID);
			 if (fr.ReferenceCodeSet == 'ULD_ASSET_ID')
			 {
			  proxyEM.Container_ID__c = fr.ReferenceID;
			 }
		   }
		 } */

		if (me.FurtherReference != null) {
			Map<String, String> references = getFurtherReferenceAttributes(me.FurtherReference);

			//Set Outside Delivery Radius as Yes if response is TRUE and set it to No if response is FALSE
			proxyEM.Outside_Delivery_Radius__c = ('true'.equalsIgnoreCase(references.get('OUTSIDE_DELIV_RADIUS')) ? 'Yes' : ('false'.equalsIgnoreCase(references.get('OUTSIDE_DELIV_RADIUS')) ? 'No' : ''));

			if (references.get('EVT_TRACKING_CODESET') == 'BAG_VISA_ID' && !String.isEmpty(references.get('EVT_TRACKING_ID'))) {
				proxyEM.Container_ID__c = '(BAG)' + references.get('EVT_TRACKING_ID');
			} else if (references.get('EVT_TRACKING_CODESET') == 'BULK_DM_ID' && !String.isEmpty(references.get('EVT_TRACKING_ID'))) {
				proxyEM.Container_ID__c = '(BDM)' + references.get('EVT_TRACKING_ID');
			} else if (references.get('EVT_TRACKING_CODESET') == 'ULD_ASSET_ID' && !String.isEmpty(references.get('EVT_TRACKING_ID'))) {
				proxyEM.Container_ID__c = '(ULD)' + references.get('EVT_TRACKING_ID');
			}

			proxyEM.SortOutputComp__c = references.get('SORT_OUTPUT_COMP');
			proxyEM.SortOutputReason__c = references.get('SORT_OUTPUT_REASON');
			proxyEM.RoutingResultSource__c = references.get('SORT_SOURCE');
			proxyEM.OCRVCS_DPID__c = (!String.isEmpty(references.get('OCRVCS_DPID')) ? Decimal.valueOf(references.get('OCRVCS_DPID')) : null);
			proxyEM.OCRVCSPostcode__c = (!String.isEmpty(references.get('OCRVCS_POSTCODE')) ? Decimal.valueOf(references.get('OCRVCS_POSTCODE')) : null);
			proxyEM.OCRVCS_OS_Zone__c = (!String.isEmpty(references.get('OCRVCS_OS_ZONE')) ? Decimal.valueOf(references.get('OCRVCS_OS_ZONE')) : null);
			proxyEM.OCRVCSResultSource__c = references.get('OCRVCS_RESULT_SOURCE');
			proxyEM.DefaultHeight__c = (!String.isEmpty(references.get('DEFAULT_HEIGHT')) ? Decimal.valueOf(references.get('DEFAULT_HEIGHT')) : null);
			proxyEM.DefaultLength__c = (!String.isEmpty(references.get('DEFAULT_LENGTH')) ? Decimal.valueOf(references.get('DEFAULT_LENGTH')) : null);
			proxyEM.DefaultWidth__c = (!String.isEmpty(references.get('DEFAULT_WIDTH')) ? Decimal.valueOf(references.get('DEFAULT_WIDTH')) : null);
			proxyEM.DefaultWeight__c = (!String.isEmpty(references.get('DEFAULT_WEIGHT')) ? Decimal.valueOf(references.get('DEFAULT_WEIGHT')) : null);
			proxyEM.VISALabelLine1__c = references.get('CONT_LINE1_TEXT');
			proxyEM.VISALabelLine2__c = references.get('CONT_LINE2_TEXT');
			proxyEM.SortDest__c = references.get('SORT_DESTINATION');
			proxyEM.SortOutputStatus__c = references.get('SORT_OUTPUT_STATUS');
			proxyEM.SortInductMode__c = references.get('SORT_INDUCT_MODE');
			proxyEM.DeliveryNetworkState__c = references.get('CONT_DEST_LOC_REGION');
			proxyEM.DeliveryNetworkPostcode__c = (!String.isEmpty(references.get('CONT_DEST_LOC_POSTCODE')) ? Decimal.valueOf(references.get('CONT_DEST_LOC_POSTCODE')) : null);
			proxyEM.PhysicalContainerID__c = references.get('LOAD_PHYSICAL_CONT');
			proxyEM.TruckId__c = references.get('TRUCK_ID');
			proxyEM.FacilitySubLocationId__c = references.get('FAC_SUBLOCATION_ID');
			proxyEM.FacilitySubLocationName__c = references.get('FAC_SUBLOCATION_NAME');

			// these values are not mapped in the Subscription (S03) interface, therefore we don't store it in Salesforce, we only use them as transaction values
			transientAttributes.eventReason = references.get('EVENT_REASON');

		}

		// process attachments element and store attachment type and guid in EventMessage__c. if the attachment type is
		// one that we monitor for safe drop image, also populate Safe Drop GUID.
		setAttachmentFields(me.Attachments);
	}

	public Integer compareTo(Object compareTo) {
		TIBCOEventMessageWrapper ct = (TIBCOEventMessageWrapper) compareTo;

		if (proxyEM.ActualDateTime__c == ct.proxyEM.ActualDateTime__c) {
			return 0;
		} else if (proxyEM.ActualDateTime__c == null) {
			return 1;//null last
		} else if (ct.proxyEM.ActualDateTime__c == null) {
			return -1;//null last
		} else if (proxyEM.ActualDateTime__c > ct.proxyEM.ActualDateTime__c) {
			return 1;//asc
		}
		return -1;
	}

	/**
	 * Process attachments element and retrieve attachment type and guid and store in EventMessage__c.
	 * If attachment type is a one that we monitor for Safe Drop attachments,  also populate Safe_Drop_GUID__c with the GUID.
	 *
	 * @param attachmentsElement attachments element returned by TIBCO for the event message
	 */
	public void setAttachmentFields(AuspostEventSchema.Attachments_element attachmentsElement) {

		System.debug('ATTACHMENTS: ');
		System.debug(attachmentsElement);

		Set<String> safeDropTypes = SafeDropUtility.getSafeDropAttachmentTypes();
		Set<String> safeDropEventTypes = SafeDropUtility.getSafeDropEvents();

		if (attachmentsElement != null && attachmentsElement.Attachment != null && attachmentsElement.Attachment.size() > 0) {

			// TIBCO returns only one attachment per event message.
			for (AuspostCommonSchema.AttachmentType att : attachmentsElement.Attachment) {

				if (String.isNotBlank(att.AttachmentType) && String.isNotBlank(att.URL)) {
					// this is for backwards compatibility for Safe Drop feature
					if(safeDropTypes.contains(att.AttachmentType) && safeDropEventTypes.contains(proxyEM.EventType__c) && String.isBlank(proxyEM.Safe_Drop_GUID__c)) {
						proxyEM.Safe_Drop_GUID__c = att.URL;
					}

					if (String.isBlank(proxyEM.AttachmentGUID__c)) {
						// event message attachment
						proxyEM.AttachmentType__c = att.AttachmentType;
						proxyEM.AttachmentGUID__c = att.URL;
					}

				}
			}
		}
	}

	/**
	 * Map all the further references to get easy access to the values
	 */
	private Map<String, String> getFurtherReferenceAttributes(List<AuspostEventSchema.FurtherReferences> furtherReferences) {
		Map<String, String> output = new Map<String, String>();

		if(furtherReferences == null) {
			return output;
		}

		for (AuspostEventSchema.FurtherReferences furtherReference : furtherReferences) {
			output.put(furtherReference.ReferenceCodeSet, furtherReference.ReferenceID);
		}
		return output;
	}

	/**
	 * Stores a list of all the attributes we are storing in SF but will still be surfaced in the UI
	 */
	public class EventTransientAttributes {
		@AuraEnabled public String eventReason;
	}
}