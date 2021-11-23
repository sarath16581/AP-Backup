/****************************************************************************************
	@author: Victor Cheng
	@description: Constant class for BGS Case related process and functionality
    @history:
-----------------------------------------------------------------------------------------
16-01-2020     vcheng@salesforce.com            New class created
14-07-2020     seth.heang@auspost.com.au 		Add case constant for STP-2240/STP-2242
*****************************************************************************************/

public with sharing class BGSConstants {

    public static final String SERVICE_DELIVERY_NAME = 'Service Delivery'; // the name for Service Delivery RT

    // the Account hosting all the BGS entitlement records
    public static final String BGS_ENTITLEMENT_STANDARD = 'BGS Entitlement Standard';
    // Entitlement RECORD names
    // Default entitlement will be VIC timezone
    public static final String BGS_ENTITLEMENT_VIC = 'BGS Entitlement Standard - VIC';
    public static final String BGS_ENTITLEMENT_NSW = 'BGS Entitlement Standard - NSW';
    public static final String BGS_ENTITLEMENT_QLD = 'BGS Entitlement Standard - QLD';
    public static final String BGS_ENTITLEMENT_WA = 'BGS Entitlement Standard - WA';
    public static final String BGS_ENTITLEMENT_SA = 'BGS Entitlement Standard - SA';
    public static final String BGS_ENTITLEMENT_NT = 'BGS Entitlement Standard - NT';
    public static final String BGS_ENTITLEMENT_TAS = 'BGS Entitlement Standard - TAS';
    public static final String BGS_ENTITLEMENT_ACT = 'BGS Entitlement Standard - ACT';
    public static final String BGS_CASE_CLOSURE_TEMPLATE = 'BGS Case Closure';
    public static final String BGS_CLOSED_CASE_BOUNCE = 'BGS Closed Case Bounce';
    // Add case constant for STP-2240/STP-2242
    public static final String AUSPOST_NOREPLY_EMAIL = 'noreply@auspost.com.au';
    public static final String CASE_RESOLUTION_CODE_CLOSED_DUPLICATE = 'Closed - Duplicate';
}