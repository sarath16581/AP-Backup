/**************************************************
Description:    Controller Class for Lightning components AsynchApexContinuationBroker and AsynchApexContinuationProxy
                Function Invoke dynamically instantiates objects that implement IAsynchApexContinuationREST or IAsynchApexContinuationSOAP
History:
--------------------------------------------------
2008-07-01  clint.dsilva@auspost.com.au Created
2020-09-08  lija.jawahar@auspost.com.au modified getVFBaseURL- Stabilize URLs for Visualforce
2022-09-16  naveen.rajanna@auspost.com.au INC2035054 incorporate new visual force url post enhanced domain
2023-08-28  Naveen Rajanna  REQ3286437 - Changed api version and removed hard coded URL to use apex methods to generate URL
**************************************************/

global with sharing class AsynchApexContinuationController {
    class errorException extends Exception{}

    public AsynchApexContinuationController() {}
    /**
    * Get base URl of Visualforce page
    *
    */
    @AuraEnabled
    public static URLConfig getVFBaseURL() {
        URLConfig urlConfig = new URLConfig();
        List<Network> newtwork = [SELECT Name, UrlPathPrefix FROM Network WHERE Id =: Network.getNetworkId() LIMIT 1];
        system.debug('urlConfig newtwork: '+newtwork);
         //System.debug( '-----------'+System.currentPageReference().getHeaders().get('Referer')  );
        if(newtwork.size() > 0){
            // access the Network for community implementations
            Network net = newtwork.get(0);
            PageReference landing = Network.communitiesLanding();
            // grab the landing page for full url
            String url1 = landing.getUrl();
            urlConfig.UrlPathPrefix = net.UrlPathPrefix;
            // regex to get the main domain for the site
            Pattern urlPattern = Pattern.compile('http(s)?://.*?(.)?([^:/?]+)');
            Matcher match = urlPattern.matcher(url1);
            match.find();
            // set the base url/main domain found with regex matcher
            urlConfig.baseURL = match.group();
            system.debug('urlConfig newtwork urlConfig: '+urlConfig);
            return urlConfig;
        } else {
            // LJ 08/09/2020
            // As a result of the critical update - 'Stabilize URLs for Visualforce, Experience Builder, Site.com Studio, and Content Files'
            // Instance name will be removed from URL and Visualforce.com replaces visual.force.com
            system.debug('urlConfig internal 1: ');
            User user = [SELECT fullPhotoUrl FROM User WHERE userType = 'Standard' LIMIT 1];
            List<String> fragments = user.fullPhotoUrl.split('\\.');
            string strFrag0 = fragments[0];
            strFrag0 = strFrag0 != null?strFrag0.toLowerCase():'';
           /* if(!Util.runningInASandbox) {
                urlConfig.baseURL =  strFrag0 + '--c.vf.force.com';
            } else {
                urlConfig.baseURL =  strFrag0 + '--c.sandbox.vf.force.com';
            }*/
            urlConfig.baseURL = 'https://'+System.DomainCreator.getVisualforceHostname(null);

        }

        system.debug('urlConfig 2: '+urlConfig);
        return urlConfig;

    }


    public with sharing class URLConfig{
        @AuraEnabled public String baseURL ;
        @AuraEnabled public String UrlPathPrefix ;
    }

    /**
    * Remove Call function called from VF page to invoke the API
    *
    * @param classNameStr name of class to create object from. Class must implement either IAsynchApexContinuationREST or IAsynchApexContinuationSOAP
    * @param methodName name of method to execute or this can be  a placeholed used within if statement to execute code
    * @param params array of params used by function methodName
    * @param useAsynchCallout if true continuation is used
    */
    @RemoteAction
    global static Object invoke(string classNameStr, String methodName, String[] params, boolean useAsynchCallout) {

        list<string> mystr =  new list<string>();
        IAsynchApexContinuationREST restObj;
        IAsynchApexContinuationSOAP soapObj;

        Type imgTyp = Type.forName(classNameStr);
        if(imgTyp != null  ){
            object objTmp = imgTyp.newInstance();
            if(objTmp instanceof IAsynchApexContinuationREST) {
                restObj = (IAsynchApexContinuationREST)objTmp;
                soapObj = null;
            } else if (objTmp instanceof IAsynchApexContinuationSOAP){
                soapObj = (IAsynchApexContinuationSOAP)objTmp;
                restObj = null;
            }
        } else{
            throw new errorException('Class name is not valid. Class needs to implement either IAsynchApexContinuationREST or IAsynchApexContinuationSOAP');
        }

        if(useAsynchCallout ){
            if(restObj != null){
                HttpRequest req = new HttpRequest();
                restObj.setHTTPRequest(req,classNameStr, methodName, params);
                // Create a Continuation for the HTTPRequest
                integer iTimeOut = restObj.getTimeOut();
                Continuation con = new Continuation(iTimeOut);
                statInfo sInfo = new  statInfo();
                sInfo.continuationId = con.addHttpRequest(req);
                sInfo.params = params;
                sInfo.className = classNameStr;
                sInfo.methodName = methodName;
                con.state = sInfo;
                con.continuationMethod = 'restCallback';
                return con;
            } else if (soapObj != null){
                Continuation con = new Continuation(soapObj.getTimeOut());
                soapObj.invokeContinuation(con, methodname,params);
                con.continuationMethod = 'soapCallback';
                return con;
            }
        } else{
            if(restObj != null){
                Http http = new Http();
                HttpRequest reqRst = new HttpRequest();
                restObj.setHTTPRequest(reqRst,classNameStr, methodName, params);
                HTTPResponse res = http.send(reqRst);
                ReturnObj rtnObj = new  ReturnObj();
                rtnObj.className = classNameStr;
                rtnObj.methodName = methodName;
                rtnObj.params = params;
                rtnObj.payload = res.getBody();
                res.setBody(JSON.serialize(rtnObj));
                return restObj.parseResponse(res);
            } else if (soapObj != null){
                //ToDO in future:  implementation of non-continuation SOAP calls
            }
        }
        return null;
    }

    /**
    * Callback of continuation function for SOAP calls
    *
    * @param state State objects of continuation
    */
    global static object soapCallback(Object state){
        object obj;

        string className = (string)getDynamicPropertyFromObject(state,'className');
        IAsynchApexContinuationSOAP soapObj;
        if(!string.isBlank(className) ){
            Type rtnTypeObj = Type.forName(className);
            if(rtnTypeObj != null){
                soapObj = (IAsynchApexContinuationSOAP)rtnTypeObj.newInstance();
                obj = soapObj.continuationMethod(state);
            } else {
                throw new errorException('Class name is not valid. Class needs to implement IAsynchApexContinuationSOAP');
            }
        } else {
            throw new errorException('cannot create object for response object , since class name is blank');
        }
        return obj;
    }

    /**
    *Dynamically get property "Eg: Class name"  from object 
    *
    * @param state State objects of continuation
    */
    global static object getDynamicPropertyFromObject(Object obj, string propertyName){
        Map<String, Object> objM = new Map<String, Object>();
        String strObj =  JSON.serialize(obj);
        objM = (Map<String, Object>)JSON.deserializeUntyped(strObj);
        return objM.get(propertyName);
    }

    /**
    * Callback of continuation function for REST calls
    *
    * @param state State objects of continuation
    */
    global static object  restCallback(Object state){
        system.debug('restCallback'+state);
        Object rtn = null;
        statInfo sInfo = (statInfo)state;
        ReturnObj rtnObj = new  ReturnObj();
        rtnObj.className = sInfo.className;
        rtnObj.methodName = sInfo.methodName;
        rtnObj.params = sInfo.params;
        rtnObj.payload = null;

        HttpResponse response = Continuation.getResponse(sInfo.continuationId);
        string encodingUsed = 'Content-Encoding:' +  response.getHeader('Content-Encoding') + ', transferEncodeing:' + response.getHeader('Transfer-Encoding');
        List<string> headerKeys = response.getHeaderKeys() ;
        Integer statusCode = response.getStatusCode();
        string sError = '';
        system.debug('response'+response);
        if (statusCode >= 2000) {
            rtnObj.errorList.add( 'Error: ' +  getContinuationError(statusCode) );
        }

        IAsynchApexContinuationREST restObj;

        Type imgTyp = Type.forName(sInfo.className);
        if(imgTyp != null){
            restObj = (IAsynchApexContinuationREST)imgTyp.newInstance();

        } else{
            //raise error not valid type
            rtnObj.errorList.add('Error: Invalid class: Class needs to inherit from IAsynchApexContinuationREST ');
        }
        system.debug('rtnObj'+rtnObj);
        if(restObj != null){
            if(rtnObj.errorList.size() > 0){
                rtnObj.payload = '';
            } else{
                rtnObj.payload = response.getBody();
            }
            response.setBody(JSON.serialize(rtnObj));
            rtn =  restObj.parseResponse(response);
        }
        system.debug('rtn'+rtn);
        return rtn;
    }
    /**
    * Common continuation Errors
    *
    * @param statusCode Display error code for statusCode value
    */
    @TestVisible private static String getContinuationError(Integer statusCode) {
        Map<Integer, String> errors = new Map<Integer, String>();
        errors.put(2000,'The timeout was reached, and the server didn’t get a chance to respond.');
        errors.put(2001,'There was a connection failure.');
        errors.put(2002,'Exceptions occurred.');
        errors.put(2003,'The response hasn’t arrived (which also means that the Apex asynchronous callout framework hasn’t resumed).');
        errors.put(2004,'The response size is too large (greater than 1 MB).');

        if(errors.get(statusCode) == null) {
            return String.valueOf(statusCode) + ': An error occurred.';
        } else {
            return errors.get(statusCode);
        }
    }

    /**
    * Class used to create state value in continuation
    *
    */
    global class statInfo{
        public string continuationId {get;set;}
        public string className {get;set;}
        public string methodName {get;set;}
        public object obj {get;set;}
        public list<String> params  {get;set;}
        public statInfo(){
            params = new list<String>();
        }
    }

    /**
    * Class to wrap return value of API sent through continuation
    *
    */
    global class ReturnObj{
        public list<String> errorList {get;set;}
        public string className {get;set;}
        public string methodName {get;set;}
        public object payload {get;set;}
        public list<String> params  {get;set;}

        public ReturnObj(){
            errorList = new list<String>();
        }
    }
}