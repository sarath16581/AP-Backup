global class APT_CleanupAPPCRateCardDocuments implements Schedulable {
   global void execute(SchedulableContext SC) {
      APT_CleanupAPPCRateCard cleanupAPPCRateCard  = new APT_CleanupAPPCRateCard(); 
       database.executebatch(cleanupAPPCRateCard);
   }
}