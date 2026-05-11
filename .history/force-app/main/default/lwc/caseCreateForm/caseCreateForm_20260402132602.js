import { LightningElement, track, wire } from 'lwc';
import createCase from '@salesforce/apex/SavCaseController.createCase';
import getMyProducts from '@salesforce/apex/ProductController.getMyProducts';

// Matrice des sous-catégories basée sur tes captures d'écran
const SUBCATEGORY_MAP = {
    'Demande information': [
        'Disponibilité produit', 
        'Suivi commande', 
        'Information sur prix / promotion', 
        'Informations sur personnalisation'
    ],
    'Echange produit': [
        'Taille / ajustement', 
        'Couleur / modèle', 
        'Produit défectueux', 
        'Produit non conforme à la commande'
    ],
    'Réclamation': [
        'Produit endommagé / défectueux', 
        'Livraison retardée', 
        'Erreur de facturation', 
        'Mauvais produit livré'
    ],
    'Retour produit': [
        'Remboursement demandé', 
        'Retour pour non-conformité'
    ]
};

export default class CaseCreateForm extends LightningElement {
    // Déclaration des variables réactives
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

    // Options pour le menu déroulant des catégories
    categoryOptions = [
        { label: 'Demande information', value: 'Demande information' },
        { label: 'Echange produit', value: 'Echange produit' },
        { label: 'Réclamation', value: 'Réclamation' },
        { label: 'Retour produit', value: 'Retour produit' }
    ];

    // Récupération des produits de l'utilisateur
    @wire(getMyProducts)
    wiredProducts({data, error}) {
        if (data) {
            this.myProducts = data;
        } else if (error) {
            console.error('Erreur lors de la récupération des produits:', error);
        }
    }

    // Gère l'affichage dynamique des sous-catégories
    get subcategoryOptions() {
        if (!this.category) return [];
        return (SUBCATEGORY_MAP[this.category] || []).map(v => ({ label: v, value: v }));
    }

    // Vérifie s'il y a des sous-catégories à afficher
    get hasSubcategories() { 
        return this.subcategoryOptions.length > 0; 
    }

    // Handlers pour les saisies utilisateur
    handleSubject(e) { this.subject = e.target.value; }
    handleDescription(e) { this.description = e.target.value; }
    handleOrderNumber(e) { this.orderNumber = e.target.value; }
    handleDateChange(e) { this.purchaseDate = e.target.value; }
    handleChannelChange(e) { this.channel = e.target.value; }
    handleProductChange(e) { this.selectedProductId = e.target.value; }

    handleCategory(e) { 
        this.category = e.target.value; 
        this.subcategory = ''; // Reset de la sous-catégorie si on change la catégorie parente
    }

    handleSubcategory(e) { 
        this.subcategory = e.target.value; 
    }

    // Envoi du formulaire vers Apex
    handleSubmit() {
        this.errorMsg = '';

        // Validation simple des champs obligatoires
        if (!this.subject.trim() || !this.category || !this.description.trim()) {
            this.errorMsg = 'Veuillez remplir les champs obligatoires (*).';
            return;
        }

        this.isLoading = true;

        // Préparation de l'objet pour Apex
        const fields = {
            subject: this.subject,
            description: this.description,
            category: this.category,
            subcategory: this.subcategory,
            orderNumber: this.orderNumber,
            purchaseDate: this.purchaseDate,
            channel: this.channel,
            productId: this.selectedProductId
        };

        createCase({ caseDetails: fields })
            .then(caseId => {
                this.createdCaseId = caseId; // Stocke l'ID pour l'upload de fichiers
                this.success = true;
                this.isLoading = false;
            })
            .catch(error => {
                this.errorMsg = 'Erreur : ' + (error.body ? error.body.message : error.message);
                this.isLoading = false;
                console.error('Erreur creation Case:', error);
            });
    }

    // Appelé quand l'utilisateur a fini d'uploader ses fichiers
    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        console.log('Nombre de fichiers uploadés : ' + uploadedFiles.length);
    }

    // Réinitialisation du formulaire
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
    }
}