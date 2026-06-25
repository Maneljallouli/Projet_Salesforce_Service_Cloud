public without sharing class AccountProfileController {

    public class AccountInfo {
        @AuraEnabled public Id contactId;
        @AuraEnabled public String userName;
        @AuraEnabled public String accountName;

        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String mobilePhone;

        @AuraEnabled public String mailingStreet;
        @AuraEnabled public String mailingCity;
        @AuraEnabled public String mailingPostalCode;
        @AuraEnabled public String mailingCountry;
    }

    @AuraEnabled(cacheable=true)
    public static AccountInfo getMyAccount() {
        User currentUser = [
            SELECT Id, FirstName, LastName, Name, Email, ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        AccountInfo info = new AccountInfo();
        info.userName = currentUser.Name;
        info.firstName = currentUser.FirstName;
        info.lastName = currentUser.LastName;
        info.email = currentUser.Email;

        if (currentUser.ContactId == null) {
            return info;
        }

        Contact c = [
            SELECT Id, FirstName, LastName, Email, Phone, MobilePhone,
                   MailingStreet, MailingCity, MailingPostalCode, MailingCountry,
                   Account.Name
            FROM Contact
            WHERE Id = :currentUser.ContactId
            LIMIT 1
        ];

        info.contactId = c.Id;
        info.accountName = c.Account != null ? c.Account.Name : null;

        info.firstName = c.FirstName;
        info.lastName = c.LastName;
        info.email = c.Email;
        info.phone = c.Phone;
        info.mobilePhone = c.MobilePhone;

        info.mailingStreet = c.MailingStreet;
        info.mailingCity = c.MailingCity;
        info.mailingPostalCode = c.MailingPostalCode;
        info.mailingCountry = c.MailingCountry;

        return info;
    }

    @AuraEnabled
    public static AccountInfo updateMyAccount(AccountInfo input) {
        if (input == null) {
            throw new AuraHandledException('Aucune donnée reçue.');
        }

        User currentUser = [
            SELECT Id, ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        if (currentUser.ContactId == null) {
            throw new AuraHandledException('Aucun contact lié à votre utilisateur.');
        }

        Contact c = new Contact(
            Id = currentUser.ContactId,
            FirstName = input.firstName,
            LastName = input.lastName,
            Email = input.email,
            Phone = input.phone,
            MobilePhone = input.mobilePhone,
            MailingStreet = input.mailingStreet,
            MailingCity = input.mailingCity,
            MailingPostalCode = input.mailingPostalCode,
            MailingCountry = input.mailingCountry
        );

        update c;

        return getMyAccount();
    }
}