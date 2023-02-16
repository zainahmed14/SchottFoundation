trigger GauInFp on GAU_In_Funding_Program__c (after insert) {
    
    List<Id> fpList = new List<Id>();
    List<Id> gauList = new List<Id>();

    for(GAU_In_Funding_Program__c gNew: trigger.new){
        
        fpList.add(gNew.Funding_Program_ID__c);
        gauList.add(gNew.GAU_Id__c);
        
    }
    
    Map<Id,outfunds__Funding_Program__c> fpMap = new Map<Id,outfunds__Funding_Program__c>([Select Id, Total_Amount__c, Funding_Program_Balance__c from outfunds__Funding_Program__c where Id IN: fpList]);
    Map<Id,npsp__General_Accounting_Unit__c> gauMap = new Map<Id,npsp__General_Accounting_Unit__c>([Select Id,New_Available_Amount__c from npsp__General_Accounting_Unit__c where Id IN: gauList]);
    Map<Id,Decimal> newMap = new Map<Id,Decimal>();
   
    for(GAU_In_Funding_Program__c gNew: trigger.new){
        
        if(newMap.containsKey(gNew.Funding_Program_ID__c)){
            Decimal d = newMap.get(gNew.Funding_Program_ID__c);
            d += gauMap.get(gNew.GAU_Id__c).New_Available_Amount__c;
            newMap.put(gNew.Funding_Program_ID__c, d);
        }else{
            
            newMap.put(gNew.Funding_Program_ID__c,gauMap.get(gNew.GAU_Id__c).New_Available_Amount__c);
        }
   
    
    }
    
    List<outfunds__Funding_Program__c> recordsToUpdate = new List<outfunds__Funding_Program__c>();
    
    for(Id i: newMap.keySet()){
        
        Decimal addAmount = newMap.get(i) + fpMap.get(i).Total_Amount__c;
        outfunds__Funding_Program__c fpUpdate = new outfunds__Funding_Program__c(id = i, Total_Amount__c = addAmount, Funding_Program_Balance__c = addAmount);
        recordsToUpdate.add(fpUpdate);
    }
    
    try{
        update recordsToUpdate;
    }catch(Exception e){
        
        System.debug(e.getMessage());
    }

}