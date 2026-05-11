import { LightningElement, track } from 'lwc';
import createCase from '@salesforce/apex/SavCaseController.createCase';

const SUBCATEGORY_MAP = {
    'Demande information': ['Disponibilité produit', 'Suivi commande', 'Information sur prix / promotion', 'Informations sur personnalisation'],
    'Echange produit': ['Taille / ajustement', 'Couleur / modèle', 'Produit défectueux', 'Produit non conforme à la commande'],
    'Réclamation': ['Produit endommagé / défectueux', 'Livraison retardée', 'Erreur de facturation', 'Mauvais produit livré'],
    'Retour produit': ['Remboursement demandé', 'Retour pour non-conformité']
};

export default class CaseCreateForm extends LightningElement {
    @track subject = '';
    @track description = '';
    @track category = '';
    @track subcategory = '';
    @track orderNumber = ''; 
    @track clientSegment = 'Standard'; 
    
    @track errorMsg = '';
    @track isLoading = false;
    @track success = false;
    @track createdCaseId = ''; // Stockera le CaseNumber

    categoryOptions = [
        { label: 'Demande information', value: 'Demande information' },
        { label: 'Echange produit', value: 'Echange produit' },
        { label: 'Réclamation', value: 'Réclamation' },
        { label: 'Retour produit', value: 'Retour produit' }
    ];

    segmentOptions = [
        { label: 'Standard', value: 'Standard' },
        { label: 'Premium', value: 'Premium' },
        { label: 'VIP', value: 'VIP' }
    ];

    get subcategoryOptions() {
        if (!this.category) return [];
        const subCats = SUBCATEGORY_MAP[this.category] || [];
        return subCats.map(v => ({ label: v, value: v }));
    }

    get hasSubcategories() {
        return this.subcategoryOptions.length > 0;
    }

    handleSubject(e) { this.subject = e.target.value; }
    handleDescription(e) { this.description = e.target.value; }
    handleOrderNumber(e) { this.orderNumber = e.target.value; }
    handleSegment(e) { this.clientSegment = e.target.value; }
    
    handleCategory(e) { 
        this.category = e.target.value; 
        this.subcategory = ''; 
    }
    
    handleSubcategory(e) { this.subcategory = e.target.value; }

    handleSubmit() {
        this.errorMsg = '';
        if (!this.subject.trim() || !this.category || !this.description.trim()) {
            this.errorMsg = 'Veuillez remplir les champs obligatoires (*).';
            return;
        }

        this.isLoading = true;

        const caseFields = {
            Subject: this.subject,
            Description: this.description,
            Category__c: this.category,
            Subcategory__c: this.subcategory,
            Order_number__c: this.orderNumber,
            Client_segment__c: this.clientSegment
        };

        createCase({ newCase: caseFields })
        .then(caseNumber => {
            this.createdCaseId = caseNumber;
            this.success = true;
            this.isLoading = false;

            // CRITIQUE : Informe le composant parent de rafraîchir la liste et le compteur
            this.dispatchEvent(new CustomEvent('caserefresh', {
                bubbles: true,
                composed: true
            }));
        })
        .catch(error => {
            this.errorMsg = 'Erreur : ' + (error.body ? error.body.message : error.message);
            this.isLoading = false;
        });
    }

    reset() {
        this.subject = '';
        this.description = '';
        this.category = '';
        this.subcategory = '';
        this.orderNumber = '';
        this.success = false;
        this.errorMsg = '';
    }
}