import { createElement } from 'lwc';
import OtpForm from 'c/otpForm';
import sendOtp from '@salesforce/apex/OTPController.sendOtp';
import validateOtp from '@salesforce/apex/OTPController.validateOtp';

jest.mock('@salesforce/apex/OTPController.sendOtp', () => { return { default: jest.fn() }; }, { virtual: true });
jest.mock('@salesforce/apex/OTPController.validateOtp', () => { return { default: jest.fn() }; }, { virtual: true });

describe('c-otp-form', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders the OTP form', () => {
        const element = createElement('c-otp-form', { is: OtpForm });
        document.body.appendChild(element);
        const input = element.shadowRoot.querySelector('lightning-input');
        expect(input).not.toBeNull();
    });
});