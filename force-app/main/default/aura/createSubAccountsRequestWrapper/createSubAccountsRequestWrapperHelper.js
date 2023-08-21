/*
  * @author       : Dheeraj Mandavilli. dheeraj.mandavilli@auspost.com.au
  * @date         : 24/04/2021
  * @description  : Component used as wrapper for Sub Account Request Quick Action Button from Billing Account. It has following features
  *                 1. It invokes createSubAccounts LWC component.
  *                 2. It also contains validation checks on Billing Account
  @changelog
  2021-04-24    Dheeraj Mandavilli Created
  2023-08-18    Harry Wang - Updated navigation to NavigateSubAccountRequestWrapper
*/

({
	navigateToCreateSubAccountsCmp : function(component, isTEAM) {
		component.find("navigationService").navigate({
			type: "standard__component",
			attributes: {
				componentName: "c__NavigateSubAccountRequestWrapper"
			},
			state: {
				"c__recordId": component.get("v.recordId"),
				"c__initialLoad": component.get("v.initialLoad"),
				"c__isTEAMRequest": isTEAM
			}
		});
	}
})