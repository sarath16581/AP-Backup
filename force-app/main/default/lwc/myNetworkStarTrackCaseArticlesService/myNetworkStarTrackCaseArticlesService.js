/**
 * @description Service component for MyNetwork StarTrack case functionality
 * @author Mahesh Parvathaneni
 * @date 2022-11-22
 */

// server calls
import getArticlesByCase from '@salesforce/apex/MyNetworkStarTrackCaseController.getArticlesByCase';

export const CONSTANTS = {
    
}


/**
 * Retrieve articles along with event messages for a case.
 */
 export const getArticles = async (caseId) => {

    const result = await getArticlesByCase({
        caseId: caseId
    });
	return result;
}