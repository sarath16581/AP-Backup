/**
 * @description Wraps all capability exposed in Happy Parcels
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 * 2020-10-05 - Disha Kariya - Allow safe drop attachment for case creation
 * 2020-10-12 - Ranjeewa Silva - Added support for Direct to Network case creation in happy parcels.
 * 2021-06-15 - Ranjeewa Silva - Updated 'readOnly' property name as per https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.js_props_names.
 * 2021-10-15 - Nathan Franklin - Updated comments around supportsSafeDropAttachment which is now used for signatures too + uplift to v52 and conversion of tracking number to uppercase
 * 2021-11-08 - Prerna Rahangdale - Added support to show the warning with a link to knowledge article for articles which have VODV checked.
 */
import { LightningElement, track, api } from "lwc";
import {getAnalyticsApiResponse, getTrackingApiResponse, getConfig, safeTrim, safeToUpper, CONSTANTS} from 'c/happyParcelService'
import { NavigationMixin } from 'lightning/navigation';

export default class HappyParcelWrapper extends NavigationMixin(LightningElement) {

	_trackingId = '';

	@api readOnly = false;

	vodvKnowledgeId;

	// if this is true then a this allows a 'calculate' button to be shown on the page where an EDD is not available from SAP.
	// this is used only when the external wrapper supports an EDD wigit (i.e. Classic Lightning Console 'Customer Service')
	// when the 'Calculate' button is clicked, an event is generated and propagated up the DOM
	@api supportsExternalEdd;

	// When showing a consignment search result, child articls are selectable and dom events are dispatched if this option is enabled
	@api supportsSelectableChildArticles;

	// if this is true then a this allows the happyParcelCustomerDetails component to be selectedable
	// when the component is clicked, an event is generated and propagated up the DOM
	@api supportsCustomerSelection;

	// if this is true then this allow any clickable links to bubble up as a custom DOM events which can be handled by an external handler to determine the appropriate action
	// this is currently used both by lightning console applications (using the flexi-page SAP_EM) and classic console app (mycustomer)
	@api supportsExternalLinkHandling;

	// if this is true then this allows happyParcelDeliveryProof component to attach safe drop image on Case creation.
	// when the component is clicked, attachdeliveryproof event is generated and propagated up the DOM
	// NOTE: The context of this option now includes Signatures as well. This will also allow a checkbox to be shown int eh delivery proof component to attach a signature to a created case too
	@api supportsSafeDropAttachment;

    // if this is true then this allows direct to network case creation in happy parcels. 'happyParcelLastMileFacility'
    // component is rendered only when this is true and the user has required permissions.
    @api supportsCaseCreation;

	// sender/receiver selected store the state of the selected customer boxes when supportsCustomerSelection is true
	// these are only for consignment search results
	// article level tracked vars are in the happyParcelArticle component
	@track consignmentSenderSelected;
	@track consignmentReceiverSelected;
	@track vodvWarning;

	@track loadingTrackingApi = false;
	@track loadingAnalyticsApi = false;

	// Stores information about the articles that were returned in the search results
	@track articles = [];

	// Stores information about any consignment that was returned in the search results
	@track consignment = {};

	// stores a list of any errors that have occurred within any of the remote API calls
	@track errors = [];

	// used in the scenario where GCP throws a 503 error
	// the structure of HP in GCP requires reclustering and rebuilding of the tables
	// during this process (which normally take a couple of seconds), the service is unavailable
	// this is a dodgy solution but have been asked to build a 'Try again' option into the solution
	@track retryAnalytics;

	// this allows us to control which panels are open on the accordion that is rendered when we are viewing search results for a consignment
	// this is a workaround due to the base accordion component forcing a single panel to *always* be open
	@track activeSections = [];

	/**
	 * Using getter/setter to enable us to trigger a search from either above (receiving tracking id from external source), or below (receiving tracking id from article selector component)
	 */
	@api
	get trackingId() { return this._trackingId; }
	set trackingId(value) {
		this._trackingId = safeToUpper(safeTrim(value));
		if(value) {
			this.triggerSearch();
		}
	}

    //Contextual information passed in by the host component.
	@api hostContext = {};

	connectedCallback() {
		// preload the config so all the components do not have to make individual apex calls because the config hasn't loaded
		getConfig().then(result => {
            this.vodvKnowledgeId = result.VODVKnowledgeId;
        });

		this.template.addEventListener('idclick', this.handleIdLinkClick);
	}

	disconnectedCallback() {
		this.template.removeEventListener('idclick', this.handleIdLinkClick);
	}

	/**
	 * Handles a click when the users clicks a link that requires an ID page to open.
	 * This may be handle by an external provider (such as where Happy Parcel is embedded in MyCustomer (mini case will catch this and use the classic console api to open a new primary tab))
	 */
	handleIdLinkClick = (e) => {
		if(!this.supportsExternalLinkHandling) {
			const id = e.detail.id;

			this[NavigationMixin.Navigate]({
				type: 'standard__recordPage',
				attributes: {
					recordId: id,
					actionName: 'view',
				},
			});

			e.preventDefault();
			e.stopPropagation();
		}
	}

	async doAnalyticsQuery(currentTrackingId) {
		this.loadingAnalyticsApi = true;

		// reset the retry error whenever we kick off a new analytics query
		this.retryAnalytics = false;

		// perform the actual callout to the api
		const result = await getAnalyticsApiResponse(currentTrackingId);


		// perform a check to ensure the current article id is the same article id that was passed into the async function
		// it's possible that while the current search was in progress that another tracking id was passed into the mix (if the component is embedded into other workflows and receives a new tracking id by api)
		if(currentTrackingId !== this._trackingId) {
			this.removeStaleSearchTrackingObjects(currentTrackingId);
			return;
		}

		const {errors, doRetry, articles} = result;

		// assign the tracking response for each article into the articles array
		// we need to loop
		if(articles) {
			articles.forEach((item) => {
				let articleIndex = this.articles.findIndex(article => article.trackingId === item.article_id);
				if (articleIndex > -1) {
					// this scenario would be the following:
					// 1. the search result returned was the same that was searched for (not a consignment)
					// 2. another api query was completed (tracking api for example) and populated this structure
					this.articles[articleIndex].analyticsResult = item;

					// check to make sure the expanded var has been set or not
					// if it has been set then we leave it as is since the default may have been overrideen by user action given the article would have been previously rendered in the UI
					// if it hasn't been set then we make sure it's collapsed if search result returned a consignment or expanded for an article search result
					if (!Object.keys(this.articles[articleIndex]).includes('articleDetailsExpanded')) {
						this.articles[articleIndex].articleDetailsExpanded = !this.isConsignment;
					}
				} else {
					// note because we are adding this article we can set the default value of articleDetailsExpanded
					// this means if the search result returned a consignment then the article should be collapsed by default
					// if the search result returned an article then the article should be expanded
					// we can do this here since the user would not have overridden the 'expanded' value since the article has not previously existed in the ui yet
					// NOTE: having trouble with this.articles.push not triggering rerendering
					this.articles = [...this.articles, {
						...this.getNewArticleContainer(),
						trackingId: item.article_id,
						analyticsResult: item,
						articleDetailsExpanded: !this.isConsignment
					}];
				}
			});
		}

		if(doRetry) {
			// since there was a problem with the remote server and it requires a retry then show a button that allows the user to click to try again
			this.retryAnalytics = true;
		}

		// add any errors from the request
		if(errors) {
			this.errors = this.errors.concat(errors.map(item => {
				return 'Analytics API: ' + item;
			}));
		}

		this.loadingAnalyticsApi = false;

		// remove any items from the articles array that do not have valid entries
		// 1. api produced no results for the item in the local 'this.articles' store AND no other API calls have populated data for that article Id
		// 2. if the search was for a consignment, then we would remove the initial 'skeleton' structure used to show the loading ui effect
		this.tidyupLocalArticleStore();
	}
	async doTrackingQuery(currentTrackingId) {
		//this.loadingAnalyticsApi = true;
		this.loadingTrackingApi = true;

		// perform the actual callout to the api
		const result = await getTrackingApiResponse(currentTrackingId);

		// perform a check to ensure the current article id is the same article id that was passed into the async function
		// it's possible that while the current search was in progress that another tracking id was passed into the mix
		// NOTE: There shouldn't be a need to reset the loadingTrackingApi var since another query should be in progress
		if(currentTrackingId !== this._trackingId) {
			this.removeStaleSearchTrackingObjects(currentTrackingId);
			return;
		}

		const {errors, consignment, articles} = result;

		// add the consignment trackingResults to the consignment object
		if(consignment) {
			this.consignment = {...this.consignment, trackingId: consignment.trackingId, trackingResult: consignment};
		}

		// assign the tracking response for each article into the articles array
		// we need to loop
		if(articles) {
			articles.forEach((item) => {
				let articleIndex = this.articles.findIndex(article => article.trackingId === item.trackingId);
				if (articleIndex > -1) {
					// this scenario would be the following:
					// 1. the search result returned was the same that was searched for (not a consignment)
					// 2. another api query was completed (analytics api for example) and populated this structure
					this.articles[articleIndex].trackingResult = item;
                    if(item.article.VODV_Redirect__c) {
                           this.vodvWarning = CONSTANTS.LABEL_HAPPYPARCELVODVWARNINGTEXT;
                    }
					// a consignment is rendered with a list selectable articles. this value stores whether the article checkbox has been clicked or not
					if (this.isConsignment && !Object.keys(this.articles[articleIndex]).includes('articleSelected')) {
						this.articles[articleIndex].articleSelected = false;
					}

					// check to make sure the expanded var has been set or not
					// if it has been set then we leave it as is since the default may have been overridden by user action given the article would have been previously rendered in the UI
					// if it hasn't been set then we make sure it's collapsed if search result returned a consignment or expanded for an article search result
					if (!Object.keys(this.articles[articleIndex]).includes('articleDetailsExpanded')) {
						this.articles[articleIndex].articleDetailsExpanded = !this.isConsignment;
					}
				} else {
					// note because we are adding this article we can set the default value of articleDetailsExpanded
					// this means if the search result returned a consignment then the article should be collapsed by default
					// if the search result returned an article then the article should be expanded
					// we can do this here since the user would not have overridden the 'expanded' value since the article has not previously existed in the ui yet
					this.articles.push({
						...this.getNewArticleContainer(),
						trackingId: item.trackingId,
						trackingResult: item,
						articleSelected: false
					}); //, articleDetailsExpanded: !this.isConsignment
				}
			});
		}

		// we need to trigger an event back to the external caller to give the correct article -> clear view case mappings based on the article we have just retrieved
		// in a pureist world, the call to get mappings should be outside happy parcels, but anyway
		this.triggerClearviewMappingEvent();

		// add any errors from the request
		if(errors) {
			this.errors = this.errors.concat(errors.map(item => {
				return 'Tracking API: ' + item;
			}));
		}

		this.loadingTrackingApi = false;

		// remove any items from the articles array that do not have valid entries
		// 1. api produced no results for the item in the local 'this.articles' store AND no other API calls have populated data for that article Id
		// 2. if the search was for a consignment, then we would remove the initial 'skeleton' structure used to show the loading ui effect
		this.tidyupLocalArticleStore();
	}

	/**
	 * Handle search when a user has entered an article id in the article selector
	 */
	handleSearch(e) {
		// the setter of this property will call 'triggerSearch' which begins the search process
		this.trackingId = e.detail;
	}

	/**
	 * This allows us to programmatically control which accordion panels are opened/closed
	 * The base accordion component by default forces a single panel to *always* be opened which is undesirable behaviour for us since we want the accordion to be fully closed when it's initialised
	 * To enable all panels to be closed, we need to use allow-multiple-sections-open and then use code to collpase panels so only 1 is ever displayed
	 * The accordion is only shown when we are viewing consignment search results
	 */
	handleToggleSection(event) {
		const openSections = event.detail.openSections;

		//only update if there is a difference (as handleToggleSection is reexecuted)
		let sectionDiff = openSections.filter( x => !this.activeSections.includes(x) );
		if (sectionDiff.length > 0) {
			this.activeSections = sectionDiff;
		}

		// hide/show the summary path since it's displayed in bigger form when the accordion is open
		for(let i=0;i<this.articles.length;i++) {
			if(openSections.includes(this.articles[i].trackingId)) {
				this.articles[i].hideAccordionSummary = true;
			} else {
				this.articles[i].hideAccordionSummary = false;
			}
		}

	}

	/**
	 * This checkbox click handler is used to set the state of the article as 'selected'.
	 * This checkbox is only visible when we render consignment search results
	 * This is used by the mini case component to create a child case for each of the selected articles (in addition to the main consignment)
	 * An exception to this rule is that if only a single article is selected, no child case is created and it instead becomes the tracking id of the primary case
	 */
	handleArticleSelectorClick(event) {
		for(let i=0;i<this.articles.length;i++) {
			if(this.articles[i].trackingId === event.target.dataset.article) {
				//this.articles[i].articleSelected = !!this.articles[i].articleSelected;
				this.articles[i] = {...this.articles[i], articleSelected: !!!this.articles[i].articleSelected };
				console.log(this.articles[i].articleSelected);
				break;
			}
		}

		this.broadcastSelectedArticles();
	}

	handleKnowledgeClick(){
        this.dispatchEvent(new CustomEvent('idclick', { detail: { id: this.vodvKnowledgeId }, bubbles: true, composed: true} ));
    }

	triggerSearch() {
		this.resetSearch();

		console.log('>> Searching for trackingId', this._trackingId);

		// before a search starts we ensure the articles var contains a single empty object to force the ui to show the article components
		// this allows us to show a 'loading' effect for each component when a search is triggered
		this.articles = [
			this.getNewArticleContainer()
		];

		// NOTE: We pass the current trackingId into the search functions to make sure after the callout is finished, that it is still the current trackingId
		//          There is a scenario where a new tracking id may be passed into the component while a search is already in progress
		//          If this happens, passing the tracking id in allows to ignore the search results if they are out of sync with the current component state
		this.doAnalyticsQuery(this._trackingId);
		this.doTrackingQuery(this._trackingId);
	}

	/**
	 * This occurs when the first analytics query fails. In that scenario the 'retryAnalytics' value is set to try which triggers a button to be rendered on the UI called 'Try Again'
	 * This is the handler for that 'Try Again' button
	 */
	handleRetriggerAnalyticsSearch() {
		console.log('>> Retriggering analytics search for trackingId', this._trackingId);
		this.doAnalyticsQuery(this._trackingId);
	}

	/**
	 * Broadcast the article selected status to whoever is listening
	 * This is used by the mini case component to create a child case for each of the selected articles (in addition to the main consignment)
	 * An exception to this rule is that if only a single article is selected, no child case is created and it instead becomes the tracking id of the primary case
	 */
	async broadcastSelectedArticles() {
		const selectedArticles = this.articles.filter(item => item.articleSelected).map(item => item.trackingId);
		this.dispatchEvent(new CustomEvent('selectedarticles', { detail: selectedArticles, bubbles: true, composed: true }));
	}

	resetSearch() {
		this.consignment = { trackingResults: {}, analyticsResult: {}};
		this.articles = [];
		this.errors = [];
		this.retryAnalytics = false;
		this.vodvWarning = null;
	}

	getNewArticleContainer() {
		return {
			trackingId: this.trackingId,
			trackingResult: {},
			analyticsResult: {}
		}
	}

	/**
	 * We use this to tidy up any 'staging' rows we have added into the 'this.articles' local store that were used to show the UI loaders.
	 * Remove any items from the articles array that do not have valid entries
	 * 1. api produced no results for the item in the local 'this.articles' store AND no other API calls have populated data for that article Id
	 * 2. if the search was for a consignment, then we would remove the initial 'skeleton' structure used to show the loading ui effect
	 */
	tidyupLocalArticleStore() {
		if(this.loadingTrackingApi)
			return;

		for(let i=this.articles.length-1;i>=0;i--) {
			// remove the elements we need to ignore which includes the .trackingId and the attribute we have just passed in
			let isEmpty = (Object.entries(this.articles[i].trackingResult).length === 0) && (Object.entries(this.articles[i].analyticsResult).length === 0);
			if(isEmpty) {
				console.log('Removing article: ' + this.articles[i].trackingId);
				this.articles.splice(i, 1);
			}
		}
	}

	/**
	 * If a search becomes stale, that is, another tracking id was passed into the component while an existing search was in progress, then the old stale search object must be removed
	 * This will ensure the correct UI is displayed
	 * This is trigger at the conclusion of the 'await' for all API callouts.
	 * This will only be called if the original trackingId is different from the current
	 */
	removeStaleSearchTrackingObjects(oldTrackingId) {
		for(let i=this.articles.length-1;i>=0;i--) {
			if(this.articles[i].trackingId === oldTrackingId) {
				console.log('Removing stale tracking object');
				this.articles.splice(i, 1);
			}
		}
	}

	/**
	 * Catches the event from the customerDetails component when it's selected
	 * Selecting one of these components (either sender/receiver) means the other must be selected
	 * This handler keeps the parent in sync with the children and manages the deselection of the other component
	 */
	handleConsignmentCustomerSelected(e) {
		if(e && e.detail) {
			const {type} = e.detail;
			if (type === 'sender') {
				this.consignmentSenderSelected = true;
				this.consignmentReceiverSelected = false;
			} else if (type === 'receiver') {
				this.consignmentSenderSelected = false;
				this.consignmentReceiverSelected = true;
			}
		}
	}

	/**
	 * Catches the event to deselect the currently selected customerDetails component (either sender/receiver)
	 */
	handleConsignmentCustomerDeselected(e) {
		if(e && e.detail) {
			const {type} = e.detail;
			if (type === 'sender') {
				this.consignmentSenderSelected = false;
			} else if (type === 'receiver') {
				this.consignmentReceiverSelected = false;
			}
		}
	}

	/**
	 * After a tracking query has been completed, it will send through case clearview type mappings for the article that was just searched
	 * We propagate these up to any external callers listening. They can do whatever they need with them
	 */
	triggerClearviewMappingEvent() {
		if(this.consignment && this.consignment.trackingId) {
			const detail = {
				isConsignment: this.isConsignment,
				articleCount: this.articles.length,
				trackingId: this.consignment.trackingId,
				type: this.consignment.trackingResult.caseTypeMapping,
				productCategory: this.consignment.trackingResult.caseProductCategory,
				productSubCategory: this.consignment.trackingResult.caseProductSubCategory,
				lodgementDate: (this.consignment.trackingResult.article ? this.consignment.trackingResult.article.ArticleLodgementDate__c : null)
			};
			this.dispatchEvent(new CustomEvent('trackingsearchcomplete', { detail: detail, bubbles: true, composed: true }));
		} else if(this.articles && this.articles.length > 0) {
			// there should only ever be one article here since if it was a consignment, this code would not be called)
			const detail = {
				trackingId: this.articles[0].trackingId,
				type: this.articles[0].trackingResult.caseTypeMapping,
				productCategory: this.articles[0].trackingResult.caseProductCategory,
				productSubCategory: this.articles[0].trackingResult.caseProductSubCategory,
				lodgementDate: (this.articles[0].trackingResult.article ? this.articles[0].trackingResult.article.ArticleLodgementDate__c : null)
			};
			this.dispatchEvent(new CustomEvent('trackingsearchcomplete', { detail: detail, bubbles: true, composed: true }));
		}

		// this will reset any state collected externally from any previous queries
		// this should broadcast an empty list
		this.broadcastSelectedArticles();
	}

	get loading() {
		return this.loadingAnalyticsApi || this.loadingTrackingApi;
	}

	get isConsignment() {
		return this.consignment && this.consignment.trackingId;
	}

	get consignmentEvents() {
		return (this.consignment && this.consignment.trackingResult && this.consignment.trackingResult.events ? this.consignment.trackingResult.events : []);
	}

	get consignmentSenderContact() {
		return (this.consignment && this.consignment.trackingResult ? this.consignment.trackingResult.senderContact : {});
	}

	get consignmentReceiverContact() {
		return (this.consignment && this.consignment.trackingResult ? this.consignment.trackingResult.receiverContact : {});
	}

	get consignmentTrackingResult() {
		return (this.consignment ? this.consignment.trackingResult : null);
	}

	get searchResultsText() {
		if(this.isConsignment) {
			return 'Consignment';
		} else {
			return 'Article';
		}
	}

	get hasSearchResults() {
		return this.articles.filter(item => (item.trackingResult && item.trackingResult.trackingId) || (item.analyticsResult && item.analyticsResult.trackingId)).length > 0;
	}

	get selectorReadOnly() {
		return this.readOnly || this.loadingAnalyticsApi || this.loadingTrackingApi;
	}

	get happyParcelCssClass() {
		return 'slds-m-bottom_large ' + (this.isConsignment ? 'is-consignment' : (!this.loadingTrackingApi && this.articles && this.articles.length > 0 ? 'is-article' : ''));
	}

	/**
	 * Disables article level customer selection if we are viewing consignment search results
	 */
	get articleCustomerSelectionEnabled() {
		return this.supportsCustomerSelection && !this.isConsignment
	}

	/**
	 * Determines whether the event message related list is displayed when viewing a consignment search result
	 */
	get consignmentHasEventMessages() {
		return this.isConsignment && this.consignment.trackingResult.events && this.consignment.trackingResult.events.length > 0;
	}

}