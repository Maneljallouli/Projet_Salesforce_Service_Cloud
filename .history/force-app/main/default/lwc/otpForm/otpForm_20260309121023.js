import { LightningElement, track } from 'lwc';
import sendOtp from '@salesforce/apex/OTPController.sendOtp';
import validateOtp from '@salesforce/apex/OTPController.validateOtp';

export default class OtpForm extends LightningElement {
    @track email = '';
    @track otp = '';
    @track otpSent = false;
    @track errorMsg = '';
    sessionContactId = null;

    // Propriété calculée pour l’inverse de otpSent
    get isOtpStep() {
        return !this.otpSent;
    }

    handleEmailChange(event) {
        this.email = event.target.value.trim();
        this.errorMsg = '';
    }

    handleOtpChange(event) {
        this.otp = event.target.value.trim();
        this.errorMsg = '';
    }

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
                this.errorMsg = (error.body && error.body.message) 
                    ? error.body.message 
                    : (error.message || 'Erreur lors de l’envoi de l’OTP');
            });
    }

    handleValidateOtp() {
        if (!this.otp) {
            this.errorMsg = 'Veuillez saisir le code OTP.';
            return;
        }

        validateOtp({ email: this.email, otpCode: this.otp })
            .then(contactId => {
                this.sessionContactId = contactId;
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

    resetForm() {
        this.email = '';
        this.otp = '';
        this.otpSent = false;
        this.errorMsg = '';
        this.sessionContactId = null;
        sessionStorage.removeItem('sessionContactId');
    }
}