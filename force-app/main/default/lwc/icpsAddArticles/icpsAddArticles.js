/**
 * @description ICPS Add Articles
 * @author Harry Wang
 * @date 2022-05-11
 * @group Controller
 * @changelog
 * 2022-05-11 - Harry Wang - Created
 */
import {api, LightningElement, track} from 'lwc';
import OBJECT_ICPS_ARTICLE from '@salesforce/schema/ICPSArticle__c';
import FIELD_NAME from '@salesforce/schema/ICPSArticle__c.Name';
import FIELD_ICPS from '@salesforce/schema/ICPSArticle__c.ICPS__c';
import FIELD_CONTENTS from '@salesforce/schema/ICPSArticle__c.Contents__c';
import FIELD_WEIGHT from '@salesforce/schema/ICPSArticle__c.Weight__c';
import FIELD_DECLARED_VALUE from '@salesforce/schema/ICPSArticle__c.DeclaredValue__c';
import FIELD_POSTAGE_INSURANCE from '@salesforce/schema/ICPSArticle__c.PostageInsurance__c';
import FIELD_SENDER_NAME from '@salesforce/schema/ICPSArticle__c.SenderName__c';
import FIELD_SENDER_STREET_LINE_1 from '@salesforce/schema/ICPSArticle__c.SenderStreetLine1__c';
import FIELD_SENDER_STREET_LINE_2 from '@salesforce/schema/ICPSArticle__c.SenderStreetLine2__c';
import FIELD_SENDER_CITY from '@salesforce/schema/ICPSArticle__c.SenderCity__c';
import FIELD_SENDER_POSTAL_CODE from '@salesforce/schema/ICPSArticle__c.SenderPostalCode__c';
import FIELD_SENDER_STATE from '@salesforce/schema/ICPSArticle__c.SenderState__c';
import FIELD_SENDER_COUNTRY from '@salesforce/schema/ICPSArticle__c.SenderCountry__c';
import FIELD_RECEIVER_NAME from '@salesforce/schema/ICPSArticle__c.ReceiverName__c';
import FIELD_RECEIVER_EMAIL from '@salesforce/schema/ICPSArticle__c.ReceiverEmail__c';
import FIELD_RECEIVER_MOBILE from '@salesforce/schema/ICPSArticle__c.ReceiverMobile__c';
import FIELD_RECEIVER_STREET_LINE_1 from '@salesforce/schema/ICPSArticle__c.ReceiverStreetLine1__c';
import FIELD_RECEIVER_STREET_LINE_2 from '@salesforce/schema/ICPSArticle__c.ReceiverStreetLine2__c';
import FIELD_RECEIVER_CITY from '@salesforce/schema/ICPSArticle__c.ReceiverCity__c';
import FIELD_RECEIVER_POSTAL_CODE from '@salesforce/schema/ICPSArticle__c.ReceiverPostalCode__c';
import FIELD_RECEIVER_STATE from '@salesforce/schema/ICPSArticle__c.ReceiverState__c';
import getICPSWithArticles from '@salesforce/apex/ICPSServiceController.getICPSWithArticles';
import searchICPSArticles from '@salesforce/apex/ICPSServiceController.searchICPSArticlesInSAP';
import saveArticles from '@salesforce/apex/ICPSServiceController.saveArticles';
import { get } from 'c/utils';
import LABEL_INVALID_INPUTS from '@salesforce/label/c.ICPSAddArticlesInvalidInputs';
import LABEL_MANUAL_MANDATORY from '@salesforce/label/c.ICPSAddArticlesManualFieldMandatory';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class IcpsAddArticles extends LightningElement {

	// store ICPS record id passed by LWC framework
	_recordId;
	@api get recordId() { return this._recordId}
	set recordId(value) {
	    if (value && this._recordId != value) {
	        // received a valid record id value. load existing ICPS articles for this ICPS record.
	        this._recordId = value;
			this.loadExistingICPSArticles(value);
        }
    }

    // collection of existing icps articles for this ICPS record. existing icps articles can be updated using this component.
    @track existingArticles = [];

    // collection of new icps articles to be added based on SAP EM article search results.
	@track newArticles = [];

	// Current ICPS
	ICPS;

	// indicates article search is disabled
	disabledSearch = true;

	// indicates the icps articles are currently being saved.
	isSaving = false;

	// error message to be displayed on screen.
	errorMessage;

	/**
	 * return a list of articles combining existing icps articles and new articles the user is attempting to add by
	 * searching in SAP EM.
	 */
	get articles() {
		const output = [];
		if (this.existingArticles.length > 0) {
			output.push(...this.existingArticles);
        }
		if (this.newArticles.length > 0) {
			output.push(...this.newArticles);
        }
		return output;
	}

	/**
	 * returns if article save button is to be disabled. save button is only enabled if there are changes on screen
	 * requiring save and no loading articles.
	 */
	get isArticleSaveDisabled() {
	    const dirtyArticles = this.getNewOrUpdatedArticles();
		const isLoading = this.newArticles.reduce((isLoading, a) => {
			return isLoading || a.icpsArticle == null
		}, false)
		return (dirtyArticles.length === 0 || isLoading);
    }

    /**
     * returns true if icps article data (either existing or new) is available for display.
     */
    get hasArticlesToDisplay() {
        return (this.articles != null && this.articles.length > 0);
    }

	/**
	 * handler for searching an article number in SAP EM.
	 */
	handleSearch(event) {
		this.disabledSearch = true;
		this.errorMessage = '';
		const input = this.template.querySelector(".search-input").value;
		if (this.validateSearchInput(input)) {
			// add a new row with article number only. icpsArticle details will be added when the search returns.
			this.newArticles.push({trackingId: input});

			searchICPSArticles({
				trackingId: input,
			}).then((result) => {
			    // search results has been received.
			    // locate the article and update based on article search results.
				let articleIndex = this.newArticles.findIndex(item => item.trackingId === input);
				if (articleIndex > -1) {
					let article = this.newArticles[articleIndex];
					if (result.consignments != null && result.consignments.length > 0) {
						article.error = 'Search failed: consignment found';
					} else {
						article.icpsArticle = this.newICPSArticle(result.articles[0]);
						article.isNew = true;
						article.isDirty = false;
						article.error = result.articles[0].error;
						if (article.error != null) {
							article.icpsArticle.ArticleNotInSAPEM__c = true;
						}
					}
                }
			}).catch((error) => {
				let articleIndex = this.newArticles.findIndex(item => item.trackingId === input);
				if (articleIndex > -1) {
					let article = this.newArticles[articleIndex];
					article.icpsArticle = {};
					article.error = 'Search failed: ' + error.body.message;
				}
			});
		}
		this.disabledSearch = false;
	}

	/**
	 * handler for saving new and updated icps articles.
	 */
	handleSave(event) {
		this.errorMessage = '';
        const newOrUpdatedArticles = this.getNewOrUpdatedArticles();
		const updateICPS = this.getICPSToBeUpdated();

		// Check input validity
		const inputValid = [...this.template.querySelectorAll('lightning-input')].reduce((validSoFar, inputCmp) => {
			inputCmp.reportValidity();
			return validSoFar && inputCmp.checkValidity();
		}, true);

		// Check mandatory for manually-input articles
		// If article is not found in SAP EM, below fields are mandatory for manual saving:
		// ReceiverName__c, SenderName__c, Contents__c, DeclaredValue__c, Weight__c
		const checkMandatory = this.newArticles.filter(article => {
			return article.icpsArticle.ArticleNotInSAPEM__c;
		}).reduce((valid, article) => {
			const icpsArticle = article.icpsArticle;
			return valid && article.error == null && icpsArticle.ReceiverName__c != null && icpsArticle.ReceiverName__c.trim() !== ''
				&& icpsArticle.SenderName__c != null && icpsArticle.SenderName__c.trim() !== ''
				&& icpsArticle.Contents__c != null && icpsArticle.Contents__c.trim() !== ''
				&& icpsArticle.DeclaredValue__c != null && icpsArticle.DeclaredValue__c.trim() !== ''
				&& icpsArticle.Weight__c != null && icpsArticle.Weight__c.trim() !== '';
		}, true);

		if (!inputValid) {
			this.errorMessage = LABEL_INVALID_INPUTS;
			return;
		}
		if (!checkMandatory) {
			this.errorMessage = LABEL_MANUAL_MANDATORY;
			return;
		}
		if (newOrUpdatedArticles.length > 0) {
			if (confirm("Are you sure to add these articles to the ICPS?")) {
				this.isSaving = true;
				saveArticles({
					articles: newOrUpdatedArticles,
					icps: updateICPS
				}).then((result) => {
					this.dispatchEvent(new CustomEvent("modalclose"));
					this.dispatchEvent(new CustomEvent("modalrefresh"));
					let event = new ShowToastEvent({
						message: 'Adding articles succeeded.',
						variant: 'success'
					});
					this.dispatchEvent(event);
				}).catch((error) => {
					this.errorMessage = 'Adding articles failed: ' + error.body.message;
				}).finally(() => {
					this.isSaving = false;
				});
			}
		}
    }

    /**
     * handle changes to receiver name
     */
    handleReceiverNameChange(event) {
        this.setArticleFieldValue(event.target.dataset.articleNumber, event.target.dataset.isNew, FIELD_RECEIVER_NAME.fieldApiName, event.target.value);
    }

	/**
     * handle changes to sender name
     */
    handleSenderNameChange(event) {
        this.setArticleFieldValue(event.target.dataset.articleNumber, event.target.dataset.isNew, FIELD_SENDER_NAME.fieldApiName, event.target.value);
    }

	/**
     * handle changes to article weight
     */
    handleArticleWeightChange(event) {
        this.setArticleFieldValue(event.target.dataset.articleNumber, event.target.dataset.isNew, FIELD_WEIGHT.fieldApiName, event.target.value);
    }

	/**
     * handle changes to article contents value
     */
    handleContentsValueChange(event) {
        this.setArticleFieldValue(event.target.dataset.articleNumber, event.target.dataset.isNew, FIELD_CONTENTS.fieldApiName, event.target.value);
    }

	/**
     * handle changes to declared value
     */
    handleDeclaredValueChange(event) {
        this.setArticleFieldValue(event.target.dataset.articleNumber, event.target.dataset.isNew, FIELD_DECLARED_VALUE.fieldApiName, event.target.value);
    }

	/**
	 * handle changes to insured value
	 */
	handleInsuredValueChange(event) {
		this.setArticleFieldValue(event.target.dataset.articleNumber, event.target.dataset.isNew, FIELD_POSTAGE_INSURANCE.fieldApiName, event.target.value);
	}

	/**
	 * handle delete row
	 */
	handleDeleteRow(event) {
		if (confirm("Are you sure to remove this article from the list")) {
			const articleIndex = this.newArticles.findIndex(item => item.trackingId === event.target.dataset.articleNumber);
			if (articleIndex > -1) {
				this.newArticles.splice(articleIndex, 1);
			}
		}
	}

	/**
	 * handle add a new article manually
	 */
	handleAddArticle(event) {
		const articleIndex = this.newArticles.findIndex(item => item.trackingId === event.target.dataset.articleNumber);
		if (articleIndex > -1) {
			this.newArticles[articleIndex].error = null;
			this.newArticles[articleIndex].isDirty = false;
		}
	}

    /**
     * handle clicking on the cancel button.
     */
    handleCancel(event) {
	    this.dispatchEvent(new CustomEvent("modalclose"));
    }

    /**
     * load any existing icps with articles for this ICPS record.
     */
    loadExistingICPSArticles(recordId) {
        // Get existing ICPS articles from Salesforce
	    getICPSWithArticles({
            icpsId: recordId
        }).then((result) => {
			if (result.ICPS_Articles__r != null) {
				this.existingArticles = result.ICPS_Articles__r.map(article => {
					return {
						'icpsArticle': article,
						'trackingId' : article.Name,
						'isDirty': false,
						'isNew': false,
					}
				});
			}
			let {ICPS_Articles__r, ...ICPS} = result;
			this.ICPS = ICPS;
        }).catch((error) => {
            this.errorMessage = 'Retrieving articles failed: ' + error.body.message;
        }).finally(() => {
            this.disabledSearch = false;
        })
    }

    /**
     * returns a new icps article populated from the tracking article received via article search.
     */
    newICPSArticle(trackingArticle) {
        let icpsArticle = {'sobjectType': OBJECT_ICPS_ARTICLE.objectApiName};
        icpsArticle[FIELD_NAME.fieldApiName] = trackingArticle.trackingId;
        icpsArticle[FIELD_ICPS.fieldApiName] = this.recordId;
        icpsArticle[FIELD_CONTENTS.fieldApiName] = get(trackingArticle, 'article.ContentsItems__c', null);
        icpsArticle[FIELD_WEIGHT.fieldApiName] = get(trackingArticle, 'article.ActualWeight__c', null);
        icpsArticle[FIELD_DECLARED_VALUE.fieldApiName] = get(trackingArticle, 'article.ArticleTransitAmountValue__c', null);
        icpsArticle[FIELD_POSTAGE_INSURANCE.fieldApiName] = get(trackingArticle, 'article.InsuranceAmount__c', null);
        icpsArticle[FIELD_SENDER_NAME.fieldApiName] = get(trackingArticle, 'article.SenderName__c', null);
        icpsArticle[FIELD_SENDER_STREET_LINE_1.fieldApiName] = get(trackingArticle, 'article.SenderAddressLine1__c', null);
        icpsArticle[FIELD_SENDER_STREET_LINE_2.fieldApiName] = get(trackingArticle, 'article.SenderAddressLine2__c', null);
        icpsArticle[FIELD_SENDER_CITY.fieldApiName] = get(trackingArticle, 'article.SenderCity__c', null);
        icpsArticle[FIELD_SENDER_POSTAL_CODE.fieldApiName] = get(trackingArticle, 'article.SenderPostcode__c', null);
        icpsArticle[FIELD_SENDER_STATE.fieldApiName] = get(trackingArticle, 'article.SenderState__c', null);
        icpsArticle[FIELD_SENDER_COUNTRY.fieldApiName] = get(trackingArticle, 'article.SenderCountry__c', null);
        icpsArticle[FIELD_RECEIVER_NAME.fieldApiName] = get(trackingArticle, 'article.ReceiverName__c', null);
        icpsArticle[FIELD_RECEIVER_EMAIL.fieldApiName] = get(trackingArticle, 'article.ReceiverEmail__c', null);
        icpsArticle[FIELD_RECEIVER_MOBILE.fieldApiName] = get(trackingArticle, 'article.Receiver_Mobile__c', null);
        icpsArticle[FIELD_RECEIVER_STREET_LINE_1.fieldApiName] = get(trackingArticle, 'article.ReceiverAddressLine1__c', null);
        icpsArticle[FIELD_RECEIVER_STREET_LINE_2.fieldApiName] = get(trackingArticle, 'article.ReceiverAddressLine2__c', null);
        icpsArticle[FIELD_RECEIVER_CITY.fieldApiName] = get(trackingArticle, 'article.ReceiverCity__c', null);
        icpsArticle[FIELD_RECEIVER_POSTAL_CODE.fieldApiName] = get(trackingArticle, 'article.ReceiverPostcode__c', null);
        icpsArticle[FIELD_RECEIVER_STATE.fieldApiName] = get(trackingArticle, 'article.ReceiverState__c', null);
        return icpsArticle;
    }

	/**
	 * get a list of new or updated articles (i.e. dirty) that need to be saved.
	 */
	getNewOrUpdatedArticles() {
		return this.articles.filter(article => {
			return article.error == null && (article.isNew || article.isDirty)
		}).map(article => {
			return article.icpsArticle;
		});
	}

	/**
	 * get ICPS with blank receiver name on the first article added
	 */
	getICPSToBeUpdated() {
		if (this.ICPS.ReceiverName__c == null && this.existingArticles.length === 0 && this.getNewOrUpdatedArticles().length > 0) {
			this.ICPS.ReceiverName__c = this.getNewOrUpdatedArticles()[0].ReceiverName__c;
			this.ICPS.ReceiverStreetLine1__c = this.getNewOrUpdatedArticles()[0].ReceiverStreetLine1__c;
			this.ICPS.ReceiverStreetLine2__c = this.getNewOrUpdatedArticles()[0].ReceiverStreetLine2__c;
			this.ICPS.ReceiverCity__c = this.getNewOrUpdatedArticles()[0].ReceiverCity__c;
			this.ICPS.ReceiverPostalCode__c = this.getNewOrUpdatedArticles()[0].ReceiverPostalCode__c;
			this.ICPS.ReceiverState__c = this.getNewOrUpdatedArticles()[0].ReceiverState__c;
			this.ICPS.ReceiverEmail__c = this.getNewOrUpdatedArticles()[0].ReceiverEmail__c;
			this.ICPS.ReceiverMobile__c = this.getNewOrUpdatedArticles()[0].ReceiverMobile__c;
			this.ICPS.SenderName__c = this.getNewOrUpdatedArticles()[0].SenderName__c;
			this.ICPS.SenderStreetLine1__c = this.getNewOrUpdatedArticles()[0].SenderStreetLine1__c;
			this.ICPS.SenderStreetLine2__c = this.getNewOrUpdatedArticles()[0].ReceiverStreetLine2__c;
			this.ICPS.SenderCity__c = this.getNewOrUpdatedArticles()[0].SenderCity__c;
			this.ICPS.SenderPostalCode__c = this.getNewOrUpdatedArticles()[0].SenderPostalCode__c;
			this.ICPS.SenderState__c = this.getNewOrUpdatedArticles()[0].SenderState__c;
			this.ICPS.SenderCountry__c = this.getNewOrUpdatedArticles()[0].SenderCountry__c;
			return this.ICPS;
		}
		return null;
	}

	/**
	 * locate the article with the specified articleNumber and set the specified field to value supplied.
	 */
	setArticleFieldValue(articleNumber, isNew, field, value) {
        let articles = isNew === 'false' ? this.existingArticles : this.newArticles;
        const articleIndex = articles.findIndex(item => item.trackingId === articleNumber);
        if (articleIndex > -1) {
			articles[articleIndex].icpsArticle[field] = value;
			articles[articleIndex].isDirty = true;
        }
    }

	validateSearchInput(input) {
		if (input == null || input.trim() === '') {
			this.errorMessage = 'Please specify an article number prior to clicking on the Search button';
			return false;
		}
		if (this.articles.some(a => input.trim() === a.trackingId)) {
			this.errorMessage = 'Article: ' + input + ' has already been added to this ICPS';
			return false;
		}
		return true;
	}
}