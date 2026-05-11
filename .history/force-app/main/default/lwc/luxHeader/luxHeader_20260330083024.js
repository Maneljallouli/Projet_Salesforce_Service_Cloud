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

    // 1. DÉTECTION AUTOMATIQUE DE LA PAGE ACTIVE
    @wire(CurrentPageReference)
    pageRef(ref) {
        if (!ref || !ref.attributes) return;
        
        const apiName = ref.attributes.name;

        // On synchronise activePage avec l'API Name réelle de la page
        if (apiName === 'Mes_Demandes__c')      this.activePage = 'demandes';
        else if (apiName === 'Nouvelle_Demande__c') this.activePage = 'nouvelle';
        else if (apiName === 'FAQ__c')              this.activePage = 'faq';
        else if (apiName === 'Produits__c')         this.activePage = 'produits';
        else if (apiName === 'Home')                this.activePage = 'home';
    }

    // 2. LOGIQUE DE REDIRECTION AU CLIC
    handleNavigation(e) {
        // On empêche le comportement par défaut du lien <a>
        e.preventDefault();
        
        const page = e.currentTarget.dataset.page;
        let targetApiName = 'Home'; // Par défaut

        // Mapping entre le dataset.page et l'API Name Salesforce
        if (page === 'demandes') targetApiName = 'Mes_Demandes__c';
        else if (page === 'nouvelle') targetApiName = 'Nouvelle_Demande__c';
        else if (page === 'faq') targetApiName = 'FAQ__c';
        else if (page === 'produits') targetApiName = 'Produits__c';

        // Commande de navigation officielle Salesforce
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

    // 3. GETTERS POUR LES CLASSES CSS (Gère l'état visuel "actif")
    get linkHome()     { return this.activePage === 'home'     ? 'lux-link active' : 'lux-link'; }
    get linkDemandes() { return this.activePage === 'demandes' ? 'lux-link active' : 'lux-link'; }
    get linkNouvelle() { return this.activePage === 'nouvelle' ? 'lux-link active' : 'lux-link'; }
    get linkFaq()      { return this.activePage === 'faq'      ? 'lux-link active' : 'lux-link'; }
    get linkProduits() { return this.activePage === 'produits' ? 'lux-link active' : 'lux-link'; }
}