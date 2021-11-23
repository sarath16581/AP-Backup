({
    doInit : function(component, event, helper) {
        //-- For testing to remove cache, enable once below and comment
        /*localStorage.removeItem("preCmpWizardData");
        localStorage.removeItem("chas_wizardData_encodedKey");
        sessionStorage.removeItem("authUserDataCache");
        sessionStorage.removeItem("chas_userInfo_encodedKey");*/
        
        // -- Getting User Data from sessionStorage and setting to wizard 'authUserData'
        /* if(sessionStorage.getItem("authUserDataCache") != null){
            helper.setUserInfoFromCacheToWizard(component);
            //component.set('v.authUserData',JSON.parse(sessionStorage.getItem("authUserDataCache"))); 
        }else{
            //-- enable below helper line, if wants to store UserInfo in 'session cache' before clicking on 'Login to My Post'(means onload of any wizard)
            //-- But the userinfo will be in cache for un authenticated pages (or) user will not be going to  click on 'My Post DB' case also
            ////-- Enabled this because, in Header already displaying the authenticated user name
            helper.getAndSetUserInfoToCache(component, false);
        }*/
        
        helper.getAndSetAuthUserInfoToWizard(component);
        
        //console.log('localStorage.getItem("preCmpWizardData")='+localStorage.getItem("preCmpWizardData"));
        //console.log('localStorage.getItem("chas_wizardData_encodedKey")='+localStorage.getItem("chas_wizardData_encodedKey"));


        // only storing the cacheKey in localStorage - this key is used to decrypt the wizardData stored in the Org PlatformCache
        if (localStorage.getItem("cacheKey") !=null) {
            //    if (localStorage.getItem("preCmpWizardData") !=null) {
            //-- if localstorage having 'cached wizard data and key(encrypted format)', then
            //----1.Get 'cached wizard data' from localstorage, decrypt from server and set to 'current wizardData'
            //----2. Also Query userInfo from server, encrypt this from server and set to 'sessionCache'
            // helper.setWizardDataFromCacheWithAuthUserData(component, true);

            helper.setWizardDataFromCache(component, true);
        }else{
            component.set('v.wizardData.currentPage', component.get('v.currentPage'));
            helper.navigateToPage(component, component.get('v.startPage'));
        }

    },
    handleWizardPageEvent : function(component, event, helper) {

        var currentPageData = component.get('v.pageMap')[component.get('v.currentPage')];
        var eventType = event.getParam('type');

        component.set('v.wizardData.navigationSourceType', eventType);     // -- Need in contact page renderer to navigate prev or next page
        // var currentStepNumber = event.getParam('currentStepNumber');
        if(eventType.indexOf('nav_')==0){
            var navPage = '';
            if(eventType == 'nav_next'){
                if(event.getParam('nextPage')!=null){
                    navPage = event.getParam('nextPage');
                } else if(currentPageData['next']!=null){
                    navPage = currentPageData['next'];
                }
            } else if(eventType == 'nav_prev'){
                if(event.getParam('prevPage')!=null){
                    navPage = event.getParam('prevPage');
                } else if(currentPageData['prev']!=null){
                    navPage = currentPageData['prev'];
                }
            } else if(eventType == 'nav_to'){
                if(event.getParam('gotoPage')!=null){
                    navPage = event.getParam('gotoPage');
                }
            }
        }
        if(navPage != ''){
            helper.navigateToPage(component,navPage);
        }
    },
    controllerFunction : function(component, event, helper) {
        
        //-- 1. Encode/Decode  -- bothencryption and decryption working 
        
        /*var encodedData = window.btoa('Hello, world'); // encode a string
        console.log('encodedData='+encodedData);
        var decodedData = window.atob(encodedData); // decode the string
        console.log('decodedData='+decodedData); */
        
        
        //-- 2. Base64 Encode/Decode   --- decode is not working
        /*// Create Base64 Object
        var Base64={_keyStr:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",encode:function(e){var t="";var n,r,i,s,o,u,a;var f=0;e=Base64._utf8_encode(e);while(f<e.length){n=e.charCodeAt(f++);r=e.charCodeAt(f++);i=e.charCodeAt(f++);s=n>>2;o=(n&3)<<4|r>>4;u=(r&15)<<2|i>>6;a=i&63;if(isNaN(r)){u=a=64}else if(isNaN(i)){a=64}t=t+this._keyStr.charAt(s)+this._keyStr.charAt(o)+this._keyStr.charAt(u)+this._keyStr.charAt(a)}return t},decode:function(e){var t="";var n,r,i;var s,o,u,a;var f=0;e=e.replace(/[^A-Za-z0-9+/=]/g,"");while(f<e.length){s=this._keyStr.indexOf(e.charAt(f++));o=this._keyStr.indexOf(e.charAt(f++));u=this._keyStr.indexOf(e.charAt(f++));a=this._keyStr.indexOf(e.charAt(f++));n=s<<2|o>>4;r=(o&15)<<4|u>>2;i=(u&3)<<6|a;t=t+String.fromCharCode(n);if(u!=64){t=t+String.fromCharCode(r)}if(a!=64){t=t+String.fromCharCode(i)}}t=Base64._utf8_decode(t);return t},_utf8_encode:function(e){e=e.replace(/rn/g,"n");var t="";for(var n=0;n<e.length;n++){var r=e.charCodeAt(n);if(r<128){t+=String.fromCharCode(r)}else if(r>127&&r<2048){t+=String.fromCharCode(r>>6|192);t+=String.fromCharCode(r&63|128)}else{t+=String.fromCharCode(r>>12|224);t+=String.fromCharCode(r>>6&63|128);t+=String.fromCharCode(r&63|128)}}return t},_utf8_decode:function(e){var t="";var n=0;var r=c1=c2=0;while(n<e.length){r=e.charCodeAt(n);if(r<128){t+=String.fromCharCode(r);n++}else if(r>191&&r<224){c2=e.charCodeAt(n+1);t+=String.fromCharCode((r&31)<<6|c2&63);n+=2}else{c2=e.charCodeAt(n+1);c3=e.charCodeAt(n+2);t+=String.fromCharCode((r&15)<<12|(c2&63)<<6|c3&63);n+=3}}return t}}
        
        // Define the string
        var string = 'Hello World!';
        
        // Encode the String
        var encodedString = Base64.encode(string);
        console.log(encodedString); // Outputs: "SGVsbG8gV29ybGQh"
        
        // Decode the String
        var decodedString = Base64.decode(encodedString);
        console.log(decodedString); // Outputs: "Hello World!" */
        
        //-- 3. AES Script file loaded, but showing 'CryptoJS' is undefined
        /*console.log('***AES scripts loaded successfully.....');
        console.log('***CryptoJS='+CryptoJS);
        var encrypted = CryptoJS.AES.encrypt("Message", "Secret Passphrase").toString();
        //U2FsdGVkX18ZUVvShFSES21qHsQEqZXMxQ9zgHy+bu0=
        console.log('*** encrypted:'+encrypted);
        
        var decrypted = CryptoJS.AES.decrypt(encrypted, "Secret Passphrase");
        console.log('wizardData='+ decrypted.toString(CryptoJS.enc.Utf8));*/
    }
})