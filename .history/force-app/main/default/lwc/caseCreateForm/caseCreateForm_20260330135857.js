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
    @track priority = 'Medium'; // Par défaut
    
    @track errorMsg = '';
    @track isLoading = false;
    @track success = false;
    @track createdCaseId = ''; // Stockera le CaseNumber

    // Handlers de saisie (simplifiés)
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

        // On regroupe tout dans l'objet attendu par le Map Apex
        const fields = {
            subject: this.subject,
            description: this.description,
            category: this.category,
            subcategory: this.subcategory,
            orderNumber: this.orderNumber,
            segment: this.clientSegment,
            priority: this.priority
        };

        createCase({ caseDetails: fields })
        .then(caseNumber => {
            // On récupère le numéro de ticket renvoyé par l'Apex
            this.createdCaseId = caseNumber;
            this.success = true;
            this.isLoading = false;
            // Rafraîchissement des composants environnants
            this.dispatchEvent(new CustomEvent('caserefresh', { bubbles: true, composed: true }));
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
        this.clientSegment = 'Standard';
        this.success = false;
        this.errorMsg = '';
        this.createdCaseId = '';
    }
}