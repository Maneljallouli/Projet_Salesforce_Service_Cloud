import { LightningElement, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { wire } from 'lwc';

export default class LuxLoginPage extends LightningElement {

    @track username  = '';
    @track password  = '';
    @track isLoading = false;
    @track errorMsg  = '';

    handleUsername(e) { this.username = e.target.value; }
    handlePassword(e) { this.password = e.target.value; }

    handleLogin() {
        if (!this.username || !this.password) {
            this.errorMsg = 'Veuillez remplir tous les champs.';
            return;
        }
        this.errorMsg  = '';
        this.isLoading = true;

        // Soumet vers l'endpoint Salesforce standard
        const startUrl = encodeURIComponent(
            window.location.origin + '/luxportail'
        );
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = '/luxportail/login';

        const fields = {
            username  : this.username,
            password  : this.password,
            startURL  : '/luxportail',
            _csrf     : this.getCsrf()
        };

        Object.entries(fields).forEach(([key, val]) => {
            const input   = document.createElement('input');
            input.type    = 'hidden';
            input.name    = key;
            input.value   = val || '';
            form.appendChild(input);
        });

        document.body.appendChild(form);
        form.submit();
    }

    getCsrf() {
        const meta = document.querySelector(
            'meta[name="salesforce-community-url"]'
        );
        return meta ? meta.getAttribute('data-csrf') || '' : '';
    }
}