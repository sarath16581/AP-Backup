/*@File Name        : ServiceNowDataConnectionTest
@Description        : Apex class to test ServiceNowDataConnection
@Author             : Ramtej Juloori
@Created            : 31/10/2018

================================ Modification Log =============================== 
Developer Name  Date            Comments

*/ 
@isTest
public class ServiceNowDataConnectionTest {
    /*******************************************************************************************************
     * @method name		: setMock
     * @description 		: method to setMock for the callouts to be made in test methods in the class
     * @parameters		: string, string
     * @returns 			: StaticResourceCalloutMock
     */
    @testsetup
    public  static void setupData(){
        AusPostSettings__c auspostSettings = new AusPostSettings__c();
        auspostSettings.Name = 'ServiceNowCredentials';
        auspostSettings.URL__c = 'TestURL';
        auspostSettings.Username__c = 'TestUserName';
        auspostSettings.Password__c = 'TestPassword';
        insert auspostSettings;
    }
        
    /*******************************************************************************************************
     * @method name		: setMock
     * @description 		: method to setMock for the callouts to be made in test methods in the class
     * @parameters		: string, string
     * @returns 			: StaticResourceCalloutMock
     */
    public static StaticResourceCalloutMock setMock(string staticResourceName, integer statusCode){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        //Set static resource name
        mock.setStaticResource(staticResourceName);
        //set status code for response
        mock.setStatusCode(statusCode);
        mock.setHeader('Content-Type', 'application/json');
        return mock;
    }
        
	/*******************************************************************************************************
     * @method name		: testSync
     * @description 		: method to test sync method of ServiceNowDataConnection class
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void testSync(){
        AusPostSettings__c connectionDetails = new AusPostSettings__c();
        connectionDetails.Name = 'ServiceNowCredentials';
        connectionDetails.URL__c = 'TestURL';
        connectionDetails.Username__c = 'TestUserName';
        connectionDetails.Password__c = 'TestPassword';
        insert connectionDetails;
        ServiceNowDataConnection dataCon = new ServiceNowDataConnection();
        dataCon.sync();
    }
    
    /*******************************************************************************************************
     * @method name		: testQueryMethodForServiceNowCaseSingleFilter
     * @description 		: method to test Query method for servicenow case with single filter
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void testQueryMethodForServiceNowCaseSingleFilter(){
		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, setMock('ServiceNowCaseQuerySuccessMock',200));
        //set table for the rows to be returned
        DataSource.Column column = DataSource.Column.get('description','label','',true,true,DataSource.DataType.STRING_SHORT_TYPE,50);
        List<DataSource.Column> columns = new List<DataSource.Column>{column};
        DataSource.Table table = DataSource.Table.get('Service_Now_Case__x','ExternalId',columns);
        List<DataSource.table> tables = new List<DataSource.table>{table};
        //Add fields for SELECT clause
        DataSource.ColumnSelection columnSelected = new DataSource.ColumnSelection();
        columnSelected.aggregation = DataSource.QueryAggregation.NONE;
        columnSelected.columnName = 'description';
        columnSelected.tableName = 'Service_Now_Case__x';
        List<DataSource.ColumnSelection> columnsSelected = new List<DataSource.ColumnSelection>{columnSelected};
        DataSource.TableSelection tableSelection = new DataSource.TableSelection();
        tableSelection.tableSelected = 'service_now_case';
        tableSelection.columnsSelected = columnsSelected;
        //set filters for the table selected in query
        DataSource.Filter filter1 = new DataSource.Filter();
        filter1.columnName = 'ExternalId';
        filter1.columnValue = 'testValue';
        filter1.Type = DataSource.FilterType.EQUALS;
        tableSelection.filter = filter1;
        //set queryContext for query
        DataSource.QueryContext queryContext = DataSource.QueryContext.get(tables,5,5,tableSelection);
        Test.startTest();
        try{
            ServiceNowDataConnection dataCon = new ServiceNowDataConnection();
        	dataCon.query(queryContext);
        }
        catch(exception ex){
            system.debug('exception ex '+ex.getMessage()+' at line '+ex.getStackTraceString());
        }
        Test.stopTest();
    }
    
    /*******************************************************************************************************
     * @method name		: testQueryMethodForServiceNowCaseSingleFilterAggException
     * @description 		: method to test Query method for servicenow case with single filter with aggregate exception
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void testQueryMethodForServiceNowCaseSingleFilterAggException(){
		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, setMock('ServiceNowCaseQuerySuccessMock',200));
        //set table for the rows to be returned
        DataSource.Column column = DataSource.Column.get('description','label','',true,true,DataSource.DataType.STRING_SHORT_TYPE,50);
        List<DataSource.Column> columns = new List<DataSource.Column>{column};
        DataSource.Table table = DataSource.Table.get('Service_Now_Case__x','ExternalId',columns);
        List<DataSource.table> tables = new List<DataSource.table>{table};
        //Add fields for SELECT clause
        DataSource.ColumnSelection columnSelected = new DataSource.ColumnSelection();
        columnSelected.aggregation = DataSource.QueryAggregation.COUNT;
        columnSelected.columnName = 'description';
        columnSelected.tableName = 'Service_Now_Case__x';
        List<DataSource.ColumnSelection> columnsSelected = new List<DataSource.ColumnSelection>{columnSelected};
        DataSource.TableSelection tableSelection = new DataSource.TableSelection();
        tableSelection.tableSelected = 'service_now_case';
        tableSelection.columnsSelected = columnsSelected;
        //set filters for the table selected in query
        DataSource.Filter filter1 = new DataSource.Filter();
        filter1.columnName = 'ExternalId';
        filter1.columnValue = 'testValue';
        filter1.Type = DataSource.FilterType.EQUALS;
        tableSelection.filter = filter1;
        //set queryContext for query
        DataSource.QueryContext queryContext = DataSource.QueryContext.get(tables,5,5,tableSelection);
        Test.startTest();
        try{
            //catch aggregation exception
            ServiceNowDataConnection dataCon = new ServiceNowDataConnection();
        	dataCon.query(queryContext);
        }
        catch(exception ex){
            system.debug('exception ex '+ex.getMessage()+' at line '+ex.getStackTraceString());
        }
        Test.stopTest();
    }
    
    /*******************************************************************************************************
     * @method name		: testQueryMethodForServiceNowCaseMultipleFilter
     * @description 		: method to test Query method for servicenow case with multiple filters
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void testQueryMethodForServiceNowCaseMultipleFilter(){
		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, setMock('ServiceNowCaseQuerySuccessMock',200));
        //set table for the rows to be returned
        DataSource.Column column = DataSource.Column.get('description','label','',true,true,DataSource.DataType.STRING_SHORT_TYPE,50);
        List<DataSource.Column> columns = new List<DataSource.Column>{column};
        DataSource.Table table = DataSource.Table.get('Service_Now_Case__x','ExternalId',columns);
        List<DataSource.table> tables = new List<DataSource.table>{table};
        //Add fields for SELECT clause
        DataSource.ColumnSelection columnSelected = new DataSource.ColumnSelection();
        columnSelected.aggregation = DataSource.QueryAggregation.NONE;
        columnSelected.columnName = 'description';
        columnSelected.tableName = 'Service_Now_Case__x';
        List<DataSource.ColumnSelection> columnsSelected = new List<DataSource.ColumnSelection>{columnSelected};
        DataSource.TableSelection tableSelection = new DataSource.TableSelection();
        tableSelection.tableSelected = 'service_now_case';
        tableSelection.columnsSelected = columnsSelected;
        //set filters for the table selected in query
        DataSource.Filter filter1 = new DataSource.Filter();
        filter1.columnName = 'Lodgement_Customer_Migration';
        filter1.columnValue = 'testValue';
        filter1.Type = DataSource.FilterType.EQUALS;
        DataSource.Filter filter2 = new DataSource.Filter();
        filter2.columnName = 'Billing_Account_Lookup';
        filter2.columnValue = 'testValue';
        filter2.Type = DataSource.FilterType.EQUALS;
        DataSource.Filter filter3 = new DataSource.Filter();
        filter3.columnName = 'description';
        filter3.columnValue = 'testValue';
        filter3.Type = DataSource.FilterType.EQUALS;
        DataSource.Filter filter4 = new DataSource.Filter();
        //join filter2 and filter3 from OR condition and form filter4
        filter4.Type = DataSource.FilterType.OR_;
        filter4.subfilters = new List<DataSource.Filter>{filter2,filter3};
        DataSource.Filter filter = new DataSource.Filter();
        filter.Type = DataSource.FilterType.OR_;
        //join filter1 and filter4 from OR condition and form main filter
        filter.subfilters = new List<DataSource.Filter>{filter1,filter4};
        tableSelection.filter = filter;
        //set order
        DataSource.Order order = DataSource.Order.get('Service_Now_Case__x','description',DataSource.OrderDirection.ASCENDING);
        tableSelection.Order = new List<DataSource.Order>{order};
        //set queryContext for query
        DataSource.QueryContext queryContext = DataSource.QueryContext.get(tables,5,5,tableSelection);
        Test.startTest();
        try{
            //catch aggregation exception
            ServiceNowDataConnection dataCon = new ServiceNowDataConnection();
        	dataCon.query(queryContext);
        }
        catch(exception ex){
            system.debug('exception ex '+ex.getMessage()+' at line '+ex.getStackTraceString());
        }
        Test.stopTest();
    }
    
    /*******************************************************************************************************
     * @method name		: testQueryMethodForServiceNowCaseCommentWithLookupFilter
     * @description 		: method to test Query method for servicenow case comment with lookup filter
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void testQueryMethodForServiceNowCaseCommentWithLookupFilter(){
		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, setMock('ServiceNowCaseCommentQuerySuccessMock',200));
        //set table for the rows to be returned
        DataSource.Column column = DataSource.Column.get('value','label','',true,true,DataSource.DataType.STRING_SHORT_TYPE,50);
        List<DataSource.Column> columns = new List<DataSource.Column>{column};
        DataSource.Table table = DataSource.Table.get('Service_Now_Case_Comment__x','ExternalId',columns);
        List<DataSource.table> tables = new List<DataSource.table>{table};
        //Add fields for SELECT clause
        DataSource.ColumnSelection columnSelected = new DataSource.ColumnSelection();
        columnSelected.aggregation = DataSource.QueryAggregation.NONE;
        columnSelected.columnName = 'value';
        columnSelected.tableName = 'Service_Now_Case_Comment__x';
        List<DataSource.ColumnSelection> columnsSelected = new List<DataSource.ColumnSelection>{columnSelected};
        DataSource.TableSelection tableSelection = new DataSource.TableSelection();
        tableSelection.tableSelected = 'Service Now Case Comment';
        tableSelection.columnsSelected = columnsSelected;
        //set filters for the table selected in query
        DataSource.Filter filter = new DataSource.Filter();
        filter.columnName = 'Service_Now_Case';
        filter.columnValue = 'testValue';
        filter.Type = DataSource.FilterType.EQUALS;
        tableSelection.filter = filter;
	 	//set queryContext for query
        DataSource.QueryContext queryContext = DataSource.QueryContext.get(tables,5,5,tableSelection);
        Test.startTest();
        try{
            //catch aggregation exception
            ServiceNowDataConnection dataCon = new ServiceNowDataConnection();
        	dataCon.query(queryContext);
        }
        catch(exception ex){
            system.debug('exception ex '+ex.getMessage()+' at line '+ex.getStackTraceString());
        }
        Test.stopTest();
    }
    
    /*******************************************************************************************************
     * @method name		: testQueryMethodForServiceNowCaseCommentWithExternalIdFilter
     * @description 		: method to test Query method for servicenow case comment with External Id filter
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void testQueryMethodForServiceNowCaseCommentWithExternalIdFilter(){
  		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, setMock('ServiceNowCaseCommentQuerySuccessMock',200));
        //set table for the rows to be returned
        DataSource.Column column = DataSource.Column.get('value','label','',true,true,DataSource.DataType.STRING_SHORT_TYPE,50);
        List<DataSource.Column> columns = new List<DataSource.Column>{column};
        DataSource.Table table = DataSource.Table.get('Service_Now_Case_Comment__x','ExternalId',columns);
        List<DataSource.table> tables = new List<DataSource.table>{table};
        //Add fields for SELECT clause
        DataSource.ColumnSelection columnSelected = new DataSource.ColumnSelection();
        columnSelected.aggregation = DataSource.QueryAggregation.NONE;
        columnSelected.columnName = 'value';
        columnSelected.tableName = 'Service_Now_Case_Comment__x';
        List<DataSource.ColumnSelection> columnsSelected = new List<DataSource.ColumnSelection>{columnSelected};
        DataSource.TableSelection tableSelection = new DataSource.TableSelection();
        tableSelection.tableSelected = 'Service Now Case Comment';
        tableSelection.columnsSelected = columnsSelected;
        //set filters for the table selected in query
        DataSource.Filter filter = new DataSource.Filter();
        filter.columnName = 'ExternalId';
        filter.columnValue = 'testValue';
        filter.Type = DataSource.FilterType.EQUALS;
        tableSelection.filter = filter;
        //set queryContext for query
        DataSource.QueryContext queryContext = DataSource.QueryContext.get(tables,5,5,tableSelection);
        Test.startTest();
        try{
            ServiceNowDataConnection dataCon = new ServiceNowDataConnection();
        	dataCon.query(queryContext);
        }
        catch(exception ex){
            system.debug('exception ex '+ex.getMessage()+' at line '+ex.getStackTraceString());
        }
        Test.stopTest();
    }

    /*******************************************************************************************************
     * @method name		: testQueryMethodForServiceNowCaseCommentWithExternalIdFilter
     * @description 		: method to test Query method for servicenow case comment with Order specified
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void testQueryMethodForServiceNowCaseCommentWithOrderSpecified(){
  		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, setMock('ServiceNowCaseCommentQuerySuccessMock',200));
        //set table for the rows to be returned
        DataSource.Column column = DataSource.Column.get('value','label','',true,true,DataSource.DataType.STRING_SHORT_TYPE,50);
        List<DataSource.Column> columns = new List<DataSource.Column>{column};
        DataSource.Table table = DataSource.Table.get('Service_Now_Case_Comment__x','ExternalId',columns);
        List<DataSource.table> tables = new List<DataSource.table>{table};
        //Add fields for SELECT clause
        DataSource.ColumnSelection columnSelected = new DataSource.ColumnSelection();
        columnSelected.aggregation = DataSource.QueryAggregation.NONE;
        columnSelected.columnName = 'value';
        columnSelected.tableName = 'Service_Now_Case_Comment__x';
        List<DataSource.ColumnSelection> columnsSelected = new List<DataSource.ColumnSelection>{columnSelected};
        DataSource.TableSelection tableSelection = new DataSource.TableSelection();
        tableSelection.tableSelected = 'Service Now Case Comment';
        tableSelection.columnsSelected = columnsSelected;
      	//set filters for the table selected in query
        DataSource.Filter filter = new DataSource.Filter();
        filter.columnName = 'ExternalId';
        filter.columnValue = 'testValue';
        filter.Type = DataSource.FilterType.EQUALS;
        tableSelection.filter = filter;
        DataSource.Order order = DataSource.Order.get('Service_Now_Case_Comment__x','value',DataSource.OrderDirection.ASCENDING);
        tableSelection.Order = new List<DataSource.Order>{order};
    	//set queryContext for query
		DataSource.QueryContext queryContext = DataSource.QueryContext.get(tables,5,5,tableSelection);
        Test.startTest();
        try{
            ServiceNowDataConnection dataCon = new ServiceNowDataConnection();
        	dataCon.query(queryContext);
        }
        catch(exception ex){
            system.debug('exception ex '+ex.getMessage()+' at line '+ex.getStackTraceString());
        }
        Test.stopTest();
    }
    
    /*******************************************************************************************************
     * @method name		: testUpsertServiceNowCasewithoutExternalId
     * @description 		: method to test upsert rows for servicenow case withoutExternalId success case
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void testUpsertServiceNowCasewithoutExternalId(){
		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, setMock('ServiceNowCaseRecordCreatedResponseSuccessMock',200));
        //set rows to be upserted 
        DataSource.UpsertContext upsertContext = new DataSource.UpsertContext();
        List<Map<String,String>> rows = new List<Map<String,String>>();
        //set map of field names, values
        Map<string,string> row = new Map<string,string>();
        row.put('description','desc');
        row.put('short_description','short');
        rows.add(row);
        upsertContext.rows = rows;
        //set object name
        upsertContext.tableSelected = 'service_now_case';
        Test.startTest();
        try{
            ServiceNowDataConnection dataCon = new ServiceNowDataConnection();
        	dataCon.upsertRows(upsertContext);
        }
        catch(exception ex){
            system.debug('exception ex '+ex.getMessage()+' at line '+ex.getStackTraceString());
        }
        Test.stopTest();
    }
    
    /*******************************************************************************************************
     * @method name		: testUpsertServiceNowCasewithExternalId
     * @description 		: method to test upsert rows for servicenow case withExternalId success case
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void testUpsertServiceNowCasewithExternalId(){
		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, setMock('ServiceNowCaseRecordCreatedResponseSuccessMock',200));
        //set rows to be upserted
        DataSource.UpsertContext upsertContext = new DataSource.UpsertContext();
        List<Map<String,String>> rows = new List<Map<String,String>>();
        //set map of field names, values
        Map<string,string> row = new Map<string,string>();
        row.put('description','desc');
        row.put('short_description','short');
        row.put('ExternalId','extraId');
        rows.add(row);
        upsertContext.rows = rows;
        //set object name
        upsertContext.tableSelected = 'service_now_case';
        Test.startTest();
        try{
            ServiceNowDataConnection dataCon = new ServiceNowDataConnection();
        	dataCon.upsertRows(upsertContext);
        }
        catch(exception ex){
            system.debug('exception ex '+ex.getMessage()+' at line '+ex.getStackTraceString());
        }
        Test.stopTest();
    }
    
    /*******************************************************************************************************
     * @method name		: testUpsertServiceNowCasewithExternalIdFail
     * @description 		: method to test upsert rows for servicenow case withExternalId failure case
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void testUpsertServiceNowCasewithExternalIdFail(){
		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, setMock('ServiceNowCaseRecordCreatedResponseFailureMock',400));
        //set rows to be upserted
        DataSource.UpsertContext upsertContext = new DataSource.UpsertContext();
        List<Map<String,String>> rows = new List<Map<String,String>>();
      	//set map of field names, values
        Map<string,string> row = new Map<string,string>();
        row.put('description','desc');
        row.put('short_description','short');
        row.put('ExternalId','extraId');
        rows.add(row);
        upsertContext.rows = rows;
        //set object name
        upsertContext.tableSelected = 'service_now_case';
        Test.startTest();
        try{
            ServiceNowDataConnection dataCon = new ServiceNowDataConnection();
        	dataCon.upsertRows(upsertContext);
        }
        catch(exception ex){
            system.debug('exception ex '+ex.getMessage()+' at line '+ex.getStackTraceString());
        }
        Test.stopTest();
    }
    
    /*******************************************************************************************************
     * @method name		: testUpsertServiceNowCasewithServiceNowFailure
     * @description 		: method to test upsert rows for servicenow case with failure from service now custom end point
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void testUpsertServiceNowCasewithServiceNowFailure(){
		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, setMock('ServiceNowCaseRecordCreatedResponseFailureFromServiceNowMock',200));
        //set rows to be upserted
        DataSource.UpsertContext upsertContext = new DataSource.UpsertContext();
        List<Map<String,String>> rows = new List<Map<String,String>>();
        //set map of field names, values
        Map<string,string> row = new Map<string,string>();
        row.put('description','desc');
        row.put('short_description','short');
        row.put('ExternalId','extraId');
        rows.add(row);
        upsertContext.rows = rows;
        //set object name
        upsertContext.tableSelected = 'service_now_case';
        Test.startTest();
        try{
            ServiceNowDataConnection dataCon = new ServiceNowDataConnection();
        	dataCon.upsertRows(upsertContext);
        }
        catch(exception ex){
            system.debug('exception ex '+ex.getMessage()+' at line '+ex.getStackTraceString());
        }
        Test.stopTest();
    }
    
    /*******************************************************************************************************
     * @method name		: testUpsertServiceNowCaseCommentFailure
     * @description 		: method to test upsert rows for servicenow case comment failure case
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void testUpsertServiceNowCaseCommentFailure(){
		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, setMock('ServiceNowCaseRecordCreatedResponseFailureMock',400));
        //set rows to be upserted
        DataSource.UpsertContext upsertContext = new DataSource.UpsertContext();
        List<Map<String,String>> rows = new List<Map<String,String>>();
        //set map of field names, values
        Map<string,string> row = new Map<string,string>();
        row.put('description','desc');
        row.put('short_description','short');
        rows.add(row);
        upsertContext.rows = rows;
       	//set object name
        upsertContext.tableSelected = 'Service Now Case Comment';
        Test.startTest();
        try{
            ServiceNowDataConnection dataCon = new ServiceNowDataConnection();
        	dataCon.upsertRows(upsertContext);
        }
        catch(exception ex){
            system.debug('exception ex '+ex.getMessage()+' at line '+ex.getStackTraceString());
        }
        Test.stopTest();
    }
    
    /*******************************************************************************************************
     * @method name		: testUpsertServiceNowCaseCommentSuccess
     * @description 		: method to test upsert rows for servicenow case comment success case
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void testUpsertServiceNowCaseCommentSuccess(){
		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, setMock('ServiceNowCaseRecordCreatedResponseSuccessMock',200));
        //set rows to be upserted
        DataSource.UpsertContext upsertContext = new DataSource.UpsertContext();
        List<Map<String,String>> rows = new List<Map<String,String>>();
        //set map of field names, values
        Map<string,string> row = new Map<string,string>();
        row.put('description','desc');
        row.put('short_description','short');
        rows.add(row);
        upsertContext.rows = rows;
       	//set object name
        upsertContext.tableSelected = 'Service Now Case Comment';
        Test.startTest();
        try{
            ServiceNowDataConnection dataCon = new ServiceNowDataConnection();
        	dataCon.upsertRows(upsertContext);
        }
        catch(exception ex){
            system.debug('exception ex '+ex.getMessage()+' at line '+ex.getStackTraceString());
        }
        Test.stopTest();
    }
}