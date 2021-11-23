/**************************************************
Description:    StarTrack util class for BSP Consignment Search
History:
--------------------------------------------------
2016-11-18 - Jen Karen Tan - Created
2018-05-22  nathan.franklin@auspost.com.au  Refactoring code. Deprecated generateSearchResult and removed generateHeader (moved into StarTrackConsignmentSearchUtil)
**************************************************/
public class BSPConsignmentSearchUtil {
    
    public static StarTrack_Settings__c stSettings = StarTrack_Settings__c.getOrgDefaults();

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   StarTrack method that generates search request
    Inputs:        String value, String searchType, String action
    Returns:       wwwAuspostComAuSchemaCustomercarema.SearchRequest
    History:
    January 13, 2017 - Jen Karen Tan - Created

    @deprecated - DO NOT USE - Use StarTrackConsignmentSearchUtil.generateSearchRequest
    ------------------------------------------------------------*/
    public static wwwAuspostComAuSchemaCustomercarema.SearchRequest generateSearchRequest(String value, String searchType, String action) {
        return StarTrackConsignmentSearchUtil.generateSearchRequest(value, searchType, action, BspConstants.BSP_SOURCEID, UserInfo.getUserName());
    }

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   StarTrack method that generates stub for async callout
    Inputs:        
    Returns:       AsyncWwwAuspostComAuSchemaCustomercarema
    History:
    January 13, 2017 - Jen Karen Tan - Created

    @deprecated - DO NOT USE - Use StarTrackConsignmentSearchUtil.generateAsyncStub
    ------------------------------------------------------------*/
    public static AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 generateAsyncStub() {
        return StarTrackConsignmentSearchUtil.generateAsyncStub();
    }
}