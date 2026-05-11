import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
// Utilisation du contrôleur sécurisé pour l'assignation automatique
import getMyCases from '@salesforce/apex/SavCaseController.getMyCases';

export default class CaseListHome extends NavigationMixin(LightningElement) {

    // Récupération des données via le wire service
    @wire(getMyCases) cases;

    // Logique pour formater et limiter les données à 3 éléments pour la Home
    get enrichedCases() {
        if (!this.cases.data) {
            return [];
        }
        
        // On prend les 3 premiers records et on ajoute la classe CSS de statut
        return this.cases.data.slice(0, 3).map(c => ({
            ...c,
            statusClass: this.getStatusClass(c.Status)
        }));
    }

    // Retourne la classe CSS correspondante au style "Luxe MJ"
    getStatusClass(status) {
        if (!status) {
            return 'lux-badge';
        }
        const s = status.toLowerCase();
        
        // Nouveaux Statuts
        if (s.includes('waiting') || s.includes('attente')) {
            return 'lux-badge lux-badge-waiting';
        }
        if (s === 'resolved' || s === 'résolu') {
            return 'lux-badge lux-badge-resolved';
        }

        // Statuts Classiques
        if (s === 'new' || s === 'nouveau') {
            return 'lux-badge lux-badge-nouveau';
        }
        if (s === 'in progress' || s === 'en cours') {
            return 'lux-badge lux-badge-en-cours';
        }

        // Par défaut ou pour 'Closed' / 'Clôturé'
        return 'lux-badge lux-badge-cloture';
    }

    // Vérifie s'il y a des dossiers à afficher
    get hasCases() {
        return this.cases.data && this.cases.data.length > 0;
    }

    /**
     * MÉTHODE DE NAVIGATION
     */
    openDetail(e) {
        const caseId = e.currentTarget.dataset.id;
        
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { 
                name: 'DetailsDemande__c' 
            },
            state: { 
                recordId: caseId 
            }
        });
    }
}