import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getCaseDetail from '@salesforce/apex/CaseController.getCaseDetail';

export default class CaseDetail extends NavigationMixin(LightningElement) {
    @track caseId = '';
    @track record = null;
    @track isLoading = true;
    @track error = null;

    // Récupère l'ID envoyé dans l'URL (?recordId=...)
    @wire(CurrentPageReference)
    getStateParameters(pageRef) {
        if (pageRef && pageRef.state && pageRef.state.recordId) {
            this.caseId = pageRef.state.recordId;
            this.isLoading = true; // On relance le chargement si l'ID change
        } else {
            this.isLoading = false;
        }
    }

    // Appelle l'Apex avec l'ID récupéré
    @wire(getCaseDetail, { caseId: '$caseId' })
    wiredCase({ data, error }) {
        if (data) {
            this.record = data;
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            this.error = error;
            this.record = undefined;
            this.isLoading = false;
            console.error('Erreur Apex:', error);
        }
    }

    // Getters pour le template
    get hasRecord() {
        return this.record != null;
    }

    get statusClass() {
        if (!this.record) return '';
        const s = this.record.Status.toLowerCase();
        if (s === 'new' || s === 'nouveau') return 'lux-badge lux-badge-nouveau';
        if (s === 'in progress' || s === 'en cours') return 'lux-badge lux-badge-en-cours';
        return 'lux-badge lux-badge-cloture';
    }

    handleBack() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Home' }
        });
    }
}