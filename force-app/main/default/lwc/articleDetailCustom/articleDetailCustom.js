import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

export default class ArticleDetailCustom extends LightningElement {
    @api recordId;

    // On utilise les noms API directement sous forme de string pour éviter les erreurs d'import schema
    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: ['Knowledge__kav.Title', 'Knowledge__kav.Details__c'] 
    })
    article;

    get title() {
        return getFieldValue(this.article.data, 'Knowledge__kav.Title');
    }

    get bodyContent() {
        return getFieldValue(this.article.data, 'Knowledge__kav.Details__c');
    }

    get errorMessage() {
        if (this.article.error) {
            return 'Erreur : ' + this.article.error.body.message;
        }
        return null;
    }
}