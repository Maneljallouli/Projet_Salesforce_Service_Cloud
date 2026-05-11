import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyCases from '@salesforce/apex/CaseController.getMyCases';

export default class CaseList extends NavigationMixin(LightningElement) {

    @wire(getMyCases) cases;

    get isLoading() {
        return !this.cases.data && !this.cases.error;
    }

    get hasError() {
        return !!this.cases.error;
    }

    get isEmpty() {
        return this.cases.data && this.cases.data.length === 0;
    }

    get hasCases() {
        return this.cases.data && this.cases.data.length > 0;
    }

    get caseCount() {
        return this.cases.data ? this.cases.data.length : 0;
    }

    get enrichedCases() {
        if (!this.cases.data) return [];
        return this.cases.data.map(c => ({
            ...c,
            statusClass  : this.getStatusClass(c.Status),
            formattedDate: new Date(c.CreatedDate).toLocaleDateString('fr-FR', {
                day: '2-digit', month: 'short', year: 'numeric'
            })
        }));
    }

    getStatusClass(status) {
        if (status === 'New')         return 'status-badge status-new';
        if (status === 'In Progress') return 'status-badge status-progress';
        return 'status-badge status-closed';
    }

    openDetail(e) {
        const caseId = e.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type      : 'comm__namedPage',
            attributes: { name: 'Case_Detail__c' },
            state     : { recordId: caseId }
        });
    }
}