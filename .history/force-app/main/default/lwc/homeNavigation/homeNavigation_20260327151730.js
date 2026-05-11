import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class HomeNavigation extends NavigationMixin(LightningElement) {

    navigateToCreate() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'nouvelle_demande__c' // Remplacez par le nom d'API exact de votre page (Étape 7)
            }
        });
    }

    navigateToMyCases() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'mes_demandes__c' // Remplacez par le nom d'API exact de votre page
            }
        });
    }

    navigateToFAQ() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'faq__c' // Remplacez par le nom d'API exact de votre page
            }
        });
    }
}