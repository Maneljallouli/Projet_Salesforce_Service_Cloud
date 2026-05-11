global class CaseTrainingBatch implements Database.Batchable<Integer> {

    Map<String, List<String>> mapping = new Map<String, List<String>>{
        'Demande information' => new List<String>{
            'Disponibilité produit',
            'Suivi commande',
            'Information sur prix / promotion',
            'Informations sur personnalisation',
            'Comment faire un retour'
        },
        'Echange produit' => new List<String>{
            'Taille / ajustement',
            'Couleur / modèle',
            'Produit défectueux',
            'Produit non conforme à la commande'
        },
        'Réclamation' => new List<String>{
            'Produit endommagé / défectueux',
            'Livraison retardée',
            'Erreur de facturation',
            'Mauvais produit livré'
        },
        'Retour produit' => new List<String>{
            'Remboursement demandé',
            'Retour pour non-conformité'
        }
    };

    List<String> priorities = new List<String>{'Low', 'Medium', 'High'};

    global Iterable<Integer> start(Database.BatchableContext bc) {
        List<Integer> scope = new List<Integer>();
        for (Integer i = 0; i < 400; i++) {
            scope.add(i);
        }
        return scope;
    }

    global void execute(Database.BatchableContext bc, List<Integer> scope) {

        List<Case> casesToInsert = new List<Case>();

        for (Integer i : scope) {

            List<String> categories = new List<String>(mapping.keySet());
            String category = categories[(Integer)(Math.random() * categories.size())];

            List<String> subCats = mapping.get(category);
            String subCat = subCats[(Integer)(Math.random() * subCats.size())];

            String priority = priorities[(Integer)(Math.random() * priorities.size())];

            casesToInsert.add(new Case(
                Subject = 'Einstein Training #' + i + ' : ' + category + ' - ' + subCat,
                Description = 'Dataset auto classification - ' + subCat,
                Status = 'Closed',
                Origin = 'Web',
                Priority = priority,
                Category__c = category,
                Subcategory__c = subCat
            ));
        }

        insert casesToInsert;
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch terminé : 400 cases créés pour Einstein training.');
    }
}