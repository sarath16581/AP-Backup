/**
  * @author       : Sameed Khan<sameed.khan@mav3rik.com>
  * @date         : 01/05/2019
  * @description  : Form component that provides conditional rendering behaviour
--------------------------------------- History --------------------------------------------------
01.04.2019    Sameed Khan(Mav3rik)    Created
**/
import { LightningElement, api } from 'lwc';

export default class LwcFormElement extends LightningElement {

    // name (ideally unique) of the form elememt which will be used as a key in the form's state 
    @api name

    /*  Takes in the part of state from the parent component that houses the flags 
        that determine whether the element should be visible. 
        */
    @api visibilityState

    /*  Accepts an optional cofiguration object that houses information about when 
        to render the particular form element. The config is an object of the 
        following properties:

        parentName - name of the parent element whose value decides whether this element be displayed
        showFor - the value or list of values that the parent can have for this element to be visible
        showIfExists - a flag which if set to true will ensure that the form element is visible if the parent is populated 

        NOTE: Generally, you want to have either 'showFor' or 'showIfExists' populated. If both are populated, 
        the behaviour defined by 'showFor' will take precedence.
        */
    @api renderConfig

    /*  Flag to indicate whether the form state should keep track of whether the element was touched 
        by the user. If set to true the component fires an update on the html 'focusout' event to 
        inform the form state that this element was touced.
        */
    @api trackTouch = false

    constructor() {
        super();
        this.template.addEventListener('change', this.handleValueChange.bind(this));
        this.template.addEventListener('focusout', this.handleTouch.bind(this));
    }

    get visible() {
        const isHidden = !this.visibilityState[this.name]; 
        const hasParent = !!(this.renderConfig && this.renderConfig.parentName)
        // if the component doesnt have a parent(or a render config) it's always visible. otherwise we look at the visibility state to determine whether it should render
        return hasParent ? !isHidden : true; 
    }

    /*  When the component is attached to the dom (this is after the parent has been atttached), we want
        to register the element which is basically a way to let the form know that this element is one
        that has conditional rendering behaviour (that it is either a parent or child) and its renderConfig
        should be added to the form's state.
        */
    connectedCallback() {
        const { renderConfig, name } = this;
        this.registerFormElement({ renderConfig, name });
    }

    // event handler for change in input value
    handleValueChange(event) {
        const target = event.target;
        const value = target.type === "checkbox" ? target.checked : target.value; // for checkbox inputs, the value is contained in the 'checked' property 
        const name = this.name;
        this.updateStateValues({ [name]: value });
    }

    // event handler for when an input component is 'touched'
    handleTouch() {
        if (this.trackTouch) {
            this.updateTouched(this.name)
        }
    }

    /*  Actions that fire the 'lwcformaction' event but with different types.
        these three functions wrap around the 'fireFormChangeEvent' function
        for ease of readability
    */
    registerFormElement(payload) {
        this.fireFormChangeEvent({
            type: 'REGISTER_ELEMENT',
            payload,
        });
    }

    updateStateValues(payload) {
        this.fireFormChangeEvent({
            type: 'UPDATE_VALUE',
            payload,
        })
    }

    updateTouched(payload) {
        this.fireFormChangeEvent({
            type: 'UPDATE_TOUCHED',
            payload,
        })
    }

    // fires event 'lwcformaction' to let the form know that there needs to be a change in the form's state
    fireFormChangeEvent(action) {
        const lwcFormAction = new CustomEvent('lwcformaction', { detail: action, bubbles: true });
        this.dispatchEvent(lwcFormAction);
    }
}