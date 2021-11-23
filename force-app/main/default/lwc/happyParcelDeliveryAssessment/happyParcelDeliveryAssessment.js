/**
 * @description Happy Parcel Delivery Assessment
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 */
import { LightningElement, api, track } from "lwc";
import { getConfig, get, CONSTANTS } from "c/happyParcelService";

export default class HappyParcelDeliveryAssessment extends LightningElement {

	@api loading = false;
	@api analyticsApiResult;

	helpText = CONSTANTS.LABEL_HAPPYPARCELDISTANCEHELPTEXT;

	connectedCallback() {
		getConfig().then(result => {
			this.thereshold = result.manifestAssessmentHappyThreshold;
		});
	}

	get isHappy() {
		return parseFloat(get(this.analyticsApiResult, 'distance_calculated', 0)) < this.threshold;
	}

	get isSad() {
		return parseFloat(get(this.analyticsApiResult, 'distance_calculated', 0)) >= this.threshold;
	}

	get isAvailable() {
		return get(this.analyticsApiResult, 'distance_calculated', null) !== null;
	}

	get threshold() {
		return parseFloat(get(this.analyticsApiResult, 'distance_threshold', 0));
	}

	get thresholdDisplay() {
		return parseFloat(get(this.analyticsApiResult, 'distance_threshold', 0)) + get(this.analyticsApiResult, 'distance_threshold_unit', '');
	}

	get thresholdSymbol() {
		return parseFloat(get(this.analyticsApiResult, 'distance_threshold', 0)) + get(this.analyticsApiResult, 'distance_threshold_unit', '');
	}

	get manifestGps() {
		const latitude = get(this.analyticsApiResult, 'latitude_dpid', false);
		const longitude = get(this.analyticsApiResult, 'longitude_dpid', false);
		return (!latitude || !longitude ? [] : [latitude, longitude]);
	}

	get scanEventGps() {
		const latitude = get(this.analyticsApiResult, 'latitude_scan', false);
		const longitude = get(this.analyticsApiResult, 'longitude_scan', false);
		return (!latitude || !longitude ? [] : [latitude, longitude]);
	}

	get mapLink() {
		const manifestGps = this.manifestGps;
		const deliveryGps = this.scanEventGps;

		if(deliveryGps.length === 2 && manifestGps.length === 2) {
			return 'https://maps.google.com?daddr=' + encodeURIComponent(manifestGps[0] + ',' + manifestGps[1]) + '&saddr=' + encodeURIComponent(deliveryGps[0] + ',' + deliveryGps[1]);
		} else if(deliveryGps.length === 2) {
			return 'https://maps.google.com?q=' + encodeURIComponent(deliveryGps[0] + ',' + deliveryGps[1]);
		} else if(manifestGps.length === 2) {
			return 'https://maps.google.com?q=' + encodeURIComponent(manifestGps[0] + ',' + manifestGps[1]);
		}
	}

}