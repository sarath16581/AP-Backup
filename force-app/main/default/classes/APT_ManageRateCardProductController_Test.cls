/**
Description: This apex class is test class for APT_ManageRateCardProductsController.
Created By - Mausam Padhiyar
Created Date - 13th Oct, 2015
Last Modified By -
Last Modified Date - 
**/
@isTest
private with sharing class APT_ManageRateCardProductController_Test {
    /*
        This is a test method to test functionality
    */
    static testMethod void testMethod1() {
        APT_ManageRateCardProductsController controller = new APT_ManageRateCardProductsController();
        
        test.startTest();
        
        system.assert(controller.getStartHours().size() > 0);        
        system.assert(controller.getStartDates().size() > 0);
        system.assert(controller.getStartMins().size() > 0);
        system.assert(controller.getStartDates().size() > 0);
        
        DateTime dt = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        controller.startDate = String.valueOf(dt.day());
        controller.startHour = String.valueOf(dt.hour());
        controller.startMin = String.valueOf(dt.minute());
        
        PageReference pgRef = controller.calculateInternationalPricing();
        system.assert(pgRef == null);
        
        pgRef = controller.calculateDomesticPricing();
        system.assert(pgRef == null);
        
        test.stopTest();
    }    
/*
        This is a test method to test functionality
    */
    static testMethod void testMethod2() {
        APT_ManageRateCardProductsController controller = new APT_ManageRateCardProductsController();
        
        test.startTest();
        
        system.assert(controller.getStartHours().size() > 0);        
        system.assert(controller.getStartDates().size() > 0);
        system.assert(controller.getStartMins().size() > 0);
        system.assert(controller.getStartDates().size() > 0);
        
        controller.startDate = '10';
        controller.startHour = '10';
        controller.startMin = '10';
        
        PageReference pgRef = controller.calculateInternationalPricing();
        system.assert(pgRef == null);
        
        pgRef = controller.calculateDomesticPricing();
        system.assert(pgRef == null);
        
        test.stopTest();
    }
}