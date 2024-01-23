/*
  * @author       : haraprasad.sahoo@auspost.com.au
  * @date         : 23/03/2020
  * @description  : Component for Case Print(Single)
--------------------------------------- History --------------------------------------------------
23.03.2020    Hara Sahoo    Created
08.09.2022	  Naveen Rajanna 	REQ2963906: domain check to populate prefix myNetwork if required
06.07.2023    Swati Mogadala    INC2170610: After summer '23 release, _target fix on NavigationMixin
*/
import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
export default class myNetworkPrintSingleCase extends NavigationMixin(LightningElement) {
	@api recordId;
	@track url;

	handleClick(evt) {
		evt.preventDefault();
		evt.stopPropagation();	
		
		this[NavigationMixin.GenerateUrl]({
			type: 'standard__webPage',
			attributes: {
				url: '/apex/myNetworkCasePDFGenerator?selectedIds=' + this.recordId
			}
		}).then(generatedUrl => {
			window.open(generatedUrl, '_blank');
		});
	}
}