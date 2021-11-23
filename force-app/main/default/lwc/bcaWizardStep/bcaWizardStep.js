/*
 * @author Victor.Cheng@auspost.com.au
 * @date 2021-02-05
 * @channel Business Credit Account
 * @tag Business Credit Account
 * @description: Modified wizard framework step component
 * @changelog
 * 2020-12-10 Victor.Cheng@auspost.com.au  Created
 *
 */

import { LightningElement, api, track } from 'lwc';

export default class bcaWizardStep extends LightningElement {
    // #region public API properties
    @api name;
    @api label;
    @api subLabel;
    @api section;
    @api hideSections = false;
    @api beforeChange = function() { return true; }
    @api hidePreviousButton = false;
    @api hideNextButton = false;
    @api showLoader = false;
    hidePrintButton = true;  // added by 'Jansi'
    @api printLabel = 'Print page';  // added by 'Jansi'
    @api hideCss = '';

    // page id
    @api pageId = '';

    @track _isActive = false;
    @api get isActive() {
        return this._isActive;
    }
    set isActive(value) {
        this._isActive = value;

        if(value) {
            this.setAttribute('is-active', true);
            this.setAttribute('aria-hidden', false);
            this.classList.add('slds-show');
            this.classList.remove('slds-hide');
        } else {
            this.removeAttribute('is-active');
            this.setAttribute('aria-hidden', true);
            this.classList.remove('slds-show');
            this.classList.add('slds-hide');
        }
    }

    @api nextButtonLabel;
    @api previousButtonLabel;
    @api finishLabel;

    // #endregion

    // #region Tracked Properties
    @track isInit = false;
    // #endregion

    // #region Private Properties

    // back/next/finish
    labels;
/*
{
    next: 'Continue',
    previous: 'Back',
    finish: 'Finish'
}

 */

    @track isLast = false;
    @track isFirst = false;

    get shouldHidePreviousButton() {
        return this.isFirst || this.hidePreviousButton? true:false;
    }

    get nextLabel() {
        if(this.showLoader) {
            return '';
        }
        return this.isLast? this.labels.finish:this.labels.next;
    }

    // #endregion

    // #region LWC Lifecycle Hooks

    connectedCallback() {

        this.dispatchEvent(new CustomEvent('stepregistered', {
            bubbles: true,
            detail: {
                pageId: this.pageId,
                name: this.name,
                label: this.label,
                showSections: !this.hideSections,
                methods: {
                    setActive: this.setActive.bind(this),
                    config: this.config.bind(this),
                    beforeChange: typeof this.beforeChange === 'function'? this.beforeChange.bind(this):null
                }
            }
        }));
    }

    disconnectedCallback() {
        if(typeof this.unregister === 'function') {
            this.unregister(this.name);
        }
    }

    // #endregion

    // #region Private API

    setActive(isActive) {
        this.isActive = isActive;
    }

    config(props) {

        this.isFirst = props.isFirst;
        this.isLast = props.isLast;


        if(!this.isInit) {
            // VC - added to avoid having to hardcode step names in the html
            this.name = props.stepName;
            this.labels = props.labels;

            if(this.nextButtonLabel)
            {
                this.labels.next = this.nextButtonLabel;
            }
            if(this.previousButtonLabel)
            {
                this.labels.previous = this.previousButtonLabel;
            }

            this.move = props.callbacks.move;
            this.jump = props.callbacks.jump;
            this.unregister = props.callbacks.unregister;
            this.isInit = true;
        }
    }

    nextStep() {
        if(typeof this.move === 'function') {
            this.move('next');
        }
    }

    previousStep() {
        if(typeof this.move === 'function') {
            this.move('previous');
        }
    }

    move = null;
    unregister = null;
    jump = null;

    // #endregion

    updateNavFromStep(event) {

        if (typeof event.detail.nextButton !== "undefined") //if,  added by Jansi
            this.hideNextButton = !event.detail.nextButton;

        if (typeof event.detail.backButton !== "undefined")  //if, added by Jansi
            this.hidePreviousButton = !event.detail.backButton;

        if (typeof event.detail.printButton !== "undefined")                           //added by Jansi
            this.hidePrintButton = !event.detail.printButton;
    }

    jumpFromStep(event)
    {
        this.jump(event.detail.pageId);
    }

    // new event to trigger the next step from within the page
    nextFromStep(event)
    {
        this.move('next');
    }

    get nextBtnClass(){
        let cls = 'slds-button slds-button_brand hide-print';
        
        if(this.showLoader){
            return cls + ' loading-true';
        }

        return cls;
    }

    containsComponent(cmp)
    {

    }

    printScreen(event){
        window.print();
    }

    get hidePrintDivClass(){
        return 'slds-p-vertical_large ' + this.hideCss;
    }

}