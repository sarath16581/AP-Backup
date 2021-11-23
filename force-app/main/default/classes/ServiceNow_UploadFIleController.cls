/**
 * Created by hasantha on 10/5/19.
 */

public without sharing class ServiceNow_UploadFIleController {

    // retrieve the credentials from auspost custom setting (use of existing mechanism as in the initial development)
    Private static AusPostSettings__c connectionDetails = AusPostSettings__c.getInstance('ServiceNowCredentials');
    private static String instanceEndPoint = connectionDetails.URL__c;
    private static String username = connectionDetails.Username__c;
    private static String password = connectionDetails.Password__c;

    //mapping file extensions and mime types used while converting attachment to files and vice versa, only supported for PDF, JPEG and DOC
    public static final map<string,string> mimeTypeMapping = new map<string,string>{
            'jpg' => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'pdf' => 'application/pdf',
            'doc' => 'application/msword',
            'docx' => 'application/msword',
            'xlsx' => 'application/vnd.ms-excel'
    };

    /**
     * save the file, file will be created and saved for the first time, then the file id will be returned,
     * from the next chunk onwards it will be redirected to append method.
     *
     * @param fileName
     * @param base64Data
     * @param contentType
     *
     * @return
     */
    @AuraEnabled
    public static Id saveTheFile(String fileName, String base64Data, String contentType) {
        // create a content version
        ContentVersion fileRec = new ContentVersion();
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        fileRec.VersionData = EncodingUtil.base64Decode(base64Data);
        fileRec.pathonClient = contentType;
        // decide the pathon client based on the type received
        for(string filext :mimeTypeMapping.keySet()){
            if(mimeTypeMapping.get(filext) == contentType){
                fileRec.pathonClient = fileName.substringBefore('.')+'.'+filext;
            }
        }
        fileRec.Title = fileName;
        fileRec.IsMajorVersion = false;
        Database.SaveResult insertResults = Database.insert(fileRec);

        return fileRec.Id;
    }


    /**
     * save the chunk, when the file has multiple chunks this will keep appending the chunks to the same file till the end
     *
     * @param parentId
     * @param fileName
     * @param base64Data
     * @param contentType
     * @param fileId
     *
     * @return
     */
    @AuraEnabled
    public static Id saveTheChunk(String fileName, String base64Data, String contentType, String fileId) {
        // aha! no fileId, so I can save it now
        if (fileId == '') {
            fileId = saveTheFile( fileName, base64Data, contentType);
        } else {
            // oh! there's more chunks let's keep appending
            appendToFile(fileId, base64Data);
        }

        return Id.valueOf(fileId);
    }

    /**
     * grab the existing file and keep appending
     *
     * @param fileId
     * @param base64Data
     */
    private static void appendToFile(Id fileId, String base64Data) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        // grab the file with the Id
        ContentVersion cv = [SELECT Id, Pathonclient, VersionData, FileExtension, Title FROM ContentVersion WHERE Id =: fileId];
        // get the body as a string so that we can append more
        String existingBody = EncodingUtil.base64Encode(cv.VersionData);
        // append the next chunk received
        cv.VersionData = EncodingUtil.base64Decode(existingBody + base64Data);
        // update the appended file
        update cv;
    }

    /**
     * prepare and call the attachment/file servicenow endpoint
     *
     * @param attachId
     *
     * @return
     */
    @AuraEnabled
    public static boolean uploadToServNow(String attachId, String parentId){
        // pull the document
        ContentVersion attachment = [SELECT Id, Pathonclient, VersionData, FileExtension, Title, ContentDocumentId FROM ContentVersion WHERE Id =: attachId];

        // prepare the request
        HTTP h = new HTTP();
        string endPoint = instanceEndPoint+'/api/now/attachment/file?table_name=sn_customerservice_case&table_sys_id='+parentId+'&file_name='+attachment.Title;
        HTTPRequest httpReq = request(endPoint, 'application/json', 'POST', attachment.Pathonclient);
        httpReq.setBodyAsBlob(attachment.VersionData);

        // ignore for test
        if(Test.isRunningTest()){
            return true;
        }
        // send the response
        HTTPResponse resp = h.send(httpReq);

        //read the response
        system.debug('### RESPONSE '+resp.getBody());

        //Get result from the response returned
        Map < String, Object > jsonResults = (Map < String, Object > ) JSON.deserializeUntyped(resp.getBody());

        // result received from serv now
        Map < String, Object > result = (Map < String, Object > ) jsonResults.get('result');

        // if the response is a success, delete the file in salesforce
        if(String.isNotEmpty(result.get('file_name').toString())) {
            delete [SELECT Id FROM ContentDocument WHERE Id =:attachment.ContentDocumentId];
            return true;
        }
        return false;
    }

    /**
     * prepare the request
     *
     * @param endPoint
     * @param contentType
     * @param reqMethod
     * @param fileType
     *
     * @return
     */
    private static HTTPRequest request(String endPoint, String contentType, string reqMethod, String fileType) {
        HTTPRequest request = new HTTPRequest();
        request.setEndpoint(endPoint);
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);

        request.setHeader('Authorization', authorizationHeader);
        if (!String.isEmpty(contentType)) {
            request.setHeader('Accept', contentType);
            request.setHeader('Content-Type', fileType);
        }
        request.setMethod(reqMethod);
        return request;
    }

}