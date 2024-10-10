import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getCasesRelatedToArticle from '@salesforce/apex/UnifiedCaseHistoryController.getCasesRelatedToArticle';
import getCasesRelatedToContact from '@salesforce/apex/UnifiedCaseHistoryController.getCasesRelatedToContact';
import COLUMNS from './columns';
import UiModal from 'c/uiModal';
import { reduceErrors } from 'c/ldsUtils';

const MAX_ROWS_TO_DISPLAY = 10;

/**
 * Displays cases related to a specified ContactId or ArticleId (could be consignment or child article).
 *
 * @changelog:
 * 2024-09-12 - Marcel HK - Created
 * 2024-10-01 - Marcel HK - Minor UI enhancements for link/unlink, title, no cases found message
 */
export default class UnifiedCaseHistory extends NavigationMixin(LightningElement) {
	/**
	 * The Case Id that is currently linked to the interaction
	 */
	@api linkedCaseId;

	_contactId;
	/**
	 * The Contact Id to use in the Cases query
	 * @type {string}
	 */
	@api set contactId(value) {
		if (this._contactId !== value) {
			this._contactId = value;
			this.casesRelatedToContactData = undefined;
			refreshApex(this.wiredCasesRelatedToContact);
		}
	}
	get contactId() {
		return this._contactId;
	}

	_articleId;
	/**
	 * The Article Id (lookup to the `Article__c` object) related to the interaction record
	 * @type {string}
	 */
	@api set articleId(value) {
		if (this._articleId !== value) {
			this._articleId = value;
			this.casesRelatedToArticleData = undefined;
			refreshApex(this._wiredCasesRelatedToArticle);
		}
	}
	get articleId() {
		return this._articleId;
	}

	/**
	 * If 'true', hides the 'Link' button column
	 * @type {boolean}
	 */
	@api disableLinking = false;

	/**
	 * If 'true', hides the Lightning Card title and icon
	 * @type {boolean}
	 */
	@api hideCardTitle = false;

	//
	// CASES RELATED TO ARTICLE
	//

	/**
	 * Indicates data is being loaded.
	 * @type {boolean}
	 */
	get casesRelatedToArticleIsLoading() {
		return !this.casesRelatedToArticleData;
	}

	/**
	 * A list of cases to be displayed in the table.
	 * @type {object[]}
	 */
	get casesRelatedToArticleRows() {
		return this.casesRelatedToArticleData?.results.map(item => {
			return {
				...item,
				disableLinkButton: !item.isLinkable || item.caseId === this.linkedCaseId
			};
		});
	}

	/**
	 * Columns for the Cases related to Article `lightning-datatable` component.
	 */
	get casesRelatedToArticleColumns() {
		if(this.disableLinking) {
			return COLUMNS.filter(column => column.label !== 'Link');
		}
		return COLUMNS;
	}

	/**
	 * Indicates how many records were returned.
	 * @type {number}
	 */
	get casesRelatedToArticleCount() {
		return this.casesRelatedToArticleData?.results?.length ?? 0;
	}

	/**
	 * Indicates if there are more records to display.
	 * @type {boolean}
	 */
	get casesRelatedToArticleHasMore() {
		return this.casesRelatedToArticleData?.hasMore === true;
	}

	/**
	 * Used to display errors on the UI
	 * @type {string}
	 */
	casesRelatedToArticleError;

	/**
	 * Used to store the `@wire` data.
	 */
	casesRelatedToArticleData;

	//
	// CASES RELATED TO CONTACT
	//

	/**
	 * Indicates data is being loaded.
	 * @type {boolean}
	 */
	get casesRelatedToContactIsLoading() {
		return !this.casesRelatedToContactData;
	}

	/**
	 * A list of cases to be displayed in the table.
	 * @type {object[]}
	 */
	get casesRelatedToContactRows() {
		return this.casesRelatedToContactData?.results.map(item => ({
			...item,
			disableLinkButton: true
		}));
	}

	/**
	 * Columns for the Cases related to Contact `lightning-datatable` component.
	 */
	get casesRelatedToContactColumns() {
		return COLUMNS.filter(column => column.label !== 'Link');
	}

	/**
	 * Indicates how many records were returned.
	 * @type {number}
	 */
	get casesRelatedToContactCount() {
		return this.casesRelatedToContactData?.results?.length ?? 0;
	}

	/**
	 * Indicates if there are more records to display.
	 * @type {boolean}
	 */
	get casesRelatedToContactHasMore() {
		return this.casesRelatedToContactData?.hasMore === true;
	}

	/**
	 * Used to display errors on the UI
	 * @type {string}
	 */
	casesRelatedToContactError;

	/**
	 * Used to store the `@wire` data.
	 */
	casesRelatedToContactData;

	//
	// WIRE ADAPTERS
	//

	/**
	 * Retrieve the Cases related to the Article Id
	 */
	_wiredCasesRelatedToArticle;
	@wire(getCasesRelatedToArticle, { articleId: '$articleId', maxRecords: MAX_ROWS_TO_DISPLAY })
	async wiredCasesRelatedToArticle(result) {
		try {
			this._wiredCasesRelatedToArticle = result;
			if (result.error) {
				throw result.error;
			} else if (result.data) {
				this.casesRelatedToArticleData = await this.generateCaseRecordUrls(result.data);
			}
		} catch (error) {
			console.error(error);
			this.casesRelatedToArticleError = reduceErrors(error).join(',');
		}
	}

	/**
	 * Retrieve the Cases related to the Contact Id
	 */
	_wiredCasesRelatedToContact;
	@wire(getCasesRelatedToContact, { contactId: '$contactId', maxRecords: MAX_ROWS_TO_DISPLAY })
	async wiredCasesRelatedToContact(result) {
		try {
			this._wiredCasesRelatedToContact = result;
			if (result.error) {
				throw result.error;
			} else if (result.data) {
				this.casesRelatedToContactData = await this.generateCaseRecordUrls(result.data);
			}
		} catch (error) {
			console.error(error);
			this.casesRelatedToContactError = reduceErrors(error).join(',');
		}
	}

	//
	// Methods and Event Handlers
	//

	/**
	 * Generates and adds the Case URL to the results
	 * @param {object} data - The data from the `@wire` adapter
	 *
	 * @returns {object} data with caseUrl property added
	 */
	async generateCaseRecordUrls(data) {
		const obj = JSON.parse(JSON.stringify(data));
		await Promise.all(
			obj.results.map(item => {
				return this[NavigationMixin.GenerateUrl]({
					type: 'standard__recordPage',
					attributes: {
						recordId: item.caseId,
						objectApiName: 'Case',
						actionName: 'view'
					}
				}).then(url => {
					item.caseUrl = url;
					return url;
				});
			})
		);
		return obj;
	}

	/**
	 * Handle row action events from lightning-datatable.
	 *
	 *  - 'Link' Action Button Click: Fires the `lincase` event for the selected Case Id.
	 *
	 * @param {CustomEvent} event - The row action event.
	 *
	 * @fires {CustomEvent<{ caseId: string }>} `linkcase`
	 */
	async handleRowAction(event) {
		try {
			const caseId = event.detail?.row?.caseId;
			const caseNumber = event.detail?.row?.caseNumber;
			const actionName = event.detail?.action?.name;

			if (actionName === 'linkCase') {
				// Ask for user to confirm action first
				const result = await UiModal.open({
					label: 'Link Case',
					header: 'Link Case to my interaction',
					body: `Proceeding will link the selected Case ${caseNumber} to your interaction. Would you like to continue?`,
					size: 'small',
					description: 'Link the case to this interaction'
				});
				if (result.action === 'btnSubmit') {
					this.dispatchEvent(new CustomEvent('linkcase', { detail: { caseId } }));
				}
			}
		} catch (error) {
			console.error(error);
		}
	}

	/**
	 * Navigate to the Cases related list for Contact or Article.
	 *
	 * Expects the `data` attributes to be set for `recordId` and `objectApiName` on the HTML element.
	 * These are used to determine which list to navigate to.
	 *
	 * @param {Event} event - The click event.
	 */
	handleViewAllCasesClick(event) {
		event.preventDefault();
		const { recordId, objectApiName, relationshipApiName } = event.currentTarget.dataset;
		this[NavigationMixin.Navigate]({
			type: 'standard__recordRelationshipPage',
			attributes: {
				recordId: recordId,
				objectApiName: objectApiName,
				relationshipApiName: relationshipApiName,
				actionName: 'view'
			}
		});
	}
}