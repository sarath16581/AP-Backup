/** 
* @author Gaurav
* @date 2017-?-? 
* @description This class performs server side processing in response to updates to work orders by drivers.
*               For example when a PDC work order is completed, the service sets the vehicle location against the driver
*               to inidicate the a PDC has been successfully done
*
* @changelog 
* 2020.05.06 - Andrew Judd - Changed Service Resource sub query to only get latest assigned driver (Technician) using Resource Type = T condition
*                               Ignoring the assigned duty Service Resource when update executed in a Resource by Duty context
* 2020.05.06 - Andrew Judd - Changes to align with change in Work Order Line Item to Work Order data model.
* 2020.05.06 - Andrew Judd - Changed to with sharing
*/
global with sharing class TDF_WorkOrderTriggerUtility{

    public List<WorkOrder> workOrderList;
    public Map<Id, WorkOrder> workOrderMap;    
    public Map<String, String> workOrderRecordTypeMap;    
    public Map<String, Schema.Location> trailerMap;
    public Map<String, String> locationWorkOrderMap;

    public TDF_WorkOrderTriggerUtility(List<WorkOrder> woList){
        //Call the method to Initialize all the public variables
        init();
        workOrderList = woList;
        //Populate a map contains workorder id and its record
        for(WorkOrder objWorkOrder : workOrderList){
            workOrderMap.put(objWorkOrder.Id, objWorkOrder);
        }
        //Populate WorkOrder record type map by calling Utlility method
        workOrderRecordTypeMap = TDF_WorkOrderUtility.workOrderRecordTypeMapForTrigger();
    }

    public void init(){
        //Initialize variables
        workOrderList = new List<WorkOrder>();
        workOrderMap = new Map<Id, WorkOrder>();        
        workOrderRecordTypeMap = new Map<String, String>();
        trailerMap = new Map<String, Schema.Location>();
        locationWorkOrderMap = new Map<String, String>();
    }
    
    public void workOrderUpdateMethod(){

        //Declare SavePoint
        Savepoint sp;

        try{

            //Set savepoint for rollback
            sp = Database.setSavepoint();

            //Local variables used in method
            Set<String> workOrderIdSet = new Set<String>();
            Set<String> trailerRegoNumberSet = new Set<String>();
            Set<String> serviceResourceIdSet = new Set<String>();
            Set<String> vehicleIdSet = new Set<String>();
            Set<String> productItemIdSet = new Set<String>();       
            Map<String, List<WorkOrderLineItem>> workOrderAndWOLIMap = new Map<String, List<WorkOrderLineItem>>();
            Map<String, List<ProductItem>> productItemMap = new Map<String, List<ProductItem>>();
            List<ProductItem> productItemToUpdateList = new List<ProductItem>();
            Map<String, String> workOrderServiceResourceMap = new Map<String, String>();
            Map<String, ServiceResource> serviceResourceMap = new Map<String, ServiceResource>();
            Map<String, Schema.Location> locationeMap = new Map<String, Schema.Location>();
            String workOrderRT;
            Set<String> workOrderLocationIdSet = new Set<String>();
            Map<String, List<ProductItem>> locationProductItemMap = new Map<String, List<ProductItem>>();
            List<ProductItem> productItemToInsertList = new List<ProductItem>();
            Map<String, Map<String, ProductItem>> productWiseProductItemMap = new Map<String, Map<String, ProductItem>>();
            Map<String, List<WorkOrderLineItem>> workOrderLineItemMap;
            Set<String> parentProductIdSet;
            Set<String> childProductIdSet;
            Set<String> productIdSetForDuplicateCheck = new Set<String>();
            Set<String> parentLocationIdSet = new Set<String>();
            Map<String, List<Schema.Location>> parentLocationTrailerMap = new Map<String, List<Schema.Location>>();
            //AJ 31.07.18 Added
            List<Vehicle_Inspection_Issues__c> vehicleInspectIssuesToInsertList = new List<Vehicle_Inspection_Issues__c>();
            List<Vehicle_Inspection_Issues__c> vehicleInspectIssuesToUpdateList = new List<Vehicle_Inspection_Issues__c>();
            Set<String> issueVehicleIdSet = new Set<String>();
            Set<String> vehicleIssuesExistingSet = new Set<String>();
            Set<String> inuseVehicleIdSet = new Set<String>();
            String vehicleIDItemExisting;
            String vehicleIDItemNew;
            String inspectSeverity;
            Boolean bolVIICreated;
            Schema.FieldSet fsVCTruckC = Schema.SObjectType.WorkOrder.fieldSets.VehicleCheck_Truck_Critical;
            Schema.FieldSet fsVCTruckNC = Schema.SObjectType.WorkOrder.fieldSets.VehicleCheck_Truck_NonCritical;
            Schema.FieldSet fsVCATrailerC = Schema.SObjectType.WorkOrder.fieldSets.VehicleCheck_ATrailer_Critical;
            Schema.FieldSet fsVCATrailerNC = Schema.SObjectType.WorkOrder.fieldSets.VehicleCheck_ATrailer_NonCritical;
            Schema.FieldSet fsVCBTrailerC = Schema.SObjectType.WorkOrder.fieldSets.VehicleCheck_BTrailer_Critical;
            Schema.FieldSet fsVCBTrailerNC = Schema.SObjectType.WorkOrder.fieldSets.VehicleCheck_BTrailer_NonCritical;
            Schema.FieldSet fsVCLSENC = Schema.SObjectType.WorkOrder.fieldSets.VehicleCheck_LSE_NonCritical;
            
            //AJ 27.08.18 Added to set Util
            List<WorkOrder> workOrderToUpdateList = new List<WorkOrder>();
            Map<String, String> parentWorkOrderMap = new Map<String, String>();

            //TDF Enhance 2020.09.28 List to consolidate collect from and deliver to work orders line items
            List<WorkOrderLineItem> workOrderLineItemList = new List<WorkOrderLineItem>();
            
            //Loop through the WorkOrders passed from trigger
            for(WorkOrder objWorkOrder : workOrderList){

                //Add work orders id in a set
                workOrderIdSet.add(objWorkOrder.Id);

                //Add Vehicle Id of WorkOrder in a Set
                if(objWorkOrder.Vehicle__c != null){
                    vehicleIdSet.add(objWorkOrder.Vehicle__c);                  
                }

                //Add Trailers Registration numbers in a Set
                if(objWorkOrder.Trailer_Reg_No_A__c != null){
                    trailerRegoNumberSet.add(objWorkOrder.Trailer_Reg_No_A__c);
                }
                if(objWorkOrder.Trailer_Reg_No_B__c != null){
                    trailerRegoNumberSet.add(objWorkOrder.Trailer_Reg_No_B__c);
                }

                //Add Location Id of WorkOrder in a Set
                if(objWorkOrder.LocationId != null){
                    workOrderLocationIdSet.add(objWorkOrder.LocationId);
                }
                                           
            }
            
            //AJJ build parent map
            for(WorkOrder objWO : [SELECT Id, ParentWorkOrder.Id FROM WorkOrder WHERE Id IN : workOrderIdSet]){
                if(objWO.ParentWorkOrder.Id != null){
                    parentWorkOrderMap.put(objWO.Id, objWO.ParentWorkOrder.Id);
                }
            }               

            //Query all Service Appointments and their Assigned Resource from WorkOrder Id Set
            //Loop throght those Service Appointments and populate maps
            //AJ TDF Enhance 05.06.20 Changed SR sub query to only get latest assigned driver (Technician) using Resource Type = T condition 
                //-filtering out the Crew SR
                //-Note that Dispatch Work does not allow dispatch if more than one driver is assigned
                //-this will ensure the logic below to get the driver (Technician) will only locate one record.
                //-If this is not alway occuring, another option is to get the SR via the User Id.
            for(ServiceAppointment objServiceAppointment : [SELECT Id, ParentRecordId, (SELECT Id, ServiceResourceId, ServiceResource.Vehicle__c, ServiceResource.LocationId FROM ServiceResources WHERE ServiceResource.ResourceType = 'T' LIMIT 1) FROM ServiceAppointment WHERE ParentRecordId IN : workOrderIdSet]){
                if(objServiceAppointment.ServiceResources.size()>0){
                    if(objServiceAppointment.ServiceResources[0].ServiceResourceId != null){
                        //Add Id of First Assigned Resource's Service Resource Id of Service Appointment
                        serviceResourceIdSet.add(objServiceAppointment.ServiceResources[0].ServiceResourceId);
                        //Populate a map contains WorkOrderId and Service Resource Id of that WorkOrder
                        //Map<Key, Value> = Map<WorkOrder_Id, WorkOrder's_SA_AssignedResource_ServiceResourceId>
                        workOrderServiceResourceMap.put(objServiceAppointment.ParentRecordId, objServiceAppointment.ServiceResources[0].ServiceResourceId);
                    }
                    if(objServiceAppointment.ServiceResources[0].ServiceResource.LocationId != null){
                        //Add Location Id of Service Resource Location
                        vehicleIdSet.add(objServiceAppointment.ServiceResources[0].ServiceResource.LocationId);
                        //Populate map that contains WorkOrder Id as key and Service Resource Location as value
                        //Map<Key, Value> = Map<WorkOrder Id, Service Resource Location Id>
                        locationWorkOrderMap.put(objServiceAppointment.ParentRecordId, objServiceAppointment.ServiceResources[0].ServiceResource.LocationId);
                    }
                }
            }

            //Query the Service Resource for Ids and Populate map
            for(ServiceResource objServiceResource : [SELECT Id, Vehicle__c, LocationId FROM ServiceResource WHERE Id IN : serviceResourceIdSet]){
                serviceResourceMap.put(objServiceResource.Id, objServiceResource);
                //AJ 21.09.19 Don't include null value
                if(objServiceResource.LocationId != null){
                    parentLocationIdSet.add(objServiceResource.LocationId);
                }
            }

            //Loop through the WorkOrders and get location id of Service Resource's Assigned Resource's Service Resource
            for(WorkOrder objWorkOrder : workOrderList){
                if(serviceResourceMap.get(workOrderServiceResourceMap.get(objWorkOrder.Id)) != null){
                    workOrderLocationIdSet.add(serviceResourceMap.get(workOrderServiceResourceMap.get(objWorkOrder.Id)).LocationId);
                }
            }

            //Query the Location from Vehicle ids of WorkOrder's Assigned Resource's Service Resource's Location and populate Location Map
            for(Schema.Location objLocation : [SELECT Id, Status__c, ParkingBay__c, Registration_Number__c, ParentLocationId, Capacity__c FROM Location WHERE Id IN : vehicleIdSet OR Registration_Number__c IN : trailerRegoNumberSet OR (Type__c = 'Trailer' AND ParentLocationId IN : parentLocationIdSet)]){
                locationeMap.put(objLocation.Id, objLocation);
            }

            //Query the Location from Trailer A and B Registration numbers of WorkOrders and Populate Trailer map with Id and its record
            for(Schema.Location objLocation : [SElECT Id, Registration_Number__c, ParentLocationId FROM Location WHERE Registration_Number__c IN : trailerRegoNumberSet]){
                trailerMap.put((objLocation.Registration_Number__c).toUpperCase(), objLocation);               
            }   

            //Query all the locations and its related Product Items from Location ids of WorkOrder's Service Resource's Assigned Resource's Service Resource's and Pupulate map
            for(Schema.Location objLocation : [SELECT Id, Name, (SELECT Id, Product2Id, QuantityOnHand, Product2.Parent_Product__c FROM ProductItems) FROM Location WHERE Id IN : workOrderLocationIdSet]){
                //Populate map with WorkOrder's Assigned Resource's Service Resource's Location id and its Product Items
                locationProductItemMap.put(objLocation.Id, objLocation.ProductItems);
            }

            //Query locations from WorkOrder's Assigned Resource's Service Resource's Location id where Location type is Trailer
            List<Schema.Location> locList = new List<Schema.Location>();
            locList = [SELECT Id, ParentLocationId FROM Location WHERE Type__c = 'Trailer' AND ParentLocationId IN : parentLocationIdSet];
                
            //Filter all the Locations by Parent Locations              
            for(String parentLocationStr : parentLocationIdSet){
                List<Schema.Location> locTempList = new List<Schema.Location>();
                for(Schema.Location objLocation : locList){
                    if(objLocation.ParentLocationId == parentLocationStr && locationeMap.get(objLocation.Id) != null){
                        locTempList.add(locationeMap.get(objLocation.Id));
                    }
                }
                //Map<key, value> = Map<ParentLocationId, List<ChildLocations>>
                parentLocationTrailerMap.put(parentLocationStr, locTempList);
            }

            Set<String> productIdSet;           

            //Query all the WorkOrders wirh related WorkOrderLineItems
            //TDF Enhance 2020.09.28: A number of changes to the section below due to the new Work Order Line Item data model with Collect From and Deliver To lookup to Work Order
            //TDF Enhance 2020.09.28: Changed query to get Collect From and Deliver To work order line items
            //for(WorkOrder objWorkOrder : [SELECT Id, LocationId,  (SELECT Id, Product__c, Product__r.Parent_Product__c, WorkOrderId, Task__c, Actual_Quantity__c, Requested_Quantity__c FROM WorkOrderLineItems) FROM WorkOrder WHERE Id IN : workOrderIdSet]){
            for(WorkOrder objWorkOrder : [SELECT Id, LocationId,  
                                            (SELECT Id, Product__c, Product__r.Parent_Product__c, WorkOrderId, Actual_Collect_Quantity__c FROM Collect_From_Work_Order_Line_Items__r),
                                            (SELECT Id, Product__c, Product__r.Parent_Product__c, WorkOrderId, Actual_Deliver_Quantity__c FROM Deliver_To_Work_Order_Line_Items__r) 
                                            FROM WorkOrder WHERE Id IN : workOrderIdSet]){  
                
                //TDF Enhance 2020.09.28: Change logic to add the Collect From and Deliver To work order line items to the woli map
                //populate map with WorkOrder id and its related WorkOrderLineItems
                //workOrderAndWOLIMap.put(objWorkOrder.Id, objWorkOrder.WorkOrderLineItems);
                //For all Collect From records
                for(WorkOrderLineItem woli : objWorkOrder.Collect_From_Work_Order_Line_Items__r){
                    //Set task value as Collect
                    woli.Task__c = 'Collect Product';
                    //Add record to temporary list
                    workOrderLineItemList.add(woli);
                }
                //For all Deliver To records
                for(WorkOrderLineItem woli : objWorkOrder.Deliver_To_Work_Order_Line_Items__r){
                    //Set task value as Deliver
                    woli.Task__c = 'Deliver Product';
                    //Add record to temporary list
                    workOrderLineItemList.add(woli);
                }                
                
                //Add collect and deliver wolis to the map
                workOrderAndWOLIMap.put(objWorkOrder.Id,workOrderLineItemList);     
                
                productIdSet = new Set<String>();

                String locId;

                //get the WorkOrder's Assigned Resource's Service Resource's Location id
                if(workOrderServiceResourceMap.get(objWorkOrder.Id) != null && serviceResourceMap.get(workOrderServiceResourceMap.get(objWorkOrder.Id)) != null){
                    locId = serviceResourceMap.get(workOrderServiceResourceMap.get(objWorkOrder.Id)).LocationId;
                }

                //Check if WorkOrder Location has Product Items
                if(objWorkOrder.LocationId != null && locationProductItemMap.get(objWorkOrder.LocationId) != null){

                    //Loop through all the Product Items of WorkOrder's Location and get Product Ids in a set
                    for(ProductItem objProductItem : locationProductItemMap.get(objWorkOrder.LocationId)){
                        productIdSet.add(objProductItem.Product2Id);
                    }

                    //Loop through all the Product Items of WorkOrder's Assigned Resource's Service Resource's Location id (the vehicle) and add Product Ids in a Set
                    if(locId != null && locationProductItemMap.get(locId) != null){
                        for(ProductItem objProductItem : locationProductItemMap.get(locId)){
                            productIdSet.add(objProductItem.Product2Id);
                        }
                    }

                    //Loop through the WorkOrderLineItems of WorkOrders and check if Productitem is present or not for Parent Product of WorkOrderLineItem's Product or WOLIs Product
                    //TFD Enhance 2020.09.28: Change to loop through map with both Collect and Deliver Work Order Line Items
                    //-Note that this does not do the insert for a site where return vehicle occurs > in which case the product will not be transfered from the truck to the rv site.
                    //for(WorkOrderLineItem objWOLI : objWorkOrder.WorkOrderLineItems){
                    for(WorkOrderLineItem objWOLI : workOrderAndWOLIMap.get(objWorkOrder.Id)){                   

                        //If no ProductItem is there with the WOLIs ParentProductId, then create one with Quantity 0
                        if(objWOLI.Product__r.Parent_Product__c != null && objWorkOrder.LocationId != null){                            
                            if(!productIdSet.contains(objWOLI.Product__r.Parent_Product__c)){
                                ProductItem objProductItem = new ProductItem();
                                objProductItem.Product2Id = objWOLI.Product__r.Parent_Product__c;
                                objProductItem.LocationId = objWorkOrder.LocationId;
                                objProductItem.QuantityOnHand = 0;
                                productItemToInsertList.add(objProductItem);
                                productIdSet.add(objWOLI.Product__r.Parent_Product__c);
                            }
                        }

                        //If no ProductItem is there with the WOLI product id, then create one with Quantity 0
                        if(objWOLI.Product__c != null && locId != null){
                            if(!productIdSet.contains(objWOLI.Product__c)){
                                ProductItem objProductItem = new ProductItem();
                                objProductItem.Product2Id = objWOLI.Product__c;
                                objProductItem.LocationId = locId;
                                objProductItem.QuantityOnHand = 0;
                                productItemToInsertList.add(objProductItem);
                                productIdSet.add(objWOLI.Product__c);
                            }
                        }                                               
                    }               
                }       
            }

            //Insert ProductItems for WOLI
            if(productItemToInsertList.size()>0){
                insert productItemToInsertList;
            } 

            locationProductItemMap = new Map<String, List<ProductItem>>();
            /*Code added by Gaurav to resolve W-000204 Begin*/
            Set<String> locationIdSetTemp = new Set<String>();
            locationIdSetTemp.addAll(workOrderLocationIdSet);
            locationIdSetTemp.addAll(vehicleIdSet);

            //Loop through all the location and their ProductItems from Ids from WorkOrder's Location or Vehicle. AJ 29.08.18 added ULD ratio
            for(Schema.Location objLocation : [SELECT Id, Name, (SELECT Id, Product2Id, QuantityOnHand, Product2.Parent_Product__c, Product2.ULD_Ratio__c FROM ProductItems) FROM Location WHERE Id IN : locationIdSetTemp]){
            /*Code added by Gaurav to resolve W-000204 End*/    

                //Populate Map<key,value> = Map<LocationId, List<ProductItems>>
                locationProductItemMap.put(objLocation.Id, objLocation.ProductItems);
                
                //Populate map Map<key, Map<key,value>> = Map<LocationId, <Map<ProductId,ProductItem>>
                Map<String, ProductItem> pMap = new Map<String, ProductItem>();
                for(ProductItem objProductItem : objLocation.ProductItems){
                    pMap.put(objProductItem.Product2Id, objProductItem);
                }
                productWiseProductItemMap.put(objLocation.Id, pMap);
            }

            /*Main Trigger for loop Begin */
            //Loop through all the WorkOrders for main business logic
            for(WorkOrder objWorkOrder : workOrderList){

                workOrderRT = '';

                //get workOrder record type
                workOrderRT = workOrderRecordTypeMap.get(objWorkOrder.recordTypeId);

                String locId;

                //get the Location id of WorkOrder's Service Resource's Assigned Resource's Service Resource's
                if(workOrderServiceResourceMap.get(objWorkOrder.Id) != null && serviceResourceMap.get(workOrderServiceResourceMap.get(objWorkOrder.Id)) != null){
                    locId = serviceResourceMap.get(workOrderServiceResourceMap.get(objWorkOrder.Id)).LocationId;
                }

                //AJ 10.08.18 If Work Order has been Completed, perform main logic
                if(objWorkOrder.Status == 'Completed'){
                    //If PDC Truck or Trailer
                    if(workOrderRT == 'PDC_PrimeMover' || workOrderRT == 'PDC_Rigid' || workOrderRT == 'PDC_Trailer'){
                    
                        //If Passed
                        if(objWorkOrder.PDC_Road_Worthy__c == 'Passed' || objWorkOrder.PDC_Road_Worthy__c == 'Passed - Non Critical Issue'){
                    
                            //If Truck - WorkOrder is of Type 'PrimeMover' or 'Rigid'
                            if(workOrderRT == 'PDC_PrimeMover' || workOrderRT == 'PDC_Rigid'){
                                    
                                /*Code added by Gaurav to resolve W-000204 Begin*/     
                                //Assign WorkOrder's Vehicle to Service Resource Location
                                if(serviceResourceMap.get(workOrderServiceResourceMap.get(objWorkOrder.Id)) != null){
                                    serviceResourceMap.get(workOrderServiceResourceMap.get(objWorkOrder.Id)).LocationId = objWorkOrder.Vehicle__c;                  
                                }
        
                                if(objWorkOrder.Vehicle__c != null && locationeMap.get(objWorkOrder.Vehicle__c) != null){
                                
                                    //Make the WorkOrder's Vehicle's Status 'In Use', Inspection Issue to null, and Parent Location null
                                    locationeMap.get(objWorkOrder.Vehicle__c).Status__c = 'In Use'; 
                                    locationeMap.get(objWorkOrder.Vehicle__c).ParentLocationId = null;
                                    //store vehicle set to In Use
                                    inuseVehicleIdSet.add(objWorkOrder.Vehicle__c); 
        
                                    //Loop through the Prodcut Items of WorkOrder's Vehicle and make their QuantityOnHand 0
                                    for(ProductItem objProductItem : locationProductItemMap.get(objWorkOrder.Vehicle__c)){
        
                                        objProductItem.QuantityOnHand = 0;
        
                                        //Add ProductItems in a list for update
                                        if(!productIdSetForDuplicateCheck.contains(objProductItem.Id)){                                            
                                            productItemToUpdateList.add(objProductItem);                                            
                                            productIdSetForDuplicateCheck.add(objProductItem.Id);
                                        }
                                    }
                                    /*Code added by Gaurav to resolve W-000204 End*/                           
                                }
                                
                            }
                                
                            //If Truck or Trailer
                            if(workOrderRT == 'PDC_PrimeMover' || workOrderRT == 'PDC_Rigid' || workOrderRT == 'PDC_Trailer'){
                                
                                String vehicleId;
                                //AJ 01.08.18 Added if SR assigned to work order
                                if(workOrderServiceResourceMap.get(objWorkOrder.Id) != null){
                                    //Get truck assigned to SR
                                    if(serviceResourceMap.get(workOrderServiceResourceMap.get(objWorkOrder.Id)).LocationId != null){
                                        vehicleId = serviceResourceMap.get(workOrderServiceResourceMap.get(objWorkOrder.Id)).LocationId;
                                    }
                                }
            
                                System.debug('vehicleId ->'+vehicleId);
                                //AJ 31.07.18 Added trailer map condition to fix error when not a location
                                if(objWorkOrder.Trailer_Reg_No_A__c != null && trailerMap.get((objWorkOrder.Trailer_Reg_No_A__c).toUpperCase()) != null){                          
                                    //Set Truck as Trailer parent as Truck, Status In Use, and clear Inspection Issue Id
                                    locationeMap.get(trailerMap.get((objWorkOrder.Trailer_Reg_No_A__c).toUpperCase()).Id).ParentLocationId = vehicleId;
                                    locationeMap.get(trailerMap.get((objWorkOrder.Trailer_Reg_No_A__c).toUpperCase()).Id).Status__c = 'In Use';
                                    //store vehicle set to In Use
                                    inuseVehicleIdSet.add(trailerMap.get((objWorkOrder.Trailer_Reg_No_A__c).toUpperCase()).Id); 
                                }
            
                                //AJ 31.07.18 Added trailer map condition to fix error when not a location
                                if(objWorkOrder.Trailer_Reg_No_B__c != null && trailerMap.get((objWorkOrder.Trailer_Reg_No_B__c).toUpperCase()) != null){
                                    //Set Truck as Trailer parent as Truck, Status In Use, and clear Inspection Id
                                    locationeMap.get(trailerMap.get((objWorkOrder.Trailer_Reg_No_B__c).toUpperCase()).Id).ParentLocationId = vehicleId;
                                    locationeMap.get(trailerMap.get((objWorkOrder.Trailer_Reg_No_B__c).toUpperCase()).Id).Status__c = 'In Use';
                                    //store vehicle set to In Use
                                    inuseVehicleIdSet.add(trailerMap.get((objWorkOrder.Trailer_Reg_No_B__c).toUpperCase()).Id); 
                                }
                                                           
                            }
                        }//End if Passed                                        
                    }//End if PDC
                    //If WorkOrder is of Type 'Return Vehicle'
                    else if(workOrderRT == 'Return_Vehicle'){
    
                        if(locId != null && serviceResourceMap.get(workOrderServiceResourceMap.get(objWorkOrder.Id)) != null && productWiseProductItemMap.get(locId) != null){
                            
                            //get all the ProductItems from WorkOrder's Service Resource's Assigned Resource's Service Resource's Location Id
                            for(ProductItem objProductItem : productWiseProductItemMap.get(locId).values()){
                                
                                //If the product item not null, and it has a parent product defined, and the work order location has a product item for this parent product
                                //-So this will not enter if no product item record for the parent product at site ()
                                if(objProductItem.Product2Id != null && objProductItem.Product2.Parent_Product__c != null && productWiseProductItemMap.get(objWorkOrder.LocationId).get(objProductItem.Product2.Parent_Product__c) != null){
    
                                    //Add the Quantity of Location's Product Items to WorkOrder's Location's ProductItem by Parent Product
                                    productWiseProductItemMap.get(objWorkOrder.LocationId).get(objProductItem.Product2.Parent_Product__c).QuantityOnHand += objProductItem.QuantityOnHand;
    
                                    //Made the Qunatity of Location's ProductItems to 0
                                    productWiseProductItemMap.get(locId).get(objProductItem.Product2Id).QuantityOnHand = 0;

                                }
                            }
    
                            //Set the Parent Locations of Trailer related to WorkOrder to WorkOrder's Location
                            if(parentLocationTrailerMap.get(locId) != null){
                                for(Schema.Location objLocation : parentLocationTrailerMap.get(locId)){
                                    if(locationeMap.get(objLocation.Id) != null){
                                        locationeMap.get(objLocation.Id).ParentLocationId = objWorkOrder.LocationId;
                                        //AJ 06.08.18 Set status available
                                        locationeMap.get(objLocation.Id).Status__c = 'Available';
                                    }
                                }
                            }
                        }
    
                        System.debug('locId ->'+locId);
    
                        if(locId != null){
                            if(locationeMap.get(locId) != null){
                                //Map the Parking bay from WorkOrder to Location's Parking Bay
                                if(objWorkOrder.Parking_Bay__c != null){
                                    locationeMap.get(locId).ParkingBay__c = objWorkOrder.Parking_Bay__c;                        
                                }else{
                                    locationeMap.get(locId).ParkingBay__c = null;
                                }
                                
                                //AJ 01.08.18 Set Parent Location of Truck to WorkOrder's Location
                                locationeMap.get(locId).ParentLocationId = objWorkOrder.LocationId;
                                
                                //Make Status of Returned vehicle to Available
                                locationeMap.get(locId).Status__c = 'Available';                    
                            }
    
                            serviceResourceMap.get(workOrderServiceResourceMap.get(objWorkOrder.Id)).LocationId = null;                 
                        }                   
    
                    }
    
                    //If WorkOrder is of Type 'Standard'
                    else if(workOrderRecordTypeMap.get(objWorkOrder.recordTypeId) == 'Standard'){
                                   
                        if(workOrderAndWOLIMap.get(objWorkOrder.Id) != null && objWorkOrder.LocationId != null && productWiseProductItemMap.get(objWorkOrder.LocationId) != null){
    
                            workOrderLineItemMap = new Map<String, List<WorkOrderLineItem>>();
                            parentProductIdSet = new Set<String>();     
                            childProductIdSet = new Set<String>();
    
                            Integer collectValue = 0;
                            Integer deliverValue = 0;
                             
                            Double loadValue = 0;                        
                            Double truckCapacity = 0;
                            Double trailer1Capacity = 0; 
                            Double trailer2Capacity = 0;
                            Double newUtil = 0;
                            Double peakUtil = 0;
                            Double totalCapacity = 0;

                            //Parent product is used for inventory volumes at sites where we are only interested in ULDs (i.e. the distinction between full and empty is not relevant)
                            //Child product is used for the product on vehicles, where we need to distinguish between empty and full ULDs as they occupy differing space
                            for(WorkOrderLineItem objWOLI : workOrderAndWOLIMap.get(objWorkOrder.Id)){                                                      
    
                                if(objWOLI.Product__r.Parent_Product__c != null){    
                                    parentProductIdSet.add(objWOLI.Product__r.Parent_Product__c);    
                                }
                                if(objWOLI.Product__c != null){    
                                    childProductIdSet.add(objWOLI.Product__c);    
                                }                           
                            }                                               
                            
                            //For product calculation at the physical site (parent product)
                            for(String pId : parentProductIdSet){
                                //For each work order line item
                                for(WorkOrderLineItem objWOLI : workOrderAndWOLIMap.get(objWorkOrder.Id)){                                                  
                                    //If the woli as product defined and it is for this parent product
                                    if(objWOLI.Product__r.Parent_Product__c != null && objWOLI.Product__r.Parent_Product__c == pId){
                                        
                                        //TDF Enhance 2020.09.28: Change to reference new Actual Collect and Actual Deliver fields
                                        //If the woli is a Collect
                                        if(objWOLI.Task__c == 'Collect Product'){    
                                            // if(objWOLI.Actual_Quantity__c != null){    
                                            //     collectValue += Integer.valueOf(objWOLI.Actual_Quantity__c);    
                                            // }else if(objWOLI.Requested_Quantity__c != null){    
                                            //     collectValue += Integer.valueOf(objWOLI.Requested_Quantity__c);    
                                            // }
                                            //If a collect quantity was recorded
                                            if(objWOLI.Actual_Collect_Quantity__c != null){
                                                //Add this to the collected value of this product
                                                collectValue += Integer.valueOf(objWOLI.Actual_Collect_Quantity__c);
                                            }
                                        //Else if the woli is a Deliver
                                        }else if(objWOLI.Task__c == 'Deliver Product'){
                                            // if(objWOLI.Actual_Quantity__c != null){    
                                            //     deliverValue += Integer.valueOf(objWOLI.Actual_Quantity__c);    
                                            // }else if(objWOLI.Requested_Quantity__c != null){    
                                            //     deliverValue += Integer.valueOf(objWOLI.Requested_Quantity__c);    
                                            // }
                                            //If a deliver quantity was recorded
                                            if(objWOLI.Actual_Deliver_Quantity__c != null){
                                                //Add this to the deliver value of this product
                                                deliverValue += Integer.valueOf(objWOLI.Actual_Deliver_Quantity__c);
                                            }
                                        }                                  
                                    }
                                }
                                //Add adjust the values in the map for the Site associated to this work order and reset variables
                                if(productWiseProductItemMap.get(objWorkOrder.LocationId) != null){
                                    productWiseProductItemMap.get(objWorkOrder.LocationId).get(pId).QuantityOnHand += deliverValue;    
                                    productWiseProductItemMap.get(objWorkOrder.LocationId).get(pId).QuantityOnHand -= collectValue;    
                                    collectValue = 0;    
                                    deliverValue = 0;
                                }
                            }                       
                            //For product calculation on the vehicle (child product - i.e more granular level such as consideration of a Full or Empty ULD)
                            for(String pId : childProductIdSet){
                                //For each work order line item
                                for(WorkOrderLineItem objWOLI : workOrderAndWOLIMap.get(objWorkOrder.Id)){
                                    //If the woli as product defined and it is for this child product
                                    if(objWOLI.Product__c != null && objWOLI.Product__c == pId){
                                        
                                        //TDF Enhance 2020.09.28: Change to reference new Actual Collect and Actual Deliver fields
                                        //If the woli is a Collect
                                        if(objWOLI.Task__c == 'Collect Product'){
                                            // if(objWOLI.Actual_Quantity__c != null){                                                
                                            //     collectValue += Integer.valueOf(objWOLI.Actual_Quantity__c);                                            
                                            // }else if(objWOLI.Requested_Quantity__c != null){    
                                            //     collectValue += Integer.valueOf(objWOLI.Requested_Quantity__c);    
                                            // }
                                            //If a collect quantity was recorded
                                            if(objWOLI.Actual_Collect_Quantity__c != null){
                                                //Add this to the collected value of this product
                                                collectValue += Integer.valueOf(objWOLI.Actual_Collect_Quantity__c);
                                            }
                                        //Else if the woli is a Deliver
                                        }else if(objWOLI.Task__c == 'Deliver Product'){
                                            // if(objWOLI.Actual_Quantity__c != null){                                                
                                            //     deliverValue += Integer.valueOf(objWOLI.Actual_Quantity__c);                                            
                                            // }else if(objWOLI.Requested_Quantity__c != null){    
                                            //     deliverValue += Integer.valueOf(objWOLI.Requested_Quantity__c);    
                                            // }
                                            //If a deliver quantity was recorded
                                            if(objWOLI.Actual_Deliver_Quantity__c != null){
                                                //Add this to the deliver value of this product
                                                deliverValue += Integer.valueOf(objWOLI.Actual_Deliver_Quantity__c);
                                            }
                                        }
                                    }                           
                                }
                                
                                //If this work order is assigned to the driver and the driver has a vehicle assigned
                                if(serviceResourceMap.get(workOrderServiceResourceMap.get(objWorkOrder.Id)) != null && locId != null){
                                    //If the vehicle and product in the map
                                    if(productWiseProductItemMap.get(locId) != null && productWiseProductItemMap.get(locId).get(pId) != null){ 
                                        //Add adjust the values in the map for the Vehicle associated to the driver SR and reset variables
                                        productWiseProductItemMap.get(locId).get(pId).QuantityOnHand += collectValue;    
                                        productWiseProductItemMap.get(locId).get(pId).QuantityOnHand -= deliverValue;    
                                        collectValue = 0;    
                                        deliverValue = 0;                     
                                    }
                                }                           
                            }
                            //AJ 29.08.18 If SR has a truck assigned calc new load and util
                            if (locId != null){
                                                          
                                //Loop through all prod items for truck to get new load
                                for(ProductItem objProductItem : productWiseProductItemMap.get(locId).values()){
    
                                    //If ratio specified and quatity is more than 0
                                    if(objProductItem.Product2.ULD_Ratio__c != null && objProductItem.QuantityOnHand > 0){
                                        //Calc load
                                        loadValue = loadValue + ( objProductItem.Product2.ULD_Ratio__c * objProductItem.QuantityOnHand );                                       
                                    }
                                }
                                
                                //Set Load, Vehicle and Trailers on this workorder - new instance as in after trigger
                                WorkOrder objWOUpd = new WorkOrder(Id = objWorkOrder.Id);
                                objWOUpd.Vehicle_Load__c = loadValue;
                                objWOUpd.Vehicle__c = locId;
                                
                                //If has Trailer set Trailers on WO and get capacity to allow util calculation
                                if(parentLocationTrailerMap.get(locId) != null){
                                    Integer i = 0;
                                    for(Schema.Location objLocation : parentLocationTrailerMap.get(locId)){
                                        if(i == 0){
                                            objWOUpd.Trailer_1__c = objLocation.Id;
                                            if(locationeMap.get(objLocation.Id).Capacity__c != null) trailer1Capacity = locationeMap.get(objLocation.Id).Capacity__c;
                                        }
                                        else if(i == 1){
                                            objWOUpd.Trailer_2__c = objLocation.Id;
                                            if(locationeMap.get(objLocation.Id).Capacity__c != null) trailer2Capacity = locationeMap.get(objLocation.Id).Capacity__c;
                                        }
                                        i++;
                                    }
                                }
                                
                                //Add to list
                                workOrderToUpdateList.add(objWOUpd);
                                
                                //Calc new util if load on truck and capacity set
                                if(locationeMap.get(locId).Capacity__c != null) truckCapacity = locationeMap.get(locId).Capacity__c;
                                totalCapacity = truckCapacity + trailer1Capacity + trailer2Capacity;
                                if(totalCapacity > 0 && loadValue > 0){
                                    newUtil = loadValue / totalCapacity ;
                                }

                                //Get peak util, and if not set or if less that new util, then update peak on FFD WO (parent)
                                peakUtil = objWorkOrder.Parent_Peak_Vehicle_Utilisation__c;
                                if(peakUtil == null || newUtil > peakUtil){    
                                    if(parentWorkOrderMap.get(objWorkOrder.Id) != null){
                                        WorkOrder objFFDWOUpd = new WorkOrder(Id = parentWorkOrderMap.get(objWorkOrder.Id)); 
                                        objFFDWOUpd.Peak_Vehicle_Utilisation__c = newUtil * 100;
                                        workOrderToUpdateList.add(objFFDWOUpd); 
                                    }
                                }
                            }
                        }                
                    }
                    //If Drop Off Trailer, Set Parent Location on Trailers from Truck to WO Location
                    else if(workOrderRT == 'Drop_Off_Trailer'){
    
                        //Set Truck as Trailer parent as Site, and Status Available
                        if(objWorkOrder.Trailer_Reg_No_A__c != null && trailerMap.get((objWorkOrder.Trailer_Reg_No_A__c).toUpperCase()) != null){
                            locationeMap.get(trailerMap.get((objWorkOrder.Trailer_Reg_No_A__c).toUpperCase()).Id).ParentLocationId = objWorkOrder.LocationId;
                            locationeMap.get(trailerMap.get((objWorkOrder.Trailer_Reg_No_A__c).toUpperCase()).Id).Status__c = 'Available';
                            System.debug('In Trailer A Mapping ->'+trailerMap.get((objWorkOrder.Trailer_Reg_No_A__c).toUpperCase()).ParentLocationId);
                        }
    
                        //Set Truck as Trailer parent as Site, and Status Available
                        if(objWorkOrder.Trailer_Reg_No_B__c != null && trailerMap.get((objWorkOrder.Trailer_Reg_No_B__c).toUpperCase()) != null){
                            locationeMap.get(trailerMap.get((objWorkOrder.Trailer_Reg_No_B__c).toUpperCase()).Id).ParentLocationId = objWorkOrder.LocationId;
                            locationeMap.get(trailerMap.get((objWorkOrder.Trailer_Reg_No_B__c).toUpperCase()).Id).Status__c = 'Available';
                            System.debug('In Trailer B Mapping ->'+trailerMap.get((objWorkOrder.Trailer_Reg_No_B__c).toUpperCase()).ParentLocationId);
                        }                   
                    }
                }//End if Completed

                //AJ 10.08.18 If Work Order Completed or In Progress (note that it is only In Progress when PDC Fails - based on setting of PDC_Copy flag in flow TDF_Pre_Departure_Check)
                if(objWorkOrder.Status == 'Completed' || objWorkOrder.Status == 'In Progress'){
                    //AJ 31.07.18 If Vehicle issues reported
                    //If Check Status indicates issue reported (on PDC, Return Vehicle, or Drop Trailer). Also do for PDC Copy record
                    if(objWorkOrder.PDC_Road_Worthy__c == 'Failed - Critical Issue' || objWorkOrder.PDC_Road_Worthy__c == 'Passed - Non Critical Issue'){                    
                        //Create Vehicle Inspection Issue records and fault vehicles
                        //If Truck has issue
                        if(objWorkOrder.Truck_Check_Status__c != null){
                            //If Truck field populated, and it's a valid location
                            if(objWorkOrder.Vehicle__c != null && locationeMap.get(objWorkOrder.Vehicle__c) != null){                         
                                bolVIICreated = false;
                                //Non Critical check - check all fields in Truck NonCritical field set
                                for(Schema.FieldSetMember fsm : fsVCTruckNC.getFields()){          
                                    //If false (i.e. failed) create non critical Issue
                                    if(objWorkOrder.get(fsm.getFieldPath())== false){
                                        Vehicle_Inspection_Issues__c vii = new Vehicle_Inspection_Issues__c();
                                        vii.Vehicle__c = objWorkOrder.Vehicle__c;
                                        vii.Work_Order__c = objWorkOrder.Id;
                                        vii.Repair_Order_No__c = objWorkOrder.WO_No_Fault_repair__c;
                                        vii.Item__c = fsm.getLabel();
                                        vii.Severity__c = 'Non Critical'; 
                                        vehicleInspectIssuesToInsertList.add(vii);
                                        bolVIICreated= true;                               
                                    }                                   
                                }
                                //LSE Non Critical check - check all fields in LSE NonCritical field set and prefix with 'LSE - '
                                for(Schema.FieldSetMember fsm : fsVCLSENC.getFields()){          
                                    //If false (i.e. failed) create non critical Issue
                                    if(objWorkOrder.get(fsm.getFieldPath())== false){
                                        Vehicle_Inspection_Issues__c vii = new Vehicle_Inspection_Issues__c();
                                        vii.Vehicle__c = objWorkOrder.Vehicle__c;
                                        vii.Work_Order__c = objWorkOrder.Id;
                                        vii.Repair_Order_No__c = objWorkOrder.WO_No_Fault_repair__c;
                                        vii.Item__c = 'LSE - ' + fsm.getLabel();
                                        vii.Severity__c = 'Non Critical'; 
                                        vehicleInspectIssuesToInsertList.add(vii);
                                        bolVIICreated= true;                               
                                    }                                   
                                }
                                //Critical check - check all fields in Truck Critical field set
                                for(Schema.FieldSetMember fsm : fsVCTruckC.getFields()){          
                                    //If false (i.e. failed) create critical Issue
                                    if(objWorkOrder.get(fsm.getFieldPath())== false){
                                        Vehicle_Inspection_Issues__c vii = new Vehicle_Inspection_Issues__c();
                                        vii.Vehicle__c = objWorkOrder.Vehicle__c;
                                        vii.Work_Order__c = objWorkOrder.Id;
                                        vii.Repair_Order_No__c = objWorkOrder.WO_No_Fault_repair__c;
                                        vii.Item__c = fsm.getLabel();
                                        vii.Severity__c = 'Critical'; 
                                        vehicleInspectIssuesToInsertList.add(vii);
                                        bolVIICreated= true;                                      
                                    }                                   
                                }
                                //Set inspect severity and fault vehicle
                                if(objWorkOrder.Truck_Check_Status__c == 'Critical Issue'){
                                    inspectSeverity = 'Critical';
                                    locationeMap.get(objWorkOrder.Vehicle__c).Status__c = 'Fault';
                                } 
                                else inspectSeverity = 'Non Critical'; 
                                
                                //If Additional Items create for truck
                                if(objWorkOrder.PDC_Additional_Items__c != null && objWorkOrder.PDC_Additional_Items__c != '-'){
                                    Vehicle_Inspection_Issues__c vii = new Vehicle_Inspection_Issues__c();
                                    vii.Vehicle__c = objWorkOrder.Vehicle__c;
                                    vii.Work_Order__c = objWorkOrder.Id;
                                    vii.Repair_Order_No__c = objWorkOrder.WO_No_Fault_repair__c;
                                    vii.Item__c = 'Additional Item: ' + objWorkOrder.PDC_Additional_Items__c;
                                    vii.Severity__c = inspectSeverity; 
                                    vehicleInspectIssuesToInsertList.add(vii);
                                    bolVIICreated = true;
                                }    
                                //If still no issue create undefined with Driver Name
                                if(bolVIICreated == false){
                                    //Create undefined item for Truck
                                    Vehicle_Inspection_Issues__c vii = new Vehicle_Inspection_Issues__c();
                                    vii.Vehicle__c = objWorkOrder.Vehicle__c;
                                    vii.Work_Order__c = objWorkOrder.Id;
                                    vii.Repair_Order_No__c = objWorkOrder.WO_No_Fault_repair__c;
                                    vii.Item__c = 'Undefined ' + inspectSeverity + ' issue by user ' + userinfo.getName();
                                    vii.Severity__c = inspectSeverity; 
                                    vehicleInspectIssuesToInsertList.add(vii);
                                }
                                //Record vehicle id
                                issueVehicleIdSet.add(objWorkOrder.Vehicle__c); 
                            }
                        }
                        
                        //If A Trailer has issue
                        if(objWorkOrder.A_Trailer_Check_Status__c != null){
                            //If A Trailer field populated, and it's a valid location
                            if(objWorkOrder.Trailer_Reg_No_A__c != null && trailerMap.get((objWorkOrder.Trailer_Reg_No_A__c).toUpperCase()) != null){
                                bolVIICreated = false;
                                //Non Critical check - check all fields in A Trailer NonCritical field set
                                for(Schema.FieldSetMember fsm : fsVCATrailerNC.getFields()){          
                                    //If false (i.e. failed) create non critical Issue
                                    if(objWorkOrder.get(fsm.getFieldPath())== false){
                                        Vehicle_Inspection_Issues__c vii = new Vehicle_Inspection_Issues__c();
                                        vii.Vehicle__c = trailerMap.get((objWorkOrder.Trailer_Reg_No_A__c).toUpperCase()).Id;
                                        vii.Work_Order__c = objWorkOrder.Id;
                                        vii.Repair_Order_No__c = objWorkOrder.WO_No_Fault_repair__c;
                                        vii.Item__c = fsm.getLabel();
                                        vii.Severity__c = 'Non Critical'; 
                                        vehicleInspectIssuesToInsertList.add(vii);
                                        bolVIICreated= true;                               
                                    }                                   
                                }
                                //Critical check - check all fields in A Trailer Critical field set
                                for(Schema.FieldSetMember fsm : fsVCATrailerC.getFields()){          
                                    //If false (i.e. failed) create critical Issue
                                    if(objWorkOrder.get(fsm.getFieldPath())== false){
                                        Vehicle_Inspection_Issues__c vii = new Vehicle_Inspection_Issues__c();
                                        vii.Vehicle__c = trailerMap.get((objWorkOrder.Trailer_Reg_No_A__c).toUpperCase()).Id;
                                        vii.Work_Order__c = objWorkOrder.Id;
                                        vii.Repair_Order_No__c = objWorkOrder.WO_No_Fault_repair__c;
                                        vii.Item__c = fsm.getLabel();
                                        vii.Severity__c = 'Critical'; 
                                        vehicleInspectIssuesToInsertList.add(vii);
                                        bolVIICreated= true;
                                    }                                   
                                }
                                //Set inspect severity
                                if(objWorkOrder.A_Trailer_Check_Status__c == 'Critical Issue'){
                                    inspectSeverity = 'Critical';
                                    locationeMap.get(trailerMap.get((objWorkOrder.Trailer_Reg_No_A__c).toUpperCase()).Id).Status__c = 'Fault';
                                }  
                                else inspectSeverity = 'Non Critical'; 
                                
                                //If Additional Items
                                if(objWorkOrder.PDC_Additional_Items_ATrailer__c != null && objWorkOrder.PDC_Additional_Items_ATrailer__c != '-'){
                                    //Create Additional Item for Trailer
                                    Vehicle_Inspection_Issues__c vii = new Vehicle_Inspection_Issues__c();
                                    vii.Vehicle__c = trailerMap.get((objWorkOrder.Trailer_Reg_No_A__c).toUpperCase()).Id;
                                    vii.Work_Order__c = objWorkOrder.Id;
                                    vii.Repair_Order_No__c = objWorkOrder.WO_No_Fault_repair__c;
                                    vii.Item__c = 'Additional Item: ' + objWorkOrder.PDC_Additional_Items_ATrailer__c;
                                    vii.Severity__c = inspectSeverity; 
                                    vehicleInspectIssuesToInsertList.add(vii);
                                    bolVIICreated = true;
                                }    
                                //If still no issue create undefined with Driver Name
                                if(bolVIICreated == false){
                                    //Create undefined item for Trailer
                                    Vehicle_Inspection_Issues__c vii = new Vehicle_Inspection_Issues__c();
                                    vii.Vehicle__c = trailerMap.get((objWorkOrder.Trailer_Reg_No_A__c).toUpperCase()).Id;
                                    vii.Work_Order__c = objWorkOrder.Id;
                                    vii.Repair_Order_No__c = objWorkOrder.WO_No_Fault_repair__c;
                                    vii.Item__c = 'Undefined ' + inspectSeverity + ' Item by user ' + userinfo.getName();
                                    vii.Severity__c = inspectSeverity; 
                                    vehicleInspectIssuesToInsertList.add(vii);
                                }
                                //Record vehicle id
                                issueVehicleIdSet.add(trailerMap.get((objWorkOrder.Trailer_Reg_No_A__c).toUpperCase()).Id); 
                            }
                        } 
                                                               
                        //If B Trailer has issue
                        if(objWorkOrder.B_Trailer_Check_Status__c != null){
                            //If B Trailer field populated, and it's a valid location
                            if(objWorkOrder.Trailer_Reg_No_B__c != null && trailerMap.get((objWorkOrder.Trailer_Reg_No_B__c).toUpperCase()) != null){
                                bolVIICreated = false;
                                //Non Critical check - check all fields in B Trailer NonCritical field set
                                for(Schema.FieldSetMember fsm : fsVCBTrailerNC.getFields()){          
                                    //If false (i.e. failed) create non critical Issue
                                    if(objWorkOrder.get(fsm.getFieldPath())== false){
                                        Vehicle_Inspection_Issues__c vii = new Vehicle_Inspection_Issues__c();
                                        vii.Vehicle__c = trailerMap.get((objWorkOrder.Trailer_Reg_No_B__c).toUpperCase()).Id;
                                        vii.Work_Order__c = objWorkOrder.Id;
                                        vii.Repair_Order_No__c = objWorkOrder.WO_No_Fault_repair__c;
                                        vii.Item__c = fsm.getLabel();
                                        vii.Severity__c = 'Non Critical'; 
                                        vehicleInspectIssuesToInsertList.add(vii);
                                        bolVIICreated= true;                               
                                    }                                   
                                }
                                //Critical check - check all fields in B Trailer Critical field set
                                for(Schema.FieldSetMember fsm : fsVCBTrailerC.getFields()){          
                                    //If false (i.e. failed) create critical Issue
                                    if(objWorkOrder.get(fsm.getFieldPath())== false){
                                        Vehicle_Inspection_Issues__c vii = new Vehicle_Inspection_Issues__c();
                                        vii.Vehicle__c = trailerMap.get((objWorkOrder.Trailer_Reg_No_B__c).toUpperCase()).Id;
                                        vii.Work_Order__c = objWorkOrder.Id;
                                        vii.Repair_Order_No__c = objWorkOrder.WO_No_Fault_repair__c;
                                        vii.Item__c = fsm.getLabel();
                                        vii.Severity__c = 'Critical'; 
                                        vehicleInspectIssuesToInsertList.add(vii);
                                        bolVIICreated= true;
                                    }                                   
                                }
                                //Set inspect severity
                                if(objWorkOrder.B_Trailer_Check_Status__c == 'Critical Issue'){
                                    inspectSeverity = 'Critical';
                                    locationeMap.get(trailerMap.get((objWorkOrder.Trailer_Reg_No_B__c).toUpperCase()).Id).Status__c = 'Fault';
                                } 
                                else inspectSeverity = 'Non Critical'; 
    
                                //If Additional Items
                                if(objWorkOrder.PDC_Additional_Items_BTrailer__c != null && objWorkOrder.PDC_Additional_Items_BTrailer__c != '-'){
                                    //Create Additional Item for Trailer
                                    Vehicle_Inspection_Issues__c vii = new Vehicle_Inspection_Issues__c();
                                    vii.Vehicle__c = trailerMap.get((objWorkOrder.Trailer_Reg_No_B__c).toUpperCase()).Id;
                                    vii.Work_Order__c = objWorkOrder.Id;
                                    vii.Repair_Order_No__c = objWorkOrder.WO_No_Fault_repair__c;
                                    vii.Item__c = 'Additional Item: ' + objWorkOrder.PDC_Additional_Items_BTrailer__c;
                                    vii.Severity__c = inspectSeverity; 
                                    vehicleInspectIssuesToInsertList.add(vii);
                                    bolVIICreated = true;
                                }    
                                //If still no issue create undefined with Driver Name
                                if(bolVIICreated == false){
                                    //Create undefined item for Trailer
                                    Vehicle_Inspection_Issues__c vii = new Vehicle_Inspection_Issues__c();
                                    vii.Vehicle__c = trailerMap.get((objWorkOrder.Trailer_Reg_No_B__c).toUpperCase()).Id;
                                    vii.Work_Order__c = objWorkOrder.Id;
                                    vii.Repair_Order_No__c = objWorkOrder.WO_No_Fault_repair__c;
                                    vii.Item__c = 'Undefined ' + inspectSeverity + ' Item by user ' + userinfo.getName();
                                    vii.Severity__c = inspectSeverity; 
                                    vehicleInspectIssuesToInsertList.add(vii);
                                }
                                //Record vehicle id
                                issueVehicleIdSet.add(trailerMap.get((objWorkOrder.Trailer_Reg_No_B__c).toUpperCase()).Id); 
                            }
                        } 
                    }
                }//End if Completed or In Progress                
            }   
            /*Main Trigger for loop Ends*/          

            System.debug('productItemToUpdateList- >'+productItemToUpdateList);
            if(productItemToUpdateList.size()>0){
                update productItemToUpdateList;
            }

            productItemToUpdateList = new List<ProductItem>();

            for(String locationIdStr : locationProductItemMap.keyset()){
                productItemToUpdateList.addAll(productWiseProductItemMap.get(locationIdStr).values());      
            }

            for(ProductItem objProductItem : productItemToUpdateList){
                if(objProductItem.QuantityOnHand < 0){
                    objProductItem.QuantityOnHand = 0;
                }
            }

            if(productItemToUpdateList.size()>0){
                update productItemToUpdateList;
            }           

            /* To resolve W-000173 bug Code added by - Gaurav Begin */
            Set<String> serviceResourceLocationIdSet = new Set<String>();
            for(ServiceResource objServiceResource : serviceResourceMap.values()){
                if(objServiceResource.LocationId != null){
                    serviceResourceLocationIdSet.add(objServiceResource.LocationId);
                }
            }

            List<ServiceResource> serviceResourceToUpdateList = new List<ServiceResource>();
            serviceResourceToUpdateList = [SELECT Id, LocationId FROM ServiceResource WHERE LocationId IN : serviceResourceLocationIdSet];
            if(serviceResourceToUpdateList.size()>0){
                for(ServiceResource objServiceResource : serviceResourceToUpdateList){
                    objServiceResource.LocationId = null;
                }
            }
            if(serviceResourceToUpdateList.size()>0){
                update serviceResourceToUpdateList;
            }
            /* To resolve W-000173 bug Code added by - Gaurav End */

            //AJ 08.08.18 For all vehicle set to In Use, set all Fixed VII to Closed
            if(inuseVehicleIdSet.size() > 0 ){
                //Get VII to update and set status to Closed
                vehicleInspectIssuesToUpdateList = [SELECT Id, Status__c FROM Vehicle_Inspection_Issues__c WHERE Status__c = 'Fixed' AND Vehicle__c IN : inuseVehicleIdSet];
                for(Vehicle_Inspection_Issues__c viiexistingfixed : vehicleInspectIssuesToUpdateList){
                    viiexistingfixed.Status__c = 'Closed';
                }
                if(vehicleInspectIssuesToUpdateList.size() > 0){
                    update vehicleInspectIssuesToUpdateList;
                }
            }            
            
            //AJ 08.08.18 If inspections issues recorded, remove any already existing           
            if(issueVehicleIdSet.size() > 0 ){                
                //Build set of existing items for vehicles - with Vehicle Id + Issue + Repair No as key
                for(Vehicle_Inspection_Issues__c viiexisting : [SELECT Vehicle__c, Item__c, Repair_Order_No__c FROM Vehicle_Inspection_Issues__c WHERE Status__c = 'New' AND Vehicle__c IN : issueVehicleIdSet]){
                    vehicleIDItemExisting = viiexisting.Vehicle__c + viiexisting.Item__c + viiexisting.Repair_Order_No__c;
                    vehicleIssuesExistingSet.add(vehicleIDItemExisting);
                }
                //For each new issue
                for (Integer i = (vehicleInspectIssuesToInsertList.size()-1) ; i >= 0 ; i--){
                    vehicleIDItemNew = vehicleInspectIssuesToInsertList[i].Vehicle__c + vehicleInspectIssuesToInsertList[i].Item__c + vehicleInspectIssuesToInsertList[i].Repair_Order_No__c;
                    //If already existing then remove from list
                    if(vehicleIssuesExistingSet.contains(vehicleIDItemNew)){
                        vehicleInspectIssuesToInsertList.Remove(i);
                    }
                }               
            }
            //AJ 31.07.18 Insert Vehicle Inspection Issue records
            if(vehicleInspectIssuesToInsertList.size() > 0){
                insert vehicleInspectIssuesToInsertList;
            }
            
            System.debug('serviceResourceMap ->'+serviceResourceMap);
            update serviceResourceMap.values();
            System.debug('locationeMap ->'+locationeMap);
            update locationeMap.values();   

            //AJ 27.08.18 update work order to set Util
            if(workOrderToUpdateList.size() > 0){
                update workOrderToUpdateList;
            }

            /*update trailerMap.values();
            locList = new List<Schema.Location>();
            for(String locationIdStr : parentLocationTrailerMap.keyset()){
                locList.addAll(parentLocationTrailerMap.get(locationIdStr));        
            }
            
            if(locList.size()>0){
                update locList;
            }*/
            
        }catch(Exception e){
            System.debug('Error Message ->'+e.getMessage());
            System.debug('Error Message Line Number ->'+e.getLineNumber());            
            Database.rollback(sp);
            //Log error to Exception object for analysis
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'TDF', 'TDF_WorkOrderTriggerUtility', 'workOrderUpdateMethod', 'TDF_WorkOrderTrigger', LoggingLevel.ERROR);          
        }
    }
}