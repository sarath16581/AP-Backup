/*
  * @author       : haraprasad.sahoo@auspost.com.au
  * @date         : 23/03/2020
  * @description  : Component for Case Print(Single)
--------------------------------------- History --------------------------------------------------
23.03.2020    Hara Sahoo    Created
08.09.2022	  Naveen Rajanna 	REQ2963906: domain check to populate prefix myNetwork if required
*/
import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
export default class myNetworkPrintSingleCase extends NavigationMixin(LightningElement) {
	@api recordId;
	@track url;
	@track myDomainUrl;
	@track siteName;
	@track instanceName;
	sfdcBaseURL;

	connectedCallback() {
		this.sfdcBaseURL = window.location.origin;
		var hostname = window.location.hostname;
		this.VFpage = {
			type: "standard__webPage",
			attributes: {
				url:
					"https://" +
					hostname +
					(this.sfdcBaseURL.includes("auspostbusiness") ? "/myNetwork" : "") +
					"/apex/myNetworkCasePDFGenerator?selectedIds=" +
					encodeURI(this.recordId),
			},
		};
	}

	handleClick(evt) {
		evt.preventDefault();
		evt.stopPropagation();
		// Navigate to the Case print VF page.
		this[NavigationMixin.Navigate](this.VFpage);
	}
}
