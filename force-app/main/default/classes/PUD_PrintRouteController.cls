/**
* @author Kamil Szyc
* @date 2022-06-24
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Controller class to for printing CCP routes.
 */

public with sharing class PUD_PrintRouteController {
    public List<PUD_Route__c> routes { get; set; }
    public PUD_Route__c route { get; set; }
    //Constructor
    public PUD_PrintRouteController(ApexPages.StandardSetController ssc) {
        //Identify the selected records from Listview
        Set<Id> selectedRouteIDs = new Set<Id>();
        for (PUD_Route__c rts : (PUD_Route__c[]) ssc.getSelected()) {
            selectedRouteIDs.add(rts.Id);
        }
        routes = getSelectedRoutesWithBookings(selectedRouteIDs,new Set<Object>{PUDRoutesSelector.Options.WITH_DEPOT});
    }
    public PUD_PrintRouteController(ApexPages.StandardController sc) {
        //Identify the selected records from Listview
        Set<Id> selectedRouteIDs = new Set<Id>();
        selectedRouteIDs.add(sc.getId());
        route = getSelectedRoutesWithBookings(selectedRouteIDs, new Set<Object>{PUDRoutesSelector.Options.WITH_DEPOT})[0];
    }
    @TestVisible private static List<PUD_Route__c> getSelectedRoutesWithBookings(Set<Id> routeIds,Set<Object>selectorOptions) {
        return PUDRoutesSelector.newInstance().selectByIdWithAllBookings(
                routeIds,
                new Set<Id>(),
                selectorOptions
        );
    }

}