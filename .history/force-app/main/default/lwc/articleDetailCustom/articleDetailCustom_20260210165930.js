import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

// Champs standards
import TITLE_FIELD from '@salesforce/schema/Knowledge__kav.Title';
// IMPORTANT : Vérifiez bien ce nom (Details__c, Answer__c, ou Question__c)
import BODY_FIELD from '@salesforce/schema/Knowledge__kav.Details__c'; 

export default class ArticleDetailCustom extends LightningElement {
    @api recordId;
    error;

    // Le '$recordId' avec le $ est CRUCIAL pour que le composant 
    // se mette à jour quand vous cliquez sur un autre article
    @wire(getRecord, { recordId: '$recordId', fields: [TITLE_FIELD, BODY_FIELD] })
    article;

    get title() {
        return getFieldValue(this.article.data, TITLE_FIELD);
    }

    get bodyContent() {
        return getFieldValue(this.article.data, BODY_FIELD);
    }

    // Pour voir l'erreur si ça ne charge pas
    get errorMessage() {
        if (this.article.error) {
            return 'Erreur Salesforce : ' + JSON.stringify(this.article.error);
        }
        return null;
    }
}