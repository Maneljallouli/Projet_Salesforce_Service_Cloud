/**
 * @class       SavCaseControllerTest
 * @description PMD-clean test class for SavCaseController.
 *              Fixes applied vs v2.0:
 *                - All test method names start with lowercase (PMD MethodNamingConventions)
 *                - All Assert calls include a descriptive message (PMD ApexAssertionsShouldIncludeMessage)
 *              Coverage target : >= 85%
 *
 * @author      Salesforce Architect
 * @version     2.1
 */
@IsTest
private class SavCaseControllerTest {

    // ─────────────────────────────────────────────────────────────
    // TEST SETUP
    // ─────────────────────────────────────────────────────────────

    @TestSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Maison Luxe');
        insert acc;

        Contact con = new Contact(
            FirstName   = 'Isabelle',
            LastName    = 'Dupont',
            Email       = 'isabelle.dupont@test.com',
            AccountId   = acc.Id
        );
        insert con;

        Produit_Client__c produit = new Produit_Client__c(
            Contact__c              = con.Id,
            Nom_Produit__c          = 'Birkin 35',
            Reference_Officielle__c = 'BIRK35-TEST-001',
            Modele__c               = 'Birkin',
            Couleur__c              = 'Noir',
            Actif__c                = true
        );
        insert produit;

        Categorie_SAV__c categorie = new Categorie_SAV__c(
            Nom__c   = 'Défaut produit',
            Code__c  = 'DEFAUT',
            Actif__c = true
        );
        insert categorie;

        Profile p = [
            SELECT Id FROM Profile
            WHERE  Name = 'Customer Community Plus Login' LIMIT 1
        ];
        User portalUser = new User(
            Username          = 'isabelle.dupont@test.com.portal',
            Email             = 'isabelle.dupont@test.com',
            FirstName         = 'Isabelle',
            LastName          = 'Dupont',
            Alias             = 'idupont',
            CommunityNickname = 'IsabelleDupont',
            LocaleSidKey      = 'fr_FR',
            LanguageLocaleKey = 'fr',
            TimeZoneSidKey    = 'Europe/Paris',
            EmailEncodingKey  = 'UTF-8',
            ProfileId         = p.Id,
            ContactId         = con.Id
        );
        insert portalUser;
    }

    // ─────────────────────────────────────────────────────────────
    // HELPERS
    // ─────────────────────────────────────────────────────────────

    private static User getPortalUser() {
        return [
            SELECT Id FROM User
            WHERE  Username = 'isabelle.dupont@test.com.portal' LIMIT 1
        ];
    }

    private static Contact getContact() {
        return [SELECT Id, AccountId FROM Contact WHERE LastName = 'Dupont' LIMIT 1];
    }

    private static Id getRecordTypeId(String devName) {
        return [
            SELECT Id FROM RecordType
            WHERE  SObjectType = 'Case' AND DeveloperName = :devName LIMIT 1
        ].Id;
    }

    private static Case buildAndInsertCase(Id contactId, Id accountId, String rtDevName) {
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

    private static SavCaseController.CaseInput buildInput(String rtName, String subject) {
        SavCaseController.CaseInput input = new SavCaseController.CaseInput();
        input.recordTypeName = rtName;
        input.subject        = subject;
        input.description    = 'Description test';
        input.langueClient   = 'fr';
        return input;
    }

    // ─────────────────────────────────────────────────────────────
    // TESTS — GET RECORD TYPES
    // ─────────────────────────────────────────────────────────────

    @IsTest
    static void testGetSavRecordTypes_returns4Types() {
        User portalUser = getPortalUser();
        System.runAs(portalUser) {
            Test.startTest();
            List<SavCaseController.RecordTypeOption> rts =
                SavCaseController.getSavRecordTypes();
            Test.stopTest();
            Assert.areEqual(4, rts.size(), 'Should return exactly 4 RecordTypes');
        }
    }

    // ─────────────────────────────────────────────────────────────
    // TESTS — CREATE CASE
    // ─────────────────────────────────────────────────────────────

    @IsTest
    static void testCreateCase_retourProduit_createsSuccessfully() {
        User              portalUser = getPortalUser();
        Produit_Client__c produit    = [SELECT Id FROM Produit_Client__c LIMIT 1];
        Categorie_SAV__c  cat        = [SELECT Id FROM Categorie_SAV__c LIMIT 1];

        SavCaseController.CaseInput input = buildInput('Retour_Produit', 'Je souhaite retourner mon sac');
        input.produitConcerneId = produit.Id;
        input.categorieSavId    = cat.Id;
        input.canalRetour       = 'Livraison_Domicile';

        System.runAs(portalUser) {
            Test.startTest();
            Id caseId = SavCaseController.createCase(input);
            Test.stopTest();

            Assert.isNotNull(caseId, 'Case Id should not be null after creation');
            Case c = [SELECT Status, Origin, Priority, ContactId FROM Case WHERE Id = :caseId];
            Assert.areEqual('New',    c.Status,   'Newly created Case status should be New');
            Assert.areEqual('Portal', c.Origin,   'Case origin should be Portal');
        }
    }

    @IsTest
    static void testCreateCase_allFourRecordTypes_createSuccessfully() {
        User portalUser = getPortalUser();
        List<String> rtNames = new List<String>{
            'Retour_Produit', 'Echange_Produit',
            'Reclamation', 'Demande_Information'
        };

        System.runAs(portalUser) {
            Test.startTest();
            for (String rtName : rtNames) {
                SavCaseController.CaseInput input = buildInput(rtName, 'Test ' + rtName);
                Id caseId = SavCaseController.createCase(input);
                Assert.isNotNull(caseId, rtName + ' should create a Case successfully');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testCreateCase_nullInput_throwsAuraException() {
        User portalUser = getPortalUser();
        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.createCase(null);
                Assert.fail('Should throw AuraHandledException for null input');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage(), 'Exception message should not be null');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testCreateCase_blankSubject_throwsAuraException() {
        User portalUser = getPortalUser();
        SavCaseController.CaseInput input = new SavCaseController.CaseInput();
        input.recordTypeName = 'Retour_Produit';

        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.createCase(input);
                Assert.fail('Should throw AuraHandledException for blank subject');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage(), 'Exception message should not be null');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testCreateCase_invalidRecordType_throwsAuraException() {
        User portalUser = getPortalUser();
        SavCaseController.CaseInput input = buildInput('INVALID_TYPE', 'Test');

        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.createCase(input);
                Assert.fail('Should throw AuraHandledException for invalid RecordType');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage(), 'Exception message should not be null');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testCreateCase_unownedProduct_throwsAuraException() {
        Account           acc2         = new Account(Name = 'Other');
        insert acc2;
        Contact           con2         = new Contact(FirstName='X', LastName='Y',
                                            Email='xy@test.com', AccountId=acc2.Id);
        insert con2;
        Produit_Client__c otherProduit = new Produit_Client__c(
            Contact__c     = con2.Id,
            Nom_Produit__c = 'Kelly 28'
        );
        insert otherProduit;

        User portalUser = getPortalUser();
        SavCaseController.CaseInput input = buildInput('Retour_Produit', 'Test');
        input.produitConcerneId = otherProduit.Id;

        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.createCase(input);
                Assert.fail('Should throw AuraHandledException for unowned product');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage(), 'Exception message should not be null');
            }
            Test.stopTest();
        }
    }

    // ─────────────────────────────────────────────────────────────
    // TESTS — GET MY CASES
    // ─────────────────────────────────────────────────────────────

    @IsTest
    static void testGetMyCases_noFilter_returnsPaginatedResults() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();

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

            Assert.areEqual(3, result.totalCount, 'Total count should be 3');
            Assert.areEqual(3, result.records.size(), 'Page 1 should contain 3 records');
        }
    }

    @IsTest
    static void testGetMyCases_statusFilter_returnsOnlyMatchingStatus() {
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

            Assert.areEqual(1, result.totalCount, 'Only New cases should be returned');
        }
    }

    @IsTest
    static void testGetMyCases_recordTypeFilter_returnsOnlyMatchingType() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();

        insert new List<Case>{
            new Case(RecordTypeId=getRecordTypeId('Reclamation'),
                     ContactId=con.Id, AccountId=con.AccountId,
                     Subject='Rec', Status='New', Origin='Portal'),
            new Case(RecordTypeId=getRecordTypeId('Demande_Information'),
                     ContactId=con.Id, AccountId=con.AccountId,
                     Subject='Info', Status='New', Origin='Portal')
        };

        System.runAs(portalUser) {
            Test.startTest();
            SavCaseController.CaseListWrapper result =
                SavCaseController.getMyCases(10, 1, null, 'Reclamation');
            Test.stopTest();

            Assert.areEqual(1, result.totalCount, 'Only Reclamation cases should be returned');
        }
    }

    @IsTest
    static void testGetMyCases_crossContact_returnsZeroRecords() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Plus Login' LIMIT 1];
        Account acc2 = new Account(Name='Acct2'); insert acc2;
        Contact con2 = new Contact(FirstName='Other', LastName='User2',
                                   Email='other2@test.com', AccountId=acc2.Id);
        insert con2;
        User user2 = new User(
            Username='other2@test.com.portal', Email='other2@test.com',
            FirstName='Other', LastName='User2', Alias='ouser2',
            CommunityNickname='OtherUser2x', LocaleSidKey='fr_FR',
            LanguageLocaleKey='fr', TimeZoneSidKey='Europe/Paris',
            EmailEncodingKey='UTF-8', ProfileId=p.Id, ContactId=con2.Id
        );
        insert user2;

        Contact con = getContact();
        insert new Case(
            RecordTypeId=getRecordTypeId('Reclamation'), ContactId=con.Id,
            AccountId=con.AccountId, Subject='Private', Status='New', Origin='Portal'
        );

        System.runAs(user2) {
            Test.startTest();
            SavCaseController.CaseListWrapper result =
                SavCaseController.getMyCases(10, 1, null, null);
            Test.stopTest();

            Assert.areEqual(0, result.totalCount,
                'User2 should not see cases belonging to User1');
        }
    }

    // ─────────────────────────────────────────────────────────────
    // TESTS — GET CASE DETAIL
    // ─────────────────────────────────────────────────────────────

    @IsTest
    static void testGetCaseDetail_validCase_returnsWrapper() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = buildAndInsertCase(con.Id, con.AccountId, 'Retour_Produit');

        System.runAs(portalUser) {
            Test.startTest();
            SavCaseController.CaseDetailWrapper detail =
                SavCaseController.getCaseDetail(c.Id);
            Test.stopTest();

            Assert.isNotNull(detail.record, 'Detail record should not be null');
            Assert.areEqual(c.Id, detail.record.Id, 'Returned Case Id should match');
            Assert.isFalse(detail.canClose,  'Cannot close a New case');
            Assert.isFalse(detail.canReopen, 'Cannot reopen an open case');
        }
    }

    @IsTest
    static void testGetCaseDetail_crossContact_throwsAuraException() {
        Account acc2 = new Account(Name='Acct3'); insert acc2;
        Contact con2 = new Contact(FirstName='X', LastName='Z',
                                   Email='xz@test.com', AccountId=acc2.Id);
        insert con2;
        Case otherCase = new Case(
            RecordTypeId=getRecordTypeId('Reclamation'), ContactId=con2.Id,
            AccountId=acc2.Id, Subject='Private', Status='New', Origin='Portal'
        );
        insert otherCase;

        User portalUser = getPortalUser();
        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.getCaseDetail(otherCase.Id);
                Assert.fail('Should throw AuraHandledException for cross-contact access');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage(), 'Exception message should not be null');
            }
            Test.stopTest();
        }
    }

    // ─────────────────────────────────────────────────────────────
    // TESTS — ADD COMMENT
    // ─────────────────────────────────────────────────────────────

    @IsTest
    static void testAddComment_validComment_createsPublicComment() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = buildAndInsertCase(con.Id, con.AccountId, 'Demande_Information');

        System.runAs(portalUser) {
            Test.startTest();
            SavCaseController.addComment(c.Id, 'Bonjour, j\'ai une question.');
            Test.stopTest();

            List<CaseComment> comments = [
                SELECT CommentBody, IsPublished FROM CaseComment WHERE ParentId = :c.Id
            ];
            Assert.areEqual(1, comments.size(), 'One comment should have been created');
            Assert.isTrue(comments[0].IsPublished, 'Comment should be public');
        }
    }

    @IsTest
    static void testAddComment_emptyBody_throwsAuraException() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = buildAndInsertCase(con.Id, con.AccountId, 'Demande_Information');

        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.addComment(c.Id, '');
                Assert.fail('Should throw AuraHandledException for empty comment body');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage(), 'Exception message should not be null');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testAddComment_onClosedCase_reopensCase() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = buildAndInsertCase(con.Id, con.AccountId, 'Demande_Information');
        update new Case(Id = c.Id, Status = 'Closed');

        System.runAs(portalUser) {
            Test.startTest();
            SavCaseController.addComment(c.Id, 'Question de suivi.');
            Test.stopTest();

            Case updated = [SELECT Status FROM Case WHERE Id = :c.Id];
            Assert.areEqual('In Progress', updated.Status,
                'Closed case should be reopened when client adds a comment');
        }
    }

    // ─────────────────────────────────────────────────────────────
    // TESTS — CLOSE CASE
    // ─────────────────────────────────────────────────────────────

    @IsTest
    static void testCloseCase_resolvedCase_closesSuccessfully() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = buildAndInsertCase(con.Id, con.AccountId, 'Retour_Produit');
        update new Case(Id = c.Id, Status = 'Resolved');

        System.runAs(portalUser) {
            Test.startTest();
            SavCaseController.closeCase(c.Id);
            Test.stopTest();

            Case closed = [SELECT Status, IsClosed FROM Case WHERE Id = :c.Id];
            Assert.areEqual('Closed', closed.Status,
                'Case status should be Closed after client confirmation');
            Assert.isTrue(closed.IsClosed,
                'IsClosed flag should be true after closing');
        }
    }

    @IsTest
    static void testCloseCase_notResolvedStatus_throwsAuraException() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = buildAndInsertCase(con.Id, con.AccountId, 'Retour_Produit');

        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.closeCase(c.Id);
                Assert.fail('Should throw AuraHandledException when status is not Resolved');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage(), 'Exception message should not be null');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testCloseCase_alreadyClosed_throwsAuraException() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = buildAndInsertCase(con.Id, con.AccountId, 'Retour_Produit');
        update new Case(Id = c.Id, Status = 'Closed');

        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.closeCase(c.Id);
                Assert.fail('Should throw AuraHandledException for already closed case');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage(), 'Exception message should not be null');
            }
            Test.stopTest();
        }
    }

    // ─────────────────────────────────────────────────────────────
    // TESTS — ESCALATE CASE
    // ─────────────────────────────────────────────────────────────

    @IsTest
    static void testEscalateCase_openCase_setsHighPriorityAndInternalComment() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = buildAndInsertCase(con.Id, con.AccountId, 'Reclamation');

        System.runAs(portalUser) {
            Test.startTest();
            SavCaseController.escalateCase(c.Id, 'Aucune réponse depuis 5 jours.');
            Test.stopTest();

            Case escalated = [SELECT Priority, Status FROM Case WHERE Id = :c.Id];
            Assert.areEqual('High',        escalated.Priority,
                'Escalated case priority should be High');
            Assert.areEqual('In Progress', escalated.Status,
                'Escalated case status should be In Progress');

            List<CaseComment> internalComments = [
                SELECT CommentBody, IsPublished
                FROM   CaseComment WHERE ParentId = :c.Id
            ];
            Assert.areEqual(1, internalComments.size(),
                'One internal comment should be created on escalation');
            Assert.isFalse(internalComments[0].IsPublished,
                'Escalation comment should be internal (not published)');
        }
    }

    @IsTest
    static void testEscalateCase_closedCase_throwsAuraException() {
        User    portalUser = getPortalUser();
        Contact con        = getContact();
        Case    c          = buildAndInsertCase(con.Id, con.AccountId, 'Reclamation');
        update new Case(Id = c.Id, Status = 'Closed');

        System.runAs(portalUser) {
            Test.startTest();
            try {
                SavCaseController.escalateCase(c.Id, 'Test');
                Assert.fail('Should throw AuraHandledException for closed case escalation');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage(), 'Exception message should not be null');
            }
            Test.stopTest();
        }
    }

    // ─────────────────────────────────────────────────────────────
    // TESTS — DASHBOARD STATS
    // ─────────────────────────────────────────────────────────────

    @IsTest
    static void testGetDashboardStats_mixedStatuses_returnsCorrectCounts() {
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
                     AccountId=con.AccountId, Subject='Res1',
                     Status='Resolved', Origin='Portal'),
            new Case(RecordTypeId=getRecordTypeId('Reclamation'), ContactId=con.Id,
                     AccountId=con.AccountId, Subject='Clo1',
                     Status='Closed', Origin='Portal')
        };

        System.runAs(portalUser) {
            Test.startTest();
            Map<String, Integer> stats = SavCaseController.getCaseDashboardStats();
            Test.stopTest();

            Assert.areEqual(4, stats.get('total'),
                'Total count should be 4');
            Assert.areEqual(2, stats.get('open'),
                'Open count should be 2 (New + In Progress)');
            Assert.areEqual(1, stats.get('resolved'),
                'Resolved count should be 1');
            Assert.areEqual(1, stats.get('closed'),
                'Closed count should be 1');
        }
    }
}