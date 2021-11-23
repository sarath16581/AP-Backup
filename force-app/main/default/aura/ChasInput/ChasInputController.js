({
    updateValue : function(cmp, event, helper) {
        cmp.set('v.value', event.target.value);
        event.target.reportValidity();
    },

    /**
     * report the value of input element
     * use this method if the input value is inserted by DOM manipulating which do not trigger oninput event
     * @param {*} component 
     * @returns 
     */
    reportInputValue : function(component)
    {
        let inputName = component.get('v.name');
        let inputElement = document.getElementById(inputName);
        let inputValue;
        if (inputElement)
        {
            inputValue = inputElement.value;
        }
        
        return inputValue;
    }
})