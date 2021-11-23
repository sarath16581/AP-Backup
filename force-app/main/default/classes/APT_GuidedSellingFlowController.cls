/**
Description: The Guided Selling page is being called from Guide Me button on Catalog Page.
This code has been provided by product team for guided selling flow.

Created By - Mausam Padhiyar
Created Date - 24th Aug,2015
 */
public with sharing class APT_GuidedSellingFlowController {
    
    //constants    
    private static final Integer searchItemsSizeLimit = 100;
    
    // parameter names
    private static final String PARAM_PRODUCT_ID = 'productId';
    private static final String PARAM_CONFIGURE = 'configure';
    private static final String PARAM_INTERVIEW_ID = 'interviewId';
    private static final String PARAM_INTERVIEW_NAME = 'interviewName';
    private static final String PARAM_CONFIG_REQUEST_ID = 'configRequestId';
    private static final String PARAM_CALLER_PAGE_ID = 'callerPage';
    private static final String PARAM_RETURN_PAGE = 'returnPage';
    private static final String PARAM_STEP = 'step';
    
    //getter/setters
    public Apttus_Config2__ProductConfiguration__c configSO {get; set;}  
    public Apttus_Proposal__Proposal__c proposal {get; set;}
    public String lookupHoverDetailUrl {get; set;}
    public String proposalPageUrl {get; set;}
    public static String doInstructions {get; set;}
    public static Boolean notFirstPage {get; set;}
    
    // default page size
    private static final Integer PAGESIZE_DEFAULT = 35;
    
    // interview steps
    private static final String STEP_BUNDLE = 'Bundle';
    private static final String STEP_OPTION = 'Option';
    private static final String STEP_RESULT = 'Result';
    
    // product configuration
    private ID configId = null;
    
    // config request
    private String configRequestId = null;
    
    // state
    
    // base controller
    @TestVisible
    private Apttus_Config2.GuidePageController base = null;
    
    // guided interview
    private transient Apttus_Config2__SearchAttributeValue__c interviewStepSO = null;
    
    // interview id
    public ID gInterviewId = null;
    
    // bundles
    @TestVisible
    private List<BundleInfo> bundles = null;
    
    // step
    @TestVisible
    private enum Step {BUNDLE, OPTION, RESULT}
    
    // current step
    @TestVisible
    private Step currStep = null;
    
    @TestVisible
    private String callerPage;
    
    public Boolean showNoRecsToDisplayError {get; set;}
    
    
    /**
     * Class Constructor
     * @param stdController the standard controller
     */
    public APT_GuidedSellingFlowController (ApexPages.StandardController stdController) {
        system.debug('!!..SFDCFlowController ' + ApexPages.currentPage().getParameters().get('interviewName'));
        
        callerPage = ApexPages.currentPage().getParameters().get(APT_Constants.URL_CALLER_PAGE);
        
        // create the base controler
        this.base = new Apttus_Config2.GuidePageController(stdController);
        system.debug(this.base);
        doInstructions = APT_Constants.LABEL_VISIBILITY_VISIBLE;
        notFirstPage = false;
        // read parameters
        
        // get the config sobject id
        this.configId = stdController.getId();
        configSO = [Select Apttus_QPConfig__Proposald__c from Apttus_Config2__ProductConfiguration__c where id = :configId limit 1];
        proposal = [Select Name, Apttus_Proposal__Proposal_Name__c, Apttus_QPApprov__Approval_Status__c, Apttus_Proposal__Approval_Stage__c From Apttus_Proposal__Proposal__c 
                    Where Id = :configSO.Apttus_QPConfig__Proposald__c limit 1];     
        
        if(APT_Utils.isPartnerUser()) {
            proposalPageUrl = APT_Constants.URL_PRM + proposal.id;
        } else {
            proposalPageUrl = APT_Constants.SEPERATOR_BACKWARD_SLASH + proposal.id;
        }
        
       
        
        // guided interview id
        String strValue = ApexPages.currentPage().getParameters().get(PARAM_INTERVIEW_ID);
        System.debug('!!..gInterviewId '+ strValue + ' this.gInterviewId is ' + this.gInterviewId);
        if (strValue != null) {
            this.gInterviewId = String.escapeSingleQuotes(strValue);                     
        }
        
        // config request id
        String configRequestIdStr = ApexPages.currentPage().getParameters().get(PARAM_CONFIG_REQUEST_ID);
        if (configRequestIdStr != null) {
            configRequestId = String.escapeSingleQuotes(configRequestIdStr);
             System.debug('!!..configRequestId '+ configRequestId);
        }
         
        // current step
        strValue = ApexPages.currentPage().getParameters().get(PARAM_STEP);
        if (strValue != null) {
            String stepName = String.escapeSingleQuotes(strValue);
            System.debug('!!..stepName '+ stepName);
            // determine step
            if (STEP_OPTION == stepName) {
                currStep = Step.OPTION;                
            } else if (STEP_RESULT == stepName) {
                currStep = Step.RESULT;                
            } else {
                currStep = Step.BUNDLE;                
            }
            
        } else {
            currStep = Step.BUNDLE;            
        }                
    }
    
    /**
     * Performs the init action
     */
    public void doInit() {
        // initialize the base controller
        base.doInit();        
        
        // update step
        setCurrentStep(currStep);
        
        showNoRecsToDisplayError = false;
        
        if (getIsOptionStep() || getIsResultStep()) {
            showNoRecsToDisplayError = true;
            
            // search bundles
            doSearchStep();            
        }        
    }
    
    /**
     * 
     * @return the product configuration id
     */
    public Id getConfigId() {   
        system.debug('!!.. getConfigId ' + this.configId);
        return this.configId;
    }
    
    /**
     * Gets the cart request id
     * @return the cart request id
     */
    public ID getRequestId() {
        system.debug('!!.. getRequestId ' + this.configRequestId);
        return this.configRequestId;        
    }
    
    /**
     * Gets the base controller
     * @return the base controller
     */
    public Apttus_Config2.GuidePageController getBase() {
        system.debug('!!.. getBase ' + base);
        return base;        
    }
    
    /**
     * Gets the guided interview id
     * @return the guided interview id
     */
    public ID getopportunityId() {
        return ApexPages.currentPage().getParameters().get(APT_Constants.URL_OPPORTUNITY_ID);        
    }
    
    /**
     * Gets the guided interview id
     * @return the guided interview id
     */
    public ID getInterviewId() {
        return base.getInterviewSO().Id;        
    }
    
    
    /**
     * Checks if the current step is the bundle step
     * @return <code>true</code> if bundle step, <code>false</code> otherwise
     */
    public Boolean getIsBundleStep() {
        system.debug('!!..getIsBundleStep ' + currStep);
        return (STEP.BUNDLE == currStep);        
    }
    
    /**
     * Checks if the current step is the option step
     * @return <code>true</code> if option step, <code>false</code> otherwise
     */
    public Boolean getIsOptionStep() {
        system.debug('!!..getIsOptionStep' + currStep);
        return (STEP.OPTION == currStep);        
    }
    
    /**
     * Checks if the current step is the result step
     * @return <code>true</code> if result step, <code>false</code> otherwise
     */
    public Boolean getIsResultStep() {
    system.debug('!!..getIsResultStep ' + currStep);
        return (STEP.RESULT == currStep);        
    }
    
    /**
     * Gets the list of bundle products from the current page in the resultset
     * @return the list of bundle info objects
     */
    public List<BundleInfo> getBundleProducts() {
        return bundles;        
    }
    
    /**
     * Checks if there are bundle products in the resultset
     * @return <code>true</code> if there are bundle products, <code<false</code> otherwise
     */
    public Boolean getHasBundleProducts() {
        return (bundles != null && !bundles.isEmpty());        
    } 
    
    /**
     * Gets the finish page
     * @return the finish page 
     */
    public PageReference getFinishPage() {
        if (notFirstPage == true) {
            doInstructions = APT_Constants.LABEL_VISIBILITY_HIDDEN;
        }
                        
        notFirstPage = true;
                
        system.debug('!!..notFirstPage ' + notFirstPage);
        //String instanceUrl = AdobeCPQSupport.getInstanceUrl();
        //String instanceUrl;
        // custom page
        //String pageName = 'GuidedSellingCustomPage';
        String pageName = APT_Constants.URL_GUIDED_SELLING_FLOW;
        
        // build the custom page url
        //String pageURL = (instanceUrl != null ? instanceUrl : '');
        String pageURL = APT_Utils.getVFPageUrlPrefix() + APT_Constants.SEPERATOR_BACKWARD_SLASH + pageName; 
        PageReference pageRef = new PageReference(pageURL);
        pageRef.getParameters().put(PARAM_CALLER_PAGE_ID, callerPage);
                    
        system.debug('!!..PARAM_INTERVIEW_NAME ' + PARAM_INTERVIEW_NAME);
        pageRef.getParameters().putAll(base.getFinishPage().getParameters());
        pageRef.getParameters().put(PARAM_INTERVIEW_NAME, APT_Constants.CASE_ORIGIN_SALESFORCE);        
        // add step name
        if (getIsBundleStep()) {
            pageRef.getParameters().put(PARAM_STEP, STEP_OPTION);            
        } else if (getIsOptionStep()) {
            pageRef.getParameters().put(PARAM_STEP, STEP_RESULT);            
        }
        //pageRef.getParameters().put(PARAM_INTERVIEW_NAME, 'VN Catg Regn Test7');
        pageRef.setRedirect(true);
            
        //System.debug(LoggingLevel.ERROR,'*** base  getFinishPage() = '+currStep+' => '+base.getInterviewSO());
        System.debug('!!..getFinishPage ' + pageRef);
        return pageRef;
    }
    
    /**
     * Performs the search step 
     */
     @TestVisible
    private void doSearchStep() {        
        // search bundles
        ApexPages.StandardSetController productSet = base.doSearchProducts(null);
        if(productSet != null) {
            // set the page size
            productSet.setPageSize(PAGESIZE_DEFAULT);
            // read bundle products
            bundles = new List<BundleInfo>();
            
            Set<ID> bdlProductIds = new Set<ID>();
            Map<ID, BundleInfo> bdlLookup = new Map<ID, BundleInfo>();
            
            for (Product2 productSO : (List<Product2>) productSet.getRecords()) {
                if(productSO.Apttus_Config2__ConfigurationType__c != APT_Constants.LABEL_LINE_TYPE_OPTION){
                    // create the product info 
                    BundleInfo bundle = new BundleInfo(productSO);
                    // add to the collection
                    bundles.add(bundle);
                    // add to the lookup
                    bdlLookup.put(productSO.Id, bundle);
                    // add to the bundle id collection to retrieve option components
                    bdlProductIds.add(productSO.Id);
                }
            }
            System.debug(LoggingLevel.ERROR,'+++ bdlProductIds dosearchstep '+bdlProductIds);       
            // read default option components
            if (!bdlProductIds.isEmpty()) {
                Map<ID, List<Apttus_Config2__ProductOptionComponent__c>> bdlComponents = base.getIncludedComponents(bdlProductIds);
                System.debug(LoggingLevel.ERROR,'+++ flow option components = '+bdlComponents);
                for (ID bundleId : bdlComponents.keySet()) {
                    // get the components for the bundle
                    List<Apttus_Config2__ProductOptionComponent__c> components = bdlComponents.get(bundleId);
                    if (components != null) {
                        // add components to the bundle
                        //bdlLookup.get(bundleId).addOptions(components);
                        
                    }
                    
                }        
            }        
        }
    }
    
    /**
     * Performs the update bundle products action 
     
    private void doUpdateStep() {
        system.debug('!!..doUpdateStep' );
        Set<ID> bdlProductIds = new Set<ID>();
        Map<ID, BundleInfo> bdlLookup = new Map<ID, BundleInfo>();
        
        for (BundleInfo bundle : bundles) {
            // clear option components
            bundle.options.clear();
            // add to the lookup
            bdlLookup.put(bundle.productSO.Id, bundle);
            // add to the bundle id collection to retrieve option components
            bdlProductIds.add(bundle.productSO.Id);
            
        }
        System.debug(LoggingLevel.ERROR,'+++ bdlProductIds doupdatestep '+bdlProductIds);       
        // read default option components
            
            if (!bdlProductIds.isEmpty()) {
                Map<ID, List<Apttus_Config2__ProductOptionComponent__c>> bdlComponents = base.getIncludedComponents(bdlProductIds);
                System.debug(LoggingLevel.ERROR,'+++ flow option components  = '+bdlComponents);
                for (ID bundleId : bdlComponents.keySet()) {
                    // get the components for the bundle
                    List<Apttus_Config2__ProductOptionComponent__c> components = bdlComponents.get(bundleId);
                    
                    if (components != null) {
                        // add components to the bundle
                        bdlLookup.get(bundleId).addOptions(components);
                        
                    }
                    
                }
                
            }
        
        
        // update step
        //setCurrentStep(null);
        
    }*/
    
    /**
     * Performs the select action
     * @return the next page reference 
     */
    public PageReference doSelect() {
        system.debug('!!..doSelect1');
        /*for (BundleInfo bundle: bundles) {
            system.debug('!!.. ' + bundle.productSO.Name);
        }*/
        String productIdStr = ApexPages.currentPage().getParameters().get(PARAM_PRODUCT_ID);
        String configureProd = ApexPages.currentPage().getParameters().get(PARAM_CONFIGURE);
        String returnPage = ApexPages.currentPage().getParameters().get(PARAM_RETURN_PAGE);
        ID productId;
        ID cartId = base.getConfigSO().Id;
        
        
        Apttus_Config2__ProductConfiguration__c cart = [select id,Apttus_QPConfig__Proposald__r.Apttus_QPConfig__PriceListId__c from Apttus_Config2__ProductConfiguration__c where id=: cartId];
        String priceListId =  cart.Apttus_QPConfig__Proposald__r.Apttus_QPConfig__PriceListId__c;
        
        Integer lineNumber;
        Boolean hasAttributes = false;
        if (productIdStr != null) {
            system.debug('!!..doSelect2');
            productId = (ID) String.escapeSingleQuotes(productIdStr);
            
            // locate the bundle
            for(BundleInfo bundle : bundles) {
                system.debug('!!..doSelect3');
                if (bundle.productSO.Id == productId) {
                    // add the bundle to the cart
                    // create the add bundle request
                    Apttus_CPQApi.CPQ.AddBundleRequestDO request = new Apttus_CPQApi.CPQ.AddBundleRequestDO();
                    
                    // add request parameters
                    request.CartId = base.getConfigSO().Id;
                    cartId = request.CartId;
                    // add bundle
                    Apttus_CPQApi.CPQ.SelectedBundleDO bundleDO = new Apttus_CPQApi.CPQ.SelectedBundleDO();
                    
                    // selected product
                    bundleDO.SelectedProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
                    
                    hasAttributes = bundle.productSO.Apttus_Config2__HasAttributes__c;
                    bundleDO.SelectedProduct.ProductId = bundle.productSO.Id;
                    bundleDO.SelectedProduct.Quantity = bundle.lineItemSO.Apttus_Config2__Quantity__c;
                    bundleDO.SelectedProduct.SellingTerm = bundle.lineItemSO.Apttus_Config2__SellingTerm__c;
                    
                    request.SelectedBundle = bundleDO;
                                                                                                                  
                    // add a bundle to the cart
                    Apttus_CPQApi.CPQ.AddBundleResponseDO result = Apttus_CPQApi.CPQWebService.addBundle(request);
                    System.debug(result);
                    System.debug('LineNumber=' + result.LineNumber);
                    lineNumber = Integer.ValueOf(result.LineNumber);
                    
                    /********************************************************************/
                    
                    if((APT_Constants.LABEL_LINE_TYPE_BUNDLE).equalsignoreCase(bundle.productSO.Apttus_Config2__ConfigurationType__c)){
                        List<Apttus_CPQApi.CPQ.SelectedOptionDO> selectedOptDOList = new List<Apttus_CPQApi.CPQ.SelectedOptionDO>();
                        //Execute the getoptionGroups API to fetch the options with option groups
                         Apttus_CPQApi.CPQ.ProductOptionGroupSearchResultDO optionGroupResult = Apttus_CPQApi.CPQWebService.getOptionGroupsForPriceListProduct(priceListId, bundle.productSO.Id);
                        //If the selected product has option groups execute the loop below
                         if(optionGroupResult.HasOptionGroups) {
                             List<Apttus_CPQApi.CPQ.ProductOptionGroupDO> prodOptGrpDOList = optionGroupResult.OptionGroups;
                             
                             
                             
                             
                             for(Apttus_CPQApi.CPQ.ProductOptionGroupDO prodOptGrpDO : prodOptGrpDOList)  {
                                
                                
                                system.debug('prodOptGrpDO-->' + prodOptGrpDO);
                                 //For an option group if a product has option components such as quantity execute the loop below
                                 if(prodOptGrpDO.HasOptionComponents)
                                 {
                                     List<Apttus_CPQApi.CPQ.ProductOptionComponentDO> prodOptCompDOList = new List<Apttus_CPQApi.CPQ.ProductOptionComponentDO>();
                                     prodOptCompDOList = prodOptGrpDO.OptionComponents;
                                    //Fetch all the option components for a particular option group.
                                     for(Apttus_CPQApi.CPQ.ProductOptionComponentDO prodOptCompDO :prodOptCompDOList )
                                     {
                                        if(prodOptCompDO.IsDefault){
                                             Apttus_CPQApi.CPQ.SelectedOptionDO selectedOptDO = new Apttus_CPQApi.CPQ.SelectedOptionDO();
                                             selectedOptDO.ComponentId = prodOptCompDO.ComponentId;
                                             selectedOptDO.ComponentProductId = prodOptCompDO.ComponentProductId;
                                             selectedOptDO.Quantity = 1;
                                             selectedOptDOList.add(selectedOptDO);
                                        }
                                     }
                                }
                            }
                        }
                        System.debug('selectedOptDOList--->' + selectedOptDOList);
                        //Invoke the addOptions API and pass the cartID, selected product line number, and the Option List retrieved from the getoptiongroups API
                        Apttus_CPQApi.CPQ.AddOptionsResponseDO addOptRespDO = Apttus_CPQApi.CPQWebService.addOptions(cartId, lineNumber, selectedOptDOList);
                    }
                    /******************************************************************/
                    
                    break;
                    
                }                
            }
            
            Apttus_Config2.ConstraintWebService2.ConstraintResult2 res = Apttus_Config2.ConstraintWebService2.applyConstraintRulesOnAddAll(base.getConfigSO().Id);
        }

        //list<Apttus_Config2__LineItem__c> lineItem = [SELECT Id FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c = : cartId 
                                                                                                        //AND Apttus_Config2__ItemSequence__c = 1
                                                                                                        //AND Apttus_Config2__LineNumber__c = : lineNumber];
        //system.debug('!!..doSelect4');
        //return pageRef;
        /*
        if(hasAttributes){
            //PageReference pr = new PageReference('https://apttus-config2.cs16.visual.force.com' + pageReferenceContext() + 'ProductAttributeDetail3');
            PageReference pr = new PageReference(APT_Utils.getVFPageUrlPrefix() + '/ProductAttributeDetail3');
            pr.getParameters().put('id', lineItem[0].Id);
            pr.getParameters().put(PARAM_CALLER_PAGE_ID, returnPage);
            pr.getParameters().put(PARAM_CONFIG_REQUEST_ID, ApexPages.currentPage().getParameters().get(PARAM_CONFIG_REQUEST_ID));
            pr.setRedirect(true);
            return pr;

        }else if(configureProd != null){
            //PageReference pr = new PageReference('https://apttus-config2.cs16.visual.force.com' + pageReferenceContext() + 'SelectConfigOptionsFilterView');
            PageReference pr = new PageReference(APT_Utils.getVFPageUrlPrefix() + '/SelectConfigOptionsFilterView');
            pr.getParameters().put('id', lineItem[0].Id);
            pr.getParameters().put(PARAM_CALLER_PAGE_ID, returnPage);
            pr.getParameters().put(PARAM_CONFIG_REQUEST_ID, ApexPages.currentPage().getParameters().get(PARAM_CONFIG_REQUEST_ID));
            pr.setRedirect(true);
            return pr;

        }else{
            // back to the catalog page
            return base.getCatalogPage();
        }
        */
        
        PageReference pg;
        
        if(callerPage != null) {            
            pg = new PageReference(APT_Utils.getVFPageUrlPrefix() + APT_Constants.SEPERATOR_BACKWARD_SLASH + APT_Constants.LABEL_NAMESPACE_CONFIG2);
        
            pg.getParameters().put(APT_Constants.URL_ID, configSO.Id);
            pg.getParameters().put(APT_Constants.URL_CONFIG_REQUEST_ID, configRequestId);
        } else {
            pg = base.getCatalogPage();
        }
        pg.getParameters().put(APT_Constants.LABEL_FLOW, APT_Constants.URL_NEW_QUOTE);
        return pg;        
    }
    
    public class SizeException extends Exception{} 

    public PageReference doCartSelected() {
        Decimal lineNumber;
        List<Apttus_Config2__LineItem__c> lineItemsToUpdate = new List<Apttus_Config2__LineItem__c>();
        
        Integer selectedItemsCount = 0;
        for (BundleInfo bundle : bundles) {
            if(bundle != null && bundle.isSelected != null && bundle.isSelected) {
                selectedItemsCount++;
            }
        }
        
        try {
            if( selectedItemsCount > searchItemsSizeLimit ) {
                throw new SizeException (APT_Constants.URL_WARNING);
            }
        } catch(Exception ex) {
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_CANNOT_ADD_MORE_THAN + searchItemsSizeLimit + APT_Constants.ERROR_PRODUCT_SAME_TIME);
            ApexPages.addMessage(errorMsg);
            return null;
        }
        
        ID cartId = base.getConfigSO().Id;
        Apttus_Config2__ProductConfiguration__c cart = [select id,Apttus_QPConfig__Proposald__r.Apttus_QPConfig__PriceListId__c from Apttus_Config2__ProductConfiguration__c where id=: cartId];
        String priceListId =  cart.Apttus_QPConfig__Proposald__r.Apttus_QPConfig__PriceListId__c;
        
        //CODE HERE
        List <Apttus_CPQApi.CPQ.SelectedProductDO> selectedProdDOList = new List <Apttus_CPQApi.CPQ.SelectedProductDO>();
        for(BundleInfo bundle : bundles) 
        {
            if(bundle != null && bundle.isSelected != null && bundle.isSelected)
        	{
        		Apttus_CPQApi.CPQ.SelectedProductDO selProdDO = new Apttus_CPQApi.CPQ.SelectedProductDO();
        		selProdDO.ProductID = bundle.productSO.Id;
        		selProdDO.Quantity = bundle.lineItemSO.Apttus_Config2__Quantity__c;
        		selProdDO.SellingTerm = bundle.lineItemSO.Apttus_Config2__SellingTerm__c;
        		selectedProdDOList.add(selProdDO);
        	}
        	lineItemsToUpdate.add(bundle.lineItemSO);
        }
        
        if(selectedProdDOList.size()>0)
        {
        	Apttus_CPQApi.CPQ.AddMultiProductRequestDO request = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO ();
        	request.CartId = cartId;
        	request.SelectedProducts = selectedProdDOList;
        	Apttus_CPQApi.CPQ.AddMultiProductResponseDO response = Apttus_CPQApi.CPQWebService.addMultiProducts(request);
        }


        Apttus_Config2.ConstraintWebService2.ConstraintResult2 res = Apttus_Config2.ConstraintWebService2.applyConstraintRulesOnAddAll(base.getConfigSO().Id);
        
        markLineItemsPricingToPending(lineItemsToUpdate);
        
        PageReference pg;
        
        if(callerPage != null) {            
            pg = new PageReference(APT_Utils.getVFPageUrlPrefix() + APT_Constants.SEPERATOR_BACKWARD_SLASH + APT_Constants.LABEL_NAMESPACE_CONFIG2);
        
            pg.getParameters().put(APT_Constants.URL_ID, configSO.Id);
            pg.getParameters().put(APT_Constants.URL_CONFIG_REQUEST_ID, configRequestId);
        } else {
            pg = base.getCatalogPage();
        }
        pg.getParameters().put(APT_Constants.LABEL_FLOW, APT_Constants.URL_NEW_QUOTE );
        return pg;
    }
    
    public PageReference doSelectAll() {
        //String configureProd = ApexPages.currentPage().getParameters().get(PARAM_CONFIGURE);
        //String returnPage = ApexPages.currentPage().getParameters().get(PARAM_RETURN_PAGE);
        //ID cartId;
        
        try {
            if( bundles.size() > searchItemsSizeLimit ) {
                throw new SizeException (APT_Constants.URL_WARNING);
            }
        } catch(Exception ex) {
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_CANNOT_ADD_MORE_THAN  + searchItemsSizeLimit + APT_Constants.ERROR_PRODUCT_SAME_TIME);
            ApexPages.addMessage(errorMsg);
            return null;
        }
        
        Decimal lineNumber;
        List<Apttus_Config2__LineItem__c> lineItemsToUpdate = new List<Apttus_Config2__LineItem__c>();
        //Boolean hasAttributes = false;

        for (BundleInfo bundle : bundles) {
            // add the bundle to the cart
            // create the add bundle request
            Apttus_CPQApi.CPQ.AddBundleRequestDO request = new Apttus_CPQApi.CPQ.AddBundleRequestDO();

            // add request parameters
            request.CartId = base.getConfigSO().Id;
            //cartId = request.CartId;
            // add bundle
            Apttus_CPQApi.CPQ.SelectedBundleDO bundleDO = new Apttus_CPQApi.CPQ.SelectedBundleDO();

            // selected product
            bundleDO.SelectedProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();

            //hasAttributes = bundle.productSO.Apttus_Config2__HasAttributes__c;
            bundleDO.SelectedProduct.ProductId = bundle.productSO.Id;
            bundleDO.SelectedProduct.Quantity = bundle.lineItemSO.Apttus_Config2__Quantity__c;
            bundleDO.SelectedProduct.SellingTerm = bundle.lineItemSO.Apttus_Config2__SellingTerm__c;

            // default options
            for (OptionInfo option : bundle.options) {
                Apttus_CPQApi.CPQ.SelectedOptionDO optionDO = new Apttus_CPQApi.CPQ.SelectedOptionDO();

                optionDO.ComponentId = option.componentId;
                optionDO.ComponentProductId = option.productSO.Id;
                optionDO.Quantity = 1;
                optionDO.SellingTerm = 1;
                // add the option to the bundle
                bundleDO.SelectedOptions.add(optionDO);
            }                                        

            request.SelectedBundle = bundleDO;
            System.debug('!!.. REQUEST ' + request);
            // add a bundle to the cart
            Apttus_CPQApi.CPQ.AddBundleResponseDO result = Apttus_CPQApi.CPQWebService.addBundle(request);
            System.debug(result);
            System.debug('!!.. LineNumber=' + result.LineNumber);
            lineNumber = result.LineNumber;
            lineItemsToUpdate.add(bundle.lineItemSO);
        }
            
        Apttus_Config2.ConstraintWebService2.ConstraintResult2 res = Apttus_Config2.ConstraintWebService2.applyConstraintRulesOnAddAll(base.getConfigSO().Id);

        //return redirectToCallerPage();
        markLineItemsPricingToPending(lineItemsToUpdate);
        
        PageReference pg;
        
        if(callerPage != null) {            
            pg = new PageReference(APT_Utils.getVFPageUrlPrefix() + APT_Constants.SEPERATOR_BACKWARD_SLASH + APT_Constants.LABEL_NAMESPACE_CONFIG2);
        
            pg.getParameters().put(APT_Constants.URL_ID, configSO.Id);
            pg.getParameters().put(APT_Constants.URL_CONFIG_REQUEST_ID, configRequestId);
        } else {
            pg = base.getCatalogPage();
        }
        pg.getParameters().put(APT_Constants.LABEL_FLOW, APT_Constants.URL_NEW_QUOTE);
        return pg;
    }
        
    /**
     * Gets the guided interview step sobject
     * @return the guided interview step sobject
     */
     @TestVisible
    private Apttus_Config2__SearchAttributeValue__c getInterviewStepSO() {
        
        if (interviewStepSO == null) {
            // get the interview sobject
            ID interviewId = getInterviewId();
            system.debug('!!..getInterviewStepSO ' + interviewId);
            List<Apttus_Config2__SearchAttributeValue__c> interviews = [SELECT Id                                                                         
                                                                        FROM Apttus_Config2__SearchAttributeValue__c
                                                                        WHERE Id = :interviewId
                                                                        LIMIT 1];
                                    
            interviewStepSO = (!interviews.isEmpty() ? interviews[0] : null);
            
        }
        
        return interviewStepSO;
        
    }
    
    /**
     * Sets the current step
     * @param currStep the current step
     */
     @TestVisible
    private void setCurrentStep(Step currStep) {        
    }
    
    
    /**
     * Wrapper class for holding bundles
     */
    public class BundleInfo {

        // state
        
        // product sobject
        public Product2 productSO {get; private set;}
        // image source
        public String imageSrc {get; private set;}
        // image style
        public String imageSizeStyle {get; private set;}
        // line item sobject
        public Apttus_Config2__LineItem__c lineItemSO {get; private set;}
        // option components
        public List<OptionInfo> options {get; private set;} 
        
        public Boolean isSelected {get; set;}
        
        /**
         * Class Constructor specifying initial values
         * @param productSO the product sobject
         */
        public BundleInfo(Product2 productSO) {
                system.debug('!!..BundleInfo');
            this.productSO = productSO;
            // create a new line item
            this.lineItemSO = new Apttus_Config2__LineItem__c(Apttus_Config2__ProductId__c = ProductSO.Id,
                                                              Apttus_Config2__Quantity__c = 1,
                                                              Apttus_Config2__SellingTerm__c = 1);
            
            // image source
            this.imageSrc = '';
            
            // create containers
            this.options = new List<OptionInfo>();
            
        }
        
        /**
         * Gets the Icon size in CSS style
         * @return the icon style
         */
        public String getIconStyleCSS() {
            
            if (imageSizeStyle == null) {
                imageSizeStyle = '';
                
            }
            
            return imageSizeStyle;
            
        }
        
        /**
         * whether to display the select button
         */
        public boolean getIsShowSelect() {
            return (!productSO.Apttus_Config2__Customizable__c && 
                    !productSO.Apttus_Config2__HasSearchAttributes__c);  
                    
        }
        
        /**
         * whether to display the configure button
         */
        public Boolean getIsShowConfigure() {
            return ((productSO.Apttus_Config2__HasOptions__c || productSO.Apttus_Config2__HasAttributes__c) && 
                    !productSO.Apttus_Config2__HasSearchAttributes__c);  
                    
        }
        
        /**
         * Add the given list of option components to the bundle
         * @param components the list of option componen sobjects to add
         */
        public void addOptions(List<Apttus_Config2__ProductOptionComponent__c> components) {
            
            System.debug('!!.. flow option components for '+productSO.Name+' = '+components);
            
            // add each option to the collection
            for (Apttus_Config2__ProductOptionComponent__c componentSO : components) {
                options.add(new optionInfo(componentSO));
                
            }
            
        }
        
    }
    
    /**
     * Wrapper class for holding options
     */
    public class OptionInfo {

        // state
        
        // product sobject
        public Product2 productSO {get; private set;}
        // option component id
        public ID componentId {get; private set;}
        
        /**
         * Class Constructor specifying initial values
         * @param componentSO the option component sobject
         */
        public OptionInfo(Apttus_Config2__ProductOptionComponent__c componentSO) {
            // create a new product sobject
            this.productSO = new Product2(Id = componentSO.Apttus_Config2__ComponentProductId__c, 
                                          Name = componentSO.Apttus_Config2__ComponentProductId__r.Name,
                                          Description = componentSO.Apttus_Config2__ComponentProductId__r.Description,
                                          Family = componentSO.Apttus_Config2__ComponentProductId__r.Family,
                                          ProductCode = componentSO.Apttus_Config2__ComponentProductId__r.ProductCode,
                                          Apttus_Config2__Uom__c = componentSO.Apttus_Config2__ComponentProductId__r.Apttus_Config2__Uom__c);
                                          
            this.componentId = componentSO.Id;
            
        }
        
    }
    
    /**
        This method will redirect to caller page
     */
    public PageReference redirectToCallerPage() {
        PageReference pg;
        
        if(callerPage != null) {
            pg = new PageReference(APT_Utils.getVFPageUrlPrefix() + APT_Constants.SEPERATOR_BACKWARD_SLASH + callerPage);
        
            pg.getParameters().put(APT_Constants.URL_ID, configSO.Id);
            pg.getParameters().put(APT_Constants.URL_CONFIG_REQUEST_ID, configRequestId);
        } else {
            pg = base.getCatalogPage();
            
        }
        pg.getParameters().put(APT_Constants.LABEL_FLOW, APT_Constants.URL_NEW_QUOTE); 
        pg.setRedirect(true);
        
        return pg;
    }
    
    /**
        This method will set pricing status on line item as pending
     */
     @TestVisible
    private void markLineItemsPricingToPending(List<Apttus_Config2__LineItem__c> lineItems) {
        for(Apttus_Config2__LineItem__c lineItem : lineItems) {
            lineItem.Apttus_Config2__PricingStatus__c = APT_Constants.LABEL_LINE_STATUS;
        }
    }
}