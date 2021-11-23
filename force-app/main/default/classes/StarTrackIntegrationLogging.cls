/**************************************************
Type:       Utility class
Purpose:    Integration logging utility class
History:
--------------------------------------------------
April 22, 2016:  Jen Karen Tan  Created
**************************************************/
public class StarTrackIntegrationLogging{

    public static Integer logListLimit = 3;

    public static void logRequestResponse(String sourceClass, String sourceFunction, String referenceId, String referenceInfo, String logMessage, Object obj){

        String logTimeStamp = logMessage;
        Map<String, Object> objMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(obj));
        // generates REQUEST log
        if (obj instanceof wwwAuspostComAuSchemaCustomercarema.SearchRequest
            || obj instanceof wwwAuspostComAuSchemaCustomercarema.CaseNotification) {
            Map<String, Object> objHeaderMap = null;
            if (obj instanceof wwwAuspostComAuSchemaCustomercarema.SearchRequest) {
                objHeaderMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(((wwwAuspostComAuSchemaCustomercarema.SearchRequest) obj).Header));
            } else {
                objHeaderMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(((wwwAuspostComAuSchemaCustomercarema.CaseNotification) obj).Header));
            }
                        
            objMap.putAll(objHeaderMap);
            Set<String> requestFieldNames = getFieldNames(objMap.keySet());
            Set<String> reqFieldNames = getFieldNames(objHeaderMap.keySet());
            requestFieldNames.addAll(reqFieldNames);
            logMessage = startAppendLogMsg('REQUEST', true);
            logMessage = appendLogMsg(requestFieldNames, objMap, logMessage);
            logMessage = endLogMsg(logMessage, true);
            
        //generates RESPONSE log
        } else if (obj instanceof wwwAuspostComAuSchemaCustomercarema.ConsignmentData) {
            
            wwwAuspostComAuSchemaCustomercarema.ConsignmentData consignmentData = (wwwAuspostComAuSchemaCustomercarema.ConsignmentData) obj;
            Integer counter = 1;

            //log for consignment search single result
            if(consignmentData.Header.NbrOfRows == 1 || consignmentData.Consignment != NULL){

                logMessage = startAppendLogMsg('RESPONSE', true);

                Set<String> responseFieldNames = getFieldNames(objMap.keySet());            
                Object consignment = objMap.get('Consignment');

                if (consignment != null) {
                    
                    logMessage += startAppendLogMsg(' Consignment', false);           
                    
                    //gets consignment fields
                    Map<String, Object> consignmentFieldMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(consignment));
                    Set<String> consignmentFields = getFieldNames(consignmentFieldMap.keySet());
                    //generates consignment log
                    logMessage = appendLogMsg(consignmentFields, consignmentFieldMap, logMessage);

                    //Article list log
                    List<wwwAuspostComAuSchemaCustomercarema.ArticleType> articleTypeList = consignmentData.Consignment.Articles != null ? consignmentData.Consignment.Articles.Article : null;
                    if (articleTypeList != null) {
                        Set<String> articleFields = ((Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(articleTypeList[0]))).keySet();
                        articleFields = getFieldNames(articleFields);
                        //article list log title
                        logMessage += startAppendLogMsg(' Articles(' + articleTypeList.size() + ')', true);
                        
                        counter = 1;
                        //generates articles log
                        for(wwwAuspostComAuSchemaCustomercarema.ArticleType resultArticle : articleTypeList){
                            Map<String, Object> articleFieldMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(resultArticle));                         
                            logMessage += appendListLog(logMessage, (' Article-' + counter), false, articleFields, articleFieldMap);
                            counter++;

                            if (counter > logListLimit && logListLimit < articleTypeList.size()) {
                                logMessage += '...  ';
                                break;
                            }
                        }
                        logMessage = endListLog(logMessage, articleTypeList);                       
                    }

                    //Event
                    if (consignmentData.Consignment.Events != null) {
                        List<wwwAuspostComAuSchemaCustomercarema.EventType> eventTypeList = consignmentData.Consignment.Events != null ? consignmentData.Consignment.Events.Event : null;
                        if (eventTypeList != null) {
                            Set<String> eventFields = ((Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(eventTypeList[0]))).keySet();
                            eventFields = getFieldNames(eventFields);
                            //event list log title
                            logMessage += startAppendLogMsg(' Events(' + eventTypeList.size() + ')', true);
                            
                            counter = 1;
                            //generates events log
                            for(wwwAuspostComAuSchemaCustomercarema.EventType resultEvent : eventTypeList){
                                Map<String, Object> eventFieldMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(resultEvent));
                                logMessage += appendListLog(logMessage, (' Event-' + counter), false, eventFields, eventFieldMap);
                                counter++;

                                if (counter > logListLimit && logListLimit < eventTypeList.size()) {
                                    logMessage += '...  ';
                                    break;
                                }
                            }
                            logMessage = endListLog(logMessage, eventTypeList);                                                 
                        }
                    }

                    //BookinNotes
                    if (consignmentData.Consignment.BookinNotes != null) {
                        List<wwwAuspostComAuSchemaCustomercarema.BookinNoteType> bookinNoteTypeList = consignmentData.Consignment.BookinNotes != null ? consignmentData.Consignment.BookinNotes.BookinNote : null;
                        if (bookinNoteTypeList != null) {
                            Set<String> bookinNotesFields = ((Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(bookinNoteTypeList[0]))).keySet();
                            bookinNotesFields = getFieldNames(bookinNotesFields);
                            //bookin notes log title
                            logMessage += startAppendLogMsg(' BookinNotes(' + bookinNoteTypeList.size() + ')', true);
                            
                            counter = 1;
                            //generates bookin notes log
                            for(wwwAuspostComAuSchemaCustomercarema.BookinNoteType resultBookinNote : bookinNoteTypeList){
                                Map<String, Object> bookinNoteFieldMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(resultBookinNote));
                                logMessage += appendListLog(logMessage, (' BookinNote-' + counter), false, bookinNotesFields, bookinNoteFieldMap);
                                counter++;

                                if (counter > logListLimit && logListLimit < bookinNoteTypeList.size()) {
                                    logMessage += '...  ';
                                    break;
                                }
                            }
                            logMessage = endListLog(logMessage, bookinNoteTypeList);                                                    
                        }
                    }

                    //SubDockets
                    if (consignmentData.Consignment.SubDockets != null) {
                        List<wwwAuspostComAuSchemaCustomercarema.SubDocketType> subdocketTypeList = consignmentData.Consignment.SubDockets != null ? consignmentData.Consignment.SubDockets.SubDocket : null;
                        if (subdocketTypeList != null) {
                            Set<String> subdocketsFields = ((Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(subdocketTypeList[0]))).keySet();
                            subdocketsFields = getFieldNames(subdocketsFields);
                            //subdockets title
                            logMessage += startAppendLogMsg(' SubDockets(' + subdocketTypeList.size() + ')', true);
                            
                            counter = 1;
                            //generates subdockets log
                            for(wwwAuspostComAuSchemaCustomercarema.SubDocketType resultSubdocket : subdocketTypeList){
                                Map<String, Object> subdocketFieldMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(resultSubdocket));
                                logMessage += appendListLog(logMessage, (' SubDocket-' + counter), false, subdocketsFields, subdocketFieldMap);
                                counter++;

                                if (counter > logListLimit && logListLimit < subdocketTypeList.size()) {
                                    logMessage += '...  ';
                                    break;
                                }
                            }
                            logMessage = endListLog(logMessage, subdocketTypeList);                                                 
                        }
                    }

                    //Proof of Deliveries
                    if (consignmentData.Consignment.ProofOfDeliveries != null) {
                        List<wwwAuspostComAuSchemaCustomercarema.ProofOfDeliveryType> proofOfDeliveryTypeList = consignmentData.Consignment.ProofOfDeliveries != null ? consignmentData.Consignment.ProofOfDeliveries.ProofOfDelivery : null;
                        if (proofOfDeliveryTypeList != null) {
                            Set<String> proofOfDeliveryFields = ((Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(proofOfDeliveryTypeList[0]))).keySet();
                            proofOfDeliveryFields = getFieldNames(proofOfDeliveryFields);
                            //proof of deliveries title
                            logMessage += startAppendLogMsg(' ProofOfDeliveries(' + proofOfDeliveryTypeList.size() + ')', true);

                            counter = 1;
                            //generates proof of deliveries log
                            for(wwwAuspostComAuSchemaCustomercarema.ProofOfDeliveryType resultProofOfDelivery : proofOfDeliveryTypeList){
                                Map<String, Object> proofOfDeliveryFieldMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(resultProofOfDelivery));
                                logMessage += appendListLog(logMessage, (' ProofOfDelivery-' + counter), false, proofOfDeliveryFields, proofOfDeliveryFieldMap);
                                counter++;

                                if (counter > logListLimit && logListLimit < proofOfDeliveryTypeList.size()) {
                                    logMessage += '...  ';
                                    break;
                                }
                            }
                            logMessage = endListLog(logMessage, proofOfDeliveryTypeList);                                                   
                        }
                    }
                    logMessage = finalizeLog(logMessage);
                } 

            //log for consignment search multiple results
            } else if(consignmentData.Header.NbrOfRows > 1){
                logMessage = startAppendLogMsg('RESPONSE', true);

                if (consignmentData.SearchResults.Results.DUPCON_DataDetail != null) {
                    List<wwwAuspostComAuSchemaCustomercarema.DUPCON_DataDetail> consignDetailList = consignmentData.SearchResults.Results.DUPCON_DataDetail;
                    if (consignDetailList != null) {
                        Set<String> consignDetailListFields = ((Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(consignDetailList[0]))).keySet();
                        consignDetailListFields = getFieldNames(consignDetailListFields);
                        //consignment title
                        logMessage += startAppendLogMsg(' ConsignmentDataDetails(' + consignDetailList.size() + ')', true);

                        counter = 1;
                        //generates consignment details log
                        for(wwwAuspostComAuSchemaCustomercarema.DUPCON_DataDetail resultConsignDetail : consignDetailList){
                            Map<String, Object> resultConsignDetailFieldMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(resultConsignDetail));                                
                            logMessage += appendListLog(logMessage, (' ConsignmentData-' + counter), false, consignDetailListFields, resultConsignDetailFieldMap);
                            counter++;

                            if (counter > logListLimit && logListLimit < consignDetailList.size()) {
                                logMessage += '...  ';
                                break;
                            }
                        }
                        logMessage = endListLog(logMessage, consignDetailList);                                                 
                    }
                }
                logMessage = finalizeLog(logMessage);
            }
        }
        
        //prevents field limit to be reached, 
        //cuts the message if over the limit
        if (logMessage.length() > 32768) {
            logMessage = logMessage.substring(0, 32767);
        }

        if (referenceId.length() > 18) {
            referenceInfo += ' (' + referenceId + ')';
            referenceId = referenceId.substring(0, 18);
        }

        //log message
        GlobalUtility.logMessage('Debug', sourceClass, sourceFunction, referenceId, referenceInfo, logTimeStamp, logMessage, null, 0);                        
    }
    
    //generates start of log message
    public static String startAppendLogMsg(String title, Boolean outerInd) {
        if (outerInd) {
            return title + ' : {';
        } else {
            return title + ' : (';                
        }
        
    }

    //generates body of log message
    public static String appendLogMsg(Set<String> fieldNames, Map<String, Object> objMap, String logMessage) {
        for (String fName : fieldNames) {
            if (fName != 'Header') {
                logMessage += ' ' + fName + '=' + objMap.get(fName) + ',';                
            }
        }
        return logMessage;
    }

    //generates log message closing brackets
    public static String endLogMsg(String logMessage, Boolean outerInd) {
        logMessage = logMessage.substring(0, logMessage.length() - 1);
        if (outerInd) {
            logMessage += ' }';
        } else {
            logMessage += ' )';
        }
        return logMessage;
    }

    //gets field names except 'type_info' fields and list fields
    public static Set<String> getFieldNames(Set<String> stringSet) {
        Set<String> fieldNames = new Set<String>();
        for (String fieldName : stringSet) {
            if (!fieldname.contains('type_info') 
                && !fieldname.contains('Articles') 
                && !fieldname.contains('Events') 
                && !fieldname.contains('SubDockets') 
                && !fieldname.contains('ProofOfDeliveries')                             
                && !fieldname.contains('BookinNotes')) {
                fieldNames.add(fieldName);
            }
        }
        return fieldNames;
    }

    //generates list log message
    public static String appendListLog(String logMessage, String logTitle, Boolean outerInd, Set<String> fieldNames, Map<String, Object> objMap) {
        logMessage = startAppendLogMsg(logTitle, outerInd);
        logMessage = appendLogMsg(fieldNames, objMap, logMessage);
        logMessage = endLogMsg(logMessage, outerInd);
        logMessage += ', ';
        return logMessage;
    }

    //generates closing bracket and removes comma and space from previous log if needed
    public static String endListLog(String logMessage, List<Object> objList) {
        if (objList.size() > 0) {
            logMessage = logMessage.substring(0, logMessage.length() - 2);
        }
        logMessage += '},';
        return logMessage;
    }

    //removes previous space/comma and add closing bracket
    public static String finalizeLog(String logMessage) {
        logMessage = logMessage.subString(0, logMessage.length() - 1);
        logMessage += '}';
        return logMessage;
    }

    public static Boolean validForLogging(StarTrack_Settings__c stSettings) {
        if (stSettings.Logging__c && stSettings.XML_Logging__c) {
            if (stSettings.Log_For__c == 'ALL USER' 
                || stSettings.Log_For__c == UserInfo.getUserId()
                || stSettings.Log_For__c == UserInfo.getUserName()
                || stSettings.Log_For__c == UserInfo.getName()) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }
    
    public static String timeNowFormatted() {
        return String.valueOf(DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
    }
}