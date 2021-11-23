global class InboundLogMover implements Database.Batchable<Task> {
	global Iterable<Task> start(Database.BatchableContext context){
		return [SELECT Description,Subject,Type,OwnerId FROM Task WHERE CallType IN ('Inbound', 'Outbound','Consult') limit 500000];
	}
	global void execute(Database.BatchableContext context, List<Task> scope){
		processTasks(scope);
	}
	
	void processTasks(List<Task> tasks){
		List<Task> shortListed = new List<Task>();
		List<Attachment> newAttachments = new List<Attachment>();
		for(Task t: tasks){
			if(!String.isBlank(t.description) && t.description.startsWith('{')){
				newAttachments.add(new Attachment(Name = 'InboundLog.txt', parentId = t.id, ownerId = t.OwnerId, body = Blob.valueOf(t.description)));
				t.Description = 'For logs, please see attachment.';
				shortListed.add(t);
			}
		}
		insert newAttachments;
		update shortListed;
	}
	
	global void finish(Database.BatchableContext context){     
    } 
}