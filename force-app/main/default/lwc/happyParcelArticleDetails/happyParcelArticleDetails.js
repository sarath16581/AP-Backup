/**
 * @description Happy Parcel Article Details
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 */
import { LightningElement, api, track } from "lwc";
import { getConfig, CONSTANTS, get } from 'c/happyParcelService'
import HappyParcelBase from "c/happyParcelBase";

export default class HappyParcelArticleDetails extends HappyParcelBase {

	@api loading = false;

	@api trackingApiResult;

	// denotes that we should be loading the fieldset from the consignment fieldset rather than the article fieldset
	@api useConsignmentFieldSet;

	@track fields = [];

	connectedCallback() {
		getConfig().then(result => {
			if(this.useConsignmentFieldSet) {
				this.fields = result.consignmentFields;
			} else {
				this.fields = result.articleFields;
			}
		});
	}

	// this is used to merge the schema and the data together into a single array item
	// we do this just in time since there is no way of knowing whether record or config will be delivered to the component first
	get fieldsIterator() {
		const article = get(this.trackingApiResult, 'article', null);
		if(!article || !this.fields) return [];

		const animationDelayIncrementor = 40;
		let animationDelay = parseInt(this.animationDelay);

		let fields = this.fields.map(item => {
			animationDelay += animationDelayIncrementor;
			return {...item, fieldValue: article[item.fieldName], animationCss: this.getAnimationStyleCss(animationDelay)}
		});

		// add a little hack to get the international tracking URL field displayed
		// this is only necessary because the ExternalTrackingURL__c is a Long Text and it can't be used in a formula field
		// this means we can't create a formula field that displays a hyperlink and add it to the fieldset
		fields.push({
			fieldName: CONSTANTS.FIELD_EXTERNAL_TRACKING_ID, fieldLabel: 'International Tracking',
			fieldType: 'URL', fieldValue: article[CONSTANTS.FIELD_EXTERNAL_TRACKING_ID],
			url: article[CONSTANTS.FIELD_EXTERNAL_TRACKING_URL], urlTarget: '_blank',
			animationCss: this.getAnimationStyleCss(animationDelay+animationDelayIncrementor)
		});

		// only return the fields that contain a value
		return fields.filter(item => item.fieldValue);
	}

	get waiting() {
		return this.loading;
	}

	get heading() {
		return (this.useConsignmentFieldSet ? 'Consignment Details' : 'Article Details');
	}


}