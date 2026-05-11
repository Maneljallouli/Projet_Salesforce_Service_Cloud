import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';

export default class LuxHeader extends LightningElement {

    @track activePage = 'home';
    userId = Id;

    @wire(getRecord, { recordId: '$userId', fields: [NAME_FIELD] })
    user;

    @wire(CurrentPageReference)
    pageRef(ref) {
        if (!ref) return;
        const url = ref.attributes && ref.attributes.name
            ? ref.attributes.name : '';
        if (url.includes('mes-demandes'))    this.activePage = 'demandes';
        else if (url.includes('nouvelle'))   this.activePage = 'nouvelle';
        else if (url.includes('faq'))        this.activePage = 'faq';
        else if (url.includes('produits'))   this.activePage = 'produits';
        else                                 this.activePage = 'home';
    }

    get userName() {
        return this.user && this.user.data
            ? getFieldValue(this.user.data, NAME_FIELD)
            : '';
    }

    get userInitials() {
        const name = this.userName;
        if (!name) return '';
        const parts = name.split(' ');
        return parts.length >= 2
            ? parts[0][0] + parts[1][0]
            : name.substring(0, 2);
    }

    get linkHome()     { return this.activePage === 'home'     ? 'lux-link active' : 'lux-link'; }
    get linkDemandes() { return this.activePage === 'demandes' ? 'lux-link active' : 'lux-link'; }
    get linkNouvelle() { return this.activePage === 'nouvelle' ? 'lux-link active' : 'lux-link'; }
    get linkFaq()      { return this.activePage === 'faq'      ? 'lux-link active' : 'lux-link'; }
    get linkProduits() { return this.activePage === 'produits' ? 'lux-link active' : 'lux-link'; }

    setActive(e) {
        this.activePage = e.currentTarget.dataset.page;
    }
}