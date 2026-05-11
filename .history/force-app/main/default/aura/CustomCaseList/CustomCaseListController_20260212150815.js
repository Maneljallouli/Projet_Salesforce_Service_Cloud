({
    doInit : function(component, event, helper) {
        var action = component.get("c.getMyCases");
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                console.log("DEBUG APEX - SUCCESS. Nombre de dossiers reçus: " + data.length);
                console.log("DEBUG APEX - DATA: ", JSON.stringify(data));
                component.set("v.cases", data);
            } 
            else if (state === "ERROR") {
                var errors = response.getError();
                console.error("DEBUG APEX - ERROR: ", JSON.stringify(errors));
                // Alerte visuelle pour savoir si c'est un problème de permission
                if (errors && errors[0] && errors[0].message) {
                    console.error("Message d'erreur: " + errors[0].message);
                }
            }
        });
        $A.enqueueAction(action);
    },

    goToDetail : function(component, event, helper) {
        // dataset.id correspond au 'data-id' dans votre HTML
        var caseId = event.currentTarget.dataset.id;
        console.log("Navigation vers le dossier ID: " + caseId);
        
        if(!caseId) {
            console.error("Erreur: ID du dossier manquant.");
            return;
        }

        var navService = component.find("navService");
        var pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        };
        navService.navigate(pageReference);
    },

    viewAll : function(component, event, helper) {
        var navService = component.find("navService");
        navService.navigate({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            }
        });
    }
})