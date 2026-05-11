// Vérification avant le SELECT Contact
if(!Schema.sObjectType.Contact.isAccessible()) {
    throw new AuraHandledException('Permission lecture Contact manquante');
}
List<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE Email = :email LIMIT 1];

// Vérification avant l'INSERT Account
if(!Schema.sObjectType.Account.isCreateable()) {
    throw new AuraHandledException('Permission création Account manquante');
}
Account a = new Account(Name = 'Prospect - ' + email);
insert a;

// Vérification avant l'INSERT Contact
if(!Schema.sObjectType.Contact.isCreateable()) {
    throw new AuraHandledException('Permission création Contact manquante');
}
Contact c = new Contact(
    FirstName = 'Nouveau',
    LastName = 'Client',
    Email = email,
    AccountId = a.Id
);
insert c;

// Vérification avant l'INSERT OTP__c
if(!Schema.sObjectType.OTP__c.isCreateable()) {
    throw new AuraHandledException('Permission création OTP manquante');
}
OTP__c otpRecord = new OTP__c(
    Contact__c = c.Id,
    OTP_Code__c = otpCode,
    Expiration__c = System.now().addMinutes(10),
    Used__c = false
);
insert otpRecord;

// Vérification avant UPDATE OTP__c
if(!Schema.sObjectType.OTP__c.isUpdateable()) {
    throw new AuraHandledException('Permission mise à jour OTP manquante');
}
otpRec.Used__c = true;
update otpRec;