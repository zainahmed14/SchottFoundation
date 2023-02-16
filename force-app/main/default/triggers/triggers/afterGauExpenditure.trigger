trigger afterGauExpenditure on outfundsnpspext__GAU_Expenditure__c (after insert) {
    
        List<Id> gauId = new List<Id>();
        List<Id> disId = new List<Id>();
   
    
    for(outfundsnpspext__GAU_Expenditure__c gexp: trigger.new){
        
        gauId.add(gexp.outfundsnpspext__General_Accounting_Unit__c);
        disId.add(gexp.outfundsnpspext__Disbursement__c);
    }
    
   
    
    Map<Id,npsp__General_Accounting_Unit__c> gauMap = new Map<Id,npsp__General_Accounting_Unit__c>([Select Id, New_Available_Amount__c from npsp__General_Accounting_Unit__c where Id IN: gauId]);
    
    Map<Id,Decimal> gauNewMap = new Map<Id,Decimal>();
    
    for(outfundsnpspext__GAU_Expenditure__c geNew: trigger.new){
        
        if(gauNewMap.containsKey(geNew.outfundsnpspext__General_Accounting_Unit__c)){
            
            Decimal d = gauNewMap.get(geNew.outfundsnpspext__General_Accounting_Unit__c);
            d += geNew.outfundsnpspext__Amount__c;
            gauNewMap.put(geNew.outfundsnpspext__General_Accounting_Unit__c,d);
            
        }else{
            
            gauNewMap.put(geNew.outfundsnpspext__General_Accounting_Unit__c, geNew.outfundsnpspext__Amount__c);
        }
    }
    
    List<sObject> recordsToUpdate = new List<sObject>();
    //Map<Id,Decimal> finalGauMap = new Map<Id,Decimal>(); // This Map is used for updating the funding program, as we could not get FP from trigger.new we used Gau to get the value.

    for(Id i: gauNewMap.keySet()){
        
        Decimal SubtractAmountGau = gauMap.get(i).New_Available_Amount__c - gauNewMap.get(i);
        //finalGauMap.put(i, gauNewMap.get(i));

        npsp__General_Accounting_Unit__c gauUpdate = new npsp__General_Accounting_Unit__c(Id = i, New_Available_Amount__c = SubtractAmountGau);
        recordsToUpdate.add(gauUpdate);
    }
    
    
    List<GAU_In_Funding_Program__c> gauInFpList = new List<GAU_In_Funding_Program__c>([Select Id, GAU_Id__c, Funding_Program_ID__c from GAU_In_Funding_Program__c where GAU_Id__c IN: gauId]);
    List<Id> fpList = new List<Id>();
    
    for(GAU_In_Funding_Program__c gifp: gauInFpList){
        fpList.add(gifp.Funding_Program_ID__c);
    }
    
    Map<Id,outfunds__Funding_Program__c> fpMap = new Map<Id,outfunds__Funding_Program__c>([Select Id, Total_Amount__c, Funding_Program_Balance__c from outfunds__Funding_Program__c where Id IN: fpList]);
    
    Map<Id,Decimal> fpNewMap = new Map<Id,Decimal>();

    
    for(GAU_In_Funding_Program__c gfp : gauInFpList){
      
        if(fpNewMap.containsKey(gfp.Funding_Program_ID__c)){
            
             Decimal d = fpNewMap.get(gfp.Funding_Program_ID__c);
             d += gauNewMap.get(gfp.GAU_Id__c);
            //System.debug('Final Map data: ' + finalGauMap);
            //System.debug('Funding Program: ' + gfp.Funding_Program_ID__c + 'Amount in this fp: ' + d);
             fpNewMap.put(gfp.Funding_Program_ID__c,d);
        }else{
             fpNewMap.put(gfp.Funding_Program_ID__c, gauNewMap.get(gfp.GAU_Id__c));
            
            
        }
    }
    
     for(Id i: fpNewMap.keySet()){
        Decimal subtractAmountFp = fpMap.get(i).Total_Amount__c - fpNewMap.get(i);
        outfunds__Funding_Program__c fpNew = new outfunds__Funding_Program__c(id = i,Total_Amount__c  = subtractAmountFp, Funding_Program_Balance__c = subtractAmountFp);
         System.debug('Funding Program final instance to update: ' + fpNew);
        recordsToUpdate.add(fpNew);
    
       }
    
    //Trying new things for before gau exp
    Map<Id,GAU_In_Funding_Program__c> actualGfpMap = new Map<Id,GAU_In_Funding_Program__c>();
    Map<Id,GAU_In_Funding_Program__c> gauInFpMap = new Map<Id,GAU_In_Funding_Program__c>([Select Id, Funding_Program_ID__c, GAU_Id__c from GAU_In_Funding_Program__c where GAU_Id__c IN: gauId]);
    Map<Id,outfundsnpspext__GAU_Expenditure__c> gauExMap = new Map<Id,outfundsnpspext__GAU_Expenditure__c>([Select Id, outfundsnpspext__Disbursement__c, outfundsnpspext__Amount__c from outfundsnpspext__GAU_Expenditure__c where outfundsnpspext__Disbursement__c IN: disId]);
    
    System.debug('gauExMap ==> '  + gauExMap);
    for(GAU_In_Funding_Program__c gfp: gauInFpMap.values()){
        actualGfpMap.put(gfp.GAU_Id__c,gfp);
    }
    
    Map<Id,Decimal> expTotalMap = new Map<Id,Decimal>();
    for(outfundsnpspext__GAU_Expenditure__c gauEx: trigger.new){
        if(expTotalMap.containsKey(gauEx.outfundsnpspext__Disbursement__c)){
            Decimal d = expTotalMap.get(gauEx.outfundsnpspext__Disbursement__c);
            d += gauEx.outfundsnpspext__Amount__c;
            expTotalMap.put(gauEx.outfundsnpspext__Disbursement__c, d);
        }else{
            expTotalMap.put(gauEx.outfundsnpspext__Disbursement__c, gauEx.outfundsnpspext__Amount__c);
        }
    }
    
    for(outfundsnpspext__GAU_Expenditure__c gauEx: trigger.New){
        Id gauId = gauEx.outfundsnpspext__General_Accounting_Unit__c;
        GAU_In_Funding_Program__c gfp = actualGfpMap.get(gauId);
        Id fpId = gfp.Funding_Program_ID__c;
        outfunds__Funding_Program__c fp = fpMap.get(fpId);
        
        System.debug('New Funding program ==> ' + fp.Id + 'Funding Program balance ==> ' + fp.Funding_Program_Balance__c);
        System.debug('GauExp Total Amount including current Gau ==> ' + expTotalMap.get(gauEx.outfundsnpspext__Disbursement__c));
        
        if(expTotalMap.get(gauEx.outfundsnpspext__Disbursement__c) > fp.Funding_Program_Balance__c){
            gauEx.addError('You dont have suffiecient funds for the following gau exp ==> ' + gauEx.Id);
        }
    }
    
    try{
        update recordsToUpdate;
    }catch(Exception e){
        
        System.debug(e.getMessage());
    }
    
}