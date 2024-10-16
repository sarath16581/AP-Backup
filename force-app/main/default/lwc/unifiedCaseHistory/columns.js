export default [
	{
		label: 'Case Number',
		fieldName: 'caseUrl',
		type: 'url',
		typeAttributes: {
			label: { fieldName: 'caseNumber', target: '_blank' }
		},
		wrapText: true
	},
	{
		label: 'Status',
		fieldName: 'status',
		type: 'text',
		wrapText: true
	},
	{
		label: 'Subject',
		fieldName: 'subject',
		type: 'text',
		wrapText: true
	},
	{
		label: 'Type',
		fieldName: 'type',
		type: 'text',
		wrapText: true
	},
	{
		label: 'Reference ID',
		fieldName: 'referenceId',
		type: 'text',
		wrapText: true
	},
	{
		label: 'Last Updated',
		fieldName: 'lastModifiedDate',
		type: 'date',
		wrapText: true,
		typeAttributes: {
			month: '2-digit',
			day: '2-digit',
			year: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		}
	},
	{
		fixedWidth: 100,
		label: 'Link',
		type: 'button',
		typeAttributes: {
			iconName: 'action:new_case',
			label: 'Link',
			name: 'linkCase',
			title: 'Link Case',
			disabled: { fieldName: 'disableLinkButton' }
		}
	}
];
