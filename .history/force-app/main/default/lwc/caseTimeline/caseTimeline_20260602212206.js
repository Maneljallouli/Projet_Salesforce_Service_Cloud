import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getTimeline from '@salesforce/apex/CaseTimelineController.getTimeline';

export default class CaseTimeline extends LightningElement {
    _recordId;

    isLoading = false;
    errorMessage;
    items = [];

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        this.loadTimeline();
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        const recordIdFromUrl = currentPageReference?.state?.recordId;

        if (recordIdFromUrl && !this._recordId) {
            this._recordId = recordIdFromUrl;
            this.loadTimeline();
        }
    }

    async loadTimeline() {
        if (!this._recordId) {
            return;
        }

        this.isLoading = true;
        this.errorMessage = undefined;

        try {
            const data = await getTimeline({
                caseId: this._recordId
            });

            this.items = (data || []).map((item, index) => ({
                ...item,
                key: `${index}-${item.title}`,
                itemClass: `lux-timeline-item ${item.state}`
            }));
        } catch (error) {
            this.errorMessage = this.reduceError(error);
            this.items = [];
        } finally {
            this.isLoading = false;
        }
    }

    get hasItems() {
        return !this.isLoading && this.items.length > 0;
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map(e => e.message).join(', ');
        }

        return error?.body?.message || error?.message || 'Impossible de charger la timeline.';
    }
}