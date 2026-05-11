import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getMyCases from '@salesforce/apex/CaseController.getMyCases';

export default class CaseList extends NavigationMixin(LightningElement) {

    cases;
    error;
    wiredCasesResult;
    focusHandler;

    @wire(getMyCases)
    wiredCases(result) {
        this.wiredCasesResult = result;

        if (result.data) {
            this.cases = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.cases = undefined;
        }
    }

    connectedCallback() {
        this.focusHandler = () => {
            if (this.wiredCasesResult) {
                refreshApex(this.wiredCasesResult);
            }
        };

        window.addEventListener('focus', this.focusHandler);
    }

    disconnectedCallback() {
        if (this.focusHandler) {
            window.removeEventListener('focus', this.focusHandler);
        }
    }

    get isLoading() {
        return !this.cases && !this.error;
    }

    get hasError() {
        return !!this.error;
    }

    get isEmpty() {
        return this.cases && this.cases.length === 0;
    }

    get hasCases() {
        return this.cases && this.cases.length > 0;
    }

    get caseCount() {
        return this.cases ? this.cases.length : 0;
    }

    get enrichedCases() {
        if (!this.cases) {
            return [];
        }

        return this.cases.map(c => ({
            ...c,
            statusClass: this.getStatusClass(c.Status),
            formattedDate: new Date(c.CreatedDate).toLocaleDateString('fr-FR', {
                day: '2-digit',
                month: 'short',
                year: 'numeric'
            })
        }));
    }

    getStatusClass(status) {
        if (!status) {
            return 'status-badge';
        }

        const s = status.toLowerCase();

        if (s === 'new' || s === 'nouveau') {
            return 'status-badge status-new';
        }

        if (s === 'in progress' || s === 'en cours') {
            return 'status-badge status-progress';
        }

        return 'status-badge status-closed';
    }

    async refreshCases() {
        if (this.wiredCasesResult) {
            await refreshApex(this.wiredCasesResult);
        }
    }

    openDetail(event) {
        const caseId = event.currentTarget.dataset.id;

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'DetailsDemande__c'
            },
            state: {
                recordId: caseId
            }
        });
    }
}