/**
 * @description Happy Parcel Critical Incidents
 * @author Raghav Ravipati
 * @date 2024-06-03
 * @group Tracking
 * @changelog
 * 2024-06-03 - Raghav Ravipati
 */
import { api, track } from "lwc";
import HappyParcelBase from "c/happyParcelBase";
export default class HappyParcelCriticalIncidents extends HappyParcelBase {
	@api eventId;
	@api criticalIncidents;

	//Send close event to parent with event Id
	closePopup() {
		this.dispatchEvent(
			new CustomEvent("closepopup", {
				detail: this.eventId
			})
		);
	}

	handleKnowledgeClick(event) {
		let recordId = event.target.dataset.id;
		this.dispatchEvent(new CustomEvent("idclick", { detail: { id: recordId }, bubbles: true, composed: true }));
	}
}
