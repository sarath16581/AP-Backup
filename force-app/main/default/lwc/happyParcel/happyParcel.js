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
 * 2022-11-28 - Dattaraj Deshmukh - Added 'logic to show caseInvestigation's article numbers'.
 * 									Added logic to check if case investigation Id is passed then it's article ID is passed as tracking Id to controller.
 * 2024-05-17 - Seth Heang - Added logic for additional query to remote .NET API for retrieving StarTrack consignment/article details and retry functionality
 * 2024-05-21 - Seth Heang - Added logic to allow force consignment search in existing SAP-EM integration when doing an article level
 * 2024-06-11 - Raghav Ravipati - Added logic to add critical incidents to articles in the tracking response
 * 2024-06-14 - Seth Heang - Added logic to allow the Proof of delivery PDF download on the Consignment Detail child component
 * 2024-06-18 - Seth Heang - Added EDD data mapping from StarTrack .NET query including SourceSystem and isDotNet Attribute
 * 2024-06-26 - Seth Heang - Added logic to publish LMS events for SAP callout completion and article selected
 */
import { LightningElement, track, wire, api } from "lwc";
import { getAnalyticsApiResponse, getTrackingApiResponse, getTrackingApiResponseForStarTrack, getCriticalIncidentDetails, getConfig, safeTrim, safeToUpper, subscribe, unsubscribe, downloadPODPDF, CONSTANTS } from 'c/happyParcelService'
import { NavigationMixin } from 'lightning/navigation';
import { publish, MessageContext } from 'lightning/messageService';
import GENERIC_LMS_CHANNEL from '@salesforce/messageChannel/genericMessageChannel__c';

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

	// if this is true then this allows any search on a single child article ID to also retrieve its parent consignment details and all related child articles (via SAP & StarTrack) if condition is met
	// and the parent consignment details and all related child article details will be displayed on the UI
	@api forceConsignmentLevelResults;

	// sender/receiver selected store the state of the selected customer boxes when supportsCustomerSelection is true
	// these are only for consignment search results
	// article level tracked vars are in the happyParcelArticle component
	@track consignmentSenderSelected;
	@track consignmentReceiverSelected;
	@track vodvWarning;

	@track loadingTrackingApi = false;
	@track loadingAnalyticsApi = false;
	@track loadingStarTrackApi = false;
	@track loadingPODPDFDownload = false;

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

	// the .NET callout is intermittantly unreliable and timeout, thus needing a 'Try again' option
	@track retryStarTrackCallout;

	// this allows us to control which panels are open on the accordion that is rendered when we are viewing search results for a consignment
	// this is a workaround due to the base accordion component forcing a single panel to *always* be open
	@track activeSections = [];

	_displayPodDownloadButton = false; // flag to show proof of delivery download button in Consignment Detail section
	_signatureEventTypes; // store event type to validate signature event
	
	@wire(MessageContext)
	messageContext; // wire the message context and pass to publisher to send LMS events

	/**
	 * Using getter/setter to enable us to trigger a search from either above (receiving tracking id from external source), or below (receiving tracking id from article selector component)
	 */
	@api
	get trackingId() { return this._trackingId; }
	set trackingId(value) {
		this._trackingId = safeToUpper(safeTrim(value));
		if (value) {
			console.log('triggered another search');
			this.triggerSearch();
		}
	}

	//Contextual information passed in by the host component.
	@api hostContext = {};

	@api hasCaseInvestigations = false;
	@api caseInvestigations;
	@api caseConsignmentId;

	/**
	 * Handles when case investigation's article ids are clicked.
	 */
	updateHappyParcels(event) {
		this.trackingId = event.target.dataset.id;
	}
	connectedCallback() {
		// preload the config so all the components do not have to make individual apex calls because the config hasn't loaded
		getConfig().then(result => {
			this.vodvKnowledgeId = result.VODVKnowledgeId;
			this._signatureEventTypes = result.signatureEventTypes;
		});

		this.template.addEventListener('idclick', this.handleIdLinkClick);
		subscribe('generatePodPDF', this.handlePODPDFDownload);
	}

	disconnectedCallback() {
		this.template.removeEventListener('idclick', this.handleIdLinkClick);
		unsubscribe('generatePodPDF', this.handlePODPDFDownload);
	}

	/**
	 * When case investigation detail is accessed from list view, show its parent case consignment number.
	 * If ST case is searched globally and accessed then do not show case consignement number.
	 */
	get isRenderConsigmentNumber() {
		return (this.hasCaseInvestigations ? false : true);
	}

	/**
	 * When case investigation is accessed from list view, list of case investigations under a star track are passed.
	 */
	get isStarTrackCase() {
		return (this.caseInvestigations && this.caseInvestigations.length > 0 ? true : false);
	}

	/**
	 * Populate case investigations array based on article numbers. 
	 */
	get articleItems() {
		var items = [];
		this.caseInvestigations.forEach((item, index) => {
			items.push({
				label: item.Article__r,
				isLink: true
			});
		});
		return items;

	}

	/**
	 * Handles a click when the users clicks a link that requires an ID page to open.
	 * This may be handle by an external provider (such as where Happy Parcel is embedded in MyCustomer (mini case will catch this and use the classic console api to open a new primary tab))
	 */
	handleIdLinkClick = (e) => {
		if (!this.supportsExternalLinkHandling) {
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
		if (currentTrackingId !== this._trackingId) {
			this.removeStaleSearchTrackingObjects(currentTrackingId);
			return;
		}

		const { errors, doRetry, articles } = result;

		// assign the tracking response for each article into the articles array
		// we need to loop
		if (articles) {
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

		if (doRetry) {
			// since there was a problem with the remote server and it requires a retry then show a button that allows the user to click to try again
			this.retryAnalytics = true;
		}

		// add any errors from the request
		if (errors) {
			this.errors = this.errors.concat(errors.map(item => {
				return {
					source: CONSTANTS.ANALYTICS_API,
					message: CONSTANTS.ANALYTICS_API + ': ' + item
				};
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
		const result = await getTrackingApiResponse(currentTrackingId, this.forceConsignmentLevelResults);

		// perform a check to ensure the current article id is the same article id that was passed into the async function
		// it's possible that while the current search was in progress that another tracking id was passed into the mix
		// NOTE: There shouldn't be a need to reset the loadingTrackingApi var since another query should be in progress
		if (currentTrackingId !== this._trackingId) {
			this.removeStaleSearchTrackingObjects(currentTrackingId);
			return;
		}

		const { errors, consignment, articles, requireAdditionalQueryForStarTrack, totalArticlesDelivered } = result;

		// add the consignment trackingResults to the consignment object
		if (consignment) {
			this.consignment = { ...this.consignment, trackingId: consignment.trackingId, trackingResult: consignment };
			// expand the relevant article accordion based on initial article Id search, when a force consignment search scenario occurs
			if (this.forceConsignmentLevelResults && consignment.trackingId !== currentTrackingId) {
				this.activeSections.push(currentTrackingId);
			}
			const totalArticlesDeliveredField = [
				{
					fieldLabel: "Total Delivered",
					fieldType: "STRING",
					fieldValue: totalArticlesDelivered
				}
			];
			this.consignment.trackingResult.additionalAttributes = totalArticlesDeliveredField;
		}

		// assign the tracking response for each article into the articles array
		// we need to loop
		if (articles) {
			//Get published critical incident knowledge articles that are available in the system
			const criticalIncidents = await getCriticalIncidentDetails();
			articles.forEach((item) => {
				let articleIndex = this.articles.findIndex(article => article.trackingId === item.trackingId);
				if (articleIndex > -1) {
					// this scenario would be the following:
					// 1. the search result returned was the same that was searched for (not a consignment)
					// 2. another api query was completed (analytics api for example) and populated this structure
					this.articles[articleIndex].trackingResult = item;
					if (item.article.VODV_Redirect__c) {
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
					//Add related critical incidents to the article based on network Id
					let events = item.events;
					events.forEach((event) => {
						if (event.event.FacilityOrganisationID__c) {
							event.criticalIncidents = criticalIncidents[event.event.FacilityOrganisationID__c];
						}
					});

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
		if (errors && errors.length > 0) {
			this.errors = this.errors.concat(
				errors.map((item) => {
					return {
						source: CONSTANTS.TRACKING_API,
						message: CONSTANTS.TRACKING_API + ": " + item
					};
				})
			);
		} else {
			// build and publish 'searchCompleted' LMS Event
			const type = consignment ? 'Consignment' : 'Article';
			const trackingId = consignment ? consignment.trackingId : currentTrackingId;
			this.publishSapSearchCompletedLMS(type, trackingId);
		}

		this.loadingTrackingApi = false;

		// remove any items from the articles array that do not have valid entries
		// 1. api produced no results for the item in the local 'this.articles' store AND no other API calls have populated data for that article Id
		// 2. if the search was for a consignment, then we would remove the initial 'skeleton' structure used to show the loading ui effect
		this.tidyupLocalArticleStore();

		// trigger an async callout for StarTrack consignemnt
		this.requireAdditionalQueryForStarTrack = requireAdditionalQueryForStarTrack;

		// validate 'Download POD' button display
		this._displayPodDownloadButton = this.handlePODDownloadButtonDisplay();
	}

	/**
	 * @description Setter to trigger the StarTrack Async Callout when the flag is set TRUE
	 */
	set requireAdditionalQueryForStarTrack(value) {
		if (value) {
			this.doTrackingQueryForStarTrack(this.trackingId);
		}
	}

	/**
	 * @description make an async callout to dotNet API via ApexController and map returned attributes for display
	 * @param consignmentNumber 
	 */
	async doTrackingQueryForStarTrack(consignmentNumber) {
		this.requireAdditionalQueryForStarTrack = false;
		this.loadingStarTrackApi = true;
		// make Async callout
		const result = await getTrackingApiResponseForStarTrack(consignmentNumber, this.consignment);

		// add any errors from the request
		if (result.errors) {
			this.errors = this.errors.concat(result.errors.map(item => {
				return {
					source: CONSTANTS.STARTRACK_API,
					message: CONSTANTS.STARTRACK_API + ': ' + item
				};
			}));
			this.loadingStarTrackApi = false;
			this.retryStarTrackCallout = true;
		}

		// additional attributes mapping
		result.article.ProductCategory__c = this.articles?.[0]?.trackingResult?.article?.ProductCategory__c ?? result.article.ProductCategory__c;
		result.article.SubProduct__c = this.articles?.[0]?.trackingResult?.article?.SubProduct__c ?? result.article.SubProduct__c;
		result.additionalAttributes = this.consignment?.trackingResult?.additionalAttributes ?? result.additionalAttributes;
		// populate EDD for StarTrack including a flag to pass down to child component(happyParcelEdd)
		this.articles?.forEach(item => {
			// only set isDotNetEdd to TRUE if both EDD and SourceSystem data from .NET are not null
			const dotNetEddExists = !!(result.article?.ExpectedDeliveryDate__c && result.article?.Source_System__c);
			item.trackingResult.isDotNetEdd = dotNetEddExists;
			item.trackingResult.article.ExpectedDeliveryDate__c = dotNetEddExists ? result.article?.ExpectedDeliveryDate__c : item.trackingResult.article.ExpectedDeliveryDate__c;
			item.trackingResult.article.Source_System__c = dotNetEddExists ? result.article?.Source_System__c : item.trackingResult.article.Source_System__c;
		});
		// update display attributes from StarTrack response
		this.consignment.trackingResult = result;
		this.retryStarTrackCallout = false;
		this.loadingStarTrackApi = false;
		// validate 'Download POD' button display
		this._displayPodDownloadButton = this.handlePODDownloadButtonDisplay();
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
		let sectionDiff = openSections.filter(x => !this.activeSections.includes(x));
		if (sectionDiff.length > 0) {
			this.activeSections = sectionDiff;
		}

		// hide/show the summary path since it's displayed in bigger form when the accordion is open
		for (let i = 0; i < this.articles.length; i++) {
			if (openSections.includes(this.articles[i].trackingId)) {
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
		for (let i = 0; i < this.articles.length; i++) {
			if (this.articles[i].trackingId === event.target.dataset.article) {
				this.articles[i] = { ...this.articles[i], articleSelected: !this.articles[i].articleSelected };
				break;
			}
		}

		// build and publish LMS Event for selected articles
		const selectedArticles = this.articles.filter((item) => item.articleSelected).map((item) => item.trackingId);
		this.publishSelectedArticlesLMS(this.consignment.trackingId, selectedArticles);

		this.broadcastSelectedArticles();
	}

	handleKnowledgeClick() {
		this.dispatchEvent(new CustomEvent('idclick', { detail: { id: this.vodvKnowledgeId }, bubbles: true, composed: true }));
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
		//There is a scenario where a new tracking id may be passed into the component while a search is already in progress
		//If this happens, passing the tracking id in allows to ignore the search results if they are out of sync with the current component state
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
		this.consignment = { trackingResults: {}, analyticsResult: {} };
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
		if (this.loadingTrackingApi)
			return;

		for (let i = this.articles.length - 1; i >= 0; i--) {
			// remove the elements we need to ignore which includes the .trackingId and the attribute we have just passed in
			let isEmpty = (Object.entries(this.articles[i].trackingResult).length === 0) && (Object.entries(this.articles[i].analyticsResult).length === 0);
			if (isEmpty) {
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
		for (let i = this.articles.length - 1; i >= 0; i--) {
			if (this.articles[i].trackingId === oldTrackingId) {
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
		if (e && e.detail) {
			const { type } = e.detail;
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
		if (e && e.detail) {
			const { type } = e.detail;
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
		if (this.consignment && this.consignment.trackingId) {
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
		} else if (this.articles && this.articles.length > 0) {
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

	/**
	 * @description handle retry StarTrack Async callout by using Setter to set to TRUE and trigger the callout
	 */
	handleRetryStarTrackCallout() {
		this.errors = this.errors.filter(error => error.source !== CONSTANTS.STARTRACK_API);
		this.retryStarTrackCallout = false;
		this.requireAdditionalQueryForStarTrack = true;
	}

	/**
	 * @description	Display a download button for Proof of delivery PDF in the consignment detail of happyParcelCard component
	 *				Validate that the article has been delivered by checking the eventMessage for existing safe drop GUID(Safe_Drop_GUID__c) or signature(SignatureXString__c)
	 */
	handlePODDownloadButtonDisplay() {
		let signatureExists = false;
		let safeDropExists = false;
		// check if signature or safe drop exists on this article, which means that the article has been delivered
		this.articles?.some(article =>
			article.trackingResult?.events?.some(item => {
				if (this._signatureEventTypes.includes(item.event.EventType__c) && item.event.SignatureXString__c) {
					signatureExists = true;
				}
				// check for SafeDropGUID (we don't check for specific event types since an 'attachment type' check is done when the article is queried from the tracking API
				if (item.event.Safe_Drop_GUID__c) {
					safeDropExists = true;
				}
				return signatureExists || safeDropExists; // Exit early if either condition is met
			})
		);
		const finishLoading = !this.loadingStarTrackApi && !this.loadingTrackingApi;
		return this.consignment && finishLoading && (safeDropExists || signatureExists);
	}

	/**
	 * @description	Execute action to generate and download the proof of delivery PDF
	 */
	handlePODPDFDownload = async () => {
		this.loadingPODPDFDownload = true;
		try {
			const trackingIds = {
				consignmentId: this.consignment.trackingId,
				articleId: null
			};
			await downloadPODPDF(trackingIds);
		} catch (exception) {
			console.error(exception);
		}
		this.loadingPODPDFDownload = false;
	}

	/**
	 * @description Publish the selected articles LMS event
	 * @param trackingId
	 * @param selectedArticles
	 */
	publishSelectedArticlesLMS(trackingId, selectedArticles) {
		const lmsEventPayload = {
			source: 'HappyParcel',
			type: 'articleSelected',
			body: {
				consignmentId: trackingId,
				selectedArticleIds: selectedArticles
			}
		};
		publish(this.messageContext, GENERIC_LMS_CHANNEL, lmsEventPayload);
	}

	/**
	 * @description Publish the SAP search complete LMS event
	 * @param type
	 * @param trackingId
	 */
	publishSapSearchCompletedLMS(type, trackingId) {
		const lmsEventPayload = {
			source: 'HappyParcel',
			type: 'searchCompleted',
			body: {
				type: type,
				trackingId: trackingId
			}
		}
		publish(this.messageContext, GENERIC_LMS_CHANNEL, lmsEventPayload);
	}

	get displayPodDownloadButton() {
		return this._displayPodDownloadButton;
	}

	get loadingConsignmentDetailsCard() {
		return this.loadingPODPDFDownload || this.loadingTrackingApi;
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
		if (this.isConsignment) {
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

	/**
	 * Display Analytic API related error
	 */
	get hasAnalyticsErrors() {
		return this.errors.filter(error => error.source === CONSTANTS.ANALYTICS_API);
	}

	/**
	 * Display Tracking API related error
	 */
	get hasTrackingErrors() {
		return this.errors.filter(error => error.source === CONSTANTS.TRACKING_API);
	}

	/**
	 * Display StarTrack API related error
	 */
	get hasStarTrackErrors() {
		return this.errors.filter(error => error.source === CONSTANTS.STARTRACK_API);
	}

	/**
	 * Display the Retry hyperlink on the error banner for retrying StarTrack Callout
	 */
	get doRetryStarTrackCallout() {
		return this.retryStarTrackCallout;
	}

}