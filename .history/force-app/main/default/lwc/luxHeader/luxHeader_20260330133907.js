import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getMyContactInfo from '@salesforce/apex/SavCaseController.getMyContactInfo';

export default class LuxHeader extends NavigationMixin(LightningElement) {

    @track activePage = 'home';
    @track dropdownOpen = false;
    @track contactInfo = {};

    // Récupération des infos réelles de l'utilisateur/contact via Apex
    @wire(getMyContactInfo)
    wiredContact({ error, data }) {
        if (data) {
            this.contactInfo = data;
        } else if (error) {
            console.error('Erreur profil:', error);
        }
    }

    // Détection automatique de la page active pour le style du menu
    @wire(CurrentPageReference)
    pageRef(ref) {
        if (!ref || !ref.attributes) return;
        const name = ref.attributes.name;
        
        if (name === 'Mes_Demandes__c')          this.activePage = 'demandes';
        else if (name === 'Nouvelle_Demande__c') this.activePage = 'nouvelle';
        else if (name === 'FAQ__c')               this.activePage = 'faq';
        else if (name === 'Produits__c')          this.activePage = 'produits';
        else                                      this.activePage = 'home';
    }

    // Gestion de la navigation fluide
    setActive(e) {
        e.preventDefault();
        const page = e.currentTarget.dataset.page;
        this.activePage = page;

        let targetApiName = 'Home';
        if (page === 'demandes')      targetApiName = 'Mes_Demandes__c';
        else if (page === 'nouvelle') targetApiName = 'Nouvelle_Demande__c';
        else if (page === 'faq')       targetApiName = 'FAQ__c';
        else if (page === 'produits')  targetApiName = 'Produits__c';

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: targetApiName }
        });
    }

    // Getters dynamiques pour le HTML
    get userName() {
        if (this.contactInfo.firstName || this.contactInfo.lastName) {
            return `${this.contactInfo.firstName} ${this.contactInfo.lastName}`;
        }
        return 'Chargement...';
    }

    get userInitials() {
        const f = this.contactInfo.firstName || '';
        const l = this.contactInfo.lastName || '';
        if (f && l) return (f[0] + l[0]).toUpperCase();
        return '??';
    }

    get userEmail() { return this.contactInfo.email || ''; }
    get contactPhone() { return this.contactInfo.phone || 'Non renseigné'; }
    get contactCity() { return this.contactInfo.city || 'Non renseignée'; }

    // Gestion de l'affichage du dropdown
    toggleDropdown() {
        this.dropdownOpen = !this.dropdownOpen;
    }

    closeDropdown() {
        this.dropdownOpen = false;
    }

    handleLogout() {
        // Redirection vers le logout standard de ton portail
        window.location.href = '/luxportail/secur/logout.jsp';
    }

    // Getters pour les classes CSS actives
    get linkHome()     { return this.activePage === 'home'     ? 'lux-link active' : 'lux-link'; }
    get linkDemandes() { return this.activePage === 'demandes' ? 'lux-link active' : 'lux-link'; }
    get linkNouvelle() { return this.activePage === 'nouvelle' ? 'lux-link active' : 'lux-link'; }
    get linkFaq()      { return this.activePage === 'faq'      ? 'lux-link active' : 'lux-link'; }
    get linkProduits() { return this.activePage === 'produits' ? 'lux-link active' : 'lux-link'; }
}