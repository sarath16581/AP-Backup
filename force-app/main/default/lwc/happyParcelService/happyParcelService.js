/**
 * @description Service class or utility functions and server communication
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 * 2020-09-09 - Ranjeewa Silva - Export last mile milestone removal help text as a constant.
 * 2020-09-18 - Disha kariya - Added method to get network details on event message
 * 2020-09-27 - Nathan Franklin - Changed Safe Drop eligibility functions and added pubsub methods
 * 2020-10-12 - Ranjeewa Silva - Export case fields required for DTN case creation as constants.
 * 2020-11-06 - Ranjeewa Silva - Export more case fields required for DTN case creation as constants.
 * 2021-05-18 - Disha Kariya - Changes for notification preferences
 * 2021-10-26 - Nathan Franklin - add safeToUpper
 * 2021-06-15 - Prerna Rahangdale - Added the warning to show for the VODV Articles.
 * 2022-04-12 - Mahesh Parvathaneni - Added custom lables and location icon SVG path to use in the lightning map marker
 * 2022-07-05 - Snigdha Sahu - REQ2851358 - Added MLID for SenderDetails
 * 2024-05-21 - Seth Heang - Updated getTrackingApiResponse with forceConsignmentSearch parameter
 * 2024-06-03 - Raghav Ravipati - Added method to get critical incident knowledge articles
 * 2024-06-13 - Seth Heang - Added getCurrentStateOfSafeDropImageRequiredForDownload and getSafeDropImageForPOD
 * 2024-06-14 - Seth Heang - Moved in download Proof of delivery method from HappyParcelDeliveryProof
 */

//continuations
import queryAnalyticsApi from '@salesforce/apexContinuation/HappyParcelController.queryAnalyticsApi';
import getArticleImage from '@salesforce/apexContinuation/HappyParcelController.getArticleImage';
import queryTrackingApiForStarTrack from '@salesforce/apexContinuation/HappyParcelController.queryTrackingApiForStarTrack';
import getSafeDropImageForPOD from '@salesforce/apexContinuation/MyCustomerDeliveryProofPdfController.getSafeDropImage';

// normal callouts
import queryTrackingApi from '@salesforce/apex/HappyParcelController.queryTrackingApi';
import getDeliveryProofPdfBlob from '@salesforce/apex/HappyParcelController.getDeliveryProofPdfBlob';
import loadConfig from '@salesforce/apex/HappyParcelController.loadConfig';
import getNetwork from '@salesforce/apex/HappyParcelController.getNetwork';
import getSafeDropStatus from '@salesforce/apex/HappyParcelController.getSafeDropStatus';
import setSafeDropToEligible from '@salesforce/apex/HappyParcelController.setSafeDropToEligible';
import unsetSafeDropEligibility from '@salesforce/apex/HappyParcelController.unsetSafeDropEligibility';
import getNotificationPreferences from '@salesforce/apex/HappyParcelController.getNotificationPreferences';
import setNotificationPreferences from '@salesforce/apex/HappyParcelController.setNotificationPreferences';
import getDistanceBetweenLocations from '@salesforce/apex/HappyParcelController.getDistanceBetweenLocations';
import getCurrentStateOfSafeDropImageRequiredForDownload from '@salesforce/apex/MyCustomerDeliveryProofPdfController.getCurrentStateOfSafeDropImageRequiredForDownload';
import getCriticalIncidents from '@salesforce/apex/HappyParcelController.getCriticalIncidents';


// field mappings
// import field mappings to create a concrete dependency
// TODO: Import all happy parcel field names
import RECEIVER_ADDRESS from '@salesforce/schema/Article__c.ReceiverAddress__c';
import RECEIVER_CITY from '@salesforce/schema/Article__c.ReceiverCity__c';
import RECEIVER_MOBILE from '@salesforce/schema/Article__c.Receiver_Mobile__c';
import RECEIVER_NAME from '@salesforce/schema/Article__c.ReceiverName__c';
import RECEIVER_PHONE from '@salesforce/schema/Article__c.Receiver_Phone__c';
import RECEIVER_POSTCODE from '@salesforce/schema/Article__c.ReceiverPostcode__c';
import RECEIVER_STATE from '@salesforce/schema/Article__c.ReceiverState__c';
import RECEIVER_SUBURB from '@salesforce/schema/Article__c.Receiver_Suburb__c';
import RECEIVER_COUNTRY from '@salesforce/schema/Article__c.ReceiverCountry__c';
import RECEIVER_COUNTRYNAME from '@salesforce/schema/Article__c.ReceiverCountryName__c';
import RECEIVER_EMAIL from '@salesforce/schema/Article__c.ReceiverEmail__c';
import RECEIVER_APCN from '@salesforce/schema/Article__c.Receiver_APCN__c';
import SENDER_ADDRESS from '@salesforce/schema/Article__c.SenderAddress__c';
import SENDER_CITY from '@salesforce/schema/Article__c.SenderCity__c';
import SENDER_MOBILE from '@salesforce/schema/Article__c.Sender_Mobile__c';
import SENDER_NAME from '@salesforce/schema/Article__c.SenderName__c';
import SENDER_PHONE from '@salesforce/schema/Article__c.Sender_Phone__c';
import SENDER_POSTCODE from '@salesforce/schema/Article__c.SenderPostcode__c';
import SENDER_STATE from '@salesforce/schema/Article__c.SenderState__c';
import SENDER_SUBURB from '@salesforce/schema/Article__c.Sender_Suburb__c';
import SENDER_COUNTRY from '@salesforce/schema/Article__c.SenderCountry__c';
import SENDER_COUNTRYNAME from '@salesforce/schema/Article__c.SenderCountryName__c';
import SENDER_EMAIL from '@salesforce/schema/Article__c.SenderEmail__c';
import SENDER_APCN from '@salesforce/schema/Article__c.Sender_APCN__c';
import SENDER_MLID from '@salesforce/schema/Article__c.MLID__c'; //snigdha
import EXTERNAL_TRACKING_ID from '@salesforce/schema/Article__c.ExternalTrackingID__c';
import EXTERNAL_TRACKING_URL from '@salesforce/schema/Article__c.ExternalTrackingURL__c';
//Case field mappings
import FIELD_CASE_ORIGINATOR from '@salesforce/schema/Case.CaseOriginator__c';
import FIELD_COMPLAINT from '@salesforce/schema/Case.Complaint__c';
import FIELD_CONTACT_ID from '@salesforce/schema/Case.ContactId';
import FIELD_ENQUIRY_SUB_TYPE from '@salesforce/schema/Case.EnquirySubType__c';
import FIELD_ORIGIN from '@salesforce/schema/Case.Origin';
import FIELD_PRIORITY from '@salesforce/schema/Case.Priority';
import FIELD_PRODUCT_CATEGORY from '@salesforce/schema/Case.ProductCategory__c';
import FIELD_PRODUCT_SUB_CATEGORY from '@salesforce/schema/Case.ProductSubCategory__c';
import FIELD_TYPE from '@salesforce/schema/Case.Type';

// labels
import LABEL_HAPPYPARCELEDDHELPTEXT from '@salesforce/label/c.HappyParcelEDDHelpText';
import LABEL_HAPPYPARCELLATESTSCANSHELPTEXT from '@salesforce/label/c.HappyParcelLatestScansHelpText';
import LABEL_HAPPYPARCELLOOPINGHELPTEXT from '@salesforce/label/c.HappyParcelLoopingHelpText';
import LABEL_HAPPYPARCELMANIFESTASSESSMENTHELPTEXT from '@salesforce/label/c.HappyParcelManifestAssessmentHelpText';
import LABEL_HAPPYPARCELMISSORTHELPTEXT from '@salesforce/label/c.HappyParcelMissortHelpText';
import LABEL_HAPPYPARCELREDIRECTIONHELPTEXT from '@salesforce/label/c.HappyParcelRedirectionHelpText';
import LABEL_HAPPYPARCELDISTANCEHELPTEXT from '@salesforce/label/c.HappyParcelDistanceHelpText';
import LABEL_HAPPYPARCELSIGNATUREHELPTEXT from '@salesforce/label/c.HappyParcelSignatureHelpText';
import LABEL_HAPPYPARCELSCANEVENTSHELPTEXT from '@salesforce/label/c.HappyParcelScanEventsHelpText';
import LABEL_HAPPYPARCELREVOKEDMILESTONEHELPTEXT from '@salesforce/label/c.HappyParcelRevokedMilestoneHelpText';
import LABEL_HAPPYPARCELDELIVERYPROOFHELPTEXT from '@salesforce/label/c.HappyParcelDeliveryProofHelpText';
import LABEL_HAPPYPARCELDTNRESTRICTEDENQUIRYSUBTYPEERRORMSG from '@salesforce/label/c.HappyParcelDTNRestrictedEnquirySubtypeErrorMessage';
import LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESAPCNPHONEHELPTEXT from '@salesforce/label/c.HappyParcelNotificationPreferencesAPCNPhoneHelpText';
import LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESAPCNEMAILHELPTEXT from '@salesforce/label/c.HappyParcelNotificationPreferencesAPCNEmailHelpText';
import LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESOPTOUTHELPTEXT from '@salesforce/label/c.HappyParcelNotificationPreferencesOptOutHelpText';
import LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESBLUEBOXTEXT from '@salesforce/label/c.HappyParcelNotificationPreferencesBlueBoxText';
import LABEL_HAPPYPARCELVODVWARNINGTEXT from '@salesforce/label/c.HappyParcelVODVWarningText';
import LABEL_HAPPYPARCELCORRECTDELIVERYHELPTEXT from '@salesforce/label/c.HappyParcelCorrectDeliveryHelpText';
import LABEL_HAPPYPARCELACCEPTABLEDELIVERYHELPTEXT from '@salesforce/label/c.HappyParcelAcceptableDeliveryHelpText';
import LABEL_HAPPYPARCELACCEPTABLEDISTANCEHELPTEXT from '@salesforce/label/c.HappyParcelAcceptableDistanceHelpText';
import LABEL_HAPPYPARCELSCANHELPTEXT from '@salesforce/label/c.HappyParcelScanHelpText';
import LABEL_HAPPYPARCELDISTANCECALCULATEDDELIVERYHELPTEXT from '@salesforce/label/c.HappyParcelDistanceCalculatedHelpText';


//Custom permissions
import PERMISSION_CREATECASEDIRECTTONETWORK from '@salesforce/customPermission/CreateCaseDirectToNetwork';

// private vars
let _config;
const _callbacks = [];

export const CONSTANTS = {
	CUSTOMER_DETAILS_SENDER: 1,
	CUSTOMER_DETAILS_RECEIVER: 2,
	TYPE_LOOPING: 1,
	TYPE_MISSORTS: 2,

	FIELD_RECEIVER_ADDRESS: RECEIVER_ADDRESS.fieldApiName,
	FIELD_RECEIVER_CITY: RECEIVER_CITY.fieldApiName,
	FIELD_RECEIVER_MOBILE: RECEIVER_MOBILE.fieldApiName,
	FIELD_RECEIVER_NAME: RECEIVER_NAME.fieldApiName,
	FIELD_RECEIVER_PHONE: RECEIVER_PHONE.fieldApiName,
	FIELD_RECEIVER_POSTCODE: RECEIVER_POSTCODE.fieldApiName,
	FIELD_RECEIVER_STATE: RECEIVER_STATE.fieldApiName,
	FIELD_RECEIVER_SUBURB: RECEIVER_SUBURB.fieldApiName,
	FIELD_RECEIVER_COUNTRY: RECEIVER_COUNTRY.fieldApiName,
	FIELD_RECEIVER_COUNTRYNAME: RECEIVER_COUNTRYNAME.fieldApiName,
	FIELD_RECEIVER_EMAIL: RECEIVER_EMAIL.fieldApiName,
	FIELD_RECEIVER_APCN: RECEIVER_APCN.fieldApiName,
	FIELD_SENDER_ADDRESS: SENDER_ADDRESS.fieldApiName,
	FIELD_SENDER_CITY: SENDER_CITY.fieldApiName,
	FIELD_SENDER_MOBILE: SENDER_MOBILE.fieldApiName,
	FIELD_SENDER_NAME: SENDER_NAME.fieldApiName,
	FIELD_SENDER_PHONE: SENDER_PHONE.fieldApiName,
	FIELD_SENDER_POSTCODE: SENDER_POSTCODE.fieldApiName,
	FIELD_SENDER_STATE: SENDER_STATE.fieldApiName,
	FIELD_SENDER_SUBURB: SENDER_SUBURB.fieldApiName,
	FIELD_SENDER_COUNTRY: SENDER_COUNTRY.fieldApiName,
	FIELD_SENDER_COUNTRYNAME: SENDER_COUNTRYNAME.fieldApiName,
	FIELD_SENDER_EMAIL: SENDER_EMAIL.fieldApiName,
	FIELD_SENDER_APCN: SENDER_APCN.fieldApiName,
	FIELD_SENDER_MLID: SENDER_MLID.fieldApiName, //Snigdha
	FIELD_EXTERNAL_TRACKING_ID: EXTERNAL_TRACKING_ID.fieldApiName,
	FIELD_EXTERNAL_TRACKING_URL: EXTERNAL_TRACKING_URL.fieldApiName,
	//Case Fields
	FIELD_CASE_ORIGINATOR: FIELD_CASE_ORIGINATOR.fieldApiName,
	FIELD_CONTACT_ID: FIELD_CONTACT_ID.fieldApiName,
	FIELD_COMPLAINT: FIELD_COMPLAINT.fieldApiName,
	FIELD_ENQUIRY_SUB_TYPE: FIELD_ENQUIRY_SUB_TYPE.fieldApiName,
	FIELD_ORIGIN: FIELD_ORIGIN.fieldApiName,
	FIELD_PRIORITY: FIELD_PRIORITY.fieldApiName,
	FIELD_PRODUCT_CATEGORY: FIELD_PRODUCT_CATEGORY.fieldApiName,
	FIELD_PRODUCT_SUB_CATEGORY: FIELD_PRODUCT_SUB_CATEGORY.fieldApiName,
	FIELD_TYPE: FIELD_TYPE.fieldApiName,

	LABEL_HAPPYPARCELEDDHELPTEXT: LABEL_HAPPYPARCELEDDHELPTEXT,
	LABEL_HAPPYPARCELLATESTSCANSHELPTEXT: LABEL_HAPPYPARCELLATESTSCANSHELPTEXT,
	LABEL_HAPPYPARCELLOOPINGHELPTEXT: LABEL_HAPPYPARCELLOOPINGHELPTEXT,
	LABEL_HAPPYPARCELMISSORTHELPTEXT: LABEL_HAPPYPARCELMISSORTHELPTEXT,
	LABEL_HAPPYPARCELREDIRECTIONHELPTEXT: LABEL_HAPPYPARCELREDIRECTIONHELPTEXT,
	LABEL_HAPPYPARCELDISTANCEHELPTEXT: LABEL_HAPPYPARCELDISTANCEHELPTEXT,
	LABEL_HAPPYPARCELSIGNATUREHELPTEXT: LABEL_HAPPYPARCELSIGNATUREHELPTEXT,
	LABEL_HAPPYPARCELSCANEVENTSHELPTEXT: LABEL_HAPPYPARCELSCANEVENTSHELPTEXT,
	LABEL_HAPPYPARCELMANIFESTASSESSMENTHELPTEXT: LABEL_HAPPYPARCELMANIFESTASSESSMENTHELPTEXT,
	LABEL_HAPPYPARCELREVOKEDMILESTONEHELPTEXT: LABEL_HAPPYPARCELREVOKEDMILESTONEHELPTEXT,
	LABEL_HAPPYPARCELDELIVERYPROOFHELPTEXT: LABEL_HAPPYPARCELDELIVERYPROOFHELPTEXT,
	LABEL_HAPPYPARCELDTNRESTRICTEDENQUIRYSUBTYPEERRORMSG: LABEL_HAPPYPARCELDTNRESTRICTEDENQUIRYSUBTYPEERRORMSG,
	LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESAPCNPHONEHELPTEXT: LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESAPCNPHONEHELPTEXT,
	LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESAPCNEMAILHELPTEXT: LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESAPCNEMAILHELPTEXT,
	LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESOPTOUTHELPTEXT: LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESOPTOUTHELPTEXT,
	LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESBLUEBOXTEXT: LABEL_HAPPYPARCELNOTIFICATIONPREFERENCESBLUEBOXTEXT,
	LABEL_HAPPYPARCELVODVWARNINGTEXT: LABEL_HAPPYPARCELVODVWARNINGTEXT,
	LABEL_HAPPYPARCELCORRECTDELIVERYHELPTEXT: LABEL_HAPPYPARCELCORRECTDELIVERYHELPTEXT,
	LABEL_HAPPYPARCELACCEPTABLEDELIVERYHELPTEXT: LABEL_HAPPYPARCELACCEPTABLEDELIVERYHELPTEXT,
	LABEL_HAPPYPARCELACCEPTABLEDISTANCEHELPTEXT: LABEL_HAPPYPARCELACCEPTABLEDISTANCEHELPTEXT,
	LABEL_HAPPYPARCELSCANHELPTEXT: LABEL_HAPPYPARCELSCANHELPTEXT,
	LABEL_HAPPYPARCELDISTANCECALCULATEDDELIVERYHELPTEXT: LABEL_HAPPYPARCELDISTANCECALCULATEDDELIVERYHELPTEXT,

	SAFEDROP_INELIGIBLE: 'Ineligible',
	SAFEDROP_ELIGIBLE: 'Eligible',
	DTN_CASE_RECORDTYPE: 'SSSW Delivery',
	LOCATION_ICON_SVG_PATH: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z',
	ANALYTICS_API: 'Analytics API',
	TRACKING_API: 'Tracking API',
	STARTRACK_API: 'StarTrack API'
};

export const safeTrim = (str) => {
	return (str && str.trim ? str.trim() : str);
}

export const safeToUpper = (str) => {
	return (str && str.toUpperCase ? str.toUpperCase() : str);
}

export const subscribe = (event, callback) => {
	_callbacks[event] = (!_callbacks[event] ? [] : _callbacks[event]);
	if (_callbacks[event].indexOf(callback) === -1) {
		_callbacks[event].push(callback);
	}
};

export const unsubscribe = (event, callback) => {
	_callbacks[event] = (!_callbacks[event] ? [] : _callbacks[event]);

	const index = _callbacks[event].indexOf(callback);
	if (index > -1) {
		_callbacks[event].splice(index, 1);
	}
};

export const publish = (event, params) => {
	_callbacks[event] = (!_callbacks[event] ? [] : _callbacks[event]);

	_callbacks[event].forEach(callback => {
		if (typeof callback == 'function') {
			callback(params);
		}
	});
};

export const getConfig = async () => {
	if (!_config) {
		_config = await loadConfig();
		return Promise.resolve(_config);
	} else {
		return Promise.resolve(_config);
	}
}

export const getCustomerArticleFields = () => {
	return [
		CONSTANTS.FIELD_RECEIVER_ADDRESS,
		CONSTANTS.FIELD_RECEIVER_CITY,
		CONSTANTS.FIELD_RECEIVER_MOBILE,
		CONSTANTS.FIELD_RECEIVER_NAME,
		CONSTANTS.FIELD_RECEIVER_PHONE,
		CONSTANTS.FIELD_RECEIVER_POSTCODE,
		CONSTANTS.FIELD_RECEIVER_STATE,
		CONSTANTS.FIELD_RECEIVER_SUBURB,
		CONSTANTS.FIELD_RECEIVER_COUNTRY,
		CONSTANTS.FIELD_RECEIVER_COUNTRYNAME,
		CONSTANTS.FIELD_RECEIVER_EMAIL,
		CONSTANTS.FIELD_RECEIVER_APCN,
		CONSTANTS.FIELD_SENDER_ADDRESS,
		CONSTANTS.FIELD_SENDER_CITY,
		CONSTANTS.FIELD_SENDER_MOBILE,
		CONSTANTS.FIELD_SENDER_NAME,
		CONSTANTS.FIELD_SENDER_PHONE,
		CONSTANTS.FIELD_SENDER_POSTCODE,
		CONSTANTS.FIELD_SENDER_STATE,
		CONSTANTS.FIELD_SENDER_SUBURB,
		CONSTANTS.FIELD_SENDER_COUNTRY,
		CONSTANTS.FIELD_SENDER_COUNTRYNAME,
		CONSTANTS.FIELD_SENDER_EMAIL,
		CONSTANTS.FIELD_SENDER_APCN,
		CONSTANTS.FIELD_SENDER_MLID
	];
}

/**
 * This is used to get the appropriate mappings between Schema.DisplayType (apex) and datatable (lwc).
 */
export const getDataTableMappingFromDisplayType = (displayType) => {
	const dataTypeMappings = {
		ADDRESS: { type: 'text', typeAttributes: {} },
		ANYTYPE: { type: 'text', typeAttributes: {} },
		BOOLEAN: { type: 'boolean', typeAttributes: {} },
		COMBOBOX: { type: 'text', typeAttributes: {} },
		CURRENCY: { type: 'currency', typeAttributes: { maximumFractionDigits: 2 } },
		DATACATEGORYGROUPREFERENCE: { type: 'text', typeAttributes: {} },
		DATE: { type: 'date', typeAttributes: { year: 'numeric', month: '2-digit', day: '2-digit', weekday: 'long' } },
		DATETIME: { type: 'date', typeAttributes: { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' } },
		DOUBLE: { type: 'number', typeAttributes: { maximumFractionDigits: 2 } },
		EMAIL: { type: 'email', typeAttributes: {} },
		ENCRYPTEDSTRING: { type: 'text', typeAttributes: {} },
		ID: { type: 'text', typeAttributes: {} },
		INTEGER: { type: 'number', typeAttributes: {} },
		LONG: { type: 'number', typeAttributes: {} },
		MULTIPICKLIST: { type: 'text', typeAttributes: {} },
		PERCENT: { type: 'percent', typeAttributes: { maximumFractionDigits: 2 } },
		PHONE: { type: 'phone', typeAttributes: {} },
		PICKLIST: { type: 'text', typeAttributes: {} },
		REFERENCE: { type: 'text', typeAttributes: {} },
		STRING: { type: 'text', typeAttributes: {} },
		TEXTAREA: { type: 'text', typeAttributes: {} },
		TIME: { type: 'date', typeAttributes: { hour: '2-digit', minute: '2-digit' } },
		URL: { type: 'url', typeAttributes: {} }
	};

	return dataTypeMappings[displayType];
}

/**
 * Get the analytics information from the remote api
 */
export const getAnalyticsApiResponse = async (trackingId) => {
	try {
		const result = await queryAnalyticsApi({
			trackingId: trackingId
		});
		console.log('getAnalyticsResponse', result);

		return result;
	} catch (error) {
		return { articles: [], errors: [error.body.message] };
	}
}

/**
 * Get the tracking information from the remote api
 */
export const getTrackingApiResponse = async (trackingId, forceConsignmentSearch) => {
	try {
		const result = await queryTrackingApi({
			trackingId: trackingId,
			forceConsignmentSearch: forceConsignmentSearch
		});

		console.log('getTrackingResponse', result);
		return result;
	} catch (error) {
		return { articles: [], errors: [error.body.message] };
	}
}

/**
 * @description Get the tracking information from the remote .NET API for StarTrack
 */
export const getTrackingApiResponseForStarTrack = async (consignmentNumber, consignment) => {
	try {
		const result = await queryTrackingApiForStarTrack({
			consignmentNumber: consignmentNumber,
			trackingResultString: JSON.stringify(consignment.trackingResult)
		});
		return result;
	} catch (error) {
		return { articles: [], errors: [error.body.message] };
	}
}

export const downloadDeliveryProofPdf = async (trackingId) => {
	const result = await getDeliveryProofPdfBlob({
		trackingId: trackingId
	});
	return result;
}

/**
 * Allows the user to get Network details
 */
export const getNetworkDetails = async (wcc) => {
	try {
		let result = await getNetwork({
			wccString: wcc
		});

		console.log('getNetworkDetails');
		return result;
	} catch (error) {
		return { network: [], error: [error.body.message] };
	}
}

/**
 * Allows the user to get critical incidents based on the network org Id
 */
export const getCriticalIncidentDetails = async () => {
	let result = await getCriticalIncidents();

	return result;
}

/**
 * perform a callout to get the safe drop eligibility
 * not sure why the method needs both trackingId and articleId
 *
 * TODO: Refactor this:
 * move the text labels into custom metadata....
 * Ran out of time for this in the first round of changes
 */
export const getSafeDropEligibilityStatus = async (trackingId) => {
	const result = await getSafeDropStatus({
		articleId: trackingId
	});
	console.log('getSafeDropEligibilityStatus', result);
	return result;
}

/**
 * Allows the user to request for Safe Drop (Should be consignment id if it's available)
 */
export const addSafeDrop = async (trackingId) => {
	let result = await setSafeDropToEligible({
		articleId: trackingId
	});

	console.log('addSafeDrop', result);
	return result;
}

/**
 * Allows the user to remove safe drop (Should be consignment id if it's available)
 */
export const deleteSafeDrop = async (trackingId) => {
	const result = await unsetSafeDropEligibility({
		articleId: trackingId
	});
	console.log('deleteSafeDrop', result);
	return result;
}

/**
 * This gets notification preference for search string
 */
export const getPreferences = async (searchString) => {
	try {
		const result = await getNotificationPreferences({
			searchStrings: searchString
		});
		console.log('getPreferences', result);
		return result;
	} catch (error) {
		return { preferences: [], error: [error.body.message] };
	}
}

/**
 * This sets/unsets notification preferences. Only one value can be set at a time.
 */
export const setPreferences = async (searchString, setValue) => {
	try {
		const result = await setNotificationPreferences({
			searchStrings: searchString,
			setValue: setValue
		});
		console.log('setPreferences', result);
		return result;
	}
	catch (error) {
		return 'Error: Something went wrong.';
	}
}


export const getSafeDropImage = async (safeDropGuid) => {
	// perform a callout to get the safe drop image
	const result = await getArticleImage({
		guidId: safeDropGuid
	});

	console.log('getSafeDropImage', result);
	return result;
}

/**
 * Retrieve safeDropImage in bulk by split off to multiple transaction using the provided list of safeDrop state including guidID and flag that indicate if a download is required
 * @param {String} safeDropGuid
 * @param {String} eventMessageId
 * @returns {Promise<*>}
 */
export const getSafeDropImageAndSaveForPOD = async (safeDropGuid, eventMessageId) => {

	// perform a callout to get the safe drop image
	const result = await getSafeDropImageForPOD({
		guidId: safeDropGuid,
		eventMessageId: eventMessageId
	});
	return result;
}

export const hasPermissionToCreateCaseDirectToNetwork = () => {
	return PERMISSION_CREATECASEDIRECTTONETWORK;
}

// get safeDropImageResult() {
// 	return this._safeDropImage;
// }

/*  implementation of lodash get
	Gets the value at path of object. If the resolved value is undefined,
	the defaultValue is returned in its place.
*/
export const get = (object, path, defaultVal) => {
	path = Array.isArray(path) ? path : path.split('.');
	object = object[path[0]];
	if (object && path.length > 1) {
		return get(object, path.slice(1));
	}
	return object === undefined ? defaultVal : object;
}

/**
 * Function to get the distance in kms between two geo-coordinates
 * @param {Number} lat1 
 * @param {Number} lon1 
 * @param {Number} lat2 
 * @param {Number} lon2 
 * @returns Distance in Kms
 */
export const getDistanceBetweenGeoCoordinates = async (lat1, lon1, lat2, lon2) => {
	try {
		const result = await getDistanceBetweenLocations({
			lat1: lat1,
			lon1: lon1,
			lat2: lat2,
			lon2: lon2
		});
		return result;
	}
	catch (error) {
		return null;
	}
}

/**
 * @description Retrieve a snapshot of the current state of SafeDrop image file per article under the parent consignment if they exist in Salesforce
 * 				If it doesn't exist, it's required to be downloaded
 * @param {String} trackingId
 * @return {Promise<*>}
 */
export const getSafeDropImageStateForDownload = async (trackingId) => {
	const result = await getCurrentStateOfSafeDropImageRequiredForDownload({
		trackingId: trackingId
	});
	return result;
}

/**
 * @description Refresh the Consignment/Article data in Salesforce from SAP/StarTrack by searching up the tracking number and upsert the responses in Salesforce
 */
export const refreshSFConsignmentArticleDataFromSAPAndStarTrack = async (trackingIds) => {
	const consignmentId = trackingIds.consignmentId;
	const articleId = trackingIds.articleId;
	const sapResult = consignmentId ? await getTrackingApiResponse(consignmentId, false) : await getTrackingApiResponse(articleId, true);
	// execute a consignment search for StarTrack if required
	const requireAdditionalQueryForStarTrack = sapResult.requireAdditionalQueryForStarTrack;
	const consignment = { trackingId: sapResult.consignment.trackingId, trackingResult: sapResult.consignment };
	if (requireAdditionalQueryForStarTrack) {
		// if this api timeout, then the download button needed to be clicked again to retry
		await getTrackingApiResponseForStarTrack(sapResult.consignment.trackingId, consignment);
	}
}

/**
 * @description Download Proof of Delivery PDF by first refreshing the Salesforce data related to consignment/articles by perform SAP/StarTrack search
 * 				Then, download required safe drop image if applicable and thereafter generate PDF pages and download them
 * @param {Object} trackingIds - Contains article tracking Id or consignment tracking Id
 * @returns {Promise<void>}
 */
export const downloadPODPDF = async (trackingIds) => {
	await refreshSFConsignmentArticleDataFromSAPAndStarTrack(trackingIds);
	const finalId = trackingIds.consignmentId || trackingIds.articleId;

	// retrieve the current state of safe drop images caches in Salesforce
	const safeDropImageState = await getSafeDropImageStateForDownload(finalId);
	// download safe drop images as required if they do not exist in Salesforce
	await processSafeDropImagesDownloading(safeDropImageState);

	// execute the VF pdf page generator logic in controller
	const pdfBase64 = await downloadDeliveryProofPdf(finalId);

	const fileName = "DeliveryProof-" + encodeURIComponent(finalId) + ".pdf";

	// deal with IE
	if (navigator && navigator.msSaveBlob) {
		// IE10+
		return navigator.msSaveBlob(new Blob([pdfBase64], { type: ".pdf" }), fileName);
	}

	// now download the generated content
	const downloadElement = document.createElement("a");
	downloadElement.href = "data:application/octet-stream;base64," + encodeURIComponent(pdfBase64);
	downloadElement.target = "_self";
	downloadElement.download = fileName;
	document.body.appendChild(downloadElement);
	downloadElement.click();
	document.body.removeChild(downloadElement);

	return Promise.resolve();
}

/**
 * @description Download SafeDropImage in bulk by looping through the SafeDropState array object and split callout in multiple transactions
 * @param {Array} safeDropImageState - The array of objects containing guidId and requireDownload
 * @returns {Promise<void>}
 */
export const processSafeDropImagesDownloading = async (safeDropImageState) => {
	for (let i = 0; i < safeDropImageState.length; i++) {
		if (safeDropImageState[i].requireDownload) {
			try {
				const result = await getSafeDropImageAndSaveForPOD(safeDropImageState[i].guidID, safeDropImageState[i].eventMessageId);
				if (!result.isError) {
					safeDropImageState[i].requireDownload = false;
				}
			} catch (error) {
				console.error("Failed to download image for guidId:", safeDropImageState[i].guidID, error);
			}
		}
	}
}