/*
* @author Victor.Cheng@auspost.com.au
* @date 2021-02-05
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Modified wizard framework
* @changelog
* 2020-12-10 Victor.Cheng@auspost.com.au  Created
*
*/

import { LightningElement, api, track } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor'

export default class BcaWizard extends LightningElement {

    @api debugging = false;
    @api showSteps = false;
    @api showSections = false;
    @api clickableSections = false;
    @track totalSections;
    @track collapseSections = false;

    _showSectionsProgressBar = true;
    @api showSectionsProgressBar(show)    {
        this._showSectionsProgressBar= show;
    }
    get sectionsProgressBarVisible() {
        return this.showSections && this._showSectionsProgressBar;
    }
    // enable the progress bar navigation

    // index of the the furthest step
    @api furthestStep = 0;

    STEP_SELECTOR = 'c-bca-wizard-step';

    // to avoid an infinite loop bug that happens when a step is configured incorrectly
    LOOP_COUNTER = 0;

    // #region public API properties
    @api variant = 'base';
    @api previousLabel = 'Back';
    @api nextLabel = 'Continue';
    @api finishLabel = 'Finish';
    @api header = '';

    @track _currentStep = null;
    @api get currentStep() {
        return this._currentStep;
    }

    get currentSection() {
        for(let i = 0; i < this.sections.length; ++i)
        {
            let section = this.sections[i];
            if(section.isActive)
            {
                return section;
            }
        }
        return {};
    }

    get currentSectionIndex() {
        for(let i = 0; i < this.sections.length; ++i)
        {
            let section = this.sections[i];
            if(section.isActive)
            {
                return i + 1;
            }
        }
        return 0;
    }

    get showSectionsIcon() {
        if(this.collapseSections)
        {

            return "utility:chevronup";
        }
        return "utility:chevrondown";
    }

    get mystepperClass() {
        let stepperClass = "form-progress-inner";
        if(!this.collapseSections)
              stepperClass += ' show-on-desktop';
        return stepperClass;
    }
    
    toggleSections(event) {
        this.collapseSections = !this.collapseSections;
    }

    set currentStep(value) {
        this.setAttribute('current-step', value);
        this._currentStep = value;
        this.setActiveStep();
    }

    // #endregion

    // #region Tracked Properties

    @track steps = {};
    @track hasError = false;
    @track errorMessages = '';
    @track flow = [];
    @track sections = [];

    // #endregion

    // #region Non-tracked Properties

    isInit = false;
    progressIndicatorType = 'base';
    progressIndicatorVariant = 'base';

    //#endregion

    // #region LWC Licecycle Callbacks

    connectedCallback() {
        this.init();
    }

    get isMobile()
    {
        if(FORM_FACTOR != 'Large')
            return true;
        return false;
    }

    errorCallback(error, stack) {
        this.hasError = true;
        this.errorMessages = error + ' ' + stack;
    }

    // #endregion

    // #region Event Handlers

    /**
     * Handles changes on the slot body, which allows to configure the internal component stated base
     * on the c-wizard-step children.
     */
    slotChange() {
        if(this.LOOP_COUNTER > 3)
            return;
        this.LOOP_COUNTER++;

        this.configSteps();
        this.setActiveStep();
    }

    /**
     * Register a wizard step defined in component template
     *
     * @param {CustomEvent} event
     * @param {Object} event.detail
     * @param {*} event.detail.for Defines a list of steps on which this action will be available
     * @param {Object} event.detail.methods WizardAction Private API
     * @param {Fuction} event.detail.methods.setActive Marks the step as current
     */
    registerStep(event) {
        var step = event.detail;

        let iStep = Object.keys(this.steps).length;
        let autoName = 'STEP-' + iStep;
        //automatically name the step by index
        step.name = autoName;

        step.methods.config({
            stepName: autoName,
            labels: {
                next: this.nextLabel,
                previous: this.previousLabel,
                finish: this.finishLabel
            },
            callbacks: {
                unregister: this.unregisterStep.bind(this),
                move: this.moveStep.bind(this),
                jump: this.jumpStep.bind(this)
            }
        });
        this.steps[autoName] = step;
    }
    // #endregion

    // #region Private Methods

    /**
     * Initializes the component, applying the global style.
     */
    init() {
        if (this.isInit) {
            return;
        }

        this.isInit = true;

        switch (this.variant) {
            case 'base-shaded':
                this.progressIndicatorVariant = 'shaded';
                this.progressIndicatorType = 'base';
                break;
            case 'path':
                this.progressIndicatorVariant = 'base';
                this.progressIndicatorType = 'path';
                break;
            default:
                this.progressIndicatorVariant = 'base';
                this.progressIndicatorType = 'base';
        }
    }

    /**
     * Unregister a wizard step defined in component template
     *
     * @param {String} Step name
     */
    unregisterStep(stepName) {
        delete this.steps[stepName];
    }

    /**
     * Sets the wizard current step
     *
     * @param {String} stepName Current Step name
     */
    setActiveStep(stepName) {
        let self = this;
        window.scrollTo(0, 0);

        if (stepName) {
            self.dispatchEvent(new CustomEvent('change', {
                detail: {
                    oldStep: self._currentStep,
                    currentStep: stepName
                }
            }));

            self._currentStep = stepName;

            // set the water level
            self.furthestStep = Math.max(self.furthestStep, self.stepIndexByName(stepName));

            let isPassed = true;
            for(let i = 0; i < this.sections.length;++i)
            {
                let section = this.sections[i];
                section.isActive = false;
                if(section.stepNames.indexOf(stepName) >= 0)
                {
                    section.isActive = true;
                    isPassed = false;
                }

                section.isPassed = isPassed;
            }
        }

        self.showSections = true;
        Object.values(self.steps).forEach(function (step) {
            step.methods.setActive(step.name === self._currentStep);

            if(step.name == self._currentStep)
            {
                self.showSections = step.showSections;
            }
        });

    }

    /**
     * Determines the wizard flow based on component body slot
     */
    configSteps() {
        let stepComponents = this.querySelectorAll(this.STEP_SELECTOR);
        self = this;

        this.flow = Array.prototype.map.call(stepComponents, (step, index) => {
            self.steps[step.name].methods.config({
                isFirst: index === 0,
                isLast: index === (stepComponents.length - 1)
            })
            self.steps[step.name].skipped = false;
            return self.steps[step.name];
        });

        if (!this.currentStep && this.flow) {
            this.currentStep = this.flow[0].name;
        }

        // sections - create a map of section name:[step name]
        this.sections = [];
        if(stepComponents.length > 1)
        {
            // first section name
            let currSection = {
                name:stepComponents[0].section,
                stepNames:[],
                isActive:true,
                isPassed:false
            };
            this.sections.push(currSection);

            for(let i = 0; i < stepComponents.length; ++i)
            {
                let stepSection = stepComponents[i].section;
                if(currSection.name != stepSection)
                {
                    // advance if a step isn't in the current section
                    currSection = {
                        name:stepSection,
                        stepNames: [],
                        isActive:false,
                        isPassed:false
                    };
                    this.sections.push(currSection);
                }
                currSection.stepNames.push(stepComponents[i].name);
            }
            this.totalSections = this.sections.length;
        }

    }

    /**
     * Moves to the next step, if available, and executes the customer-defined beforeChange hook of the current step.
     * If the beforeChange promise is resolve with a falsy value, the wizard stops at current step.
     * If the wizard is in its final step, dispatch the complete event.
     *
     * @param {String} direction Direction to move to. Valid values are next/previous
     */
    async moveStep(direction) {
        let currentStep = this.steps[this._currentStep];
        let currentStepIndex = this.flow.indexOf(currentStep);

        if (direction === 'next') {
            this.hasError = !(await this.beforeChange(this.steps[this._currentStep]));

            if (!this.hasError) {
                let newStep = this.flow[currentStepIndex + 1];

                while(newStep.skipped == true && currentStepIndex < this.flow.length)
                {
                    currentStepIndex++;
                    newStep = this.flow[currentStepIndex + 1];
                }

                if (newStep) {
                    this.setActiveStep(newStep.name);
                } else {
                    this.dispatchEvent(new CustomEvent('complete'));
                }
            }
        } else {
            let newStep = this.flow[currentStepIndex - 1];

            while(newStep.skipped == true && currentStepIndex > 0)
            {
                currentStepIndex--;
                newStep = this.flow[currentStepIndex - 1];
            }

            if (newStep) {
                this.setActiveStep(newStep.name);
            }
        }
    }

    /**
     * Used for jumping to steps by index
     * @param {String} pageId from constants
     * @returns {Promise<void>}
     */
    async jumpStep(pageId) {
        let self = this;
        this.flow.forEach(stepFlow => {
            if(stepFlow.pageId == pageId){
                self.setActiveStep(stepFlow.name);
            }
        });
    }

    stepIndexByName(stepName)
    {
        return this.flow.findIndex(function (step, index){
            if(step.name == stepName)
                return true;
        })
    }

    clickSection(event) {
        if(false == this.clickableSections){
            // disabled
            return;
        }

        // get the section
        let sectionIndex = event.currentTarget.dataset.id;
        let section = this.sections[sectionIndex];

        // first step of the section
        let stepName = section.stepNames[0];

        // get the index of this step from the flow
        let stepIndex = this.stepIndexByName(stepName);

        // check if we're allowed to jump there
        if(this.debugging || stepIndex <= this.furthestStep){
            this.jumpStep(stepIndex);
        }
    }

    /**
     *
     * @param pageIds {Array}
     */
    @api skipPageIds(pageIds){
        this.flow.forEach(stepFlow => {
            stepFlow.skipped = false;
            if(pageIds.indexOf(stepFlow.pageId) >= 0){
                stepFlow.skipped = true;
            }
        })
    }

    /**
     * Execute flows the customer-defined beforeChange hook, fired whenever the wizard goes to the next step.
     * The hook is not invoked when a step change is a consequence of external causes
     *
     * @param {Object} step Step public definition, as defined on registerStep method
     * @returns {Promise(Boolean}) If the promise is resolve with a falsy value, the wizards stops at the current step, showing an error on the steo definition
     */
    beforeChange(step) {
        return new Promise((resolve) => {
            if (!step.methods.beforeChange) {
                return resolve(true);
            }

            return resolve(step.methods.beforeChange());
        });
    }

    // #endregion
}