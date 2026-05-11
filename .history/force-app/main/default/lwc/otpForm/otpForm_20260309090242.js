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
        this.email = event.target.value;
        this.errorMsg = '';
    }

    // Gestion du changement de l'OTP
    handleOtpChange(event) {
        this.otp = event.target.value;
        this.errorMsg = '';
    }

    // Envoi de l'OTP
    handleSendOtp() {
        sendOtp({ email: this.email })
            .then(() => {
                this.otpSent = true;
                this.errorMsg = '';
            })
            .catch(error => {
                this.errorMsg = error.body ? error.body.message : 'Erreur lors de l’envoi de l’OTP';
            });
    }

    // Validation de l'OTP
    handleValidateOtp() {
        validateOtp({ email: this.email, otpCode: this.otp })
            .then(contactId => {
                this.sessionContactId = contactId;

                // Stocker le contact dans sessionStorage pour les autres composants
                sessionStorage.setItem('sessionContactId', contactId);

                this.errorMsg = '';
                this.dispatchEvent(new CustomEvent('otpvalidated', { detail: { contactId } }));
            })
            .catch(error => {
                this.errorMsg = error.body ? error.body.message : 'Erreur lors de la validation de l’OTP';
            });
    }
}