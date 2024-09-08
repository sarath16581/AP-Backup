/**
 * @description Wraps a single article to display in the ui
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 * 2020-10-05 - Disha Kariya - Allow safe drop attachment for case creation
 * 2020-10-12 - Ranjeewa Silva -  Added support for Direct to Network case creation.
 * 2021-10-01 - Nathan Franklin - Changed safe drop to delivery proof + uplift to v52
 * 2022-04-11 - Mahesh Parvathaneni - Added Map component for delivery and manifest locations
 */
import { LightningElement, track, api } from 'lwc';
import { getConfig, get, CONSTANTS } from "c/happyParcelService";
import HappyParcelBase from "c/happyParcelBase";

export default class HappyParcelArticle extends HappyParcelBase {

	_articleTypes;
	_configStatusValues;
	_defaultStatus;

	// if the article is a part of a consignment
	@api isArticleConsignment;

	//if the article is selected this is valid when a consignment is searched for
	@api isArticleSelected;

	// if this is true then a this allows a 'calculate' button to be shown on the page where an EDD is not available from SAP.
	// this is used only when the external wrapper supports an EDD wigit (i.e. Classic Lightning Console 'Customer Service')
	// when the 'Calculate' button is clicked, an event is generated and propagated up the DOM
	@api supportsExternalEdd;

	// if this is true then a this allows the happyParcelCustomerDetails component to be selectedable
	// when the component is clicked, an event is generated and propagated up the DOM
	@api supportsCustomerSelection;

	// if this is true then this allows happyParcelDeliveryProof component to attach safe drop image on Case creation.
	// when the component is clicked, attachdeliveryproof event is generated and propagated up the DOM
	@api supportsDeliveryProofAttachment;

    // if this is true then this allows direct to network case creation in happy parcels. 'happyParcelLastMileFacility'
    // component is rendered only when this is true and the user has required permissions.
	@api supportsCaseCreation;

	@api readOnly = false;
	@api loadingTrackingApi = false;
	@api loadingAnalyticsApi = false;

	// make sure the article passed in contains the right structures
	// this relies on the correct structure being passed which contains the correct properties defined in HappyParcel.getNewArticleContainer()
	@api article = {};

    //Contextual information passed in by the happy parcel host component.
	@api hostContext = {};

	// Display sender and receiver details
	@api displaySenderReceiverDetails = false;

	// sender/receiver selected store the state of the selected customer boxes when supportsCustomerSelection is true
	@track senderSelected;
	@track receiverSelected;

	// selection to attach safedrop or signature PDF to cases raised when supportsDeliveryProofAttachment is true
	attachDeliveryProof;
	showMapCard = false; // Flag to show/hide the map card based on delivery assessment event
	mapMarkers; // map markers for delivery address gps and manifested address gps from delivery assessment component
	selectedMarkerValue; //selected map marker value for lightning map

	connectedCallback() {
		getConfig().then(result => {
			// grab the article types so we know what type of article to display
			this._articleTypes = result.articleTypes;
			this._configStatusValues = result.happyParcelStatusValues;
			const defaultStatus = Object.values(this._configStatusValues).filter(item => {
				return item.IsDefault__c;
			});
			this._defaultStatus = (defaultStatus.length > 0 ? defaultStatus[0] : []);
		});
	}

	/**
	 * Catches the event from the customerDetails component when it's selected
	 * Selecting one of these components (either sender/receiver) means the other must be selected
	 * This handler keeps the parent in sync with the children and manages the deselection of the other component
	 */
	handleCustomerSelected(e) {
		if(e && e.detail) {
			const {type} = e.detail;
			if (type === 'sender') {
				this.senderSelected = true;
				this.receiverSelected = false;
			} else if (type === 'receiver') {
				this.senderSelected = false;
				this.receiverSelected = true;
			}
		}
	}

	/**
	 * Catches the event to deselect the currently selected customerDetails component (either sender/receiver)
	 */
	handleCustomerDeselected(e) {
		if(e && e.detail) {
			const {type} = e.detail;
			if (type === 'sender') {
				this.senderSelected = false;
			} else if (type === 'receiver') {
				this.receiverSelected = false;
			}
		}
	}

    /**
     * Handles 'attachdeliveryproof' event dispatched by happyParcelDeliveryProof component.
     * This is a signal to the case creation process to attach the delivery proof (either signature or safe drop)
     * Let the event propagate up the DOM.
     */
	handleAttachDeliveryProof(e) {
	    if (e && e.detail) {
	        this.attachDeliveryProof = e.detail.selected;
        }
    }

	get loading() {
		return this.loadingTrackingApi || this.loadingAnalyticsApi;
	}

	get emoticonAnimationCss() {
		return this.getAnimationStyleCss(parseInt(this.animationDelay));
	}

	get productType() {
		return get(this.article, 'trackingResult.caseProductSubCategory', '');
	}

	get productTypeDisplay() {
		if(!this._articleTypes)
			return;

		return (this._articleTypes[this.productType] ? this._articleTypes[this.productType].Label : this.productType);
	}

	get productTypeCss() {
		if(!this._articleTypes)
			return;

		return (this._articleTypes[this.productType] ? 'background-color: #' + this._articleTypes[this.productType].BackgroundColour__c + ';color: #' + this._articleTypes[this.productType].ForegroundColour__c + ';' : 'color:#000000;') + this.getAnimationStyleCss(this.animationDelay);
	}

	get articleSummaryCssClass() {
		return 'slds-grid slds-card slds-grow slds-grid_vertical-stretch' + (this.isArticleConsignment ? ' slds-card slds-card_boundary' : '');
	}

	/**
	 * Determines which smiling face icon should be shown in the article summary
	 */
	get emoticonStatusIcon() {
		return this.emoticonStatus.CustomIconName__c;
	}

	/**
	 * Determines the status text to display below the smiling face icon shown in the article summary
	 */
	get emoticonStatusText() {
		return this.emoticonStatus.StatusText__c;
	}

	/**
	 * Determines the help text to display below the smiling face icon shown in the article summary
	 */
	get emoticonHelpText() {
		return this.emoticonStatus.HelpText__c;
	}

	get emoticonStatus() {
		if(!this._configStatusValues)
			return (this._defaultStatus ? this._defaultStatus : []);

		const status = get(this.article, 'analyticsResult.flag_smiling', null);
		if(this._configStatusValues[status]) {
			return this._configStatusValues[status];
		} else {
			return this._defaultStatus;
		}
	}

    /**
     * Customer type currently selected in happy parcels.
     */
	get selectedCustomerType() {
	    return (this.senderSelected ? CONSTANTS.CUSTOMER_DETAILS_SENDER : (this.receiverSelected ? CONSTANTS.CUSTOMER_DETAILS_RECEIVER : null));
    }

	//handler for map click dispatched by happyParcelDeliveryAssessment component
	handleMapClick(event) {
		this.showMapCard = true;
		this.mapMarkers = event.detail.mapMarkers;
		this.selectedMarkerValue = this.mapMarkers[0].value;
	}

	// handler to hide the map from happyParcelEventMessageMap event
	handleCloseMap(event) {
		this.showMapCard = false;
	}
}