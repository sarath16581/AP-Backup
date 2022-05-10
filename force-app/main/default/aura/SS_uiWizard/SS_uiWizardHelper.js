/*
 * * Modified by   : 24/03/2021 : Hara Sahoo : Include header for Thank You page
 * */
({
    navigateToPage : function(component, page) {
        var pages = component.get('v.pageMap');
        var pageData = pages[page];
        if(component.get("v.enableWebAnalytics")){
            this.logSiteAnalytics(component, component.get('v.name') , pageData['key']);
        }
        console.log(component.getReference('v.wizardData'));
        var compAttributes = {
            "wizardData": component.getReference('v.wizardData'),
            "wizardPageEvent" : component.getReference("c.handleWizardPageEvent"),
            "nextPage" : pageData['next'],
            "prevPage" : pageData['prev'],
            "gotoPages" : pageData['gotoPages'],
            "currentStepNumber" : pageData['step'],
            "firstWordInProgressBar" : component.getReference('v.firstWordInProgressBar'),         // added by Jansi
            "pageTitle" : component.getReference('v.pageTitle') ,                                  // added by Jansi 05 Jun 2018 - to have dynamic page title common to every cmp in wizard
            "authUserData" : component.getReference('v.authUserData'),                             // added by Jansi 05 July 2018 - to have dynamic page title common to every cmp in wizard
            "currentStepName" : pageData['currentStepName'],                                       // added by Jansi 09 Aug 2018 for analytics 
            "stage" : pageData['stage'],                                                           // added by Jansi 09 Aug 2018 for analytics
            'analyticsPageViewAutoTracking': (pageData.hasOwnProperty('analyticsPageViewAutoTracking') ? pageData['analyticsPageViewAutoTracking'] : true) // added by Nathan Franklin 06/09. If the key doesn't exist, the default value is true
        };
        if (pageData['currentStepName'] == 'thankyou'){
            component.set('v.wizardData.showHeaderForThankYouPage', true);
        }
        if(!pageData['next'] && !pageData['prev']){                                            
            component.set('v.wizardData.isHideForm', true);
        }else{
            component.set('v.wizardData.isHideForm', false);
        }
        
        var attributes = pageData['attributes']
        if (attributes !=null) {
            for (var attrname in attributes) { compAttributes[attrname] = attributes[attrname]; }
        }
        component.set('v.wizardData.currentPage',pageData['key']);           //  // added by Jansi to set the currentpage, to use wheneveer return back from other wizard
        
        $A.createComponent(
            pageData['name'],
            compAttributes,
            function(pageCmp,status, errorMessage){
                var body = component.get("v.body");
                component.set("v.body", [pageCmp]);
                //component.set("v.currentPage", page);
                // TODO: Generate Nxav Control Footer!
            }
        );
        
    },
    
    setWizardDataFromCache: function(component, navigate){
        //console.log('setWizardDataFromCache...');
        //-- 1. Decrypting 'cached Wizard Data' from Server


        var action = component.get("c.decryptData");

        //action.setParams({
        //    "encodedData" :localStorage.getItem("preCmpWizardData"),
        //    "cacheKey" :localStorage.getItem("cacheKey")}
        //    );

        action.setParams({ "cacheKey" :localStorage.getItem("cacheKey")});
        //console.log('setWizardDataFromCache: cacheKey from localStorage: ' + localStorage.getItem("cacheKey"));
        //console.log('setWizardDataFromCache: preCmpWizardData from localStorage: ' + localStorage.getItem("preCmpWizardData"));

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //console.log('setWizardDataFromCache:cached wizard data  decrypt Success');
                
                if(response.getReturnValue() != null){

                    //console.log('setWizardDataFromCache.decryptData SUCCESS response :' +response.getReturnValue());

                    //-- 1.a. If encrypt success, then setting cached wizardData to current 'WizardData'
                    //--- and display the current page as from cached data
                    component.set('v.wizardData',JSON.parse(response.getReturnValue()) );
                    component.set('v.startPage',component.get('v.wizardData.currentPage'));
                    component.set('v.currentPage',component.get('v.wizardData.currentPage'));
                    
                    //-- 1.a.1 Removing cached wizardData and its encrypted key
                    //-- removing localstorage wizardData
                    //localStorage.removeItem("preCmpWizardData");

                    // added for platform cache
                    localStorage.removeItem("cacheKey");
                    
                    //-- removing localstorage encoded key
                    // localStorage.removeItem("chas_wizardData_encodedKey");
                    
                    //-- 1.a.2 Query loggedIn user info, encrypt it and set to session storage
                    //-- calling to get and set Logged in User info
                    //this.getAndSetUserInfoToCache(component, navigate);
                    //

                    //-- Navigating to the page
                    this.navigateToPage(component, component.get('v.startPage'));
                }else{
                    if(navigate){
                        //-- 1.b. If encrypt fails in server side, then allowing user to show default start page
                        component.set('v.wizardData.currentPage', component.get('v.currentPage'));
                        this.navigateToPage(component, component.get('v.startPage'));   
                    }
                }
                
            } else if (state === "INCOMPLETE") {
                console.log('setWizardDataFromCacheWithAuthUserData  decrypt INCOMPLETE');
            } else if (state === "ERROR") {
                console.log('setWizardDataFromCacheWithAuthUserData decrypt  ERROR');
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("setWizardDataFromCacheWithAuthUserData Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
        
    },
    
    getAndSetAuthUserInfoToWizard: function(component){
       //-- 1. Query User Info from Server and store in session storage with encrypted format
        var action = component.get("c.getLoggedInUserInfo");
        action.setStorable();  //-- Added on Aug 07 2018
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnObj =  JSON.parse((JSON.stringify(response.getReturnValue())));
                console.log('User authentication status='+JSON.stringify(response.getReturnValue()));
                //-- 1.a Checking If User is authenticated
                if(returnObj["isUserAuthenticated"] == true){
                    
                    //-- 1.a.1 remove userInfo from sessioncache if have
                    /*if(sessionStorage.getItem("authUserDataCache")!= null){
                        sessionStorage.removeItem("authUserDataCache");
                    }*/
                    //--1.a.2 remove user info encode key from sessioncache if have 
                    // if(sessionStorage.getItem("chas_userInfo_encodedKey")!= null){
                    //sessionStorage.removeItem("chas_userInfo_encodedKey");
                    //}
                    
                    //--1.a.2 setting latest userInfo to wizard attribute
                    component.set('v.authUserData.loggedInUserFullName', returnObj["userFullName"]);
                    component.set('v.authUserData.loggedInUserEmail',returnObj["userEmail"]);
                    component.set('v.authUserData.loggedInUserPhone',returnObj["userPhone"]);
                    component.set('v.authUserData.userContactEmail',returnObj["userContactEmail"]);
                    component.set('v.authUserData.userContactPhone',returnObj["userContactPhone"]);
                    component.set('v.authUserData.userFirstName',returnObj["userFirstName"]);
                    component.set('v.authUserData.userLastName',returnObj["userLastName"]);
                    component.set('v.authUserData.userContactFirstName',returnObj["userContactFirstName"]);
                    component.set('v.authUserData.userContactLastName',returnObj["userContactLastName"]);
                    component.set('v.authUserData.isUserAuthenticated',true);
                    if(returnObj["userContactPhone"] == null){
                        component.set('v.authUserData.isUserPhoneEmpty',true);
                    }
                    //-- 1.a.3 set latest queryed user Info to 'SessionCache' after encryption
                    // this.encryptUserDataAndSetToCache(component, navigate);
                    
                }else{
                    /*if(navigate){
                        //-- 1.b. If quesry userino fails in server side, then allowing user to show default start page
                        component.set('v.wizardData.currentPage', component.get('v.currentPage'));
                        this.navigateToPage(component, component.get('v.startPage'));   
                    }*/
                }
                
            }
            else if (state === "INCOMPLETE") {
                console.log("INCOMPLETE : Error from service Call");
            }
                else if (state === "ERROR") {
                    component.set('v.wizardData.caseCreationStatus', 'ERROR');
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            //-- Console log
                            if(component.get("v.debugMode")){
                                console.log("Error message: " + errors[0].message);
                            }
                        }
                    } else {
                        //-- Console log
                        if(component.get("v.debugMode")){
                            console.log("Unknown error");
                        }
                    }
                }
            
        });
        $A.enqueueAction(action);
        
    },
    
    /* encryptUserDataAndSetToCache : function(component,navigate){
        //console.log('encryptUserDataAndSetToCache='+component.get('v.authUserData'));
        var action = component.get("c.encryptData");
        action.setParams({ "inputData" : JSON.stringify(component.get('v.authUserData')) });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //console.log('encryptUserDataAndSetToCache  Success==>');//+response.getReturnValue());
                //-- if encrypt success from server setting to session cache
                if(response.getReturnValue() != null){
                    console.log('encryptUserDataAndSetToCache success');
                    var returnObj =  JSON.parse((JSON.stringify(response.getReturnValue())));
                    //console.log('returnObj["encodedKey"]='+returnObj["encodedKey"]);
                    //console.log('returnObj["encodedData"]='+returnObj["encodedData"]);
                    //-- storing User Data in session storage
                    sessionStorage.setItem("authUserDataCache",  returnObj["encodedData"]); 
                    //sessionStorage.setItem("chas_userInfo_encodedKey",   returnObj["encodedKey"]); 
                }
                
                if(navigate){
                    //-- Navigating to the page
                    this.navigateToPage(component, component.get('v.startPage'));
                } else{
                    
                }               
                
            } else if (state === "INCOMPLETE") {
                console.log('encryptUserDataAndSetToCache  INCOMPLETE');
            } else if (state === "ERROR") {
                console.log('encryptUserDataAndSetToCache  ERROR');
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("encryptUserDataAndSetToCache Error message: " + errors[0].message);
                    }
                } else {
                    console.log("encryptUserDataAndSetToCache Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    }, */
    
    /* setUserInfoFromCacheToWizard: function(component){
        console.log('setUserInfoFromCacheToWizard');
        var action = component.get("c.decryptData");
        action.setParams({ "encodedData" :sessionStorage.getItem("authUserDataCache")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //console.log('setUserInfoFromCacheToWizard  decrypt Success');
                if(response.getReturnValue() != null){
                    component.set('v.authUserData',JSON.parse(response.getReturnValue()));
                }else{
                    //-- nothing to do 
                }
                
            } else if (state === "INCOMPLETE") {
                console.log('setUserInfoFromCacheToWizard  INCOMPLETE');
            } else if (state === "ERROR") {
                console.log('setUserInfoFromCacheToWizard decrypt  ERROR');
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log(" setUserInfoFromCacheToWizard Error message: " + errors[0].message);
                    }
                } else {
                    console.log("setUserInfoFromCacheToWizard Unknown error");
                }
            }
        });
        $A.enqueueAction(action);  
    },*/
    
    cacheAuthenticatedDetails: function(component, returnObj){   // -- Not using this function
        //-- Checking If User is authenticated
        /*if(returnObj["isUserAuthenticated"] != null){
            component.set('v.authUserData.loggedInUserFullName', returnObj["userFullName"]);
            component.set('v.authUserData.loggedInUserEmail',returnObj["userEmail"]);
            component.set('v.authUserData.loggedInUserPhone',returnObj["userPhone"]);
            component.set('v.authUserData.userContactEmail',returnObj["userContactEmail"]);
            component.set('v.authUserData.userContactPhone',returnObj["userContactPhone"]);
            component.set('v.authUserData.userFirstName',returnObj["userFirstName"]);
            component.set('v.authUserData.userLastName',returnObj["userLastName"]);
            component.set('v.authUserData.userContactFirstName',returnObj["userContactFirstName"]);
            component.set('v.authUserData.userContactLastName',returnObj["userContactLastName"]);
            component.set('v.authUserData.isUserAuthenticated',true);
            
            //-- remove and set in cache
            var authUserDatavar = component.get('v.authUserData');
            if(sessionStorage.getItem("authUserDataCache")!= null){
                sessionStorage.removeItem("authUserDataCache");
            }
            
            sessionStorage.setItem("authUserDataCache",  JSON.stringify(authUserDatavar)); 
            
        }*/
        
    }
})