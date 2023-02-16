trigger AmountValidation on outfundsnpspext__GAU_Expenditure__c (before insert) {
   
   Set<Id> newSet = new Set<Id>();
   Decimal DynamicAmount = 0.00;
    for(outfundsnpspext__GAU_Expenditure__c GE : trigger.new){
        newSet.add(GE.outfundsnpspext__Disbursement__c);
    }
    List<outfundsnpspext__GAU_Expenditure__c> newList = [Select Id,outfundsnpspext__Disbursement__c, outfundsnpspext__Amount__c, outfundsnpspext__General_Accounting_Unit__c  
                                                         from outfundsnpspext__GAU_Expenditure__c where outfundsnpspext__Disbursement__c IN: newSet];
    
    for(outfundsnpspext__GAU_Expenditure__c gNew : newList){
        
        DynamicAmount += gNew.outfundsnpspext__Amount__c;
        
    }
    
    for(outfundsnpspext__GAU_Expenditure__c g: trigger.new){
        
        outfunds__Disbursement__c dis = new outfunds__Disbursement__c(id = g.outfundsnpspext__Disbursement__c);
        System.debug(dis.Id);
        System.debug(dis.outfunds__Status__c);

        System.debug(dis.outfunds__Amount__c);
        if(dis.outfunds__Amount__c != null){
             Decimal AmountAvailable = dis.outfunds__Amount__c - DynamicAmount;
                    System.debug(dis.outfunds__Amount__c);

            if(g.outfundsnpspext__Amount__c > AmountAvailable){
            g.outfundsnpspext__Amount__c.addError('You have crosssed the limit');
        }
        }
      
        
        
            
            
    }
    
    

}