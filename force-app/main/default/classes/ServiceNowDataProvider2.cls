/*
@Description 		: Datasource provider class used in Custom data source connection for service now integration 
@Author			    : Ramtej Juloori
@Created			: 26/06/2018

================================ Modification Log =============================== 
Developer Name 	Date 			Comments

*/

global without sharing class ServiceNowDataProvider2 extends DataSource.Provider {

    /*
    * @description 		: Standard method used to define the authentication method to connect to
                          external source (service now)
    * @returns 			: List<DataSource.AuthenticationCapability>
    */
    override global List < DataSource.AuthenticationCapability > getAuthenticationCapabilities() {
        List < DataSource.AuthenticationCapability > capabilities = new List < DataSource.AuthenticationCapability > ();
        //Define Authentication to external source will be Basic
        capabilities.add(DataSource.AuthenticationCapability.BASIC);
        return capabilities;
    }

    /*
    * @description 		: Standard method used to define the dml operations can be performed on the
                          external object connected to this external data source
    * @returns 			: List<DataSource.Capability>
    */
    override global List < DataSource.Capability > getCapabilities() {
        List < DataSource.Capability > capabilities = new List < DataSource.Capability > ();
        //Enable querying, pagination, search and create capabilities on external objects
        capabilities.add(DataSource.Capability.ROW_QUERY);
        capabilities.add(DataSource.Capability.QUERY_PAGINATION_SERVER_DRIVEN);
        //capabilities.add(DataSource.Capability.SEARCH);
        capabilities.add(DataSource.Capability.ROW_CREATE);
        //capabilities.add(DataSource.Capability.ROW_UPDATE);
        //capabilities.add(DataSource.Capability.ROW_DELETE);
        return capabilities;
    }

    /*	
    * @description 		: Standard method used to return the DataSource.Connection class which defines 
                          the apex logic on operations of external object like sync, query
                          and dml operations
    * @parameters		: DataSource.ConnectionParams
    * @returns 			: List<DataSource.Capability>
    */
    override global DataSource.Connection getConnection(DataSource.ConnectionParams connectionParams) {
        return new ServiceNowDataConnection(connectionParams);
    }
}