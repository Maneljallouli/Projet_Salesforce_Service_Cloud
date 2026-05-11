import { LightningElement, track } from 'lwc';
import createCase from '@salesforce/apex/CaseController.createCase';

const SUBCATEGORY_MAP = {
    'Réclamation'        : ['Produit défectueux', 'Retard livraison', 'Autre'],
    'Retour produit'     : ['Remboursement', 'Échange taille', 'Autre'],
    'Échange produit'    : ['Couleur', 'Modèle', 'Autre'],
    'Demande information': ['Disponibilité', 'Entretien produit', 'Autre']
};

export default class CaseCreateForm extends LightningElement {

    @track subject      = '';
    @track description  = '';
    @track category     = '';
    @track subcategory  = '';
    @track errorMsg     = '';
    @track isLoading    = false;
    @track success      = false;
    @track createdCaseId = '';

    categoryOptions = [
        { label: 'Réclamation',         value: 'Réclamation' },
        { label: 'Retour produit',       value: 'Retour produit' },
        { label: 'Échange produit',      value: 'Échange produit' },
        { label: 'Demande information',  value: 'Demande information' }
    ];

    get subcategoryOptions() {
        if (!this.category) return [];
        return (SUBCATEGORY_MAP[this.category] || [])
            .map(v => ({ label: v, value: v }));
    }

    get hasSubcategories() {
        return this.subcategoryOptions.length > 0;
    }

    handleSubject(e)     { this.subject     = e.target.value; }
    handleDescription(e) { this.description = e.target.value; }
    handleCategory(e)    { this.category    = e.target.value; this.subcategory = ''; }
    handleSubcategory(e) { this.subcategory = e.target.value; }

    handleSubmit() {
        this.errorMsg = '';

        if (!this.subject.trim()) {
            this.errorMsg = 'Le sujet est requis.';
            return;
        }
        if (!this.category) {
            this.errorMsg = 'Veuillez choisir un type de demande.';
            return;
        }
        if (!this.description.trim()) {
            this.errorMsg = 'La description est requise.';
            return;
        }

        this.isLoading = true;

        createCase({
            subject      : this.subject,
            description  : this.description,
            category     : this.category,
            subcategory  : this.subcategory,
            clientSegment: 'Standard'
        })
        .then(caseId => {
            this.createdCaseId = caseId;
            this.success       = true;
            this.isLoading     = false;
        })
        .catch(error => {
            this.errorMsg  = 'Une erreur est survenue. Veuillez réessayer.';
            this.isLoading = false;
            console.error(error);
        });
    }

    reset() {
        this.subject      = '';
        this.description  = '';
        this.category     = '';
        this.subcategory  = '';
        this.success      = false;
        this.createdCaseId = '';
        this.errorMsg     = '';
    }
}