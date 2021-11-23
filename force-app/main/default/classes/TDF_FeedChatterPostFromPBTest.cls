@isTest(SeeAllData = true)
public class TDF_FeedChatterPostFromPBTest{

	static testmethod void validateFeedChatterPostFromPB(){

		List<TDF_FeedChatterPostFromPB.InputValues> inputValues = new List<TDF_FeedChatterPostFromPB.InputValues>();
		List<WorkOrder> workOrderList = new List<WorkOrder>();
        List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();
        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;
    
        String standardWORecordType = objTestDataFactory.getWorkOrderRTId('Standard');

        for(Integer i=0; i<10; i++){
            WorkOrder objWorkOrder = objTestDataFactory.getWorkOrder(standardWORecordType);
            objWorkOrder.Duty_Board__c = objRouteTemplate.Id;
            workOrderList.add(objWorkOrder);
        }
        insert workOrderList;

        Integer counter = 0;

        for(WorkOrder objWorkOrder : workOrderList){
            ServiceAppointment objServiceAppointment = new serviceAppointment();
            objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now().addDays(counter), counter++);                
        	objServiceAppointment.Duty_Board__c = objRouteTemplate.Id;
            serviceAppointmentList.add(objServiceAppointment);
        }
        insert serviceAppointmentList;

        for(WorkOrder objWorkOrder : workOrderList){
        	TDF_FeedChatterPostFromPB.InputValues objInput = new TDF_FeedChatterPostFromPB.InputValues();
        	objInput.workOrderId = objWorkOrder.Id;
        	objInput.chatterMsg = 'Test Chatter Post';
        	inputValues.add(objInput);
        }

        TDF_FeedChatterPostFromPB.postChatterFeed(inputValues);
	}
}