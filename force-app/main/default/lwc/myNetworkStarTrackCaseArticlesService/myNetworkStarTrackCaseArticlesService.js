/**
 * @description Service component for MyNetwork StarTrack case functionality
 * @author Mahesh Parvathaneni
 * @date 2022-11-22
 */

// server calls
import getArticlesByCase from '@salesforce/apex/MyNetworkStarTrackCaseController.getArticlesByCase';

import { get } from 'c/utils';


export const CONSTANTS = {
    
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
 * Returns the value for the field passed in the object
 * @param {Object} record 
 * @param {String} fieldName 
 * @param {Object} defaultValue 
 * @returns Object
 */
export const getValue = (record, fieldName, defaultValue) => {
    return get(record, fieldName, defaultValue);
}