import { LightningElement, track } from 'lwc';
import createCase from '@salesforce/apex/CaseController.createCase';

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
    @track orderNumber = ''; // Nouveau
    @track clientSegment = 'Standard'; // Nouveau (par défaut)
    
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

        // Appel Apex avec les nouveaux champs
        createCase({
            subject: this.subject,
            description: this.description,
            category: this.category,
            subcategory: this.subcategory,
            orderNumber: this.orderNumber, // Ajouté
            clientSegment: this.clientSegment // Ajouté
        })
        .then(caseNumber => {
            this.createdCaseId = caseNumber;
            this.success = true;
            this.isLoading = false;
        })
        .catch(error => {
            this.errorMsg = 'Une erreur est survenue lors de la création.';
            this.isLoading = false;
            console.error(error);
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