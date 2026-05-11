import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

// Utilisation impérative de __kav pour Knowledge
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

    get errorMessage() {
        if (this.article.error) {
            return 'Erreur : ' + this.article.error.body.message;
        }
        return null;
    }
}