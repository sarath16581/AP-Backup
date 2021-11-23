/** 
--------------------------------------- History --------------------------------------------------
28.08.2019    Swati.mogadala@AusPost.com.au     Added @api selectyouroutlet to be used in all smart forms as helptext
**/

import { LightningElement, api } from 'lwc';
import { ensureArray, debounce } from 'c/utils';

const DEBOUNCE_WAIT = 150;
export default class LwcForm extends LightningElement {

    // part of the form state that stores the values of all the child input elements in the form keyed by the element's or input's name
    @api values = {}

    // part of the form state that stores the information about which of the children elements in the form were touched by the user, keyed by the element's or input's name.
    @api touched = {}

    // part of the form state that stores the information about which of the children elements in the form are visible at any time, keyed by the element's or input's name
    @api visibilities = {}

    // part of the form state that houses the render configurations of the form elements, keyed by the element's name
    @api renderConfigs = {}

    /*  Part of the form state that houses the dependacy graph that represents the rendering relationship of the form elements.
        The graph is expected to be non cyclic, for it doesn't make sense for the value of child element to control the visibility 
        of it's own parent or grandparent.
        
        The graph could look something like 

        grandparent___________                  grandparent 2
           |                  |                       |                  
        parent____         parent 2                parent 3___
          |       |           |                    |          |
        child   child 2    child 3               child 4    child 5 

        where the value of the 'grandparent' component detemines whether the 'parent' and 'parent 2' are visible and the values of 
        those determine which of the children are visble. The 'formElementGraph' property is a adjacency list and graph above would 
        be repreented as in this data structure as follows.

        {
            grandparent: ['parent', 'parent 2'],
            grandparent 2: ['parent 3'],
            parent: ['child', 'child 2'],
            parent 2: 'child 3',
            parent 3: ['child 4', 'child 5'],
        }

        The reason we store this relationship in a graph is because it quite intuitively lends itself to be represented as multiple 
        trees (this should be obvious from the picture above)and trees are just non cyclic graphs. There is also a performance benefit 
        to representing the renedering logic in a graph because graphs can be searched effeciently in O(n), linear time complexity.
        
        When the value of a component changes we only need to traverse down that component's subtree to determine which of its children 
        have undergone changes in visibility. We don't need to compute the visibility of all elements of the form. Thus, by representing 
        the elements as a graph, we perform a 'breadth first search' starting from the element whose value changed and traverse down the 
        tree (graph) to compute the visibility state of each of its children (and grandchildren). 
        
        We perfrom a breadth first search (as opposed to a depth first search) because we want to compute the visibiliies in the 
        order of grandparent -> parent -> child. This is because the form state is retained even when an element and its children are
        hidden so that when an element that was previsouly hidden becomes visible again, it 's retained value can be used to determine 
        the visibility of it's children. In other words, breadth first search is analogus to tree traversal where we traverse each level 
        first before moving onto the nex deepest level.                     
    */ 
    @api formElementGraph = {} 
    @api selectYourOutlet = 'If your current outlet is not listed here, please request that the Postal Manager update your MyNetwork account'
    @api selectOutletDamages = 'If your facility is not listed here, please have a manager update your MyNetwork account'
   
    constructor() {  
        super();
        this.template.addEventListener('lwcformaction', this.handleFormChange.bind(this));
    }

    // exposed method that returns the values of all the visible fields in the form 
    @api
    getVisibleData = () => {
        const { visibilities, values, renderConfigs } = this;
        return Object.keys(values).reduce((acc, key) => {
            if (!(renderConfigs[key] && !visibilities[key])) {
                return Object.assign(acc, { [key]: values[key] });
            }
            return acc;
        }, {})
    }

    /*  exposed method that returns true of all the visible fields in the form are valid

        For this validation method to be used the component needs to be decorated with the class 'form-input'.
        If it is a custom input component, it needs to implement the reportVailidity() and checkValidity() 
        methods which should work in a manner similar to the lightning-input components as specified in 
        https://developer.salesforce.com/docs/component-library/bundle/lightning-input/specification
    */
    @api
    validateInputs = () => {
        const inputComponents = this.template.querySelectorAll(".form-input");
        const inputsArray = inputComponents ? [...inputComponents] : [];
        return inputsArray.reduce((acc, inputCmp) => {
            inputCmp.reportValidity();
            return acc && inputCmp.checkValidity();
        }, true)
    }

    // exposed method that lets a parent or external lwc component to set values in the form
    @api
    handleValueChange = (event) => {
        const target = event.target;
        const value = target.type === "checkbox" ? target.checked : target.value;
        const name = target.name;
        // we don't need immediate state updates, so a debounced computation is preferred to improve performance 
        this.debouncedUpdateStateValues({ [name]: value });
    }

    // exposed method that lets a parent or external lwc component to set touched state in the form
    @api
    handleTouched = (event) => {
        const name = event.target.name;
        this.updateStateTouched(name);
    }

    // expose a method for any parent component to call and update form state followed by a visibility computation
    @api
    updateValuesAndVisibilities = (newValues) => {
        this.updateStateValues(newValues)
        this.updateChildrenVisibilities(Object.keys(newValues))
    }

    // handler for 'lwcformaction' events
    handleFormChange(event) {
        const { type, payload } = event.detail;
        if (type === 'UPDATE_VALUE') {
            // on state updates dont need immediate computation of visibilities, so a debounced computation is preferred to improve performance
            this.debouncedUpdateValuesAndVisibilities(payload);
        } else if (type === 'REGISTER_ELEMENT') {
            const { renderConfig, name } = payload;
            this.updateState('renderConfigs')({ [name]: renderConfig })
        } else if (type === 'UPDATE_TOUCHED') {
            this.updateStateTouched(payload)
        }
    }

    /*  Upon render(fired after all the child components have rendered) we generate the dependancy graph.

        If the sub component (the form component that extends this class) wants its own rendered callback,
        it needs to call this renderedCallback method with super.renderedCallback(). 
    */
    renderedCallback() {
        this.formElementGraph = this.generateElementGraphFromRenderConfigs()
    }
    
    // generates the dependancy graph from the render configuration objects in state. 
    generateElementGraphFromRenderConfigs() {
        return Object.entries(this.renderConfigs).reduce((graph, [name, config]) => {
            const parentName = config && config.parentName
            if (parentName) {
                graph[parentName] = graph[parentName] ? [...graph[parentName], name] : [name]
            }
            return graph
        }, {})
    }

    // updates the visibility of a list of elements and their children but performing a breadth first search on the graph. Read the comments on the 'formElementGraph' property above for more information on the graph
    updateChildrenVisibilities(elemNames = []){
        const visibilities = {...this.visibilities }
        while(elemNames.length > 0) {
            const currentElemName = elemNames.pop()
            // needs the updated visibilities to determine component's visibility based on parent
            const visibility = this.computeElementVisibility(currentElemName, visibilities)
            visibilities[currentElemName] = visibility
            if (this.formElementGraph[currentElemName]) {
                elemNames = [...elemNames, ...this.formElementGraph[currentElemName]]
            }
        }
        this.visibilities = visibilities
    }

    /*  takes the name of an element and the visibility state and checks the parent's value and visibility 
        to determine if the element in question is currently visible or not. returns true if visible and 
        false otherwise
        */
    computeElementVisibility(name, visibilities) {
        let visible = true
        const renderConfig = this.renderConfigs[name]
        if (renderConfig) {
            visible = false;
            const { parentName, showFor, showIfExists } = renderConfig;
            const value = this.values[parentName]
            const parentVisible = visibilities[parentName]
            if (parentName) {
                // eslint-disable-next-line no-extra-boolean-cast
                if (!!parentVisible) {
                    if (showIfExists === true) {
                        visible = !!value;
                    } else if (showFor) {
                        const showForValues = ensureArray(showFor)
                        visible = showForValues.includes(value)
                    }
                }
            }
        }
        return visible
    }

    /*  Effecient state updates by debouncing the 'updateStateValues' function. The debounced function 
        is preferred since we don't need to update the values on each keystroke for text fields.
    */
    debouncedUpdateStateValues = debounce(values => {
        this.updateStateValues(values)
    }, DEBOUNCE_WAIT)

    /*  Effecient state updates and subsequent visibility updates by grouping and then debouncing 
        the 'updateStateValues' and 'updateChildrenVisibilities' functions. The debounced function 
        is preferred since we don't need to update the values on each keystroke for text fields.
    */
    debouncedUpdateValuesAndVisibilities = debounce(newValues => {
        this.updateStateValues(newValues)
        this.updateChildrenVisibilities(Object.keys(newValues))
    }, DEBOUNCE_WAIT)

    // wrappers around the update state function to update values (for readability)
    updateStateValues = newValues => {
        this.updateState('values')(newValues)
    }
    // wrappers around the update state function to update touced state (for readability)
    updateStateTouched(name) {
        this.updateState('touched')({[name]: true})
    }

    // function to update state 
    updateState = key => newState => {
        this[key] = { ...this[key], ...newState }
    }
}