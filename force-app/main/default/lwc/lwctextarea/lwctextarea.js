import { LightningElement, api } from 'lwc';

export default class lwctextarea extends LightningElement {
    @api name;
    @api disabled;
    @api placeholder;
    @api rows;
    @api fieldlabel;
    @api required;
    @api mxlength;

    handleChange(event) {
        const selectedEvent = new CustomEvent('changeinput', {
            detail : event.target.value
        });
        this.dispatchEvent(selectedEvent);
    }
}