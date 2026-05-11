import { LightningElement, track } from 'lwc';
import sendOtp from '@salesforce/apex/OTPController.sendOtp';
import validateOtp from '@salesforce/apex/OTPController.validateOtp';

export default class OtpForm extends LightningElement {
    @track email = '';
    @track otp = '';
    @track otpSent = false;
    @track errorMsg = '';
    sessionContactId = null;

    // Gestion du changement de l'email
    handleEmailChange(event) {
        this.email = event.target.value.trim();
        this.errorMsg = '';
    }

    // Gestion du changement de l'OTP
    handleOtpChange(event) {
        this.otp = event.target.value.trim();
        this.errorMsg = '';
    }

    // Envoi de l'OTP
    handleSendOtp() {
        if (!this.email) {
            this.errorMsg = 'Veuillez saisir un email.';
            return;
        }

        sendOtp({ email: this.email })
            .then(() => {
                this.otpSent = true;
                this.errorMsg = '';
            })
            .catch(error => {
                // Prise en charge de différentes structures d'erreur
                this.errorMsg = (error.body && error.body.message) 
                    ? error.body.message 
                    : (error.message || 'Erreur lors de l’envoi de l’OTP');
            });
    }

    // Validation de l'OTP
    handleValidateOtp() {
        if (!this.otp) {
            this.errorMsg = 'Veuillez saisir le code OTP.';
            return;
        }

        validateOtp({ email: this.email, otpCode: this.otp })
            .then(contactId => {
                this.sessionContactId = contactId;

                // Stocker le contact dans sessionStorage pour les autres composants
                sessionStorage.setItem('sessionContactId', contactId);

                this.errorMsg = '';
                this.dispatchEvent(new CustomEvent('otpvalidated', { detail: { contactId } }));
            })
            .catch(error => {
                this.errorMsg = (error.body && error.body.message) 
                    ? error.body.message 
                    : (error.message || 'Erreur lors de la validation de l’OTP');
            });
    }

    // Reset du formulaire
    resetForm() {
        this.email = '';
        this.otp = '';
        this.otpSent = false;
        this.errorMsg = '';
        this.sessionContactId = null;
        sessionStorage.removeItem('sessionContactId');
    }
}