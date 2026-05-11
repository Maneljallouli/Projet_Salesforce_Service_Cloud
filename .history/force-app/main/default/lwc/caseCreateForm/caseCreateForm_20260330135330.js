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

    categoryOptions = [
        { label: 'Demande information', value: 'Demande information' },
        { label: 'Echange produit', value: 'Echange produit' },
        { label: 'Réclamation', value: 'Réclamation' },
        { label: 'Retour produit', value: 'Retour produit' }
    ];

    segmentOptions = [
        { label: 'Standard', value: 'Standard' },
        { label: 'VIP', value: 'VIP' }
    ];

    get subcategoryOptions() {
        if (!this.category) return [];
        return (SUBCATEGORY_MAP[this.category] || []).map(v => ({ label: v, value: v }));
    }

    get hasSubcategories() {
        return this.subcategoryOptions.length > 0;
    }

    // Handlers
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
        
        // Validation locale
        if (!this.subject.trim() || !this.category || !this.description.trim()) {
            this.errorMsg = 'Veuillez remplir les champs obligatoires (*).';
            return;
        }

        this.isLoading = true;

        // Préparation du Map pour l'Apex (Clés minuscules)
        const fieldsMap = {
            subject: this.subject,
            description: this.description,
            category: this.category,
            subcategory: this.subcategory,
            orderNumber: this.orderNumber,
            segment: this.clientSegment
        };

        // Appel de la méthode Apex avec le paramètre nommé 'caseDetails'
        createCase({ caseDetails: fieldsMap })
        .then(() => {
            this.success = true;
            this.isLoading = false;
            // Déclenche un événement pour rafraîchir les listes parentes si nécessaire
            this.dispatchEvent(new CustomEvent('caserefresh', { bubbles: true, composed: true }));
        })
        .catch(error => {
            this.isLoading = false;
            // Récupération propre du message d'erreur Salesforce
            this.errorMsg = 'Erreur : ' + (error.body ? error.body.message : error.message);
            console.error('Erreur creation case:', error);
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