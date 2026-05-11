import { LightningElement, track } from 'lwc';
import callSendOtp from '@salesforce/apex/OTPController.sendOtp';           // ✅ RENOMME
import callValidateOtp from '@salesforce/apex/OTPController.validateOtp';    // ✅ RENOMME

export default class OtpForm extends LightningElement {
    @track email = '';
    @track otp = '';
    @track otpSent = false;
    @track errorMsg = '';
    sessionContactId = null;

    // Propriété calculée pour l'inverse de otpSent
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
        console.log('🔥 BOUTON CLIQUÉ ! Email:', this.email);
        
        if (!this.email) {
            this.errorMsg = 'Veuillez saisir un email.';
            return;
        }

        // Spinner + disable bouton pendant appel
        const button = this.template.querySelector('lightning-button[variant="brand"]');
        if (button) button.disabled = true;

        callSendOtp({ email: this.email })
            .then(() => {
                console.log('✅ OTP ENVOYÉ AVEC SUCCÈS');
                this.otpSent = true;
                this.errorMsg = '';
            })
            .catch(error => {
                console.error('❌ ERREUR APEX:', error);
                this.errorMsg = error.body?.message || error.message || 'Erreur lors de l\'envoi de l\'OTP';
            })
            .finally(() => {
                if (button) button.disabled = false;
            });
    }

    handleValidateOtp() {
        console.log('🔥 VALIDATION OTP:', this.otp);
        
        if (!this.otp || this.otp.length !== 6) {
            this.errorMsg = 'Veuillez saisir un code OTP à 6 chiffres.';
            return;
        }

        const button = this.template.querySelector('lightning-button[variant="brand"]');
        if (button) button.disabled = true;

        callValidateOtp({ email: this.email, otpCode: this.otp })
            .then(contactId => {
                console.log('✅ OTP VALIDÉ ! ContactId:', contactId);
                this.sessionContactId = contactId;
                sessionStorage.setItem('sessionContactId', contactId);
                this.errorMsg = '';
                this.dispatchEvent(new CustomEvent('otpvalidated', { 
                    detail: { contactId: contactId } 
                }));
            })
            .catch(error => {
                console.error('❌ VALIDATION ÉCHOUÉE:', error);
                this.errorMsg = error.body?.message || error.message || 'Code OTP invalide ou expiré';
            })
            .finally(() => {
                if (button) button.disabled = false;
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
