import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

// Utilisation stricte de __kav (Knowledge Article Version)
import TITLE_FIELD from '@salesforce/schema/Knowledge__kav.Title';
import BODY_FIELD from '@salesforce/schema/Knowledge__kav.Details__c'; 

export default class ArticleDetailCustom extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: [TITLE_FIELD, BODY_FIELD] })
    article;

    get title() {
        return getFieldValue(this.article.data, TITLE_FIELD);
    }

    get bodyContent() {
        return getFieldValue(this.article.data, BODY_FIELD);
    }

    // Gestion d'affichage de l'erreur
    get errorMessage() {
        if (this.article.error) {
            console.error('Détails de l\'erreur:', JSON.stringify(this.article.error));
            return 'Erreur de récupération : ' + (this.article.error.body ? this.article.error.body.message : 'Erreur inconnue');
        }
        return null;
    }
}