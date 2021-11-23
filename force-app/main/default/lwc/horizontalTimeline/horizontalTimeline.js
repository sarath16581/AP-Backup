/**
 * @description
 * Render a horizontal timeline with dynamic plots
 *
 * @author Nathan Franklin
 * @date 2020-09-22
 * @group Core
 * @changelog
 */
import {LightningElement, api} from 'lwc';

export default class HorizontalTimeline extends LightningElement {
	_plots = [];

	//Cache to minimise rerender processing
	_intervalCache;
	_plotsCache;

	@api
	get plots() {
		return this._plots;
	}
	set plots(value) {

		// make sure we invalidate the cache so it can be rebuilt
		this._plotsCache = null;
		this._intervalCache = null;

		this._plots = value;
	}

	/**
	 * Define each plotted timeline entry and calculate the correct styles and labels
	 * This is used to build the ui markup for each entry
	 */
	get computedPlots() {
		if(this._plotsCache != null)
			return this._plotsCache;

		if(this.intervals.length === 0)
			return;

		// put the plots in lowest order first to ensure we can correctly calculate vertical offsets
		const plots = [...this.plots];
		plots.sort((a, b) => a.low - b.low);

		let i = 0;
		const output = [];

		// use the lowRange to help figure out where each entry should be plotted
		const lowIntervalRange = this.intervals[0].value;

		plots.forEach(plot => {
			const item = {};
			const start = parseFloat(plot.low);
			const end = parseFloat(plot.high);
			const left = (start - lowIntervalRange) * this.percentageWidth;
			const width = this.percentageWidth * (end - start);

			item.cssStyle = 'left:' + left + '%;width:' + width + '%';
			item.cssClass = 'entry';
			item.cssClassInner = plot.cssClass;
			item.cssStyleInner = 'animation-delay:' + (i*200) + 'ms;' + plot.cssStyle;
			item.label = plot.label;
			item.low = start;
			item.high = end;
			item.id = i;

			// use this to store which elements intersect
			item.verticalOffset = 0;

			output.push(item);

			i++;
		});

		// loop through each entry and figure out which ones should be veritcally offsetted if the intersect with each other
		// skip the 0 element because it should never be vertically offsetted
		for(let i=1;i<output.length;i++) {
			const entriesToCheck = output.filter(item => {
				return item.id < i;
			});

			// see how many times the plot intersects with its siblings
			entriesToCheck.forEach(item => {
				if(output[i].low < item.high && output[i].low > item.low) {
					output[i].verticalOffset = item.verticalOffset + 1;
				}
			});
		}

		// now we have build up a list of intersects we can apply an additional css class to reflect the vertical offset
		output.forEach(item => {
			item.cssClass += ' vertical-offset-' + item.verticalOffset;
		});

		console.log('output', output);

		this._plotsCache = output;

		return output;
	}

	get percentageWidth() {
		return 100 / (this.intervals.length - 1);
	}

	get intervals() {
		if(this._intervalCache != null)
			return this._intervalCache;

		const d = new Date();

		let lowRange = 999;
		let highRange = 0;

		this.plots.forEach(item => {
			lowRange = Math.min(lowRange, item.low);
			highRange = Math.max(highRange, item.high);
		});

		lowRange = parseInt(Math.floor(lowRange), 10);
		highRange = parseInt(Math.ceil(highRange), 10);

		const intervalCount = (highRange+1) - (lowRange-1);
		const percentageMultiplier = (100 / intervalCount);
		const output = [];
		let multiplierIndex = 0;
		for(let i=(lowRange-1);i<=(highRange+1);i++) {

			d.setHours(i);

			// TODO: dodgy workaround
			let label = d.toLocaleString([], {hour12:true, hour: 'numeric'});
			if(label === '0 am') label = '12 am';
			if(label === '0 pm') label = '12 pm';

			output.push({
				label: label.toLowerCase().replace(" ", ""),
				value: i,
				cssStyle: 'left:' + (multiplierIndex * percentageMultiplier) + '%',
				cssClass: 'interval ' + (i === (lowRange-1) || (i === (highRange+1)) ? ' end' : '')
			});
			multiplierIndex++;
		}

		this._intervalCache = output;

		return output;
	}
}