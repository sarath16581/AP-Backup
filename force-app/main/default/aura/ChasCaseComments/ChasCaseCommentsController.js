({
	doInit : function(cmp, event, helper) { 
		helper.fetchCaseComments(cmp);
		helper.setLoggedInUserName(cmp);
		
	},

	handleCase : function(cmp, event, helper) {
		cmp.set('v.isLoadingStatus', false)
		var newStatus = event.getParam("value").Enquiry_Status__c;
		//console.log('newStatus='+newStatus);
		//cmp.set('v.caseStatus', newStatus);
		if (newStatus === "In progress") 	 cmp.set('v.textAreaLabel', 'Add a comment');
		if (newStatus === "Resolved") 		 cmp.set('v.textAreaLabel', 'Why do you consider your enquiry unresolved?');
		if (newStatus === "Action required") cmp.set('v.textAreaLabel', 'Please provide details requested below');
	},

	closeCase : function(cmp, event, helper) {
		var callback = event.getParam('arguments').callback;
		helper.updateCaseStatus(cmp, "Closed", callback, helper)
	},
	
	showCommentInput : function(cmp, event, helper) {
		cmp.set('v.showInput',true);

		// push event to analaytics that the add comment button was pressed
		helper.pushAnalyticsEvent(cmp, 'case', 'comment:add');
	},
	
	cancelNewComment: function(cmp, event, helper) {
		cmp.set('v.showInput',false);
	},

	createNewComment : function(cmp, event, helper) {
		event.preventDefault(); // Required for button type="submit"
		if(!cmp.get('v.isSendingComment') && helper.validateNewComment(cmp.find('newComment'))){
			helper.createNewCaseComment(cmp, helper);
		}
	},
	
	onchange: function(cmp, event, helper) {
		var srcCmp = event.getSource();
		var fieldName = event.getParam("name");
		if (fieldName === 'newComment') {
			helper.validateNewComment(cmp.find('newComment'));
		}
	},

	showModal: function(cmp, evt, helper) {
		var compAttributes = {
			"closeCaseAction" : cmp.closeCase
		};

		$A.createComponent("c:ChasCaseModal", compAttributes,
			function(content, status) {
				if (status === "SUCCESS") {

					cmp.find('overlayLib').showCustomModal({
						body: content, 
						showCloseButton: true,
						cssClass: "mymodal"
					})
				}                               
			}
		);
	}
})