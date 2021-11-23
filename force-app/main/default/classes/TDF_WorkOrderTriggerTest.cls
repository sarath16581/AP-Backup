@isTest
public class TDF_WorkOrderTriggerTest{

    public static testmethod void insertCustomSettingValue(){

        if(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'FollowWorkOrder';
            objNotificationSch.FeedMessage__c = 'Test';
            objNotificationSch.ScheduleTime__c = 24;
            insert objNotificationSch;
        }        
    }

    static testmethod void validateWorkOrderTriggerStandard(){

        insertCustomSettingValue();
        List<AssignedResource> assignedResourceList = new List<AssignedResource>(); 
        List<Schema.Location> locationList = new List<Schema.Location>();
        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();           

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation.Registration_Number__c = 'GF55431';
        locationList.add(objVehicleLocation);

        Schema.Location objVehicleLocation1 = new Schema.Location();
        objVehicleLocation1 = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation1.Registration_Number__c = 'HJ4FR4';
        locationList.add(objVehicleLocation1);

        Schema.Location objVehicleLocation2 = new Schema.Location();
        objVehicleLocation2 = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation2.Registration_Number__c = 'IJ4FR2';
        locationList.add(objVehicleLocation2);

        insert locationList;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        objSiteLocation.Registration_Number__c = 'GF55432';
        objSiteLocation.IsInventoryLocation = true;
        objSiteLocation.IsMobile = true;
        objSiteLocation.City__c = 'Sydney';
        objSiteLocation.Country__c = 'Australia';
        objSiteLocation.Post_Code__c = '1234';
        objSiteLocation.State__c = 'Australia';
        objSiteLocation.Street__c = 'Test Australia';
        insert objSiteLocation;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        objServiceResource.Vehicle__c = locationList[0].Id;
        objServiceResource.LocationId = objSiteLocation.Id;
        insert objServiceResource;

        ServiceTerritoryMember objServiceTerritoryMember = new ServiceTerritoryMember();
        objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(7));
        insert objServiceTerritoryMember;
        
        Product2 objProduct = objTestDataFactory.getProduct2('Test Product 001');
        insert objProduct;

        Product2 objProduct1 = objTestDataFactory.getProduct2('Test Product 002');
        objProduct1.Parent_Product__c = objProduct.Id;
        insert objProduct1;

        ProductItem objProductItem = new ProductItem();
        objProductItem = objTestDataFactory.getProductItem(objProduct1.Id, objSiteLocation.Id, 10);
        insert objProductItem;  

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        String standardWORecordType = objTestDataFactory.getWorkOrderRTId('Standard');

        WorkOrder objWorkOrder = new WorkOrder();
        objWorkOrder = objTestDataFactory.getWorkOrder(standardWORecordType);
        objWorkOrder.Status = 'New';
        objWorkOrder.Fit_For_Duty_Response__c = 'No';
        objWorkOrder.Vehicle__c = locationList[0].Id;
        objWorkOrder.Trailer_Reg_No_A__c = 'HJ4FR4';
        objWorkOrder.Trailer_Reg_No_B__c = 'IJ4FR2';        
        objWorkOrder.LocationId = objSiteLocation.Id;
        insert objWorkOrder;

        WorkOrderLineItem objWOLI = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Collect Product');
        objWOLI.Actual_Quantity__c = 10;        
        insert objWOLI;

        WorkOrderLineItem objWOLI1 = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Deliver Product');        
        objWOLI.Actual_Quantity__c = 5;
        insert objWOLI1;        

        WorkOrderLineItem objWOLI2 = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Collect Product');
        objWOLI2.Requested_Quantity__c = 10;        
        insert objWOLI2;

        WorkOrderLineItem objWOLI3 = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Deliver Product');        
        objWOLI.Requested_Quantity__c = 5;
        insert objWOLI3; 

        ServiceAppointment objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now(), 1);                
        objServiceAppointment.Duty_Board__c = objRouteTemplate.Id;
        insert objServiceAppointment;

        AssignedResource objAssignedResource = new AssignedResource();
        objAssignedResource = objTestDataFactory.getAssignedResource(objServiceAppointment.Id, objServiceResource.Id);
        insert objAssignedResource;
        
        /*objWorkOrder.Status = 'Completed';        
        objWorkOrder.Trailer_Reg_No_A__c = 'HJ4FR4';
        objWorkOrder.Trailer_Reg_No_B__c = 'IJ4FR2';*/

        DescribeSObjectResult describeResult = WorkOrder.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
        String query = ' SELECT ' + String.join( fieldNames, ',' );
        query += ' ,(SELECT Id FROM ServiceAppointments) FROM ' + describeResult.getName();
        query += ' WHERE Id =' + '\'' + objWorkOrder.Id + '\'';
        objWorkOrder = Database.query(query);

        update objWorkOrder;
        
        //AJ 20.06.18 - enabled status transition to ensure full coverage on TDF_WorkOrderTrigger.  Note this must adhere to default status transition rules
        objWorkOrder.Status = 'Dispatched';     
        update objWorkOrder;
        objWorkOrder.Status = 'In Progress';     
        update objWorkOrder;      
        objWorkOrder.Status = 'Completed';     
        update objWorkOrder;          

        workOrderList.add(objWorkOrder);
        TDF_WorkOrderTriggerUtility objWOUtil = new TDF_WorkOrderTriggerUtility(workOrderList);
        objWOUtil.workOrderUpdateMethod();        
    }

    static testmethod void validateWorkOrderTriggerReturnVehicle(){

        insertCustomSettingValue();

        List<AssignedResource> assignedResourceList = new List<AssignedResource>(); 
        List<Schema.Location> locationList = new List<Schema.Location>();
        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();            

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation.Registration_Number__c = 'GF55431';
        locationList.add(objVehicleLocation);

        Schema.Location objVehicleLocation1 = new Schema.Location();
        objVehicleLocation1 = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation1.Registration_Number__c = 'HJ4FR4';
        locationList.add(objVehicleLocation1);

        Schema.Location objVehicleLocation2 = new Schema.Location();
        objVehicleLocation2 = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation2.Registration_Number__c = 'IJ4FR2';
        locationList.add(objVehicleLocation2);

        insert locationList;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        objSiteLocation.Registration_Number__c = 'GF55432';
        objSiteLocation.IsInventoryLocation = true;
        objSiteLocation.IsMobile = true;
        insert objSiteLocation;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        objServiceResource.Vehicle__c = locationList[0].Id;
        objServiceResource.LocationId = objSiteLocation.Id;
        insert objServiceResource;

        ServiceTerritoryMember objServiceTerritoryMember = new ServiceTerritoryMember();
        objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(7));
        insert objServiceTerritoryMember;
        
        Product2 objProduct = new Product2();
        objProduct = objTestDataFactory.getProduct2('Test Product 001');
        insert objProduct;

        Product2 objProduct1 = objTestDataFactory.getProduct2('Test Product 002');
        objProduct1.Parent_Product__c = objProduct.Id;
        insert objProduct1;

        ProductItem objProductItem = new ProductItem();
        objProductItem = objTestDataFactory.getProductItem(objProduct1.Id, objSiteLocation.Id, 10);
        insert objProductItem;  

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        String returnVehicleWORecordType = objTestDataFactory.getWorkOrderRTId('Return Vehicle');

        WorkOrder objWorkOrder = new WorkOrder();
        objWorkOrder = objTestDataFactory.getWorkOrder(returnVehicleWORecordType);
        objWorkOrder.Status = 'New';
        objWorkOrder.Vehicle__c = locationList[0].Id;
        objWorkOrder.Trailer_Reg_No_A__c = 'HJ4FR4';
        objWorkOrder.Trailer_Reg_No_B__c = 'IJ4FR2';
        objWorkOrder.LocationId = objSiteLocation.Id;
        objWorkOrder.Parking_Bay__c = 'test123';                    
        insert objWorkOrder;

        WorkOrderLineItem objWOLI = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Collect Product');
        objWOLI.Actual_Quantity__c = 10;        
        insert objWOLI;

        WorkOrderLineItem objWOLI1 = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Deliver Product');        
        objWOLI.Actual_Quantity__c = 5;
        insert objWOLI1;        

        WorkOrderLineItem objWOLI2 = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Collect Product');
        objWOLI2.Requested_Quantity__c = 10;        
        insert objWOLI2;

        WorkOrderLineItem objWOLI3 = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Deliver Product');        
        objWOLI.Requested_Quantity__c = 5;
        insert objWOLI3;  

        ServiceAppointment objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now(), 1);                
        objServiceAppointment.Duty_Board__c = objRouteTemplate.Id;
        insert objServiceAppointment;

        AssignedResource objAssignedResource = new AssignedResource();
        objAssignedResource = objTestDataFactory.getAssignedResource(objServiceAppointment.Id, objServiceResource.Id);
        insert objAssignedResource;
        
        //AJ 24.08.18 Set Status from Scheduled to Dispatched to allow Work Order to be set to In Progress
        objServiceAppointment.Status = 'Dispatched';
        update objServiceAppointment;        

        DescribeSObjectResult describeResult = WorkOrder.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
        String query = ' SELECT ' + String.join( fieldNames, ',' );
        query += ' ,(SELECT Id FROM ServiceAppointments) FROM ' + describeResult.getName();
        query += ' WHERE Id =' + '\'' + objWorkOrder.Id + '\'';
        objWorkOrder = Database.query(query);

        /*objWorkOrder.Status = 'Completed';
        objWorkOrder.Vehicle__c = locationList[0].Id;
        objWorkOrder.Trailer_Reg_No_A__c = 'HJ4FR4';
        objWorkOrder.Trailer_Reg_No_B__c = 'IJ4FR2';
        objWorkOrder.LocationId = objSiteLocation.Id;
        objWorkOrder.Parking_Bay__c = 'test123';*/
        
        //AJ 24.08.18 Set status to In Progress
        objWorkOrder.Status = 'In Progress';
        update objWorkOrder;    
        
        //AJ 24.08.18 Set status to Completed
        objWorkOrder.Status = 'Completed';
        update objWorkOrder;

        workOrderList.add(objWorkOrder);
        TDF_WorkOrderTriggerUtility objWOUtil = new TDF_WorkOrderTriggerUtility(workOrderList);
        objWOUtil.workOrderUpdateMethod();        
    } 

    static testmethod void validateWorkOrderTriggerPDCTrailer(){

        insertCustomSettingValue();

        List<AssignedResource> assignedResourceList = new List<AssignedResource>(); 
        List<Schema.Location> locationList = new List<Schema.Location>();
        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();
         
        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation.Registration_Number__c = 'GF55431';
        locationList.add(objVehicleLocation);

        Schema.Location objVehicleLocation1 = new Schema.Location();
        objVehicleLocation1 = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation1.Registration_Number__c = 'HJ4FR4';
        locationList.add(objVehicleLocation1);

        Schema.Location objVehicleLocation2 = new Schema.Location();
        objVehicleLocation2 = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation2.Registration_Number__c = 'IJ4FR2';
        locationList.add(objVehicleLocation2);

        insert locationList;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        objSiteLocation.Registration_Number__c = 'GF55432';
        objSiteLocation.IsInventoryLocation = true;
        objSiteLocation.IsMobile = true;
        insert objSiteLocation;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        objServiceResource.Vehicle__c = locationList[0].Id;
        objServiceResource.LocationId = objSiteLocation.Id;
        insert objServiceResource;

        ServiceTerritoryMember objServiceTerritoryMember = new ServiceTerritoryMember();
        objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(7));
        insert objServiceTerritoryMember;
                
        Product2 objProduct = new Product2();
        objProduct = objTestDataFactory.getProduct2('Test Product 001');
        insert objProduct;

        Product2 objProduct1 = objTestDataFactory.getProduct2('Test Product 002');
        objProduct1.Parent_Product__c = objProduct.Id;
        insert objProduct1;

        ProductItem objProductItem = new ProductItem();
        objProductItem = objTestDataFactory.getProductItem(objProduct1.Id, objSiteLocation.Id, 10);
        insert objProductItem;  

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        String pdcTrailerWORecordType = objTestDataFactory.getWorkOrderRTId('PDC - Trailer');

        WorkOrder objWorkOrder = new WorkOrder();
        objWorkOrder = objTestDataFactory.getWorkOrder(pdcTrailerWORecordType);
        objWorkOrder.Status = 'New';
        objWorkOrder.Vehicle__c = locationList[0].Id;
        objWorkOrder.Trailer_Reg_No_A__c = 'HJ4FR4';
        objWorkOrder.Trailer_Reg_No_B__c = 'IJ4FR2';
        objWorkOrder.LocationId = objSiteLocation.Id;                    
        insert objWorkOrder;

        WorkOrderLineItem objWOLI = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Collect Product');
        objWOLI.Actual_Quantity__c = 10;        
        insert objWOLI;

        WorkOrderLineItem objWOLI1 = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Deliver Product');        
        objWOLI.Actual_Quantity__c = 5;
        insert objWOLI1;        

        WorkOrderLineItem objWOLI2 = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Collect Product');
        objWOLI2.Requested_Quantity__c = 10;        
        insert objWOLI2;

        WorkOrderLineItem objWOLI3 = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Deliver Product');        
        objWOLI.Requested_Quantity__c = 5;
        insert objWOLI3;  

        ServiceAppointment objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now(), 1);                
        objServiceAppointment.Duty_Board__c = objRouteTemplate.Id;
        insert objServiceAppointment;

        AssignedResource objAssignedResource = new AssignedResource();
        objAssignedResource = objTestDataFactory.getAssignedResource(objServiceAppointment.Id, objServiceResource.Id);
        insert objAssignedResource;

        DescribeSObjectResult describeResult = WorkOrder.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
        String query = ' SELECT ' + String.join( fieldNames, ',' );
        query += ' ,(SELECT Id FROM ServiceAppointments) FROM ' + describeResult.getName();
        query += ' WHERE Id =' + '\'' + objWorkOrder.Id + '\'';
        objWorkOrder = Database.query(query);

        /*objWorkOrder.Status = 'Completed';
        objWorkOrder.Vehicle__c = locationList[0].Id;
        objWorkOrder.Trailer_Reg_No_A__c = 'HJ4FR4';
        objWorkOrder.Trailer_Reg_No_B__c = 'IJ4FR2';
        objWorkOrder.LocationId = objSiteLocation.Id;*/

        update objWorkOrder;

        workOrderList.add(objWorkOrder);
        TDF_WorkOrderTriggerUtility objWOUtil = new TDF_WorkOrderTriggerUtility(workOrderList);
        objWOUtil.workOrderUpdateMethod();        
    } 

    static testmethod void validateWorkOrderTriggerPrimeMover(){

        insertCustomSettingValue();
        
        List<AssignedResource> assignedResourceList = new List<AssignedResource>(); 
        List<Schema.Location> locationList = new List<Schema.Location>();
        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();
         
        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation.Registration_Number__c = 'GF55431';
        objVehicleLocation.Type__c = 'Prime Mover'; //AJ 24.09.18 Added
        locationList.add(objVehicleLocation);

        Schema.Location objVehicleLocation1 = new Schema.Location();
        objVehicleLocation1 = objTestDataFactory.getLocation('Trailer 001', 'Vehicle');
        objVehicleLocation1.Registration_Number__c = 'HJ4FR4';
        objVehicleLocation1.Type__c = 'Trailer'; //AJ 24.09.18 Added
        locationList.add(objVehicleLocation1);

        Schema.Location objVehicleLocation2 = new Schema.Location();
        objVehicleLocation2 = objTestDataFactory.getLocation('Trailer 002', 'Vehicle');
        objVehicleLocation2.Registration_Number__c = 'IJ4FR2';
        objVehicleLocation2.Type__c = 'Trailer'; //AJ 24.09.18 Added
        locationList.add(objVehicleLocation2);

        insert locationList;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        objSiteLocation.Registration_Number__c = 'GF55432';
        objSiteLocation.IsInventoryLocation = true;
        objSiteLocation.IsMobile = true;
        insert objSiteLocation;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        objServiceResource.Vehicle__c = locationList[0].Id;
        objServiceResource.LocationId = objSiteLocation.Id;
        insert objServiceResource;

        ServiceTerritoryMember objServiceTerritoryMember = new ServiceTerritoryMember();
        objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(7));
        insert objServiceTerritoryMember;
                
        Product2 objProduct = new Product2();
        objProduct = objTestDataFactory.getProduct2('Test Product 001');
        insert objProduct;

        Product2 objProduct1 = new Product2();
        objProduct1 = objTestDataFactory.getProduct2('Test Product 002');
        objProduct1.Parent_Product__c = objProduct.Id;
        insert objProduct1;

        ProductItem objProductItem = new ProductItem();
        objProductItem = objTestDataFactory.getProductItem(objProduct1.Id, objSiteLocation.Id, 10);
        insert objProductItem;  

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        String pdcRigidWORecordType = objTestDataFactory.getWorkOrderRTId('PDC - PrimeMover');

        WorkOrder objWorkOrder = new WorkOrder();
        objWorkOrder = objTestDataFactory.getWorkOrder(pdcRigidWORecordType);
        objWorkOrder.Status = 'New';
        objWorkOrder.Vehicle__c = locationList[0].Id;
        objWorkOrder.Trailer_Reg_No_A__c = 'HJ4FR4';
        objWorkOrder.Trailer_Reg_No_B__c = 'IJ4FR2';
        objWorkOrder.LocationId = objSiteLocation.Id;                    
        insert objWorkOrder;

        WorkOrderLineItem objWOLI = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Collect Product');
        objWOLI.Actual_Quantity__c = 10;        
        insert objWOLI;

        WorkOrderLineItem objWOLI1 = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Deliver Product');        
        objWOLI.Actual_Quantity__c = 5;
        insert objWOLI1;        

        WorkOrderLineItem objWOLI2 = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Collect Product');
        objWOLI2.Requested_Quantity__c = 10;        
        insert objWOLI2;

        WorkOrderLineItem objWOLI3 = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Deliver Product');        
        objWOLI.Requested_Quantity__c = 5;
        insert objWOLI3;  

        ServiceAppointment objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now(), 1);                
        objServiceAppointment.Duty_Board__c = objRouteTemplate.Id;
        insert objServiceAppointment;
        
        AssignedResource objAssignedResource = new AssignedResource();
        objAssignedResource = objTestDataFactory.getAssignedResource(objServiceAppointment.Id, objServiceResource.Id);
        insert objAssignedResource;

        //AJ 24.08.18 Set Status to Dispatched to allow Work Order to be set to In Progress
        objServiceAppointment.Status = 'Dispatched';
        update objServiceAppointment;

        DescribeSObjectResult describeResult = WorkOrder.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
        String query = ' SELECT ' + String.join( fieldNames, ',' );
        query += ' ,(SELECT Id FROM ServiceAppointments) FROM ' + describeResult.getName();
        query += ' WHERE Id =' + '\'' + objWorkOrder.Id + '\'';
        objWorkOrder = Database.query(query);

        /*objWorkOrder.Status = 'Completed';
        objWorkOrder.Vehicle__c = locationList[0].Id;
        objWorkOrder.Trailer_Reg_No_A__c = 'HJ4FR4';
        objWorkOrder.Trailer_Reg_No_B__c = 'IJ4FR2';
        objWorkOrder.LocationId = objSiteLocation.Id;*/

        //AJ 24.08.18 set fields record failure. AJ 24.09.18 Do just Non Critical issue to prevent chatter post
        objWorkOrder.Truck_Check_Status__c = 'Non Critical Issue';
        objWorkOrder.A_Trailer_Check_Status__c = 'Non Critical Issue';
        objWorkOrder.B_Trailer_Check_Status__c = 'Non Critical Issue';
        
        objWorkOrder.PDC_PM_Safety_Labels__c = false;
        objWorkOrder.PDC_PM_FirstAidKit__c = false;
        objWorkOrder.PDC_Trailer_A_Free_of_oil_leaks__c = false;
        objWorkOrder.PDC_Trailer_B_Free_of_oil_leaks__c = false;
        objWorkOrder.PDC_Trailer_A_Service_sticker__c = false;
        objWorkOrder.PDC_Trailer_B_Service_sticker__c = false;
        objWorkOrder.PDC_Rigid_LSE_Battery_Check__c = false;

        objWorkOrder.PDC_Additional_Items__c = 'truck additional issue';
        objWorkOrder.PDC_Additional_Items_ATrailer__c = 'A trailer additional issue';
        objWorkOrder.PDC_Additional_Items_BTrailer__c = 'B trailer additional issue';        
        
        //AJ 24.08.18 set fields to trigger PDC check
        objWorkOrder.PDC_Copy__c = true;
        objWorkOrder.Status = 'In Progress';

        update objWorkOrder;

        workOrderList.add(objWorkOrder);
        TDF_WorkOrderTriggerUtility objWOUtil = new TDF_WorkOrderTriggerUtility(workOrderList);
        objWOUtil.workOrderUpdateMethod();        
    }

    //AJ 24.08.18 Added to run a passed test scenario
    static testmethod void validateWorkOrderTriggerPrimeMoverPassed(){

        insertCustomSettingValue();
        
        List<AssignedResource> assignedResourceList = new List<AssignedResource>(); 
        List<Schema.Location> locationList = new List<Schema.Location>();
        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();
         
        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation.Registration_Number__c = 'GF55431';
        locationList.add(objVehicleLocation);

        Schema.Location objVehicleLocation1 = new Schema.Location();
        objVehicleLocation1 = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation1.Registration_Number__c = 'HJ4FR4';
        locationList.add(objVehicleLocation1);

        Schema.Location objVehicleLocation2 = new Schema.Location();
        objVehicleLocation2 = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation2.Registration_Number__c = 'IJ4FR2';
        locationList.add(objVehicleLocation2);

        insert locationList;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        objSiteLocation.Registration_Number__c = 'GF55432';
        objSiteLocation.IsInventoryLocation = true;
        objSiteLocation.IsMobile = true;
        insert objSiteLocation;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        objServiceResource.Vehicle__c = locationList[0].Id;
        objServiceResource.LocationId = objSiteLocation.Id;
        insert objServiceResource;

        ServiceTerritoryMember objServiceTerritoryMember = new ServiceTerritoryMember();
        objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(7));
        insert objServiceTerritoryMember;
                
        Product2 objProduct = new Product2();
        objProduct = objTestDataFactory.getProduct2('Test Product 001');
        insert objProduct;

        Product2 objProduct1 = new Product2();
        objProduct1 = objTestDataFactory.getProduct2('Test Product 002');
        objProduct1.Parent_Product__c = objProduct.Id;
        insert objProduct1;

        ProductItem objProductItem = new ProductItem();
        objProductItem = objTestDataFactory.getProductItem(objProduct1.Id, objSiteLocation.Id, 10);
        insert objProductItem;  

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        String pdcRigidWORecordType = objTestDataFactory.getWorkOrderRTId('PDC - PrimeMover');

        WorkOrder objWorkOrder = new WorkOrder();
        objWorkOrder = objTestDataFactory.getWorkOrder(pdcRigidWORecordType);
        objWorkOrder.Status = 'New';
        objWorkOrder.Vehicle__c = locationList[0].Id;
        objWorkOrder.Trailer_Reg_No_A__c = 'HJ4FR4';
        objWorkOrder.Trailer_Reg_No_B__c = 'IJ4FR2';
        objWorkOrder.LocationId = objSiteLocation.Id;                    
        insert objWorkOrder;

        WorkOrderLineItem objWOLI = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Collect Product');
        objWOLI.Actual_Quantity__c = 10;        
        insert objWOLI;

        WorkOrderLineItem objWOLI1 = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Deliver Product');        
        objWOLI.Actual_Quantity__c = 5;
        insert objWOLI1;        

        WorkOrderLineItem objWOLI2 = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Collect Product');
        objWOLI2.Requested_Quantity__c = 10;        
        insert objWOLI2;

        WorkOrderLineItem objWOLI3 = objTestDataFactory.getWOLI(objWorkOrder.Id, objProduct1.Id, 'Deliver Product');        
        objWOLI.Requested_Quantity__c = 5;
        insert objWOLI3;  

        ServiceAppointment objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now(), 1);                
        objServiceAppointment.Duty_Board__c = objRouteTemplate.Id;
        insert objServiceAppointment;
        
        AssignedResource objAssignedResource = new AssignedResource();
        objAssignedResource = objTestDataFactory.getAssignedResource(objServiceAppointment.Id, objServiceResource.Id);
        insert objAssignedResource;

        //AJ 24.08.18 Set Status to Dispatched to allow WO to be set to In Progress
        objServiceAppointment.Status = 'Dispatched';
        update objServiceAppointment;

        DescribeSObjectResult describeResult = WorkOrder.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
        String query = ' SELECT ' + String.join( fieldNames, ',' );
        query += ' ,(SELECT Id FROM ServiceAppointments) FROM ' + describeResult.getName();
        query += ' WHERE Id =' + '\'' + objWorkOrder.Id + '\'';
        objWorkOrder = Database.query(query);

        //Set fields for record pass
        objWorkOrder.Truck_Check_Status__c = 'Non Critical Issue';
        objWorkOrder.A_Trailer_Check_Status__c = 'Non Critical Issue';
        objWorkOrder.B_Trailer_Check_Status__c = 'Non Critical Issue';
        
        objWorkOrder.PDC_PM_FirstAidKit__c = false;
        objWorkOrder.PDC_Trailer_A_Service_sticker__c = false;
        objWorkOrder.PDC_Trailer_B_Service_sticker__c = false; 
        
        //PDC check in progress
        objWorkOrder.Status = 'In Progress';
        update objWorkOrder;    
        
        //PDC check complete
        objWorkOrder.Status = 'Completed';
        update objWorkOrder;

        workOrderList.add(objWorkOrder);
        TDF_WorkOrderTriggerUtility objWOUtil = new TDF_WorkOrderTriggerUtility(workOrderList);
        objWOUtil.workOrderUpdateMethod();        
    } 

    static testmethod void validateWorkOrderTriggerDropTrailer(){

        insertCustomSettingValue();

        List<AssignedResource> assignedResourceList = new List<AssignedResource>(); 
        List<Schema.Location> locationList = new List<Schema.Location>();
        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();            

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation.Registration_Number__c = 'GF55431';
        locationList.add(objVehicleLocation);

        Schema.Location objVehicleLocation1 = new Schema.Location();
        objVehicleLocation1 = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation1.Registration_Number__c = 'HJ4FR4';
        locationList.add(objVehicleLocation1);

        Schema.Location objVehicleLocation2 = new Schema.Location();
        objVehicleLocation2 = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation2.Registration_Number__c = 'IJ4FR2';
        locationList.add(objVehicleLocation2);

        insert locationList;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        objSiteLocation.Registration_Number__c = 'GF55432';
        objSiteLocation.IsInventoryLocation = true;
        objSiteLocation.IsMobile = true;
        insert objSiteLocation;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        objServiceResource.Vehicle__c = locationList[0].Id;
        objServiceResource.LocationId = objSiteLocation.Id;
        insert objServiceResource;

        ServiceTerritoryMember objServiceTerritoryMember = new ServiceTerritoryMember();
        objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(7));
        insert objServiceTerritoryMember;

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        String dropTrailerWORecordType = objTestDataFactory.getWorkOrderRTId('Drop Off Trailer');

        WorkOrder objWorkOrder = new WorkOrder();
        objWorkOrder = objTestDataFactory.getWorkOrder(dropTrailerWORecordType );
        objWorkOrder.Status = 'New';
        objWorkOrder.Vehicle__c = locationList[0].Id;
        objWorkOrder.Trailer_Reg_No_A__c = 'HJ4FR4';
        objWorkOrder.Trailer_Reg_No_B__c = 'IJ4FR2';
        objWorkOrder.LocationId = objSiteLocation.Id;
        objWorkOrder.Parking_Bay__c = 'test123';                    
        insert objWorkOrder;

        ServiceAppointment objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now(), 1);                
        objServiceAppointment.Duty_Board__c = objRouteTemplate.Id;
        insert objServiceAppointment;

        AssignedResource objAssignedResource = new AssignedResource();
        objAssignedResource = objTestDataFactory.getAssignedResource(objServiceAppointment.Id, objServiceResource.Id);
        insert objAssignedResource;
        
        //AJ 24.08.18 Set Status from Scheduled to Dispatched to allow Work Order to be set to In Progress
        objServiceAppointment.Status = 'Dispatched';
        update objServiceAppointment;        

        DescribeSObjectResult describeResult = WorkOrder.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
        String query = ' SELECT ' + String.join( fieldNames, ',' );
        query += ' ,(SELECT Id FROM ServiceAppointments) FROM ' + describeResult.getName();
        query += ' WHERE Id =' + '\'' + objWorkOrder.Id + '\'';
        objWorkOrder = Database.query(query);
       
        //AJ 24.08.18 Set status to In Progress
        objWorkOrder.Status = 'In Progress';
        update objWorkOrder;    
        
        //AJ 24.08.18 Set status to Completed
        objWorkOrder.Status = 'Completed';
        update objWorkOrder;

        workOrderList.add(objWorkOrder);
        TDF_WorkOrderTriggerUtility objWOUtil = new TDF_WorkOrderTriggerUtility(workOrderList);
        objWOUtil.workOrderUpdateMethod();        
    }
}