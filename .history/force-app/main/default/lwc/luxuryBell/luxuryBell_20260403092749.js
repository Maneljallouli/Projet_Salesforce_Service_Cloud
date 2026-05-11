import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class LuxuryBell extends NavigationMixin(LightningElement) {
    @track hasNotifications = true; // On peut le rendre dynamique plus tard

    handleBellClick() {
        // Rediriger vers la liste des Cases du client
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent' 
            }
        });
    }
}