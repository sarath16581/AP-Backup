/******************************************************************************************************
 * @description 	Trigger on Knowledge__kav object. Dispatch to module based trigger handler to handle all trigger events.
 * 					1. Creates the datacategory records based the recordtype of knowledge articles
 * 					2. Deletes the unwanted datacategories that are added on knowledge record
 *
 * @author 			Raghav Ravipati
 * @test			KnowledgeArticleVersionTriggerTest
 * @date 			2024-05-23
 * *****************************************************************************************************
 * @changelog
 * *****************************************************************************************************
 */
trigger KnowledgeArticleVersionTrigger on Knowledge__kav (after insert, after update) {
	if(!TriggerHelper.isTriggerDisabled(String.valueOf(Knowledge__kav.sObjectType))){ // verify if triggers are disabled
	(new KnowledgeArticleVersionTriggerHandler()).dispatch(); // invoke domain based trigger dispatch
	}
}