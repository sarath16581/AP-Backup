/**
* @author       : 
* @date         : 
* @description  : helper class for case manager allocation flow
*/
/*******************************  History ************************************************
23/01/2016  kalpita.talwadekar@auspost.com.au   Created
07/06/2017  nanda.kothamasu@auspost.com.au - updated codes based on INC0896795
19/04/2017  nanda.kothamasu@auspost.com.au - updated new Prod Sub Cat based on REQ1403395
08/08/2018  nmain@salesforce.com - commented out mapping from 'Mail redirection' to 'Parcel Post'
04/08/2020 hara.sahoo@auspost.com.au commented out mapping for 'Article carded - no delivery attempt'. This was required for the Help and support deliveryissue form uplift

*******************************  History ************************************************/
public class SSSW_CaseClearViewMapping_ForOnline {

    private static final String IDCASE = 'Id';
    private static final String PRD_SUB_CAT = 'PRD_SUB_CAT';
    private static final String ENQ_SUB_TYPE = 'ENQ_SUB_TYPE';
    private static final String OP_PARAM = 'newCaseId';

    /**
   @description  method invoked from the flow to send inpiut params and perform allocation accordinly.
   @param    Process.PluginRequest request
   @return   Process.PluginResult
   @throws NA
   */
    @InvocableMethod
    public static void processClearViewCodes(List<Id> idList){
        try {
            map<STring,String> productSubCatMap = new Map<String,String>();
            productSubCatMap.put('Mobile devices','Mobile products');
            productSubCatMap.put('mobile website','Mobile apps');
            productSubCatMap.put('Other Post Office & Hub Services','Post office locator');
            productSubCatMap.put('Stationery','Stationery and packaging');
            productSubCatMap.put('PostBillPay','Post BillPay');
            productSubCatMap.put('ID check - ATO TFN','Tax file number');
            productSubCatMap.put('Passport-Austrlian','Passport');
            productSubCatMap.put('Passport-British','Identity & document services');
            productSubCatMap.put('stationery.auspost.com.au','Stationery & packaging');
            productSubCatMap.put('Packaging','Stationery & packaging');
            productSubCatMap.put('Ordinary mail','Regular Mail');
            productSubCatMap.put('Other domestic letters','Regular Mail');
            productSubCatMap.put('Business letters','Regular Mail');
            productSubCatMap.put('Other Domestic Parcels','Parcel Post');
            productSubCatMap.put('Other international letters','International Standard');
            productSubCatMap.put('Other international Parcels','International Standard');
            productSubCatMap.put('Parcel','Parcel Post');   // Nanda K : Fix string INC0896795
            productSubCatMap.put('Letter','Ordinary Mail'); // Nanda K : Fix string INC0896795

            //Snigdha : Added for REQ1060551
            // 08/08/2018 - commented out no longer required for online.
            //productSubCatMap.put('Mail redirection','Parcel Post');

            //Nanda K : Added for REQ1403395
            productSubCatMap.put('Global Logistics','International Parcels');

            map<STring,String> enqSubTypeMap = new Map<String,String>();
            //enqSubTypeMap.put('POD provided','POD request');
            enqSubTypeMap.put('Disputed delivery','Disputed delivery scan');
            //enqSubTypeMap.put('Delayed','Delayed delivery');
            //enqSubTypeMap.put('Website technical issues','Website/app technical issues');
            //enqSubTypeMap.put('Delayed - outside networks','Delayed delivery');
            enqSubTypeMap.put('Article safe dropped unsafe location','Delivery complaint');
            enqSubTypeMap.put('Article carded - no card left','Delivery complaint');
            //enqSubTypeMap.put('Article carded - no delivery attempt','Delivery complaint');

            //Snigdha : Added for REQ1060551
            //enqSubTypeMap.put('Not receiving any letters or parcels','Unauthorised mail redirection'); 
            enqSubTypeMap.put('Not receiving any letters or parcels','Delivery complaint');

            enqSubTypeMap.put('Unauthorised MRS application','Delivery complaint');

            List<Case> caseList = new List<Case>();
            for(Case cse: [Select Id,ProductCategory__c, ProductSubCategory__c, EnquirySubType__c from Case where Id in : idList]) {
                cse.ProductSubCategory__c = !String.isBlank(cse.ProductSubCategory__c) && productSubCatMap.keySet().contains(cse.ProductSubCategory__c) ?
                        productSubCatMap.get(cse.ProductSubCategory__c) : String.isBlank(cse.ProductSubCategory__c) ? '' :cse.ProductSubCategory__c ;
                cse.ProductSubCategory__c = String.isBlank(cse.ProductSubCategory__c) && productSubCatMap.keySet().contains(cse.ProductCategory__c)  ?
                        productSubCatMap.get(cse.ProductCategory__c)  : cse.ProductSubCategory__c;
                /*cse.ProductSubCategory__c = ('Not receiving any letters or parcels'.equalsIgnoreCase(cse.EnquirySubType__c) ||
                                             'Unauthorised MRS application'.equalsIgnoreCase(cse.EnquirySubType__c) ) &&
                                            !String.isBlank(cse.ProductCategory__c) ? 'Mail redirection' :
                                            cse.ProductSubCategory__c; */
                cse.EnquirySubType__c = !String.isBlank(cse.EnquirySubType__c) && enqSubTypeMap.keySet().contains(cse.EnquirySubType__c) ?
                        enqSubTypeMap.get(cse.EnquirySubType__c) : cse.EnquirySubType__c;

                caseList.add(cse);
            }
            if(!caseList.IsEmpty()) database.update(caseList);
        }
        catch(Exception exp) {
            //log exceptions
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    SSSW_CaseClearViewMapping_ForOnline.class.getName(), 'processClearViewCodes', '', LoggingLevel.ERROR);
        }
    }


}