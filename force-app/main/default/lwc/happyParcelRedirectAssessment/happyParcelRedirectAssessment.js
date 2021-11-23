/**
 * @description Happy Parcel Redirect Assessment
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 */
import {LightningElement, api, track} from "lwc";
import { get, CONSTANTS } from "c/happyParcelService";
import HappyParcelBase from "c/happyParcelBase";

export default class HappyParcelRedirectAssessment extends HappyParcelBase {
	@api loading = false;

	/**
	 * Grab the data we need from the analytics response and discard the rest
	 */
	@api analyticsApiResult;

	helpText = CONSTANTS.LABEL_HAPPYPARCELREDIRECTIONHELPTEXT;

	get hasInTransitRedirect() {
		return get(this.analyticsApiResult, 'current_address', false) && get(this.analyticsApiResult, 'previous_address', false);
	}

	get redirectFromLine1() {
		return get(this.analyticsApiResult, 'previous_address_1', '');
	}
	get redirectFromLine2() {
		return get(this.analyticsApiResult, 'previous_address_2', '');
	}
	get redirectFromSuburbPostcode() {
		return get(this.analyticsApiResult, 'previous_suburb', '') + (get(this.analyticsApiResult, 'previous_to_postcode', '') ? ' ' : '') + get(this.analyticsApiResult, 'previous_to_postcode', '');
	}
	get redirectToLine1() {
		return get(this.analyticsApiResult, 'current_address_1', '');
	}
	get redirectToLine2() {
		return get(this.analyticsApiResult, 'current_address_2', '');
	}
	get redirectToSuburbPostcode() {
		return get(this.analyticsApiResult, 'current_suburb', '') + (get(this.analyticsApiResult, 'current_to_postcode', '') ? ' ' : '') + get(this.analyticsApiResult, 'current_to_postcode', '');
	}

}