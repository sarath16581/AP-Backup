/**
  * @author       : Sameed Khan<sameed.khan@mav3rik.com>
  * @date         : 01/05/2019
  * @description  : Component that searches SAP EM for articles
--------------------------------------- History --------------------------------------------------
01.04.2019    Sameed Khan(Mav3rik)    Created
07.07.2022    Talib Raza - REQ2859463: Auto capitalised the value in handleArticleNumberChange and uplifted API version to 52
**/
import { LightningElement, track, api } from 'lwc'
import { showNotification } from 'c/utils'

export default class ArticleSearch extends LightningElement {
    @api name
    @api label = 'Article Id'
    @api placeholder = 'Click search icon after article ID entered'
    @api fieldLevelHelp = 'Enter Article ID, if known.'
    @api formUpdateCallback
    @api required = false
    @api getOnlyArticles = false
    @api getOnlyConsignments = false

    @track searchResult
    @track verified = false
    @track loading = false
    @track articleNumber

    @api formUpdateArticleid

    get variant() {
        return this.label ? 'standard' : 'label-hidden'
    }

    get formUpdateDisabled() {
        return !this.verified
    }

    @api getSearchResult = () => this.searchResult

    updateParentForm () {
        if (typeof this.formUpdateCallback === 'function') {
            this.formUpdateCallback(this.searchResult)
        }
    }

    searchArticle() {
        const filterChangeEvent = new CustomEvent('asynchapexcontinuationrequest', {
            detail: {
                className: "ArticleSearchSAPEM",
                methodName: "SearchArticle",
                methodParams: [this.articleNumber],
                useAsynchCallout: true,
                callback: this.articleSearchResultHandler
            },
            bubbles: true,
            composed: true,
        })
        this.loading = true
        // Fire the custom event
        this.dispatchEvent(filterChangeEvent)
    }

    handleArticleNumberChange = event => {
        this.verified = false
        this.articleNumber = event.target.value.toUpperCase()

        if (typeof this.formUpdateArticleid === 'function') {
            this.formUpdateArticleid(this.articleNumber)
        }
    }

    articleSearchResultHandler = data => {
        this.loading = false
        const parsedData = JSON.parse(JSON.stringify(data))
        if (parsedData.error) {
            showNotification(parsedData.error, 'error', 'Search Unsuccessful','sticky')(this)
        } else if (parsedData.payload) {
            if (parsedData.payload.trackResults.length === 0) {
                showNotification('Article ID does not exist', 'error','','sticky')(this)
            } else {
                const result = parsedData.payload.trackResults[0] //the first item in the array is used as the search result since there can only ever be one search result as we search by tracking number
                if (this.getOnlyArticles && this.isArticle(result) || (this.getOnlyConsignments && this.isConsignment(result) || (this.getOnlyArticles === false && this.getOnlyConsignments === false))){
                    this.verified = true
                    this.searchResult = result
                } else if (this.getOnlyArticles && this.isConsignment(result)) {
                    showNotification('You have searched with a consignment Id when an article Id was expected. Please search again with the article Id instead.', 'warning','','sticky')(this)
                    //console.log('this is consignment id');
                    //this.verified = true
                    //this.searchResult = result
                } else if (this.getOnlyConsignments && this.isArticle(result)) {
                    showNotification('You have searched with a article Id when consignment Id was expected. Please search again with the consignment Id instead.', 'warning','','sticky')(this)
                }
            }
        }
    }

    @api reportValidity(){
        const inputComponent = this.template.querySelector(".lookup")
        inputComponent.reportValidity()
    }

    @api checkValidity(){
        const inputComponent = this.template.querySelector(".lookup")
        return inputComponent.checkValidity()
    }

    // the search result is a consignment if it has a property called 'consignmentDetails' and article otherwise (articles have a property called 'articleDetails')
    isConsignment = searchResult => searchResult && searchResult.hasOwnProperty('consignmentDetails')

    isArticle = searchResult => !this.isConsignment(searchResult)
}