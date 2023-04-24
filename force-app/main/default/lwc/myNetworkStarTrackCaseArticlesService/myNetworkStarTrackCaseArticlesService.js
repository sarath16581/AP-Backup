/**
 * @description Service component for MyNetwork StarTrack case functionality
 * @author Mahesh Parvathaneni
 * @date 2022-11-22
 * @changelog
 * 2023-03-06 - Mahesh Parvathaneni - Added function getStarTrackFormattedDateTimeString
 * 2023-04-03 - Mahesh Parvathaneni - Added label LABEL_BLANK_CASE_TYPE_ERROR_MESSAGE
 */

// server calls
import getArticlesByCase from '@salesforce/apex/MyNetworkStarTrackCaseController.getArticlesByCase';
import saveCaseInvestigations from '@salesforce/apex/MyNetworkStarTrackCaseController.saveCaseInvestigations';
import getCriticalIncidentsKav from '@salesforce/apex/MyNetworkStarTrackCaseController.getCriticalIncidents';

// custom labels
import LABEL_CONSIGNMENT_ERROR_MESSAGE from '@salesforce/label/c.MyNetworkConsignmentErrorMessage';
import LABEL_CASE_INVESTIGATION_SUCCESS_MESSAGE from '@salesforce/label/c.MyNetworkCaseInvestigationSuccessMessage';
import LABEL_INVALID_CASE_INVESTIGATION_ERROR_MESSAGE from '@salesforce/label/c.MyNetworkInvalidCaseInvestigationErrorMessage';
import LABEL_INVALID_NETWORK_ERROR_MESSAGE from '@salesforce/label/c.MyNetworkInvalidNetworkErrorMessage';
import LABEL_BLANK_NETWORK_ERROR_MESSAGE from '@salesforce/label/c.MyNetworkBlankNetworkErrorMessage';
import LABEL_BLANK_CASE_TYPE_ERROR_MESSAGE from '@salesforce/label/c.MyNetworkBlankCaseTypeErrorMessage';

import { get } from 'c/utils';


export const CONSTANTS = {
	LABEL_CONSIGNMENT_ERROR_MESSAGE: LABEL_CONSIGNMENT_ERROR_MESSAGE,
	LABEL_CASE_INVESTIGATION_SUCCESS_MESSAGE: LABEL_CASE_INVESTIGATION_SUCCESS_MESSAGE,
	LABEL_INVALID_CASE_INVESTIGATION_ERROR_MESSAGE: LABEL_INVALID_CASE_INVESTIGATION_ERROR_MESSAGE,
	LABEL_INVALID_NETWORK_ERROR_MESSAGE: LABEL_INVALID_NETWORK_ERROR_MESSAGE,
	LABEL_BLANK_NETWORK_ERROR_MESSAGE: LABEL_BLANK_NETWORK_ERROR_MESSAGE,
	LABEL_BLANK_CASE_TYPE_ERROR_MESSAGE: LABEL_BLANK_CASE_TYPE_ERROR_MESSAGE,

	MY_NETWORK: 'MyNetwork'
}


/**
 * Retrieve articles along with event messages for a case
 * @param {String} caseId 
 * @returns articles related to case
 */
 export const getArticles = async (caseId) => {

	const result = await getArticlesByCase({
		caseId: caseId
	});
	return result;
}

/**
 * save case investigation records related to case and articles
 * @param {Array} recordsToSave 
 * @returns save result from the server
 */
 export const submitCaseInvestigations = async (recordsToSave, comments) => {

	const result = await saveCaseInvestigations({
		recordsToSave: recordsToSave,
		comments: comments
	});
	return result;
}

/**
 * Returns the value for the field passed in the object
 * @param {Object} record 
 * @param {String} fieldName 
 * @param {Object} defaultValue 
 * @returns Object
 */
export const getValue = (record, fieldName, defaultValue) => {
	return get(record, fieldName, defaultValue);
}

/**
 * Retrieve the online published critical incidents knowledge articles
 * @returns critical incidents knowledge articles
 */
export const getCriticalIncidents = async () => {

	const result = await getCriticalIncidentsKav();
	return result;
}

const monthNameToNum = new Map([
	["jan", "01"], ["feb", "02"], ["mar", "03"], ["apr", "04"], ["may", "05"], ["jun", "06"], ["jul", "07"], ["aug", "08"], 
	["sep", "09"], ["oct", "10"], ["nov", "11"], ["dec", "12"]
])

/**
 * Converts the timestamp string to dd/mm/yyyy hh:mm format
 * @param {String} dateTimeString // '20-Nov-201912:00 AM' format
 * @returns String 20/11/2019 12:00 AM
 */
export const getStarTrackFormattedDateTimeString = (dateTimeString) => {
	let formattedDatetime;
	if (dateTimeString) {
		let tempArray = dateTimeString.split('-');
		formattedDatetime = tempArray[0] + '/' + monthNameToNum.get(tempArray[1].toLowerCase()) + '/' + 
			tempArray[2].substring(0, 4) + (tempArray[2].substring(4) ? (' ' + tempArray[2].substring(4)) : '');
	}
	return formattedDatetime;
}