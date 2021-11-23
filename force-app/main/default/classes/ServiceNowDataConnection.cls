/*@File Name		: ServiceNowDataConnection
@Description 		: Datasource connection class to define apex logic on operations on external object like sync, 
query and dml operations
@Author			: Ramtej Juloori
@Created			: 26/06/2018

================================ Modification Log =============================== 
Developer Name 	Date 			Comments

*/
global without sharing class ServiceNowDataConnection extends DataSource.Connection {

    Private AusPostSettings__c connectionDetails = AusPostSettings__c.getInstance('ServiceNowCredentials');
    private String instanceEndPoint = connectionDetails.URL__c;
    private String username = connectionDetails.Username__c;
    private String password = connectionDetails.Password__c;

    /*******************************************************************************************************
     * @method name		: ServiceNowDataConnection
     * @description 		: ServiceNowDataConnection constructor
     * @parameters		: DataSource.ConnectionParams
     * @returns 			: NA
     */
    global ServiceNowDataConnection() {}
    global ServiceNowDataConnection(DataSource.ConnectionParams connectionParams) {

    }

    /*******************************************************************************************************
* @method name		: sync
* @description 		: Standard method to get the schema from the externals source (service now) and create external object
in salesforce when external data source is synced with salesforce
* @parameters		: NA
* @returns 			: List<DataSource.Table>
*/
    //Method commented since schema is created manually and no sync is required
    override global List < DataSource.Table > sync() {
        List < DataSource.Table > tables = new List < DataSource.Table > ();
        /*List<DataSource.Column> incidentColumns = new List<DataSource.Column>();
incidentColumns.add(DataSource.Column.text('ExternalId', 255));
incidentColumns.add(DataSource.Column.url('DisplayUrl'));
//callout to service now to get the schema of specified object name and get the field info in a wrapper class
Map<String, SchemaColumn> schemaColumns = new Map<String, SchemaColumn>();//getIncidentSchema('sn_customerservice_case');
//iterate over the wrapper class and create DataSource.Column (field info) to creat external object in salesforce
for(SchemaColumn col : schemaColumns.values()) {
String label = capitalizeWords(col.name.replace('_', ' '));
if(col.dataType == 'GUID' || col.dataType == 'string') {
DataSource.Column column = DataSource.Column.text(col.name, col.maxLength);
column.label = label;
column.filterable = true;
incidentColumns.add(column);
} else if(col.dataType == 'glide_date_time') {
DataSource.Column column = DataSource.Column.get(col.name, label, '', true, true, DataSource.DataType.DATETIME_TYPE, 0);
incidentColumns.add(column);
} else if(col.dataType == 'reference' || col.dataType == 'glide_list') {
DataSource.Column column = DataSource.Column.text(col.name, 255);
column.label = label;
column.filterable = false;
incidentColumns.add(column);
} else if(col.dataType == 'integer') {
DataSource.Column column = DataSource.Column.number(col.name, 18, 0);
column.label = label;
column.filterable = true;
incidentColumns.add(column);
} else if(col.dataType == 'boolean') {
DataSource.Column column = DataSource.Column.boolean(col.name);
column.label = label;
column.filterable = true;
incidentColumns.add(column);
}

}
tables.add(DataSource.Table.get('service_now_case', 'Service Now Cases', incidentColumns));*/
        return tables;
    }

    /*******************************************************************************************************
     * @method name		: query
     * @description 		: Standard method to make callout, transform the response and present in salesforce when external object is queried.
     * @parameters		: DataSource.QueryContext
     * @returns 			: DataSource.TableResult
     */
    override global DataSource.TableResult query(DataSource.QueryContext context) {
        try {
            List < Map < String, Object >> queryResults = new List < Map < String, Object >> ();
            string sysparamLimit = '';
            //build select string to get the fields to be displayed using DataSource.ColumnSelection from the context, add id field in service now by default
            String displayFields = 'sys_id';
            //set limits for the number of records to be returned from service now
            if (context.maxResults != 0) {
                sysparamLimit = '&sysparm_limit=' + context.maxResults;
            }

            //select API name in service now for the corresponsing external object selected in salesforce
            string selectedTable = '';
            HTTP h = new HTTP();
            //Logic to handle when Service now case comment is queried
            if (context.tableSelection.tableSelected == 'Service Now Case Comment') {
                //Build where query string using the context
                string sysParamQuery = buildQueryStringforCaseComments(new List < DataSource.Filter > {
                        context.tableSelection.filter
                }, sysparamLimit);
                //Comments are by default sorted according to date and User cannot apply external order clause
                if (context.tableSelection.order != null && context.tableSelection.order.size() > 0) {
                    throw new DataSource.DataSourceException('By default case comments are sorted by latest comment and cannot specify order clause.');
                }
                //Fields to be retrieved
                displayFields += ',element_id,sys_created_on,sys_created_by,value,sys_id';
                //Form the final end point
                string endPoint = instanceEndPoint+'/api/now/table/sys_journal_field?sysparm_query=' + sysParamQuery + '&sysparm_fields=' + displayFields;
                system.debug('#service now comment endPoint' + endPoint);
                HTTPRequest httpReq = request(endPoint, 'application/json', 'GET');
                HTTPResponse resp = h.send(httpReq);

                system.debug('#HANS query resp.getBody()' + resp.getBody());
				//Get result from the response returned
                Map < String, Object > jsonResults = (Map < String, Object > ) JSON.deserializeUntyped(resp.getBody());
                List < Object > result = (List < Object > ) jsonResults.get('result');

                for (Object row: result) {
                    Map < String, Object > item = (Map < String, Object > ) row;
                    //Pushing sys_id value to ExternalId field
                    item.put('ExternalId', item.get('sys_id'));
                    //Push element_id to Case look up field
                    item.put('Service_Now_Case', item.get('element_id'));
                    queryResults.add(item);
                }
                //Return Table result
                return DataSource.TableResult.get(context, queryResults);
            } else if (context.tableSelection.tableSelected == 'service_now_case') {
                System.Debug('TWO CALLS: 1');
                system.debug('context.tableSelection.filter '+context.tableSelection.filter);
                ///build where clause acceptable by service now API using List<DataSource.Filter> from the context
                String sysparm_query = buildQueryStringforCase(new List < DataSource.Filter > {
                        context.tableSelection.filter
                });
                system.debug('sysparm_query built '+sysparm_query);
                //build order by string acceptable by service now API using List<DataSource.Order> from the context
                String OrderByString = buildOrderByString(context.tableSelection.order);
                String qs = '';
                //set offset value for the query firing to Service now
                string sysparamOffset = '';
                if (context.offset != 0) {
                    sysparamOffset = '&sysparm_offset=' + context.offset;
                }
                //concetanate query and orderby string
                if (sysparm_query != '') {
                    qs = '&sysparm_exclude_reference_link=true&sysparm_query=' + EncodingUtil.urlEncode(sysparm_query, 'UTF-8') + '^' + OrderByString;
                } else {
                    qs = '&sysparm_exclude_reference_link=true&sysparm_query=' + EncodingUtil.urlEncode(sysparm_query, 'UTF-8') + OrderByString;
                }
                displayFields += ',number,account.u_account_number,u_third_party_reference';
                for (DataSource.ColumnSelection colSel: context.tableSelection.ColumnsSelected) {
                    if (string.valueOf(colSel.aggregation) != 'NONE') {
                        throw new DataSource.DataSourceException('Aggregate queries cannot be used on external objects.');
                    }
                    if (displayFields == '') {
                        displayFields += colSel.columnName;
                    } else {
                        displayFields += ',' + colSel.columnName;
                    }
                }
                system.debug('displayFields '+displayFields);
                selectedTable = 'sn_customerservice_case';
                //callout to service now to get records from the specified object
                string endPoint = instanceEndPoint + '/api/now/table/' + selectedTable + '?' + qs + sysparamOffset + sysparamLimit + '&sysparm_fields=' + displayFields + '&sysparm_display_value=true';
                Long t1 = System.currentTimeMillis();

                HTTPRequest httpReq = request(endPoint, 'application/json', 'GET');
                HTTPResponse resp = h.send(httpReq);

                System.Debug('>>> THE TIMER RESULT: ' + (System.currentTimeMillis() - t1));
                system.debug('endpoint ' + endPoint);
                Integer statusCode = resp.getStatusCode();
                system.debug(' response body ' + JSON.deserializeUntyped(resp.getBody()));
                system.debug('statusCode '+statusCode);
                if (statusCode == 200) {
                    //parse response and transform the response data to DataSource.TableResult
                    Map < String, Object > jsonResults = (Map < String, Object > ) JSON.deserializeUntyped(resp.getBody());
                    List < Object > result = (List < Object > ) jsonResults.get('result');
                    for (Object row: result) {
                        Map < String, Object > item = (Map < String, Object > ) row;
                        //Push sys_id value to ExternalId field
                        item.put('ExternalId', item.get('sys_id'));
                        //Push third party reference value to appropriate lookup field based on record Id
                        if (item.get('u_third_party_reference') != null && item.get('u_third_party_reference') != '') {
                            String objectName = ServiceNowUtility.findObjectNameFromRecordIdPrefix((string) item.get('u_third_party_reference'));
                            system.debug('objectName objectName '+objectName+' u_third_party_reference '+item.get('u_third_party_reference'));
                            if (objectName == 'Lodgement_Customer_Migration__c') {
                                item.put('Lodgement_Customer_Migration', item.get('u_third_party_reference'));
                            }
                            else if(objectName == 'Account'){
                                item.put('Account', item.get('u_third_party_reference'));
                            }
                            //Set Url to the record in third party reference field
                            sobject thirdParty = ServiceNowUtility.getNameByIdUtility((string) item.get('u_third_party_reference'));
                            if(thirdParty != null && thirdParty.get('Name') != null){
                            	item.put('u_third_party_reference', '<html><a href=/' + item.get('u_third_party_reference') + ' target="_blank">' + thirdParty.get('Name') + '</a></html>');    
                            }
                        }
                        //Get Account number, query billing Account and display link to the appropriate record in Billing Account field
                        if (item.containsKey('account.u_account_number')) {
                            string accountNumber = (string) item.get('account.u_account_number');
                            List < Billing_Account__c > billingAccountNumbers = [SELECT Id, Name, LEGACY_ID__c FROM Billing_Account__c WHERE LEGACY_ID__c =: accountNumber LIMIT 1];
                            if (!billingAccountNumbers.isEmpty()) {
                                item.put('Billing_Account_Lookup', (string) billingAccountNumbers.get(0).Id);
                                item.put('account.u_account_number', '<html><a href=/' + billingAccountNumbers.get(0).Id + ' target="_blank">' + billingAccountNumbers.get(0).LEGACY_ID__c + '</a></html>');
                            }
                        }
                        queryResults.add(item);
                    }
                    system.debug(' DataSource.TableResult.get(context, queryResults) '+DataSource.TableResult.get(context, queryResults));
                    return DataSource.TableResult.get(context, queryResults);
                } else {
                    //Error handling in case of failed status
                    throw new DataSource.DataSourceException(resp.getBody());
                }
            } else {
                //throw new DataSource.DataSourceException(resp.getBody());
                return null;
            }
        } catch (exception ex) {
            system.debug('error ' + ex.getMessage() + ' at line ' + ex.getStackTraceString());
            throw new DataSource.DataSourceException('Cannot connect to Service Now. Please try again.');
        }
    }

    /*******************************************************************************************************
* @method name		: upsertRows
* @description 		: Standard method to make callout, transform the response and present in salesforce when records in
external object is inserted or updated.
* @parameters		: DataSource.UpsertContext
* @returns 			: List<DataSource.UpsertResult>
*/
    override global List < DataSource.UpsertResult > upsertRows(DataSource.UpsertContext context) {
        system.debug('[ServiceNowDataConnection] : upsertRows() tableSelected' + context.tableSelected);
        List < DataSource.UpsertResult > results = new List < DataSource.UpsertResult > ();
        //transform the upserted rows from DataSource.UpsertContext into generic objects
        List < Map < String, Object >> rows = new List < Map < String, Object >> (); //reverseNormaliseRows(context.rows);
        rows = context.rows;
        //seperate callout for each records since service now API doesn't supports dml operation on multiple records by default
        HttpResponse response;
        //Upsert logic for service now case object
        if (context.tableSelected == 'service_now_case') {
            //upsertMethod(instanceEndPoint + '/api/sn_customerservice_case/salesforce_lightning_connect/create_case', 'application/json', JSON.serialize(context.rows),'POST');
            for (Map < String, Object > row: rows) {
                string selectedTable = 'sn_customerservice_case';
                //identify if the operation is update or insert and route to proper callout method
                if (row.get('ExternalId') == null) {
                        //response = upsertMethod(instanceEndPoint + '/api/now/table/'+selectedTable, 'application/json', JSON.serialize(row),'POST');
                        Map < string, Object > createCaseBody = new Map < string, Object > ();
                    	//Since account.u_account_number should be modified as u_account_number a new map is set to post as body to the request
                        createCaseBody.put('u_account_number', context.rows[0].get('account.u_account_number'));
                        createCaseBody.put('u_classification', context.rows[0].get('u_classification'));
                        createCaseBody.put('u_case_type', context.rows[0].get('u_case_type'));
                        createCaseBody.put('short_description', context.rows[0].get('short_description'));
                        createCaseBody.put('description', context.rows[0].get('description'));
                        createCaseBody.put('product', context.rows[0].get('product'));
                        createCaseBody.put('u_third_party_reference', context.rows[0].get('u_third_party_reference'));
                        createCaseBody.put('u_contact_details', context.rows[0].get('u_contact_details'));
                        createCaseBody.put('assignment_group', context.rows[0].get('assignment_group'));
                        createCaseBody.put('assigned_to', context.rows[0].get('assigned_to'));
                        createCaseBody.put('watch_list', context.rows[0].get('watch_list'));
                        createCaseBody.put('contact_type', context.rows[0].get('contact_type'));
                        createCaseBody.put('priority', context.rows[0].get('priority'));
                        createCaseBody.put('state', context.rows[0].get('state'));
                        system.debug('createBody ' + JSON.serialize(createCaseBody));
                        system.debug('context.rows[0] ' + JSON.serialize(context.rows[0]));
                        string endPoint = instanceEndPoint + '/api/sn_customerservice/salesforce_lightning_connect/create_case';
                        system.debug('endPoint ' + endPoint);
                        response = upsertMethod(endPoint, 'application/json', JSON.serialize(createCaseBody), 'POST');

                } else {
                    response = upsertMethod(instanceEndPoint + '/api/now/table/' + selectedTable + '/' + row.get('ExternalId'), 'application/json', JSON.serialize(row), 'PUT');
                }
                system.debug('response befire obj ' + response);
                Map < String, Object > obj = (Map < String, Object > ) JSON.deserializeUntyped(response.getBody());
                system.debug('complete obj ' + obj);
                Map < string, Object > objResponseResult = (Map < string, Object > ) obj.get('result');
                //Catch standard service now errors
                if((Map < string, Object > ) obj.get('error') != null){
                    Map < string, Object > errorMap = (Map < string, Object > ) obj.get('error');
                    DataSource.UpsertResult upsertResult = DataSource.UpsertResult.failure('', string.valueOf(errorMap.get('message')));
                    results.add(upsertResult);
                }
                //Success case returned by createCase API 
                else if (objResponseResult.get('status') == 'Success') {
                    Map < String, Object > result = (Map < String, Object > ) obj.get('result');
                    results.add(DataSource.UpsertResult.success(String.valueOf(result.get('sys_id'))));
                } else if (objResponseResult.get('status') == 'Failure') { //Failed case returned by createCase API 
                    DataSource.UpsertResult upsertResult = DataSource.UpsertResult.failure('', string.valueOf(objResponseResult.get('error_details')));
                    results.add(upsertResult);
                }

            }
        } else if (context.tableSelected == 'Service Now Case Comment') { //Upsert logic for service now case comment object
            system.debug('#HANS [ServiceNowDataConnection] : upsertRows() in Service_Now_Case_Comment');
            string selectedTable = 'sn_customerservice_case';

            for (Map < String, Object > row: rows) {

                system.debug('#HANS[ServiceNowDataConnection] : upsertRows()in Service_Now_Case_Comment row ' + JSON.serialize(row));
				//Create request body to create case comment
                Map < string, Object > createCaseBody = new Map < string, Object > ();
                createCaseBody.put('comments', row.get('value'));
                system.debug('#HANS[ServiceNowDataConnection] : upsertRows()in Service_Now_Case_Comment createCaseBody' + JSON.serialize(createCaseBody));
				//Form final End point including service now case externalId
                String endpoint = instanceEndPoint + '/api/now/table/' + selectedTable + '/' + row.get('Service_Now_Case') + '?sysparm_display_value=true&sysparm_fields=sys_id,u_third_party_reference,comments';

                system.debug('@HANS: -' + endpoint);

                response = upsertMethod(
                        endpoint,
                        'application/json',
                        JSON.serialize(createCaseBody),
                        'PUT');

                system.debug('#HANS[ServiceNowDataConnection] : upsertRows()in Service_Now_Case_Comment response' + response);

                Map < String, Object > obj = (Map < String, Object > ) JSON.deserializeUntyped(response.getBody());
                if (response.getStatusCode() == 201 || response.getStatusCode() == 200) {
                    //transfor the response into DataSource.UpsertResult
                    Map < String, Object > result = (Map < String, Object > ) obj.get('result');
                    system.debug('case comment result '+result);
                    results.add(DataSource.UpsertResult.success(String.valueOf(result.get('sys_id'))));
                } else if (obj.get('error') != null) { 
                    //error handling
                    Map < String, Object > error = (Map < String, Object > ) obj.get('error');
                    results.add(DataSource.UpsertResult.failure(String.valueOf(row.get('ExternalId')), response.getStatusCode() + ', Message: ' + String.valueOf(error.get('detail')) + ' - ' + String.valueOf(error.get('message'))));
                }
            }
        }
        //Return empty results in case of DML on invalid object 
        return results;
    }

    /*******************************************************************************************************
     * @method name		: buildQueryStringforCase
     * @description 		: method to form service now API friendly where query when service now case is queried.
     * @parameters		: List<DataSource.Filter>
     * @returns 			: String
     */
    private String buildQueryStringforCase(List < DataSource.Filter > filters) {
        if (filters[0] != null && filters.size() > 0) {
            //get the  mapping of operator symbols between service now and salesforce
            Map < string, ServiceNowUtility.operatorCompare > operatorMap = ServiceNowUtility.getOperatorMap();
            
            if (!operatorMap.get(string.valueOf(filters[0].Type)).FilterType) {
                return createcompareString(filters[0], operatorMap);
            } else {
                //transform salesforce where query to service now API friendly where query string by changing operator symbols and filter structure and diving
                //into two levels of filters
                string tempCompareOp = string.valueOf(filters[0].Type) == 'OR_' ? 'OR_Filter' : string.valueOf(filters[0].Type);
                string formQuery = '';
                for (DataSource.Filter filter: filters[0].Subfilters) {
                    if (!operatorMap.get(string.valueOf(filter.Type)).FilterType) {
                        if (formQuery == '') {
                            formQuery += createcompareString(filter, operatorMap);
                        } else {
                            formQuery += operatorMap.get(tempCompareOp).SNType + createcompareString(filter, operatorMap);
                        }
                    } else {
                        string tempformQuery = '';
                        for (DataSource.Filter innerfilter: filter.subfilters) {
                            if (!operatorMap.get(string.valueOf(innerfilter.Type)).FilterType) {
                                if (tempformQuery == '') {
                                    tempformQuery += createcompareString(innerfilter, operatorMap);
                                } else {
                                    tempformQuery += operatorMap.get(string.valueOf(filter.Type)).SNType + createcompareString(innerfilter, operatorMap);
                                }
                            } else {
                                //throw error if SOQL has filters nested at more than 2 levels
                                throw new DataSource.DataSourceException('Query too complex.');
                            }
                        }
                        if (formQuery == '') {
                            formQuery += tempformQuery;
                        } else {
                            formQuery += operatorMap.get(tempCompareOp).SNType + tempformQuery;
                        }
                    }
                }
                return formQuery;
            }

        } else {
            return '';
        }
    }
    /*******************************************************************************************************
     * @method name		: buildQueryStringforCaseComments
     * @description 		: method to form service now API friendly where query when service now case comment is queried.
     * @parameters		: List<DataSource.Filter>
     * @returns 			: String
     */
    private String buildQueryStringforCaseComments(List < DataSource.Filter > filters, String recordsLimit) {
        system.debug('#HANS [ServiceNowDataConnection] : filters' + filters);
        if (filters[0] != null) {
            if (filters.size() == 1) {
                //get the  mapping of operator symbols between service now and salesforce
            	Map < string, ServiceNowUtility.operatorCompare > operatorMap = ServiceNowUtility.getOperatorMap();
                if (operatorMap.get(string.valueOf(filters[0].Type)).FilterType) {
                    throw new DataSource.DataSourceException('Filter can only be applied on case Id.');
                } else {
                    // filtering with lookup field
                    if (filters[0].columnName == 'Service_Now_Case') {
                        return 'element_id=' + filters[0].columnValue + '^element=comments^ORDERBYDESCsys_created_on&sysparm_limit=' + recordsLimit;
                    } else if (filters[0].columnName == 'ExternalId') {
                        // filtering with external id
                        return 'sys_id=' + filters[0].columnValue;
                    } else {
                        throw new DataSource.DataSourceException('Filter can only be applied on case Id.');
                    }
                }
            } else {
                throw new DataSource.DataSourceException('Filter can only be applied on case Id.');
            }
        } else {
            throw new DataSource.DataSourceException('Please specify a case Id for the comments to be retrieved.');
        }
    }
    /*******************************************************************************************************
* @method name		: createcompareString
* @description 		: method to get a basic formatted string involving a simple filter comparing a field and a value.
* @parameters		: DataSource.Filter, Map<string,OperatorCompare__mdt> (OperatorCompare__mdt --> metadata to map operator
symbols in salesforce and service now)
* @returns 			: String
*/
    private string createcompareString(DataSource.Filter filter, Map < string, ServiceNowUtility.operatorCompare > operatorMap) {
        string tempColName = filter.columnName;
        string tempColValue = (string) filter.columnValue;
        //replace ExternalId with sys_id
        if (filter.columnName == 'ExternalId') {
            tempColName = 'sys_id';
        } else if (filter.columnName == 'Lodgement_Customer_Migration') {//replace Lodgment customer migration with Third Party reference
            tempColName = 'u_third_party_reference';
        } else if(filter.columnName == 'Account'){
            tempColName = 'u_third_party_reference';
        } else if (filter.columnName == 'Billing_Account_Lookup') {//replace Billing Account Lookup to Lookup
            tempColName = 'account.u_account_number';
            Billing_Account__c billingAccountNumber = [SELECT Id, Name, LEGACY_ID__c FROM Billing_Account__c WHERE Id =: tempColValue LIMIT 1];
            if (billingAccountNumber != null) {
                tempColValue = billingAccountNumber.LEGACY_ID__c;
            }
        }
        return tempColName + operatorMap.get(string.valueOf(filter.Type)).SNType + tempColValue;
    }

    /*******************************************************************************************************
     * @method name		: buildOrderByString
     * @description 		: method to get string which defines the sorting of the records queried in service now API format.
     * @parameters		: List<DataSource.Order>
     * @returns 			: String
     */
    private string buildOrderByString(List < DataSource.Order > orderBy) {
        string OrderByString = '';
        if (orderBy != null && orderBy.size() > 0) {
            for (DataSource.Order orderElements: orderBy) {
                string tempString = '^';
                if (OrderByString == '') {
                    tempString = '';
                }
                if (string.valueOf(orderElements.direction) == 'ASCENDING') {
                    OrderByString += tempString + 'ORDERBY' + orderElements.columnName;
                } else {
                    OrderByString += tempString + 'ORDERBYDESC' + orderElements.columnName;
                }
            }
        }
        return OrderByString;
    }

    /*******************************************************************************************************
     * @method name		: getIncidentSchema
     * @description 		: method to callout to service now to get the schema of the specified service now object.
     * @parameters		: string
     * @returns 			: Map<String, SchemaColumn>
     */
    //Method commented due to the change in structure to avoid schema call
    /*public Map<String, SchemaColumn> getIncidentSchema(string objectNameToSync) {
Map<String, SchemaColumn> output = new Map<String, SchemaColumn>();
String incidentSchemaEndPoint = instanceEndPoint + '/'+objectNameToSync+'.do?SCHEMA';
HTTP h = new HTTP();
HTTPRequest httpReq = request(incidentSchemaEndPoint, 'application/json','GET');
HTTPResponse resp = h.send(httpReq);
//iterate through the response and form the wrapper object
Dom.Document doc = resp.getBodyDocument();
Dom.XMLNode incident = doc.getRootElement();
List<Dom.XmlNode> nodes = incident.getChildElements();
for(Dom.XmlNode node : nodes) {
String name = node.getAttribute('name', null);
if (name == 'sys_id')
continue;

String dataType = node.getAttribute('internal_type', null);
String maxLength = node.getAttribute('max_length', null);

SchemaColumn c = new SchemaColumn();
c.name = name;
c.dataType = dataType;
c.maxLength = Integer.valueOf(maxLength);

output.put(c.name, c);
}
return output;
}*/

    /*******************************************************************************************************
     * @method name		: request
     * @description 		: generic method to perform callouts to service now
     * @parameters		: string, String, String
     * @returns 			: HTTPRequest
     */
    private HTTPRequest request(String endPoint, String contentType, string reqMethod) {
        HTTPRequest r = new HTTPRequest();
        r.setEndpoint(endPoint);
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        r.setHeader('Authorization', authorizationHeader);
        if (!String.isEmpty(contentType)) {
            r.setHeader('Accept', contentType);
            r.setHeader('Content-Type', contentType);
        }
        r.setMethod(reqMethod);
        return r;
    }



    /*******************************************************************************************************
     * @method name		: upsertMethod
     * @description 		: generic method to perform callout when a record is updated or inserted
     * @parameters		: String, String, String, String
     * @returns 			: HttpResponse
     */
    private HttpResponse upsertMethod(String endPoint, String contentType, String postBody, string methodType) {
        system.debug('entered into save');
        HTTP h = new HTTP();
        HTTPRequest r = request(endPoint, contentType, methodType);
        r.setBody(postBody);
        HTTPResponse resp = h.send(r);
        return resp;
    }

}