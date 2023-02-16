trigger beforeGauExp on outfundsnpspext__GAU_Expenditure__c (before insert) {
    
    List<Id> disIdList = new List<Id>();
    for(outfundsnpspext__GAU_Expenditure__c gex: trigger.new){
        disIdList.add(gex.outfundsnpspext__Disbursement__c);
    }
    
    Map<Id,outfunds__Disbursement__c> disMap = new Map<Id,outfunds__Disbursement__c>([Select Id,outfunds__Funding_Request__c from outfunds__Disbursement__c where Id IN: disIdList]);
    List<Id> frIdList = new List<Id>();
    Map<Id,outfunds__Funding_Request__c> disFrMap = new Map<Id,outfunds__Funding_Request__c>();
    
    
    for(outfunds__Disbursement__c dis: disMap.values()){
        frIdList.add(dis.outfunds__Funding_Request__c);
    }
    
    Map<Id,outfunds__Funding_Request__c> frMap = new Map<Id,outfunds__Funding_Request__c>([Select Id, outfunds__FundingProgram__c from outfunds__Funding_Request__c where Id IN: frIdList]);
    List<Id> fpIdList = new List<Id>();
    
    for(outfunds__Disbursement__c dis: disMap.values()){
        Id frId = dis.outfunds__Funding_Request__c;
        outfunds__Funding_Request__c fr = frMap.get(frId);
        disFrMap.put(dis.Id, fr);
    }
    
    Map<Id,outfunds__Funding_Program__c> disFpMap = new Map<Id,outfunds__Funding_Program__c>();
   
    
    for(outfunds__Funding_Request__c fr: frMap.values()){
        fpIdList.add(fr.outfunds__FundingProgram__c);
    }
    
    Map<Id,outfunds__Funding_Program__c> fpMap = new Map<Id,outfunds__Funding_Program__c>([Select Id, Funding_Program_Balance__c from outfunds__Funding_Program__c where Id IN: fpIdList]);
    
     for(Id d: disFrMap.keySet()){
        Id fpId = disFrMap.get(d).outfunds__FundingProgram__c;
        outfunds__Funding_Program__c fp = fpMap.get(fpId);
         disFpMap.put(d,fp);
    }
    
    Map<Id,Decimal> balMap = new Map<Id,Decimal>();
    
    for(outfundsnpspext__GAU_Expenditure__c ge: trigger.new){
        if(ge.outfundsnpspext__Amount__c > disFpMap.get(ge.outfundsnpspext__Disbursement__c).Funding_Program_Balance__c){
            ge.addError('You dont have sufficient funds');
        }
    }

}