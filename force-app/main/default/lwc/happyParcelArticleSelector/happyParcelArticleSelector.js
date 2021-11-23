/**
 * @description Allows a user to select an article to query Happy Parcels with
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 * 2021-10-26 - Nathan Franklin - Force uppercase on data input
 */
import { LightningElement, api } from "lwc";
import { safeTrim } from "c/happyParcelService";

export default class HappyParcelArticleSelector extends LightningElement {

	@api readOnly;
	@api loading = false;
	@api trackingId = '';

	handleSearch(e) {
		if(e.which === 13) {
			this.trackingId = safeTrim(this.template.querySelector('lightning-input').value);
			console.log(this.trackingId);

			// trigger a search in the parent component
			// NOTE: the parent component will feed loading=true once the search has begun
			this.dispatchEvent(new CustomEvent('search', { detail: this.trackingId}));
		}
	}

	/**
	 * Ensures that entered input is converted to uppercase for data consistency
	 */
	convertToUppercase(e) {
		const { selectionStart, selectionEnd } = e.currentTarget;
		e.currentTarget.value = e.currentTarget.value.toUpperCase();
		e.currentTarget.selectionStart = selectionStart;
		e.currentTarget.selectionEnd = selectionEnd;
	}

}