/**
 * @author Thang Nguyen
 * @date 2023-12-04
 * @group lwc
 * @domain Generic
 * @description adobe analytic utilities
 * @changelog
 * 2023-12-04 - Thang Nguyen - Created
 */

export function analyticsTrackPageLoad(pageData) {

	analytics.page = {}; 
	analytics.page.pageData = {}; 		
	analytics.page.pageData.sitePrefix = pageData.sitePrefix;
	analytics.page.pageData.pageAbort = pageData.pageAbort;
	analytics.page.pageData.pageName = pageData.pageName;
	analytics.component = {}; 

	console.log('Pushing Analytics Event >> ', pageData, JSON.parse(JSON.stringify(analytics)));
}

