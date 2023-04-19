/**
 * Created by hasan on 18/04/2023.
 */

public virtual inherited sharing class BaseUtil {

    /**
         @Description : Returns the next business day considering the weekends and holidays
         @param : date dateSent(EDD derived from consignment service) , integer maxDays(days configured as the latest date by which consignments shoulf arrive)
         @return : NA
     */
    public static Date calculateNextBusinessDay(Date dateSent, Integer maxDays){
        Datetime maxDeliveryDate =  addDays(dateSent,maxDays);
        return maxDeliveryDate.date();
    }

    /**
     * Add business days to a given date based on the parameters passed
     * */
    public static Datetime addDays(Datetime startDate, Integer days) {
        Id bHours = getDefaultBusinessHours().Id;

        for (Integer elapsed = 0; elapsed < days; elapsed++) {
            //Add 1 day
            startDate = startDate.addDays(1);

            //Check if new date is within working days
            if (!BusinessHours.isWithin(bHours, startDate)) {
                //If new date is not within working days, get new working day
                startDate = BusinessHours.nextStartDate(bHours, startDate);
            }
        }
        return startDate;
    }

    public static BusinessHours getDefaultBusinessHours() {
        return BusinessHoursSelector.newInstance().selectDefault(true);
    }

    //-- Case Wrapper Class
    public class CaseWrapper {
        @AuraEnabled public String caseNumber { get; set; }
        @AuraEnabled public String caseStatus { get; set; }
    }
}