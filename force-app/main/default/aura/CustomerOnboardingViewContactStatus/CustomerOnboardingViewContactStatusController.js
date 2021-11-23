({
	getContactList : function(component, event, helper) { 
        var actions = [
            { label: 'Show Contacts', name: 'ShowContacts' }
        ];
        component.set('v.columns',[
            {label: 'Case Number', fieldName: 'parentCaseURL', type: 'url', 
             typeAttributes: {
           		label: {fieldName: 'parentCaseNumber'}
       		}},
            {label: 'Status', fieldName: 'parentCaseStatus', type: 'text'},
            {label: 'Subject', fieldName: 'parentCaseSubject', type: 'text'},
            {label: 'Number of Contacts', fieldName: 'contactSize', type: 'text'},
            { type: 'action', typeAttributes: { rowActions: actions } }
        ]);
		component.set("v.displaySpinner",true);
		var action = component.get("c.getContacts");
		console.log('caseId List '+component.get("v.caseIdList"));
		action.setParams({
			"caseIds" : component.get("v.caseIdList")
		});

		action.setCallback(this, function(response){
			var state = response.getState();
			console.log(' state '+state);
            if (state === "SUCCESS") {
				component.set("v.parentCaseMappingWithContactDetails",response.getReturnValue());
				component.set("v.displaySpinner",false);
			}
			else if (state === "ERROR") {
				console.log('response on error '+response);
				component.set("v.ErrorString",response.getError()[0].message);
				component.set("v.displayError", true);
				component.set("v.displaySpinner",false);
			}
			
		});

		$A.enqueueAction(action);
	},

	navigateTorecordPage : function(component, event, helper) {
		component.set("v.displaySpinner",true);
		var recordId = event.target.id;
		window.open('/'+recordId, '_blank');
		component.set("v.displaySpinner",false);
	},
    
    showContacts : function(component, event, helper){
        component.set('v.isModalOpen',true);
        var contactDetails = event.getParam('row');
		var assetList = [];
        for(var assetGrouping in contactDetails.contactdetailsWrapper){
            for(var assets in contactDetails.contactdetailsWrapper[assetGrouping].AssetGroupingWrapperList){
                console.log(JSON.stringify(contactDetails.contactdetailsWrapper[assetGrouping].AssetGroupingWrapperList[assets].assetName));
                for(var asset in contactDetails.contactdetailsWrapper[assetGrouping].AssetGroupingWrapperList[assets].assetList){                    
                  console.log(JSON.stringify(contactDetails.contactdetailsWrapper[assetGrouping].AssetGroupingWrapperList[assets].assetList[asset]));
                    var assetRec = contactDetails.contactdetailsWrapper[assetGrouping].AssetGroupingWrapperList[assets].assetList[asset];
					assetList.push(assetRec);
                }
            }
        }
        component.set('v.assets',assetList);
    },
    
    closePopUp : function(component, event, helper){
        component.set('v.isModalOpen',false);
    }
})