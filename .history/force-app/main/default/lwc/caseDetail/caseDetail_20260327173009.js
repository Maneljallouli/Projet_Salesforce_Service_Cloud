import { LightningElement, wire, track, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getCaseDetail from '@salesforce/apex/CaseController.getCaseDetail';

export default class CaseDetail extends LightningElement {
    // @api recordId permet d'exposer la propriété à l'Experience Builder
    @api recordId; 
    
    @track record = null;
    @track isLoading = true;

    // CAPTURER L'ID DEPUIS L'URL (Méthode de secours et synchronisation)
    @wire(CurrentPageReference)
    pageRef(ref) {
        if (ref && ref.state && ref.state.recordId) {
            this.recordId = ref.state.recordId;
            this.isLoading = true;
        }
    }

    // RÉCUPÉRER LES DONNÉES DEPUIS APEX
    // On utilise '$recordId' car c'est la variable officielle liée au Builder
    @wire(getCaseDetail, { caseId: '$recordId' })
    wiredCase({ data, error }) {
        if (data) {
            this.record = data;
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
            console.error('Erreur de récupération:', error);
        }
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