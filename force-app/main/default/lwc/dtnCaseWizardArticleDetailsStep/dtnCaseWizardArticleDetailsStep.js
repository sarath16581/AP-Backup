/**
 * @description Step capturing details related to the article in Direct to Network Case creation flow.
 * @author Ranjeewa Silva
 * @date 2020-10-05
 * @changelog
 * 2020-10-05 - Ranjeewa Silva - Created
 */

import { LightningElement, api } from 'lwc';

export default class DtnCaseWizardArticleDetailsStep extends LightningElement {

    @api article;
    @api messageToNetworkDefaultValue

    datePosted;
    valueOfContents;
    descriptionOfContents;
    messageToNetwork;

    get articleLodgementDate() {
        if (!this.datePosted && this.article) {
            this.datePosted = this.article.ArticleLodgementDate__c;
        }
        return this.datePosted;
    }

    handleValueOfContentsChange(e) {
        this.valueOfContents = e.target.value;
    }

    handleDatePostedValueChange(e) {
        this.datePosted = e.target.value;
    }

    handleDescriptionOfContentsValueChange(e) {
        this.descriptionOfContents = e.target.value;
    }

    handleMessageToNetworkValueChange(e) {
        this.messageToNetwork = e.target.value;
    }

    @api validate() {
        const inputComponents = this.template.querySelectorAll(".article-input");
        const inputsArray = inputComponents ? [...inputComponents] : [];
        return inputsArray.reduce((acc, inputCmp) => {
            inputCmp.reportValidity();
            return acc && inputCmp.checkValidity();
        }, true);
    }

    @api getFieldValues() {
        return {
            datePosted: this.datePosted,
            valueOfContents: this.valueOfContents,
            descriptionOfContents: this.descriptionOfContents,
            messageToNetwork: (this.messageToNetwork ? this.messageToNetwork : this.messageToNetworkDefaultValue)
        };
    }

}