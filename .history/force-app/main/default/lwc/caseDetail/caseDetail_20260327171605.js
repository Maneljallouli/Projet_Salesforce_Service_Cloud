import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getCaseDetail from '@salesforce/apex/CaseController.getCaseDetail';

export default class CaseDetail extends NavigationMixin(LightningElement) {

    @track caseId = '';
    @track record = null;
    @track isLoading = true;

    // Récupère l'ID envoyé par la Home depuis l'URL
    @wire(CurrentPageReference)
    pageRef(ref) {
        if (ref && ref.state && ref.state.recordId) {
            this.caseId = ref.state.recordId;
        }
    }

    // Charge les données du Case dès que l'ID est connu
    @wire(getCaseDetail, { caseId: '$caseId' })
    wiredCase({ data, error }) {
        if (data) { 
            this.record = data; 
            this.isLoading = false; 
        }
        if (error) { 
            this.isLoading = false; 
            console.error('Erreur detail:', error); 
        }
    }

    get formattedDate() {
        if (!this.record) return '';
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

    // Retourne à la Home
    handleBack() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Home' }
        });
    }
}