trigger afterDisbursement on outfunds__Disbursement__c (after insert, before insert) {
    
   List<Id> disList = new List<Id>();
   List<Id> frList = new List<Id>();
    
    //Stamping Disbursement Date on Disbursement Record
    if(Trigger.isBefore){
        for(outfunds__Disbursement__c dis: trigger.new){
            dis.outfunds__Disbursement_Date__c = System.today();
        }
    }

    
    for(outfunds__Disbursement__c dis: trigger.new){
        disList.add(dis.Id);
        frList.add(dis.outfunds__Funding_Request__c);
    }
    
    List<Id,outfunds__Funding_Request__c> newFrMap = new List<Id,outfunds__Funding_Request__c>([Select Id, outfunds__FundingProgram__c, Fully_Disbursed_Date__c, outfunds__Status__c, outfunds__Awarded_Amount__c from outfunds__Funding_Request__c
                                                                                          where Id IN: frList]);
 
    
    System.debug('newFrMap: ' + newFrMap);
   
    List<Id,outfunds__Disbursement__c> newDisMap = new List<Id,outfunds__Disbursement__c>([Select Id, outfunds__Funding_Request__c, outfunds__Disbursement_Date__c, outfunds__Amount__c, outfunds__Funding_Request__r.outfunds__Awarded_Amount__c from outfunds__Disbursement__c 
                                                                                         where outfunds__Funding_Request__c IN: frList]);
    

    
    System.debug('newDisMap: ' + newDisMap);
    

    Map<Id,Id> fpMap = new Map<Id,Id>();
    
    for(outfunds__Funding_Request__c fr: newFrMap.values()){
        fpMap.put(fr.Id,fr.outfunds__FundingProgram__c);
    }
    
    System.debug('fpMap: ' + fpMap);

    List<outfunds__Funding_Program__c> fpList = new List<outfunds__Funding_Program__c>([Select Id, Disbursed_Amount__c from outfunds__Funding_Program__c where Id IN: fpMap.values()]);
  

    
    Map<Id,outfunds__Funding_Program__c> newFpMap = new Map<Id,outfunds__Funding_Program__c>([Select Id, Disbursed_Amount__c from outfunds__Funding_Program__c
                                                                                          where Id IN: fpList]);
    
    Map<Id,Decimal> disMap = new Map<Id,Decimal>();
    
 
    
    // creating map of funding request with total amount 
    for(outfunds__Disbursement__c db: newDisMap.values()){
        
            System.debug('disMap.keySet: ' + disMap.keySet());

        
        if(disMap.containsKey(db.outfunds__Funding_Request__c)){
            Decimal d = disMap.get(db.outfunds__Funding_Request__c);
            System.debug('Inside first If condition: ' + d);
            d += db.outfunds__Amount__c;
            disMap.put(db.outfunds__Funding_Request__c,d);
        }else{
            disMap.put(db.outfunds__Funding_Request__c, db.outfunds__Amount__c);
        }
        
         
    }
    System.debug('disMap: ' + disMap);

    List<sObject> recordsToUpdate = new List<sObject>();  
    Map<Id,sObject> recordsToUpdateMap = new Map<Id,sObject>();
    Map<Id,outfunds__Funding_Program__c> fundingProgramMap = new Map<id,outfunds__Funding_Program__c>();
    
    for (Id i : disMap.keySet()){
        
      
        
        Id fundingProgramId  = fpMap.containsKey(i) ? fpMap.get(i) : '';
        if(!String.isBlank(fundingProgramId)){
        if(fundingProgramMap.containsKey(fundingProgramId)){
            outfunds__Funding_Program__c temp = fundingProgramMap.get(fundingProgramID);
            Decimal amount = temp.Disbursed_Amount__c + disMap.get(i); // Change here if bulk insert fails 11/20
            System.debug('Dis Amount ==> ' + amount);
            temp.Disbursed_Amount__c = amount;
            fundingProgramMap.put(fundingProgramId,temp);
        }  
        else{
            //Made Changes here for review, check previous codes as well
             outfunds__Funding_Program__c fp =  newFpMap.get(fundingProgramId);
            System.debug('Single value ==> ' + disMap.get(i));
             fp.Disbursed_Amount__c = disMap.get(i);
            System.debug('Dis amount final==> ' + fp.Disbursed_Amount__c);
            fundingProgramMap.put(fundingProgramId,fp);
            
        }
            
           
        }
    }
    
    //trying below 
    Set<sObject> newSet = new Set<sObject>();
    for(outfunds__Disbursement__c dis: trigger.new){
          System.debug('Awarded Amnount ==> ' + newFrMap.get(dis.outfunds__Funding_Request__c).outfunds__Awarded_Amount__c);
            System.debug('Total Disbursement Amount ==> ' + disMap.get(dis.outfunds__Funding_Request__c));
         if(newFrMap.containsKey(dis.outfunds__Funding_Request__c) && newFrMap.get(dis.outfunds__Funding_Request__c).outfunds__Awarded_Amount__c == disMap.get(dis.outfunds__Funding_Request__c) ){
                 outfunds__Funding_Request__c fr = new  outfunds__Funding_Request__c(id = dis.outfunds__Funding_Request__c,
                 outfunds__Status__c = 'Fully Disbursed',
            Fully_Disbursed_Date__c = System.today());
                //recordsToUpdate.add(fr);
                newSet.add(fr);
            }
        else if(newFrMap.containsKey(dis.outfunds__Funding_Request__c) && newFrMap.get(dis.outfunds__Funding_Request__c).outfunds__Awarded_Amount__c < disMap.get(dis.outfunds__Funding_Request__c)) {
            dis.addError('You are crossing the awarded amount on the following Funding Request ==> ' + dis.outfunds__Funding_Request__c);
        }
    }
    
    recordsToUpdate.addAll(newSet);
    recordsToUpdate.addAll(fundingProgramMap.values());
    
System.debug('updating records'+   recordsToUpdate);    
System.debug('newSet Values ==> ' + newSet);    
   
    
    try{
      //  update recordsToUpdateMap.values();
       update recordsToUpdate;
    }catch(Exception e){
        System.debug('Error ==>' +e.getMessage());
    }
    
    
}