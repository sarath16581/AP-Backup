/**
 * @description Display details of last mile delivery facility for the article based on event messages and enable
 *              direct to network case creation.
 * @author Ranjeewa Silva
 * @date 2020-10-12
 * @changelog
 * 2020-10-12 - Ranjeewa Silva - Created
 * 2020-11-06 - Ranjeewa Silva - Restrict 'Case Originator' picklist options in Direct to Network Case creation
 * 2020-11-08 - Ranjeewa Silva - Set DTN Case default value Origin = "Phone".
 * 2021-10-01 - Nathan Franklin - Changed safe drop to delivery proof + uplift to v52
 */

import { LightningElement, api, track } from 'lwc';
import HappyParcelBase from "c/happyParcelBase";
import { CONSTANTS, get, getConfig, getNetworkDetails, hasPermissionToCreateCaseDirectToNetwork } from "c/happyParcelService";

export default class HappyParcelLastMileFacility extends HappyParcelBase {

    @api loading = false;

    // contextual information received from the component hosting happy parcels.
    @api hpHostContext;

    // tracking api results received from parent
    @api trackingApiResult;

    // customer type selected in happy parcels.
    // possible values are CONSTANTS.CUSTOMER_DETAILS_SENDER or CONSTANTS.CUSTOMER_DETAILS_RECEIVER
    @api selectedCustomerType;

    // selection to attach delivery proof pdf image to cases in happy parcels.
    @api attachDeliveryProof;

    // make the direct to network case wizard visible
    showDtnCaseWizard;

    // show network information popup
    showNetworkPopover = false;

    // cached last mile delivery facility based on the latest event message in category "Delivered"
    _lastMileDeliveryFacilityCache;

    // the event types categorised as 'Delivered' - used to monitor events to identify the last mile delivery facility.
    _deliveredEventTypes;

    // the event types categorised as 'AwaitingCollection' - used to monitor events to determine enquiry sub type restrictions.
    _awaitingCollectionEventTypes;

    connectedCallback() {
        // grab a list of event types to monitor for with a milestone category of 'Delivered'
        getConfig().then(result => {
            this._deliveredEventTypes = get(result.eventMessageTypeDefinitions, 'Delivered', []).map(item => item.Label);
            this._awaitingCollectionEventTypes = get(result.eventMessageTypeDefinitions, 'AwaitingCollection', []).map(item => item.Label);
        });
    }

    /**
     * Record type to use for any new Direct to Network cases
     */
    get dtnCaseRecordTypeName() {
        return CONSTANTS.DTN_CASE_RECORDTYPE;
    }

    /**
     * Default values to use for Direct to Network case creation
     */
    get dtnCaseDefaultValues() {

        const defaultValues = {};

        if (this.hpHostContext) {

            // if product category and product sub category available in article search results - use those as
            // default values for the case. Use default values received from Happy Parcel host component if article
            // search has not returned these values.
            defaultValues[CONSTANTS.FIELD_PRODUCT_CATEGORY] = get(this.trackingApiResult, 'caseProductCategory', this.hpHostContext.productCategory);
            defaultValues[CONSTANTS.FIELD_PRODUCT_SUB_CATEGORY] = get(this.trackingApiResult, 'caseProductSubCategory', this.hpHostContext.productSubCategory);

            defaultValues[CONSTANTS.FIELD_COMPLAINT] = this.hpHostContext.complaint;
            defaultValues[CONSTANTS.FIELD_TYPE] = this.hpHostContext.caseType;
            defaultValues[CONSTANTS.FIELD_CONTACT_ID] = this.hpHostContext.contactId;

            // check if product category and product sub category passed in by happy parcel host has been overridden by values
            // in article search results. Only pass "enquiry sub type" received from happy parcel host if controlling
            // values (i.e. type, product category and product sub category) are not overridden.
            if (defaultValues[CONSTANTS.FIELD_PRODUCT_CATEGORY] === this.hpHostContext.productCategory
                    && defaultValues[CONSTANTS.FIELD_PRODUCT_SUB_CATEGORY] === this.hpHostContext.productSubCategory) {

                defaultValues[CONSTANTS.FIELD_ENQUIRY_SUB_TYPE] = this.hpHostContext.enquirySubType;
            }
        }

        // set the default case originator based on the customer type selected in happy parcels.
        defaultValues[CONSTANTS.FIELD_CASE_ORIGINATOR] = (this.selectedCustomerType === CONSTANTS.CUSTOMER_DETAILS_SENDER ? 'Sender' : (this.selectedCustomerType === CONSTANTS.CUSTOMER_DETAILS_RECEIVER ? 'Addressee' : null));
        defaultValues[CONSTANTS.FIELD_ORIGIN] = 'Phone';

        return defaultValues;
    }




    /**
     * Return the last mile delivery facility for the article. Last mile delivery facility is based on the latest
     * event message in 'Delivered' category.
     */
    get computedLastMileDeliveryFacility() {

        if (this._lastMileDeliveryFacilityCache) {
            // if last mile facility is available in cache return the value.
            return this._lastMileDeliveryFacilityCache;
        }

        if (this._deliveredEventTypes) {

            let lastMileFacilityOrgId;

            get(this.trackingApiResult, 'events', []).filter(item => {
                return (this._deliveredEventTypes.includes(item.event.EventType__c) && item.event.Facility__c);
            }).slice(-1).forEach(item => {
                lastMileFacilityOrgId = item.event.FacilityOrganisationID__c;
            });

            if (lastMileFacilityOrgId) {
                getNetworkDetails(lastMileFacilityOrgId)
                    .then(result => {
                        if (result.network) {
                            //Last mile delivery faciility details available. Cache the value and return.
                            this._lastMileDeliveryFacilityCache = result.network;
                            return this._lastMileDeliveryFacilityCache;
                        }
                    });
            }
        }

        return {};
    }

    get canRaiseEnquiryDirectToNetwork() {
        const contactId = get(this.hpHostContext, 'contactId', null);
        return (hasPermissionToCreateCaseDirectToNetwork() && this.computedLastMileDeliveryFacility.Id && contactId);
    }

    /**
     * Checks if a last mile delivery facility is available for this article.
     */
    get isLastMileFacilityAvailable() {
        return (this.computedLastMileDeliveryFacility.Id);
    }

    /**
     * Checks if the last mile delivery facility has access to my network.
     */
    get canFacilityAccessMyNetwork() {
        return (this.computedLastMileDeliveryFacility.Id && this.computedLastMileDeliveryFacility.Contact_Facility__c === 'MyNetwork');
    }

    /**
     * Returns article details to pass in to DTN Case wizard.
     */
    get articleDetailsFromTrackingApiResult() {
        if (this.trackingApiResult) {
            const events = get(this.trackingApiResult, 'events', []);
            if (events.length > 0) {
                return {
                    ...this.trackingApiResult.article,
                    Id: events[0].event.Article__c
                }
            }
        }
    }

    get dtnCaseRestrictedPicklistValues() {

        const awaitingCollectionEventsPresent = !!this.awaitingCollectionEventsPresent;

        // Define the picklist value restrictions to pass on to DTN Case Wizard. Currently holding the configuration in
        // component as it is not significant enough to move into a custom metadata type.
        // Consider moving to a custom metadata type if this grows in future.
        let restrictedPicklistFieldValues = {};
        restrictedPicklistFieldValues[CONSTANTS.FIELD_ENQUIRY_SUB_TYPE] = [
            {
                name: 'Article carded - no delivery attempt',
                isValid: !awaitingCollectionEventsPresent,
                errorMessage: (awaitingCollectionEventsPresent ? CONSTANTS.LABEL_HAPPYPARCELDTNRESTRICTEDENQUIRYSUBTYPEERRORMSG : '')
            },
            {
                name: 'Carding issue',
                isValid: !awaitingCollectionEventsPresent,
                errorMessage: (awaitingCollectionEventsPresent ? CONSTANTS.LABEL_HAPPYPARCELDTNRESTRICTEDENQUIRYSUBTYPEERRORMSG : '')
            },
            {
                name: 'Delivery complaint',
                isValid: !awaitingCollectionEventsPresent,
                errorMessage: (awaitingCollectionEventsPresent ? CONSTANTS.LABEL_HAPPYPARCELDTNRESTRICTEDENQUIRYSUBTYPEERRORMSG : '')
            },
            {
                name: 'Disputed delivery scan',
                isValid: true
            },
            {
                name: 'Item transfer',
                isValid: true
            }
        ];

        restrictedPicklistFieldValues[CONSTANTS.FIELD_CASE_ORIGINATOR] = [
            {
                name: 'Addressee',
                isValid: true
            },
            {
                name: 'Sender',
                isValid: true
            }
        ];
        return restrictedPicklistFieldValues;
    }

    get awaitingCollectionEventsPresent() {

        if (this._awaitingCollectionEventTypes) {
            const awaitingCollectionEvents = get(this.trackingApiResult, 'events', []).filter(item => {
                return (this._awaitingCollectionEventTypes.includes(item.event.EventType__c));
            });

            return (awaitingCollectionEvents.length > 0);
        }
    }

    /**
     * Show Direct to Network Case wizard.
     */
    handleShowDtnCaseWizard(event) {
        this.showDtnCaseWizard = true;
    }

    /**
     * Hide Direct to Network Case wizard.
     */
    handleCloseDtnCaseWizard(event) {
        this.showDtnCaseWizard = false;
    }

    /**
     * Handles successful completion of Direct to Network Case wizard after the case is created successfully.
     */
    handleCompleteDtnCaseWizard(event) {
        if (event && event.detail) {
            // trigger a DOM event that can be handled by any parent component in the DOM.
            // this will be handled by 1 of 2 options
            // 1. if happyParcel -> supportsExternalLinkHandling!=true, happyParcel.js which will have NavigationMixin to navigate
            //															idclick event handler is stopped here.
            // 2. if happyParcel -> supportsExternalLinkHandling==true, the idclick event will propagate up to the external listener and the external listener will handle the event
            this.dispatchEvent(new CustomEvent('idclick', { detail: { id: event.detail.id }, bubbles: true, composed: true} ));
        }
        this.showDtnCaseWizard = false;
    }

    /**
     * Show network information popup
     */
    handleShowNetworkInfo(event) {
        this.showNetworkPopover = true;
    }

    /**
     * Closes the popup for network information
     */
    handleCloseNetworkInfo(event) {
        this.showNetworkPopover = false;
    }
}