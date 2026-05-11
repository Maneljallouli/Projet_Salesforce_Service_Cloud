import { LightningElement, track } from 'lwc';
import apexSendOtp from '@salesforce/apex/OTPController.sendOtp';
import apexValidateOtp from '@salesforce/apex/OTPController.validateOtp';

export default class OtpForm extends LightningElement {
    @track email = '';
    @track otp = '';
    @track otpSent = false;
    @track errorMsg = '';

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
        console.log('🔥 CLICK DÉTECTÉ ! Email:', this.email);
        
        if (!this.email) {
            this.errorMsg = 'Email requis.';
            return;
        }

        apexSendOtp({ email: this.email })
            .then(() => {
                console.log('✅ OTP ENVOYÉ');
                this.otpSent = true;
                this.errorMsg = '';
            })
            .catch(error => {
                console.error('❌ ERREUR:', error);
                this.errorMsg = error.body?.message || 'Erreur envoi OTP';
            });
    }

    handleValidateOtp() {
        console.log('🔥 VALIDATION:', this.otp);
        
        if (!this.otp || this.otp.length !== 6) {
            this.errorMsg = 'Code OTP = 6 chiffres.';
            return;
        }

        apexValidateOtp({ email: this.email, otpCode: this.otp })
            .then(contactId => {
                console.log('✅ VALIDÉ ! ID:', contactId);
                sessionStorage.setItem('sessionContactId', contactId);
                this.dispatchEvent(new CustomEvent('otpvalidated', { 
                    detail: { contactId } 
                }));
            })
            .catch(error => {
                console.error('❌ CODE INVAlIDE:', error);
                this.errorMsg = 'Code invalide/expiré';
            });
    }
}
