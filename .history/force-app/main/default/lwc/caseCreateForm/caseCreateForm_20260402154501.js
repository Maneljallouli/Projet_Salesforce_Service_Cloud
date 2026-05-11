import { LightningElement, track, wire } from 'lwc';
import createCase from '@salesforce/apex/SavCaseController.createCase';
import getMyProducts from '@salesforce/apex/SavCaseController.getMyProducts';

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
    @track purchaseDate = '';
    @track channel = 'Online';
    @track selectedProductId = '';
    
    @track myProducts = [];
    @track createdCaseId = ''; 
    @track errorMsg = '';
    @track isLoading = false;
    @track success = false;

    // --- AJOUTS POUR LES FICHIERS ---
    @track fileName = '';
    fileBase64 = ''; // Stockage du contenu encodé
    tempRecordId = null; 
    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg'];
    }
    // -------------------------------

    categoryOptions = [
        { label: 'Demande information', value: 'Demande information' },
        { label: 'Echange produit', value: 'Echange produit' },
        { label: 'Réclamation', value: 'Réclamation' },
        { label: 'Retour produit', value: 'Retour produit' }
    ];

    @wire(getMyProducts)
    wiredProducts({data, error}) {
        if (data) {
            this.myProducts = data;
        } else if (error) {
            console.error('Erreur produits:', error);
        }
    }

    get subcategoryOptions() {
        if (!this.category) return [];
        return (SUBCATEGORY_MAP[this.category] || []).map(v => ({ label: v, value: v }));
    }

    get hasSubcategories() { return this.subcategoryOptions.length > 0; }

    handleSubject(e) { this.subject = e.target.value; }
    handleDescription(e) { this.description = e.target.value; }
    handleOrderNumber(e) { this.orderNumber = e.target.value; }
    handleCategory(e) { 
        this.category = e.target.value; 
        this.subcategory = ''; 
    }
    handleSubcategory(e) { this.subcategory = e.target.value; }
    handleDateChange(e) { this.purchaseDate = e.target.value; }
    handleChannelChange(e) { this.channel = e.target.value; }
    handleProductChange(e) { this.selectedProductId = e.target.value; }

    // --- GESTION DU FICHIER (LECTURE BASE64) ---
    handleUploadFinished(event) {
        const file = event.target.files[0];
        this.fileName = file.name;
        
        const reader = new FileReader();
        reader.onload = () => {
            // On extrait uniquement la partie Base64 après la virgule
            this.fileBase64 = reader.result.split(',')[1];
        };
        reader.readAsDataURL(file);
    }
    // --------------------------

    handleSubmit() {
        this.errorMsg = '';
        if (!this.subject.trim() || !this.category || !this.description.trim()) {
            this.errorMsg = 'Veuillez remplir les champs obligatoires (*).';
            return;
        }

        this.isLoading = true;

        const fields = {
            subject: this.subject,
            description: this.description,
            category: this.category,
            subcategory: this.subcategory,
            orderNumber: this.orderNumber,
            purchaseDate: this.purchaseDate,
            channel: this.channel,
            productId: this.selectedProductId,
            // --- AJOUT DATA FICHIER ---
            fileName: this.fileName,
            fileBase64: this.fileBase64
        };

        createCase({ caseDetails: fields })
        .then(result => {
            this.createdCaseId = result; 
            this.success = true;
            this.isLoading = false;
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
        this.purchaseDate = '';
        this.selectedProductId = '';
        this.success = false;
        this.createdCaseId = '';
        this.errorMsg = '';
        this.fileName = ''; 
        this.fileBase64 = '';
    }
}