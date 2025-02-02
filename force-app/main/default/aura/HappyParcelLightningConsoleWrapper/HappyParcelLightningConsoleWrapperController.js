/**
 * @description
 * This wrapper is to catch a link event that requires navigation based on Lightning. LWC currently doesnt support workspaceAPI so this aura wrapper will handle the heavy lifting
	Note: This is only needed when Happy Parcel is included in a Lightning App. Lightning out via Visualforce can be configured to catch the same DOM event this aura component catches
			Once LWC support workspaceAPI, happyParcel LWC can be reconfigured to handle these links directly without the need for this wrapper.
 * @author Nathan Franklin
 * @date 2020-06-30
 * @changelog
 *
 */
({
	handleIdLinkClick: function(component, event) {
		var recordId = event.getParam('id');
		console.log('recordId', recordId);
		var workspaceAPI = component.find("workspace");
		workspaceAPI.openTab({
			pageReference: {
				"type": "standard__recordPage",
				"attributes": {
					"recordId": recordId,
					"actionName": "view"
				},
				"state": {}
			},
			focus: true
		});
	}
});