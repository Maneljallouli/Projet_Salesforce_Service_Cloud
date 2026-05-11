import { LightningElement, track, wire } from 'lwc';
import createCase from '@salesforce/apex/SavCaseController.createCase';
import getMyProducts from '@salesforce/apex/ProductController.getMyProducts';

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
    @track purchaseDate = '';
    @track channel = 'Online';
    @track selectedProductId = '';
    
    @track myProducts = [];
    @track createdCaseId = ''; 
    @track success = false;
    @track isLoading = false;

    categoryOptions = [
        { label: 'Demande information', value: 'Demande information' },
        { label: 'Echange produit', value: 'Echange produit' },
        { label: 'Réclamation', value: 'Réclamation' },
        { label: 'Retour produit', value: 'Retour produit' }
    ];

    @wire(getMyProducts)
    wiredProducts({data}) { if (data) this.myProducts = data; }

    get subcategoryOptions() {
        if (!this.category) return [];
        return (SUBCATEGORY_MAP[this.category] || []).map(v => ({ label: v, value: v }));
    }

    get hasSubcategories() { return this.subcategoryOptions.length > 0; }

    handleSubject(e) { this.subject = e.target.value; }
    handleDescription(e) { this.description = e.target.value; }
    handleCategory(e) { this.category = e.target.value; this.subcategory = ''; }
    handleSubcategory(e) { this.subcategory = e.target.value; }
    handleDateChange(e) { this.purchaseDate = e.target.value; }
    handleChannelChange(e) { this.channel = e.target.value; }
    handleProductChange(e) { this.selectedProductId = e.target.value; }

    handleSubmit() {
        if (!this.subject || !this.category || !this.description) return;
        this.isLoading = true;

        const fields = {
            subject: this.subject,
            description: this.description,
            category: this.category,
            subcategory: this.subcategory,
            purchaseDate: this.purchaseDate,
            channel: this.channel,
            productId: this.selectedProductId
        };

        createCase({ caseDetails: fields })
        .then(resultId => {
            this.createdCaseId = resultId;
            this.success = true;
            this.isLoading = false;
        })
        .catch(error => {
            this.isLoading = false;
            console.error(error);
        });
    }

    reset() {
        this.success = false;
        this.createdCaseId = '';
        this.subject = '';
        this.description = '';
    }
}