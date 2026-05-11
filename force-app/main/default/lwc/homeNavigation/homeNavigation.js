import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class HomeNavigation extends NavigationMixin(LightningElement) {

    // Redirige vers la page de création de demande
    navigateToCreate() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Nouvelle_Demande__c'
            }
        });
    }

    // Redirige vers la liste complète des demandes (Suivi)
    navigateToMyCases() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Mes_Demandes__c'
            }
        });
    }

    // Redirige vers la foire aux questions
    navigateToFAQ() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'FAQ__c'
            }
        });
    }
}