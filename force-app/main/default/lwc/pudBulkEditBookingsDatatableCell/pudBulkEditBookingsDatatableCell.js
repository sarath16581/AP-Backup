/**
 * @description Represents a single cell (field) in bookings data table in PUD Bulk Edit user interface. Supports
 *              display and inline editing for the bookings field value received from the parent component.
 *              Inline edits are published back to the parent as custom events.
 * @author Ranjeewa Silva
 * @date 2022-03-11
 * @changelog
 * 2022-03-11 - Ranjeewa Silva - Created
 * 2022-09-14 - Dattaraj Deshmukh - Added 'isEditable()' method to check for optional cellAttributes. 
 *              Updated 'handleValueChange()' to handle checkbox 'checked' property.
 */
import { LightningElement, api } from 'lwc';
import { CONSTANTS } from 'c/pudBulkEditBookingsService';

export default class PudBulkEditBookingsDatatableCell extends LightningElement {

	// id of the booking
	@api bookingId;

	// field label
    @api label;

	// field name
    @api name;

	// field type. please see CONSTANTS.FIELD_TYPES for the supported field types.
    @api type;

	// if true, supports inline editing.
    @api editable;

    // provides additional customization, such as displaying colour coded 'dot' next to the cell value.
    @api cellAttributes;

    // provides additional formatting for the data type. For example, minimum and maximum values for input
    @api typeAttributes;

	// field value supplied from the parent
    _source;

	// field value converted to a form suitable for display and editing. e.g. time fields are converted to a ISO8601 string
	// supported by Salesforce base lightning components.
    _value;

	// component renders in edit mode when inline editing
    editMode = false;

	// current field value has been edited and considered dirty.
    isDirty = false;

    @api
    get value() { return this._source; }
    set value(v) {
        this._source = v;
        if (this.type === CONSTANTS.FIELD_TYPES.TIME && !!v) {
            const dateTimeISOString = new Date(v).toISOString();
            if (dateTimeISOString.indexOf('T') != -1) {
                this._value = dateTimeISOString.split('T')[1].replace('Z', '');
            }
        } else {
            this._value = (!!v ? v : null);
        }
    }

	/**
	 * handle enable inline edit event - rendering the component in edit mode.
	 */
    handleEdit(event) {
        this.editMode = true;
        // set the focus on to the input element
        setTimeout(()=>this.template.querySelector('.booking-input').focus());
    }

	/**
	 * handle value change event.
	 */
    handleValueChange(event) {
        //special handing for getting checkbox value
        this._value = (this.type === CONSTANTS.FIELD_TYPES.CHECKBOX ?  event.target.checked : event.detail.value);
        
        // value has changed - mark the component as dirty
        this.isDirty = true;

        //calling handleEditCompleted() method explicitly to take checkbox out of focus upon select/unselect.
        //This avoids the need to click outside of checkbox area to close checkbox edit element.
        if(this.type === CONSTANTS.FIELD_TYPES.CHECKBOX){
            this.handleEditCompleted(event);
        }
    }

	/**
	 * handle the edit completed event. occurs when the input component looses focus
	 */
    handleEditCompleted(event) {
        if (!this.isDirty) {
            // value has not been updated - nothing to do. just render the component in view mode.
            this.editMode = false;
        } else if (this.checkValidity()) {
            // value has been updated and the new value is considered valid for this field.
            // publish the new value to parent and render the component in view mode.
            this.editMode = false;
            // special handling for time fields to convert to epoch time
            const draftValue = (this.type === CONSTANTS.FIELD_TYPES.TIME ? Date.parse('1970-01-01T'+this._value+'Z') : this._value);

            this.dispatchEvent(new CustomEvent('valuechange', { detail: { id: this.bookingId, draftValue: draftValue, fieldName: this.name }} ));
        }
    }

	/**
	 * returns true if this field is a TEXTAREA field
	 */
    get isTextArea() {
        return this.type === CONSTANTS.FIELD_TYPES.TEXTAREA;
    }


    /**
	 * returns true if this field is a CHECKBOX field
	 */
     get isCheckbox() {
        return this.type === CONSTANTS.FIELD_TYPES.CHECKBOX;
    }

    /**
	 * returns true if this field is other than checkbox and textarea
	 */
     get isGeneric() {
        return this.type !== CONSTANTS.FIELD_TYPES.CHECKBOX && this.type !== CONSTANTS.FIELD_TYPES.TEXTAREA;
    }
    

	/**
	 * maps the field type to a supported 'lightning-input' type
	 */
    get inputType() {
        return (this.type === CONSTANTS.FIELD_TYPES.INTEGER ? 'number' : this.type);
    }

	/**
	 * returns the type attributes for the field. returns a blank object when type attributes are not specified.
	 */
    get inputTypeAttributes() {
        return (this.typeAttributes ? this.typeAttributes : {});
    }

    get readOnlyCssClass() {
        let styleClass = 'slds-truncate' + (this.isTextArea ? ' slds-line-clamp_x-small' : '');
        styleClass += ((this.cellAttributes && this.cellAttributes.styleClass) ? (' ' + this.cellAttributes.styleClass) : '');
        return styleClass;
    }

    get isEditable() {
        //if cellAttributes has editable set then use cellAttributes.editable. Else, use editable property set on columns.
        //return (this.cellAttributes && this.cellAttributes.editable) ? this.cellAttributes.editable : this.editable; 
        
        return (!this.editable ? false : ( (this.cellAttributes && this.cellAttributes.hasOwnProperty('editable')) ? this.cellAttributes.editable : this.editable ));
        
    }

	/**
	 * check validity of the supplied value.
	 */
    checkValidity() {
        const inputCmp = this.template.querySelector(".booking-input");
        inputCmp.reportValidity();
        return inputCmp.checkValidity();
    }
}