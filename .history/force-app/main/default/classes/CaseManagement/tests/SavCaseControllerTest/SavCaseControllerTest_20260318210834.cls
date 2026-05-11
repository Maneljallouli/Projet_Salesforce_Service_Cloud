/**
 * @class       SavCaseControllerTest
 * @description Test class for SavCaseController.
 *              Coverage target : ≥ 85%
 *              Tests : création Case, liste, détail, commentaire,
 *                      fermeture, escalade, stats dashboard,
 *                      sécurité cross-contact, validations input.
 *
 * @author      Salesforce Architect
 * @version     2.0
 */
@IsTest
private class SavCaseControllerTest {

    // ─────────────────────────────────────────────────────────────
    // TEST DATA FACTORY
    // ─────────────────────────────────────────────────────────────

    @TestSetup
    static void setupTestData() {
        // Account
        Account acc = new Account(Name = 'Test Maison Luxe');
        insert acc;

        // Contact principal (portail user)
        Contact con = new Contact(
            FirstName             = 'Isabelle',
            LastName              = 'Dupont',
            Email                 = 'isabelle.dupont@test.com',
            AccountId             = acc.Id,
            Preferred_Language__c = 'fr',
            Segment_VIP__c        = 'VIP'
        );
        insert con;

        // Produit_Client__c
        Produit_Client__c produit = new Produit_Client__c(
            Contact__c              = con.Id,
            Nom_Produit__c          = 'Birkin 35',
            Reference_Officielle__c = 'BIRK35-TEST-001',
            Modele__c               = 'Birkin',
            Couleur__c              = 'Noir',
            Actif__c                = true
        );
        insert produit;

        // Categorie_SAV__c
        Categorie_SAV__c categorie = new Categorie_SAV__c(
            Nom__c   = 'Défaut produit',
            Code__c  = 'DEFAUT',
            Actif__c = true
        );
        insert categorie;

        // Portal User
        Profile p = [
            SELECT Id FROM Profile
            WHERE Name = 'Customer Community Plus Login'
            LIMIT 1
        ];
        User portalUser = new User(
            Username         = 'isabelle.dupont@test.com.portal',
            Email            = 'isabelle.dupont@test.com',
            FirstName        = 'Isabelle',
            LastName         = 'Dupont',
            Alias            = 'idupont',
            CommunityNickname = 'IsabelleDupont',
            LocaleSidKey     = 'fr_FR',
            LanguageLocaleKey = 'fr',
            TimeZoneSidKey   = 'Europe/Paris',
            EmailEncodingKey = 'UTF-8',
            ProfileId        = p.Id,
            ContactId        = con.Id
        );
        insert portalUser;
    }

    // ─────────────────────────────────────────────────────────────
    // HELPERS
    // ─────────────────────────────────────────────────────────────

    private static User getPortalUser() {
        return [SELECT Id FROM User WHERE Username = 'isabelle.dupont@test.com.portal' LIMIT 1];
    }

    private static Contact getContact() {
        return [SELECT Id, AccountId FROM Contact WHERE LastName = 'Dupont' LIMIT 1];
    }

    private static Id getRecordTypeId(String devName) {
        return [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Case' AND DeveloperName = :devName LIMIT 1
        ].Id;
    }

    private static Case createTestCase(Id contactId, Id accountId, String rtDevName) {
        Case c = new Case(
            RecordTypeId = getRecordTypeId(rtDevName),
            ContactId    = contactId,
            AccountId    = accountId,
            Subject      = 'Test case - ' + rtDevName,
            Status       = 'New',
            Origin       = 'Portal',
            Priority     = 'Medium'
        );
        insert c;
        return c;
    }

    // ─────────────────────────────────────────────────────────────
    // TESTS — GET RECORD TYPES
    // ─────────────────────────────────────────────────────────────

    @IsTest
    static void testGetSavRecordTypes_returnsAll4() {
        User portalUser = getPortalUser();
        System.runAs(portalUser) {
            Test.startTest();
            List<SavCaseController.RecordTypeOption> rts =
                SavCaseController.getSavRecordTypes();
            Test.stopTest();
            Assert.isTrue(rts.size() == 4, 'Should return 4 RecordTypes');
        }
    }

    // ─────────────────────────────────────────────────────────────
    // TESTS — CREATE CASE
    // ─────────────────────────────────────────────────────────────

    @IsTest
    static void testCreateCase_retourProduit_success() {
        User             portalUser = getPortalUser();
        Produit_Client__c produit   = [SELECT Id FROM Produit_Client__c LIMIT 1];
        Categorie_SAV__c  cat       = [SELECT Id FROM Categorie_SAV__c LIMIT 1];

        SavCaseController.CaseInput input = new SavCaseController.CaseInput();
        input.recordTypeName    = 'Retour_Produit';
        input.subject           = 'Je souhaite retourner mon sac';
        input.description       = 'Produit reçu endommagé';
        input.produitConcerneId = produit.Id;
        input.categorieSavId    = cat.Id;
        input.canalRetour       = 'Livraison_Domicile';
        input.langueClient      = 'fr';

        System.runAs(portalUser) {
            Test.startTest();
            Id caseId = SavCaseController.createCase(input);
            Test.stopTest();

            Assert.isNotNull(caseId, 'Case Id should be returned');
            Case c = [SELECT Status, Origin, Priority, ContactId FROM Case WHERE Id = :caseId];
            Assert.areEqual('New',    c.Status,   'Status should be New');
            Assert.areEqual('Portal', c.Origin,   'Origin should be Portal');
            Assert.areEqual('Medium', c.Priority, 'Priority should be Medium (VIP contact)');
        }
    }

    @IsTest
    static void testCreateCase_allRecordTypes_success() {
        User portalUser = getPortalUser();

        List<String> rtNames = new List<String>{
            'Retour_Produit', 'Echange_Produit',
            'Reclamation', 'Demande_Information'
        };

        System.runAs(portalUser) {
            Test.startTest();
            for (String rtName : rtNames) {
                SavCaseController.CaseInput input = new SavCaseController.CaseInput();
                input.recordTypeName = rtName;
                input.subject        = 'Test ' + rtName;
                input.description    = 'Description test';
                Id caseId = SavCaseController.createCase(input);
                Assert.isNotNull(caseId, rtName + ' should create successfully');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testCreateCase_nullInput_throws() {
        User portalUser = getPortalUser();
        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.createCase(null);
                Assert.fail('Should throw for null input');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage());
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testCreateCase_missingSubject_throws() {
        User portalUser = getPortalUser();
        SavCaseController.CaseInput input = new SavCaseController.CaseInput();
        input.recordTypeName = 'Retour_Produit';
        // subject intentionally blank

        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.createCase(input);
                Assert.fail('Should throw for missing subject');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage());
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testCreateCase_invalidRecordType_throws() {
        User portalUser = getPortalUser();
        SavCaseController.CaseInput input = new SavCaseController.CaseInput();
        input.recordTypeName = 'INVALID_RT';
        input.subject        = 'Test';

        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.createCase(input);
                Assert.fail('Should throw for invalid RecordType');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage());
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testCreateCase_productNotOwned_throws() {
        // Create a product belonging to a different contact
        Account acc2    = new Account(Name = 'Other Account');
        insert acc2;
        Contact con2    = new Contact(FirstName='Other', LastName='Client',
                                      Email='other@test.com', AccountId=acc2.Id);
        insert con2;
        Produit_Client__c otherProduit = new Produit_Client__c(
            Contact__c     = con2.Id,
            Nom_Produit__c = 'Kelly 28'
        );
        insert otherProduit;

        User portalUser = getPortalUser();
        SavCaseController.CaseInput input = new SavCaseController.CaseInput();
        input.recordTypeName    = 'Retour_Produit';
        input.subject           = 'Test';
        input.produitConcerneId = otherProduit.Id; // Not owned by portal user

        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.createCase(input);
                Assert.fail('Should throw for unowned product');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage());
            }
            Test.stopTest();
        }
    }

    // ─────────────────────────────────────────────────────────────
    // TESTS — GET MY CASES
    // ─────────────────────────────────────────────────────────────

    @IsTest
    static void testGetMyCases_noFilter_returnsPaginated() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();

        // Create 3 cases
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 3; i++) {
            cases.add(new Case(
                RecordTypeId = getRecordTypeId('Reclamation'),
                ContactId    = con.Id,
                AccountId    = con.AccountId,
                Subject      = 'Test ' + i,
                Status       = 'New',
                Origin       = 'Portal'
            ));
        }
        insert cases;

        System.runAs(portalUser) {
            Test.startTest();
            SavCaseController.CaseListWrapper result =
                SavCaseController.getMyCases(10, 1, null, null);
            Test.stopTest();

            Assert.areEqual(3, result.totalCount, 'Should return 3 cases');
            Assert.areEqual(3, result.records.size(), 'Page 1 should have 3 records');
        }
    }

    @IsTest
    static void testGetMyCases_statusFilter() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();

        insert new List<Case>{
            new Case(RecordTypeId=getRecordTypeId('Reclamation'), ContactId=con.Id,
                     AccountId=con.AccountId, Subject='Open', Status='New', Origin='Portal'),
            new Case(RecordTypeId=getRecordTypeId('Reclamation'), ContactId=con.Id,
                     AccountId=con.AccountId, Subject='Closed', Status='Closed', Origin='Portal')
        };

        System.runAs(portalUser) {
            Test.startTest();
            SavCaseController.CaseListWrapper result =
                SavCaseController.getMyCases(10, 1, 'New', null);
            Test.stopTest();

            Assert.areEqual(1, result.totalCount, 'Should return only New cases');
        }
    }

    @IsTest
    static void testGetMyCases_crossContact_isolation() {
        // Other user should not see current user's cases
        Account acc2 = new Account(Name = 'Acct2');
        insert acc2;
        Contact con2 = new Contact(FirstName='Other', LastName='User2',
                                   Email='other2@test.com', AccountId=acc2.Id,
                                   Preferred_Language__c='fr');
        insert con2;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus Login' LIMIT 1];
        User user2 = new User(
            Username='other2@test.com.portal', Email='other2@test.com',
            FirstName='Other', LastName='User2', Alias='ouser2',
            CommunityNickname='OtherUser2', LocaleSidKey='fr_FR',
            LanguageLocaleKey='fr', TimeZoneSidKey='Europe/Paris',
            EmailEncodingKey='UTF-8', ProfileId=p.Id, ContactId=con2.Id
        );
        insert user2;

        // Create case for original user
        Contact con = getContact();
        insert new Case(
            RecordTypeId=getRecordTypeId('Reclamation'), ContactId=con.Id,
            AccountId=con.AccountId, Subject='Private case',
            Status='New', Origin='Portal'
        );

        System.runAs(user2) {
            Test.startTest();
            SavCaseController.CaseListWrapper result =
                SavCaseController.getMyCases(10, 1, null, null);
            Test.stopTest();
            Assert.areEqual(0, result.totalCount, 'User2 should not see User1 cases');
        }
    }

    // ─────────────────────────────────────────────────────────────
    // TESTS — GET CASE DETAIL
    // ─────────────────────────────────────────────────────────────

    @IsTest
    static void testGetCaseDetail_success() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = createTestCase(con.Id, con.AccountId, 'Retour_Produit');

        System.runAs(portalUser) {
            Test.startTest();
            SavCaseController.CaseDetailWrapper detail =
                SavCaseController.getCaseDetail(c.Id);
            Test.stopTest();

            Assert.isNotNull(detail.record);
            Assert.areEqual(c.Id, detail.record.Id);
            Assert.isFalse(detail.canClose,  'Cannot close a New case');
            Assert.isFalse(detail.canReopen, 'Cannot reopen an open case');
        }
    }

    @IsTest
    static void testGetCaseDetail_crossContact_throws() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();

        // Create case for a different contact
        Account acc2 = new Account(Name='Acct3'); insert acc2;
        Contact con2 = new Contact(FirstName='X', LastName='Y',
                                   Email='xy@test.com', AccountId=acc2.Id);
        insert con2;
        Case otherCase = new Case(
            RecordTypeId=getRecordTypeId('Reclamation'), ContactId=con2.Id,
            AccountId=acc2.Id, Subject='Private', Status='New', Origin='Portal'
        );
        insert otherCase;

        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.getCaseDetail(otherCase.Id);
                Assert.fail('Should throw for cross-contact access');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage());
            }
            Test.stopTest();
        }
    }

    // ─────────────────────────────────────────────────────────────
    // TESTS — ADD COMMENT
    // ─────────────────────────────────────────────────────────────

    @IsTest
    static void testAddComment_success() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = createTestCase(con.Id, con.AccountId, 'Demande_Information');

        System.runAs(portalUser) {
            Test.startTest();
            SavCaseController.addComment(c.Id, 'Bonjour, j\'ai une question.');
            Test.stopTest();

            List<CaseComment> comments = [
                SELECT CommentBody FROM CaseComment WHERE ParentId = :c.Id
            ];
            Assert.areEqual(1, comments.size());
        }
    }

    @IsTest
    static void testAddComment_emptyBody_throws() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = createTestCase(con.Id, con.AccountId, 'Demande_Information');

        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.addComment(c.Id, '');
                Assert.fail('Should throw for empty comment');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage());
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testAddComment_reopensClosedCase() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = createTestCase(con.Id, con.AccountId, 'Demande_Information');
        update new Case(Id=c.Id, Status='Closed');

        System.runAs(portalUser) {
            Test.startTest();
            SavCaseController.addComment(c.Id, 'Je reviens avec une nouvelle question.');
            Test.stopTest();

            Case updated = [SELECT Status FROM Case WHERE Id = :c.Id];
            Assert.areEqual('In Progress', updated.Status, 'Case should be reopened');
        }
    }

    // ─────────────────────────────────────────────────────────────
    // TESTS — CLOSE CASE
    // ─────────────────────────────────────────────────────────────

    @IsTest
    static void testCloseCase_success() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = createTestCase(con.Id, con.AccountId, 'Retour_Produit');
        update new Case(Id=c.Id, Status='Resolved');

        System.runAs(portalUser) {
            Test.startTest();
            SavCaseController.closeCase(c.Id);
            Test.stopTest();

            Case closed = [SELECT Status, IsClosed FROM Case WHERE Id = :c.Id];
            Assert.areEqual('Closed', closed.Status);
            Assert.isTrue(closed.IsClosed);
        }
    }

    @IsTest
    static void testCloseCase_notResolved_throws() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = createTestCase(con.Id, con.AccountId, 'Retour_Produit');
        // Status = New, not Resolved

        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.closeCase(c.Id);
                Assert.fail('Should throw: case not resolved');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage());
            }
            Test.stopTest();
        }
    }

    // ─────────────────────────────────────────────────────────────
    // TESTS — ESCALATE
    // ─────────────────────────────────────────────────────────────

    @IsTest
    static void testEscalateCase_success() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = createTestCase(con.Id, con.AccountId, 'Reclamation');

        System.runAs(portalUser) {
            Test.startTest();
            SavCaseController.escalateCase(c.Id, 'Délai dépassé, aucune réponse reçue.');
            Test.stopTest();

            Case escalated = [SELECT Priority, Status FROM Case WHERE Id = :c.Id];
            Assert.areEqual('High',        escalated.Priority);
            Assert.areEqual('In Progress', escalated.Status);

            List<CaseComment> internalComments = [
                SELECT CommentBody, IsPublished FROM CaseComment WHERE ParentId = :c.Id
            ];
            Assert.areEqual(1, internalComments.size());
            Assert.isFalse(internalComments[0].IsPublished, 'Escalation comment should be internal');
        }
    }

    @IsTest
    static void testEscalateCase_closedCase_throws() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = createTestCase(con.Id, con.AccountId, 'Reclamation');
        update new Case(Id=c.Id, Status='Closed');

        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.escalateCase(c.Id, 'Test');
                Assert.fail('Should throw for closed case');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage());
            }
            Test.stopTest();
        }
    }

    // ─────────────────────────────────────────────────────────────
    // TESTS — DASHBOARD STATS
    // ─────────────────────────────────────────────────────────────

    @IsTest
    static void testGetDashboardStats_correctCounts() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();

        insert new List<Case>{
            new Case(RecordTypeId=getRecordTypeId('Reclamation'), ContactId=con.Id,
                     AccountId=con.AccountId, Subject='Open1',
                     Status='New', Origin='Portal'),
            new Case(RecordTypeId=getRecordTypeId('Reclamation'), ContactId=con.Id,
                     AccountId=con.AccountId, Subject='Open2',
                     Status='In Progress', Origin='Portal'),
            new Case(RecordTypeId=getRecordTypeId('Reclamation'), ContactId=con.Id,
                     AccountId=con.AccountId, Subject='Resolved1',
                     Status='Resolved', Origin='Portal'),
            new Case(RecordTypeId=getRecordTypeId('Reclamation'), ContactId=con.Id,
                     AccountId=con.AccountId, Subject='Closed1',
                     Status='Closed', Origin='Portal')
        };

        System.runAs(portalUser) {
            Test.startTest();
            Map<String, Integer> stats = SavCaseController.getCaseDashboardStats();
            Test.stopTest();

            Assert.areEqual(4, stats.get('total'),    'Total should be 4');
            Assert.areEqual(2, stats.get('open'),     'Open should be 2 (New + In Progress)');
            Assert.areEqual(1, stats.get('resolved'), 'Resolved should be 1');
            Assert.areEqual(1, stats.get('closed'),   'Closed should be 1');
        }
    }
}