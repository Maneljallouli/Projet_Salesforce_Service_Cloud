import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';

export default class LuxHeader extends NavigationMixin(LightningElement) {

    @track activePage = 'home';
    userId = Id;

    @wire(getRecord, { recordId: '$userId', fields: [NAME_FIELD] })
    user;

    // Détecte la page actuelle pour mettre le menu en "gras/actif"
    @wire(CurrentPageReference)
    pageRef(ref) {
        if (!ref || !ref.attributes) return;
        const name = ref.attributes.name;
        
        if (name === 'Mes_Demandes__c')      this.activePage = 'demandes';
        else if (name === 'Nouvelle_Demande__c') this.activePage = 'nouvelle';
        else if (name === 'FAQ__c')              this.activePage = 'faq';
        else if (name === 'Produits__c')         this.activePage = 'produits';
        else                                     this.activePage = 'home';
    }

    // LA FONCTION QUI MANQUAIT OU CAUSAIT L'ERREUR
    setActive(e) {
        // Empêche le rechargement de la page via le href
        e.preventDefault();
        
        const page = e.currentTarget.dataset.page;
        this.activePage = page;

        let targetApiName = 'Home';
        if (page === 'demandes')      targetApiName = 'Mes_Demandes__c';
        else if (page === 'nouvelle') targetApiName = 'Nouvelle_Demande__c';
        else if (page === 'faq')      targetApiName = 'FAQ__c';
        else if (page === 'produits') targetApiName = 'Produits__c';

        // Navigation fluide sans recharger tout le portail
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: targetApiName
            }
        });
    }

    get userName() {
        return this.user && this.user.data ? getFieldValue(this.user.data, NAME_FIELD) : '';
    }

    get userInitials() {
        const name = this.userName;
        if (!name) return 'MJ';
        const parts = name.split(' ');
        return parts.length >= 2 
            ? (parts[0][0] + parts[1][0]).toUpperCase() 
            : name.substring(0, 2).toUpperCase();
    }

    // Getters pour les classes CSS
    get linkHome()     { return this.activePage === 'home'     ? 'lux-link active' : 'lux-link'; }
    get linkDemandes() { return this.activePage === 'demandes' ? 'lux-link active' : 'lux-link'; }
    get linkNouvelle() { return this.activePage === 'nouvelle' ? 'lux-link active' : 'lux-link'; }
    get linkFaq()      { return this.activePage === 'faq'      ? 'lux-link active' : 'lux-link'; }
    get linkProduits() { return this.activePage === 'produits' ? 'lux-link active' : 'lux-link'; }
}