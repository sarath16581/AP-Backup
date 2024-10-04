import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class UiModal extends LightningModal {
	@api label;
	@api header;
	@api body;
	@api buttons;

	get _buttons() {
		return (
			this.buttons || [
				{ label: 'Cancel', name: 'btnCancel' },
				{ label: 'Proceed', name: 'btnSubmit', variant: 'brand' }
			]
		);
	}

	handleClick(event) {
		const { name } = event.target;

		this.close({
			success: true,
			action: name
		});
	}
}