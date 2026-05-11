import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getCaseDetail from '@salesforce/apex/CaseController.getCaseDetail';

export default class CaseDetail extends LightningElement {

    @track caseId   = '';
    @track record   = null;
    @track isLoading = true;

    @wire(CurrentPageReference)
    pageRef(ref) {
        if (ref && ref.state && ref.state.recordId) {
            this.caseId = ref.state.recordId;
        }
    }

    @wire(getCaseDetail, { caseId: '$caseId' })
    wiredCase({ data, error }) {
        if (data)  { this.record = data; this.isLoading = false; }
        if (error) { this.isLoading = false; console.error(error); }
    }

    get formattedDate() {
        if (!this.record) return '';
        return new Date(this.record.CreatedDate).toLocaleDateString('fr-FR', {
            day: '2-digit', month: 'long', year: 'numeric'
        });
    }

    get statusClass() {
        const s = this.record ? this.record.Status : '';
        if (s === 'New')         return 'status-badge status-new';
        if (s === 'In Progress') return 'status-badge status-progress';
        return 'status-badge status-closed';
    }
}