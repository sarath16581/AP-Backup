/**
 * @description Used to display Happy Parcel status milestones
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 * 2020-09-07 - Ranjeewa Silva - Updated milestone hover dates to display date and time.
 * 2020-09-09 - Ranjeewa Silva - Removed last mile milestones (Awaiting Collection and Delivered) if we subsequently encounter 'Processed' scan events.
 */
import {LightningElement, track, api} from 'lwc';
import { getConfig, get, CONSTANTS } from "c/happyParcelService";
import HappyParcelBase from "c/happyParcelBase";

export default class HappyParcelMilestonePath extends HappyParcelBase {

	_eventMessageTypes = {};

	helpText = {};

	@track _invertedEventTypes = {};

	// determines whether a 'compact' view or the 'normal' view will be loaded
	// compact view will only show a small version of the status dots
	@api variant = 'normal';

	// passed down from the top level component which show whether the tracking api call is in progress or not
	@api loadingTrackingApi = false;

	@api trackingApiResult;

	connectedCallback() {
		// grab a list of event types to monitor for with signature for delivery
		getConfig().then(result => {
			for(const [key, value] of Object.entries(result.eventMessageTypeDefinitions)) {
				this._eventMessageTypes[key] = value.map(item => item.Label);
			}

			// also store the flipped event type / category mappings so it's easy to access as we are iterating through our statuses
			const invertedEventTypes = {};
			for (const [eventCategory, eventTypes] of Object.entries(this._eventMessageTypes)) {
				eventTypes.forEach(item => {
					invertedEventTypes[item] = eventCategory;
				});
			}
			this._invertedEventTypes = invertedEventTypes;
		});
	}

	/**
	 * Build a dynamic PATH for display.
	 * We need to compute this since the attribute 'variant' determines the labels that need to be displayed which may or may not be set at the time the trackingApiResult attribute is set
	 */
	get computedPath() {
		const events = get(this.trackingApiResult, 'events', []);

		// current milestones of the article
		const articleState = {
			Lodged: {},
			Processed: {},
			Onboard: {},
			AttemptedDelivery: {},
			AwaitingCollection: {},
			Delivered: {}
		};

		events.forEach(item => {
			const e = item.event;
			const eventType = e.EventType__c;
			const dateTime = Date.parse(e.ActualDateTime__c);

			// NOTE: we check for an existing value in articleState since there will be other categories in this._invertedEventTypes which we do not want to display in the ui.... like 'Admin' and others.
			if(this._invertedEventTypes[eventType] && articleState.hasOwnProperty(this._invertedEventTypes[eventType])) {
				articleState[this._invertedEventTypes[eventType]] = { is: true, dateTime: dateTime, isRevoked: false };
			}
		});

        if (articleState.Processed.is && articleState.Processed.dateTime) {
            //Revoke last mile milestones if they are prior to the processed scan event.
            this.revokeMilestoneIfOccurredBefore(articleState.AwaitingCollection, articleState.Processed.dateTime);
            this.revokeMilestoneIfOccurredBefore(articleState.Delivered, articleState.Processed.dateTime);
        }

		const animationDelay = parseInt(this.animationDelay);

		const output = [
			{
				cssClass: 'animated pulse slds-path__item ' + (articleState.Lodged.is ? 'slds-is-complete' : 'slds-is-incomplete'),
				label: 'Lodged',
				hoverLabel: (articleState.Lodged.is ? articleState.Lodged.dateTime : 'Lodged'),
				hoverIsDate: !!articleState.Lodged.is,
				animationCss: this.getAnimationStyleCss(animationDelay)
			},
			{
				cssClass: 'animated pulse slds-path__item ' + (articleState.Processed.is ? 'slds-is-complete' : 'slds-is-incomplete'),
				label: 'Processed',
				hoverLabel: (articleState.Processed.is ? articleState.Processed.dateTime : 'Processed'),
				hoverIsDate: !!articleState.Processed.is,
				animationCss: this.getAnimationStyleCss(animationDelay+60)
			},
			{
				cssClass: 'animated pulse slds-path__item ' + (articleState.Onboard.is ? 'slds-is-complete' : 'slds-is-incomplete'),
				label: 'Onboard',
				hoverLabel: (articleState.Onboard.is ? articleState.Onboard.dateTime : 'Onboard'),
				hoverIsDate: !!articleState.Onboard.is,
				animationCss: this.getAnimationStyleCss(animationDelay+120)
			},
			{
				//cssClass: 'slds-path__item ' + (articleState.AttemptedDelivery.is ? 'slds-is-complete slds-is-complete-warning' : 'slds-is-incomplete'),
				cssClass: 'animated pulse slds-path__item ' + (articleState.AttemptedDelivery.is ? 'slds-is-complete' : 'slds-is-incomplete'),
				label: (this.variantIsCompact ? 'Attempted' : 'Attempted Delivery'),
				hoverLabel: (articleState.AttemptedDelivery.is ? articleState.AttemptedDelivery.dateTime : (this.variantIsCompact ? 'Attempted' : 'Attempted Delivery')),
				hoverIsDate: !!articleState.AttemptedDelivery.is,
				animationCss: this.getAnimationStyleCss(animationDelay+180)
			},
			{
				cssClass: 'animated pulse slds-path__item ' + (articleState.AwaitingCollection.is ? (articleState.AwaitingCollection.isRevoked ? 'slds-is-complete is-revoked' : 'slds-is-complete') : 'slds-is-incomplete'),
				label: (this.variantIsCompact ? 'Awaiting' : 'Awaiting Collection'),
				hoverLabel: (articleState.AwaitingCollection.is ? articleState.AwaitingCollection.dateTime : (this.variantIsCompact ? 'Awaiting' : 'Awaiting Collection')),
				hoverIsDate: !!articleState.AwaitingCollection.is,
				animationCss: this.getAnimationStyleCss(animationDelay+240)
			},
			{
				cssClass: 'animated pulse slds-path__item ' + (articleState.Delivered.is ? (articleState.Delivered.isRevoked ? 'slds-is-complete is-revoked' : 'slds-is-complete') : 'slds-is-incomplete'),
				label: 'Delivered',
				hoverLabel: (articleState.Delivered.is ? articleState.Delivered.dateTime : 'Delivered'),
				hoverIsDate: !!articleState.Delivered.is,
				animationCss: this.getAnimationStyleCss(animationDelay+300)
			}
		];

		return output;
	}

	get variantIsNormal() {
		return this.variant == 'normal' || this.variantIsNormalConsignment;
	}

	get variantIsNormalConsignment() {
		return this.variant == 'normal-consignment';
	}

	get variantIsCompact() {
		return this.variant == 'compact';
	}

	get pathContainerCssClass() {
		return 'path-container' + (this.variantIsCompact ? ' compact' : (!this.variantIsNormalConsignment ? ' slds-card slds-card_boundary slds-p-around_small slds-m-bottom_medium path-container normal' : ''));
	}

	get pathAnimationCss() {
		return this.getAnimationStyleCss(this.animationDelay, 400);
	}

    revokeMilestoneIfOccurredBefore(milestone, dateTime) {
        if (milestone.dateTime && milestone.dateTime < dateTime) {
            milestone.isRevoked = true;
            this.helpText = {
                message : CONSTANTS.LABEL_HAPPYPARCELREVOKEDMILESTONEHELPTEXT,
                icon : 'utility:warning'
            };
        }
    }
}