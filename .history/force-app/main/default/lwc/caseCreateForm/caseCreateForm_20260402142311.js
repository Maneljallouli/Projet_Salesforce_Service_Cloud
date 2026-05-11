import { LightningElement, track, wire } from 'lwc';
import createCaseWithFile from '@salesforce/apex/SavCaseController.createCaseWithFile';
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
    @track orderNumber = ''; 
    @track purchaseDate = '';
    @track channel = 'Online';
    @track selectedProductId = '';
    
    @track myProducts = [];
    @track isLoading = false;
    @track success = false;
    @track errorMsg = '';

    // Gestion du fichier
    fileData; 
    @track fileName = '';

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

    // Handlers basiques
    handleSubject(e) { this.subject = e.target.value; }
    handleDescription(e) { this.description = e.target.value; }
    handleOrderNumber(e) { this.orderNumber = e.target.value; }
    handleCategory(e) { this.category = e.target.value; this.subcategory = ''; }
    handleSubcategory(e) { this.subcategory = e.target.value; }
    handleDateChange(e) { this.purchaseDate = e.target.value; }
    handleChannelChange(e) { this.channel = e.target.value; }
    handleProductChange(e) { this.selectedProductId = e.target.value; }

    // Lecture du fichier sélectionné
    handleFileChange(event) {
        const file = event.target.files[0];
        if (file) {
            this.fileName = file.name;
            let reader = new FileReader();
            reader.onload = () => {
                let base64 = reader.result.split(',')[1];
                this.fileData = {
                    'filename': file.name,
                    'base64': base64
                };
            };
            reader.readAsDataURL(file);
        }
    }

    handleSubmit() {
        this.errorMsg = '';
        if (!this.subject || !this.category || !this.description) {
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
            productId: this.selectedProductId
        };

        createCaseWithFile({ 
            caseDetails: fields, 
            fileName: this.fileData ? this.fileData.filename : '', 
            base64Data: this.fileData ? this.fileData.base64 : '' 
        })
        .then(() => {
            this.success = true;
            this.isLoading = false;
        })
        .catch(error => {
            this.errorMsg = 'Une erreur est survenue lors de l\'envoi.';
            this.isLoading = false;
            console.error(error);
        });
    }

    reset() {
        this.success = false;
        this.fileName = '';
        this.fileData = null;
        this.subject = '';
        this.description = '';
    }
}