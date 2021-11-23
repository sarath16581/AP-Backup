/**************************************************
Description:    Contains functionality to parse and return back results to calling functions from AsynchApexContinuationController
                Objects for this class are dynamically created, use test class to test :  AsynchApexContinuationController_Test

History:
--------------------------------------------------
2008-07-01  clint.dsilva@auspost.com.au Created

**************************************************/

public with sharing virtual class ImageAPIDetails implements IAsynchApexContinuationREST {
    public virtual void setHTTPRequest(HttpRequest req,string classNameStr, String methodName, String[] params){}

    Public Integer getTimeOut(){
        return 120;
    }
    /**
    * Format the result returned form the image API so that it can be used by Lightning component ConsignmentAttachment
    *
    * @param httpResp receive the result sent by API
    */
    public Object parseResponse(HttpResponse httpResp ){
        String responseBody = httpResp.getBody();
        ImageResult ReturnVal = new ImageResult();
        string imageBody = '';
        Map<String, Object> o ;
        Map<string,Object> respObj = new Map<string,Object>() ;
        string classname = '';
        list<object> errorLst = new list<object>();
        list<object> params = new list<object>();
        try{
            respObj = (Map<string,Object>)JSON.deserializeUntyped(responseBody);
            classname = (string)respObj.get('className') ;
            errorLst = (list<object>)respObj.get('errorList');
            params = (list<object>)respObj.get('params');
            object obj = respObj.get('payload');
            string payloadStr  = (string)respObj.get('payload');
            payloadStr = string.isBlank(payloadStr)?'{}':payloadStr;
            o = (Map<String, Object>)JSON.deserializeUntyped(payloadStr);
            if(o ==  null){
                o = new Map<String, Object>();
            }
        } catch (exception e){
            // do nothing
            params = new list<string>();
            errorLst = new list<string>();
            errorLst.add( e.getMessage());

            o = new Map<String, Object>();
        }

        // always check for an error first in the request regardless of the response code.
        String error = '';
        Map<String, Object> oDocument = (Map<String, Object>)o.get('document');
        if(oDocument != null){
            Object oError  =    oDocument.get('error');
            if(oError != null){
                List<Object> listAnyObj = (List<Object>)oError;
                for(Object obj : listAnyObj ){
                    Map<string,object> errObjMap = ( Map<string,object>)obj;
                    Map<string,string> errObjMapS = new Map<string,string>();
                    for(string s : errObjMap.keySet()){
                        errObjMapS.put(s, string.valueOf(errObjMap.get(s)));
                    }
                    ReturnVal.errorMapLst.Add(errObjMapS);
                }
            } else if (httpResp.getStatusCode() >= 2000 &&   String.isEmpty(error) ) {
                //ReturnVal.errorMapLst.add(new map<string,string>( string.valueof(httpResp.getStatusCode()) ,getContinuationError(httpResp.getStatusCode()) )) ;
            } else if(httpResp.getStatusCode() >= 300 && String.isEmpty(error)) {
                // ReturnVal.errorMapLst.add(new map<string,string>( 'Error:' + string.valueof(httpResp.getStatusCode()) ,getContinuationError(httpResp.getStatusCode()) )) ;

            }

            if(!String.isEmpty(error)) {
                // do nothing
            } else {
                // grab the document if it exists in the response
                // no get prop handles null gracefully
                string sGuid  = (string)oDocument.get('object_id');
                if(sGuid == null){
                    sGuid = '';
                } else{
                    // ReJig Guid To be removed later if not required
                    // sGuid = sGuid.replaceall('.JPG$','');
                    // sGuid = sGuid.replaceall('.jpg$','');
                }
                ReturnVal.guid = sGuid;
                ReturnVal.bucketName = (string)oDocument.get('bucket_name');
                Map<String, Object> objectDetails = (Map<String, Object>)oDocument.get('object_details');
                String content = '';
                if(objectDetails != null){
                    content =  String.valueOf(objectDetails.get('object_content'));
                }
                ReturnVal.base64Image = content;
            }
        } else {
            List<Map<string,string>> errorMapLstVal = new  List<Map<string,string>>();
            Map<string,string> mtemp;
            //integer idx= 0;
            for(object  ss : errorLst){
                //idx += 1;
                mtemp = new Map<string,string>();
                mtemp.put('error' ,string.valueof(ss));
                errorMapLstVal.add(mtemp );
            }
            if(params != null && params.size() > 0) {
                ReturnVal.guid = string.valueof(params[0]);
            }
            ReturnVal.errorMapLst =  errorMapLstVal;
        }
        return  ReturnVal;
    }
    /**
    * Structure the value to return by parseResponse
    *
    */
    class ImageResult{
        List<Map<string,string>> errorMapLst {get; set;}
        string base64Image {get; set;}
        string guid {get; set;}
        string bucketName {get; set;}
        public ImageResult(){
            errorMapLst = new List<Map<string,string>>();
        }
    }
}