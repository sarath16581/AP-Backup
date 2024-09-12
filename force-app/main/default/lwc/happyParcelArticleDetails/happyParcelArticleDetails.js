/**
 * @description Happy Parcel Article Details
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 * 2024-05-17 - Seth Heang - added a new loading attribute to pass on to happyParcelCard child component and add additional attributes to be displayed
 * 2024-06-14 - Seth Heang - add displayPodDownloadButton flag and pass on to child HappyParcelCard
 */
import { LightningElement, api, track } from "lwc";
import { getConfig, CONSTANTS, get } from 'c/happyParcelService'
import HappyParcelBase from "c/happyParcelBase";

export default class HappyParcelArticleDetails extends HappyParcelBase {

	@api loading = false;

	@api titleLoading = false;

	@api displayPodDownloadButton = false;

	@api trackingApiResult;

	// denotes that we should be loading the fieldset from the consignment fieldset rather than the article fieldset
	@api useConsignmentFieldSet;

	// display additional attributes outside of the field set and merge into existing list for display
	@api displayAdditionalAttributes;

	@track fields = [];

	connectedCallback() {
		getConfig().then(result => {
			if (this.useConsignmentFieldSet) {
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
		if (!article || !this.fields) return [];

		const animationDelayIncrementor = 40;
		let animationDelay = parseInt(this.animationDelay);

		let fields = this.fields.map(item => {
			animationDelay += animationDelayIncrementor;
			return { ...item, fieldValue: article[item.fieldName], animationCss: this.getAnimationStyleCss(animationDelay) }
		});

		// add a little hack to get the international tracking URL field displayed
		// this is only necessary because the ExternalTrackingURL__c is a Long Text and it can't be used in a formula field
		// this means we can't create a formula field that displays a hyperlink and add it to the fieldset
		fields.push({
			fieldName: CONSTANTS.FIELD_EXTERNAL_TRACKING_ID, fieldLabel: 'International Tracking',
			fieldType: 'URL', fieldValue: article[CONSTANTS.FIELD_EXTERNAL_TRACKING_ID],
			url: article[CONSTANTS.FIELD_EXTERNAL_TRACKING_URL], urlTarget: '_blank',
			animationCss: this.getAnimationStyleCss(animationDelay + animationDelayIncrementor)
		});

		// check and merge additional attributes for display
		fields = this.mergeAdditionalAttributesForDisplay(fields);

		// only return the fields that contain a value
		return fields.filter(item => item.fieldValue);
	}

	/**
	 * @description	merge the additional attributes that are passed into this component
	 * 				via the @api from parent component into the fields array used for UI display
	 */
	mergeAdditionalAttributesForDisplay(fields) {
		// validate for valid properties prior to merging the attributes
		const validAttributes = Array.isArray(this.displayAdditionalAttributes) ?
			this.displayAdditionalAttributes.filter(attr =>
				attr.hasOwnProperty('fieldLabel') && attr.hasOwnProperty('fieldValue')
			) : [];
		return fields.concat(validAttributes);
	}

	get waiting() {
		return this.loading;
	}

	get moreWaiting() {
		return this.titleLoading;
	}

	get showPodDownloadButton() {
		return this.displayPodDownloadButton;
	}

	get heading() {
		return (this.useConsignmentFieldSet ? 'Consignment Details' : 'Article Details');
	}


}