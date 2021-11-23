({
	onInit : function(component, event, helper)
    {
		// DDS-5272: check next step configurations >> if no image URL present in any step >> set the left column to non display and right column to full width
		let options = component.get('v.options') || [];
		
		let haveImage = false;

		for (let step of options)
			if (!$A.util.isEmpty(step.image))
				haveImage = true;
		
		// SLDS design tokens
		const SPACE = ' ';
		const SLDS_COL = 'slds-col';
		const SLDS_SIZE_1_OF_12 = 'slds-size_1-of-12';
		const SLDS_SIZE_11_OF_12 = 'slds-size_11-of-12';
		const SLDS_SIZE_12_OF_12 = 'slds-size_12-of-12';
		const SLDS_HIDE = 'slds-hide';
		const SLDS_P_TOP_MEDIUM = 'slds-p-top_medium';
		
		// CSS style from SLDS design tokens
		const SMALL_COLUMN = [SLDS_COL, SLDS_SIZE_1_OF_12].join(SPACE);
		const BIG_COLUMN = [SLDS_COL, SLDS_SIZE_11_OF_12].join(SPACE);
		const NO_COLUMN = [SLDS_HIDE].join(SPACE);
		const FULL_WIDTH_COLUMN = [SLDS_COL, SLDS_SIZE_12_OF_12].join(SPACE);
		const FULL_WIDTH_COLUMN_WITH_TOP_PAD = [SLDS_COL, SLDS_SIZE_12_OF_12, SLDS_P_TOP_MEDIUM].join(SPACE);

		if (haveImage)
		{
			// apply CSS for having image
			component.set('v.LEFT_COLUMN_CSS', SMALL_COLUMN);
			component.set('v.RIGHT_COLUMN_LABEL_CSS', BIG_COLUMN);
			component.set('v.RIGHT_COLUMN_SUBLABEL_CSS', BIG_COLUMN);
		} else
		{
			// apply CSS for not having image
			component.set('v.LEFT_COLUMN_CSS', NO_COLUMN);
			component.set('v.RIGHT_COLUMN_LABEL_CSS', FULL_WIDTH_COLUMN_WITH_TOP_PAD);
			component.set('v.RIGHT_COLUMN_SUBLABEL_CSS', FULL_WIDTH_COLUMN);
		}
	}
})