trigger BeforeGauEx on outfundsnpspext__GAU_Expenditure__c (after insert) {
    List<Id> disId = new List<Id>();
    List<Id> gauId = new List<Id>();
    for(outfundsnpspext__GAU_Expenditure__c gauEx: trigger.new){
        disId.add(gauEx.outfundsnpspext__Disbursement__c);
        gauId.add(gauEx.outfundsnpspext__General_Accounting_Unit__c);
    }
    System.debug('Disbursement List: ' + disId);
    Map<Id,outfunds__Disbursement__c> newDisMap = new Map<Id,outfunds__Disbursement__c>([Select Id, outfunds__Funding_Request__c, outfunds__Amount__c from outfunds__Disbursement__c where Id IN: disId]);
    System.debug('newDisMap: ' + newDisMap.values());
    
    Map<Id,Id> frMap = new Map<Id,Id>();
    
    for(outfunds__Disbursement__c dis: newDisMap.values()){
        
       //outfunds__Disbursement__c newDis = new outfunds__Disbursement__c(Id = dis.Id);
        //System.debug('newDis ' + newDis);
        frMap.put(dis.Id, dis.outfunds__Funding_Request__c);
    }
    System.debug('Fr Map: ' + frMap);
    
    List<outfunds__Funding_Request__c> frList = [Select Id, outfunds__FundingProgram__c from outfunds__Funding_Request__c where Id IN: frMap.values()];
    
    System.debug('Fr List: ' + frList);
    
    List<Id> fpList = new List<Id>();
    
    for(outfunds__Funding_Request__c fr: frList){
        fpList.add(fr.outfunds__FundingProgram__c);
    }
    
    System.debug('fpList: ' + fpList);
    List<GAU_In_Funding_Program__c> gauInFpList = [Select Id,GAU_Id__c from GAU_In_Funding_Program__c where Funding_Program_ID__c IN: fpList];
    Map<Id,GAU_In_Funding_Program__c> gauInFpMap = new Map<Id,GAU_In_Funding_Program__c>();
   
    for(GAU_In_Funding_Program__c gau: gauInFpList){
        gauInFpMap.put(gau.GAU_Id__c, gau);
    }
    
    //New Process to check if the selected GAU have enough funds
    Map<Id,npsp__General_Accounting_Unit__c> gauMap = new Map<Id,npsp__General_Accounting_Unit__c>([Select Id, Name, New_Available_Amount__c from npsp__General_Accounting_Unit__c where Id IN: gauId]);
    Map<Id,Decimal> GauAmountMap = new Map<Id,Decimal>();
    for(outfundsnpspext__GAU_Expenditure__c gauEx: trigger.new){
        if(GauAmountMap.containsKey(gauEx.outfundsnpspext__General_Accounting_Unit__c)){
            Decimal TotalAmount = GauAmountMap.get(gauEx.outfundsnpspext__General_Accounting_Unit__c) + gauEx.outfundsnpspext__Amount__c;
            GauAmountMap.put(gauEx.outfundsnpspext__General_Accounting_Unit__c, TotalAmount);
             if(GauAmountMap.get(gauEx.outfundsnpspext__General_Accounting_Unit__c) > gauMap.get(gauEx.outfundsnpspext__General_Accounting_Unit__c).New_Available_Amount__c){
                gauEx.addError('The GAU Selected does not have enough funds ==> ' + gauMap.get(gauEx.outfundsnpspext__General_Accounting_Unit__c).Name  + '' + gauMap.get(gauEx.outfundsnpspext__General_Accounting_Unit__c).Id);
             }
        }else{
            GauAmountMap.put(gauEx.outfundsnpspext__General_Accounting_Unit__c, gauEx.outfundsnpspext__Amount__c);
            if(GauAmountMap.get(gauEx.outfundsnpspext__General_Accounting_Unit__c) > gauMap.get(gauEx.outfundsnpspext__General_Accounting_Unit__c).New_Available_Amount__c){
                gauEx.addError('The GAU Selected does not have enough funds ==> ' + gauMap.get(gauEx.outfundsnpspext__General_Accounting_Unit__c).Name  + '' + gauMap.get(gauEx.outfundsnpspext__General_Accounting_Unit__c).Id);
            }
        }
    }
    
    
    System.debug('gauInFpMap: ' + gauInFpMap);
    
    for(outfundsnpspext__GAU_Expenditure__c gauEx: trigger.new){
        
        if(!gauInFpMap.containsKey(gauEx.outfundsnpspext__General_Accounting_Unit__c)){
            
            gauEx.addError('Please select the right Gau');
            
        }
    }
    
    List<outfundsnpspext__GAU_Expenditure__c> gauExList = [Select Id, outfundsnpspext__Amount__c, outfundsnpspext__Disbursement__c from outfundsnpspext__GAU_Expenditure__c where outfundsnpspext__Disbursement__c IN: disId];
    
    System.debug('gauExList: ' + gauExList);
    System.debug('gauExList size: ' + gauExList.size());
    
    Map<Id,Decimal> gauexMap = new Map<Id,Decimal>();
   
    for(outfundsnpspext__GAU_Expenditure__c gauExp: gauExList){
        
        if(gauexMap.containsKey(gauExp.outfundsnpspext__Disbursement__c)){
            Decimal d = gauexMap.get(gauExp.outfundsnpspext__Disbursement__c);
            d += gauExp.outfundsnpspext__Amount__c;
            gauexMap.put(gauExp.outfundsnpspext__Disbursement__c, d);
        }else{
                        gauexMap.put(gauExp.outfundsnpspext__Disbursement__c, gauExp.outfundsnpspext__Amount__c);

        }
        
    }
        
        System.debug('gauexMap: ' + gauexMap);
        
        for(outfundsnpspext__GAU_Expenditure__c gauExpend: trigger.new){
            Decimal disAmount = newDisMap.get(gauExpend.outfundsnpspext__Disbursement__c).outfunds__Amount__c;
            Decimal gauexAmount = gauexMap.get(gauExpend.outfundsnpspext__Disbursement__c);
            //Decimal TotalAmount = gauexMap.get(gauExpend.outfundsnpspext__Disbursement__c) + gauExpend.outfundsnpspext__Amount__c;
            //System.debug('Total Amount: ' + TotalAmount);
            //System.debug('Amouunt on disbursement: ' + newDisMap.get(gauExpend.outfundsnpspext__Disbursement__c).outfunds__Amount__c);
                                              
                                               if(gauexAmount > disAmount){
                                                   gauExpend.addError('you are crossing the amount limit');
                                               }
                System.debug('Insert Allowed because amount is ' + disAmount +','+ gauexAmount);
        }
    
    

}