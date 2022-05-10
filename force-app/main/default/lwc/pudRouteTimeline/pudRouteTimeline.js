/**
 * @description Plot the bookings assigned to a specific PUD route on a horizontal timeline with drag and drop support.
 *				Timeline renders a collection of drop zones where each drop zone represents an interval of configurable
 *				number of minutes (e.g. 5 minutes). Consideration must be given to number of drop zones on the page and
 *				any performance impact if configuring this to less than 5 minutes.
 *
 * @author Ranjeewa Silva
 * @date 2022-02-11
 * @changelog
 * 2022-02-11 - Ranjeewa Silva - Created
 */

import { LightningElement, api, track } from 'lwc';
import { CONSTANTS, epochToDecimalTime, decimalToDisplayTime, getDisplayTimeString, getColorCodeStyleClass } from 'c/pudBulkEditBookingsService';

export default class PudRouteTimeline extends LightningElement {

	 // pud route to plot the timeline view.
	@api route;


	// start time to determine the time range displayed on the timeline. time range on the timeline starts at (startTime - 1 hour) for clarity.
	// if not supplied by the parent, start time is determined based on the bookings currently assigned to this route.
	@api startTime;

	// end time to determine the time range displayed on the timeline. time range on the timeline ends at (endTime + 1 hour) for clarity.
	// if not supplied by the parent, end time is determined based on the bookings currently assigned to this route.
	@api endTime;

	// horizontal scaling to apply to timeline. scale of 1 means the timeline takes 100% of the available width.
	// setting the scale > 1 means the timeline is displayed with horizontal scrolling.
	@api horizontalScale;

	// cache to minimise rerender processing
	_intervalCache;
	_plotsCache;
	_timeRangeCache;

	// bookings to plot on the timeline. received from the parent component.
	_bookings = [];
	@api
	get bookings() { return this._bookings; }
	set bookings(value) {
		// bookings updated - invalidate cache to force a rebuild.
		this._plotsCache = null;
		this._intervalCache = null;
		this._bookings = value;
	}

	// intervals to plot on the timeline.
	get intervals() {

		if(this._intervalCache != null) {
			return this._intervalCache;
  		}

		// calculate number of intervals required based on the time range. note that for clarity, the timeline is rendered
		// with a buffer of 1 hour at each end.
		const intervalCount = (this.timeRange.highRange - this.timeRange.lowRange) * (60/CONSTANTS.NUMBER_OF_MINUTES_PER_INTERVAL);
		const percentageMultiplier = (100 / intervalCount);
		let intervalIndex = 0;
		const output = [];

		for(let i=(this.timeRange.lowRange);i<=(this.timeRange.highRange);i++) {

			for (let j=0; j<60; j+=CONSTANTS.NUMBER_OF_MINUTES_PER_INTERVAL) {
				// add intervals to render on timeline. for the last hour (this.timeRange.highRange) we only need to render
				// the 0 minute interval marker.
				if (i < this.timeRange.highRange || j===0) {
					output.push({
						label: getDisplayTimeString(i, j),
						value: i*60+j,
						hour: i,
						minute: j,
						cssStyle: 'left:' + (i === this.timeRange.highRange ? '100' : (intervalIndex * percentageMultiplier)) + '%; width: ' + ((i === (this.timeRange.highRange)) ? '1px' : (percentageMultiplier) + '%'),
						cssClass: this.getIntervalCssClass(i, j)
					});
					intervalIndex++;
				}
			}
		}

		// populate cache and return the calculated intervals data
		this._intervalCache = output;
		return output;
	}

	/**
	 * compute each plotted timeline entry based on the bookings and calculate styles and labels
	 * This is used to build the ui markup for each entry
	 */
	get computedPlots() {

		if(this._plotsCache != null) {
			return this._plotsCache;
		}

		if(this.intervals.length === 0 || !this.route) {
			// route is not available or the intervals are not computed yet. we cannot compute the plots yet.
			return;
		}

		// determine the plots based on the bookings
		const plots = [];
		this.bookings.forEach(item => {

		    const dwellTime = item.booking.Dwell_Time_Planned__c ? item.booking.Dwell_Time_Planned__c : CONSTANTS.DEFAULT_DWELL_TIME_IN_MINUTES;
		    const bookingEndTime = (item.booking.Start_Time__c ? item.booking.Start_Time__c + (dwellTime * 60 * 1000) : null);

		    // only plot bookings having a valid start time and within the time range (this.startTime-1hour to this.endTime+1hour).
		    if (item.booking.Start_Time__c && item.booking.Start_Time__c >= this.timeRange.lowRangeEpoch && bookingEndTime <= this.timeRange.highRangeEpoch) {
				let plot = {};
				plot.low = epochToDecimalTime(item.booking.Start_Time__c);
				plot.high = plot.low + (dwellTime / 60);
				plot.cssClass = 'slds-badge item ' + getColorCodeStyleClass(item.booking);
				plot.cssStyle = '';
				plot.label = item.booking.Name;
				plot.tooltip = item.booking.Name + ' (' + decimalToDisplayTime(plot.low) + '-' + decimalToDisplayTime(plot.high) + ')';
				plot.id = item.booking.Id;
				plots.push(plot);
			}
		});

		plots.sort((a, b) => a.low - b.low);

		const output = [];

		// use the lowRange to help figure out where each entry should be plotted
		const lowIntervalRange = this.intervals[0].hour;

		plots.forEach((plot, index) => {
			const item = {};
			const start = parseFloat(plot.low);
			const end = parseFloat(plot.high);
			const left = (start - lowIntervalRange) * this.percentageWidth;
			const width = this.percentageWidth * (end - start);

			item.cssStyle = 'left:' + left + '%;width:' + width + '%';
			item.cssClass = 'entry';
			item.cssClassInner = plot.cssClass;
			item.cssStyleInner = plot.cssStyle;
			item.label = plot.label;
			item.tooltip = plot.tooltip;
			item.low = start;
			item.high = end;
			item.id = plot.id;
			item.index = index;

			// use this to store which elements intersect
			item.verticalOffset = 0;

			output.push(item);
		});

		// now that we have calculated the list of entries to plot work out the vertical offset for each entry based on
		// intersecting bookings.
		this.setVerticalOffset(output);

		// now we have build up a list of intersects we can apply an additional css class to reflect the vertical offset
		output.forEach(item => {
			item.cssClass += ' vertical-offset-' + item.verticalOffset;
		});

		this._plotsCache = output;
		return output;
	}

	/**
     * calculate time range to render on the timeline.
     */
 	get timeRange() {

 	    if (this._timeRangeCache) {
 	        // reuse the cached time range if available.
 	        return this._timeRangeCache;
        }

 	    let startTime = this.startTime;
 	    let endTime = this.endTime;

 	    if (!this.startTime || !this.endTime) {
 	        // parent has not set the start and end time to use.
            // determine timeline range dynamically from bookings passed in
            this.bookings.forEach(item => {
                if (item.booking.Start_Time__c) {
                    const dwellTime = item.booking.Dwell_Time_Planned__c ? item.booking.Dwell_Time_Planned__c : CONSTANTS.DEFAULT_DWELL_TIME_IN_MINUTES;
                    const bookingEndTime = (item.booking.Start_Time__c ? item.booking.Start_Time__c + (dwellTime * 60 * 1000) : null);

                    if (!startTime || item.booking.Start_Time__c < startTime) {
                        startTime = item.booking.Start_Time__c;
                    }
                    if (bookingEndTime && (!endTime || bookingEndTime > endTime)) {
                        endTime = bookingEndTime;
                    }
                }
            });
        }

        let timeRange;

        if (startTime && endTime) {

			let lowRange = parseInt(Math.floor(epochToDecimalTime(startTime)), 10);
            let highRange = parseInt(Math.ceil(epochToDecimalTime(endTime)), 10);

			// ensure the timeline is rendered with a buffer of one full hour at both ends for clarity. timeline is plotted
            // from (startTime(hh)-1hour) to (endTime(hh)+1hour).
            lowRange =  (lowRange > 0 ? lowRange-1 : lowRange);
            highRange =  (highRange < 23 ? highRange+1 : highRange);

	        timeRange = {
                lowRange: lowRange,
                lowRangeEpoch: Date.UTC(1970, 0, 1, lowRange, 0),
                highRange: highRange,
                highRangeEpoch: Date.UTC(1970, 0, 1, highRange, 0)
            }
        } else {
            // start and end times are not specified by the parent and no existing bookings on timeline.
            // render timeline for 8am to 5pm by default.
            timeRange =  {
                lowRange: CONSTANTS.DEFAULT_ROUTE_START_TIME_HH - 1,
                lowRangeEpoch: Date.UTC(1970, 0, 1, (CONSTANTS.DEFAULT_ROUTE_START_TIME_HH - 1), 0),
                highRange: CONSTANTS.DEFAULT_ROUTE_END_TIME_HH + 1,
                highRangeEpoch: Date.UTC(1970, 0, 1, (CONSTANTS.DEFAULT_ROUTE_END_TIME_HH + 1), 0)
            }
        }

		// cache calculated time range for reuse
        this._timeRangeCache = timeRange;
        return this._timeRangeCache;
    }



	/**
	 * calculate and set vertical off set on the entries passed in.
	 * vertical offset is set on intersecting entries so that they do not overlap on the timeline.
	 */
 	setVerticalOffset(entries) {
 		// loop through each entry and figure out which ones should be vertically offsetted if they intersect with each other
		// skip the 0 element because it should never be vertically offsetted
		for(let i=1;i<entries.length;i++) {
			const entriesToCheck = entries.filter(item => {
				return item.index < i;
			});

			// see how many times the plot intersects with its siblings. also collect vertical offsets of those intersecting
			// siblings so that a vertical offset can be allocated to current entry.
			let overlappingOffsets = [];
			entriesToCheck.forEach(item => {
				if(item.high-entries[i].low>=1/60 && entries[i].low >= item.low) {
					overlappingOffsets.push(item.verticalOffset);
				}
			});

			if (overlappingOffsets.length > 0) {
				// overlapping siblings found for the current entry. sort the vertical offsets so that the current entry
				// can be assigned the smallest vertical offset not taken by it's siblings.
				overlappingOffsets.sort();

				// set the initial vertical offset. if overlapping siblings currently do not have a offset of 0, current entry
				// is assigned the offset 0. else set the initial vertical offset to [highest offset assigned to overlapping siblings  + 1].
				entries[i].verticalOffset = overlappingOffsets[0] != 0 ? 0 : overlappingOffsets[overlappingOffsets.length-1]+1;


				if (overlappingOffsets[0] != 0) {
					// if overlapping siblings currently do not have a offset of 0, current entry is assigned the offset 0.
					entries[i].verticalOffset = 0;
				} else {
					// need to check offsets assigned to overlapping siblings and find the lowest available offset not
					// currently taken by a sibling.
					// set the initial vertical offset to [highest offset assigned to overlapping siblings  + 1]. note that the
					// 'overlappingOffsets' is already sorted.
					entries[i].verticalOffset = overlappingOffsets[overlappingOffsets.length-1]+1;
					for (let j=0; j<overlappingOffsets.length-1; j++) {
						// check if there is any gap between overlappingOffsets[j] & overlappingOffsets[j+1].
						if (overlappingOffsets[j]+1 < overlappingOffsets[j+1] ) {
							// unused vertical offset found. assign this to the current entry.
							entries[i].verticalOffset = overlappingOffsets[j]+1;
							break;
						}
					}
				}
			} else {
				// overlapping siblings not found for this entry. set vertical off set to 0.
				entries[i].verticalOffset = 0;
			}
		}
  	}

	// returns the width taken by an hour on the timeline as a percentage of total available width.
	get percentageWidth() {
		return 100 / (this.timeRange.highRange - this.timeRange.lowRange);
	}

	// title displayed on timeline
	get timelineTitle() {
		if (this.route) {
			return (this.bookings ? `${this.route.Name} (${this.bookings.length})` : `${this.route.Name} (0)`);
		}
	}

	get timelineWrapperStyleCss() {
		return 'width:' + this.horizontalScale * 100 +'%';
	}

	get timelineCssClass() {

		let isCompact = false;
		if (this.intervals && this.intervals.length > 0 && this.horizontalScale) {
			// TODO - better way to determine compact mode calculation
			// users can use zoom controls to change the horizontal scaling of the timeline. when timeline is zoomed out
			// we apply additional styling to determine which marker labels are displayed. in compact mode 15 minute and
			// 45 minute marker labels are not displayed.
			isCompact = this.horizontalScale * (100 / this.intervals.length) < 1;
		}

		return 'timeline animated pulse' + (isCompact ? ' compact' : '');
	}

	/**
	 * calculate the css classes applied to intervals rendered on the timeline.
	 */
	getIntervalCssClass(hour, minute) {
        let cssClass = 'interval';
        // check if this interval is at one end of the timeline. append 'end' css class to apply relevant styling.
        cssClass += (minute === 0 && (hour === this.timeRange.lowRange || hour === this.timeRange.highRange) ? ' end' : '');
        // check if interval marker should be visible. only 0, 15, 30 and 45 minute markers are visible for each hour.
        cssClass += ((minute % 15) === 0 ? ' marker-visible marker-'+minute+'-min' : '');
        return cssClass;
    }

	handleItemDragStart(evt) {

		// dispatch event passing in booking id and route id so the parent can register the item being dragged.
		const event = new CustomEvent('bookingdragstart', {
			detail: {
				bookingId: evt.target.dataset.id,
				routeId: this.route.Id
			}
		});
		this.dispatchEvent(event);
   	}

   	handleDragEnter(evt) {
		// item dragged is entering a new drop zone. apply additional styling to current drop zone for visual effects.
		evt.target.classList.add('over');
		// cancel the event
		this.cancel(evt);
   	}

  	handleDragOver(evt) {

		// cancel the event
		this.cancel(evt);
	}

	handleDragLeave(evt) {

		// item dragged is leaving the current drop zone. remove styling applied to highlight current drop zone.
		evt.target.classList.remove('over');
		// cancel the event
		this.cancel(evt);
	}

	handleDrop(evt) {

		// item dragged is dropped into the current drop zone. remove styling applied to highlight current drop zone.
		evt.target.classList.remove('over');

		// cancel the event
		this.cancel(evt);

		// dispatch event passing in the details (route id / hours / minutes) of the drop zone where the item is dropped.
		const dropEvent = new CustomEvent('bookingdrop', {
			detail: {
				routeId : this.route.Id,
				startTimeHH : evt.target.dataset.hour,
				startTimeMM : evt.target.dataset.min
   			}
		});
		this.dispatchEvent(dropEvent);

 	}

 	handleSelectItem(evt) {
 		const event = new CustomEvent('bookingselect', {
			detail: {
				bookingId: evt.currentTarget.dataset.id,
				routeId: this.route.Id
			}
		});
		this.dispatchEvent(event);
  	}

 	// cancel drag n drop events
	cancel(event) {
		if (event.stopPropagation) event.stopPropagation();
		if (event.preventDefault) event.preventDefault();
		return false;
	};
}