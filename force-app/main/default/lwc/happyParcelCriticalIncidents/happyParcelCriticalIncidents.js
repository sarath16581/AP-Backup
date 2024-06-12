/**
 * @description Happy Parcel Critical Incidents
 * @author Raghav Ravipati
 * @date 2024-06-03
 * @group Tracking
 * @changelog
 * 2024-06-03 - Raghav Ravipati
 */
import { api, track } from "lwc";
import { getCriticalIncidentDetails } from "c/happyParcelService";
import HappyParcelBase from "c/happyParcelBase";
export default class HappyParcelCriticalIncidents extends HappyParcelBase {
	@track showSpinner;
	@track criticalIncidents;
	@track displayMessage;
	@track baseURL;
	@api networkId;
	@api eventId;	

	//Send close event to parent with event Id
	closePopup() {
		this.dispatchEvent(
			new CustomEvent("closepopup", {
				detail: this.eventId
			})
		);
	}

	async connectedCallback() {
		const NO_CRITICAL_INCIDENTS = 'No critical incidents found.';
		const INTERNAL_ERROR = 'Someting went wrong please try again later.';

		if (this.networkId) {
			this.showSpinner = true;
			try {
				const result = await getCriticalIncidentDetails(this.networkId);
				if (result && result.length) {
					this.criticalIncidents = result;
				}
				else{
					this.displayMessage = NO_CRITICAL_INCIDENTS;
				}
			} catch (error) {
				this.displayMessage = INTERNAL_ERROR;
			}
		}
		this.showSpinner = false;
	}

	handleKnowledgeClick(event) {
		let recordId = event.target.dataset.id;
		this.dispatchEvent(new CustomEvent("idclick", { detail: { id: recordId }, bubbles: true, composed: true }));
	}
}
