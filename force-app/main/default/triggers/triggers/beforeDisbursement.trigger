trigger beforeDisbursement on outfunds__Disbursement__c (before insert) {
    
    List<Id> frIdList = new List<Id>();
    for(outfunds__Disbursement__c dis: trigger.new){
        frIdList.add(dis.outfunds__Funding_Request__c);
    }
    
    Map<Id,Id> fpIdMap = new Map<Id,Id>();
    Map<Id,outfunds__Funding_Request__c> frMap = new Map<Id,outfunds__Funding_Request__c>([Select Id, outfunds__FundingProgram__c, outfunds__Status__c from outfunds__Funding_Request__c where Id IN: frIdList]);

    for(outfunds__Funding_Request__c fr: frMap.values()){
        fpIdMap.put(fr.Id, fr.outfunds__FundingProgram__c);
    }
    
    Map<Id,outfunds__Funding_Program__c> fpMap = new Map<Id,outfunds__Funding_Program__c>([Select Id, Funding_Program_Balance__c from outfunds__Funding_Program__c where Id IN: fpIdMap.values()]);
    
    for(outfunds__Disbursement__c dis: trigger.new){
        
        Id fpId = fpIdMap.get(dis.outfunds__Funding_Request__c);
        outfunds__Funding_Program__c fp = fpMap.get(fpId);
        
        if(frMap.get(dis.outfunds__Funding_Request__c).outfunds__Status__c == 'Fully Disbursed'){
            dis.addError('Either you are out of Funds or the awarded amount is already disbursed, Please Check');
        }
       
    }
}