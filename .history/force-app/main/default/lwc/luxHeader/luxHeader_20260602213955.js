import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';
import USER_ID from '@salesforce/user/Id';

import getMyNotifications from '@salesforce/apex/NotificationController.getMyNotifications';
import markAllAsRead from '@salesforce/apex/NotificationController.markAllAsRead';

import NAME_FIELD from '@salesforce/schema/User.Name';
import EMAIL_FIELD from '@salesforce/schema/User.Email';
import PHONE_FIELD from '@salesforce/schema/User.Phone';
import CITY_FIELD from '@salesforce/schema/User.City';
import CONTACT_ID_FIELD from '@salesforce/schema/User.ContactId';

const CHANNEL = '/event/Case_Status_Change__e';

export default class LuxHeader extends NavigationMixin(LightningElement) {

    @track activePage = 'home';
    @track dropdownOpen = false;
    @track notifDropdownOpen = false;
    @track hasUnread = false;
    @track notifications = [];

    _wiredNotifResult;
    _subscription = null;
    _hasBeenOpened = false;

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [NAME_FIELD, EMAIL_FIELD, PHONE_FIELD, CITY_FIELD, CONTACT_ID_FIELD]
    })
    userData;

    @wire(getMyNotifications)
    wiredNotifs(result) {
        this._wiredNotifResult = result;

        const { data, error } = result;

        if (data) {
            this.notifications = data.map(n => ({
                ...n,
                isReadBool: n.isRead === 'true',
                itemClass: n.isRead === 'true'
                    ? 'lux-notif-item lux-notif-read'
                    : 'lux-notif-item lux-notif-unread'
            }));

            const unread = data.filter(n => n.isRead === 'false');
            this.hasUnread = unread.length > 0;

        } else if (error) {
            console.error('Erreur notifications:', error);
            this.notifications = [];
            this.hasUnread = false;
        }
    }

    get unreadCount() {
        return this.notifications.filter(n => !n.isReadBool).length;
    }

    get hasNotifications() {
        return this.notifications.length > 0;
    }

    @wire(CurrentPageReference)
    pageRef(ref) {
        if (!ref || !ref.attributes) return;

        const map = {
            'Mes_Demandes__c': 'demandes',
            'Nouvelle_Demande__c': 'nouvelle',
            'FAQ__c': 'faq',
            'Produits__c': 'produits',
            'MonCompte__c': 'compte'
        };

        this.activePage = map[ref.attributes.name] || 'home';
    }

    connectedCallback() {
        this._subscribeToEvents();
        onError(error => console.error('Erreur EMP API:', error));
    }

    disconnectedCallback() {
        if (this._subscription) {
            unsubscribe(this._subscription, () => {});
        }
    }

    _subscribeToEvents() {
        const messageCallback = (event) => {
            const currentContactId = getFieldValue(this.userData.data, CONTACT_ID_FIELD);
            const eventContactId = event.data.payload.Contact_Id__c;

            if (currentContactId && currentContactId === eventContactId) {
                refreshApex(this._wiredNotifResult);
            }
        };

        subscribe(CHANNEL, -1, messageCallback)
            .then(sub => {
                this._subscription = sub;
            })
            .catch(err => console.error('Erreur subscribe:', err));
    }

    get userName() {
        return getFieldValue(this.userData.data, NAME_FIELD) || 'Client Luxe';
    }

    get userEmail() {
        return getFieldValue(this.userData.data, EMAIL_FIELD) || '';
    }

    get contactPhone() {
        return getFieldValue(this.userData.data, PHONE_FIELD) || 'Non renseigné';
    }

    get contactCity() {
        return getFieldValue(this.userData.data, CITY_FIELD) || 'Non renseignée';
    }

    get userInitials() {
        const name = this.userName;

        if (!name || name === 'Client Luxe') return 'ML';

        const parts = name.trim().split(' ');

        return parts.length >= 2
            ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
            : name.substring(0, 2).toUpperCase();
    }

    setActive(e) {
        e.preventDefault();

        const page = e.currentTarget.dataset.page;
        this.activePage = page;

        const map = {
            home: 'Home',
            demandes: 'Mes_Demandes__c',
            nouvelle: 'Nouvelle_Demande__c',
            faq: 'FAQ__c',
            produits: 'Produits__c',
            compte: 'MonCompte__c'
        };

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: map[page] || 'Home'
            }
        });
    }

    navigateToMonCompte(event) {
        if (event) {
            event.preventDefault();
            event.stopPropagation();
        }

        this.dropdownOpen = false;
        this.notifDropdownOpen = false;
        this.activePage = 'compte';

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'MonCompte__c'
            }
        });
    }

    toggleDropdown() {
        this.dropdownOpen = !this.dropdownOpen;
    }

    closeDropdown() {
        this.dropdownOpen = false;
    }

    toggleNotifDropdown() {
        if (this.notifDropdownOpen) {
            this._closeAndMarkRead();
        } else {
            this.notifDropdownOpen = true;
            this.hasUnread = false;
            this._hasBeenOpened = true;
        }
    }

    _closeAndMarkRead() {
        this.notifDropdownOpen = false;

        if (this._hasBeenOpened) {
            markAllAsRead()
                .then(() => {
                    this._hasBeenOpened = false;
                    return refreshApex(this._wiredNotifResult);
                })
                .catch(err => console.error('Erreur markAllAsRead:', err));
        }
    }

    closeNotifDropdown() {
        this._closeAndMarkRead();
    }

    handleLogout() {
        const logoutEndpoint = '/MJSupport/secur/logout.jsp';
        const destinationUrl = 'https://olivesoft--pfe.sandbox.my.site.com/MJSupport/s/login';

        window.location.href = `${logoutEndpoint}?retUrl=${encodeURIComponent(destinationUrl)}`;
    }

    get linkHome() {
        return this.activePage === 'home' ? 'lux-link active' : 'lux-link';
    }

    get linkDemandes() {
        return this.activePage === 'demandes' ? 'lux-link active' : 'lux-link';
    }

    get linkNouvelle() {
        return this.activePage === 'nouvelle' ? 'lux-link active' : 'lux-link';
    }

    get linkFaq() {
        return this.activePage === 'faq' ? 'lux-link active' : 'lux-link';
    }

    get linkProduits() {
        return this.activePage === 'produits' ? 'lux-link active' : 'lux-link';
    }

    get linkCompte() {
        return this.activePage === 'compte' ? 'lux-link active' : 'lux-link';
    }
}