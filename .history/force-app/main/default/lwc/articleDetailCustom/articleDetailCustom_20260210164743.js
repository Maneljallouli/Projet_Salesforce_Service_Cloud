import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import TITLE_FIELD from '@salesforce/schema/Knowledge__kav.Title';
import BODY_FIELD from '@salesforce/schema/Knowledge__kav.Details__c'; 

export default class ArticleDetailCustom extends LightningElement {
    @api recordId;
    articleData; // Variable pour stocker les données proprement

    @wire(getRecord, { recordId: '$recordId', fields: [TITLE_FIELD, BODY_FIELD] })
    wiredArticle({ error, data }) {
        if (data) {
            this.articleData = data;
        } else if (error) {
            console.error('Erreur de chargement', error);
        }
    }

    get title() {
        return getFieldValue(this.articleData, TITLE_FIELD);
    }

    get bodyContent() {
        return getFieldValue(this.articleData, BODY_FIELD);
    }
}