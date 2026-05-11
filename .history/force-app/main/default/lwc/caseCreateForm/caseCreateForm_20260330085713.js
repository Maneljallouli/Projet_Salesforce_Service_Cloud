import { LightningElement, track } from 'lwc';
import createCase from '@salesforce/apex/SavCaseController.createCase';

const SUBCATEGORY_MAP = {
    'Réclamation': ['Produit défectueux', 'Retard livraison', 'Autre'],
    'Retour produit': ['Remboursement', 'Échange taille', 'Autre'],
    'Échange produit': ['Couleur', 'Modèle', 'Autre'],
    'Demande information': ['Disponibilité', 'Entretien produit', 'Autre']
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
    @track createdCaseId = '';

    categoryOptions = [
        { label: 'Réclamation', value: 'Réclamation' },
        { label: 'Retour produit', value: 'Retour produit' },
        { label: 'Échange produit', value: 'Échange produit' },
        { label: 'Demande information', value: 'Demande information' }
    ];

    segmentOptions = [
        { label: 'Standard', value: 'Standard' },
        { label: 'Premium', value: 'Premium' },
        { label: 'VIP', value: 'VIP' }
    ];

    get subcategoryOptions() {
        if (!this.category) return [];
        return (SUBCATEGORY_MAP[this.category] || [])
            .map(v => ({ label: v, value: v }));
    }

    get hasSubcategories() {
        return this.subcategoryOptions.length > 0;
    }

    // Handlers
    handleSubject(e) { this.subject = e.target.value; }
    handleDescription(e) { this.description = e.target.value; }
    handleOrderNumber(e) { this.orderNumber = e.target.value; }
    handleSegment(e) { this.clientSegment = e.target.value; }
    handleCategory(e) { this.category = e.target.value; this.subcategory = ''; }
    handleSubcategory(e) { this.subcategory = e.target.value; }

    handleSubmit() {
        this.errorMsg = '';

        if (!this.subject.trim() || !this.category || !this.description.trim()) {
            this.errorMsg = 'Veuillez remplir tous les champs obligatoires (*).';
            return;
        }

        this.isLoading = true;

        // Préparation de l'objet Case avec les API NAMES EXACTS
        // Cela permet de passer un seul paramètre à l'Apex et d'éviter l'erreur PMD
        const caseFields = {
            Subject: this.subject,
            Description: this.description,
            Category__c: this.category,
            Subcategory__c: this.subcategory,
            Order_number__c: this.orderNumber, // Nom API exact avec underscore
            Client_segment__c: this.clientSegment // Nom API exact avec underscore
        };

        // On appelle la méthode Apex en envoyant l'objet 'newCase'
        createCase({ newCase: caseFields })
        .then(resultId => {
            this.createdCaseId = resultId;
            this.success = true;
            this.isLoading = false;
        })
        .catch(error => {
            this.errorMsg = 'Une erreur est survenue lors de la création : ' + (error.body ? error.body.message : error.message);
            this.isLoading = false;
            console.error('Erreur Apex:', error);
        });
    }

    reset() {
        this.subject = '';
        this.description = '';
        this.category = '';
        this.subcategory = '';
        this.orderNumber = '';
        this.clientSegment = 'Standard';
        this.success = false;
        this.errorMsg = '';
    }
}