import { LightningElement, wire, track, api } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getCaseDetail from '@salesforce/apex/CaseController.getCaseDetail';

export default class CaseDetail extends NavigationMixin(LightningElement) {
    @api recordId; // Indispensable pour l'Experience Builder
    @track record = null;
    @track isLoading = true;

    // Synchronisation avec l'URL
    @wire(CurrentPageReference)
    pageRef(ref) {
        if (ref && ref.state && ref.state.recordId) {
            this.recordId = ref.state.recordId;
        }
    }

    // Récupération des données Apex
    @wire(getCaseDetail, { caseId: '$recordId' })
    wiredCase({ data, error }) {
        if (data) {
            this.record = data;
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
            console.error('Erreur Apex:', error);
        }
    }

    // Redirection vers l'accueil
    handleBack() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Home' }
        });
    }

    get formattedDate() {
        if (!this.record || !this.record.CreatedDate) return '';
        return new Date(this.record.CreatedDate).toLocaleDateString('fr-FR', {
            day: '2-digit', month: 'long', year: 'numeric'
        });
    }

    get statusClass() {
        if (!this.record) return '';
        const s = this.record.Status.toLowerCase();
        if (s === 'new' || s === 'nouveau') return 'lux-badge lux-badge-nouveau';
        if (s === 'in progress' || s === 'en cours') return 'lux-badge lux-badge-en-cours';
        return 'lux-badge lux-badge-cloture';
    }
}