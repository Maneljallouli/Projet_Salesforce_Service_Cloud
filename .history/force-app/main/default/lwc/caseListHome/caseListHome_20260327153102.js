import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
// Remplacez 'getCases' par le nom exact de votre méthode Apex existante
import getCasesApex from '@salesforce/apex/CaseController.getCases'; 

export default class CaseListHome extends NavigationMixin(LightningElement) {
    cases;
    error;

    @wire(getCasesApex, { recordLimit: 3 }) // On limite à 3 records pour la Home
    wiredCases({ error, data }) {
        if (data) {
            this.cases = data.map(record => ({
                ...record,
                // On prépare les classes CSS pour les badges de statut
                statusClass: `lux-badge lux-badge-${record.Status.toLowerCase().replace(' ', '-')}`
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.cases = undefined;
        }
    }

    navigateToDetail(event) {
        const caseId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'detail_demande__c' // Nom d'API exact de votre page de détail
            },
            state: {
                recordId: caseId
            }
        });
    }
}