trigger BeforeGauInFP on GAU_In_Funding_Program__c (before insert) {
    
    List<Id> fpId = new List<Id>();
    List<Id> gauId = new List<Id>();
    
    for(GAU_In_Funding_Program__c gfp: trigger.new){
        fpId.add(gfp.Funding_Program_ID__c);
        gauId.add(gfp.GAU_Id__c);
    }
    
    System.debug('gauId List: ' + gauId);
    
    List<Id> fpIdNew = new List<Id>();
    //List<outfunds__Funding_Program__c> fpList = [Select Id from outfunds__Funding_Program__c where Id IN: fpId];
    List<GAU_In_Funding_Program__c> gfpList = [Select Id, Funding_Program_ID__c from GAU_In_Funding_Program__c where GAU_Id__c IN: gauId];

    //Map<Id,outfunds__Funding_Program__c> fpMap = new Map<Id,outfunds__Funding_Program__c>([Select Id from outfunds__Funding_Program__c where Id IN: fpId]);
    
    for(GAU_In_Funding_Program__c gfp: gfpList){
        fpIdNew.add(gfp.Funding_Program_ID__c);
    }
    
    System.debug('fpIdNew List: ' + fpIdNew);
    
    for(GAU_In_Funding_Program__c gfp: trigger.new){
        System.debug('gfp: ' + gfp.Funding_Program_ID__c);
        if(fpIdNew.size()>0 && fpIdNew.contains(gfp.Funding_Program_ID__c)){
            gfp.addError('The Funding Program is already selected for the following gau with the following FP ==> ' + gfp.GAU_Id__c + ' ' + gfp.Funding_Program_ID__c);
        }else{
            fpIdNew.add(gfp.Funding_Program_ID__c);
        }
    }

}