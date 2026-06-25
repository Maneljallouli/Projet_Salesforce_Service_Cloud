import { LightningElement } from 'lwc';
import getMyAccount from '@salesforce/apex/AccountProfileController.getMyAccount';
import updateMyAccount from '@salesforce/apex/AccountProfileController.updateMyAccount';

export default class AccountProfile extends LightningElement {
    isLoading = true;
    isSaving = false;

    errorMessage;
    successMessage;

    form = {};

    connectedCallback() {
        this.loadAccount();
    }

    async loadAccount() {
        this.isLoading = true;
        this.errorMessage = undefined;
        this.successMessage = undefined;

        try {
            const data = await getMyAccount();
            this.form = { ...data };
        } catch (error) {
            this.errorMessage = this.reduceError(error);
        } finally {
            this.isLoading = false;
        }
    }

    handleChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;

        this.form = {
            ...this.form,
            [field]: value
        };

        this.successMessage = undefined;
    }

    async handleSave() {
        this.isSaving = true;
        this.errorMessage = undefined;
        this.successMessage = undefined;

        try {
            const updated = await updateMyAccount({
                input: this.form
            });

            this.form = { ...updated };
            this.successMessage = 'Vos informations ont été mises à jour avec succès.';
        } catch (error) {
            this.errorMessage = this.reduceError(error);
        } finally {
            this.isSaving = false;
        }
    }

    handleReset() {
        this.loadAccount();
    }

    get fullName() {
        const first = this.form.firstName || '';
        const last = this.form.lastName || '';
        return `${first} ${last}`.trim() || this.form.userName || 'Mon profil';
    }

    get accountLabel() {
        return this.form.accountName || 'Espace client Maison Luxe';
    }

    get initials() {
        const first = this.form.firstName || '';
        const last = this.form.lastName || '';
        const fallback = this.form.userName || '';

        if (first || last) {
            return `${first.charAt(0)}${last.charAt(0)}`.toUpperCase();
        }

        return fallback
            .split(' ')
            .map(part => part.charAt(0))
            .join('')
            .substring(0, 2)
            .toUpperCase() || 'ML';
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map(e => e.message).join(', ');
        }

        return error?.body?.message || error?.message || 'Une erreur est survenue.';
    }
}