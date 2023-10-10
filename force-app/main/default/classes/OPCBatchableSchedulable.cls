/**************************************************
* @Test OPCBatchableSchedulable_Test
Type: Apex Schedulable Batch Job Class for Generation of Opportunity Product Classification (OPC)
Purpose: Generates the Opportunity Product Classification (OPC) record from their source revenue schedule(s) and 
 finds any matching actual revenue against it from the current financial year and last financial year
Used By: 
History:
--------------------------------------------------
13.08.2012 M. Isidro (Cloud Sherpas) Created
04.09.2012 M. Isidro (Cloud Sherpas) Added test coverage
28/06/2022 KMcGuire	Modified for including related account sales in OPC classification
28/06/2022 KMcGuire	Separated test class from code
26/09/2023 processing in batches to avoid govenour limits.
**************************************************/
global class OPCBatchableSchedulable implements Schedulable {

	global void execute(SchedulableContext sc) {
		GenerateOPCBatchable genOPC = new GenerateOPCBatchable();
		Database.executeBatch(genOPC,50);
	}
}