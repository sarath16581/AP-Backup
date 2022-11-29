/**
 * @description Service component for MyNetwork StarTrack case functionality
 * @author Mahesh Parvathaneni
 * @date 2022-11-22
 */

// server calls
import getArticlesByCase from '@salesforce/apex/MyNetworkStarTrackCaseController.getArticlesByCase';
import saveCaseInvestigations from '@salesforce/apex/MyNetworkStarTrackCaseController.saveCaseInvestigations';

// custom labels
import LABEL_CONSIGNMENT_ERROR_MESSAGE from '@salesforce/label/c.MyNetworkConsignmentErrorMessage';
import LABEL_CASE_INVESTIGATION_SUCCESS_MESSAGE from '@salesforce/label/c.MyNetworkCaseInvestigationSuccessMessage';
import LABEL_INVALID_CASE_INVESTIGATION_ERROR_MESSAGE from '@salesforce/label/c.MyNetworkInvalidCaseInvestigationErrorMessage';
import LABEL_INVALID_NETWORK_ERROR_MESSAGE from '@salesforce/label/c.MyNetworkInvalidNetworkErrorMessage';

import { get } from 'c/utils';


export const CONSTANTS = {
    LABEL_CONSIGNMENT_ERROR_MESSAGE: LABEL_CONSIGNMENT_ERROR_MESSAGE,
	LABEL_CASE_INVESTIGATION_SUCCESS_MESSAGE: LABEL_CASE_INVESTIGATION_SUCCESS_MESSAGE,
    LABEL_INVALID_CASE_INVESTIGATION_ERROR_MESSAGE: LABEL_INVALID_CASE_INVESTIGATION_ERROR_MESSAGE,
    LABEL_INVALID_NETWORK_ERROR_MESSAGE: LABEL_INVALID_NETWORK_ERROR_MESSAGE
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