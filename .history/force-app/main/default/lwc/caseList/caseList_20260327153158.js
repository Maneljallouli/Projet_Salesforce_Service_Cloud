import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyCases from '@salesforce/apex/CaseController.getMyCases';

export default class CaseListHome extends NavigationMixin(LightningElement) {

    @wire(getMyCases) cases;

    // On ne garde que les 3 derniers pour la Home
    get enrichedCases() {
        if (!this.cases.data) return [];
        
        // On prend les 3 premiers (supposant que l'Apex trie par date décroissante)
        return this.cases.data.slice(0, 3).map(c => ({
            ...c,
            // On adapte les classes pour coller au CSS luxe (.lux-badge-...)
            statusClass: this.getStatusClass(c.Status)
        }));
    }

    // Adapté pour correspondre au CSS de la maquette MJ
    getStatusClass(status) {
        const s = status.toLowerCase();
        if (s === 'new' || s === 'nouveau') {
            return 'lux-badge lux-badge-nouveau';
        }
        if (s === 'in progress' || s === 'en cours') {
            return 'lux-badge lux-badge-en-cours';
        }
        return 'lux-badge lux-badge-cloture';
    }

    // Gestion de l'affichage
    get hasCases() {
        return this.cases.data && this.cases.data.length > 0;
    }

    // Navigation vers la page de détail existante
    openDetail(e) {
        const caseId = e.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { 
                name: 'Case_Detail__c' // Garde le nom d'API que tu utilises déjà
            },
            state: { recordId: caseId }
        });
    }
}