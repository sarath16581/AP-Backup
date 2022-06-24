/**
* @author Kamil Szyc
* @date 2022-06-24
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Controller class to for printing CCP routes.
 */

public with sharing class PUD_RoutesPrintController {
    List<PUD_Route__c> routes {get;set;}
    //Constructor
    public PUD_RoutesPrintController(ApexPages.StandardSetController ssc){
        //Identify the selected records from Listview
        Set<Id> selectedRouteIDs = new Set<Id>();
        for(PUD_Route__c rts : (PUD_Route__c[])ssc.getSelected()){
            selectedRouteIDs.add(rts.Id);
        }
        routes = getSelectedRoutesWithBookings(selectedRouteIDs);

    }
    @TestVisible private static List<PUD_Route__c> getSelectedRoutesWithBookings(Set<Id> routeIds) {
        return PUDRoutesSelector.newInstance().selectByIdWithActiveBookings(
                routeIds,
                null,
                new Set<Object>()
        );
    }

}