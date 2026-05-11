import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyCases from '@salesforce/apex/CaseController.getMyCases';

export default class CaseListHome extends NavigationMixin(LightningElement) {

    @wire(getMyCases) cases;

    // Prépare les 3 dernières demandes avec le style Luxe
    get enrichedCases() {
        if (!this.cases.data) return [];
        
        return this.cases.data.slice(0, 3).map(c => ({
            ...c,
            statusClass: this.getStatusClass(c.Status)
        }));
    }

    getStatusClass(status) {
        const s = status ? status.toLowerCase() : '';
        if (s === 'new' || s === 'nouveau') return 'lux-badge lux-badge-nouveau';
        if (s === 'in progress' || s === 'en cours') return 'lux-badge lux-badge-en-cours';
        return 'lux-badge lux-badge-cloture';
    }

    get hasCases() {
        return this.cases.data && this.cases.data.length > 0;
    }

    // FONCTION DE NAVIGATION : Envoie l'ID vers la page de détail
    openDetail(e) {
        const caseId = e.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { 
                name: 'Case_Detail__c' 
            },
            state: { 
                recordId: caseId 
            }
        });
    }
}