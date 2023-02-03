/**
 * @author Nathan Franklin
 * @date 2023-02-01
 * @description Custom built report for handling a breakdown of pending cases to be assigned via skills
 * @changelog
 */
import {LightningElement, api} from 'lwc';
import fetchReportData from '@salesforce/apex/OmniSkillsReportController.fetchReportData';
import fetchReportDataWithoutSkill from '@salesforce/apex/OmniSkillsReportController.fetchReportDataWithoutSkill';
import fetchReportDataIteration from '@salesforce/apex/OmniSkillsReportController.fetchReportDataIteration';
import getCases from '@salesforce/apex/OmniSkillsReportController.getCases';

export default class OmniSkillsReport extends LightningElement {

	@api renderHeader = false;

	loaded = false;
	waiting = true;

	buckets = ['0-5 Days',
				'5-10 Days',
				'10-15 Days',
				'15-20 Days',
				'20-25 Days',
				'25-30 Days',
				'30+'];

	sortField = '';

	sortDirection = 'asc';

	columns = [
		{ label: 'Case Number', fieldName: 'CaseNumber', sortable: true },
		{ label: 'Type', fieldName: 'Type', sortable: true },
		{ label: 'Product Category', fieldName: 'ProductCategory__c', sortable: true },
		{ label: 'Product Subcategory', fieldName: 'ProductSubCategory__c', sortable: true },
		{ label: 'Enquiry Subtype', fieldName: 'EnquirySubType__c', sortable: true },
		{
			label: 'Created Date',
			fieldName: 'CreatedDate',
			type: 'date',
			sortable: true,
			typeAttributes:{
				year: "numeric",
				month: "long",
				day: "2-digit",
				hour: "2-digit",
				minute: "2-digit"
			}
		},
	];

	parsedSkillMappings = {};

	drilldownCases = [];

	reportData = {};
	filteredReportData = {};

	selectedFilters = [];

	connectedCallback() {
		this.fetch();
	}

	/**
	 * This will iteratively retrieve a list of all the pending cases waiting for assignment to an agent
	 * We retrieve this data based on the skills assigned to each work item (Case only here)
	 * We then group and parse all the data here. This type of thing would not be possible on the server
	 *  given we may need to fetch records across multiple transactions
	 */
	async fetch() {
		let jobOutput = await fetchReportDataWithoutSkill();
		const jobKey = jobOutput.jobKey;
		let isDone = jobOutput.isDone;

		let records = [];
		while(!isDone) {
			console.log('iterating!');

			jobOutput = await fetchReportDataIteration({existingJobKey: jobKey});
			isDone = jobOutput.isDone;
			records = [...records, ...jobOutput.records];
		}

		this.parseRecords(records);

		this.waiting = false;
		this.loaded = true;
	}

	/**
	 * Iterate over all the retrieved data and consolidate it into case/skill and date bucket
	 */
	parseRecords(records) {
		const parsedSkillMappings = {};

		const now = Date.now();
		const count1Day = (1000*60*60*24);
		const buckets = {
			'0-5 Days': [now, now-(count1Day*5)],
			'5-10 Days': [now-(count1Day*5), now-(count1Day*10)],
			'10-15 Days': [now-(count1Day*10), now-(count1Day*15)],
			'15-20 Days': [now-(count1Day*15), now-(count1Day*20)],
			'20-25 Days': [now-(count1Day*20), now-(count1Day*25)],
			'25-30 Days': [now-(count1Day*25), now-(count1Day*30)],
			'30+': [now-(count1Day*30), now-(count1Day*1000)],
		}
		const caseSkillList = {};

		// we need to group cases together to prevent duplication of report data on the screen
		// additional we need to grab the case creation date so we can bucet the data into a report
		for(const record of records) {
			caseSkillList[record.RelatedRecord.WorkItemId] = caseSkillList[record.RelatedRecord.WorkItemId] ?? {};
			caseSkillList[record.RelatedRecord.WorkItemId]['skills'] = caseSkillList[record.RelatedRecord.WorkItemId]['skills'] ?? {};
			caseSkillList[record.RelatedRecord.WorkItemId]['skills'][record.SkillId] = true;
			caseSkillList[record.RelatedRecord.WorkItemId]['createdDate'] = record.RelatedRecord.WorkItem.CreatedDate;

			// grab the developer names for each of the skils
			parsedSkillMappings[record.SkillId] = record.Skill.DeveloperName;
		}

		const reportData = {};
		for(const [workItemId, record] of Object.entries(caseSkillList)) {
			const createdDate = Date.parse(record.createdDate);
			const skills = Object.keys(record.skills);

			// make sure all the data is combined by skill properly by sorting the data first
			skills.sort();

			// grab a list of the skills by developer name
			const combinedSkills = skills.map((skillId) => { return parsedSkillMappings[skillId]});
			const combinedSkillsKey = combinedSkills.join(',');

			reportData[combinedSkillsKey] = reportData[combinedSkillsKey] ?? {buckets: {}, skills: combinedSkills, key: combinedSkillsKey, total: 0};

			// populate bucket names since we can't use computed values in templates
			for(const bucketName of this.buckets) {
				reportData[combinedSkillsKey].buckets[bucketName] = reportData[combinedSkillsKey].buckets[bucketName] ?? {key: bucketName, count: 0, countGreaterThan0: false, ids: []};
			}

			for(const [bucketName, dateThresholds] of Object.entries(buckets)) {
				if(createdDate <= dateThresholds[0] && createdDate > dateThresholds[1]) {
					reportData[combinedSkillsKey].buckets[bucketName].count++;
					reportData[combinedSkillsKey].buckets[bucketName].countGreaterThan0 = true;
					reportData[combinedSkillsKey].buckets[bucketName].ids.push(workItemId);
					reportData[combinedSkillsKey].total++;
				}
			}
		}

		this.parsedSkillMappings = parsedSkillMappings;
		this.reportData = reportData;
		this.filteredReportData = reportData;
	}

	get reportDataAsArray() {
		// {... is a shallow copy}, we need a deep copy or else it will mutate the original reportData variable
		const output = JSON.parse(JSON.stringify(this.filteredReportData));

		// convert buckets to an array now we have finished populating it
		for(const combinedSkillsKey of Object.keys(output)) {
			output[combinedSkillsKey].buckets = Object.values(output[combinedSkillsKey].buckets);
		}

		return Object.values(output);
	}

	get bucketColumns() {
		return this.buckets.map(item => { return {bucket: item, isSortField: this.sortField === item}; });
	}

	/**
	 * User has clicked the bucket column to sort that particular bucket
	 */
	handleBucketSort(e) {
		const bucket = e.currentTarget.dataset.bucket;
		if(this.sortField === bucket) {
			this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
		} else {
			this.sortField = bucket;
			this.sortDirection = 'asc';
		}

		this.sortFilteredData();
	}

	/**
	 * User click the Total column to sort by totals
	 */
	handleTotalSort(e) {
		if(this.sortField === 'total') {
			this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
		} else {
			this.sortField = 'total';
			this.sortDirection = 'asc';
		}

		this.sortFilteredData();
	}

	/**
	 * User has clicked on the numbers in a row in a bucket column to drill down to see all the cases
	 */
	async handleDrilldown(e) {
		this.waiting = true;

		const group = e.currentTarget.dataset.skillkey;
		const bucket = e.currentTarget.dataset.bucket;

		const caseIds = this.reportData[group].buckets[bucket].ids;
		this.queryCases(caseIds);

		return false;
	}

	async queryCases(caseIds) {
		this.drilldownCases = await getCases({caseIds})
		this.waiting = false;
	}

	/**
	 * Multiselect filters have changed
	 * From here, we refilter the dataset initially retrieved
	 * NOTE: This happens on blur of the picklist
	 */
	handleSelectOptionList(e) {
		this.selectedFilters = e.detail;
		this.filterReportData();
	}

	get hasDrilldownCases() {
		return this.drilldownCases.length > 0;
	}

	get skillMappingsForPicklist() {
		return Object.values(this.parsedSkillMappings).map(item => {
			return {label: item, value: item};
		});
	}

	get isSortAsc() {
		return this.sortDirection === 'asc';
	}

	get isSortDesc() {
		return this.sortDirection === 'desc';
	}

	get isSortFieldTotal() {
		return this.sortField === 'total';
	}

	/**
	 * Whenever the picklist filters change, we filter the data to only show whens relevant
	 */
	async filterReportData() {
		const regEx = (this.selectedFilters ?? []).map(item => new RegExp('\\b' + item + '\\b', 'i'));

		if(regEx.length === 0) {
			this.filteredReportData = this.reportData;
		} else {
			const filteredData = {};
			for(const [skillGroup, record] of Object.entries(this.reportData)) {
				let included = true;
				for(const r of regEx) {
					if(!r.test(skillGroup)) {
						included = false;
						break;
					}
				}
				if(included) {
					filteredData[skillGroup] = record;
				}
			}

			// trigger rerender with the new data set
			this.filteredReportData = filteredData;

			// reset the case list
			this.drilldownCases = [];
		}

		// reset the sort data based on what was previously used
		if(this.sortField) {
			this.sortFilteredData();
		}
	}

	/**
	 * Sort the data based ont he sortfield and sortdirection
	 * The sorting for the main summary table are all numbers
	 */
	sortFilteredData() {
		const filteredReportDataKeys = Object.keys(this.filteredReportData);
		filteredReportDataKeys.sort((a, b) => {
			let value1 = 0;
			let value2 = 0;
			if(this.sortField === 'total') {
				value1 = this.filteredReportData[a].total;
				value2 = this.filteredReportData[b].total;
			} else {
				value1 = this.filteredReportData[a].buckets[this.sortField].count;
				value2 = this.filteredReportData[b].buckets[this.sortField].count;
			}

			const reverse = (this.sortDirection === 'asc' ? 1 : -1);
			return reverse * ((value1 > value2) - (value2 > value1));
		});

		const newFilteredData = {};
		for(const sortedKey of filteredReportDataKeys) {
			newFilteredData[sortedKey] = this.filteredReportData[sortedKey];
		}

		this.filteredReportData = newFilteredData;
	}

}
