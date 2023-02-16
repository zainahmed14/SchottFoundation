trigger AfterGauAllocation on npsp__Allocation__c (after insert) {
    
    
    List<Id> oppIdList = new List<Id>();
    List<Id> gauIdList = new List<Id>();

    for(npsp__Allocation__c alloc: trigger.new){
      
        oppIdList.add(alloc.npsp__Opportunity__c);
        gauIdList.add(alloc.npsp__General_Accounting_Unit__c);
        
        
    }
        
    Map<Id,Opportunity> OppMap = new Map<Id,Opportunity>([Select Id, Name, Amountlefttoallocate__c from Opportunity where Id IN: oppIdList]);
    Map<Id,npsp__General_Accounting_Unit__c> gauMap = new Map<Id,npsp__General_Accounting_Unit__c>([Select Id, New_Available_Amount__c from npsp__General_Accounting_Unit__c where Id IN: gauIdList]);

    Map<Id,Decimal> oppNewMap = new Map<Id,Decimal>();
    Map<Id,Decimal> gauNewMap = new Map<Id,Decimal>();

    for(npsp__Allocation__c newAlloc: trigger.new){
        if(oppNewMap.containsKey(newAlloc.npsp__Opportunity__c)){
            
            Decimal d = oppNewMap.get(newAlloc.npsp__Opportunity__c);
            d += newAlloc.npsp__Amount__c;
            oppNewMap.put(newAlloc.npsp__Opportunity__c, d);

           
            
        }else{
            oppNewMap.put(newAlloc.npsp__Opportunity__c, newAlloc.npsp__Amount__c);
        }
        
        if(gauNewMap.containsKey(newAlloc.npsp__General_Accounting_Unit__c)){
            
            Decimal d1 = gauNewMap.get(newAlloc.npsp__General_Accounting_Unit__c);
            d1 += newAlloc.npsp__Amount__c;
            gauNewMap.put(newAlloc.npsp__General_Accounting_Unit__c, d1);
        }else{
            
            gauNewMap.put(newAlloc.npsp__General_Accounting_Unit__c, newAlloc.npsp__Amount__c);
        }
        
    }
    
    List<sObject> recordstoUpdate = new List<sObject>();
    Map<Id,Decimal> finalGauMap = new Map<Id,Decimal>();
    for(Id i: oppNewMap.keySet()){
        Decimal subtractedAmount = oppMap.get(i).Amountlefttoallocate__c - oppNewMap.get(i);
        Opportunity opp = new Opportunity(id = i, Amountlefttoallocate__c = subtractedAmount);
        recordsToUpdate.add(opp);
    }
    
     for(Id i1: gauNewMap.keySet()){
        
         Decimal AddAmount = gauMap.get(i1).New_Available_Amount__c + gauNewMap.get(i1);
         finalGauMap.put(i1, gauNewMap.get(i1));
        npsp__General_Accounting_Unit__c gau = new npsp__General_Accounting_Unit__c (id = i1, New_Available_Amount__c = AddAmount);
        recordsToUpdate.add(gau);
    }
    
    
    
  
    
   List<GAU_In_Funding_Program__c> gauInFpList = [Select GAU_Id__c, Funding_Program_ID__c from GAU_In_Funding_Program__c where GAU_Id__c IN: gauIdList];
    List<Id> fplatestList = new List<Id>();
    
    for(GAU_In_Funding_Program__c gifp: gauInFpList){
        fplatestList.add(gifp.Funding_Program_ID__c);
    }
    
    Map<Id,outfunds__Funding_Program__c> gauInFpMap = new Map<Id,outfunds__Funding_Program__c>([Select Id, Total_Amount__c, Funding_Program_Balance__c  from outfunds__Funding_Program__c where Id IN: fplatestList]);
  
    
    System.debug('FP Map ' + gauInFpMap.values());
    
    Map<Id,Decimal> FpMap = new Map<Id,Decimal>();
    
    
    for(GAU_In_Funding_Program__c gfp : gauInFpList){
        
        if(FpMap.containsKey(gfp.Funding_Program_ID__c)){
             Decimal d = FpMap.get(gfp.Funding_Program_ID__c);
             d += finalGauMap.get(gfp.GAU_Id__c);
            System.debug('Final Map data: ' + finalGauMap);
            System.debug('Funding Program: ' + gfp.Funding_Program_ID__c + 'Amount in this fp: ' + d);
             FpMap.put(gfp.Funding_Program_ID__c,d);
           
            
        }else{
             FpMap.put(gfp.Funding_Program_ID__c, finalGauMap.get(gfp.GAU_Id__c));
            
            
        }
 
    }
    
        for(Id i: FpMap.keySet()){
        Decimal addAmount = gauInFpMap.get(i).Total_Amount__c + FpMap.get(i);
        outfunds__Funding_Program__c fpNew = new outfunds__Funding_Program__c(id = i,Total_Amount__c  = addAmount, Funding_Program_Balance__c = addAmount);
            System.debug('Funding Program final instance to update: ' + fpNew);
        recordsToUpdate.add(fpNew);
    
       }
    
    try{
        
        update recordsToUpdate;
    }
    catch(Exception e){
        
        System.debug('gauAllocation Error: ' + e.getMessage());
    }
        
      
}