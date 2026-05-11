import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyCases from '@salesforce/apex/CaseController.getMyCases';

export default class CaseListHome extends NavigationMixin(LightningElement) {

    @wire(getMyCases) cases;

    get hasCases() {
        return this.cases.data && this.cases.data.length > 0;
    }

    get enrichedCases() {
        if (!this.cases.data) return [];
        
        // On limite à 3 et on calcule la classe CSS
        return this.cases.data.slice(0, 3).map(c => ({
            ...c,
            statusClass: this.getStatusClass(c.Status)
        }));
    }

    getStatusClass(status) {
        if (!status) return 'lux-badge';
        const s = status.toLowerCase();
        
        // Mapping précis avec tes classes CSS
        if (s === 'new' || s === 'nouveau') {
            return 'lux-badge lux-badge-nouveau';
        }
        if (s === 'in progress' || s === 'en cours') {
            return 'lux-badge lux-badge-en-cours';
        }
        if (s.includes('waiting') || s.includes('attente')) {
            return 'lux-badge lux-badge-waiting';
        }
        if (s === 'resolved' || s === 'résolu') {
            return 'lux-badge lux-badge-resolved';
        }
        
        // Par défaut pour Clôturé / Closed
        return 'lux-badge lux-badge-cloture';
    }

    openDetail(e) {
        const caseId = e.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'DetailsDemande__c' },
            state: { recordId: caseId }
        });
    }
}