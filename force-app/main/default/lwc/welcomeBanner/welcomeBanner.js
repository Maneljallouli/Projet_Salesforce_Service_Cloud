import { LightningElement, wire } from 'lwc';
import Id from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import FIRSTNAME_FIELD from '@salesforce/schema/User.FirstName';

export default class WelcomeBanner extends LightningElement {
    userId = Id;
    userName = '';

    @wire(getRecord, { recordId: '$userId', fields: [FIRSTNAME_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.fields.FirstName.value;
        } else if (error) {
            console.error('Erreur lors de la récupération du nom', error);
            this.userName = 'Client VIP'; // Valeur par défaut
        }
    }
}