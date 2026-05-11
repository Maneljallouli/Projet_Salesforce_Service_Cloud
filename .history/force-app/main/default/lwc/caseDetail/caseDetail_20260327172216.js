import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getCaseDetail from '@salesforce/apex/CaseController.getCaseDetail';

export default class CaseDetail extends LightningElement {
    @track caseId = '';
    @track record = null;
    @track isLoading = true;

    // 1. CAPTURER L'ID DEPUIS L'URL
    @wire(CurrentPageReference)
    pageRef(ref) {
        if (ref && ref.state && ref.state.recordId) {
            this.caseId = ref.state.recordId;
            this.isLoading = true;
        } else {
            this.isLoading = false;
        }
    }

    // 2. RÉCUPÉRER LES DONNÉES DEPUIS APEX
    @wire(getCaseDetail, { caseId: '$caseId' })
    wiredCase({ data, error }) {
        if (data) {
            this.record = data;
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
            console.error('Erreur de récupération:', error);
        }
    }

    // 3. FORMATER LA DATE
    get formattedDate() {
        if (!this.record || !this.record.CreatedDate) return '';
        return new Date(this.record.CreatedDate).toLocaleDateString('fr-FR', {
            day: '2-digit', month: 'long', year: 'numeric'
        });
    }

    // 4. CLASSES CSS LUXE POUR LES BADGES
    get statusClass() {
        if (!this.record) return '';
        const s = this.record.Status.toLowerCase();
        if (s === 'new' || s === 'nouveau') return 'lux-badge lux-badge-nouveau';
        if (s === 'in progress' || s === 'en cours') return 'lux-badge lux-badge-en-cours';
        return 'lux-badge lux-badge-cloture';
    }
}