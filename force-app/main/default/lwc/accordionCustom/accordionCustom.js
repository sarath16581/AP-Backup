import { LightningElement, api } from 'lwc';
import template_base from "./templates/base.html";
import template_titleSections from "./templates/titleSections.html";
import template_nonCollapsible from "./templates/nonCollapsible.html";
import * as utils from "./accordionCustomUtils";

export default class AccordionCustom extends LightningElement {
    @api mainClass = "";
    @api sectionTitle = "";
    @api iconName = null;
    @api sectionTitleBackgroundColor = null;

    @api get variant() {
        return this._variant;
    }

    _variant = "base";
    set variant(value) {
        this._variant = utils.validateVariant(value);
        if (this._variant === "non-collapsible") {
            this._expanded = true;
        }
    }

    @api get expanded() {
        return this._expanded; // to receive the state
    }

    _expanded = false;
    set expanded(value) {
        this._expanded = Boolean(value);
    }

    render() {
        switch (this._variant) {
            case "non-collapsible":
            return template_nonCollapsible;
            case "titles":
            return template_titleSections;
            default:
            return template_base;
        }
    }

    get computeSectionClasses() {
        return this._expanded ? "slds-section slds-is-open" : "slds-section";
    }

    get computeButtonClasses() {
        const classes = [
            "slds-button",
            "slds-section__title-action",
            "slds-grid",
            "slds-grid_vertical-align-center"
        ];

        if (this.iconName) {
            classes.push("slds-grid_align-spread", "slds-grid_reverse");
        }
        return classes.join(" ");
    }

    get computeAreaHidden() {
        return this._expanded ? "false" : "true";
    }

    get computeSectionTitleStyles() {
        if (this.sectionTitleBackgroundColor) {
            return `background-color: ${this.sectionTitleBackgroundColor};`;
        }
        return "";
    }

    handleClick() {
        this._expanded = !this._expanded;
        this.dispatchEvent(new CustomEvent("toggle", { detail: this._expanded }));
    }
}