/**
 * @description Provides a label/value output based on the format that was passed in
 * @author Nathan Franklin
 * @date 2020-04-01
 * @changelog
 * 2021-10-15 - Nathan Franklin - Added icon rendering
 */
import {LightningElement, api} from 'lwc';

const FIELD_TYPES = {
	Boolean: 'BOOLEAN',
	Currency: 'CURRENCY',
	Date: 'DATE',
	DateTime: 'DATETIME',
	Double: 'DOUBLE',
	Integer: 'INTEGER',
	Long: 'LONG',
	Percent: 'PERCENT',
	Time: 'TIME',
	Url: 'URL',

	//CUSTOM
	Icon: 'ICON'
};

export default class FormattedTextLabel extends LightningElement {

	@api label = '';
	@api value = '';
	@api type = '';
	@api scale = 2;
	@api url = '';
	@api urlTarget = '';
	@api helpText = '';
	@api iconName = 'utility:check';
	@api iconVariant = 'success';
	@api iconSize = 'x-small';

	get isText() {
		return (!this.isUrl && !this.isNumber && !this.isCurrency && !this.isPercentage && !this.isDate && !this.isDateTime && !this.isTime && !this.isBoolean);
	}
	get isDate() {
		return this.type === FIELD_TYPES.Date;
	}
	get isTime() {
		return this.type === FIELD_TYPES.Time;
	}
	get isDateTime() {
		return this.type === FIELD_TYPES.DateTime;
	}
	get isBoolean() {
		return this.type === FIELD_TYPES.Boolean;
	}
	get isPercentage() {
		return this.type === FIELD_TYPES.Percentage;
	}
	get isCurrency() {
		return this.type === FIELD_TYPES.Currency;
	}
	get isUrl() {
		return this.type === FIELD_TYPES.Url;
	}
	get isIcon() {
		return this.type === FIELD_TYPES.Icon;
	}
	get isNumber() {
		return [FIELD_TYPES.Double, FIELD_TYPES.Integer, FIELD_TYPES.Long].includes(this.type);
	}

	get isValidDateTime() {
		return this.value && !isNaN((new Date(this.value)).getTime());
	}
	get isValidDate() {
		return this.value && !isNaN((new Date(this.value)).getTime());
	}
	get isValidTime() {
		return this.value && !isNaN((new Date(this.value)).getTime());
	}
	get ishelpTextRequired() {
		return !!this.helpText;
	}

}